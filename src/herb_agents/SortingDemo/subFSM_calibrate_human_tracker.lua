
----------------------------------------------------------------------------
--  init.lua - Herb skills initialization file
--
--  Created: Fri Aug 20 18:25:22 2010 (at Intel Research, Pittsburgh)
--  License: BSD, cf. LICENSE file
--  Copyright  2010  Tim Niemueller [www.niemueller.de]
--             2010  Carnegie Mellon University
--             2010  Intel Labs Pittsburgh
----------------------------------------------------------------------------

-- Initialize module
module(..., agentenv.module_init)

-- Crucial skill information
name            = "calibrate_human_tracker"
fsm             = AgentHSM:new{name=name, debug=true, start="START", exit_state="FINAL", fail_state="FAILED"}
depends_skills  = {}
depends_actions = {}

documentation      = [==[asdf]==]

-- Initialize as agent module
agentenv.agent_module(...)

local preds = require("herb_agents.predicates.general")
local obj_preds = require("herb_agents.predicates.obj_tracking_preds")
local Skill = AgentSkillExecJumpState

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds, op=obj_preds},
  {"START", JumpState},
  {"CALIBRATE_HUMAN_TRACKER", JumpState},
  {"FINAL", JumpState},
  {"FAILED", JumpState},
}

fsm:add_transitions{
--  {"START", "FINAL", "op.human_tracking_working and op.human_near_table"},
--  {"START", "CALIBRATE_HUMAN_TRACKER", "not op.human_tracking_working or not op.human_near_table"},
  {"CALIBRATE_HUMAN_TRACKER", "FINAL", "true"},
  {"CALIBRATE_HUMAN_TRACKER", "FAILED", "false"},

  {"START", "FINAL", "p.HRI_yes"},
  {"START", "CALIBRATE_HUMAN_TRACKER", "p.HRI_no"},
}

