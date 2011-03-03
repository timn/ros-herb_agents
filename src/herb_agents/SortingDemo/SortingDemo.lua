
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
INSTRUCTIONS = "Lets collaborate to put these items where they belong. If you are familiar with this task, you may press the button and we can begin. The pop tarts belong in my bin. The fuze bottles belong in your bin. I will need you to pass me pop tarts that are out of my reach. Likewise, I will pass you fuze bottles that are near me."

local preds = require("herb_agents.predicates.general")
local obj_preds = require("herb_agents.predicates.obj_tracking_preds")
local Skill = AgentSkillExecJumpState
local SubFSM = SubFSMJumpState

local subFSM_sort = require("herb_agents.SortingDemo.subFSM_sort")
local subFSM_calibrate_human_tracker = require("herb_agents.SortingDemo.subFSM_calibrate_human_tracker")
local subFSM_take_handoff = require("herb_agents.SortingDemo.subFSM_take_handoff")

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds, op=obj_preds, TIMEOUT_INDIFFERENCE=TIMEOUT_INDIFFERENCE},
  {"START", JumpState},
  {"FINAL", JumpState},
  {"GOTO_TABLE",Skill, skills={{"say", text="Moving to the table. I assume I am already at the table."}}, 
          final_state="WAIT_FOR_HUMAN", 
          failure_state="FINAL"},
  {"WAIT_FOR_HUMAN",JumpState},
  {"INIT_HUMAN_TRACKER",SubFSM, subfsm=subFSM_calibrate_human_tracker.fsm, 
          exit_to="INSTRUCTIONS", 
          fail_to="GOTO_TABLE"},
  {"INSTRUCTIONS",Skill, skills={{"say", text=INSTRUCTIONS}}, 
          final_state="SORT", 
          failure_state="SORT"},
  {"SORT",SubFSM, subfsm=subFSM_sort.fsm, 
          exit_to="SORT_LOOP", 
          fail_to="SORT_LOOP"},
  {"SORT_LOOP",JumpState},
  {"TAKE_HANDOFF",SubFSM, subfsm=subFSM_take_handoff.fsm, 
          exit_to="SORT", 
          fail_to="SORT"},
}

fsm:add_transitions{
  {"START", "GOTO_TABLE", "p.start_button"},
  {"FINAL", "GOTO_TABLE", "true"},
  {"WAIT_FOR_HUMAN", "INIT_HUMAN_TRACKER", "op.human_near_table"},
  {"INIT_HUMAN_TRACKER", "INSTRUCTIONS", "op.human_tracking_working"},
  {"INSTRUCTIONS", "SORT", "p.HRI_yes"},
  {"SORT_LOOP", "SORT", "op.objects_on_table"},
  {"SORT_LOOP", "FINAL", "not op.objects_on_table and not op.human_holding_object"},
  {"SORT_LOOP", "TAKE_HANDOFF", "op.human_offering_object"},
  {"SORT_LOOP", "GOTO_TABLE", "not op.human_near_table or not op.human_tracking_working"},

--  {"WAIT_FOR_HUMAN", "INIT_HUMAN_TRACKER", "p.HRI_yes"},
--  {"INIT_HUMAN_TRACKER", "INSTRUCTIONS", "p.HRI_yes"},
--  {"SORT_LOOP", "SORT", "p.HRI_yes"},
--  {"SORT_LOOP", "FINAL", "p.HRI_no"},
--  {"SORT_LOOP", "TAKE_HANDOFF", "p.start_button"},
--  {"SORT_LOOP", "GOTO_TABLE", "false"},
}

