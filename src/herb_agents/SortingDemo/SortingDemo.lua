
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


local TIMEOUT_INDIFFERENCE = 10
local FAILURE_LOOP_MAX_COUNT = 3
local EXEC_TIME_LIMIT = 20
local PREP_TIME_LIMIT = 20
local INSTRUCTIONS =  "Hello. Lets collaborate to put these items where they belong. The fuze bottles belong in your bin. I will need you to pass me pop tarts that are out of my reach. Likewise, I will pass you fuze bottles that are near me."
local HELP_ME_PHRASE = "I need help."

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
  {"GO_INITIAL",Skill, skills={{"goinitial_both", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="RESET", 
          failure_state="GO_INITIAL_FAIL"},
  {"GO_INITIAL_FAIL",Skill, skills={{"say", text="I cannot go to my initial configuration." .. " " .. HELP_ME_PHRASE}}, 
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
          exit_to="SORT_LOOP", 
          fail_to="SORT_LOOP"},
  {"INTERUPT_FOR_HANDOFF",Skill, skills={{"stop_manipapp"}}, 
          final_state="TAKE_HANDOFF", 
          failure_state="TAKE_HANDOFF"},
  {"TAKE_HANDOFF",SubFSM, subfsm=subFSM_take_handoff.fsm, 
          exit_to="SORT_LOOP", 
          fail_to="SORT_LOOP"},
  {"INTERUPT_FOR_INACTIVE_ARM",Skill, skills={{"stop_manipapp"},{"say",text="Oh no, my arm died." .. " " .. HELP_ME_PHRASE}}, 
          final_state="WAIT_FOR_ARMS", 
          failure_state="WAIT_FOR_ARMS"},
  {"WAIT_FOR_ARMS", JumpState},
  {"ARMS_ACTIVE",Skill, skills={{"say",text="Great! My arms are active. Let's continue!"}}, 
          final_state="SORT_LOOP", 
          failure_state="SORT_LOOP"},
  {"INTERUPT_FOR_COLLISION",Skill, skills={{"stop_manipapp"},{"say",text="Oh no, I am in collision and I cannot move." .. " " .. HELP_ME_PHRASE}}, 
          final_state="WAIT_FOR_COLLISION", 
          failure_state="WAIT_FOR_COLLISION"},
  {"WAIT_FOR_COLLISION", JumpState},
  {"INTERUPT_FOR_HUMAN",Skill, skills={{"stop_manipapp"}}, 
          final_state="WAIT_FOR_START", 
          failure_state="WAIT_FOR_START"},
  {"INTERUPT_FOR_LOOP_ERROR",Skill, skills={{"stop_manipapp"},{"say",text="Oh no, I am trying to do the same thing over and over." .. " " .. HELP_ME_PHRASE}}, 
          final_state="WAIT_FOR_START", 
          failure_state="WAIT_FOR_START"},
  {"WAIT_FOR_START", JumpState},
}

fsm:add_transitions{
  {"START", "START", timeout=1, hide=true},
  {"START", "GO_INITIAL", "p.start_button", desc="Start"},
  {"WAIT_FOR_HELP", "GO_INITIAL", "p.start_button", desc="Start"},
  {"FINAL", "GO_INITIAL", "p.start_button", hide=true, desc="Start"},
  {"RESET", "WAIT_FOR_HUMAN", timeout=20},
  {"RESET", "INSTRUCTIONS", "op.human_near_table", desc="Human near table"},
  {"RESET", "SORT_LOOP", "p.HRI_yes", desc="HRI_yes"},
  --{"INSTRUCTIONS", "SORT_LOOP", "p.HRI_yes or p.start_button"},
  {"SORT_LOOP", "INTERUPT_FOR_HUMAN", "p.stop_button", hide=true, desc="Stop"},
  {"SORT_LOOP", "INTERUPT_FOR_LOOP_ERROR", "fsm.states.SORT.subfsm.states.FAILED.closure.fail_count >= FAILURE_LOOP_MAX_COUNT", hide=true, desc="Loop error"},
  {"SORT_LOOP", "INTERUPT_FOR_LOOP_ERROR", "fsm.states.TAKE_HANDOFF.subfsm.states.FAILED.closure.fail_count >= FAILURE_LOOP_MAX_COUNT", hide=true, desc="Loop error"},
  {"SORT_LOOP", "TAKE_HANDOFF", "op.human_offering_object", desc="Human offering object"},
  {"SORT_LOOP", "FINAL", "(not op.objects_in_play)", desc="Objects in play"},
  {"SORT_LOOP", "SORT", "op.sortable_objects_on_table or op.HERB_holding_object", desc="Objects to sort"},
  --{"SORT_LOOP", "RESET", "(not op.human_tracking_working) and (not p.HRI_yes)"},
  --{"SORT_LOOP", "RESET", "(not op.human_near_table) and (not p.HRI_yes)"},
  {"SORT", "INTERUPT_FOR_HUMAN", "p.stop_button", hide=true, desc="Stop"},
  {"SORT", "INTERUPT_FOR_INACTIVE_ARM", "op.either_arm_inactive", hide=true, desc="Arm inactive"},
  {"SORT", "INTERUPT_FOR_COLLISION", "fsm.check_for_collision_errors()", hide=true, desc="Collision"},
  {"SORT", "INTERUPT_FOR_HANDOFF", "op.human_offering_object and (not fsm.check_for_robot_handoff())", hide=true, desc="Handoff"},
  {"TAKE_HANDOFF", "INTERUPT_FOR_HUMAN", "p.stop_button", hide=true, desc="Stop"},
  {"TAKE_HANDOFF", "INTERUPT_FOR_INACTIVE_ARM", "op.either_arm_inactive", hide=true, desc="Arm inactive"},
  {"TAKE_HANDOFF", "INTERUPT_FOR_COLLISION", "fsm.check_for_collision_errors()", hide=true, desc="Collision"},
  {"WAIT_FOR_ARMS", "ARMS_ACTIVE", "(not op.either_arm_inactive)", desc="Arms active"},
  {"WAIT_FOR_COLLISION", "SORT_LOOP", "p.start_button", desc="Start"},
  {"WAIT_FOR_START", "SORT_LOOP", "p.start_button", desc="Start"},
}

function fsm:check_for_collision_errors()
  if fsm.error:find("Collision") then
    print_warn("FSM Error: " .. SORT.subfsm.error)
    return true
  end
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
  fsm.error = ""
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
    if SORT.subfsm.current.name == "HANDOFF_GO_INITIAL_RIGHT" then
      return true
    end
    if SORT.subfsm.current.name == "PLACE_ON_TABLE_RIGHT" then
      return true
    end
    if SORT.subfsm.current.name == "PLACE_GO_INITIAL_RIGHT" then
      return true
    end
    if SORT.subfsm.current.name == "FINAL" then
      return true
    end
    if SORT.subfsm.current.name == "FAILED" then
      return true
    end
  end
  return false
end

function START:init()
  SORT.subfsm.states.FINAL.closure.fail_count = 0
  TAKE_HANDOFF.subfsm.states.FINAL.closure.fail_count = 0
  
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
  
  ---print_error("asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf")
  ---print_table(_M)
  ---print_table(self)
  ---print_error("asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf")
end

function print_table(v0)
  print_warn("%s table:", tostring(v0))
  for k1,v1 in pairs(v0) do
    print_var(k1,v1,"  ")
    if v1 and type(v1) == "table" and check_parents(v1,v0,1) then
      for k2,v2 in pairs(v1) do
        print_var(k2,v2,"      ")
        if v2 and type(v2) == "table" and check_parents(v2,v0,2) then
          for k3,v3 in pairs(v2) do
            print_var(k3,v3,"          ")
            if v3 and type(v3) == "table" and check_parents(v3,v0,3) then
              for k4,v4 in pairs(v3) do
                print_var(k4,v4,"              ")
              end
            end
          end
        end
      end
    end
  end
end

function print_var(k,v,indent)
  if v then
    print_info("%s%s: %s (%s)", indent, tostring(k), tostring(v), type(v))
  else
    print_info("%s%s: nil", indent, tostring(k))
  end
end

function check_parents(v,parent,layer)
  if v == parent then
    return false
  end
  if layer > 1 then
    for k1,v1 in pairs(parent) do
      if v1 and v == v1 then
        return false
      end
      if layer > 2 then
        if v1 and type(v1) == "table" then
          for k2,v2 in pairs(v1) do
            if v2 and v == v2 then
              return false
            end
            if layer > 3 then
              if v2 and type(v2) == "table" then
                for k3,v3 in pairs(v2) do
                  if v3 and v == v3 then
                    return false
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  return true
end

function WAIT_FOR_START:init()
  SORT.subfsm.states.FINAL.closure.fail_count = 0
  TAKE_HANDOFF.subfsm.states.FINAL.closure.fail_count = 0
end


