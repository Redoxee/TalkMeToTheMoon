vector = require "Utils.HUMP.vector"
require "functionLib"
require "Levels"
require "Inputs"
require "FXManager"

MAX_DT = 0.08

TIMEFACTOR = 2

MAX_DISTANCE2 = 800 * 800

function GetForce(position, mass, objects, dt) 
	local cumulativForces = vector(0,0)
	for i = 1,#objects do
		obj = objects[i]
		local dif = ( obj.Position - position)
		cumulativForces = cumulativForces + dif:normalized() * mass * obj.Masse / dif:len2()
	end
	return cumulativForces
end

IntegrationStep = 0

function Integrate(originalPosition, originalVelocity, originalAcceleration, mass, objects, dt, maxDt)
	local r = dt / maxDt
	local iteration,rest = math.floor(dt/maxDt) , dt%maxDt

	IntegrationStep = iteration + 1

	local position = originalPosition
	local velocity = originalVelocity
	local acceleration = originalAcceleration

	if iteration > 0 then
		for i = 1,iteration do
			acceleration =  GetForce(position, mass, objects, maxDt)
			velocity = velocity + acceleration * maxDt
			position = position + velocity * maxDt
		end
	end

	acceleration = GetForce(position, mass, objects, rest)
	velocity = velocity + acceleration * rest
	position = position + velocity * rest

	return position,velocity,acceleration

end

Launcher = {
	Position = vector(450,250),
		
	ChargeVector = false,

	Initialize = function(o)

		RegisterMouseInput("l","down", function() o:OnPress() end)
		RegisterMouseInput("l","drag", function() o:OnDrag() end)
		RegisterMouseInput("l","up", function() o:OnRelease() end)

	end,


	Draw = function(o)
		love.graphics.setColor(128,128,255)
		love.graphics.circle("fill",o.Position.x,o.Position.y,4.5)

		if o.ChargeVector then
			local vPos = o.Position + o.ChargeVector
			love.graphics.setColor(64,128,192)
			love.graphics.line(o.Position.x,o.Position.y, vPos.x,vPos.y)
		end
 	end,

 	MoveSpeed = 30,
	PadForce = 70,
	CurrentCharge = false,
	Update = function(o,dt)
		local displacment = GPad.Left * o.MoveSpeed * dt
		o.Position = o.Position + displacment
	
		local force = GPad.Right
		if force:len2() > 0.05 then
			force = force * o.PadForce

			o.CurrentCharge = force
			
			o:Spread(force:len(),force,1)
		else
			o.CurrentCharge = false
		end
	end,

	ComputCharge = function(o)
		local direction = MouseHold.Position - MouseHold.StartPosition
		o.ChargeVector = direction:normalized() * math.sqrt(direction:len()) * 4
	end,

	OnPress = function(o)
		-- o.Position = MouseHold.StartPosition
	end,

	OnRelease = function(o)
		o:ComputCharge()

		o:Launch(o.ChargeVector)
		
		o.ChargeVector = false
	end,

	OnDrag = function(o)
		o:ComputCharge()
	end,

	Pulse = function(o, force, iteration)
		for i = 0,iteration do
			local a = math.pi * 2 * i / iteration
			local x,y = math.cos(a), math.sin(a)
			o:Launch(vector(x,y) * force)
		end
	end,


	_GetRandomSpreadVector = function(o)
		local r = math.random() * 2 * math.pi
		return vector(math.cos(r),math.sin(r)) * math.random()
	end,

	SpreadMaxRadius = .5,
	SpreadMinRadius = .0,
	SpreadRadiusForceMin = 40,
	SpreadRadiusForceMax = 130,
	Spread = function(o, force, direction, spreadRate)
		for i = 1,spreadRate do
			local p = math.min(o.SpreadRadiusForceMax, math.max(o.SpreadRadiusForceMin,force))
			p = (p - o.SpreadRadiusForceMin)/(o.SpreadRadiusForceMax - o.SpreadRadiusForceMin)
			p = (o.SpreadMaxRadius - o.SpreadMinRadius) * (1-p) + o.SpreadMinRadius
			local vec = direction:normalized() + o:_GetRandomSpreadVector() * p
			vec = vec * force
			o:Launch(vec)
		end
	end,

	Launch = function(o,launchDirection)
		local velocity = launchDirection

		local proj = {
			Position = o.Position,
			Velocity = velocity,
			Mass = 2,
		}

		ProjectilManager:AddProjectil(proj)
	end,
}


ProjectilManager = {
	HardCap = 1500,

	AddProjectil = function(o, proj)
		if #Projectils < o.HardCap then
			proj.StartTime = AbsolutTime
			ListInsert(Projectils,proj)
		end
	end,

	Initialize = function(o)
	end,

	Update = function(o,dt)
	end,
}

