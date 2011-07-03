-- Initialize module
module(..., skillenv.module_init)

-- Crucial skill information
name            = "BasicSkill"
fsm             = SkillHSM:new{name=name, start="START"}
depends_skills  = {}
depends_actions = {}
depends_topics  = {}

documentation      = [==[Basic Behavior Engine Skill]==]

-- Initialize as skill module
skillenv.skill_module(_M)

-- Setup FSM
fsm:define_states{ export_to=_M,
  {"START", JumpState},
}


fsm:add_transitions{
  {"START", "FINAL", timeout=5},
}
