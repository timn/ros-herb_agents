
----------------------------------------------------------------------------
--  IOH2010.lua - Intel Open House 2010 Agent
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
name               = "IOH2010"
fsm                = AgentHSM:new{name=name, debug=true, start="START", recover_state="RECOVER"}
depends_skills     = {"grab", "lockenv", "releasenv", "pickup", "handoff", "turn", "take", "give"}
depends_topics     = {
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
local TAKE_SIDE="left"

local Skill = AgentSkillExecJumpState
local utils = require("herb_agents.utils")
local preds = require("herb_agents.predicates.general")


TEXTS_HANDOFF = {"Here is your drink, please take it.", "Here you are, please take the drink.",
		 "Please take the drink.", "Here you go.", "Would you like a drink? Then please take it.",
		 "Fuze has five calories. Only Five. Please take it.",
		 "Good taste, five calories. Please take it."}
TEXTS_PLACE_STATION1 = {"Let me put this down.", "I will leave it on the table in case someone wants it later.",
			"Let me put this on the table."}
TEXTS_TAKE = {"Please give me an empty bottle.", "Do you have any empty bottles?",
	      "I can recycle something for you.", "Do you have an empty bottle to take back?"}
TEXTS_WEIGH = { "I wonder how much this weighs.", "Let me check how much this weighs.",
		"I wonder if this is empty." }
TEXTS_UNKOWN_WEIGHT = {"This feels full. But I'm not sure.", "This one might be full.",
		       "Sometimes it's hard to tell.", "I cannot tell if this is full.",
		       "Cannot determine weight, assuming full bottle."}
TEXTS_PUT_RECYCLE = {"Saving the world, one bottle at a time.",
		     "That is the most satisfying part of my job.",
		     "Saving the environment is so much fun.", "I do not know why people drink so much.",
		     "I need a raise for all these bottles.", "I need to buy another recycling bin."}

-- Setup FSM
fsm:define_states{ export_to=_M,
   closure={envlock=envlock, p=preds},
   {"START", JumpState},
   {"FINAL", JumpState},
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
   {"GRAB", Skill, final_state="DETERMINE_SIDE", failure_state="GRAB_TRYAGAIN",
      skills={{"grab_object", object_id=OBJECT_PATTERN}}},
   {"DETERMINE_SIDE", JumpState},
   {"GRAB_TRYAGAIN", Skill, final_state="GRAB", failure_state="GRAB",
      skills={{"say", text="Oops, grasping failed, trying again."}}}, -- , {"goinitial", side="left"}
   --{"GRAB_TRYAGAIN_RIGHT", Skill, final_state="GRAB", failure_state="FAILED_RELAX_LEFT", skills={{"goinitial", side="right"}}},
   {"GOTO_STATION1", Skill, skills={{"goto", place="station1"}, {"say", text="Delivering the drink."}},
      final_state="HANDOFF", failure_state="RECOVER_MOTION"},
      --final_state="TURN_LEFT_STATION1_PLACE", failure_state="RECOVER"},
   {"HANDOFF", Skill, skills={{"give"}, {"say"}},
      --final_state="RETRACT_ARM_HANDOFF", failure_state="TURN_LEFT_STATION1_PLACE"},
      final_state="RETRACT_ARM_HANDOFF", failure_state="TURN_LEFT_STATION1_PLACE"},
   {"RETRACT_ARM_HANDOFF", Skill, skills={{"goinitial"}},
      final_state="TAKE", failure_state="FAILED_RELAX_LEFT"},
   {"TURN_LEFT_STATION1_PLACE", Skill,
      skills={{"turn", angle_rad=math.pi/2.}, {"say"}},
      final_state="ANNOUNCE_WAIT_STATION1", failure_state="RECOVER"},
   {"ANNOUNCE_WAIT_STATION1", Skill, skills={{"say", text="Scanning the environment."}},
      final_state="WAIT_STATION1", failure_state="WAIT_STATION1"},
   {"WAIT_STATION1", JumpState},
      --final_state="TURN_RIGHT_STATION1", failure_state="RECOVER"},
   {"PLACE_STATION1", Skill, skills={{"place"}},
      final_state="RETRACT_ARM_STATION1", failure_state="RETRACT_ARM_STATION1"},
   {"RETRACT_ARM_STATION1", Skill, skills={{"goinitial"}},
      final_state="TURN_RIGHT_STATION1_PLACE", failure_state="FAILED_RELAX_LEFT"},
   {"TURN_RIGHT_STATION1_PLACE", Skill, skills={{"turn", angle_rad=-math.pi/2.}},
      final_state="TAKE", failure_state="TAKE"},
      --final_state="GOTO_COUNTER2", failure_state="RECOVER"},
   {"TAKE", Skill,
      skills={{"take", side=TAKE_SIDE, exec_timelimit=5}, {"say"}},
      final_state="TAKE_RETRACT", failure_state="RETRACT_ARM_STATION1_EMPTY"},
      --final_state="GOTO_COUNTER2", failure_state="TURN_LEFT_STATION1_PRE_GRAB"},
   {"TAKE_RETRACT", Skill,
      skills={{"pickup", side=TAKE_SIDE}, {"say", text="Going to the counter. Watch out for my ell boh while I turn."}},
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
   {"RETRACT_ARM_STATION1_EMPTY", Skill, skills={{"goinitial", side=TAKE_SIDE}},
      final_state="GOTO_COUNTER2_EMPTY", failure_state="FAILED_RELAX_LEFT"},
   {"GOTO_COUNTER2_EMPTY", Skill,
      skills={{"goto", place="counter2"}, {"say", text="Going back to the counter without a bottle."}},
      final_state="FINAL", failure_state="RECOVER_MOTION"},
   {"WEIGH", Skill, skills={{"weigh", side=TAKE_SIDE}, {"say"}},
      final_state="DECIDE_WEIGHT", failure_state="UNKNOWN_WEIGHT"},
   {"DECIDE_WEIGHT", JumpState},
   {"UNKNOWN_WEIGHT", Skill, skills={{"say"}}, final_state="PLACE_FULL", failure_state="PLACE_FULL"},
   {"TURN_RIGHT_COUNTER2", Skill,
      skills={{"turn", angle_rad=-math.pi/2.}, {"say", text="The bottle is empty, going to recycle."}},
      final_state="ANNOUNCE_WAIT_RECYCLE", failure_state="RECOVER_MOTION"},
      --final_state="TURN_LEFT_COUNTER2", failure_state="RECOVER"},
   {"ANNOUNCE_WAIT_RECYCLE", Skill, skills={{"say", text="Scanning the environment."}},
      final_state="WAIT_RECYCLE", failure_state="WAIT_RECYCLE"},
   {"WAIT_RECYCLE", JumpState},
   {"PUT_RECYCLE", Skill,
      skills={{"put", side=TAKE_SIDE, object_id="recyclingbin2"}, {"say"}},
      final_state="RETRACT_ARM_COUNTER2", failure_state="GIVE_RECYCLE"},
   {"GIVE_RECYCLE", AgentSkillExecJumpState, final_state="RETRACT_ARM_COUNTER2", failure_state="FAILED_RELAX_LEFT",
      skills={{"give", side=TAKE_SIDE}, {"say", text="Cannot reach the recycling bin. Please take."}}},
   {"RETRACT_ARM_COUNTER2", Skill, skills={{"goinitial", side=TAKE_SIDE}},
      final_state="TURN_LEFT_COUNTER2", failure_state="FAILED_RELAX_LEFT"},
   {"TURN_LEFT_COUNTER2", Skill, skills={{"turn", angle_rad=math.pi/2.}},
      final_state="FINAL", failure_state="RECOVER_MOTION"},
   --{"PLACE_COUNTER2", Skill, skills={{"place"}, {"say", text="Saving the world, one bottle at a time"}},
   --   final_state="RETRACT_ARM_COUNTER2", failure_state="RECOVER"},
   --{"HANDOFF_FULL", Skill, skills={{"give"}, {"say", text="Full bottle, please take!"}},
      --final_state="RETRACT_ARM_HANDOFF", failure_state="TURN_LEFT_STATION1_PLACE"},
   --   final_state="TURN_RIGHT_COUNTER2_POST", failure_state="TURN_RIGHT_COUNTER2_POST"},
   {"PLACE_FULL", Skill,
      skills={{"place", side=TAKE_SIDE, object_id="tabletop1"},
	      {"say", text="Full bottle, putting back on the table!"}},
      --final_state="RETRACT_ARM_HANDOFF", failure_state="TURN_LEFT_STATION1_PLACE"},
      final_state="GOINITIAL_FULL", failure_state="FAILED_RELAX_LEFT"},
   {"GOINITIAL_FULL", Skill, skills={{"goinitial", side=TAKE_SIDE}},
      final_state="FINAL", failure_state="FAILED_RELAX_LEFT"},
   {"FAILED_RELAX_LEFT", AgentSkillExecJumpState,
    skills={{"relax_arm", side="left"}, {"say", text="User assistance required. Please help."}},
    final_state="FAILED_RELAX_RIGHT", failure_state="FAILED_RELAX_RIGHT"},
   {"FAILED_RELAX_RIGHT", AgentSkillExecJumpState, skills={{"relax_arm", side="right"}},
    final_state="FAILED", failure_state="FAILED"},
   {"FAILED_GOINITIAL_LEFT", AgentSkillExecJumpState, skills={{"goinitial", side="left"}},
    final_state="FAILED_GOINITIAL_RIGHT", failure_state="FAILED_GOINITIAL_RIGHT"},
   {"FAILED_GOINITIAL_RIGHT", AgentSkillExecJumpState, skills={{"goinitial", side="right"}},
    final_state="FINAL", failure_state="FINAL"},
}

