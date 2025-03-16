local Settings = {
	selectedButton = 1, -- Default to first option
	font = love.graphics.newFont("res/fonts/font.ttf", 64),
	options = {
		{ text = "Music", checked = true, toggleCallback = nil },
		{ text = "Sound Effects", checked = true, toggleCallback = nil },
	},
	screenWidth = 0,
	screenHeight = 0,
}

Settings.__index = Settings

function Settings:init()
	local instance = setmetatable({}, { __index = Settings })

	local screenWidth, screenHeight = love.graphics.getDimensions()
	instance.screenWidth = screenWidth
	instance.screenHeight = screenHeight
	instance.options[1].toggleCallback = function()
		Settings.options[1].checked = not Settings.options[1].checked
	end
	instance.options[2].toggleCallback = function()
		Settings.options[2].checked = not Settings.options[2].checked
	end

	return instance
end

function Settings:update()
	GameSettings.isBgMuted = not Settings.options[1].checked
	GameSettings.isSoundEffectsMuted = not Settings.options[2].checked
end
function Settings:draw()
	-- Black overlay
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

	-- Title
	local titleText = "SETTINGS"
	local titleFont = love.graphics.newFont("res/fonts/font.ttf", math.max(24, self.screenHeight * 0.1))
	love.graphics.setFont(titleFont)
	love.graphics.setColor(1, 1, 1)
	local titleWidth = titleFont:getWidth(titleText)
	love.graphics.print(titleText, (self.screenWidth - titleWidth) / 2, self.screenHeight * 0.1)

	-- Options
	local optionFont = love.graphics.newFont("res/fonts/font.ttf", math.max(24, self.screenHeight * 0.05))
	love.graphics.setFont(optionFont)
	local startY = self.screenHeight * 0.35 -- Move options more toward center
	local lineSpacing = self.screenHeight * 0.1
	local boxSize = self.screenHeight * 0.05
	local textOffset = boxSize + 20 -- Space between checkbox and text

	local widestText = 0 -- Find the widest text for uniform button sizing
	for _, option in ipairs(self.options) do
		widestText = math.max(widestText, optionFont:getWidth(option.text))
	end

	local buttonWidth = widestText + textOffset * 2 -- Dynamic width based on text size
	local centerX = (self.screenWidth - buttonWidth) / 2

	for i, option in ipairs(self.options) do
		local boxY = startY + (i - 1) * lineSpacing

		-- Highlight selection
		if self.selectedButton == i then
			love.graphics.setColor(0.3, 0.3, 0.3) -- Dark gray highlight
			love.graphics.rectangle("fill", centerX - 10, boxY - 5, buttonWidth + 20, boxSize + 10)
		end

		-- Checkbox border
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", centerX, boxY, boxSize, boxSize)

		-- Checked state
		if option.checked then
			love.graphics.rectangle("fill", centerX + 5, boxY + 5, boxSize - 10, boxSize - 10)
		end

		-- Draw option text centered to the right of the checkbox
		local textX = centerX + textOffset
		love.graphics.print(option.text, textX, boxY + (boxSize - optionFont:getHeight()) / 2)
	end

	-- Back Button
	local backText = "Back"
	local backWidth = optionFont:getWidth(backText) + 40 -- Dynamic width with padding
	local backHeight = optionFont:getHeight() + 20
	local backX = (self.screenWidth - backWidth) / 2
	local backY = startY + (#self.options + 1) * lineSpacing -- Position after options

	-- Highlight Back button if selected
	if self.selectedButton > #self.options then
		love.graphics.setColor(0.3, 0.3, 0.3) -- Dark gray highlight
	else
		love.graphics.setColor(0, 0, 0) -- Lighter gray background
	end
	love.graphics.rectangle("fill", backX, backY, backWidth, backHeight)

	-- Button Border
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("line", backX, backY, backWidth, backHeight)

	-- Button Text (centered)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(
		backText,
		backX + (backWidth - optionFont:getWidth(backText)) / 2,
		backY + (backHeight - optionFont:getHeight()) / 2
	)
end

function Settings:keypressed(key)
	if key == "down" then
		self.selectedButton = (self.selectedButton % (#self.options + 1)) + 1
	elseif key == "up" then
		self.selectedButton = (self.selectedButton - 2) % (#self.options + 1) + 1
	elseif key == "return" then
		if self.selectedButton <= #self.options then
			-- Toggle checkbox
			self.options[self.selectedButton].toggleCallback()
		else
			-- Go back to menu
			love.changeState("menu")
		end
	end
end

return Settings
