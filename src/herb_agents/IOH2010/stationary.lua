
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
   { v="doorbell", name="/callbutton",              type="std_msgs/Byte" },
   { v="objects",  name="/manipulation/obj_list",   type="manipulationapplet/ObjectActions", latching=true },
   { v="envlock",  name="/manipulation/env/locked", type="std_msgs/Bool", latching=true },
}

documentation      = [==[Intel Open House 2010.
]==]

-- Initialize as agent module
agentenv.agent_module(...)

local utils = require("herb_agents.utils")

-- Setup FSM
fsm:define_states{ export_to=_M,
   closure={doorbell=doorbell, envlock=envlock},
   {"START", JumpState},
   {"RECOVER", JumpState},
   {"RECOVER_RELEASE", AgentSkillExecJumpState, skills={{"releaseenv"}, {"goinitial"}}, final_state="RECOVER", failure_state="RECOVER"},
   {"ANNOUNCE_DETECT", AgentSkillExecJumpState, final_state="WAIT_OBJECT", failure_state="WAIT_OBJECT",
      skills={{"say", text="Detecting bottle."}}},
   {"WAIT_OBJECT", JumpState},
   {"GRAB", AgentSkillExecJumpState, final_state="TURN", failure_state="RECOVER",
      skills={{"grab_object"}, {"say", text="Grabbing the bottle"}}},
   {"TURN", AgentSkillExecJumpState, skills={{"turn", angle_rad=-math.pi/2.}},
      final_state="PUT_RECYCLE", failure_state="RECOVER"},
   {"PUT_RECYCLE", AgentSkillExecJumpState, final_state="GOINITIAL", failure_state="RECOVER",
    skills={{"put"}, {"say", text="Saving the world. One bottle at a time."}}},
   {"GOINITIAL", AgentSkillExecJumpState, skills={{"goinitial"}}, final_state="TURN_BACK", failure_state="RECOVER"},
   {"TURN_BACK", AgentSkillExecJumpState, skills={{"turn", angle_rad=math.pi/2.}},
    final_state="START", failure_state="RECOVER"},
}

fsm:add_transitions{
   {"START", "ANNOUNCE_DETECT", "#doorbell.messages > 0"},
   {"WAIT_OBJECT", "GRAB", "vars.found_object"},
   {"WAIT_OBJECT", "RECOVER", timeout=10},
   {"RECOVER", "START", timeout=5},
   {"RECOVER", "RECOVER_RELEASE", "#envlock.messages > 0 and envlock.messages[1].values.data", precond_only=true},
}

function START:init()
   self.fsm:reset_trace()
   for k,_ in pairs(self.fsm.vars) do
      self.fsm.vars[k] = nil
   end
end

function WAIT_OBJECT:loop()
   if #objects.messages > 0 then
      local m = objects.messages[#objects.messages] -- only check most recent
      for i,o in ipairs(m.values.object_id) do
         --printf("Comparing %s / %s / %s", o, m.values.poss_act[i], m.values.side[i])
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
GOINITIAL.init = GRAB.init
--HANDOFF.init = GRAB.init

function PUT_RECYCLE:init()
   self.skills[1].args = {side=self.fsm.vars.side, object_id="recyclingbin2"}
end

function RECOVER:init()
   if self.fsm.error and self.fsm.error ~= "" then
      print_warn("Error: %s", self.fsm.error)
   end
end

function RECOVER_RELEASE:init()
   self.skills[2].args = {side=self.fsm.vars.side}
end
