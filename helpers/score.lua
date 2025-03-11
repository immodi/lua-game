local Score = {
	value = 0,
	scale = 1.0,
	font = nil,
}

function Score:init()
	self.font = love.graphics.newFont("res/fonts/font.ttf", 42) -- Change path if needed
end

function Score:update(dt)
	-- Gradually shrink scale back to normal
	self.scale = self.scale - dt * 2
	if self.scale < 1.0 then
		self.scale = 1.0
	end
end

function Score:increment()
	self.value = self.value + 1
end

function Score:increase(amount)
	self.value = self.value + amount
	self.scale = 1.5 -- Trigger enlargement effect
end

function Score:reset()
	self.value = 0
end

function Score:draw()
	love.graphics.setFont(self.font)
	love.graphics.setColor(1, 1, 1, 1) -- White color

	local text = tostring(self.value)
	-- Get dimensions of the text
	local textWidth = self.font:getWidth(text)
	local textHeight = self.font:getHeight()
	-- Set origin to the center of the text

	local scoreX = 20
	local scoreY = 45

	-- Use love.graphics.printf with the computed origin offsets.
	-- The "limit" is set to textWidth so the text isn't wrapped.
	love.graphics.printf(text, scoreX, scoreY, textWidth, "center", 0, self.scale, self.scale, 0, textHeight / 2)
end

return Score
