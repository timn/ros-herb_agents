
----------------------------------------------------------------------------
--  testing.lua
--
--  License: BSD, cf. LICENSE file
--  Copyright  2010  Kyle Strabala [strabala@cmu.edu]
--             2010  Tim Niemueller [www.niemueller.de]
--             2010  Carnegie Mellon University
--             2010  Intel Labs Pittsburgh
----------------------------------------------------------------------------

-- Initialize module
module(..., agentenv.module_init)

-- Crucial skill information
name               = "testing"
fsm                = AgentHSM:new{name=name, info=true, start="START"}
depends_skills     = {}
depends_topics     = {}

documentation      = [==[Agent for testing predicates and other logic.]==]

-- Initialize as agent module
agentenv.agent_module(...)

local preds = require("herb_agents.predicates.general")
local obj_preds = require("herb_agents.predicates.obj_tracking_preds")
local Skill = AgentSkillExecJumpState
local SubFSM = SubFSMJumpState

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds, op=obj_preds, TIMEOUT_INDIFFERENCE=TIMEOUT_INDIFFERENCE},
  {"START", JumpState},
  {"FINAL", JumpState},
}

fsm:add_transitions{
  {"START", "FINAL", timeout=2},
  {"FINAL", "START", true},
}

function FINAL:init()
  print_info("%s = %q", "obj_preds.held_object_belongs_in_human_bin", tostring(obj_preds.held_object_belongs_in_human_bin))
  print_info("%s = %q", "obj_preds.human_near_table", tostring(obj_preds.human_near_table))
  print_info("%s = %q", "obj_preds.human_tracking_working", tostring(obj_preds.human_tracking_working))
  print_info("%s = %q", "obj_preds.objects_on_table", tostring(obj_preds.objects_on_table))
  print_info("%s = %q", "obj_preds.human_holding_object", tostring(obj_preds.human_holding_object))
  print_info("%s = %q", "obj_preds.human_offering_object", tostring(obj_preds.human_offering_object))
  print_info("%s = %q", "obj_preds.held_object_belongs_in_robot_bin", tostring(obj_preds.held_object_belongs_in_robot_bin))
end


