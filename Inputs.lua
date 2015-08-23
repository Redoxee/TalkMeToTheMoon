MouseHold = {
	Position = vector(0,0),
	StartPosition = vector(0,0),
	Field_l = false,
	Field_r = false,
	Field_m = false,

	PressFunction = false,
	ReleaseFunction = false,
	DragFunction = false,

	RPressFunction = false,
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

function checkMouseInput(input,downFunction,releaseFunction,dragFunction)
	local d = love.mouse.isDown(input)
	local inputField = "Field_" .. input
	local prevInput = MouseHold[inputField]
	if d then
		if prevInput then
			if dragFunction then
				dragFunction()
			end
		else
			if downFunction then
				downFunction()
			end
		end
	else
		if prevInput and releaseFunction then
			releaseFunction()
		end
	end
	MouseHold[inputField] = d
end



function handleInputs()
	local d = love.mouse.isDown('l')
	local curPos = vector(love.mouse.getPosition())
	local ldfunc = function()
		MouseHold.StartPosition = curPos
		if MouseHold.PressFunction then
			MouseHold.PressFunction()
		end
	end

	checkMouseInput('l',ldfunc,MouseHold.ReleaseFunction,MouseHold.DragFunction)
	checkMouseInput('r',MouseHold.RPressFunction)
	checkMouseInput("m", function()
			Print("mouse position " ..  tostring(curPos))
			ListInsert(LaunchZone.Points,curPos)
		end)
	MouseHold.Position = curPos

	KeyboardHolder:Update()
end