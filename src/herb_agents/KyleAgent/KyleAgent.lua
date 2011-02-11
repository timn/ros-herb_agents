
----------------------------------------------------------------------------
--  KyleAgent.lua
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
name               = "KyleAgent"
fsm                = AgentHSM:new{name=name, debug=true, start="START"}
depends_skills     = {"say","goinitial"}
depends_topics     = {}

documentation      = [==[Kyle Agent: for testing.]==]

-- Initialize as agent module
agentenv.agent_module(...)


TIMEOUT_INDIFFERENCE = 10

local fpc = {{2.13,-1.69,0.75},{1.83,-1.84,0.75},{1.83,-1.54,0.75}} --Fuze Pyramid Corners

function getMidPointStr(p1, p2)
  mid = {}
  midStr = ""
  for i,v in pairs(p1) do
    if midStr ~= "" then
       midStr = midStr .. ","
    end
    if p2[i] then
      mid[i] = (p1[i] + p2[i])/2
      midStr = midStr .. tostring(mid[i])
    end
  end
  return midStr
end

local stack = {
      { goal="JustDoIt", skills={{"grab_object", object_id="fuze_bottle",side="left"}} },
      { goal="JustDoIt", skills={{"place", side="left", object_id="tabletop1@(" .. getMidPointStr(fpc[1],fpc[1]) .. ")"}} },
      { goal="JustDoIt", skills={{"grab_object", object_id="fuze_bottle",side="left"}} },
      { goal="JustDoIt", skills={{"place", side="left", object_id="tabletop1@(" .. getMidPointStr(fpc[1],fpc[2]) .. ")"}} },
      { goal="JustDoIt", skills={{"grab_object", object_id="fuze_bottle",side="left"}} },
      { goal="JustDoIt", skills={{"place", side="left", object_id="tabletop1@(" .. getMidPointStr(fpc[2],fpc[2]) .. ")"}} },
      { goal="JustDoIt", skills={{"grab_object", object_id="fuze_bottle",side="left"}} },
      { goal="JustDoIt", skills={{"place", side="left", object_id="tabletop1@(" .. getMidPointStr(fpc[1],fpc[3]) .. ")"}} },
      { goal="JustDoIt", skills={{"grab_object", object_id="fuze_bottle",side="left"}} },
      { goal="JustDoIt", skills={{"place", side="left", object_id="tabletop1@(" .. getMidPointStr(fpc[2],fpc[3]) .. ")"}} },
      { goal="JustDoIt", skills={{"grab_object", object_id="fuze_bottle",side="left"}} },
      { goal="JustDoIt", skills={{"place", side="left", object_id="tabletop1@(" .. getMidPointStr(fpc[3],fpc[3]) .. ")"}} },
              }

local preds = require("herb_agents.predicates.general")
local Skill = AgentSkillExecJumpState
local SubFSM = SubFSMJumpState

local goal_achieved = require("herb_agents.KyleAgent.goal_achieved")
local goal_feasible = require("herb_agents.KyleAgent.goal_feasible")
local watch_exec_skill = require("herb_agents.KyleAgent.watch_exec_skill")

--QUICKJUMP = "EXEC_SKILL"

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds, TIMEOUT_INDIFFERENCE=TIMEOUT_INDIFFERENCE},
  {"START", JumpState},
  {"FINAL", JumpState},
  {"STACK_EMPTY",JumpState},
  {"GOAL_ACHIEVED",SubFSM, subfsm=goal_achieved.fsm, 
          exit_to="GOTO_NEXT_TASK", 
          fail_to="ASK_FOR_TURN"},
  {"GOTO_NEXT_TASK",Skill, skills={{"say", text="Moving to next task."}}, 
          final_state="STACK_EMPTY", 
          failure_state="STACK_EMPTY"},
  {"ASK_FOR_TURN",Skill, skills={{"say", text="Should I do this task?"}}, 
          final_state="WAIT_FOR_TURN", 
          failure_state="WAIT_FOR_TURN"},
  {"WAIT_FOR_TURN", JumpState},
  {"WATCH_EXEC_SKILL",SubFSM, subfsm=watch_exec_skill.fsm, 
          exit_to="GO_INITIAL", 
          fail_to="GO_INITIAL"},
  {"EXEC_SKILL",Skill, 
          final_state="GO_INITIAL", 
          failure_state="GO_INITIAL"},
  {"GO_INITIAL", Skill, skills={{"goinitial", side="left"}},
          final_state="STACK_EMPTY", 
          failure_state="STACK_EMPTY"},
  {"ALL_DONE",Skill, skills={{"say", text="That was all of the tasks."}}, 
          final_state="FINAL", 
          failure_state="FINAL"},
}