fsm:add_transitions{
   {"START", QUICKJUMP or "GRAB_ANNOUNCE", "p.start_button"},
   {"FINAL", "START", "p.start_button"},
   {"FINAL", "GRAB_ANNOUNCE", timeout=5},
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
   {"FAILED", "FAILED_GOINITIAL_LEFT", "p.start_button"},
}

function random_text(texts)
   return texts[math.random(#texts)]
end


function START:init()
   self.fsm:reset_trace()
   for k,_ in pairs(self.fsm.vars) do
      self.fsm.vars[k] = nil
   end
end
FINAL.init = START.init

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
   self.skills[1].args = {side=self.fsm.vars.side, exec_timelimit=10}
   self.skills[2].args = {text=random_text(TEXTS_HANDOFF)}
end

function TAKE:init()
   self.skills[2].args = {text=random_text(TEXTS_TAKE)}
end

function TURN_LEFT_STATION1_PLACE:init()
   self.skills[2].args = {text=random_text(TEXTS_PLACE_STATION1)}
end

function PLACE_STATION1:init()
   self.skills[1].args = {side=self.fsm.vars.side, object_id="tabletop2"}
end

function WEIGH:init()
   self.skills[2].args = {text=random_text(TEXTS_WEIGH)}
end

function UNKNOWN_WEIGHT:init()
   self.skills[1].args = {text=random_text(TEXTS_UNKNOWN_WEIGHT)}
end

--function PLACE_FULL:init()
--   self.skills[1].args = {side=self.fsm.vars.side, object_id="tabletop1"}
--end

function PUT_RECYCLE:init()
   self.skills[2].args = {text=random_text(TEXTS_PUT_RECYCLE)}
end

function RECOVER:init()
   if self.fsm.error and self.fsm.error ~= "" then
      print_warn("Error: %s", self.fsm.error)
   end
end

function RECOVER_RELEASE:init()
   self.skills[2].args = {side=self.fsm.vars.side}
end
