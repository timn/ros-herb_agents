
----------------------------------------------------------------------------
--  IOH2010.lua - Intel Open House 2010 Agent
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
fsm                = AgentHSM:new{name=name, debug=true, start="START", recover_state="RECOVER"}
depends_skills     = {"grab", "lockenv", "releasenv", "pickup"}
depends_topics     = {
   { v="doorbell", name="/callbutton", type="std_msgs/Byte" }
}

documentation      = [==[Intel Open House 2010.
]==]

-- Initialize as agent module
agentenv.agent_module(...)

-- Setup FSM
fsm:define_states{ export_to=_M,
   closure={doorbell=doorbell},
   {"START", JumpState},
   {"RECOVER", JumpState},
   {"LOCK", AgentSkillExecJumpState, skills={{"lockenv"}},
    final_state="GRAB", failure_state="RECOVER"},
   {"GRAB", AgentSkillExecJumpState, final_state="PICKUP", failure_state="RECOVER",
    skills={{"grab", side="left", object_id="poptarts"},{"noop", side="right"}}},
   {"PICKUP", AgentSkillExecJumpState, final_state="RELEASE", failure_state="RECOVER",
    skills={{"pickup", side="left"}, {"noop", side="right"}}},
   {"RELEASE", AgentSkillExecJumpState, skills={{"releaseenv"}},
    final_state="DONE", failure_state="RECOVER"},
   {"DONE", JumpState},
}

fsm:add_transitions{
   {"START", "LOCK", "#doorbell.messages > 0"},
   {"RECOVER", "START", timeout=10}
}

function RECOVER:init()
   if self.fsm.error and self.fsm.error ~= "" then
      print_warn("Error: %s", self.fsm.error)
   end
end
