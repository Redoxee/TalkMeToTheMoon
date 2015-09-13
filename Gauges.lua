_Gauge = {
	Position = vector(0,0),
	Size = vector(0,0),

	Completion = 0,
	GraphicCompletion = 0,

	Update = function(o,dt)
		o.GraphicCompletion = damping(1.5,o.GraphicCompletion,o.Completion,dt)
	end,

	Draw = function(o)
		local s = o.Size
		local p = o.Position +vector(-.5 * s.x,.5 * s.y)

		local h = -o.GraphicCompletion * s.y
		love.graphics.setColor(205,207,0)
		love.graphics.rectangle("fill",p.x,p.y,s.x,h)
	end,

	Initialize = function(o)
		GaugeManager:Register(o)
	end,

	Deinitialize = function(o)
		GaugeManager:Initialize(o)
	end,
}

GaugeManager = {
	Gauges = {},

	Initialize = function(o)
		o.Gauges = {}
	end,

	Update = function(o,dt)
		for i,g in ipairs(o.Gauges) do
			g:Update(dt)
		end
	end,

	Draw = function(o)
		for i,g in ipairs(o.Gauges) do
			g:Draw()
		end
	end,

	Register = function(o,g)
		if not ListFind(o.Gauges,g) then
			table.insert(o.Gauges,g)
		end
	end,

	Unregister = function(o,g)
		if ListFind(o.Gauges,g) then
			table.remove(o.Gauges,g)
		end
	end,
}


CreateGauge = function(params)
	local o = {}
	for k,v in pairs(_Gauge) do
		o[k] = v
	end
	if params then
		for k,v in pairs(params) do
			o[k] = v
		end
	end
	o:Initialize()
	return o
end 