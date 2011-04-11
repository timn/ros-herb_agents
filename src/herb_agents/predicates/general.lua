
------------------------------------------------------------------------
--  general.lua - General HERB Predicates
--
--  Created: Fri Oct 22 17:28:32 2010
--  License: BSD, cf. LICENSE file
--  Copyright  2010  Tim Niemueller [www.niemueller.de]
--             2011  Kyle Strabala <strabala@cmu.edu>
--             2010  Carnegie Mellon University
--             2010  Intel Labs Pittsburgh
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

--- This module provides generic predicates.
-- @author Tim Niemueller
module(..., predlib.module_init)

name = "herb_general"
depends_topics = {
   {v="callbutton", name="/callbutton", type="std_msgs/Byte"}
}

-- Initialize as predicate library
predlib.setup(...)

local HRI_NO_NUM = 1
local HRI_YES_NUM = 2
local STOP_NUM = 3
local START_NUM = 4

function start_button()
   if #callbutton.messages > 0 then
      local m = callbutton.messages[#callbutton.messages]
      --print_debug("%s: %d messages; most recent: data = %d","start_button",#callbutton.messages,m.values.data)
      return m.values.data == START_NUM
   end
   --print_debug("%s: no messages","start_button")
   return false
end

function stop_button()
   if #callbutton.messages > 0 then
      local m = callbutton.messages[#callbutton.messages]
      --print_debug("%s: %d messages; most recent: data = %d","stop_button",#callbutton.messages,m.values.data)
      return m.values.data == STOP_NUM
   end
   --print_debug("%s: no messages","stop_button")
   return false
end

function HRI_yes()
   if #callbutton.messages > 0 then
      local m = callbutton.messages[#callbutton.messages]
      --print_debug("%s: %d messages; most recent: data = %d","HRI_yes",#callbutton.messages,m.values.data)
      return m.values.data == HRI_YES_NUM
   end
   --print_debug("%s: no messages","HRI_yes")
   return false
end

function HRI_no()
   if #callbutton.messages > 0 then
      local m = callbutton.messages[#callbutton.messages]
      --print_debug("%s: %d messages; most recent: data = %d","HRI_no",#callbutton.messages,m.values.data)
      return m.values.data == HRI_NO_NUM
   end
   --print_debug("%s: no messages","HRI_no")
   return false
end

