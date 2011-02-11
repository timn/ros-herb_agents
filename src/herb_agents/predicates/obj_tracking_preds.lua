
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
local math=math

--- This module provides object tracking predicates.
-- @author Tim Niemueller
module(..., predlib.module_init)

name = "herb_obj_tracking"
depends_topics = {
  {v="callbutton", name="/callbutton", type="std_msgs/Byte"},
  {v="obj_list", name="/objtracking/obj_list", type="objtracking/ObjectList"},
}

-- Initialize as predicate library
predlib.setup(...)


function human_near_table()
  return false
end
function human_tracking_working()
  return false
end
function objects_on_table()
  return false
end
function human_holding_object()
  return false
end
function human_offering_object()
  return false
end
function held_object_belongs_in_robot_bin()
  return false
end
function held_object_belongs_in_human_bin()
  return false
end
