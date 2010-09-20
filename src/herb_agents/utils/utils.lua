----------------------------------------------------------------------------
--  skillqueue.lua - Skill queue for agents
--
--  Created: Fri Jan 02 16:31:14 2009
--  Copyright  2008-2009  Tim Niemueller [http://www.niemueller.de]
--
----------------------------------------------------------------------------

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

require("fawkes.modinit")

--- Skill Queue for agents.
-- @author Tim Niemueller
module(..., fawkes.modinit.module_init)

function opposite_side(side)
   if side == "left" then return "right" else return "left" end
end
