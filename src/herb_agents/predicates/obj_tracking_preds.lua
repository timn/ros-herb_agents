
------------------------------------------------------------------------
--  obj_tracking_preds.lua - Object Tracking HERB Predicates
--
--  Created: Mon Feb 07 12:41:15 2011
--  License: BSD, cf. LICENSE file
--  Copyright  2011  Kyle Strabala <strabala@cmu.edu>
--             2010  Tim Niemueller [www.niemueller.de]
--             2011  Carnegie Mellon University
--             2011  Intel Labs Pittsburgh
------------------------------------------------------------------------

local predlib = require("fawkes.predlib")
local os = os
local math = math
local pairs = pairs
local type = type
local print = print
local tostring = tostring
local print_info = print_info
local print_debug = print_debug
local roslua = roslua
local string = string

--- This module provides object tracking predicates.
-- @author Tim Niemueller
module(..., predlib.module_init)

name = "herb_obj_tracking"
depends_topics = {
  {v="callbutton", name="/callbutton", type="std_msgs/Byte"},
  {v="obj_list", name="/objtracking/objlist", type="objtracking/ObjectList", latching=true},
  {v="skeleton_list", name="/skeletons", type="body_msgs/Skeletons", latching=true},
  {v="human_near_table_byte", name="/human_near_table_status", type="std_msgs/Byte", latching=true},
  {v="hand_off_byte", name="/human_handoff_status", type="std_msgs/Byte", latching=true},
  { v="grabbed",  name="/manipulation/grabbed_obj", type="newmanipapp/GrabbedObjects", latching=true },
}

-- Initialize as predicate library
predlib.setup(...)

local TABLE_HEIGHT = 0.725
local HANDOFF_YES_BYTE = 1
local HUMAN_NEAR_TABLE_YES_BYTE = 1
local WORLD_FRAME_ID = "/openrave"
local HUMAN_HAND_FRAME_ID_BASE = "human_left_hand"
local HERB_LEFT_HAND_FRAME_ID = "/left/wam7"
local HERB_RIGHT_HAND_FRAME_ID = "/right/wam7"
local TRACKING_TIMEOUT_SECS = 4
local ROBOT_BIN_OBJECT_PATTERN = "poptarts[%d]*"
local HUMAN_BIN_OBJECT_PATTERN = "fuze_bottle[%d]*"

