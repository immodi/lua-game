local Player = require("entities.player")
local Enemy = require("entities.enemy")
local Grid = require("entities.grid")
local Camera = require("helpers.camera")
local Background = require("helpers.background")
local ParticleSystem = require("helpers.particles")
local Freeze = require("helpers.freeze")
local Score = require("helpers.score")
local BgMusic = require("helpers.bg_music")
local Powerups = require("entities.powerup")
local Boss = require("entities.boss")
local bgState = {
	bgMusic = {},
	score = {},
	camera = {},
	grid = {},
}

local enemiesState = {
	enemies = {},
	isSpawning = true,
	defaultSpawnTimer = Enemy.defaultSpawnTimer,
	spawnTimer = Enemy.defaultSpawnTimer,
	MAX_DIFICULTY_TIMER = 0.4,
	lastCheckedBgState = { score = 0 }, -- Initialize this
}

local bossState = {
	boss = {},
}

local powerups = {} -- Table to store active power-ups
local shootDelay = 0.1
local freezeTimer = 1
local isMouseVisible = false

local effectsCallbacks = {
	spinAttack = function(dt)
		if Player.spinProgress == 0 then
			Player.isSpinning = true
			Player:spinAttack(dt, enemiesState.enemies, ParticleSystem.activeExplosions, ParticleSystem.ps, function()
				bgState.score:increment()
			end, function()
				bgState.camera:shake()
			end)
		end
	end,

	heal = function(dt)
		if Player.healthSystem.health < Player.baseHeart then
			Player.healthSystem:heal()
		end
	end,
}

function love.load()
	ParticleSystem:init()
	bgState.score = Score:init()
	bgState.camera = Camera:init()
	bgState.bgMusic = BgMusic:init()
	love.window.setMode(0, 0, { fullscreen = true })
	love.mouse.setVisible(isMouseVisible)
	local screenWidth, screenHeight = love.graphics.getDimensions()

	Player:init(screenWidth, screenHeight, ParticleSystem.ps:clone())
	Background:init(screenWidth, screenHeight)
	bossState.boss = Boss:init(screenWidth, screenHeight)
	bgState.grid = Grid:init()
end

