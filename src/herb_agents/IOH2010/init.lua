
----------------------------------------------------------------------------
--  init.lua - Intel Open House 2010 Agent
--
--  Created: Mon Sep 06 14:11:54 2010
--  Copyright  2010  Tim Niemueller [www.niemueller.de]
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

-- Initialize module
module(..., agentenv.module_init)

-- Crucial skill information
name               = "IOH2010"
fsm                = AgentHSM:new{name=name, debug=true, start="START"}
depends_skills     = {"grab", "lockenv", "releasenv", "pickup"}

documentation      = [==[Intel Open House 2010.
]==]

-- Initialize as agent module
agentenv.agent_module(...)

-- Setup FSM
fsm:define_states{ export_to=_M,
   {"START", JumpState},
   {"LOCK", AgentSkillExecJumpState, skills={{"lockenv"}}},
   {"GRAB", AgentSkillExecJumpState, skills={{"grab"}}},
   {"PICKUP", AgentSkillExecJumpState, skills={{"pickup"}}},
   {"RELEASE", AgentSkillExecJumpState, skills={{"releaseenv"}}},
   {"DONE", JumpState},
   {"FAILED", JumpState}
}

fsm:add_transitions{
   {"LOCK", "GRAB", AgentSkillExecJumpState.final},
   {"LOCK", "FAILED", AgentSkillExecJumpState.failed},
   {"GRAB", "PICKUP", AgentSkillExecJumpState.final},
   {"GRAB", "FAILED", AgentSkillExecJumpState.failed},
   {"PICKUP", "RELEASE", AgentSkillExecJumpState.final},
   {"PICKUP", "FAILED", AgentSkillExecJumpState.failed},
   {"RELEASE", "DONE", AgentSkillExecJumpState.final},
   {"RELEASE", "FAILED", AgentSkillExecJumpState.failed}
}
