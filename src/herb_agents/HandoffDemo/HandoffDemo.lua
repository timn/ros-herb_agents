
----------------------------------------------------------------------------
--  HandoffDemo.lua
--
--  License: BSD, cf. LICENSE file
--  Copyright  2010  Kyle Strabala [strabala@cmu.edu]
--             2010  Carnegie Mellon University
--             2010  Intel Labs Pittsburgh
----------------------------------------------------------------------------

-- Initialize module
module(..., agentenv.module_init)

-- Crucial skill information
name               = "HandoffDemo"
fsm                = AgentHSM:new{name=name, debug=true, start="START"}
depends_skills     = {}
depends_topics     = {}

documentation      = [==[Handoff Demo.]==]

-- Initialize as agent module
agentenv.agent_module(...)


local FAILURE_LOOP_MAX_COUNT = 3
local HELP_ME_PHRASE = "I need help."

local preds = require("herb_agents.predicates.general")
local obj_preds = require("herb_agents.predicates.obj_tracking_preds")
local Skill = AgentSkillExecJumpState
local SubFSM = SubFSMJumpState

local subFSM_take_handoff = require("herb_agents.HandoffDemo.subFSM_take_handoff")

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds, op=obj_preds, FAILURE_LOOP_MAX_COUNT=FAILURE_LOOP_MAX_COUNT},
  {"START", JumpState},
  {"RESET", JumpState},
  {"TAKE_HANDOFF",SubFSM, subfsm=subFSM_take_handoff.fsm, 
          exit_to="RESET", 
          fail_to="RESET"},
  {"INTERUPT_FOR_INACTIVE_ARM",Skill, skills={{"stop_manipapp"},{"say",text="Oh no, my arm died. " .. HELP_ME_PHRASE}}, 
          final_state="WAIT_FOR_ARMS", 
          failure_state="WAIT_FOR_ARMS"},
  {"WAIT_FOR_ARMS", JumpState},
  {"ARMS_ACTIVE",Skill, skills={{"say",text="Great! My arms are active. Let's continue!"}}, 
          final_state="RESET", 
          failure_state="RESET"},
  {"INTERUPT_FOR_COLLISION",Skill, skills={{"stop_manipapp"},{"say",text="Oh no, I am in collision and I cannot move. " .. HELP_ME_PHRASE}}, 
          final_state="WAIT_FOR_START", 
          failure_state="WAIT_FOR_START"},
  {"INTERUPT_FOR_HUMAN",Skill, skills={{"stop_manipapp"}}, 
          final_state="WAIT_FOR_START", 
          failure_state="WAIT_FOR_START"},
  {"INTERUPT_FOR_LOOP_ERROR",Skill, skills={{"stop_manipapp"},{"say",text="Oh no, I am trying to do the same thing over and over. " .. HELP_ME_PHRASE}}, 
          final_state="WAIT_FOR_START", 
          failure_state="WAIT_FOR_START"},
  {"WAIT_FOR_START", JumpState},
}

fsm:add_transitions{
  {"START", "RESET", "p.start_button", desc="Start"},
  {"RESET", "INTERUPT_FOR_HUMAN", "p.stop_button", hide=true, desc="Stop"},
  {"RESET", "INTERUPT_FOR_LOOP_ERROR", "fsm.states.TAKE_HANDOFF.subfsm.states.FAILED.closure.fail_count >= FAILURE_LOOP_MAX_COUNT", hide=true, desc="Loop error"},
  {"RESET", "TAKE_HANDOFF", "true"},
  {"TAKE_HANDOFF", "INTERUPT_FOR_HUMAN", "p.stop_button", hide=true, desc="Stop"},
  {"TAKE_HANDOFF", "INTERUPT_FOR_INACTIVE_ARM", "op.either_arm_inactive", hide=true, desc="Arm inactive"},
  {"TAKE_HANDOFF", "INTERUPT_FOR_COLLISION", "fsm.check_for_collision_errors()", hide=true, desc="Collision"},
  {"WAIT_FOR_ARMS", "ARMS_ACTIVE", "(not op.either_arm_inactive)", desc="Arms active"},
  {"WAIT_FOR_START", "RESET", "p.start_button", desc="Start"},
}

function fsm:check_for_collision_errors()
  if fsm.error:find("Collision") then
    print_warn("FSM Error: " .. fsm.error)
    return true
  end
  if TAKE_HANDOFF.subfsm.error:find("Collision") then
    print_warn("TAKE_HANDOFF Error: " .. TAKE_HANDOFF.subfsm.error)
    return true
  end
  return false
end

function WAIT_FOR_START:init()
  fsm.error = ""
  TAKE_HANDOFF.subfsm.error = ""
  TAKE_HANDOFF.subfsm.states.FINAL.closure.fail_count = 0
end

function START:init()
  TAKE_HANDOFF.subfsm.states.FINAL.closure.fail_count = 0
  self.fsm:reset_trace()
end

