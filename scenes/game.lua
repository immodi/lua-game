local Player = require("entities.player")
local Enemy = require("entities.enemy")
local Grid = require("entities.grid")
local Camera = require("helpers.camera")
local Background = require("helpers.background")
local ParticleSystem = require("helpers.particles")
local Freeze = require("helpers.freeze")
local Score = require("helpers.score")
local Powerups = require("entities.powerup")
local Boss = require("entities.boss")

local Game = {
	bgState = {
		-- bgMusic = {},
		score = {},
		camera = {},
		grid = {},
	},

	enemiesState = {
		enemies = {},
		isSpawning = true,
		defaultSpawnTimer = Enemy.defaultSpawnTimer,
		spawnTimer = Enemy.defaultSpawnTimer,
		MAX_DIFICULTY_TIMER = 0.4,
		lastCheckedBgState = { score = 0 }, -- Initialize this
	},

	bossState = {
		boss = {},
	},

	powerups = {}, -- Table to store active power-ups
	shootDelay = 0.1,
	freezeTimer = 1,
	isMouseVisible = false,
	effectsCallbacks = {},
}

Game.__index = Game

function Game:init()
	local instance = setmetatable({}, Game)
	ParticleSystem:init()
	instance.bgState.score = Score:init()
	instance.bgState.camera = Camera:init()
	instance.bgState.bgMusic = GlobalObjects.bgMusic
	local screenWidth, screenHeight = love.graphics.getDimensions()
	love.mouse.setVisible(self.isMouseVisible)

	Player:init(screenWidth, screenHeight, ParticleSystem.ps:clone(), GameSettings.isSoundEffectsMuted)
	Background:init(screenWidth, screenHeight)
	instance.bossState.boss = Boss:init(screenWidth, screenHeight)
	instance.bgState.grid = Grid:init()

	instance.effectsCallbacks = {
		spinAttack = function(dt)
			if Player.spinProgress == 0 then
				Player.isSpinning = true
				Player:spinAttack(
					dt,
					instance.enemiesState.enemies,
					ParticleSystem.activeExplosions,
					ParticleSystem.ps,
					function()
						Game.bgState.score:increment()
					end,
					function()
						Game.bgState.camera:shake()
					end
				)
			end
		end,

		heal = function(dt)
			if Player.healthSystem.health < Player.baseHeart then
				Player.healthSystem:heal()
			end
		end,
	}

	return instance
end

