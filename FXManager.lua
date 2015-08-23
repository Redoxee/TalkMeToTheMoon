SHADERSPATH = "Shaders/"

FXManager = {
	RedContourFBO = false,
	RedContourShader = false,

	Initialize = function(o)
		o.RedContourFBO = love.graphics.newCanvas(WindowSize[1],WindowSize[2])
		o.RedContourShader =  love.graphics.newShader( SHADERSPATH .. "RedAnimatedContour.sha" )
		o.RedContourShader:send("iResolution", WindowSize)
	    o.RedContourShader:send("iStencil",o.RedContourFBO)
	end,

	Update = function(o,dt)
	end,

	Draw = function(o)
		o:DrawRedContour()

		o.GreenZone:ApplyEffect()
	end,

	RedContourTarget = false,

	DrawRedContour = function(o)
		if o.RedContourTarget then
			love.graphics.setCanvas(o.RedContourFBO)
			o.RedContourFBO:clear()

				love.graphics.setColor(255,255,255,255)
				love.graphics.circle("fill", o.RedContourTarget.x,WindowSize[2] - o.RedContourTarget.y, 20)
			
			love.graphics.setCanvas()

		    love.graphics.setShader(o.RedContourShader)

		    love.graphics.rectangle("fill", 0, 0, WindowSize[1],WindowSize[2])
		    love.graphics.setShader()
		end
	end,

	GreenZone = {
		PolygonPoints = false,

		ApplyEffect = function(o)
			if o.PolygonPoints and #o.PolygonPoints > 2 then
				love.graphics.setColor(255,255,255)
				local points = {}
				for i = 1,#o.PolygonPoints do
					p = o.PolygonPoints[i]
					ListInsert(points, p.x)
					ListInsert(points, p.y)
				end

				love.graphics.polygon("fill",points)
			end
		end,
	},
}
