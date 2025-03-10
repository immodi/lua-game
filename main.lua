local Player = require("entities.player")
local Enemy = require("entities.enemy")
local Grid = require("entities.grid")
local Camera = require("helpers.camera")
local Background = require("helpers.background")
local ParticleSystem = require("helpers.particles")
local Freeze = require("helpers.freeze")
local Score = require("helpers.score")
local BgMusic = require("helpers.bg_music")
local enemies = {}
local spawnTimer = 0.5
local shootDelay = 0.1
local freezeTimer = 1
local isMouseVisible = false

function love.load()
	ParticleSystem:init()
	Score:init()
	love.window.setMode(0, 0, { fullscreen = true })
	love.mouse.setVisible(isMouseVisible)
	local screenWidth, screenHeight = love.graphics.getDimensions()

	Player:init(screenWidth, screenHeight, ParticleSystem.ps:clone())
	Background:init(screenWidth, screenHeight)
	BgMusic:init()
end

function love.update(dt)
	local screenWidth, screenHeight = love.graphics.getDimensions()
	love.mouse.setVisible(isMouseVisible)
	spawnTimer = spawnTimer - dt
	shootDelay = shootDelay - dt
	Background:animate(dt)
	Score:update(dt)

	if Player.healthSystem.health <= 0 then
		love.freeze(freezeTimer)
		isMouseVisible = true
	end

	Camera:update(dt)
	BgMusic:update()

	if shootDelay <= 0 then
		Player:shoot(screenWidth, Player.y - Player.height / 2)
		shootDelay = 0.1
	end

	Player:move(dt)
	Player:broderPhysics(screenWidth, screenHeight)

	-- Move player smoothly into view during cutscene
	if Player.isRunningCutscene then
		Player.x = Player.x + (10 - Player.x) * dt * 3 -- Lerp towards x = 10
		if Player.x >= 9.9 then
			Player.x = 10
			Player.isRunningCutscene = false
		end
	end

	for _, enemy in ipairs(enemies) do
		enemy:move(dt)

		-- Check collision between Player and Enemy
		if enemy:checkCollision(Player) then
			enemy:destroy(enemies, ParticleSystem.activeExplosions, ParticleSystem.ps, function()
				Camera:shake()
			end, true)
			Player:takeDamage(function()
				BgMusic:switchTracks()
			end)
		end
	end

	Grid:updateGrid(enemies, Player.projectiles)
	Grid:checkCollisions(
		enemies,
		Player.projectiles,
		ParticleSystem.activeExplosions,
		ParticleSystem.ps,
		screenWidth + 100,
		screenHeight + 100,
		function()
			Camera:shake()
		end,
		function()
			Score:increment()
		end
	)

	if not Player.isRunningCutscene then
		if spawnTimer <= 0 then
			table.insert(enemies, Enemy:new(screenWidth, screenHeight, Player.x, Player.y))
			spawnTimer = 0.5
		end
	end

	-- Update explosions
	for i = #ParticleSystem.activeExplosions, 1, -1 do
		ParticleSystem.activeExplosions[i]:update(dt)

		-- Remove finished particle effects
		if ParticleSystem.activeExplosions[i]:getCount() == 0 then
			table.remove(ParticleSystem.activeExplosions, i)
		end
	end
end

function love.draw()
	love.graphics.clear(0, 0, 0.148, 1) -- Black background (R, G, B, Alpha)
	love.graphics.push() -- Save the transformation
	love.graphics.setColor(1, 1, 1, 1) -- Reset color to full brightness

	love.graphics.translate(Camera.x, Camera.y)

	Score:draw()
	Player:draw()
	Enemy:draw(enemies)
	Background:draw()

	for _, explosion in ipairs(ParticleSystem.activeExplosions) do
		love.graphics.setColor(1, 1, 1, 1) -- Ensure particles are drawn properly
		love.graphics.draw(explosion)
	end

	love.graphics.pop() -- Restore transformation after shake
end

function love.keyreleased(key)
	if key == "rshift" then
		Player.canShoot = true
	end
end

function love.freeze(duration)
	if Freeze.duration > 0 then
		return
	end

	Freeze.duration = duration
	Freeze.elapsed = 0
	Freeze.fadeAlpha = 0

	-- Store original functions only if they haven't been stored before
	if not Freeze.originalUpdate then
		Freeze.originalUpdate = love.update or function() end
	end
	if not Freeze.originalDraw then
		Freeze.originalDraw = love.draw or function() end
	end

	-- Override love.update
	love.update = function(dt)
		local scaledDt = Freeze:update(dt)
		if scaledDt > 0 then
			Freeze.originalUpdate(scaledDt)
		end

		if Freeze.isReseting then
			-- Restore original functions
			love.update = Freeze.originalUpdate
			love.draw = Freeze.originalDraw
			Freeze.duration = 0 -- Reset freeze state
		end
	end

	-- Override love.draw
	love.draw = function()
		Freeze:draw(function()
			love.reset()
		end)
	end
end

function love.reset()
	Freeze.isReseting = true
	isMouseVisible = false
	enemies = {}
	Freeze:reset()
	Player:reset()
	Score:reset()
	BgMusic:reset()
end
