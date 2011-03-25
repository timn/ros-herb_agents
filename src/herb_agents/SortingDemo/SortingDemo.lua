
----------------------------------------------------------------------------
--  SortingDemo.lua
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
name               = "SortingDemo"
fsm                = AgentHSM:new{name=name, debug=true, start="START"}
depends_skills     = {}
depends_topics     = {}

documentation      = [==[Sorting Demo.]==]

-- Initialize as agent module
agentenv.agent_module(...)


TIMEOUT_INDIFFERENCE = 10
FAILURE_LOOP_MAX_COUNT = 3
INSTRUCTIONS =  "Instructions. who dat girl." --"Lets collaborate to put these items where they belong. The fuze bottles belong in your bin. I will need you to pass me pop tarts that are out of my reach. Likewise, I will pass you fuze bottles that are near me."

local preds = require("herb_agents.predicates.general")
local obj_preds = require("herb_agents.predicates.obj_tracking_preds")
local Skill = AgentSkillExecJumpState
local SubFSM = SubFSMJumpState

local subFSM_sort = require("herb_agents.SortingDemo.subFSM_sort")
local subFSM_calibrate_human_tracker = require("herb_agents.SortingDemo.subFSM_calibrate_human_tracker")
local subFSM_take_handoff = require("herb_agents.SortingDemo.subFSM_take_handoff")

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds, op=obj_preds, TIMEOUT_INDIFFERENCE=TIMEOUT_INDIFFERENCE, FAILURE_LOOP_MAX_COUNT=FAILURE_LOOP_MAX_COUNT},
  {"START", JumpState},
  {"FINAL", JumpState},
  {"GO_INITIAL",Skill, skills={{"goinitial_both"}}, 
          final_state="RESET", 
          failure_state="GO_INITIAL_FAIL"},
  {"GO_INITIAL_FAIL",Skill, skills={{"say", text="I cannot go to my initial configuration. Please help, then press the start button."}}, 
          final_state="WAIT_FOR_HELP", 
          failure_state="WAIT_FOR_HELP"},
  {"WAIT_FOR_HELP", JumpState},
  {"RESET", JumpState},
  {"WAIT_FOR_HUMAN",Skill, skills={{"say", text="I am waiting for some help."}}, 
          final_state="RESET", 
          failure_state="RESET"},
  {"INSTRUCTIONS",Skill, skills={{"say", text=INSTRUCTIONS}}, 
          final_state="SORT_LOOP", 
          failure_state="SORT_LOOP"},
  {"SORT_LOOP",JumpState},
  {"SORT",SubFSM, subfsm=subFSM_sort.fsm, 
          exit_to="RESET_SORT_LOOP_COUNT", 
          fail_to="CHECK_FOR_SORT_LOOPS"},
  {"INTERUPT_FOR_HANDOFF",Skill, skills={{"stop_manipapp"}}, 
          final_state="TAKE_HANDOFF", 
          failure_state="TAKE_HANDOFF"},
  {"TAKE_HANDOFF",SubFSM, subfsm=subFSM_take_handoff.fsm, 
          exit_to="RESET_HANDOFF_LOOP_COUNT", 
          fail_to="CHECK_FOR_HANDOFF_LOOPS"},
  {"INTERUPT_FOR_INACTIVE_ARM",Skill, skills={{"stop_manipapp"},{"say",text="Oh no, my arm died. Can you help me restart it?"}}, 
          final_state="WAIT_FOR_ARMS", 
          failure_state="WAIT_FOR_ARMS"},
  {"WAIT_FOR_ARMS", JumpState},
  {"ARMS_ACTIVE",Skill, skills={{"say",text="Great! My arms are active. Let's continue!"}}, 
          final_state="SORT", 
          failure_state="SORT"},
  {"INTERUPT_FOR_COLLISION",Skill, skills={{"stop_manipapp"},{"say",text="Oh no, I am in collision and I cannot move. Can you help me? Press the start button when you are finished."}}, 
          final_state="WAIT_FOR_COLLISION", 
          failure_state="WAIT_FOR_COLLISION"},
  {"LOOP_ERROR",Skill, skills={{"stop_manipapp"},{"say",text="Oh no, I am trying to do the same thing over and over, but it is not working. Can you help me? Press the start button when you are finished."}}, 
          final_state="WAIT_FOR_LOOP_ERROR", 
          failure_state="WAIT_FOR_LOOP_ERROR"},
  {"WAIT_FOR_COLLISION", JumpState},
  {"CHECK_FOR_SORT_LOOPS", JumpState},
  {"RESET_SORT_LOOP_COUNT", JumpState},
  {"CHECK_FOR_HANDOFF_LOOPS", JumpState},
  {"RESET_HANDOFF_LOOP_COUNT", JumpState},
  {"WAIT_FOR_LOOP_ERROR", JumpState},
}