function human_tracking_working()
  now_time = roslua.Time.now():to_sec()
  if #skeleton_list.messages > 0 then
    local m = skeleton_list.messages[#skeleton_list.messages]
    msg_time = roslua.Time.from_message_array(m.values.header.values.stamp):to_sec()
    if now_time - msg_time > TRACKING_TIMEOUT_SECS then
      return false
    end
    --print_debug("Tracking " .. tostring(#m.values.skeletons) .. " skeletons at " .. tostring(msg_time) .. ", current time: " .. tostring(now_time))
    if #m.values.skeletons > 0 then
      return true
    end
  end
  return false
end

function human_near_table()
  if human_tracking_working == false then
    return false
  end
  if #human_near_table_byte.messages > 0 then
    local m = human_near_table_byte.messages[#human_near_table_byte.messages]
    if m.values.data == HUMAN_NEAR_TABLE_YES_BYTE then
      return true
    end
  end
  return false
end

function objects_on_table()
  now_time = roslua.Time.now():to_sec()
  if #obj_list.messages > 0 then
    local m = obj_list.messages[#obj_list.messages]
    msg_time = roslua.Time.from_message_array(m.values.header.values.stamp):to_sec()
    if now_time - msg_time > TRACKING_TIMEOUT_SECS then
      return false
    end
    for i = 1, #m.values.objects do
      object = m.values.objects[i].values
      --if object.header.values.frame_id == WORLD_FRAME_ID then
        --pos = object.pose.values.position.values
        --if math.abs(pos.z - TABLE_HEIGHT) < 0.05 then
          return true
        --end
      --end
    end
  end
  return false
end

function human_holding_object()
  now_time = roslua.Time.now():to_sec()
  if #obj_list.messages > 0 then
    local m = obj_list.messages[#obj_list.messages]
    msg_time = roslua.Time.from_message_array(m.values.header.values.stamp):to_sec()
    if now_time - msg_time > TRACKING_TIMEOUT_SECS then
      return false
    end
    for i = 1, #m.values.objects do
      object = m.values.objects[i].values
      if string.find(object.header.values.frame_id, HUMAN_HAND_FRAME_ID_BASE) ~= nil then
        return true
      end
    end
  end
  --return false
  return true --assume human is always holding object
end

function human_offering_object()
  if human_tracking_working == true and human_holding_object == true then
    if #hand_off_byte.messages > 0 then
      local m = hand_off_byte.messages[#hand_off_byte.messages]
      if m.values.data == HANDOFF_YES_BYTE then
        return true
      end
    end
  end
  return false
end

-- Check if HERB has an object
function HERB_holding_object()
   return (HERB_holding_object_in_left_hand or HERB_holding_object_in_left_hand)
end

-- Check if HERB has an object in his left hand
function HERB_holding_object_in_left_hand()
   if #grabbed.messages > 0 then
      local m = grabbed.messages[#grabbed.messages] -- only check most recent
      print_debug("Comparing %s to 'none'", m.values.left_object_id)
      if not m.values.left_object_id:match("none") then
        return true
      end
   end
   return false
end

-- Check if HERB has an object in his left hand
function HERB_holding_object_in_right_hand()
   if #grabbed.messages > 0 then
      local m = grabbed.messages[#grabbed.messages] -- only check most recent
      print_debug("Comparing %s to 'none'", m.values.right_object_id)
      if not m.values.right_object_id:match("none") then
        return true
      end
   end
   return false
end

-- Check if the object in the left hand belongs in the either bin
function left_held_object_unsortable()
   return not (left_held_object_belongs_in_robot_bin or left_held_object_belongs_in_human_bin)
end

-- Check if the object in the left hand belongs in the robot bin
function left_held_object_belongs_in_robot_bin()
   if #grabbed.messages > 0 then
      local m = grabbed.messages[#grabbed.messages] -- only check most recent
      print_debug("Comparing %s to %s", m.values.left_object_id, ROBOT_BIN_OBJECT_PATTERN)
      if m.values.left_object_id:match(ROBOT_BIN_OBJECT_PATTERN) then
        return true
      end
   end
   return false
end

-- Check if the object in the left hand belongs in the human bin
function left_held_object_belongs_in_human_bin()
   if #grabbed.messages > 0 then
      local m = grabbed.messages[#grabbed.messages] -- only check most recent
      print_debug("Comparing %s to %s", m.values.left_object_id, HUMAN_BIN_OBJECT_PATTERN)
      if m.values.left_object_id:match(HUMAN_BIN_OBJECT_PATTERN) then
        return true
      end
   end
   return false
end

-- Check if the object in the right hand belongs in the either bin
function right_held_object_unsortable()
   return not (right_held_object_belongs_in_robot_bin or right_held_object_belongs_in_human_bin)
end

-- Check if the object in the right hand belongs in the robot bin
function right_held_object_belongs_in_robot_bin()
   if #grabbed.messages > 0 then
      local m = grabbed.messages[#grabbed.messages] -- only check most recent
      print_debug("Comparing %s to %s", m.values.right_object_id, ROBOT_BIN_OBJECT_PATTERN)
      if m.values.right_object_id:match(ROBOT_BIN_OBJECT_PATTERN) then
        return true
      end
   end
   return false
end

-- Check if the object in the right hand belongs in the human bin
function right_held_object_belongs_in_human_bin()
   if #grabbed.messages > 0 then
      local m = grabbed.messages[#grabbed.messages] -- only check most recent
      print_debug("Comparing %s to %s", m.values.right_object_id, HUMAN_BIN_OBJECT_PATTERN)
      if m.values.right_object_id:match(HUMAN_BIN_OBJECT_PATTERN) then
        return true
      end
   end
   return false
end

