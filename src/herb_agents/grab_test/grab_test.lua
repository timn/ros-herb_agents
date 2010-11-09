
----------------------------------------------------------------------------
--  init.lua - Grab object demo/test agent
--
--  Created: Mon Sep 06 14:11:54 2010
--  License: BSD, cf. LICENSE file
--  Copyright  2010  Tim Niemueller [www.niemueller.de]
--             2010  Carnegie Mellon University
--             2010  Intel Labs Pittsburgh
----------------------------------------------------------------------------

-- Initialize module
module(..., agentenv.module_init)

-- Crucial skill information
name               = "grab_object"
fsm                = AgentHSM:new{name=name, debug=true, start="START", recover_state="RECOVER"}
depends_skills     = {"grab", "lockenv", "releasenv", "pickup"}

documentation      = [==[Intel Open House 2010.
]==]

-- Initialize as agent module
agentenv.agent_module(...)

-- Setup FSM
fsm:define_states{ export_to=_M,
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
   {"START", "LOCK", true},
   {"RECOVER", "START", timeout=10}
}

function RECOVER:init()
   if self.fsm.error and self.fsm.error ~= "" then
      print_warn("Error: %s", self.fsm.error)
   end
end
