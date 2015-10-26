function middle(trap)
	local a,b,c,d = unpack(trap)
	return {(a[1] + b[1] + c[1] + d[1])/4, (a[2] + b[2] + c[2] + d[2])/4}
end

function isLeft(P0, P1, P2 )
	local det = ( (P1[1] - P0[1]) * (P2[2] - P0[2]) - (P2[1] -  P0[1]) * (P1[2] - P0[2]) )
	if det ~= det or det == 0 then
		return 0
	end
	return det/math.abs(det)
end

function wn_PnPoly( P, points ) --possibly rewrite this
	local wn = 0
	for i=1,#points-3,2 do
		if (points[i+1] <= P[2]) then
			if (points[i+3]  > P[2]) and (isLeft( {points[i],points[i+1]}, {points[i+2],points[i+3]}, P) > 0) then
				wn = wn + 1
			end
		elseif (points[i+3]  <= P[2]) then
			if (isLeft( {points[i], points[i+1]}, {points[i+2], points[i+3]}, P) < 0) then
				wn = wn - 1
			end
		end
	end
	return wn
end

function evenOddRule(wn)
	return wn%2==1
end

function whereIntersect(S1,S2)
	local px,py = S1[1][1], S1[1][2]
	local rx,ry = S1[2][1] - px, S1[2][2] - py
	local qx,qy = S2[1][1], S2[1][2]
	local sx,sy = S2[2][1] - qx, S2[2][2] - qy
	
	local t = ((qx-px)*sy-sx*(qy-py)) / (rx*sy-ry*sx)
	return (0 < t and t < 1),{ px + t*rx, py + t*ry }
end
function whereIntersectY(S1,yVal)
	local px,py = S1[1][1], S1[1][2]
	return px - (py-yVal) / (S1[2][2] - py) * (S1[2][1] - px)
end

function phase0(pointList) --clean this up a little
	local segments = {}
	local subSegs = {}
	for i=1,#pointList-3,2 do
		segments[(i+1)/2] = {{pointList[i],pointList[i+1]},{pointList[i+2],pointList[i+3]}}
		subSegs[(i+1)/2] = {}
	end
	for i,seg in ipairs(segments) do
		subSegs[i][#subSegs[i]+1] = seg[1]
		for j=i+2,#segments do --was i+1 but if the segments are ordered properly, it shouldn't intersect the one after it
			local seg2 = segments[j]
			local crosses,loc = whereIntersect(seg2, seg)
			if crosses then
				subSegs[i][#subSegs[i]+1] = loc
				subSegs[j][#subSegs[j]+1] = loc
			end
		end
		subSegs[i][#subSegs[i]+1] = seg[2]
		local o = seg[1]
		table.sort(subSegs[i],function(a,b)
			return (o[1]-a[1])^2+(o[2]-a[2])^2 < (o[1]-b[1])^2+(o[2]-b[2])^2
		end)
	end
	local newSegments = {}
	local k = 1
	for i,inter in ipairs(subSegs) do
		for j=1,#inter-1 do
			local a = {unpack(inter[j])}
			local b = {unpack(inter[j+1])}
			if a[2] > b[2] then
				a,b = b,a
			end
			newSegments[k] = {a,b}
			k = k + 1 --faster than #newSegments
		end
	end
	table.sort(newSegments,function(a,b) --sort all segments by their top y
		return a[1][2] < b[1][2]
	end)
	return newSegments
end

function phaseI(segments)
	local sweeps = {}
	local ssr = {}
	local k = 0 -- faster than #sweeps
	for i,segment in ipairs(segments) do
		if sweeps[k] ~= segment[1][2] then
			k = k + 1
			sweeps[k] = segment[1][2]
			ssr[k] = {}
		end
	end
	for i=1,#sweeps do
		local j = 1
		while j <= #segments do --allows us to remove from the table, which massively decreses loopage
			local seg = segments[j]
			if seg[1][2] == sweeps[i] then
				local segment = seg
				if i < #sweeps and seg[2][2] > sweeps[i+1] then --crosses the next sweep
					local cross = {whereIntersectY(seg, sweeps[i+1]),sweeps[i+1]}
					segment = {seg[1], cross}
					table.insert(segments, {cross, seg[2]})
				end
				ssr[i][#ssr[i]+1] = segment
				table.remove(segments,j)
				j = j - 1
			end
			j = j + 1
		end
		table.sort(ssr[i], function(a,b) --sort rows by Ax and then by Bx
			return a[1][1] < b[1][1] or (a[1][1] == b[1][1] and a[2][1] < b[2][1])
		end)
	end
	return ssr
end

function phaseII(rows, points, inside) --kinda small to be a phase but whatever
	local trapTable = {}
	for i,row in ipairs(rows) do
		for j=1,#row-1,1 do
			local s1 = row[j]
			local s2 = row[j+1]
			local trap = { s1[1], s2[1], s2[2], s1[2]}			
			if (inside or evenOddRule)(wn_PnPoly(middle(trap), points)) then
				trapTable[#trapTable+1] = trap
			end
		end
	end
	return trapTable
end

function algorithm(points, inside)
	return phaseII(phaseI(phase0(points)), points, inside)
end

return algorithm