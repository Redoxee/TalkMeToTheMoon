
ComputeBezierPoint = function(points,t)
	local size = #points / 2
	if size == 1 then
		return points[1],points[2]
	end

	local _p = {}
	for i = 2,size do
		local ind1 = (i-1)* 2 - 1
		local ind2 =  i   * 2 - 1
		local x1,y1,x2,y2 = points[ind1],points[ind1 + 1],points[ind2],points[ind2 + 1]
		
		_p[ind1]		= x1 + (x2 - x1) * t 
		_p[ind1 + 1]	= y1 + (y2 - y1) * t
	end
	return ComputeBezierPoint(_p,t)
end

GetSampledBezier = function(points,nbStep)
	local x,y = ComputeBezierPoint(points,0)
	local res = {x,y}
	for i = 1,nbStep do
		x,y = ComputeBezierPoint(points, i / nbStep)
		table.insert(res,x)
		table.insert(res,y)
	end
	return res
end