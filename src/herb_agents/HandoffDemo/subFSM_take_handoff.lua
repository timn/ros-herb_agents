
----------------------------------------------------------------------------
--  subFSM_take_handoff.lua
--
--  License: BSD, cf. LICENSE file
--  Copyright  2010  Kyle Strabala [strabala@cmu.edu]
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


local TABLETOP_NAME_RIGHT = "tabletop1"
local HELP_ME_PHRASE = "I need help."
local EXEC_TIME_LIMIT = 20
local PREP_TIME_LIMIT = 20

local preds = require("herb_agents.predicates.general")
local obj_preds = require("herb_agents.predicates.obj_tracking_preds")
local Skill = AgentSkillExecJumpState

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds, op=obj_preds, fail_count=0},
  {"START", JumpState},
  {"GO_INITIAL",Skill, skills={{"goinitial_both", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="DECIDE", 
          failure_state="GO_INITIAL_FAIL"},
  {"GO_INITIAL_FAIL",Skill, skills={{"say", text="I cannot go to my initial configuration." .. " " .. HELP_ME_PHRASE}}, 
          final_state="WAIT_FOR_HELP", 
          failure_state="WAIT_FOR_HELP"},
  {"WAIT_FOR_HELP", JumpState},
  {"DECIDE", JumpState},
  {"TAKE_HANDOFF", Skill, skills={{"follow", side="right", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=0}}, 
          final_state="DECIDE",
          failure_state="FAILED"},
  {"PICKUP_RIGHT", Skill, skills={{"pickup", side="right", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}},
          final_state="PLACE_RIGHT",
          failure_state="FAILED", hide_failure_transition = true},
  {"PLACE_RIGHT_1",Skill, skills={{"place", side="right", object_id=TABLETOP_NAME_RIGHT}}, 
          final_state="FINAL",
          failure_state="FAILED", hide_failure_transition = true},
  {"PLACE_RIGHT_2",Skill, skills={{"place", side="right", object_id=TABLETOP_NAME_LEFT}}, 
          final_state="FINAL",
          failure_state="FAILED", hide_failure_transition = true},
  {"FINAL", JumpState},
  {"FAILED", JumpState},
}

fsm:add_transitions{
  {"START", "GO_INITIAL", "not op.HERB_holding_object", desc="Not holding objects"},
  {"WAIT_FOR_HELP", "GO_INITIAL", "p.start_button", desc="Start"},
  {"DECIDE", "PLACE_RIGHT_1", "op.HERB_holding_object_in_right_hand and (not op.right_held_object_belongs_in_robot_bin)", desc="Object goes on right side"},
  {"DECIDE", "PLACE_RIGHT_2", "op.HERB_holding_object_in_right_hand and op.right_held_object_belongs_in_robot_bin", desc="Object goes on left side"},
  {"DECIDE", "TAKE_HANDOFF", "(not op.HERB_holding_object_in_right_hand)", desc="No object in right hand"},
}


function FINAL:init()
  self.fsm.current.closure.fail_count = 0
  print_debug("%s:FINAL:init(): reset fail_count to %d", self.fsm.name, self.fsm.current.closure.fail_count)
end

function FAILED:init()
  self.fsm.current.closure.fail_count = self.fsm.current.closure.fail_count + 1
  print_debug("%s:FAILED:init(): increment fail_count to %d", self.fsm.name, self.fsm.current.closure.fail_count)
end
