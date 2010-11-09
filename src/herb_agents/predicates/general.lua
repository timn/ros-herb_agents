
------------------------------------------------------------------------
--  general.lua - General HERB Predicates
--
--  Created: Fri Oct 22 17:28:32 2010
--  License: BSD, cf. LICENSE file
--  Copyright  2010  Tim Niemueller [www.niemueller.de]
--             2010  Carnegie Mellon University
--             2010  Intel Labs Pittsburgh
------------------------------------------------------------------------

local predlib = require("fawkes.predlib")
local math=math

--- This module provides generic soccer predicates.
-- @author Tim Niemueller
module(..., predlib.module_init)

name = "herb_general"
depends_topics = {
   {v="doorbell", name="/callbutton", type="std_msgs/Byte"}
}

-- Initialize as predicate library
predlib.setup(...)

local DOORBELL_START_NUM = 4

function start_button()
   if #doorbell.messages > 0 then
      local m = doorbell.messages[#doorbell.messages]
      return m.values.data == DOORBELL_START_NUM
   end

   return false
end
