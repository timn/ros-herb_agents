
----------------------------------------------------------------------------
--  init.lua - Research at Intel Day Agent mockup
--
--  Created: Mon Jul 02 14:22:58 2010
--  License: BSD, cf. LICENSE file
--  Copyright  2010  Tim Niemueller [www.niemueller.de]
--             2010  Carnegie Mellon University
--             2010  Intel Labs Pittsburgh
----------------------------------------------------------------------------

-- Initialize module
module(..., agentenv.module_init)

-- Crucial skill information
name               = "RAID2010"
fsm                = AgentHSM:new{name=name, debug=true, start="START"}
depends_skills     = {"move_arm", "handoff", "grab", "say", "put", "hand", "wam"}
depends_interfaces = {}

documentation      = [==[Research At Intel Day 2010.
Mockup of how that agent could look like in the Fawkes BE.
]==]

-- Initialize as agent module
agentenv.agent_module(...)

function jc_start()
   return false -- replace with check if start button was pushed
end

function jc_from_match(s)
   return function ()
	     return grab.fsm.error:match(s)
	  end
end

-- Setup FSM
fsm:add_transitions{
   {"START", "WELCOME", jc_start, desc="Pushed START", precond=true},

   {"WELCOME", "ARMS_INITIAL",
    skills={{"say", {text="Hello World", wait=true}}}, timeout=2},

   {"ARMS_INITIAL", "GRAB_STUFF",
    skills={{"move_arm", {arm="both", position="initial"}}},
    timeout={2, "NO_PLANNER"}},
   {"ARMS_INITIAL", "OPEN_HAND", jc_from_match("Planner failed.*")},

   {"GRAB_STUFF", "ANNOUNCE_HANDOFF", -- assume grab skill = grasp + lift
    skills={{"grab", {object="FUZE"}}}, fail_to="FAILED", timeout={10, "NO_PLANNER"}},
   {"GRAB_STUFF", "GRAB_AGAIN", jc_from_match("Hand is closed without object.*"),
    desc="No object"},
   {"GRAB_STUFF", "ANNOUNCE_OPEN_HAND", jc_from_match("Lifted config in collision.*"),
    desc="HomePos failed"},

   {"ANNOUNCE_OPEN_HAND", "OPEN_HAND",
    skills={{"say", {text="Something is in my way", wait=true}}}, timeout=2},
   {"OPEN_HAND", "RELAX_HAND", skills={{"hand", {action="open"}}}, timeout=2},
   {"RELAX_HAND", "FAILED", skills={{"wam", {action="relax"}}}, timeout=5},

   {"GRAB_AGAIN", "ARMS_INITIAL",
    skills={{"say", {text="Let me try again", wait=true}}}, timeout=2},

   {"NO_PLANNER", "START", timeout=2,
    skills={{"say", {text="No planner loaded", wait=true}}}},

   {"ANNOUNCE_HANDOFF", "HANDOFF",
    skills={{"say", {text="Please take the drink", wait=true}}}, timeout=2},

   {"HANDOFF", "ENJOY",
    skills={{"handoff", {action="give"}}}, fail_to="ANNOUNCE_HANDOFF",
    timeout={2, "ANNOUNCE_RECYCLING"}},

   {"ENJOY", "ANNOUNCE_TAKE", skills={{"say", {text="Enjoy.", wait=true}}}},

   {"ANNOUNCE_TAKE", "TAKE",
    skills={{"say", {text="Please give me your empty bottle.", wait=true}}}, timeout=2},

   {"TAKE", "ANNOUNCE_RECYCLING",
    skills={{"handoff", {action="take"}}}, fail_to="FAILED", timeout={2, "FAILED"}},

   {"ANNOUNCE_RECYCLING", "RECYCLE",
    skills={{"say", {text="Good robots recycle empty bottles.", wait=true}}}},

   {"RECYCLE", "ANNOUNCE_RECYCLING_DONE",
    skills={{"put", {object="FUZE", where="recycling_bin"}}},
    fail_to="ANNOUNCE_RECYCLING_FAILED"},

   {"ANNOUNCE_RECYCLING_FAILED", "ARMS_INITIAL_DONE",
    skills={{"say", {text="Failed to recycle. Maybe next time.", wait=true}}},
    fail_to="ARMS_INITIAL_DONE"},

   {"ANNOUNCE_RECYCLING_DONE", "ARMS_INITIAL_DONE",
    skills={{"say", {text="Saving the environment is fun.", wait=true}}}},

   {"ARMS_INITIAL_DONE", "FINAL",
    skills={{"move_arm", {arm="both", position="initial"}}}, fail_to="FAILED"},
    

   {"FINAL", "START", true, desc="restart", precond=true},
   {"FAILED", "START", true, desc="restart", precond=true}
}
