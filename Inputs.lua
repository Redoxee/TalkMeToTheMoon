MouseHold = {
	Position = vector(0,0),
	StartPosition = vector(0,0),
	Field_l = false,
	Field_r = false,
	Field_m = false,
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

function RegisterMouseInput(button, event, callback)
	local list = MouseHold[button .. "_" .. event] or {}
	local handle = callback
	ListInsert(list, callback)
	MouseHold[button .. "_" .. event] = list
	return handle
end

function UnRegisterMouseInput(button,event, handle)
	local list = MouseHold[button .. "_" .. event]
	ListRemove(list,handle)
end

function _callMouseInput(inputField)
	local list = MouseHold[inputField]
	if list then
		for i= 1, #list do
			local c = list[i]
			if c() then
				break
			end
		end
	end
end

function checkMouseInput(input, alias)
	local d = love.mouse.isDown(input)
	
	local inputField = "Field_" .. alias
	local prevInput = MouseHold[inputField]
	local callBackprefix = alias .. "_"
	if d then
		if prevInput then
			_callMouseInput(callBackprefix .. "drag")
		else
			MouseHold.StartPosition = MouseHold.Position
			_callMouseInput(callBackprefix .. "down")
		end
	else
		if prevInput then
			_callMouseInput(callBackprefix .. "up")
		end
	end
	MouseHold[inputField] = d
end


GPad = {

	_Listeners = {},

	Left = vector(0,0),
	Right = vector(0,0),

	_DeadZone = .21,
	_PadRef = false,

	UpdateInputs = function(o)
		if o._PadRef then
			local x,y

	        x = o._PadRef:getGamepadAxis("leftx")
	        if math.abs(x) < o._DeadZone then
	        	x = 0
	        end
	        y = o._PadRef:getGamepadAxis("lefty")
			if math.abs(y) < o._DeadZone then
				y = 0
			end
			o.Left = vector(x,y)

	        x = o._PadRef:getGamepadAxis("rightx")
	        if math.abs(x) < o._DeadZone then
	        	x = 0
	        end
	        y = o._PadRef:getGamepadAxis("righty")
			if math.abs(y) < o._DeadZone then
				y = 0
			end
			o.Right = vector(x,y)
		else
			o.Left = vector(0,0)
			o.Right = vector(0,0)
		end

		o:UpdateBtn()
	end,

	RegisterListener = function(o,btn,callback)
		if not o._Listeners[btn] then
			o._Listeners[btn] = {}
		end
		ListInsert(o._Listeners[btn],callback) 
	end,
	
	ClearListener = function(o,btn)
		o._Listeners[btn] = nil
	end,
	
	ClearAll = function(o)
		o._Listeners = {}
	end,

	_PrevBtns = {},

	UpdateBtn = function(o)
		for btn,values in pairs(o._Listeners) do
			if values then
				local isDown = o._PadRef:isGamepadDown(btn)
				if isDown and not o._PrevBtns[btn] then
					o._PrevBtns[btn] = true
					for i = 1,#values do
						values[i]()
					end
				elseif not isDown then
					o._PrevBtns[btn] = false
				end
			end
		end
	end,
}

function love.joystickadded(joystick)
    GPad._PadRef = joystick
end


function handleInputs()
	local curPos = vector(love.mouse.getPosition())
	MouseHold.Position = curPos
	checkMouseInput(1, 'l')
	checkMouseInput(2, 'r')
	checkMouseInput(3, 'm')

	KeyboardHolder:Update()
	GPad:UpdateInputs()
end
