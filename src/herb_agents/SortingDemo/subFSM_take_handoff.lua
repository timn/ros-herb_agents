
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
name            = "take_handoff"
fsm             = AgentHSM:new{name=name, debug=true, start="START", exit_state="FINAL", fail_state="FAILED"}
depends_skills  = {}
depends_actions = {}

documentation      = [==[take a handoff offered by a human]==]

-- Initialize as agent module
agentenv.agent_module(...)

local preds = require("herb_agents.predicates.general")
local obj_preds = require("herb_agents.predicates.obj_tracking_preds")
local Skill = AgentSkillExecJumpState

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds, op=obj_preds},
  {"START", JumpState},
  {"TAKE_HANDOFF", Skill, skills={{"ft_take", side="right"}}, 
          final_state="FINAL", 
          failure_state="FAILED"},
  {"FINAL", JumpState},
  {"FAILED", JumpState},
}

fsm:add_transitions{
  {"START", "FINAL", "not op.human_offering_object"},
  {"START", "TAKE_HANDOFF", "op.human_offering_object"},

--  {"START", "FINAL", "p.HRI_no"},
--  {"START", "TAKE_HANDOFF", "p.HRI_yes"},
}

