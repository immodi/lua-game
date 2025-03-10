local Freeze = {
	elapsed = 0,
	duration = 0,
	fadeAlpha = 0,
	originalUpdate = nil,
	originalDraw = nil,
	isReseting = false,
	font = love.graphics.newFont("res/fonts/font.ttf", 64), -- Load game font
}

-- Gradually slows down the game
function Freeze:update(dt)
	if self.elapsed < self.duration then
		self.elapsed = self.elapsed + dt
		local progress = math.min(self.elapsed / self.duration, 1)
		self.fadeAlpha = progress -- Increase fade effect
		return dt * (1 - progress) -- Scale dt until full stop
	end
	return 0
end

function Freeze:reset()
	self.elapsed = 0
	self.duration = 0
	self.fadeAlpha = 0
	self.isReseting = false

	-- Restore original update and draw functions
	if self.originalUpdate then
		love.update = self.originalUpdate
	end
	if self.originalDraw then
		love.draw = self.originalDraw
	end

	self.originalUpdate = nil
	self.originalDraw = nil
end

function Freeze:draw(retryCallback)
	if self.originalDraw then
		self.originalDraw()
	end

	-- Draw black fade overlay
	love.graphics.setColor(0, 0, 0, self.fadeAlpha)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	-- Draw "YOU LOST" text
	love.graphics.setFont(self.font)
	love.graphics.setColor(1, 1, 1, self.fadeAlpha)
	local text = "YOU LOST"
	local textWidth = self.font:getWidth(text)
	local textHeight = self.font:getHeight()
	local screenWidth, screenHeight = love.graphics.getDimensions()

	love.graphics.print(text, (screenWidth - textWidth) / 2, (screenHeight - textHeight) / 2 - 50)

	-- Define button properties
	local buttonWidth, buttonHeight = 200, 50
	local buttonX = (screenWidth - buttonWidth) / 2
	local buttonY = (screenHeight + textHeight) / 2 + 10 -- Position below text

	-- Draw button background
	love.graphics.setColor(0.2, 0.2, 0.2, self.fadeAlpha) -- Dark gray button
	love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, 10)

	-- Draw button text

	local smallFont = love.graphics.newFont("res/fonts/font.ttf", 32) -- Smaller font size
	love.graphics.setFont(smallFont)

	love.graphics.setColor(1, 1, 1, self.fadeAlpha) -- White text
	local buttonText = "Retry?"
	local buttonTextWidth = smallFont:getWidth(buttonText)
	local buttonTextHeight = smallFont:getHeight()
	love.graphics.print(
		buttonText,
		buttonX + (buttonWidth - buttonTextWidth) / 2,
		buttonY + (buttonHeight - buttonTextHeight) / 2
	)

	love.graphics.setFont(self.font)

	love.graphics.setColor(1, 1, 1, 1)

	-- Handle button click
	if love.mouse.isDown(1) then
		local mx, my = love.mouse.getPosition()
		if mx >= buttonX and mx <= buttonX + buttonWidth and my >= buttonY and my <= buttonY + buttonHeight then
			if retryCallback then
				retryCallback() -- Call the retry function
			end
		end
	end
end

return Freeze