Projectils= {
	--[[
		{
			Position = ...
			Velocity = ...
			Mass = ...
		},
	--]]
}

Collidables = {}

_Projectils = {

	Initialize = function(o)
		Collidables = {}
    	Projectils = {}
	end,

	PointInterval = .15,
	PointAcc = .5,

	ProjectilRadius = 3,

	ToRemoves = {},
	RemoveProjectils = function(o)
		ListSort(o.ToRemoves)
		for i = #o.ToRemoves, 1 , -1 do
			ListRemove(Projectils,o.ToRemoves[i])
		end
		o.ToRemoves = {}
	end,

	Update = function(o,dt)
		o.PointAcc = o.PointAcc - dt
		local addPoints = false
		if o.PointAcc < 0 then
			o.PointAcc = o.PointInterval
			addPoints = true
		end

		local masses = CurrentLevel.Planets

		local r2s = {}
		for i,plnt in ipairs(masses) do
			r2s[i] = plnt.Radius * plnt.Radius
		end

		for i = 1, #Projectils do
			p = Projectils[i]
	
			p.Position, p.Velocity = Integrate(p.Position, p.Velocity, vector(0,0), p.Mass, masses,dt, MAX_DT)
		
			local removed = false
			for j,r2 in ipairs(r2s) do
				if p.Position:dist2(masses[j].Position) < r2 then
					_DeadProjectils:AddDeadProjectil(p.Position)
					table.insert(o.ToRemoves, i)
					removed = true
					break
				end
			end
			if not removed then
				local dist = p.Position:dist2(vector(WindowSize[1],WindowSize[2]) / 2)
				if dist > MAX_DISTANCE2 then
					-- Print(tostring(dist))
					table.insert(o.ToRemoves, i)
					removed = true
				end
			end

			if addPoints then
				_DotPointManager:AddPoint(p.Position)
			end
		end

		o:RemoveProjectils()
	end,

	Draw = function(o)
	
		love.graphics.setColor(128,128,255)
		for i = 1,#Projectils do
			p = Projectils[i]
			love.graphics.circle("fill",p.Position.x,p.Position.y,o.ProjectilRadius)
		end
	end,


	CheckProjectileCollision = function()
		local colls = {}
		for i = 1,#Projectils do
			local p = Projectils[i]
			for j= 1,#Collidables do
				c = Collidables[i]
				local dist2 = p.Position:dist2(c.Position)
				local r2 = o.ProjectilRadius + (c.Radius or 0) 
				r2 = r2 * r2
				if dist2 < r2 then
					ListInsert(colls,{P = p, C = c})
				end 
			end
		end

		for i = 1,#colls do
			local col = colls[i]
			if col.C.OnCollision then
				col.C:OnCollision(col)
			end
		end
	end,
}

SearchForNearestProjectil = function(position)
	local minDist2 = false
	local pIndex = 0
	for i = 1,#Projectils do
		local p = Projectils[i]
		local sd = p.Position:dist2(position)
		if not minDist2 or sd < minDist2 then
			minDist2 = sd
			pIndex = i
		end
	end
	return minDist2, pIndex
end

DeadProjectils = {}
_DeadProjectils = {
	IsEnabled = false,
	Projectils = {},
	Initialize = function(o)
		DeadProjectils = {}
	end,

	Draw = function(o)
		if o.IsEnabled then
			love.graphics.setColor(255,127,0)
			for i = 1, #DeadProjectils do
				local p = DeadProjectils[i]
				love.graphics.circle("fill",p.x,p.y,4)
			end
		end
	end,

	AddDeadProjectil = function(o,position)
		if o.IsEnabled then
			table.insert(DeadProjectils,position)
		end
	end,
}

DotPoints = {}
_DotPointManager = {
	Accumulator = 0,
	DotDuration = 1,
	Initialize = function(o)
		DotPoints = {}
	end,
	AddPoint = function(o,position)
		ListInsert(DotPoints,1,{Position = position , Stamp = o.Accumulator + o.DotDuration})
	end,

	Update = function(o,dt)
		o.Accumulator = o.Accumulator + dt
		
		for i = #DotPoints, 1, -1 do
			if DotPoints[i].Stamp < o.Accumulator then
				ListRemove(DotPoints,i)
			else
				break
			end
		end
	end,

	Draw = function(o)
		love.graphics.setColor(128,128,0)
		for i = 1,#DotPoints do
			local d = DotPoints[i]
			love.graphics.circle("fill",d.Position.x,d.Position.y,1)
		end
	end,
}

LaunchZone = {
	Points = {},
	Initialize = function(o)
		FXManager.GreenZone.PolygonPoints = o.Points
	end,
}