function Game:update(dt)
	local screenWidth, screenHeight = love.graphics.getDimensions()
	love.mouse.setVisible(self.isMouseVisible)
	self.enemiesState.spawnTimer = self.enemiesState.spawnTimer - dt
	self.shootDelay = self.shootDelay - dt
	Background:animate(dt)
	self.bgState.score:update(dt)

	if self.enemiesState.lastCheckedBgState.score == nil then
		self.enemiesState.lastCheckedBgState.score = 0
	end

	if
		self.bgState.score.value % 100 == 0
		and self.bgState.score.value ~= 0
		and self.bgState.score.value ~= self.enemiesState.lastCheckedBgState.score
	then
		if self.enemiesState.defaultSpawnTimer > self.enemiesState.MAX_DIFICULTY_TIMER then
			self.enemiesState.defaultSpawnTimer = math.max(0.1, self.enemiesState.defaultSpawnTimer - 0.1)
		end
		self.enemiesState.lastCheckedBgState.score = self.bgState.score.value
	end

	local base = math.floor(self.bgState.score.value / 100) * 100 -- Get the nearest lower multiple of 100
	if
		self.bgState.score.value >= base
		and self.bgState.score.value <= base + 10
		and base ~= 0
		and not self.bossState.boss.isSpawned
		and not self.bossState.boss.isDying
	then
		self.bossState.boss:spawn(function()
			self.enemiesState.isSpawning = true
			self.bossState.boss:reset()
			self.bossState.phaseTwo = false
		end)
	end

	if Player.healthSystem.health <= 0 then
		love.freeze(self.freezeTimer)
		self.isMouseVisible = true
	end

	self.bgState.camera:update(dt)
	-- self.bgState.bgMusic:update(GameSettings.isBgMuted)

	if self.shootDelay <= 0 then
		Player:shoot(screenWidth, Player.y - Player.height / 2)
		self.shootDelay = 0.1
	end

	Player:move(dt)
	Player:broderPhysics(screenWidth, screenHeight)
	Player:laser(self.enemiesState.enemies, ParticleSystem.activeExplosions, ParticleSystem.ps, function()
		self.bgState.camera:shake()
		self.bgState.score:increment()
	end)

	Player:spinAttack(dt, self.enemiesState.enemies, ParticleSystem.activeExplosions, ParticleSystem.ps, function()
		self.bgState.score:increment()
	end, function()
		self.bgState.camera:shake()
	end)

	for i = #self.powerups, 1, -1 do
		local powerup = self.powerups[i]
		local isPoweringUp = CheckCollision(powerup, Player)

		if isPoweringUp then
			powerup:run(dt)
			table.remove(self.powerups, i) -- Remove collected power-up
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

	for _, enemy in ipairs(self.enemiesState.enemies) do
		enemy:move(dt)

		-- Check collision between Player and Enemy
		if enemy:checkCollision(Player) then
			enemy:destroy(self.enemiesState.enemies, ParticleSystem.activeExplosions, ParticleSystem.ps, function()
				self.bgState.camera:shake()
			end, true)
			Player:takeDamage(function()
				self.bgState.bgMusic:switchTracks()
			end)
		end
	end

	local randomEnemyX, randomEnemyY, enemeySpeed = self.bossState.boss:getPhaseOneEnemyPos()
	if self.enemiesState.isSpawning then
		self.bgState.grid:updateGrid(self.enemiesState.enemies, Player.projectiles)
		self.bgState.grid:checkCollisions(
			self.enemiesState.enemies,
			Player.projectiles,
			ParticleSystem.activeExplosions,
			ParticleSystem.ps,
			screenWidth + 100,
			screenHeight + 100,
			function()
				self.bgState.camera:shake()
			end,
			function()
				self.bgState.score:increment()
			end
		)

		if not Player.isRunningCutscene then
			if self.enemiesState.spawnTimer <= 0 then
				table.insert(
					self.enemiesState.enemies,
					Enemy:new(
						screenWidth,
						screenHeight,
						Player.x,
						Player.y,
						randomEnemyX,
						randomEnemyY,
						enemeySpeed,
						self.bossState.boss.inPhaseTwo,
						GameSettings.isSoundEffectsMuted
					)
				)
				self.enemiesState.spawnTimer = self.enemiesState.defaultSpawnTimer
			end
		end
	end

	if self.bossState.boss.isSpawned then
		-- Check collision between Player and Boss
		if CheckCollision(Player, self.bossState.boss) then
			Player:takeDamage(function()
				self.bgState.bgMusic:switchTracks()
			end)
		end

		-- Check collision between laser and Boss
		if Player.isLasering then
			if CheckCollision(Player.laserBeam, self.bossState.boss) then
				self.bossState.boss:takeDamage(function()
					self.bgState.camera:shake()
				end, function()
					self.enemiesState.isSpawning = false
				end)
			end
		end

		for _, projectile in ipairs(Player.projectiles) do
			if CheckCollision(projectile, self.bossState.boss) then
				self.bossState.boss:takeDamage(function()
					self.bgState.camera:shake()
				end, function()
					self.enemiesState.isSpawning = false
				end)
			end
		end
	end

	Powerups:update(
		self.powerups,
		dt,
		screenWidth,
		screenHeight,
		self.effectsCallbacks,
		GameSettings.isSoundEffectsMuted
	)

	-- Update explosions
	for i = #ParticleSystem.activeExplosions, 1, -1 do
		ParticleSystem.activeExplosions[i]:update(dt)

		-- Remove finished particle effects
		if ParticleSystem.activeExplosions[i]:getCount() == 0 then
			table.remove(ParticleSystem.activeExplosions, i)
		end
	end

	self.bossState.boss:update(dt)
end

function Game:draw()
	love.graphics.clear(0, 0, 0.148, 1) -- Black background (R, G, B, Alpha)
	love.graphics.push() -- Save the transformation
	love.graphics.setColor(1, 1, 1, 1) -- Reset color to full brightness

	love.graphics.translate(self.bgState.camera.x, self.bgState.camera.y)

	self.bgState.score:draw()
	Background:draw()
	Player:draw()
	Enemy:draw(self.enemiesState.enemies)

	for _, explosion in ipairs(ParticleSystem.activeExplosions) do
		love.graphics.setColor(1, 1, 1, 1) -- Ensure particles are drawn properly
		love.graphics.draw(explosion)
	end

	for _, p in ipairs(self.powerups) do
		p:draw()
	end

	self.bossState.boss:draw()
	-- bgState.grid:draw()
	love.graphics.pop() -- Restore transformation after shake
end

function love.keyreleased(key)
	if key == "rshift" then
		Player.canShoot = true
	end
end

function Game:freeze(duration)
	local freezeGameCallback = function()
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
	end

	local overrideUpdateCallback = function(dt)
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

	local overrideDrawCallback = function()
		Freeze:draw(function()
			love.reset()
		end, function()
			Freeze:reset() -- Restore original update and draw
			self:reset()
			love.changeState("menu")
		end)
	end

	return freezeGameCallback, overrideUpdateCallback, overrideDrawCallback
end

function Game:keypressed(key)
	Freeze:keypressed(key)
end

function Game:reset()
	Freeze.isReseting = true
	self.isMouseVisible = false
	self.enemiesState = {
		enemies = {},
		isSpawning = true,
		defaultSpawnTimer = Enemy.defaultSpawnTimer,
		spawnTimer = Enemy.defaultSpawnTimer,
		MAX_DIFICULTY_TIMER = 0.4,
		lastCheckedBgState = { score = 0 }, -- Initialize this
	}
	self.powerups = {}
	Freeze:reset()
	Player:reset()
	self.bgState.score:reset()
	self.bgState.bgMusic:reset()
	self.bossState.boss:reset()
end

return Game
