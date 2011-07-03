-- Initialize module
module(..., agentenv.module_init)

-- Crucial skill information
name               = "SimpleAgentWithSubFSM"
fsm                = AgentHSM:new{name=name, debug=true, start="START"}
depends_skills     = {"say","goinitial"}
depends_topics     = {}

documentation      = [==[
    A simple agent demonstrating the use of a subFSM.
                     ]==]

-- Initialize as agent module
agentenv.agent_module(...)

local BasicSubFSM = require("herb_agents.examples.BasicSubFSM")

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={p=preds, TIMEOUT_INDIFFERENCE=TIMEOUT_INDIFFERENCE},
  {"START", JumpState},
  {"FINAL", JumpState},
  {"FAILED", JumpState},
  {"EXECUTE_SUB_FSM", SubFSMJumpState, subfsm=BasicSubFSM.fsm, 
          exit_to="FINAL", 
          fail_to="FAILED"},
}

fsm:add_transitions{
  {"START", "EXECUTE_SUB_FSM", timeout=2},
  {"EXECUTE_SUB_FSM", "FINAL", "false"},
  {"FINAL", "START", timeout=5},
}