World = {
	LevelIndex = false,
	LevelsAvailable = {"Level1","Level2","Level3","Level4"},

	Initialize = function(o)
		o.LevelIndex = 0
		o:OnNextPressed()

		local nLevel = function()
			o:OnNextPressed()
		end
		local pLevel = function()
			o:OnPrevPressed()
		end
		
		KeyboardHolder:RegisterListener("n",nLevel)
		GPad:RegisterListener("rightshoulder",nLevel)
		GPad:RegisterListener("leftshoulder",pLevel)
	end,

	OnNextPressed = function(o)
		local i = ((o.LevelIndex) % #o.LevelsAvailable) + 1
		o:SwitchLevel(i)
	end,
	
	OnPrevPressed = function(o)
		local i = o.LevelIndex - 1
		if i < 1 then 
			i = #o.LevelsAvailable
		end
		o:SwitchLevel(i)
	end,

	SwitchLevel = function(o,levelIndex)
		AbsolutTime = 0
		o.LevelIndex = levelIndex
		Print("Level index : " .. tostring(o.LevelIndex) )
		-- clear projectiles
		_Projectils:Initialize()
		_DotPointManager:Initialize()
		_DeadProjectils:Initialize()
		-- load level
		LoadLevel(o.LevelsAvailable[o.LevelIndex])
	end,
}

Controller = {
	DeleteRadius = 35 * 35,

	DeleteTarget = false,

	Initialize = function(o)
		RegisterMouseInput("r","down", function() o:OnDeleteAction() end)
	end,

	Update = function(o)
		o:_UpdateDeletable()
	end,


	_UpdateDeletable = function(o)
		local mPosition = MouseHold.Position 
		local minDist2, pIndex = SearchForNearestProjectil(mPosition)

		if minDist2 and minDist2 < o.DeleteRadius then
			FXManager.RedContourTarget = Projectils[pIndex].Position
			o.DeleteTarget = pIndex
		else
			FXManager.RedContourTarget = false
			o.DeleteTarget = false
		end
	end,

	OnDeleteAction = function(o)
		if o.DeleteTarget then
			ListInsert(_Projectils.ToRemoves,o.DeleteTarget)
			Print("Deleting " ..  tostring (o.DeleteTarget))
		end
	end,
}

Initialize = function()
	World:Initialize()
	Launcher:Initialize()
	FXManager:Initialize()
	Controller:Initialize()
	ProjectilManager:Initialize()
	LaunchZone:Initialize()

	---[[
	table.insert(Updatables, Launcher)
	table.insert(Updatables, ProjectilManager)
	table.insert(Updatables, CurrentLevel)
	table.insert(Updatables, _Projectils)
	table.insert(Updatables, _DotPointManager)
	table.insert(Updatables, Controller)
	-- table.insert(Updatables, FXManager)
	-- table.insert(Updatables, Ship)
	--]]

	---[[
	table.insert(Drawables, _DotPointManager)
	table.insert(Drawables, CurrentLevel)
	table.insert(Drawables, Launcher)
	table.insert(Drawables, _Projectils)
	table.insert(Drawables, _DeadProjectils)
	-- table.insert(Drawables, FXManager)
	-- table.insert(Drawables, Ship)
	--]]
end

KeyboardHolder:RegisterListener("p",function() Launcher:Pulse(120,1000) end )

WindowSize = {900,800}
function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  
	love.window.setTitle("Orbit")
	love.window.setMode(WindowSize[1], WindowSize[2])

	Initialize()
end

debugFPS = 0

DebugDraw = function()

	love.graphics.setColor(255,255,255)
	local h = 15
	local s = 12
	love.graphics.print("FPS : " .. tostring(debugFPS), 15, h)
	h = h + s
	love.graphics.print("Steps : " .. tostring(IntegrationStep), 15, h)
	h = h + s
	love.graphics.print("Projectils : " .. tostring(#Projectils),15,h)
	if #Projectils > 0 then
		h = h + s
		love.graphics.print("Max Life Time : " .. tostring(AbsolutTime - Projectils[1].StartTime),15,h)
	end
end


Drawables = {}
function love.draw()
	love.graphics.clear()
	DebugDraw()

	for i = 1,#Drawables do
		Drawables[i]:Draw()
	end
end

Updatables = {}
AbsolutTime = 0

function love.update(dt)
	if love.keyboard.isDown("escape") then
  		love.event.push('quit')
	end
	dt = math.min(dt,3)
	debugFPS = math.floor(1/dt)
	dt = dt * TIMEFACTOR

	AbsolutTime = AbsolutTime + dt
	-- Inputs --
	handleInputs()

	-- UI --

	-- Logics --
	for i = 1,#Updatables do
		Updatables[i]:Update(dt)
	end

end