fsm:add_transitions{
  {"START", QUICKJUMP or "STACK_EMPTY", "p.start_button"},
  {"STACK_EMPTY", "ALL_DONE", "vars.stack_task_num > #vars.stack"},
  {"STACK_EMPTY", "GOAL_ACHIEVED", "vars.stack_task_num <= #vars.stack"},
  --{"GOAL_ACHIEVED", "GOTO_NEXT_TASK", "p.HRI_yes"},
  --{"GOAL_ACHIEVED", "ASK_FOR_TURN", "p.HRI_no"},
  {"WAIT_FOR_TURN", "WATCH_EXEC_SKILL", "p.HRI_no"},
  {"WAIT_FOR_TURN", "EXEC_SKILL", "p.HRI_yes"},
  {"WAIT_FOR_TURN", "EXEC_SKILL", timeout=TIMEOUT_INDIFFERENCE},
  {"FINAL", "START", "p.start_button"},
}


function START:init()
  self.fsm:reset_trace()
  for k,_ in pairs(self.fsm.vars) do
     self.fsm.vars[k] = nil
  end
  self.fsm.vars.stack = stack
  self.fsm.vars.stack_task_num = 1
end

function GOTO_NEXT_TASK:init()
  self.fsm.vars.stack_task_num = self.fsm.vars.stack_task_num + 1
end

function EXEC_SKILL:init()
  for k1, v1 in pairs(self.skills) do
    self.skills[k1] = nil
  end
  for k1, v1 in pairs(self.fsm.vars.stack[self.fsm.vars.stack_task_num].skills) do
    table.insert(self.skills, v1)
  end
  self.skill_queue = SkillQueue:new{name=self.name, skills=self.skills}
end

function GOAL_ACHIEVED:init()
  skills = self.fsm.vars.stack[self.fsm.vars.stack_task_num].skills
  if #skills == 1 then
    skill = skills[1][1]
    if skill == "say" then
      goal_text = string.format("The current goal is to say %s. Has this been done?",skills[1].text)
    elseif skill == "grab_object" then
      object = skills[1].object_id
      a,b,c,d,e,f = string.find(object, '^([^_%d]*)(%d*)_?([^_%d]*)(%d*)$')
      if a ~= nil then
          objectStr = c .. " "  .. d .. " "  .. e .. " "  .. f
      else
          objectStr = object
      end
      goal_text = string.format("The current goal is to grab %s. Has this been done?",objectStr)
    elseif skill == "place" then
      object = skills[1].object_id
      a,b,c,d,e,f,g = string.find(object, '^([^_@%d]*)(%d*)_?([^@_%d]*)(%d*)@?([^@]*)$')
      if a ~= nil then
          objectStr = c .. " " .. d .. " "  .. e .. " "  .. f
      else
          objectStr = object
      end
      goal_text = string.format("The current goal is to place the grabbed object onto %s. Has this been done?",objectStr)
    else
      object = ""
      for i,v in skills[1] do
        if i ~= 1 and i ~= "side" then
          object = object .. " " .. v
        end
      end
      goal_text = string.format("The current goal is to %s %s. Has this been done?", skill, object)
    end
  elseif #(skills) > 1 then
    goal_text = "The current goal has multiple skills, is it achieved?"
  else
    goal_text = "Goal is empty. This goal has been accomplished."
  end
    self.subfsm.vars.text = goal_text
end


