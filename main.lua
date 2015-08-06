vector = require "utils.hump.vector"
require "functionLib"
require "Levels"
require "Inputs"

MAX_DT = 0.1

TIMEFACTOR = 3

MAX_DISTANCE2 = 3000 * 3000

function GetForce (position, objects, dt) 
	local cumulativForces = vector(0,0)
	for i = 1,#objects do
		obj = objects[i]
		local dif = ( obj.Position - position)
		cumulativForces = cumulativForces + dif:normalized() * (obj.Masse) / dif:len2()
	end
	return cumulativForces
end

IntegrationStep = 0

function Integrate (originalPosition,originalVelocity,originalAcceleration , objects, dt , maxDt)
	local r = dt / maxDt
	local iteration,rest = math.floor(dt/maxDt) , dt%maxDt

	IntegrationStep = iteration + 1

	local position = originalPosition
	local velocity = originalVelocity
	local acceleration = originalAcceleration

	if iteration > 0 then
		for i = 1,iteration do
			acceleration =  GetForce(position,objects,maxDt)
			velocity = velocity + acceleration * maxDt
			position = position + velocity * maxDt
		end
	end

	acceleration = GetForce(position, objects, rest)
	velocity = velocity + acceleration * rest
	position = position + velocity * rest

	return position,velocity,acceleration

end

Launcher = {
	Position = vector(450,250),
		
	ChargeVector = false,

	Initialize = function(o)

		MouseHold.PressFunction = function(holder)
			o:OnPress(holder)
		end

		MouseHold.ReleaseFunction = function(holder)
			o:OnRelease(holder)
		end

		MouseHold.DragFunction = function(holder)
			o:OnDrag(holder)
		end
	end,


	Draw = function(o)
		love.graphics.setColor(128,128,128)
		love.graphics.circle("fill",o.Position.x,o.Position.y,5)

		if o.ChargeVector then
			local vPos = o.Position + o.ChargeVector
			love.graphics.setColor(64,128,192)
			love.graphics.line(o.Position.x,o.Position.y, vPos.x,vPos.y)
		end
 	end,

	Update = function(o,dt)
	end,

	ComputCharge = function(o,holder)
		local direction = holder.Position - holder.StartPosition
		o.ChargeVector = direction:normalized() * math.sqrt(direction:len()) * 4
	end,

	OnPress = function(o,holder)
		o.Position = holder.StartPosition
	end,

	OnRelease = function(o,holder)
		o:ComputCharge(holder)

		o:Launch(o.ChargeVector)
		-- o:Spread(o.ChargeVector:len(), 100)
		
		o.ChargeVector = false
	end,

	OnDrag = function(o,holder)
		o:ComputCharge(holder)
	end,

	Spread = function(o, force, iteration)
		for i = 0,iteration do
			local a = math.pi * 2 * i / iteration
			local x,y = math.cos(a), math.sin(a)
			o:Launch(vector(x,y) * force)
		end
	end,

	Launch = function(o,launchDirection)
		local velocity = launchDirection

		local proj = {
			Position = o.Position,
			Velocity = velocity,
		}

		table.insert(Projectils,proj)
		-- Print(tostring(#Projectils))
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


		toRemove = {}

		for i = 1, #Projectils do
			p = Projectils[i]
	
			p.Position, p.Velocity = Integrate(p.Position, p.Velocity, vector(0,0),masses,dt, MAX_DT)
		
			local removed = false
			for j,r2 in ipairs(r2s) do
				if p.Position:dist2(masses[j].Position) < r2 then
					table.insert(DeadProjectils,p.Position)
					table.insert(o.ToRemoves, i)
					removed = true
					break
				end
			end
			if not removed then
				local dist = p.Position:dist2(vector(450,400))
				if dist > MAX_DISTANCE2 then
					Print(tostring(dist))
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

DeadProjectils = {}
_DeadProjectils = {
	Projectils = {},
	Initialize = function(o)
		DeadProjectils = {}
	end,

	Draw = function(o)
		love.graphics.setColor(255,127,0)
		for i = 1, #DeadProjectils do
			local p = DeadProjectils[i]
			love.graphics.circle("fill",p.x,p.y,4)
		end
	end,
}

DotPoints = {}
_DotPointManager = {
	Accumulator = 0,
	DotDuration = 3,
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

World = {
	LevelIndex = false,
	LevelsAvailable = {"Level1","Level2","Level3","Level4"},

	Initialize = function(o)
		o.LevelIndex = 0
		o:OnNextPressed()

		local nLevel = function()
			o:OnNextPressed()
		end
		
		KeyboardHolder:RegisterListener("n",nLevel)
	end,

	OnNextPressed = function(o)
		AbsolutTime = 0
		o.LevelIndex = ((o.LevelIndex) % #o.LevelsAvailable) + 1

		Print("Level index : " .. tostring(o.LevelIndex) )

		-- clear projectiles
		_Projectils:Initialize()
		_DotPointManager:Initialize()
		_DeadProjectils:Initialize()
		-- load level
		LoadLevel(o.LevelsAvailable[o.LevelIndex])

	end,
}

Initialize = function()
	World:Initialize()

	table.insert(Updatables, Launcher)
	table.insert(Updatables, CurrentLevel)
	table.insert(Updatables, _Projectils)
	table.insert(Updatables, _DotPointManager)

	table.insert(Drawables, _DotPointManager)
	table.insert(Drawables, CurrentLevel)
	table.insert(Drawables, Launcher)
	-- table.insert(Drawables, _DeadProjectils)
	table.insert(Drawables, _Projectils)

	Launcher:Initialize()
end

KeyboardHolder:RegisterListener("p",function() Launcher:Spread(105,120) end )


function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  
	love.window.setTitle("Orbit")
	love.window.setMode(900, 800)

	Initialize()
end

DebugDraw = function()

	love.graphics.setColor(255,255,255)
	local h = 15
	local s = 12
	love.graphics.print("Steps : " .. tostring(IntegrationStep), 15, h)
	h = h + s
	love.graphics.print("Projectils : " .. tostring(#Projectils),15,h)
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
