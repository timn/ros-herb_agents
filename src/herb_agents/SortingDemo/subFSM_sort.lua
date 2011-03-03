
----------------------------------------------------------------------------
--  init.lua - Herb skills initialization file
--
--  Created: Fri Aug 20 18:25:22 2010 (at Intel Research, Pittsburgh)
--  License: BSD, cf. LICENSE file
--  Copyright  2010  Tim Niemueller [www.niemueller.de]
--             2010  Carnegie Mellon University
--             2010  Intel Labs Pittsburgh
----------------------------------------------------------------------------

-- Initialize module
module(..., agentenv.module_init)

-- Crucial skill information
name            = "sort"
fsm             = AgentHSM:new{name=name, debug=true, start="START", exit_state="FINAL", fail_state="FAILED"}
depends_skills  = {}
depends_actions = {}

documentation      = [==[Pick an object up and sort it. Either put in a bin or handoff to human.]==]

-- Initialize as agent module
agentenv.agent_module(...)

ROBOT_BIN_NAME = "icebin1"
TABLETOP_NAME = "tabletop1"

local preds = require("herb_agents.predicates.general")
local obj_preds = require("herb_agents.predicates.obj_tracking_preds")
local Skill = AgentSkillExecJumpState

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds, op=obj_preds},
  {"START", JumpState},
  {"CHOOSE_OBJECT", JumpState},
  {"PICKUP_OBJECT",Skill, skills={{"grab_object", side="left", object_id="fuze_bottle[%d]*"}}, 
          final_state="CLASSIFY_OBJECT", 
          failure_state="FAILED"},
  {"CLASSIFY_OBJECT",Skill, skills={{"say", text="I am classifying the object in my hand."}}, 
          final_state="SORT", 
          failure_state="FAILED"},
  {"SORT", JumpState},
  {"PLACE_INTO_BIN",Skill, skills={{"place", object_id=ROBOT_BIN_NAME}}, 
          final_state="FINAL", 
          failure_state="FAILED"},
  {"HANDOFF_TO_HUMAN",Skill, skills={{"ft_handoff", side="right"}}, 
          final_state="FINAL", 
          failure_state="PLACE_ON_TABLE"},
  {"PLACE_ON_TABLE",Skill, skills={{"place", object_id=TABLETOP_NAME}}, 
          final_state="FAILED", 
          failure_state="FAILED"},
  {"FINAL", JumpState},
  {"FAILED", JumpState},
}

fsm:add_transitions{
  {"START", "CHOOSE_OBJECT", "op.objects_on_table and not op.holding_object"},
  {"CHOOSE_OBJECT", "PICKUP_OBJECT", "true"},
  {"START", "CLASSIFY_OBJECT", "op.holding_object"},
  {"START", "FINAL", "not op.objects_on_table and not op.holding_object"},
  {"SORT", "HANDOFF_TO_HUMAN", "op.held_object_belongs_in_human_bin"},
  {"SORT", "PLACE_INTO_BIN", "op.held_object_belongs_in_robot_bin"},
  {"SORT", "PLACE_ON_TABLE", "not (op.held_object_belongs_in_robot_bin or op.held_object_belongs_in_human_bin)"},

--  {"START", "CHOOSE_OBJECT", "p.start_button"},
--  {"START", "CLASSIFY_OBJECT", "p.HRI_yes"},
--  {"START", "FINAL", "p.HRI_no"},
--  {"SORT", "HANDOFF_TO_HUMAN", "p.HRI_yes"},
--  {"SORT", "PLACE_INTO_BIN", "p.HRI_no"},
--  {"SORT", "PLACE_ON_TABLE", "p.start_button"},
}


function CHOOSE_OBJECT:init()
  
end
