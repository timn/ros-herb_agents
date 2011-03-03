
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

--- This module provides object tracking predicates.
-- @author Tim Niemueller
module(..., predlib.module_init)

name = "herb_obj_tracking"
depends_topics = {
  {v="callbutton", name="/callbutton", type="std_msgs/Byte"},
  {v="obj_list", name="/objtracking/obj_list", type="objtracking/ObjectList", latching=true},
  {v="skeleton_list", name="/skeletons", type="body_msgs/Skeletons", latching=true},
  {v="hand_off_byte", name="/human_handoff_status", type="std_msgs/Byte", latching=true},
}

-- Initialize as predicate library
predlib.setup(...)

local TABLE_HEIGHT = 0.725;
local HANDOFF_YES = 1;
local HUMAN_HAND_FRAME_ID_BASE = "human_left_hand"
local HERB_LEFT_HAND_FRAME_ID = "/left/wam7"
local HERB_RIGHT_HAND_FRAME_ID = "/right/wam7"
local TRACKING_TIMEOUT_SECS = 2

function human_tracking_working()
  if #skeleton_list.messages > 0 then
    local m = skeleton_list.messages[#skeleton_list.messages]
    print("Tracking " .. tostring(#m.values.skeletons) .. " skeletons.")
    if #m.values.skeletons > 0 and os.time(os.date('*t')) - m.values.header.values.stamp.sec <= TRACKING_TIMEOUT_SECS then
      return true
    end
  end
  return false
end

function human_near_table()
  if human_tracking_working == false then
    return false
  end
  if #skeleton_list.messages > 0 then
    local m = skeleton_list.messages[#skeleton_list.messages]
    for i = 1, #m.values.skeletons do
      local skeleton = m.values.skeletons[i]
      local pos = skeleton.values.torso.values.position.values
      if math.abs(pos.x) < 0.6 and math.abs(pos.y + 1.5) < 0.6 then
        return true
      end
    end
  end
  return false
end

function objects_on_table()
  if #obj_list.messages > 0 then
    local m = obj_list.messages[#obj_list.messages]
    for i = 1, #m.values.object_list do
      object = m.values.object_list[i].values
      if object.header.values.frame_id == WORLD_FRAME_ID then
        pos = object.pose.values.position.values
        if math.abs(pos.z - TABLE_HEIGHT) < 0.03 then
          return true
        end
      end
    end
  end
  return false
end

function human_holding_object()
  if #obj_list.messages > 0 then
    local m = obj_list.messages[#obj_list.messages]
    for i = 1, #m.values.object_list do
      object = m.values.object_list[i].values
      if string.find(object.header.values.frame_id, HUMAN_HAND_FRAME_ID_BASE) ~= nil then
        return true
      end
    end
  end
  return false
end

function human_offering_object()
  if human_holding_object == true then
    if #hand_off_byte.messages > 0 then
      hand_off = hand_off_byte.messages[#hand_off_byte.messages]
      if hand_off.values.data == HANDOFF_YES then
        return true
      end
    end
  end
  return false
end

function held_object_belongs_in_robot_bin()
  if #obj_list.messages > 0 then
    local m = obj_list.messages[#obj_list.messages]
    for i = 1, #m.values.object_list do
      object = m.values.object_list[i].values
      if string.find(object.header.values.frame_id, HERB_LEFT_HAND_FRAME_ID) ~= nil then
        if object.object_type == "poptarts" then
          return true
        else
          return false
        end    
        break 
      end
    end
  end
  return false
end

function held_object_belongs_in_human_bin()
  if #obj_list.messages > 0 then
    local m = obj_list.messages[#obj_list.messages]
    for i = 1, #m.values.object_list do
      object = m.values.object_list[i].values
      if string.find(object.header.values.frame_id, HERB_LEFT_HAND_FRAME_ID) ~= nil then
        if object.object_type == "fuze_bottle" then
          return true
        else
          return false
        end    
        break 
      end
    end
  end
  return false
end

