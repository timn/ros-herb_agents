
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
depends_skills     = {"grab", "lockenv", "releasenv", "pickup", "handoff", "turn", "take"}
depends_topics     = {
   { v="doorbell", name="/callbutton",               type="std_msgs/Byte" },
   { v="objects",  name="/manipulation/obj_list",    type="manipulationapplet/ObjectActions", latching=true },
   { v="envlock",  name="/manipulation/env/locked",  type="std_msgs/Bool", latching=true },
   { v="grabbed",  name="/manipulation/grabbed_obj", type="manipulationapplet/GrabbedObjects", latching=true },
}

documentation      = [==[Intel Open House 2010.
]==]

-- Initialize as agent module
agentenv.agent_module(...)

local HOME_POS = "counter1"
local QUICKJUMP = "WEIGH"
local FIXED_SIDE = "right"

local Skill = AgentSkillExecJumpState
local utils = require("herb_agents.utils")

-- Setup FSM
fsm:define_states{ export_to=_M,
   closure={doorbell=doorbell, envlock=envlock},
   {"START", JumpState},
   {"RECOVER", JumpState},
   {"RECOVER_RELEASE", Skill, skills={{"releaseenv"}, {"goinitial"}},
      final_state="RECOVER", failure_state="RECOVER"},
   {"GOTO_COUNTER1", Skill, skills={{"goto", place="counter1"}, {"say", text="Going to counter 1"}},
      final_state="WAIT_OBJECT", failure_state="GOTO_COUNTER1"},
      --final_state="GOTO_STATION1", failure_state="RECOVER"},
   {"WAIT_OBJECT", JumpState},
   {"OBJECT_NOT_VISIBLE", Skill, skills={{"say", text="I cannot see the object, please help."}},
      final_state="WAIT_OBJECT", failure_state="WAIT_OBJECT"},
   {"GRAB", Skill, final_state="GOTO_STATION1", failure_state="GRAB_TRYAGAIN",
      skills={{"grab_object"}}},
   {"GRAB_TRYAGAIN", Skill, final_state="WAIT_OBJECT", failure_state="WAIT_OBJECT",
      skills={{"say", text="Oops, grasping failed, trying again."}}},
   {"GOTO_STATION1", Skill, skills={{"goto", place="station1"}, {"say", text="Going to recycling bin"}},
      final_state="HANDOFF", failure_state="RECOVER"},
      --final_state="TURN_LEFT_STATION1_PLACE", failure_state="RECOVER"},
   {"HANDOFF", Skill, skills={{"handoff"}, {"say", text="Here is the drink, please take it!"}},
      --final_state="RETRACT_ARM_HANDOFF", failure_state="TURN_LEFT_STATION1_PLACE"},
      final_state="RETRACT_ARM_HANDOFF", failure_state="RETRACT_ARM_HANDOFF"},
   {"RETRACT_ARM_HANDOFF", Skill, skills={{"goinitial"}},
      final_state="TAKE", failure_state="RECOVER"},
   --{"TURN_LEFT_STATION1_PLACE", Skill, skills={{"turn", angle_rad=math.pi/2.}},
   --   final_state="PUT_TABLE", failure_state="RECOVER"},
      --final_state="TURN_RIGHT_STATION1", failure_state="RECOVER"},
   --{"PUT_TABLE", Skill, skills={{"put"}, {"say", text="Placing bottle on table."}},
   --   final_state="RETRACT_ARM_STATION1", failure_state="RECOVER"},
   --{"RETRACT_ARM_STATION1", Skill, skills={{"goinitial"}},
   --   final_state="TURN_RIGHT_STATION1_PLACE", failure_state="RECOVER"},
   --{"TURN_RIGHT_STATION1_PLACE", Skill, skills={{"turn", angle_rad=-math.pi/2.}},
   --   final_state="TAKE", failure_state="RECOVER"},
      --final_state="GOTO_COUNTER2", failure_state="RECOVER"},
   {"TAKE", Skill, skills={{"take"}, {"say", text="Please give me a bottle to take back."}},
      final_state="GOTO_COUNTER2", failure_state="GOTO_COUNTER2"},
      --final_state="GOTO_COUNTER2", failure_state="TURN_LEFT_STATION1_PRE_GRAB"},
   --{"TURN_LEFT_STATION1_PRE_GRAB", Skill, skills={{"turn", angle_rad=math.pi/2.}},
   --   final_state="WAIT_OBJECTS_STATION1", failure_state="RECOVER"},
   --{"WAIT_OBJECTS_STATION1", JumpState},
   --{"GRAB_STATION1", Skill, final_state="TURN_LEFT_STATION1_POST_GRAB", failure_state="RECOVER",
   --   skills={{"grab_object"}}},
   --{"TURN_LEFT_STATION1_POST_GRAB", Skill, skills={{"turn", angle_rad=math.pi/2.}},
   --   final_state="GOTO_COUNTER2", failure_state="RECOVER"},
   {"GOTO_COUNTER2", Skill, skills={{"goto", place="counter2"}, {"say", text="Going to home position."}},
      final_state="WEIGH", failure_state="RECOVER"},
   {"WEIGH", Skill, skills={{"weigh"}, {"say", text="Weighing the object."}},
      final_state="DECIDE_WEIGHT", failure_state="UNKNOWN_WEIGHT"},
   {"DECIDE_WEIGHT", JumpState},
   {"UNKNOWN_WEIGHT", Skill, skills={{"say", text="Cannot determine weight, assuming empty bottle"}},
      final_state="TURN_RIGHT_COUNTER2_PRE_PUT", failure_state="RECOVER"},
   {"TURN_RIGHT_COUNTER2_PRE_PUT", Skill, skills={{"turn", angle_rad=-math.pi/2.}},
      final_state="PUT_RECYCLE", failure_state="RECOVER"},
      --final_state="TURN_LEFT_COUNTER2", failure_state="RECOVER"},
   {"PUT_RECYCLE", Skill, skills={{"put"}, {"say", text="Saving the world, one bottle at a time"}},
      final_state="RETRACT_ARM_COUNTER2", failure_state="RECOVER"},
   {"RETRACT_ARM_COUNTER2", Skill, skills={{"goinitial"}},
      final_state="TURN_RIGHT_COUNTER2_POST", failure_state="RECOVER"},
   -- ATTENTION: turning left atm for testing
   {"TURN_RIGHT_COUNTER2_POST", Skill, skills={{"turn", angle_rad=math.pi/2.}},
      final_state="START", failure_state="RECOVER"},
   --{"PLACE_COUNTER2", Skill, skills={{"place"}, {"say", text="Saving the world, one bottle at a time"}},
   --   final_state="RETRACT_ARM_COUNTER2", failure_state="RECOVER"},
   {"HANDOFF_FULL", Skill, skills={{"handoff"}, {"say", text="Full bottle, please take!"}},
      --final_state="RETRACT_ARM_HANDOFF", failure_state="TURN_LEFT_STATION1_PLACE"},
      final_state="START", failure_state="START"},
}

