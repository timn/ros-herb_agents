
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
name            = "take_handoff"
fsm             = AgentHSM:new{name=name, debug=true, start="START", exit_state="FINAL", fail_state="FAILED", graph_collapse=false}
depends_skills  = {}
depends_actions = {}

documentation      = [==[take a handoff offered by a human]==]

-- Initialize as agent module
agentenv.agent_module(...)

ROBOT_BIN_NAME = "icebin1"
TABLETOP_NAME_RIGHT = "tabletop1"
TABLETOP_NAME_LEFT = "tabletop2"

local preds = require("herb_agents.predicates.general")
local obj_preds = require("herb_agents.predicates.obj_tracking_preds")
local Skill = AgentSkillExecJumpState

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds, op=obj_preds},
  {"START", JumpState},
  {"PLACE_RIGHT",Skill, skills={{"say", text="Please wait while I set this on the table."},
                                {"place", side="right", object_id=TABLETOP_NAME_RIGHT}}, 
          final_state="TAKE_HANDOFF",
          failure_state="FAILED", hide_failure_transition = true},
  {"TAKE_HANDOFF", Skill, skills={{"say", text="I am going to take what you are holding. Be careful."},
                                  {"take_at_tm", side="right", T="[0,1,0,0,0,-1,-1,0,0,0.57,-1.83,1.175]", exec_timelimit=10}}, 
          final_state="PICKUP_RIGHT",
          failure_state="FAILED", hide_failure_transition = true},
  {"PICKUP_RIGHT", Skill, skills={{"pickup", side="right"}}, 
          final_state="CHECK_LEFT_HAND",
          failure_state="FAILED", hide_failure_transition = true},
  {"CHECK_LEFT_HAND", JumpState},
  {"PLACE_LEFT",Skill, skills={{"place", side="left", object_id=TABLETOP_NAME_LEFT}}, 
          final_state="SWITCH_HANDS",
          failure_state="FAILED", hide_failure_transition = true},
  {"SWITCH_HANDS",Skill, skills={{"handover", side="right"}}, 
          final_state="GO_INITIAL_RIGHT",
          failure_state="FAILED", hide_failure_transition = true},
  {"GO_INITIAL_RIGHT",Skill, skills={{"goinitial",side="right"}}, 
          final_state="PLACE_INTO_BIN",
          failure_state="FAILED", hide_failure_transition = true},
  {"PLACE_INTO_BIN",Skill, skills={{"put", side="left", object_id=ROBOT_BIN_NAME}}, 
          final_state="FINAL",
          failure_state="FAILED", hide_failure_transition = true},
  {"FINAL", JumpState},
  {"FAILED", JumpState},
}

fsm:add_transitions{
  {"START", "PLACE_RIGHT", "op.HERB_holding_object_in_right_hand"},
  {"START", "TAKE_HANDOFF", "(not op.HERB_holding_object_in_right_hand)"},
  {"CHECK_LEFT_HAND", "SWITCH_HANDS", "(not op.HERB_holding_object_in_left_hand)"},
  {"CHECK_LEFT_HAND", "PLACE_LEFT", "op.HERB_holding_object_in_left_hand"},
}

