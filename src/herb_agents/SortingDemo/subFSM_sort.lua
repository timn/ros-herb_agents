
----------------------------------------------------------------------------
--  init.lua - Herb skills initialization file
--
--  License: BSD, cf. LICENSE file
--  Copyright  2010  Kyle Strabala [strabala@cmu.edu]
--             2010  Tim Niemueller [www.niemueller.de]
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
TABLETOP_NAME_RIGHT = "tabletop1"
TABLETOP_NAME_LEFT = "tabletop2"
local ROBOT_BIN_OBJECT_PATTERN = "poptarts[%d]*"
local HUMAN_BIN_OBJECT_PATTERN = "fuze_bottle[%d]*"

local preds = require("herb_agents.predicates.general")
local obj_preds = require("herb_agents.predicates.obj_tracking_preds")
local Skill = AgentSkillExecJumpState

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds, op=obj_preds},
  {"START", JumpState},
  {"GO_INITIAL",Skill, skills={{"goinitial_both"}}, 
          final_state="PICKUP_OBJECT", 
          failure_state="GO_INITIAL_FAIL"},
  {"GO_INITIAL_FAIL",Skill, skills={{"say", text="I cannot go to my initial configuration. Please help, then press the start button."}}, 
          final_state="WAIT_FOR_HELP", 
          failure_state="WAIT_FOR_HELP"},
  {"WAIT_FOR_HELP", JumpState},
  {"PICKUP_OBJECT", JumpState},
  {"PICKUP_OBJECT_LEFT",Skill, skills={{"grab_object", side="left", object_id=(ROBOT_BIN_OBJECT_PATTERN .. "," .. HUMAN_BIN_OBJECT_PATTERN)}}, 
          final_state="SORT_LEFT", 
          failure_state="FAILED"},
  {"PICKUP_OBJECT_RIGHT",Skill, skills={{"grab_object", side="right", object_id=(ROBOT_BIN_OBJECT_PATTERN .. "," .. HUMAN_BIN_OBJECT_PATTERN)}}, 
          final_state="SORT_RIGHT", 
          failure_state="FAILED"},
  {"SORT_LEFT", JumpState},
  {"PLACE_INTO_BIN",Skill, skills={{"put", side="left", object_id=ROBOT_BIN_NAME}}, 
          final_state="FINAL", 
          failure_state="FAILED"},
  {"CHECK_RIGHT_HAND", JumpState},
  {"PLACE_RIGHT",Skill, skills={{"place", side="right", object_id=TABLETOP_NAME_RIGHT}}, 
          final_state="HANDOVER_TO_RIGHT", 
          failure_state="FAILED"},
  {"HANDOVER_TO_RIGHT",Skill, skills={{"handover", side="left"}}, 
          final_state="HANDOVER_GO_INITIAL_LEFT", 
          failure_state="FAILED"},
  {"HANDOVER_GO_INITIAL_LEFT",Skill, skills={{"goinitial",side="left"}}, 
          final_state="CHECK_FOR_HUMAN", 
          failure_state="FAILED"},
  {"SORT_RIGHT", JumpState},
  {"CHECK_LEFT_HAND", JumpState},
  {"PLACE_LEFT",Skill, skills={{"place", side="left", object_id=TABLETOP_NAME_LEFT}}, 
          final_state="HANDOVER_TO_LEFT", 
          failure_state="FAILED"},
  {"HANDOVER_TO_LEFT",Skill, skills={{"handover", side="right"}}, 
          final_state="HANDOVER_GO_INITIAL_RIGHT", 
          failure_state="FAILED"},
  {"HANDOVER_GO_INITIAL_RIGHT",Skill, skills={{"goinitial",side="right"}}, 
          final_state="PLACE_INTO_BIN", 
          failure_state="FAILED"},
  {"CHECK_FOR_HUMAN", JumpState},
  {"HANDOFF_TO_HUMAN",Skill, skills={{"say", text="I am going to give you this."},{"go_to_tm", side="right", T="[0,1,0,0,0,-1,-1,0,0,0.75,-1.83,1.175]"}}, 
          final_state="HANDOFF_TO_HUMAN_GIVE", 
          failure_state="FAILED"},
  {"HANDOFF_TO_HUMAN_GIVE",Skill, skills={{"say", text="Please take this."},{"ft_handoff", side="right"}}, 
          final_state="FINAL", 
          failure_state="PLACE_ON_TABLE_RIGHT"},
  {"PLACE_ON_TABLE_LEFT",Skill, skills={{"place", side="left", object_id=TABLETOP_NAME_LEFT}}, 
          final_state="PLACE_GO_INITIAL_LEFT", 
          failure_state="FAILED"},
  {"PLACE_GO_INITIAL_LEFT",Skill, skills={{"goinitial",side="left"}}, 
          final_state="FAILED", 
          failure_state="FAILED"},
  {"PLACE_ON_TABLE_RIGHT",Skill, skills={{"place", side="right", object_id=TABLETOP_NAME_RIGHT}}, 
          final_state="PLACE_GO_INITIAL_RIGHT", 
          failure_state="FAILED"},
  {"PLACE_GO_INITIAL_RIGHT",Skill, skills={{"goinitial",side="right"}}, 
          final_state="FAILED", 
          failure_state="FAILED"},
  {"FINAL", JumpState},
  {"FAILED", JumpState},
}

fsm:add_transitions{
  {"START", "GO_INITIAL", "not op.HERB_holding_object"},
  {"START", "SORT_RIGHT", "op.HERB_holding_object_in_right_hand"},
  {"START", "SORT_LEFT", "op.HERB_holding_object_in_left_hand"},
  {"WAIT_FOR_HELP", "GO_INITIAL", "p.start_button"},
  {"PICKUP_OBJECT", "PICKUP_OBJECT_LEFT", "op.sortable_objects_on_left"},
  {"PICKUP_OBJECT", "PICKUP_OBJECT_RIGHT", "op.sortable_objects_on_right"},
  {"PICKUP_OBJECT", "FINAL", "(not op.sortable_objects_on_table)"},
  {"SORT_LEFT", "CHECK_RIGHT_HAND", "op.left_held_object_belongs_in_human_bin"},
  {"SORT_LEFT", "PLACE_INTO_BIN", "op.left_held_object_belongs_in_robot_bin"},
  {"SORT_LEFT", "PLACE_ON_TABLE_LEFT", "op.left_held_object_unsortable"},
  {"CHECK_RIGHT_HAND", "HANDOVER_TO_RIGHT", "(not op.HERB_holding_object_in_right_hand)"},
  {"CHECK_RIGHT_HAND", "PLACE_RIGHT", "op.HERB_holding_object_in_right_hand"},
  {"SORT_RIGHT", "CHECK_FOR_HUMAN", "op.right_held_object_belongs_in_human_bin"},
  {"SORT_RIGHT", "CHECK_LEFT_HAND", "op.right_held_object_belongs_in_robot_bin"},
  {"SORT_RIGHT", "PLACE_ON_TABLE_RIGHT", "op.right_held_object_unsortable"},
  {"CHECK_LEFT_HAND", "HANDOVER_TO_LEFT", "(not op.HERB_holding_object_in_left_hand)"},
  {"CHECK_LEFT_HAND", "PLACE_LEFT", "op.HERB_holding_object_in_left_hand"},
  {"CHECK_FOR_HUMAN", "HANDOFF_TO_HUMAN", "op.human_near_table"},
  {"CHECK_FOR_HUMAN", "PLACE_ON_TABLE_RIGHT", "(not op.human_near_table)"},
}

