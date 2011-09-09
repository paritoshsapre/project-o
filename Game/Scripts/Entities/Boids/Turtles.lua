Script.ReloadScript( "Scripts/Entities/Boids/Chickens.lua" );

Turtles = {
	Properties = {
		Boid = 
		{
			object_Model = "Objects/Characters/Animals/turtles/red_eared_slider/red_eared_slider.chr",
		},
	},
	Sounds = 
	{
                          "Sounds/environment:random_oneshots_natural:turtle_idle",   -- idle
                          "Sounds/environment:random_oneshots_natural:turtle_scared",  -- scared
                          "Sounds/environment:random_oneshots_natural:turtle_scared",    -- die
                          "Sounds/environment:random_oneshots_natural:turtle_scared",  -- pickup
                          "Sounds/environment:random_oneshots_natural:turtle_scared",  -- throw
	},
	Animations = 
	{
		"walk_loop",   -- walking
		"idle_loop",      -- idle1
		"scared",      -- scared anim
		"idle_loop",      -- idle3
		"idle_loop",      -- pickup
		"idle_loop",      -- throw
	},
	Editor = {
		Icon = "Bird.bmp"
	},
}

MakeDerivedEntityOverride( Turtles,Chickens )


function Turtles:OnSpawn()
	self:SetFlags(ENTITY_FLAG_CLIENT_ONLY, 0);
end

function Turtles:GetFlockType()
	return Boids.FLOCK_TURTLES;
end