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
}
