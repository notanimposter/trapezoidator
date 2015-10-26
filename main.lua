local Trapezoidator = require 'trapezoidator'

local frameRate = 0

local points = {
	2*200,2*150,
	2*170,2*240,
	2*250,2*180,
	2*250,2*170,
	2*150,2*190,
	2*230,2*240,
	2*200,2*150
}

function evenOdd(wn)
	return wn%2 == 1
end
function nonZero(wn)
	return wn ~= 0
end

local timeDelta
local traps
function love.load()
	local beforeTime = love.timer.getTime()
	for i=1,10000 do
		traps = Trapezoidator(points, evenOdd)
	end
	timeDelta = love.timer.getTime() - beforeTime
end
function love.update(dt)
	frameRate = 1/dt
end
function love.keypressed(k)
	if k == 'escape' then love.event.quit() end
end
function love.draw()
	love.graphics.setBackgroundColor(255,255,127)
	love.graphics.setLineWidth(2)
	love.graphics.setColor(255,127,255,127)
	if traps ~= nil then
		for i,trap in ipairs(traps) do
			local a,b,c,d = unpack(trap)
			love.graphics.polygon("fill",a[1],a[2],b[1],b[2],c[1],c[2],d[1],d[2])
		end
	end
	love.graphics.setColor(0,0,0)
	love.graphics.line(points)
	love.graphics.print(string.format("%i", frameRate), 10,10)
	love.graphics.print(string.format("%.2f", 1000 * timeDelta), 50,10)
end