function love.update(dt)
	local screenWidth, screenHeight = love.graphics.getDimensions()
	love.mouse.setVisible(isMouseVisible)
	enemiesState.spawnTimer = enemiesState.spawnTimer - dt
	shootDelay = shootDelay - dt
	Background:animate(dt)
	bgState.score:update(dt)

	if enemiesState.lastCheckedBgState.score == nil then
		enemiesState.lastCheckedBgState.score = 0
	end

	if
		bgState.score.value % 100 == 0
		and bgState.score.value ~= 0
		and bgState.score.value ~= enemiesState.lastCheckedBgState.score
	then
		if enemiesState.defaultSpawnTimer > enemiesState.MAX_DIFICULTY_TIMER then
			enemiesState.defaultSpawnTimer = math.max(0.1, enemiesState.defaultSpawnTimer - 0.1)
		end
		enemiesState.lastCheckedBgState.score = bgState.score.value
	end

	local base = math.floor(bgState.score.value / 100) * 100 -- Get the nearest lower multiple of 100
	if
		bgState.score.value >= base
		and bgState.score.value <= base + 10
		and base ~= 0
		and not bossState.boss.isSpawned
		and not bossState.boss.isDying
	then
		bossState.boss:spawn(function()
			enemiesState.isSpawning = true
			bossState.boss:reset()
			bossState.phaseTwo = false
		end)
	end

	if Player.healthSystem.health <= 0 then
		love.freeze(freezeTimer)
		isMouseVisible = true
	end

	bgState.camera:update(dt)
	bgState.bgMusic:update()

	if shootDelay <= 0 then
		Player:shoot(screenWidth, Player.y - Player.height / 2)
		shootDelay = 0.1
	end

	Player:move(dt)
	Player:broderPhysics(screenWidth, screenHeight)
	Player:laser(enemiesState.enemies, ParticleSystem.activeExplosions, ParticleSystem.ps, function()
		bgState.camera:shake()
		bgState.score:increment()
	end)

	Player:spinAttack(dt, enemiesState.enemies, ParticleSystem.activeExplosions, ParticleSystem.ps, function()
		bgState.score:increment()
	end, function()
		bgState.camera:shake()
	end)

	for i = #powerups, 1, -1 do
		local powerup = powerups[i]
		local isPoweringUp = CheckCollision(powerup, Player)

		if isPoweringUp then
			powerup:run(dt)
			table.remove(powerups, i) -- Remove collected power-up
		end
	end

	-- Move player smoothly into view during cutscene
	if Player.isRunningCutscene then
		Player.x = Player.x + (20 - Player.x) * dt * 3 -- Lerp towards x = 20
		if Player.x >= 19.9 then
			Player.x = 20
			Player.isRunningCutscene = false
		end
	end

	for _, enemy in ipairs(enemiesState.enemies) do
		enemy:move(dt)

		-- Check collision between Player and Enemy
		if enemy:checkCollision(Player) then
			enemy:destroy(enemiesState.enemies, ParticleSystem.activeExplosions, ParticleSystem.ps, function()
				bgState.camera:shake()
			end, true)
			Player:takeDamage(function()
				bgState.bgMusic:switchTracks()
			end)
		end
	end

	local randomEnemyX, randomEnemyY, enemeySpeed = bossState.boss:getPhaseOneEnemyPos()
	if enemiesState.isSpawning then
		bgState.grid:updateGrid(enemiesState.enemies, Player.projectiles)
		bgState.grid:checkCollisions(
			enemiesState.enemies,
			Player.projectiles,
			ParticleSystem.activeExplosions,
			ParticleSystem.ps,
			screenWidth + 100,
			screenHeight + 100,
			function()
				bgState.camera:shake()
			end,
			function()
				bgState.score:increment()
			end
		)

		if not Player.isRunningCutscene then
			if enemiesState.spawnTimer <= 0 then
				table.insert(
					enemiesState.enemies,
					Enemy:new(
						screenWidth,
						screenHeight,
						Player.x,
						Player.y,
						randomEnemyX,
						randomEnemyY,
						enemeySpeed,
						bossState.boss.inPhaseTwo
					)
				)
				enemiesState.spawnTimer = enemiesState.defaultSpawnTimer
			end
		end
	end

	if bossState.boss.isSpawned then
		-- Check collision between Player and Boss
		if CheckCollision(Player, bossState.boss) then
			Player:takeDamage(function()
				bgState.bgMusic:switchTracks()
			end)
		end

		-- Check collision between laser and Boss
		if Player.isLasering then
			if CheckCollision(Player.laserBeam, bossState.boss) then
				bossState.boss:takeDamage(function()
					bgState.camera:shake()
				end, function()
					enemiesState.isSpawning = false
				end)
			end
		end

		for _, projectile in ipairs(Player.projectiles) do
			if CheckCollision(projectile, bossState.boss) then
				bossState.boss:takeDamage(function()
					bgState.camera:shake()
				end, function()
					enemiesState.isSpawning = false
				end)
			end
		end
	end

	Powerups:update(powerups, dt, screenWidth, screenHeight, effectsCallbacks)

	-- Update explosions
	for i = #ParticleSystem.activeExplosions, 1, -1 do
		ParticleSystem.activeExplosions[i]:update(dt)

		-- Remove finished particle effects
		if ParticleSystem.activeExplosions[i]:getCount() == 0 then
			table.remove(ParticleSystem.activeExplosions, i)
		end
	end

	bossState.boss:update(dt)
end

function love.draw()
	love.graphics.clear(0, 0, 0.148, 1) -- Black background (R, G, B, Alpha)
	love.graphics.push() -- Save the transformation
	love.graphics.setColor(1, 1, 1, 1) -- Reset color to full brightness

	love.graphics.translate(bgState.camera.x, bgState.camera.y)

	bgState.score:draw()
	Background:draw()
	Player:draw()
	Enemy:draw(enemiesState.enemies)

	for _, explosion in ipairs(ParticleSystem.activeExplosions) do
		love.graphics.setColor(1, 1, 1, 1) -- Ensure particles are drawn properly
		love.graphics.draw(explosion)
	end

	for _, p in ipairs(powerups) do
		p:draw()
	end

	bossState.boss:draw()
	-- bgState.grid:draw()
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
	enemiesState = {
		enemies = {},
		isSpawning = true,
		defaultSpawnTimer = Enemy.defaultSpawnTimer,
		spawnTimer = Enemy.defaultSpawnTimer,
		MAX_DIFICULTY_TIMER = 0.4,
		lastCheckedBgState = { score = 0 }, -- Initialize this
	}
	powerups = {}
	Freeze:reset()
	Player:reset()
	bgState.score:reset()
	bgState.bgMusic:reset()
	bossState.boss:reset()
end
