local Freeze = {
	elapsed = 0,
	duration = 0,
	fadeAlpha = 0,
	originalUpdate = nil,
	originalDraw = nil,
	isReseting = false,
	selectedButton = 1, -- Default to first button
	font = love.graphics.newFont("res/fonts/font.ttf", 64), -- Load game font
	buttons = {}, -- Store buttons persistently
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
	self.selectedButton = 1 -- Reset button selection

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

function Freeze:draw(retryCallback, menuCallback)
	if self.originalDraw then
		self.originalDraw()
	end

	local screenWidth, screenHeight = love.graphics.getDimensions()
	-- Draw black fade overlay
	love.graphics.setColor(0, 0, 0, self.fadeAlpha)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	-- Draw "YOU LOST" text
	self.font = love.graphics.newFont("res/fonts/font.ttf", math.max(24, screenHeight * 0.1))
	love.graphics.setFont(self.font)
	love.graphics.setColor(1, 1, 1, self.fadeAlpha)

	local text = "YOU LOST"
	local headerTextWidth = self.font:getWidth(text)
	local headerTextHeight = self.font:getHeight()

	love.graphics.print(text, (screenWidth - headerTextWidth) / 2, (screenHeight - headerTextHeight) / 3)

	-- Button settings
	local buttonWidth = screenWidth * 0.3 -- 30% of screen width
	local buttonHeight = screenHeight * 0.08 -- 8% of screen height
	local spacing = screenHeight * 0.03 -- 3% spacing
	local startY = (screenHeight - (#self.buttons * (buttonHeight + spacing))) / 1.7 -- Centers buttons

	-- Define buttons only once
	if #self.buttons == 0 then
		self.buttons = {
			{ text = "Retry?", action = retryCallback },
			{ text = "Menu", action = menuCallback },
		}
	end

	self.font = love.graphics.newFont("res/fonts/font.ttf", math.max(24, screenHeight * 0.05))
	love.graphics.setFont(self.font)

	-- Draw buttons
	for i, btn in ipairs(self.buttons) do
		local buttonX = (screenWidth - buttonWidth) / 2
		local buttonY = startY + (i - 1) * (buttonHeight + spacing)

		-- Highlight selected button
		if self.selectedButton == i then
			love.graphics.setColor(0.235, 0.235, 0.235) -- Dark gray
			love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight)
		else
			love.graphics.setColor(0, 0, 0) -- Black fill
			love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight)
		end

		-- Draw button border
		love.graphics.setColor(1, 1, 1, self.fadeAlpha) -- White border
		love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight)

		-- Draw button text
		local textWidth = self.font:getWidth(btn.text)
		local textHeight = self.font:getHeight()
		love.graphics.print(
			btn.text,
			buttonX + (buttonWidth - textWidth) / 2,
			buttonY + (buttonHeight - textHeight) / 2
		)
	end
end

-- Handle keyboard input
function Freeze:keypressed(key)
	if key == "down" then
		self.selectedButton = (self.selectedButton % #self.buttons) + 1
	elseif key == "up" then
		self.selectedButton = (self.selectedButton - 2) % #self.buttons + 1
	elseif key == "return" then
		local btn = self.buttons[self.selectedButton]
		if btn and btn.action then
			btn.action()
		end
	end
end

return Freeze
