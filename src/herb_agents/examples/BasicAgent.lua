-- Initialize module
module(..., agentenv.module_init)

-- Crucial skill information
name            = "BasicAgent"
fsm             = AgentHSM:new{name=name, start="START"}
depends_skills  = {}
depends_topics  = {}


documentation      = [==[Basic Behavior Engine Agent]==]

-- Initialize as agent module
agentenv.agent_module(...)

-- Setup FSM
fsm:define_states{ export_to=_M,
  {"START", JumpState},
  {"FINAL", JumpState},
}

fsm:add_transitions{
  {"START", "FINAL", timeout=5},
}
