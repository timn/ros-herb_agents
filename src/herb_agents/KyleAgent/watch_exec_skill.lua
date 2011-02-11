
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
name            = "watch_exec_skill"
fsm             = AgentHSM:new{name=name, debug=true, start="START", exit_state="FINAL", fail_state="FAILED"}
depends_skills  = {"say"}
depends_actions = {}

documentation      = [==[asdf]==]

-- Initialize as agent module
agentenv.agent_module(...)

local preds = require("herb_agents.predicates.general")
local Skill = AgentSkillExecJumpState

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds},
  {"START", Skill, skills={{"say", text="Have you finished?"}}, 
          final_state="GET_HRI_INPUT", failure_state="GET_HRI_INPUT"},
  {"GET_HRI_INPUT", JumpState},
  {"FINAL", JumpState},
  {"FAILED", JumpState},
}

fsm:add_transitions{
  {"GET_HRI_INPUT", "FINAL", "p.HRI_yes"},
  {"GET_HRI_INPUT", "FAILED", "p.HRI_no"},
}

