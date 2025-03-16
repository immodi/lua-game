local Background = require("helpers.background")

local Controls = {
	selectedButton = 1,
	font = love.graphics.newFont("res/fonts/font.ttf", 64),
	buttons = {},
}

function Controls:init()
	local screenWidth, screenHeight = love.graphics.getDimensions()

	Background:init(screenWidth, screenHeight)
	self.selectedButton = 1
	self.font = love.graphics.newFont("res/fonts/font.ttf", 64)

	-- Define buttons
	self.buttons = {
		{
			text = "Back",
			action = function()
				love.changeState("menu")
			end,
		},
	}

	return self
end

function Controls:update(dt)
	Background:animate(dt)
end

function Controls:draw()
	local screenWidth, screenHeight = love.graphics.getDimensions()
	Background:draw()

	-- Black overlay
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

	-- Title
	local titleText = "CONTROLS"
	local titleFont = love.graphics.newFont("res/fonts/font.ttf", math.max(24, screenHeight * 0.1))
	love.graphics.setFont(titleFont)
	love.graphics.setColor(1, 1, 1)
	local titleWidth = titleFont:getWidth(titleText)
	love.graphics.print(titleText, (screenWidth - titleWidth) / 2, screenHeight * 0.1)

	-- Control List
	local controls = {
		"Move:   W A S D  /  Arrow Keys",
		"Shoot:  Right Shift",
		"Laser:  L",
	}

	local startX = screenWidth * 0.1 -- Left margin (10%)
	local maxWidth = screenWidth * 0.8 -- Max width (80% to fit within 10% margin)
	local startY = screenHeight * 0.3
	local lineSpacing = screenHeight * 0.1

	-- Find the longest text width
	local controlFont = love.graphics.newFont("res/fonts/font.ttf", math.max(24, screenHeight * 0.05))
	love.graphics.setFont(controlFont)
	local longestWidth = 0

	for _, controlText in ipairs(controls) do
		local textWidth = controlFont:getWidth(controlText)
		if textWidth > longestWidth then
			longestWidth = textWidth
		end
	end

	-- Scale down if text is too wide
	local scaleFactor = 1
	if longestWidth > maxWidth then
		scaleFactor = maxWidth / longestWidth
		love.graphics.push()
		love.graphics.scale(scaleFactor, 1)
		startX = startX / scaleFactor -- Adjust for scaling
	end

	-- Draw controls text
	for i, controlText in ipairs(controls) do
		love.graphics.print(controlText, startX, startY + (i - 1) * lineSpacing)
	end

	-- Restore normal scaling
	if longestWidth > maxWidth then
		love.graphics.pop()
	end

	-- Button Settings
	local buttonWidth = screenWidth * 0.3
	local buttonHeight = screenHeight * 0.08
	local buttonY = screenHeight * 0.75

	-- Button Background
	love.graphics.setColor(0.235, 0.235, 0.235) -- Dark gray
	love.graphics.rectangle("fill", (screenWidth - buttonWidth) / 2, buttonY, buttonWidth, buttonHeight)

	-- Button Border
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("line", (screenWidth - buttonWidth) / 2, buttonY, buttonWidth, buttonHeight)

	-- Button Text
	local textWidth = controlFont:getWidth("Back")
	local textHeight = controlFont:getHeight()
	love.graphics.print("Back", (screenWidth - textWidth) / 2, buttonY + (buttonHeight - textHeight) / 2)
end

function Controls:keypressed(key)
	if key == "return" or key == "escape" then
		love.changeState("menu")
	end
end

return Controls
