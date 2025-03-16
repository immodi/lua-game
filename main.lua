local Game = require("scenes.game")
local Menu = require("scenes.menu")
local Controls = require("scenes.controls")
local Settings = require("scenes.settings")
local BgMusic = require("helpers.bg_music")
GlobalObjects = {
	bgMusic = BgMusic,
}
GameSettings = {
	isBgMuted = not Settings.options[1].checked,
	isSoundEffectsMuted = not Settings.options[2].checked,
}

local states = {
	game = Game,
	menu = Menu,
	controls = Controls,
	settings = Settings,
}

local currentState = "menu"

function love.load()
	love.window.setMode(0, 0, { fullscreen = true })
	GlobalObjects.bgMusic = GlobalObjects.bgMusic:init()
	states.settings = Settings:init()

	-- Initialize other states (but skip Settings)
	for i, state in pairs(states) do
		if i ~= "settings" then
			states[i] = state:init(GameSettings)
		end
	end
end

function love.update(dt)
	GlobalObjects.bgMusic:update()

	if states[currentState].update then
		states[currentState]:update(dt)
	end
end

function love.draw()
	if states[currentState].draw then
		states[currentState]:draw()
	end
end

function love.changeState(newState)
	if states[newState] then
		currentState = newState
	end
end

function love.freeze(duration)
	local freezeGameCallback, overrideUpdateCallback, overrideDrawCallback = states.game:freeze(duration)
	freezeGameCallback()

	-- Override love.update
	love.update = function(dt)
		overrideUpdateCallback(dt)
	end
	-- Override love.draw
	love.draw = function()
		overrideDrawCallback()
	end
end

function love.reset()
	states.game:reset()
end

function love.keypressed(key)
	if states[currentState] and states[currentState].keypressed then
		states[currentState]:keypressed(key)
	end
end
