_Button = {
	Position = vector(0,0),
	Size = vector(0,0),

	OnPress = false,

	_Handle = false,

	Initialize = function(o)
		o._Handle = RegisterMouseInput("l","down",function() return o:_OnPress()end)
		o.Size = o.Position + o.Size
	end,

	DeInitialize = function(o)
		if o._Handle then
			UnRegisterMouseInput("l","down",o._Handle)
		end
	end,

	_OnPress = function(o)
		if o.OnPress then
			local mp = MouseHolder.Position

			if o.Position.x > mp.x and o.Size.x < mp.x and
				o.Position.y > mp.y and o.Size.y < mp.y then
				o.OnPress()
			end 
		end
		return false
	end,
}

function CreateButton(params)
	local o = {}
	for k,v in pairs(_Button) do
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