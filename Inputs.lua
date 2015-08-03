MouseHold = {
	Position = vector(0,0),
	StartPosition = vector(0,0),
	RDown = false,
	LDown = false,

	PressFunction = false,
	ReleaseFunction = false,
	DragFunction = false,
}

KeyboardHolder = {
	_Listeners = {},
	RegisterListener = function(o,key,callback)
		if not o._Listeners[key] then
			o._Listeners[key] = {}
		end
		ListInsert(o._Listeners[key],callback) 
	end,
	
	ClearListener = function(o,key)
		o._Listeners[key] = nil
	end,
	
	ClearAll = function(o)
		o._Listeners = {}
	end,

	_PrevKeys = {},

	Update = function(o)
		for key,values in pairs(o._Listeners) do
			if values then
				local isDown = love.keyboard.isDown(key)
				if isDown and not o._PrevKeys[key] then
					o._PrevKeys[key] = true
					for i = 1,#values do
						values[i]()
					end
				elseif not isDown then
					o._PrevKeys[key] = false
				end
			end
		end
	end,
}

function handleInputs()
	local d = love.mouse.isDown('l')
	local curPos = vector(love.mouse.getPosition())
	if d then
		if MouseHold.LDown then
			if MouseHold.DragFunction then
				MouseHold.DragFunction(MouseHold)
			end
		else
			MouseHold.StartPosition = curPos
			if MouseHold.PressFunction then
				MouseHold.PressFunction(MouseHold)
			end
		end
	else
		if MouseHold.LDown and MouseHold.ReleaseFunction then
			MouseHold.ReleaseFunction(MouseHold)
		end
	end
	MouseHold.LDown = d
	MouseHold.Position = curPos

	KeyboardHolder:Update()
end