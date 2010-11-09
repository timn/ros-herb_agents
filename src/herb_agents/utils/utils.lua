----------------------------------------------------------------------------
--  utils.lua - Herb agent utilities
--
--  Created: Mon Sep 13 12:06:59 2010
--  License: BSD, cf. LICENSE file
--  Copyright  2010  Tim Niemueller [www.niemueller.de]
--             2010  Carnegie Mellon University
--             2010  Intel Labs Pittsburgh
----------------------------------------------------------------------------

require("fawkes.modinit")

--- Skill Queue for agents.
-- @author Tim Niemueller
module(..., fawkes.modinit.module_init)

function opposite_side(side)
   if side == "left" then return "right" else return "left" end
end

