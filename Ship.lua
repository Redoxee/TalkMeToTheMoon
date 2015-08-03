vRotate = function(x, y, a)
	local c,s = math.cos(a), math.sin(a)
	return c*x-s*y,s*x+c*y
end

Ship = {
	Position = vector(400,450),
	Velocity = vector(0,0),
	Orientation = 0,

	Points = {-6,6,
			6,6,
			0,-9},

	Update = function(o,dt)
		o.Orientation = o.Orientation + dt * math.pi / 9.
		o.Position, o.Velocity = Integrate(o.Position, o.Velocity, vector(0,0),CurrentLevel.Planets,dt, MAX_DT)

		local x,y = o.Position.x,o.Position.y
		x = Min(Max(0,x),900)
		y = Min(Max(0,y),800)
		o.Position = vector(x,y)
	end,

	Draw = function(o)
		love.graphics.setColor(255,255,0)
		local x,y = o.Position.x, o.Position.y
		local p = o.Points

		local p1x,p1y = vRotate(p[1],p[2],o.Orientation)
		local p2x,p2y = vRotate(p[3],p[4],o.Orientation)
		local p3x,p3y = vRotate(p[5],p[6],o.Orientation)

		love.graphics.polygon("fill",p1x + x, p1y + y, p2x + x, p2y + y, p3x + x, p3y + y)
		end,

	Initialize = function(o)
	end,

}