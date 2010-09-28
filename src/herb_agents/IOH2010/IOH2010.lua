
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
depends_skills     = {"grab", "lockenv", "releasenv", "pickup", "handoff", "turn", "take", "give"}
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
--local QUICKJUMP = "WEIGH"
OBJECT_PATTERN="fuze_bottle[%d]*"

local Skill = AgentSkillExecJumpState
local utils = require("herb_agents.utils")


TEXT_DRIVING_COUNTER1 = {"Driving to the counter.","Going to the counter.","Lets see what we have at the counter."}
TEXT_DRIVING_RECYCLINGBIN = {"Driving to the recycling bin.","Going to the recycling bin.","I'm going to recycle this.", "Recycling", "I will be right back", "A good robot always recycles", "I need to trash this", "I hope you liked the drink"}
TEXT_GIVEDRINK = {"Here is your drink, please take it.","Here you are, please take the drink.", "Please take the drink", "Here you go", "Would you like a drink", "I like this drink", "Fuze for you", "Fuze has five calories. Just five. Not six. Not four. Five.", "Good taste, five calories"}
TEXT_PLACE = {"Let me put this down.","Let me put this on the table."}
TEXT_GIVEME = {"Please give me an empty bottle.", "Do you have any empty bottles", "I can recycle something for you"}
TEXT_HOME = {"Going to home position."}
TEXT_WEIGHT = {"I wonder how much this weighs.","Let me check how much this weighs.", "I wonder if this is empty"}
TEXT_UNKOWNWEIGHT = {"This feels empty. But I'm not sure", "This one might be empty", "Sometimes it's hard to tell", "I cannot tell if this is empty"}
TEXT_PUTRECYCLE = {"Saving the world, one bottle at a time","That is the most satisfying part of my job", "Saving the environment is so much fun","I do not know why people drink so much", "I need a raise", "I need to buy another recycling bin"}

