
------------------------------------------------------------------------
--  general.lua - General HERB Predicates
--
--  Created: Fri Oct 22 17:28:32 2010
--  Copyright  2010  Tim Niemueller [www.niemueller.de]
--
------------------------------------------------------------------------

--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU Library General Public License for more details.
--
--  Read the full text in the LICENSE.GPL file in the doc directory.

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