fsm:add_transitions{
  {"START", "START", timeout=1},
  {"START", "GO_INITIAL", "p.start_button"},
  {"WAIT_FOR_HELP", "GO_INITIAL", "p.start_button"},
  {"FINAL", "GO_INITIAL", "p.start_button"},
  {"RESET", "WAIT_FOR_HUMAN", timeout=20},
  {"RESET", "INSTRUCTIONS", "op.human_near_table"},
  {"RESET", "SORT_LOOP", "p.HRI_yes"},
  {"INSTRUCTIONS", "SORT_LOOP", "p.HRI_yes or p.start_button"},
  {"SORT_LOOP", "TAKE_HANDOFF", "op.human_offering_object or p.start_button"},
  {"SORT_LOOP", "FINAL", "(not op.objects_in_play)"},
  {"SORT_LOOP", "SORT", "op.sortable_objects_on_table or op.HERB_holding_object"},
  --{"SORT_LOOP", "RESET", "(not op.human_tracking_working) and (not p.HRI_yes)"},
  --{"SORT_LOOP", "RESET", "(not op.human_near_table) and (not p.HRI_yes)"},
  {"SORT", "INTERUPT_FOR_INACTIVE_ARM", "op.either_arm_inactive"},
  {"SORT", "INTERUPT_FOR_COLLISION", "fsm.check_for_collision_errors()"},
  {"SORT", "INTERUPT_FOR_HANDOFF", "(op.human_offering_object and (not fsm.check_for_robot_handoff())) or p.start_button"},
  {"TAKE_HANDOFF", "INTERUPT_FOR_INACTIVE_ARM", "op.either_arm_inactive"},
  {"TAKE_HANDOFF", "INTERUPT_FOR_COLLISION", "fsm.check_for_collision_errors()"},
  {"WAIT_FOR_ARMS", "ARMS_ACTIVE", "(not op.either_arm_inactive)"},
  {"WAIT_FOR_COLLISION", "SORT", "p.start_button"},
  {"CHECK_FOR_SORT_LOOPS", "SORT_LOOP", "vars.sort_loop_count < FAILURE_LOOP_MAX_COUNT"},
  {"CHECK_FOR_SORT_LOOPS", "LOOP_ERROR", "vars.sort_loop_count >= FAILURE_LOOP_MAX_COUNT"},
  {"RESET_SORT_LOOP_COUNT", "SORT_LOOP", "true"},
  {"CHECK_FOR_HANDOFF_LOOPS", "SORT", "vars.handoff_loop_count < FAILURE_LOOP_MAX_COUNT"},
  {"CHECK_FOR_HANDOFF_LOOPS", "LOOP_ERROR", "vars.handoff_loop_count >= FAILURE_LOOP_MAX_COUNT"},
  {"RESET_HANDOFF_LOOP_COUNT", "SORT", "true"},
  {"WAIT_FOR_LOOP_ERROR", "SORT", "p.start_button"},
}

function fsm:check_for_collision_errors()
  if SORT.subfsm.error:find("Collision") then
    print_warn("Sort Error: " .. SORT.subfsm.error)
    return true
  end
  if TAKE_HANDOFF.subfsm.error:find("Collision") then
    print_warn("TAKE_HANDOFF Error: " .. TAKE_HANDOFF.subfsm.error)
    return true
  end
  return false
end

function WAIT_FOR_COLLISION:init()
  SORT.subfsm.error = ""
  TAKE_HANDOFF.subfsm.error = ""
end

function fsm:check_for_robot_handoff()
  if SORT.subfsm.current then
    if SORT.subfsm.current.name == "HANDOFF_TO_HUMAN" then
      return true
    end
    if SORT.subfsm.current.name == "HANDOFF_TO_HUMAN_GIVE" then
      return true
    end
  end
  return false
end

function START:init()
  self.fsm.vars.sort_loop_count = 0
  self.fsm.vars.handoff_loop_count = 0
  
  self.fsm:reset_trace()
  print_debug("*************************************")
  print_debug("%s = %q", "obj_preds.human_tracking_working", tostring(obj_preds.human_tracking_working))
  print_debug("%s = %q", "obj_preds.human_near_table", tostring(obj_preds.human_near_table))
  print_debug("%s = %q", "obj_preds.objects_on_table", tostring(obj_preds.objects_on_table))
  print_debug("%s = %q", "obj_preds.human_holding_object", tostring(obj_preds.human_holding_object))
  print_debug("%s = %q", "obj_preds.human_offering_object", tostring(obj_preds.human_offering_object))
  print_debug("%s = %q", "obj_preds.HERB_holding_object", tostring(obj_preds.HERB_holding_object))
  print_debug("%s = %q", "obj_preds.HERB_holding_object_in_left_hand", tostring(obj_preds.HERB_holding_object_in_left_hand))
  print_debug("%s = %q", "obj_preds.HERB_holding_object_in_right_hand", tostring(obj_preds.HERB_holding_object_in_right_hand))
  print_debug("%s = %q", "obj_preds.left_held_object_unsortable", tostring(obj_preds.left_held_object_unsortable))
  print_debug("%s = %q", "obj_preds.left_held_object_belongs_in_robot_bin", tostring(obj_preds.left_held_object_belongs_in_robot_bin))
  print_debug("%s = %q", "obj_preds.left_held_object_belongs_in_human_bin", tostring(obj_preds.left_held_object_belongs_in_human_bin))
  print_debug("%s = %q", "obj_preds.right_held_object_unsortable", tostring(obj_preds.right_held_object_unsortable))
  print_debug("%s = %q", "obj_preds.right_held_object_belongs_in_robot_bin", tostring(obj_preds.right_held_object_belongs_in_robot_bin))
  print_debug("%s = %q", "obj_preds.right_held_object_belongs_in_human_bin", tostring(obj_preds.right_held_object_belongs_in_human_bin))
end

function CHECK_FOR_HANDOFF_LOOPS:init()
  self.fsm.vars.handoff_loop_count = self.fsm.vars.handoff_loop_count + 1
end

function RESET_HANDOFF_LOOP_COUNT:init()
  self.fsm.vars.handoff_loop_count = 0
end

function CHECK_FOR_SORT_LOOPS:init()
  self.fsm.vars.sort_loop_count = self.fsm.vars.sort_loop_count + 1
end

function RESET_SORT_LOOP_COUNT:init()
  self.fsm.vars.sort_loop_count = 0
end

function WAIT_FOR_LOOP_ERROR:init()
  self.fsm.vars.handoff_loop_count = 0
  self.fsm.vars.sort_loop_count = 0
end
