
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
  {"PICKUP_OBJECT",Skill, skills={{"grab_object", side="left", object_id="poptarts[%d]*,fuze_bottle[%d]*"}}, 
          final_state="SORT", 
          failure_state="FAILED"},
  {"SORT", JumpState},
  {"PLACE_INTO_BIN",Skill, skills={{"place", object_id=ROBOT_BIN_NAME}}, 
          final_state="FINAL", 
          failure_state="FAILED"},
  {"CHECK_RIGHT_HAND", JumpState},
  {"PLACE_RIGHT",Skill, skills={{"place", side="right", object_id=TABLETOP_NAME}}, 
          final_state="SWITCH_HANDS", 
          failure_state="FAILED"},
  {"SWITCH_HANDS",Skill, skills={{"handover", side="left"}}, 
          final_state="CHECK_FOR_HUMAN", 
          failure_state="FAILED"},
  {"CHECK_FOR_HUMAN", JumpState},
  {"HANDOFF_TO_HUMAN",Skill, skills={{"say", text="I'm going to give you this."},{"ft_handoff", side="right"}}, 
          final_state="FINAL", 
          failure_state="PLACE_ON_TABLE"},
  {"PLACE_ON_TABLE",Skill, skills={{"place", object_id=TABLETOP_NAME}}, 
          final_state="FAILED", 
          failure_state="FAILED"},
  {"FINAL", JumpState},
  {"FAILED", JumpState},
}

fsm:add_transitions{
  {"START", "PICKUP_OBJECT", "op.objects_on_table and not op.HERB_holding_object_in_left_hand"},
  {"START", "SORT", "op.HERB_holding_object_in_left_hand"},
  {"START", "FINAL", "not op.objects_on_table and not op.HERB_holding_object_in_left_hand"},
  {"SORT", "CHECK_RIGHT_HAND", "op.held_object_belongs_in_human_bin"},
  {"CHECK_RIGHT_HAND", "SWITCH_HANDS", "not op.HERB_holding_object_in_right_hand"},
  {"CHECK_RIGHT_HAND", "PLACE_RIGHT", "op.HERB_holding_object_in_right_hand"},
  {"CHECK_FOR_HUMAN", "HANDOFF_TO_HUMAN", "op.human_near_table"},
  {"CHECK_FOR_HUMAN", "PLACE_ON_TABLE", "not op.human_near_table"},
  {"SORT", "PLACE_INTO_BIN", "op.held_object_belongs_in_robot_bin"},
  {"SORT", "PLACE_ON_TABLE", "not (op.held_object_belongs_in_robot_bin or op.held_object_belongs_in_human_bin)"},
}

