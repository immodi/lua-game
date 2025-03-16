local Background = require("helpers.background")

local Menu = {
	bgMusic = {},
}

Menu.__index = Menu

local buttons = {}
local selectedButton = 1
local font

function Menu:init()
	local instance = setmetatable({}, { __index = Menu })
	local screenWidth, screenHeight = love.graphics.getDimensions()
	Background:init(screenWidth, screenHeight)
	instance.bgMusic = GlobalObjects.bgMusic

	-- Dynamic font size based on screen height
	local fontSize = math.max(24, screenHeight * 0.05) -- Min 24px, scales with screen height
	font = love.graphics.newFont("res/fonts/font.ttf", fontSize)
	love.graphics.setFont(font)

	-- Button settings (scaled)
	local buttonWidth = screenWidth * 0.3 -- 30% of screen width
	local buttonHeight = screenHeight * 0.08 -- 8% of screen height
	local spacing = screenHeight * 0.02 -- 2% spacing

	-- Define buttons
	buttons = {
		{
			text = "Start",
			action = function()
				love.changeState("game")
			end,
		},
		{
			text = "Settings",
			action = function()
				love.changeState("settings")
			end,
		},
		{
			text = "Controls",
			action = function()
				love.changeState("controls")
			end,
		},
		{
			text = "Quit",
			action = function()
				love.event.quit()
			end,
		},
	}

	-- Now that buttons exist, calculate startY correctly
	local totalHeight = (#buttons * buttonHeight) + ((#buttons - 1) * spacing)
	local startY = (screenHeight - totalHeight) / 2 -- Center vertically

	-- Center buttons and apply scaling
	for i, btn in ipairs(buttons) do
		btn.x = (screenWidth - buttonWidth) / 2
		btn.y = startY + (i - 1) * (buttonHeight + spacing)
		btn.width = buttonWidth
		btn.height = buttonHeight
	end

	return instance
end

function Menu:update(dt)
	-- self.bgMusic:update()
	Background:animate(dt)
end

function Menu:draw()
	love.graphics.setFont(font)
	Background:draw()

	-- Draw buttons
	for i, btn in ipairs(buttons) do
		-- Highlight selected button
		if i == selectedButton then
			love.graphics.setColor(0.235, 0.235, 0.235) -- Dark gray
			love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height)
		else
			love.graphics.setColor(0, 0, 0) -- Black fill
			love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height)
		end

		-- Button border
		love.graphics.setColor(1, 1, 1) -- White border
		love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height)

		-- Draw button text
		love.graphics.printf(btn.text, btn.x, btn.y + (btn.height / 4), btn.width, "center")
	end
end

function Menu:keypressed(key)
	if key == "down" then
		selectedButton = (selectedButton % #buttons) + 1
	elseif key == "up" then
		selectedButton = (selectedButton - 2) % #buttons + 1
	elseif key == "return" then
		buttons[selectedButton].action()
	end
end

return Menu
