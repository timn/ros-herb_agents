
----------------------------------------------------------------------------
--  intro.lua - Intel Open House 2010 Intro Agent
--
--  Created: Tue Sep 14 13:27:09 2010
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
name               = "IOH2010_intro"
fsm                = AgentHSM:new{name=name, debug=true, start="START", recover_state="RECOVER"}
depends_skills     = {"say", "pose_goto", "pose_fromto", "reset_arms"}
depends_topics     = {
   { v="doorbell", name="/callbutton",              type="std_msgs/Byte" }
}

documentation      = [==[Intel Open House 2010.
Intro agent, showing off some robot features.
]==]

-- Initialize as agent module
agentenv.agent_module(...)

local utils = require("herb_agents.utils")
local Skill = AgentSkillExecJumpState

-- text constants for better readability of HSM
TEXT_GREET="Hello, I am HERB, the home exploring robot buttler. "..
   "Let me tell you a little about myself."
TEXT_ARM="I have two arms with seven degrees of freedom each. Planning "..
   "my motion is tough work, but I am quite good at it."
TEXT_HAND="These are my four degree of freedom hands."
TEXT_3DLASER="I use a 3D laser to perceive the environment and avoid unknown objects."
TEXT_PROSILICA="I recognize objects with this camera."
TEXT_OBLASER="My laser scannar helps me to avoid, obstacles while driving."
TEXT_GUTS="I have twelve, intel processors for motion planning, navigation, and vision"
TEXT_SEGWAY="I use a segway to move around."
TEXT_MOVEMENT="I can drive quite fast, but I usually don't, because it might scare you."
TEXT_GOODBYE="Now let me dazzle you, with my ability to serve drinks."


-- Setup FSM
fsm:define_states{ export_to=_M,
   closure={doorbell=doorbell, envlock=envlock},
   {"START", JumpState},
   {"RECOVER", JumpState},
   {"RECOVER_RELEASE", Skill, skills={{"reset_arms"}},  final_to="RECOVER",     fail_to="RECOVER"},
   {"GREET",       Skill, skills={{"pose_goto", pose_name="driving"},{"say", text=TEXT_GREET}},
      final_to="PTO_ARM",     fail_to="RECOVER"},
   {"PTO_ARM",     Skill, skills={{"pose_goto", pose_name="pointing-at-arm"}},
      final_to="EXP_ARM",     fail_to="RECOVER"},
   {"EXP_ARM",     Skill, skills={{"say", text=TEXT_ARM}},             final_to="PTO_HAND",    fail_to="RECOVER"},
   {"PTO_HAND",    Skill,
      skills={{"pose_fromto", pose_name_initial="pointing-at-arm", pose_name_final="pointing-at-hand"}},
      final_to="EXP_HAND",     fail_to="RECOVER"},
   {"EXP_HAND",    Skill, skills={{"say", text=TEXT_HAND}},            final_to="PTO_3DLASER", fail_to="RECOVER"},
   {"PTO_3DLASER", Skill,
      skills={{"pose_fromto", pose_name_initial="pointing-at-hand", pose_name_final="pointing-at-laser"}},
      final_to="EXP_3DLASER",     fail_to="RECOVER"},
   {"EXP_3DLASER", Skill, skills={{"say", text=TEXT_3DLASER}},         final_to="PTO_PROSIL",  fail_to="RECOVER"},
   {"PTO_PROSIL",  Skill,
      skills={{"pose_fromto", pose_name_initial="pointing-at-laser", pose_name_final="pointing-at-camera"}},
      final_to="EXP_PROSIL",     fail_to="RECOVER"},
   {"EXP_PROSIL",  Skill, skills={{"say", text=TEXT_PROSILICA}},       final_to="PTO_GUTS", fail_to="RECOVER"},
   --{"PTO_OBLASER", Skill,
   --   skills={{"pose_fromto", pose_name_initial="pointing-at-camera", pose_name_final="pointing-at-obslaser"}},
   --   final_to="EXP_OBSLASER",     fail_to="RECOVER"},
   --{"EXP_OBLASER", Skill, skills={{"say", text=TEXT_OBLASER}},         final_to="PTO_GUTS",    fail_to="RECOVER"},
   {"PTO_GUTS", Skill,
      skills={{"pose_fromto", pose_name_initial="pointing-at-camera", pose_name_final="pointing-at-laptops"}},
      final_to="EXP_GUTS",     fail_to="RECOVER"},
   {"EXP_GUTS",    Skill, skills={{"say", text=TEXT_GUTS}},            final_to="RETRACT_ARMS" , fail_to="RECOVER"},
   --{"PTO_SEGWAY", Skill,
   --   skills={{"pose_fromto", pose_name_initial="pointing-at-laptops", pose_name_final="pointing-at-segway"}},
   --   final_to="EXP_GUTS",     fail_to="RECOVER"},
   --{"EXP_SEGWAY",  Skill, skills={{"say", text=TEXT_SEGWAY}},          final_to="RETRACT_ARM", fail_to="RECOVER"},
   {"RETRACT_ARMS", Skill,
      skills={{"pose_fromto", pose_name_initial="pointing-at-laptops", pose_name_final="driving"}},
      final_to="GOODBYE",     fail_to="RECOVER"},
   --{"RETRACT_ARM", Skill, skills={{"reset_arms"}},                     final_to="EXP_MOVES",   fail_to="RECOVER"},
   --{"EXP_MOVES",   Skill, skills={{"say", text=TEXT_MOVEMENT}},        final_to="GOODBYE",     fail_to="RECOVER"},
   {"GOODBYE",     Skill, skills={{"say", text=TEXT_GOODBYE}},         final_to="START",       fail_to="RECOVER"},
}

fsm:add_transitions{
   {"START", "GREET", "#doorbell.messages > 0"},
   {"RECOVER", "START", timeout=5},
   {"RECOVER", "RECOVER_RELEASE", "#envlock.messages > 0 and envlock.messages[1].values.data", precond_only=true},
}

function START:init()
   self.fsm:reset_trace()
   for k,_ in pairs(self.fsm.vars) do
      self.fsm.vars[k] = nil
   end
end
