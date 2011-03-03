
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
local DOORBELL_START_NUM = 4

function start_button()
   if #callbutton.messages > 0 then
      local m = callbutton.messages[#callbutton.messages]
      return m.values.data == DOORBELL_START_NUM
   end

   return false
end

function HRI_yes()
   if #callbutton.messages > 0 then
      local m = callbutton.messages[#callbutton.messages]
      return m.values.data == HRI_YES_NUM
   end

   return false
end

function HRI_no()
   if #callbutton.messages > 0 then
      local m = callbutton.messages[#callbutton.messages]
      return m.values.data == HRI_NO_NUM
   end

   return false
end

