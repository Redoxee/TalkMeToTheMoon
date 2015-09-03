
_Smiles = {
	--[[
		
	--]]
}

SmileManager = {
	CreateSmile = function(o, position, width, height)
		local newSmile = {}
		local halfW = width / 2
		local halfH = height / 2
		newSmile.UpperLip = {
			position.x - halfW, position.y - halfH,
			position.x		  , position.y - halfH,
			position.x + halfW, position.y - halfH,
		}
		newSmile.LowerLip = {
			position.x - halfW, position.y - halfH,
			position.x		  , position.y,
			position.x + halfW, position.y - halfH,
		}

		newSmile.IsBigSmilling = true
		newSmile.Target = 0.5
		newSmile.Height = height
		newSmile.width = width
		newSmile.Position = position

		ListInsert(_Smiles,newSmile)
		return newSmile
	end,

	UpdateSmile = function(o,dt,smile)
		local upperTarget, lowerTarget

		if smile.IsBigSmilling then
			upperTarget = 0
			lowerTarget = smile.Target
		else
			upperTarget = .4
			lowerTarget = .6
		end

		upperTarget = (upperTarget - 0.5) * smile.Height + smile.Position.y
		lowerTarget = (lowerTarget - 0.5) * smile.Height + smile.Position.y

		smile.UpperLip[4] = damping(.9,smile.UpperLip[4],upperTarget,dt)
		smile.LowerLip[4] = damping(.9,smile.LowerLip[4],lowerTarget,dt)

	end,

	Update = function(o,dt)
		for _,smile in ipairs(_Smiles) do
			o:UpdateSmile(dt,smile)
		end
	end,

	DrawSmile = function(o, smile)
		local up = GetSampledBezier(smile.UpperLip, 20)
		local down = GetSampledBezier(smile.LowerLip, 20)
		local points = up
		for _,p in ipairs(down) do
			ListInsert(points,p)
		end

		love.graphics.polygon("fill",points)
	end,

	Draw = function(o)
		for _,smile in ipairs(_Smiles) do 
			o:DrawSmile(smile)
		end
	end,
}