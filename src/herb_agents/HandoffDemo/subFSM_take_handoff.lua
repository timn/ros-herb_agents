
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
depends_topics = {
  {v="hand_off_msg", name="/HandOffDetector/handoff_msg", type="pr_msgs/HandOff", latching=true},
}

documentation      = [==[take a handoff offered by a human]==]

-- Initialize as agent module
agentenv.agent_module(...)


local TABLETOP_NAME_RIGHT = "tabletop1"
local TABLETOP_NAME_LEFT = "tabletop2"
local HELP_ME_PHRASE = "I need help."
local EXEC_TIME_LIMIT = 20
local PREP_TIME_LIMIT = 20

local obj_count = {0,0,0,0}
local last_handoff_msg_seq = -1

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
  {"TAKE_HANDOFF", Skill, skills={{"say", text="I am ready for a handoff."}}, 
          final_state="WAIT_FOR_HANDOFF",
          failure_state="FAILED", hide_failure_transition = true},
  {"WAIT_FOR_HANDOFF", JumpState},
  {"TAKE_HANDOFF_INVJAC", Skill, skills={{"follow", side="right", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=15.0}}, 
          final_state="PICKUP_RIGHT",
          failure_state="FAILED", hide_failure_transition = true},
  {"TAKE_HANDOFF_PLANNER", Skill, skills={{"take_at_tm", side="right", T="[0,1,0,0,0,-1,-1,0,0,0.57,-1.93,1.05]", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=15.0}}, 
          final_state="PICKUP_RIGHT",
          failure_state="FAILED", hide_failure_transition = true},
  {"PICKUP_RIGHT", Skill, skills={{"pickup", side="right", prep_timelimit=PREP_TIME_LIMIT, exec_timelimit=EXEC_TIME_LIMIT}},
          final_state="DECIDE",
          failure_state="FAILED", hide_failure_transition = true},
  {"SAY_POPTARTS",Skill, skills={{"say", text="This is a poptarts box."}}, 
          final_state="FINAL",
          failure_state="FAILED", hide_failure_transition = true},
  {"SAY_FUZE",Skill, skills={{"say", text="This is a fuze bottle."}}, 
          final_state="FINAL",
          failure_state="FAILED", hide_failure_transition = true},
  {"FINAL", JumpState},
  {"FAILED", JumpState},
}

fsm:add_transitions{
  {"START", "GO_INITIAL", "true"},
  {"WAIT_FOR_HELP", "GO_INITIAL", "p.start_button", desc="Start"},
  {"DECIDE", "SAY_POPTARTS", "op.HERB_holding_object_in_right_hand and (fsm.determine_side() or (op.right_held_object_belongs_in_robot_bin))", desc="Holding a poptart"},
  {"DECIDE", "SAY_FUZE", "op.HERB_holding_object_in_right_hand", desc="Holding a fuze bottle"},
  {"DECIDE", "TAKE_HANDOFF", "(not op.HERB_holding_object_in_right_hand)", desc="No object in right hand"},
  {"TAKE_HANDOFF", "WAIT_FOR_HANDOFF", "op.human_offering_object"},
  {"WAIT_FOR_HANDOFF", "TAKE_HANDOFF_INVJAC", "op.human_offering_object"},
  {"WAIT_FOR_HANDOFF", "TAKE_HANDOFF_PLANNER", "false and op.human_offering_object"},
}

function fsm:determine_side()
  return (last_handoff_msg_seq > -1 and obj_count[2] > obj_count[3])
end

function TAKE_HANDOFF_PLANNER:init()
  last_handoff_msg_seq = -1
  obj_count = {0,0,0,0}
  if #hand_off_msg.messages > 0 then
    local m = hand_off_msg.messages[#hand_off_msg.messages]
    local x = m.values.point_world.values.x + -0.10
    local y = m.values.point_world.values.y + -0.12
    local z = m.values.point_world.values.z + 0.075
    self.skills[1].T = "[0,1,0,0,0,-1,-1,0,0," .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z) .. "]"
    self.skill_queue = SkillQueue:new{name=self.name, skills=self.skills}
  end
end

function TAKE_HANDOFF_PLANNER:loop()
  if #hand_off_msg.messages > 0 then
    local m = hand_off_msg.messages[#hand_off_msg.messages]
    if m.values.header.values.seq ~= last_handoff_msg_seq then
      last_handoff_msg_seq = m.values.header.values.seq
      obj_id = m.values.object
      obj_count[obj_id + 1] = obj_count[obj_id + 1] + 1
    end
  end
end

function TAKE_HANDOFF_PLANNER:exit()
  print_table(obj_count)
end

function FINAL:init()
  self.fsm.current.closure.fail_count = 0
  print_debug("%s:FINAL:init(): reset fail_count to %d", self.fsm.name, self.fsm.current.closure.fail_count)
end

function FAILED:init()
  self.fsm.current.closure.fail_count = self.fsm.current.closure.fail_count + 1
  print_debug("%s:FAILED:init(): increment fail_count to %d", self.fsm.name, self.fsm.current.closure.fail_count)
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