-- Setup FSM
fsm:define_states{ export_to=_M,
   closure={doorbell=doorbell, envlock=envlock},
   {"START", JumpState},
   {"FAILED", JumpState},
   {"RECOVER", JumpState},
   {"RECOVER_RELEASE", Skill, skills={{"releaseenv"}, {"goinitial"}},
      final_state="RECOVER", failure_state="RECOVER"},
   {"RECOVER_MOTION", Skill, skills={{"say", text="Motion component disabled. Cannot drive. Please help."}},
      final_state="RECOVER", failure_state="RECOVER"},
   --{"GOTO_COUNTER2_START", Skill, skills={{"goto", place="counter2"}, {"say", text="Going to storage"}},
   --   final_state="GRAB", failure_state="RECOVER_MOTION"},
      --final_state="GOTO_STATION1", failure_state="RECOVER"},
   --{"WAIT_OBJECT", JumpState},
   {"OBJECT_NOT_VISIBLE", Skill, skills={{"say", text="I cannot see the object, please help."}},
      final_state="GRAB", failure_state="GRAB"},
   {"GRAB_ANNOUNCE", Skill, final_state="GRAB", failure_state="GRAB",
      skills={{"say", text="Let me get you a drink."}}},
   {"GRAB", Skill, final_state="DETERMINE_SIDE", failure_state="GRAB_TRYAGAIN_LEFT",
      skills={{"grab_object", object_id=OBJECT_PATTERN}}},
   {"DETERMINE_SIDE", JumpState},
   {"GRAB_TRYAGAIN_LEFT", Skill, final_state="GRAB_TRYAGAIN_RIGHT", failure_state="GRAB_TRYAGAIN_RIGHT",
      skills={{"say", text="Oops, grasping failed, trying again."}, {"goinitial", side="left"}}},
   {"GRAB_TRYAGAIN_RIGHT", Skill, final_state="GRAB", failure_state="GRAB", skills={{"goinitial", side="right"}}},
   {"GOTO_STATION1", Skill, skills={{"goto", place="station1"}, {"say", text="Delivering the drink."}},
      final_state="HANDOFF", failure_state="RECOVER_MOTION"},
      --final_state="TURN_LEFT_STATION1_PLACE", failure_state="RECOVER"},
   {"HANDOFF", Skill, skills={{"give"}, {"say", text="Here is the drink, please take it!"}},
      --final_state="RETRACT_ARM_HANDOFF", failure_state="TURN_LEFT_STATION1_PLACE"},
      final_state="RETRACT_ARM_HANDOFF", failure_state="TURN_LEFT_STATION1_PLACE"},
   {"RETRACT_ARM_HANDOFF", Skill, skills={{"goinitial"}},
      final_state="TAKE", failure_state="RECOVER"},
   {"TURN_LEFT_STATION1_PLACE", Skill,
      skills={{"turn", angle_rad=math.pi/2.},
              {"say", text="I will leave it on the table in case someone wants it later"}},
      final_state="WAIT_STATION1", failure_state="RECOVER"},
   {"WAIT_STATION1", JumpState},
      --final_state="TURN_RIGHT_STATION1", failure_state="RECOVER"},
   {"PLACE_STATION1", Skill, skills={{"place"}},
      final_state="RETRACT_ARM_STATION1", failure_state="RETRACT_ARM_STATION1"},
   {"RETRACT_ARM_STATION1", Skill, skills={{"goinitial"}},
      final_state="TURN_RIGHT_STATION1_PLACE", failure_state="TURN_RIGHT_STATION1_PLACE"},
   {"TURN_RIGHT_STATION1_PLACE", Skill, skills={{"turn", angle_rad=-math.pi/2.}},
      final_state="TAKE", failure_state="TAKE"},
      --final_state="GOTO_COUNTER2", failure_state="RECOVER"},
   {"TAKE", Skill,
      skills={{"take", side="right", exec_timelimit=5}, {"say", text="Do you have an empty bottle to take back?"}},
      final_state="TAKE_RETRACT", failure_state="RETRACT_ARM_STATION1_EMPTY"},
      --final_state="GOTO_COUNTER2", failure_state="TURN_LEFT_STATION1_PRE_GRAB"},
   {"TAKE_RETRACT", Skill,
      skills={{"pickup", side="right"}, {"say", text="Going to the counter. Watch out for my elbow while I turn."}},
      final_state="GOTO_COUNTER2", failure_state="GOTO_COUNTER2"},
   --{"TURN_LEFT_STATION1_PRE_GRAB", Skill, skills={{"turn", angle_rad=math.pi/2.}},
   --   final_state="WAIT_OBJECTS_STATION1", failure_state="RECOVER"},
   --{"WAIT_OBJECTS_STATION1", JumpState},
   --{"GRAB_STATION1", Skill, final_state="TURN_LEFT_STATION1_POST_GRAB", failure_state="RECOVER",
   --   skills={{"grab_object"}}},
   --{"TURN_LEFT_STATION1_POST_GRAB", Skill, skills={{"turn", angle_rad=math.pi/2.}},
   --   final_state="GOTO_COUNTER2", failure_state="RECOVER"},
   {"GOTO_COUNTER2", Skill, skills={{"goto", place="counter2"}},
      final_state="WEIGH", failure_state="RECOVER_MOTION"},
   {"RETRACT_ARM_STATION1_EMPTY", Skill, skills={{"goinitial", side="right"}},
      final_state="GOTO_COUNTER2_EMPTY", failure_state="GOTO_COUNTER2_EMPTY"},
   {"GOTO_COUNTER2_EMPTY", Skill,
      skills={{"goto", place="counter2"}, {"say", text="Going back to the counter without a bottle."}},
      final_state="START", failure_state="RECOVER_MOTION"},
   {"WEIGH", Skill, skills={{"weigh", side="right"}, {"say", text="Weighing the bottle."}},
      final_state="DECIDE_WEIGHT", failure_state="UNKNOWN_WEIGHT"},
   {"DECIDE_WEIGHT", JumpState},
   {"UNKNOWN_WEIGHT", Skill, skills={{"say", text="Cannot determine weight, assuming full bottle."}},
      final_state="PLACE_FULL", failure_state="PLACE_FULL"},
   {"TURN_RIGHT_COUNTER2", Skill,
      skills={{"turn", angle_rad=-math.pi/2.}, {"say", text="The bottle is empty, going to recycle."}},
      final_state="WAIT_RECYCLE", failure_state="RECOVER_MOTION"},
      --final_state="TURN_LEFT_COUNTER2", failure_state="RECOVER"},
   {"WAIT_RECYCLE", JumpState},
   {"PUT_RECYCLE", Skill,
      skills={{"put", side="right", object_id="recyclingbin2"},
	      {"say", text="Saving the world, one bottle at a time!"}},
      final_state="RETRACT_ARM_COUNTER2", failure_state="GIVE_RECYCLE"},
   {"GIVE_RECYCLE", AgentSkillExecJumpState, final_state="RETRACT_ARM_COUNTER2", failure_state="FAILED_RELAX_LEFT",
      skills={{"give", side="right"}, {"say", text="Cannot reach the recycling bin. Please take."}}},
   {"RETRACT_ARM_COUNTER2", Skill, skills={{"goinitial", side="right"}},
      final_state="TURN_LEFT_COUNTER2", failure_state="RECOVER"},
   {"TURN_LEFT_COUNTER2", Skill, skills={{"turn", angle_rad=math.pi/2.}},
      final_state="START", failure_state="RECOVER_MOTION"},
   --{"PLACE_COUNTER2", Skill, skills={{"place"}, {"say", text="Saving the world, one bottle at a time"}},
   --   final_state="RETRACT_ARM_COUNTER2", failure_state="RECOVER"},
   --{"HANDOFF_FULL", Skill, skills={{"give"}, {"say", text="Full bottle, please take!"}},
      --final_state="RETRACT_ARM_HANDOFF", failure_state="TURN_LEFT_STATION1_PLACE"},
   --   final_state="TURN_RIGHT_COUNTER2_POST", failure_state="TURN_RIGHT_COUNTER2_POST"},
   {"PLACE_FULL", Skill,
      skills={{"place", side="right", object_id="tabletop"},
	      {"say", text="Full bottle, putting back on the table!"}},
      --final_state="RETRACT_ARM_HANDOFF", failure_state="TURN_LEFT_STATION1_PLACE"},
      final_state="GOINITIAL_FULL", failure_state="FAILED_RELAX_LEFT"},
   {"GOINITIAL_FULL", Skill, skills={{"goinitial", side="right"}},
      final_state="START", failure_state="RECOVER"},
   {"FAILED_RELAX_LEFT", AgentSkillExecJumpState,
    skills={{"relax_arm", side="right"}, {"say", text="User assistance required. Please help."}},
    final_state="FAILED_RELAX_RIGHT", failure_state="FAILED_RELAX_RIGHT"},
   {"FAILED_RELAX_RIGHT", AgentSkillExecJumpState, skills={{"relax_arm", side="right"}},
    final_state="FAILED", failure_state="FAILED"},
   {"FAILED_GOINITIAL_LEFT", AgentSkillExecJumpState, skills={{"goinitial", side="left"}},
    final_state="FAILED_GOINITIAL_RIGHT", failure_state="FAILED_GOINITIAL_RIGHT"},
   {"FAILED_GOINITIAL_RIGHT", AgentSkillExecJumpState, skills={{"goinitial", side="right"}},
    final_state="START", failure_state="START"},
}

