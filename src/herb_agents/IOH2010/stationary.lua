
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
   { v="doorbell", name="/callbutton",               type="std_msgs/Byte" },
   { v="grabbed",  name="/manipulation/grabbed_obj", type="manipulationapplet/GrabbedObjects", latching=true },
}

documentation      = [==[Intel Open House 2010.
]==]

-- Initialize as agent module
agentenv.agent_module(...)

OBJECT_PATTERN="fuze_bottle[%d]*"

local utils = require("herb_agents.utils")

-- Setup FSM
fsm:define_states{ export_to=_M,
   closure={doorbell=doorbell, envlock=envlock},
   {"START", JumpState},
   {"RECOVER", JumpState},
   {"RECOVER_RELEASE", AgentSkillExecJumpState, skills={{"releaseenv"}, {"goinitial"}}, final_state="RECOVER", failure_state="RECOVER"},
   {"ANNOUNCE_GRAB", AgentSkillExecJumpState, final_state="GRAB", failure_state="GRAB",
      skills={{"say", text="Detecting and grabbing bottle."}}},
   {"GRAB", AgentSkillExecJumpState, final_state="DETERMINE_SIDE", failure_state="GRAB",
      skills={{"grab_object"}}},
   {"DETERMINE_SIDE", JumpState},
   {"TURN", AgentSkillExecJumpState, skills={{"turn", angle_rad=-math.pi/2.}},
      final_state="PUT_RECYCLE", failure_state="RECOVER"},
   {"PUT_RECYCLE", AgentSkillExecJumpState, final_state="GOINITIAL", failure_state="RECOVER",
    skills={{"put"}, {"say", text="Saving the world. One bottle at a time."}}},
   {"GOINITIAL", AgentSkillExecJumpState, skills={{"goinitial"}}, final_state="TURN_BACK", failure_state="RECOVER"},
   {"TURN_BACK", AgentSkillExecJumpState, skills={{"turn", angle_rad=math.pi/2.}},
    final_state="START", failure_state="RECOVER"},
}

fsm:add_transitions{
   {"START", "ANNOUNCE_GRAB", "#doorbell.messages > 0"},
   {"DETERMINE_SIDE", "TURN", "vars.side_determined"},
   {"DETERMINE_SIDE", "RECOVER", timeout=20},
   {"RECOVER", "START", timeout=5},
   {"RECOVER", "RECOVER_RELEASE", "#envlock.messages > 0 and envlock.messages[1].values.data", precond_only=true},
}

function START:init()
   self.fsm:reset_trace()
   for k,_ in pairs(self.fsm.vars) do
      self.fsm.vars[k] = nil
   end
end

function DETERMINE_SIDE:loop()
   if #grabbed.messages > 0 then
      local m = grabbed.messages[#grabbed.messages] -- only check most recent
      if m.values.left_object_id:match(OBJECT_PATTERN) then
	 self.fsm.vars.side = "left"
	 self.fsm.vars.object_id = m.values.left_object_id
	 self.fsm.vars.side_determined = true
      elseif m.values.left_object_id:match(OBJECT_PATTERN) then
	 self.fsm.vars.side = "right"
	 self.fsm.vars.object_id = m.values.right_object_id
	 self.fsm.vars.side_determined = true
      end
   end
end

function GRAB:init()
   self.skills[1].args = {object_id=OBJECT_PATTERN}
end

function GOINITIAL:init()
   self.skills[1].args = {side=self.fsm.vars.side}
end
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
