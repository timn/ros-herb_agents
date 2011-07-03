-- Initialize module
module(..., agentenv.module_init)

-- Crucial skill information
name            = "BasicSubFSM"
fsm             = AgentHSM:new{ name=name, 
                                start="START", 
                                exit_state="FINAL", 
                                fail_state="FAILED" }
depends_skills  = {}
depends_actions = {}

documentation      = [==[
    A simple subFSM. 
    The same as CounterAgent, except with the addition
    of exit_state and fail_state declarations.
                     ]==]

-- Initialize as agent module
agentenv.agent_module(...)

local COUNTER_START = 0
local MAX_COUNTER = 4

-- Setup FSM
fsm:define_states{ export_to=_M,
  closure={MAX_COUNTER=MAX_COUNTER},
  {"START", JumpState},
  {"State1", JumpState},
  {"State2", JumpState},
  {"FINAL", JumpState},
  {"FAILED", JumpState},
}

fsm:add_transitions{
  {"START", "State1", timeout=2},
  {"State1", "State2", timeout=2},
  {"State2", "State1", timeout=2},
  {"State2", "FINAL", "vars.counter >= MAX_COUNTER"},
}

function START:exit()
  self.fsm.vars.counter = COUNTER_START
  print_info("counter started at %d, counting to %d", 
                  self.fsm.vars.counter, 
                  self.fsm.current.closure.MAX_COUNTER)
end

function State1:init()
  self.fsm.vars.counter = self.fsm.vars.counter + 1
  print_debug("counter is now %d", self.fsm.vars.counter)
end

function FINAL:init()
  print_warn("counter finished with a final value of %d",
                                    self.fsm.vars.counter)
end