fsm:add_transitions{
   {"START", QUICKJUMP or "GRAB_ANNOUNCE", "#doorbell.messages > 0"},
   {"GRAB", "OBJECT_NOT_VISIBLE", "self.error == 'object not visible'"},
   --{"WAIT_OBJECT", "GRAB", "vars.found_object"},
   --{"WAIT_OBJECT", "OBJECT_NOT_VISIBLE", timeout=20},
   --{"WAIT_OBJECTS_STATION1", "GRAB_STATION1", "vars.found_objects"},
   --{"WAIT_OBJECTS_STATION1", "RECOVER", timeout=10},
   {"WAIT_STATION1", "PLACE_STATION1", timeout=5},
   {"PLACE_STATION1", "GOTO_COUNTER2", "self.error and self.error:match('.*Planner failed.*')"},
   {"DETERMINE_SIDE", "GOTO_STATION1", "vars.side_determined"},
   --{"DETERMINE_SIDE", "GOTO_STATION1", timeout=20},
   {"DECIDE_WEIGHT", "UNKNOWN_WEIGHT", "vars.weight ~= nil and vars.weight == -1"},
   {"DECIDE_WEIGHT", "TURN_RIGHT_COUNTER2", "vars.weight ~= nil and vars.weight < 4"},
   {"DECIDE_WEIGHT", "PLACE_FULL", "vars.weight ~= nil and vars.weight >= 4"},
   {"WAIT_RECYCLE", "PUT_RECYCLE", timeout=5},
   {"RECOVER", "START", timeout=5},
   {"RECOVER", "RECOVER_RELEASE", "#envlock.messages > 0 and envlock.messages[1].values.data", precond_only=true},
   {"FAILED", "FAILED_GOINITIAL_LEFT", "#doorbell.messages > 0"},
}

