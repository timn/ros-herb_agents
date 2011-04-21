
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
fsm             = AgentHSM:new{name=name, debug=true, start="START", exit_state="FINAL", fail_state="FAILED", graph_collapse=false}
depends_skills  = {}
depends_actions = {}

documentation      = [==[Pick an object up and sort it. Either put in a bin or handoff to human.]==]

-- Initialize as agent module
agentenv.agent_module(...)

local ROBOT_BIN_NAME = "icebin1"
local TABLETOP_NAME_RIGHT = "tabletop1"
local TABLETOP_NAME_LEFT = "tabletop2"
local ROBOT_BIN_OBJECT_PATTERN = "poptarts[%d]*"
local HUMAN_BIN_OBJECT_PATTERN = "fuze_bottle[%d]*"
local HELP_ME_PHRASE = "I need help."
local EXEC_TIME_LIMIT = 20
local PREP_TIME_LIMIT = 20

local object_oscillator = -1

local preds = require("herb_agents.predicates.general")
local obj_preds = require("herb_agents.predicates.obj_tracking_preds")
local Skill = AgentSkillExecJumpState

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds, op=obj_preds, fail_count=0},
  {"START", JumpState},
  {"GO_INITIAL",Skill, skills={{"goinitial_both", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="PICKUP_OBJECT", 
          failure_state="GO_INITIAL_FAIL"},
  {"GO_INITIAL_FAIL",Skill, skills={{"say", text="I cannot go to my initial configuration." .. " " .. HELP_ME_PHRASE}}, 
          final_state="WAIT_FOR_HELP", 
          failure_state="WAIT_FOR_HELP"},
  {"WAIT_FOR_HELP", JumpState},
  {"PICKUP_OBJECT", JumpState},
  {"PICKUP_OBJECT_LEFT",Skill, skills={{"grab_object", side="left", object_id=(ROBOT_BIN_OBJECT_PATTERN .. "," .. HUMAN_BIN_OBJECT_PATTERN), prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="SORT_LEFT", 
          failure_state="FAILED", hide_failure_transition = true},
  {"PICKUP_OBJECT_RIGHT",Skill, skills={{"grab_object", side="right", object_id=(ROBOT_BIN_OBJECT_PATTERN .. "," .. HUMAN_BIN_OBJECT_PATTERN), prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="SORT_RIGHT", 
          failure_state="FAILED", hide_failure_transition = true},
  {"SORT_LEFT", JumpState},
  {"PLACE_INTO_BIN",Skill, skills={{"say", text="This <break time='100ms'/> goes in <prosody rate='x-slow'> my </prosody> bin."},{"put", side="left", object_id=ROBOT_BIN_NAME, prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="PLACE_BIN_GO_INITIAL_LEFT", 
          failure_state="FAILED", hide_failure_transition = true},
  {"PLACE_BIN_GO_INITIAL_LEFT",Skill, skills={{"goinitial",side="left", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="FINAL", 
          failure_state="FINAL"},
  {"CHECK_RIGHT_HAND", JumpState},
  {"PLACE_RIGHT",Skill, skills={{"place", side="right", object_id=TABLETOP_NAME_RIGHT, prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="HANDOVER_TO_RIGHT", 
          failure_state="FAILED", hide_failure_transition = true},
  {"HANDOVER_TO_RIGHT",Skill, skills={{"handover", side="left", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="HANDOVER_GO_INITIAL_LEFT", 
          failure_state="FAILED", hide_failure_transition = true},
  {"HANDOVER_GO_INITIAL_LEFT",Skill, skills={{"goinitial",side="left", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="CHECK_FOR_HUMAN", 
          failure_state="CHECK_FOR_HUMAN"},
  {"SORT_RIGHT", JumpState},
  {"CHECK_LEFT_HAND", JumpState},
  {"PLACE_LEFT",Skill, skills={{"place", side="left", object_id=TABLETOP_NAME_LEFT, prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="HANDOVER_TO_LEFT", 
          failure_state="FAILED", hide_failure_transition = true},
  {"HANDOVER_TO_LEFT",Skill, skills={{"handover", side="right", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="HANDOVER_GO_INITIAL_RIGHT", 
          failure_state="FAILED", hide_failure_transition = true},
  {"HANDOVER_GO_INITIAL_RIGHT",Skill, skills={{"goinitial",side="right", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="PLACE_INTO_BIN", 
          failure_state="PLACE_INTO_BIN"},
  {"CHECK_FOR_HUMAN", JumpState},
  {"HANDOFF_TO_HUMAN",Skill, skills={{"say", text="I am going to give you this."},{"go_to_tm", side="right", T="[0,1,0,0,0,-1,-1,0,0,0.75,-1.83,1.175]", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="HANDOFF_TO_HUMAN_GIVE", 
          failure_state="FAILED", hide_failure_transition = true},
  {"HANDOFF_TO_HUMAN_GIVE",Skill, skills={{"say", text="Please take this."},{"ft_handoff", side="right", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="HANDOFF_GO_INITIAL_RIGHT", 
          failure_state="PLACE_ON_TABLE_RIGHT"},
  {"HANDOFF_GO_INITIAL_RIGHT",Skill, skills={{"goinitial",side="right", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="FINAL", 
          failure_state="FINAL"},
  {"PLACE_ON_TABLE_LEFT",Skill, skills={{"place", side="left", object_id=TABLETOP_NAME_LEFT, prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="PLACE_GO_INITIAL_LEFT", 
          failure_state="FAILED", hide_failure_transition = true},
  {"PLACE_GO_INITIAL_LEFT",Skill, skills={{"goinitial",side="left", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="FAILED", 
          failure_state="FAILED"},
  {"PLACE_ON_TABLE_RIGHT",Skill, skills={{"place", side="right", object_id=TABLETOP_NAME_RIGHT, prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="PLACE_GO_INITIAL_RIGHT", 
          failure_state="FAILED", hide_failure_transition = true},
  {"PLACE_GO_INITIAL_RIGHT",Skill, skills={{"goinitial",side="right", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}}, 
          final_state="FAILED", 
          failure_state="FAILED"},
  {"FINAL", JumpState},
  {"FAILED", JumpState},
}

fsm:add_transitions{
  {"START", "GO_INITIAL", "not op.HERB_holding_object", desc="Not holding objects"},
  {"START", "SORT_RIGHT", "op.HERB_holding_object_in_right_hand", desc="Object in right hand"},
  {"START", "SORT_LEFT", "op.HERB_holding_object_in_left_hand", desc="Object in left hand"},
  {"WAIT_FOR_HELP", "GO_INITIAL", "p.start_button", desc="Start"},
  {"PICKUP_OBJECT", "PICKUP_OBJECT_LEFT", "vars.pickup_left", desc="Choose left"}, --"op.sortable_objects_on_left"
  {"PICKUP_OBJECT", "PICKUP_OBJECT_RIGHT", "vars.pickup_right", desc="Choose right"}, --"op.sortable_objects_on_right"
  {"PICKUP_OBJECT", "FAILED", "not (vars.pickup_left or vars.pickup_right)", hide=true, desc="Choose neither hand"},
  {"PICKUP_OBJECT", "FINAL", "(not op.sortable_objects_on_table)", hide=true, desc="No sortable objects"},
  {"SORT_LEFT", "CHECK_RIGHT_HAND", "op.left_held_object_belongs_in_human_bin", desc="Belongs in human bin"},
  {"SORT_LEFT", "PLACE_INTO_BIN", "op.left_held_object_belongs_in_robot_bin", desc="Belongs in robot bin"},
  {"SORT_LEFT", "PLACE_ON_TABLE_LEFT", "op.left_held_object_unsortable", desc="Unsortable"},
  {"CHECK_RIGHT_HAND", "HANDOVER_TO_RIGHT", "(not op.HERB_holding_object_in_right_hand)", desc="No object in right hand"},
  {"CHECK_RIGHT_HAND", "PLACE_RIGHT", "op.HERB_holding_object_in_right_hand", desc="Object in right hand"},
  {"SORT_RIGHT", "CHECK_FOR_HUMAN", "op.right_held_object_belongs_in_human_bin", desc="Belongs in human bin"},
  {"SORT_RIGHT", "CHECK_LEFT_HAND", "op.right_held_object_belongs_in_robot_bin", desc="Belongs in robot bin"},
  {"SORT_RIGHT", "PLACE_ON_TABLE_RIGHT", "op.right_held_object_unsortable", desc="Unsortable"},
  {"CHECK_LEFT_HAND", "HANDOVER_TO_LEFT", "(not op.HERB_holding_object_in_left_hand)", desc="No object in left hand"},
  {"CHECK_LEFT_HAND", "PLACE_LEFT", "op.HERB_holding_object_in_left_hand", desc="Object in left hand"},
  {"CHECK_FOR_HUMAN", "HANDOFF_TO_HUMAN", "op.human_near_table", desc="Human near table"},
  {"CHECK_FOR_HUMAN", "PLACE_ON_TABLE_RIGHT", "(not op.human_near_table)", desc="Human not near table"},
}

function get_oscillator(orig)
  for i = 0,3,1 do
    local check = check_objects((object_oscillator + i) % 4)
    print_debug("get_oscillator: check_objects(%d) = %s", (object_oscillator + i) % 4, tostring(check))
    if check == true then
      print_debug("get_oscillator: returning %d", (object_oscillator + i) % 4)
      return (object_oscillator + i) % 4
    end
  end
  print_debug("get_oscillator: returning -1")
  return -1
end

function check_objects(index)
  if index == 0 then
    return obj_preds.robot_bin_objects_on_left
  end
  if index == 1 then
    return obj_preds.robot_bin_objects_on_right
  end
  if index == 2 then
    return obj_preds.human_bin_objects_on_left
  end
  if index == 3 then
    return (obj_preds.human_bin_objects_on_right)-- and obj_preds.human_near_table)
  end
  return false
end

function PICKUP_OBJECT:init()
  self.fsm.vars.pickup_left = false
  self.fsm.vars.pickup_right = false
  local pickup_left = false
  local pickup_right = false
  local left_object_id = "NONE"
  local right_object_id = "NONE"
  local max_object_oscillator = 3 -- values: 0 to max by 1
  
  --obj_preds.sortable_objects_on_right
  --obj_preds.robot_bin_objects_on_left
  --ROBOT_BIN_OBJECT_PATTERN
  --HUMAN_BIN_OBJECT_PATTERN
  --object_oscillator
  
  -- iterate oscillator
  -- object_oscillator: 0=left/pop, 1=right/pop, 2=left/fuze, 3=right/fuze
  object_oscillator = (object_oscillator + 1) % 4
  print_debug("PICKUP_OBJECT:init(): increment object_oscillator to %d", object_oscillator)
  --if object_oscillator == 3 and (not obj_preds.human_near_table) then
  --  print_debug("PICKUP_OBJECT:init(): loop object_oscillator to 0")
  --  object_oscillator = 0 --object_oscillator + 1
  --end

  object_oscillator = get_oscillator(object_oscillator)
  print_debug("PICKUP_OBJECT:init(): get_oscillator(object_oscillator) = %d", object_oscillator)
  
  if object_oscillator == 0 then
    pickup_left = true
    left_object_id = ROBOT_BIN_OBJECT_PATTERN
  end
  if object_oscillator == 1 then
    pickup_right = true
    right_object_id = ROBOT_BIN_OBJECT_PATTERN
  end
  if object_oscillator == 2 then
    pickup_left = true
    left_object_id = HUMAN_BIN_OBJECT_PATTERN
  end
  if object_oscillator == 3 then
    pickup_right = true
    right_object_id = HUMAN_BIN_OBJECT_PATTERN
  end
  
  print_debug("PICKUP_OBJECT:init(): pickup_left = %s", tostring(pickup_left))
  print_debug("PICKUP_OBJECT:init(): pickup_right = %s", tostring(pickup_right))
  print_debug("PICKUP_OBJECT:init(): left_object_id = %s", left_object_id)
  print_debug("PICKUP_OBJECT:init(): right_object_id = %s", right_object_id)
  
  self.fsm.vars.pickup_left = pickup_left
  self.fsm.vars.pickup_right = pickup_right
  if pickup_left == true then
    self.fsm.vars.pickup_left = true
    PICKUP_OBJECT_LEFT.skills[1].args = {side="left", object_id=left_object_id}
  elseif pickup_right == true then
    self.fsm.vars.pickup_right = true
    PICKUP_OBJECT_RIGHT.skills[1].args = {side="right", object_id=right_object_id}
  end
end

function FINAL:init()
  self.closure.fail_count = 0
  print_debug("%s:FINAL:init(): reset fail_count to %d", self.fsm.name, self.closure.fail_count)
end

function FAILED:init()
  self.closure.fail_count = self.closure.fail_count + 1
  print_debug("%s:FAILED:init(): increment fail_count to %d", self.fsm.name, self.closure.fail_count)
end