fsm:add_transitions{
   {"START", QUICKJUMP or "GOTO_COUNTER1", "#doorbell.messages > 0"},
   {"WAIT_OBJECT", "GRAB", "vars.found_object"},
   {"WAIT_OBJECT", "OBJECT_NOT_VISIBLE", timeout=20},
   --{"WAIT_OBJECTS_STATION1", "GRAB_STATION1", "vars.found_objects"},
   --{"WAIT_OBJECTS_STATION1", "RECOVER", timeout=10},
   {"DECIDE_WEIGHT", "UNKNOWN_WEIGHT", "vars.weight ~= nil and vars.weight == -1"},
   {"DECIDE_WEIGHT", "TURN_RIGHT_COUNTER2_PRE_PUT", "vars.weight ~= nil and vars.weight < 9"},
   {"DECIDE_WEIGHT", "HANDOFF_FULL", "vars.weight ~= nil and vars.weight >= 9"},
   {"RECOVER", "START", timeout=5},
   {"RECOVER", "RECOVER_RELEASE", "#envlock.messages > 0 and envlock.messages[1].values.data", precond_only=true},
}

function START:init()
   self.fsm:reset_trace()
   for k,_ in pairs(self.fsm.vars) do
      self.fsm.vars[k] = nil
   end
end

function WAIT_OBJECT:init()
   self.fsm.vars.found_object = false
end

function WAIT_OBJECT:loop()
   if #objects.messages > 0 then
      local m = objects.messages[#objects.messages] -- only check most recent
      for i,o in ipairs(m.values.object_id) do
         --printf("Comparing %s / %s / %s", o, m.values.poss_act[i], m.values.side[i])
         if o:match("fuze_bottle[%d]*") and m.values.poss_act[i] == "grab"
	 and not FIXED_SIDE or m.values.side[i] == FIXED_SIDE
	 then
            self.fsm.vars.side         = m.values.side[i]
            self.fsm.vars.object_id    = o
            self.fsm.vars.found_object = true
            break
         end
      end 
   end
end

function DECIDE_WEIGHT:loop()
   if #grabbed.messages > 0 then
      local m = grabbed.messages[#grabbed.messages] -- only check most recent
      if m.values.left_object_id:match("fuze_bottle[%d]*") and m.values.left_weight ~= -1 then
	 self.fsm.vars.weight = m.values.left_weight
      elseif m.values.right_object_id:match("fuze_bottle[%d]*") and m.values.right_weight ~= -1 then
	 self.fsm.vars.weight = m.values.right_weight
      --else
	-- self.fsm.vars.weight = -1
      end
   end
end

function GRAB:init()
   print_warn("Setting side for %s", self.name)
   self.skills[1].args = {side=self.fsm.vars.side or FIXED_SIDE, object_id=self.fsm.vars.object_id}
end
--RETRACT_ARM_STATION1.init = GRAB.init
RETRACT_ARM_HANDOFF.init = GRAB.init
RETRACT_ARM_COUNTER2.init = GRAB.init

function HANDOFF:init()
   self.skills[1].args = {side=self.fsm.vars.side or FIXED_SIDE, exec_timelimit=15}
end
TAKE.init = HANDOFF.init

function WEIGH:init()
   self.skills[1].args = {side=self.fsm.vars.side or FIXED_SIDE}
end
HANDOFF_FULL.init = WEIGH.init

function PUT_RECYCLE:init()
   self.skills[1].args = {side=self.fsm.vars.side or FIXED_SIDE, object_id="recyclingbin2"}
end

function RECOVER:init()
   if self.fsm.error and self.fsm.error ~= "" then
      print_warn("Error: %s", self.fsm.error)
   end
end

function RECOVER_RELEASE:init()
   self.skills[2].args = {side=self.fsm.vars.side or FIXED_SIDE}
end
