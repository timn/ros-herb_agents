
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

local ROBOT_BIN_NAME = "icebin1"
local TABLETOP_NAME_RIGHT = "tabletop1"
local TABLETOP_NAME_LEFT = "tabletop2"
local EXEC_TIME_LIMIT = 20
local PREP_TIME_LIMIT = 20

local preds = require("herb_agents.predicates.general")
local obj_preds = require("herb_agents.predicates.obj_tracking_preds")
local Skill = AgentSkillExecJumpState

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds, op=obj_preds, fail_count=0},
  {"START", JumpState},
  {"PLACE_RIGHT",Skill, skills={{"say", text="Please wait while I set this on the table."},
                                {"place", side="right", object_id=TABLETOP_NAME_RIGHT}}, 
          final_state="TAKE_HANDOFF",
          failure_state="FAILED", hide_failure_transition = true},
  {"TAKE_HANDOFF", Skill, skills={{"say", text="I am going to take what you are holding. Be careful."},
                                  {"take_at_tm", side="right", T="[0,1,0,0,0,-1,-1,0,0,0.57,-1.83,1.175]", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=10}}, 
          final_state="PICKUP_RIGHT",
          failure_state="TAKE_FAIL_GO_INITIAL_RIGHT"},
  {"PICKUP_RIGHT", Skill, skills={{"pickup", side="right", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}},
          final_state="CHECK_LEFT_HAND",
          failure_state="FAILED", hide_failure_transition = true},
  {"CHECK_LEFT_HAND", JumpState},
  {"SORT_LEFT", JumpState},
  {"PLACE_LEFT",Skill, skills={{"place", side="left", object_id=TABLETOP_NAME_LEFT, prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="SWITCH_HANDS",
          failure_state="FAILED", hide_failure_transition = true},
  {"SORT_PLACE_INTO_BIN",Skill, skills={{"say", text="This <break time='100ms'/> goes in <prosody rate='x-slow'> my </prosody> bin."},{"put", side="left", object_id=ROBOT_BIN_NAME, prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="SWITCH_HANDS",
          failure_state="FAILED", hide_failure_transition = true},
  {"SWITCH_HANDS",Skill, skills={{"handover", side="right", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="GO_INITIAL_RIGHT",
          failure_state="FAILED", hide_failure_transition = true},
  {"GO_INITIAL_RIGHT",Skill, skills={{"goinitial",side="right", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="PLACE_INTO_BIN",
          failure_state="PLACE_INTO_BIN"},
  {"PLACE_INTO_BIN",Skill, skills={{"say", text="This <break time='100ms'/> goes in <prosody rate='x-slow'> my </prosody> bin."},{"put", side="left", object_id=ROBOT_BIN_NAME, prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="GO_INITIAL_LEFT",
          failure_state="FAILED", hide_failure_transition = true},
  {"GO_INITIAL_LEFT",Skill, skills={{"goinitial",side="left", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}},
          final_state="FINAL",
          failure_state="FINAL"},
  {"FINAL", JumpState},
  {"TAKE_FAIL_GO_INITIAL_RIGHT",Skill, skills={{"goinitial",side="right", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="FAILED",
          failure_state="FAILED", hide_failure_transition = true},
  {"FAILED", JumpState},
}

fsm:add_transitions{
  {"START", "PLACE_RIGHT", "op.HERB_holding_object_in_right_hand", desc="Object in right hand"},
  {"START", "TAKE_HANDOFF", "(not op.HERB_holding_object_in_right_hand)", desc="No object in right hand"},
  {"CHECK_LEFT_HAND", "SWITCH_HANDS", "(not op.HERB_holding_object_in_left_hand)", desc="No object in left hand"},
  {"CHECK_LEFT_HAND", "SORT_LEFT", "op.HERB_holding_object_in_left_hand", desc="Object in left hand"},
  {"SORT_LEFT", "PLACE_LEFT", "(not op.left_held_object_belongs_in_robot_bin)", desc="Does not belong in robot bin"},
  {"SORT_LEFT", "SORT_PLACE_INTO_BIN", "op.left_held_object_belongs_in_robot_bin", desc="Belongs in robot bin"},
}


function FINAL:init()
  self.fsm.current.closure.fail_count = 0
  print_debug("%s:FINAL:init(): reset fail_count to %d", self.fsm.name, self.fsm.current.closure.fail_count)
end

function FAILED:init()
  self.fsm.current.closure.fail_count = self.fsm.current.closure.fail_count + 1
  print_debug("%s:FAILED:init(): increment fail_count to %d", self.fsm.name, self.fsm.current.closure.fail_count)
end
