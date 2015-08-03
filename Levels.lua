OrbitFunc = function(center, radius, period, shift)
	local t = (AbsolutTime + (shift or 0)) * period

	local x,y = math.cos(t),math.sin(t)


	return center + vector(x,y) * radius 
end


AvailableLevels = {
	Level1 = {
		Planets = {
			{
				Position = vector(450,6200),
				-- Masse = 750000,
				Masse = 500 * 1000 * 1000,
				Radius = 5500,
			},
		},
		Launcher = {
			Position = vector(82,712),
		},
	},
	Level2 = {
		Planets = {
			{
				Position = vector(450,400),
				Masse = 750000,
				Radius = 150,
			},
		},
		Launcher = {
			Position = vector(450,250),
		},
	},
	Level3 = {
		Planets = {
			{
				Position = vector(450,400),
				Masse = 750000 * .8,
				Radius = 75,
			},
			{
				Position = vector(650,150),
				Masse = 250000,
				Radius = 25,

				Update = function(o)
					o.Position = OrbitFunc(AvailableLevels.Level3.Planets[1].Position,250,.05)
				end,
			},
		},
		Launcher = {
			Position = vector(450,325),
		},
	},
	Level4 = {
		Planets = {
			{
				Position = vector(450,400),
				Masse = 750000 * .25,
				Radius = 37.5,
			},
			{
				Position = vector(580,230),
				Masse = 250000,
				Radius = 13,
				Update = function(o)
					o.Position = OrbitFunc(AvailableLevels.Level4.Planets[1].Position,250,.05)
				end,
			},
			{
				Position = vector(100,120),
				Masse = 210000,
				Radius = 9,
				Update = function(o)
					o.Position = OrbitFunc(AvailableLevels.Level4.Planets[4].Position,60,.4, 30)
				end,
			},
			{
				Position = vector(495,710),
				Masse = 290000,
				Radius = 17,
				Update = function(o)
					o.Position = OrbitFunc(AvailableLevels.Level4.Planets[1].Position,350,.04, 120)
				end,
			},
		},
		Launcher = {
			Position = vector(450,362.5),
		},
	}
}

CurrentLevel = {
	LevelName = "none",
	Planets = {},


	Update = function(o,dt)
		for _,planet in pairs(o.Planets) do
			if planet.Update then
				planet:Update(dt)
			end
		end
	end,

	Draw = function(o)
		for _,planet in pairs(o.Planets) do
			love.graphics.setColor(255,255,255)
			love.graphics.circle("fill", planet.Position.x,planet.Position.y, planet.Radius)
		end
	end,
}

LoadLevel = function(levelName)
	local base = AvailableLevels[levelName] 
	if base then
		CurrentLevel.LevelName = levelName

		CurrentLevel.Planets = base.Planets
		
		for key,value in pairs(base.Launcher) do
			Launcher[key] = value
		end
	else 
		CurrentLevel.LevelName = "none"
		CurrentLevel.Planets = {}
	end
	return true
end