
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
depends_skills     = {"grab", "lockenv", "releasenv", "pickup", "handoff", "turn"}
depends_topics     = {
   { v="doorbell", name="/callbutton",            type="std_msgs/Byte" },
   { v="objects",  name="/manipulation/obj_list", type="manipulationapplet/ObjectActions", latching=true }
}

documentation      = [==[Intel Open House 2010.
]==]

-- Initialize as agent module
agentenv.agent_module(...)

local utils = require("herb_agents.utils")

-- Setup FSM
fsm:define_states{ export_to=_M,
   closure={doorbell=doorbell},
   {"START", JumpState},
   {"RECOVER", JumpState},
   {"WAIT_OBJECT", JumpState},
   {"LOCK", AgentSkillExecJumpState, skills={{"lockenv"}}, final_state="GRAB", failure_state="RECOVER"},
   {"GRAB", AgentSkillExecJumpState, final_state="PICKUP", failure_state="RECOVER", skills={{"grab"}}},
   {"PICKUP", AgentSkillExecJumpState, final_state="RELEASE", failure_state="RECOVER", skills={{"pickup"}}},
   {"RELEASE", AgentSkillExecJumpState, skills={{"releaseenv"}}, final_state="HANDOFF", failure_state="RECOVER"},
   {"HANDOFF", AgentSkillExecJumpState, skills={{"handoff"}}, final_state="START", failure_state="RECOVER"},
   --{"TURN_RECYCLE", AgentSkillExecJumpState, skills={{"turn", angle_rad=math.pi}},
   -- final_state="PUT_RECYCLE", failure_state="RECOVER"},
   --{"PUT_RECYCLE", AgentSkillExecJumpState, skills={{"put", object_id={"recycle_bin"}}},
   -- final_state="PUT_RECYCLE", failure_state="RECOVER"},
}

fsm:add_transitions{
   {"START", "WAIT_OBJECT", "#doorbell.messages > 0"},
   {"WAIT_OBJECT", "LOCK", "vars.found_object"},
   {"WAIT_OBJECT", "RECOVER", timeout=10},
   {"RECOVER", "START", timeout=10}
}

function WAIT_OBJECT:loop()
   if #objects.messages > 0 then
      print("Got a message")
      local m = objects.messages[#objects.messages] -- only check most recent
      for i,o in ipairs(m.values.object_id) do
         printf("Comparing %s / %s / %s", o, m.values.poss_act[i], m.values.side[i])
         if o:match("fuze_bottle[%d]*") and m.values.poss_act[i] == "grab" then
            self.fsm.vars.side         = m.values.side[i]
            self.fsm.vars.object_id    = o
            self.fsm.vars.found_object = true
            break
         end
      end 
   end
end

function GRAB:init()
   self.skills[1].args = {side=self.fsm.vars.side, object_id=self.fsm.vars.object_id}
end
PICKUP.init  = GRAB.init
HANDOFF.init = GRAB.init

function RECOVER:init()
   if self.fsm.error and self.fsm.error ~= "" then
      print_warn("Error: %s", self.fsm.error)
   end
end