function START:init()
   self.fsm:reset_trace()
   for k,_ in pairs(self.fsm.vars) do
      self.fsm.vars[k] = nil
   end
end

--[[
function WAIT_OBJECT:init()
   self.fsm.vars.found_object = false
end

function WAIT_OBJECT:loop()
   if #objects.messages > 0 then
      local m = objects.messages[#objects.messages] -- only check most recent
      for i,o in ipairs(m.values.object_id) do
         --printf("Comparing %s / %s / %s", o, m.values.poss_act[i], m.values.side[i])
         if o:match("fuze_bottle[%d]*") and m.values.poss_act[i] == "grab"
	 and (not FIXED_SIDE or m.values.side[i] == FIXED_SIDE)
	 then
            self.fsm.vars.side         = m.values.side[i]
            self.fsm.vars.object_id    = o
            self.fsm.vars.found_object = true
            break
         end
      end 
   end
end
--]]

function DETERMINE_SIDE:loop()
   if #grabbed.messages > 0 then
      local m = grabbed.messages[#grabbed.messages] -- only check most recent
      print_debug("Comparing %s/%s to %s", m.values.left_object_id, m.values.right_object_id, OBJECT_PATTERN)
      if m.values.left_object_id:match(OBJECT_PATTERN) then
	 self.fsm.vars.side = "left"
	 self.fsm.vars.object_id = m.values.left_object_id
	 self.fsm.vars.side_determined = true
      elseif m.values.right_object_id:match(OBJECT_PATTERN) then
	 self.fsm.vars.side = "right"
	 self.fsm.vars.object_id = m.values.right_object_id
	 self.fsm.vars.side_determined = true
      end
   end
end

function DECIDE_WEIGHT:loop()
   if #grabbed.messages > 0 then
      local m = grabbed.messages[#grabbed.messages] -- only check most recent
      if m.values.left_object_id ~= "none" and m.values.left_weight ~= -1 then
	 self.fsm.vars.weight = m.values.left_weight
      elseif m.values.right_object_id  ~= "none" and m.values.right_weight ~= -1 then
	 self.fsm.vars.weight = m.values.right_weight
      --else
	-- self.fsm.vars.weight = -1
      end
   end
end

function RETRACT_ARM_HANDOFF:init()
   print_warn("Setting side for %s", self.name)
   self.skills[1].args = {side=self.fsm.vars.side}
end
RETRACT_ARM_STATION1.init = RETRACT_ARM_HANDOFF.init
--RETRACT_ARM_STATION1_EMPTY.init = RETRACT_ARM_HANDOFF.init
--RETRACT_ARM_COUNTER2.init = RETRACT_ARM_HANDOFF.init
--GOINITIAL_FULL.init = RETRACT_ARM_HANDOFF.init
--TAKE_RETRACT.init = RETRACT_ARM_HANDOFF.init

function HANDOFF:init()
   self.skills[1].args = {side=self.fsm.vars.side, exec_timelimit=5}
end
--TAKE.init = HANDOFF.init

function PLACE_STATION1:init()
   self.skills[1].args = {side=self.fsm.vars.side, object_id="tabletop2"}
end

--function WEIGH:init()
--   self.skills[1].args = {side=self.fsm.vars.side}
--end

--function PLACE_FULL:init()
--   self.skills[1].args = {side=self.fsm.vars.side, object_id="tabletop"}
--end

--function PUT_RECYCLE:init()
--   self.skills[1].args = {side=self.fsm.vars.side, object_id="recyclingbin2"}
--end

function RECOVER:init()
   if self.fsm.error and self.fsm.error ~= "" then
      print_warn("Error: %s", self.fsm.error)
   end
end

function RECOVER_RELEASE:init()
   self.skills[2].args = {side=self.fsm.vars.side}
end
