local Projectile = require("entities.projectile")
local HealthSystem = require("helpers.hearts")
local Laser = require("entities.laser")
local Player = {
	x = -100,
	y = 0,
	width = 20,
	height = 20,
	vx = 0, -- Velocity X
	vy = 0, -- Velocity Y
	baseHeart = 5,
	ax = 4000, -- Acceleration X
	scale = 4,
	ay = 4000, -- Acceleration Y
	friction = 0.86, -- Friction factor (between 0 and 1)
	image = {}, -- Load player sprite
	projectiles = {},
	currentFrame = 1, -- Start with the first frame
	animationTimer = 0, -- Timer for animation
	animationSpeed = 0.1, -- Seconds per frame
	isSlowing = false,
	healthSystem = {},
	particleSystem = {},
	isCritical = false,
	damageFlashTimer = 0,
	isDead = false,
	isRunningCutscene = true,
	isLasering = false,
	rotation = math.rad(90), -- Start at 0 degrees
	spinProgress = 0,
	isSpinning = false,
	maxRotation = math.rad(360),
	rotationSpeed = math.rad(360 * 2.5), -- 180 degrees per second (adjust as needed)
}

Player.__index = Player

function Player:init(screenWidth, screenHeight, particleSystem)
	local spriteSheet = love.graphics.newImage("res/sprites/i_are_spaceship_128.png")
	spriteSheet:setFilter("nearest", "nearest")
	self.healthSystem = HealthSystem:init(self.baseHeart)
	self.Timer = TimeToggler(0.2)

	self.laserBeam = Laser:init(screenWidth)

	-- Clone only if `particleSystem` exists
	if particleSystem then
		self.particleSystem = particleSystem:clone()
		self.particleSystem:setParticleLifetime(1, 2)
		self.particleSystem:setSizes(1.4)
		self.particleSystem:setSpeed(1000, 1400)
		self.particleSystem:setColors(1, 1, 1, 1, 1, 0.5, 0.5, 0.5, 1, 1, 1, 0)
	else
		print("Warning: No particle system provided!")
	end

	-- Store the spriteSheet for rendering
	self.spriteSheet = spriteSheet

	-- Define animation frames
	self.frames = {
		love.graphics.newQuad(0, 0, 16, 28, spriteSheet:getDimensions()),
		love.graphics.newQuad(16, 0, 16, 28, spriteSheet:getDimensions()),
		love.graphics.newQuad(32, 0, 16, 28, spriteSheet:getDimensions()),
		love.graphics.newQuad(48, 0, 16, 28, spriteSheet:getDimensions()),
	}

	self.laserSound = love.audio.newSource("res/audio/effects/laser.wav", "static")
	self.spinLaserSound = love.audio.newSource("res/audio/effects/laser12.wav", "static")

	-- Apply scale
	self.width = 16 * self.scale
	self.height = 28 * self.scale
	self.screenWidth = screenWidth
	self.screenHeight = screenHeight

	self.y = (screenHeight - self.height) / 2
end

function Player:takeDamage(stopTheBgMusic)
	self.healthSystem:damage()
	self:checkIfDead(stopTheBgMusic)
	self.damageFlashTimer = 0.2
end

function Player:updatePosition(dt)
	self.x = self.x + self.vx * dt
	self.y = self.y + self.vy * dt

	self.vx = self.vx * self.friction
	self.vy = self.vy * self.friction
end

function Player:broderPhysics(screenWidth, screenHeight)
	if not self.isRunningCutscene then
		if self.x + self.width >= screenWidth then
			self.x = screenWidth - self.width
			self.vx = -self.vx * 0.5 -- Bounce with some speed reduction
		end
		if self.y + self.height >= screenHeight then
			self.y = screenHeight - self.height
			self.vy = -self.vy * 0.5
		end
		if self.x <= 0 then
			self.x = 0
			self.vx = -self.vx * 0.5
		end
		if self.y <= 0 then
			self.y = 0
			self.vy = -self.vy * 0.5
		end
	end
end

function Player:move(dt)
	if not self.isRunningCutscene then
		if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
			self.vx = self.vx + self.ax * dt
			self.isSlowing = true
		end
		if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
			self.vx = self.vx - self.ax * dt
			self.isSlowing = false
		end
		if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
			self.vy = self.vy + self.ay * dt
		end
		if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
			self.vy = self.vy - self.ay * dt
		end
	end

	if self.damageFlashTimer > 0 then
		self.damageFlashTimer = self.damageFlashTimer - dt
	end

	Player:updatePosition(dt)
	for _, projectile in ipairs(self.projectiles) do
		projectile:move(dt)
	end

	Player:animateMovement(dt)
	self.laserBeam:update(dt, self)

	self.isCritical = self.Timer(dt)
	self.particleSystem:update(dt)
end

function Player:animateMovement(dt)
	self.animationTimer = self.animationTimer + dt
	if self.animationTimer >= self.animationSpeed then
		self.animationTimer = 0
		local startFrame = self.isSlowing and 1 or 3 -- Use first two frames if true, otherwise last two
		self.currentFrame = startFrame + (self.currentFrame % 2)
	end
end

function Player:checkIfDead(stopTheBgMusic)
	if self.healthSystem.health <= 0 and not self.isDead then
		self.isDead = true -- Set to dead only once
		stopTheBgMusic()
	end
	-- Emit explosion particles ONCE
	if self.particleSystem then
		self.particleSystem:setPosition(self.x + self.width / 2, self.y + self.height / 2)
		self.particleSystem:emit(100)
	end
end

function Player:shoot(screenWidth, targetY)
	if not self.isRunningCutscene and not self.isLasering and not self.isSpinning then
		if not self.canShoot then
			return
		end -- Prevent holding down to spam fire

		table.insert(
			self.projectiles,
			Projectile:spawn(screenWidth, targetY, self.x + self.width, self.y + self.height / 2.5)
		)

		-- Restart sound from the beginning
		self.laserSound:stop()
		self.laserSound:play()

		-- Prevent immediate re-firing until key is released
		self.canShoot = false
	end
end

function Player:laser(enemies, activeExplosions, particleSystem, shakeCamera)
	if not self.isRunningCutscene then
		if love.keyboard.isDown("l") and not self.isSpinning then
			self.isLasering = true
			for _, enemy in ipairs(enemies) do
				local isColliding = enemy:checkCollision(self.laserBeam)
				if isColliding then
					enemy:destroy(enemies, activeExplosions, particleSystem, shakeCamera, true)
				end
			end
		else
			self.isLasering = false
		end
	end
end

function Player:spinAttack(dt, enemies, activeExplosions, ps, scoreCallback, camerShakeCallback)
	if not self.isRunningCutscene then
		-- If spinning, update rotation
		if self.isSpinning and not self.isLasering then
			self.spinLaserSound:play()
			local spinAmount = self.rotationSpeed * dt
			self.rotation = self.rotation + spinAmount
			self.spinProgress = self.spinProgress + spinAmount
			-- Stop spinning after 360 degrees
			if self.spinProgress >= math.rad(360) then
				for _, enemy in ipairs(enemies) do
					enemy:destroy(enemies, activeExplosions, ps, camerShakeCallback, true)
					scoreCallback()
				end

				for i = #enemies, 1, -1 do
					table.remove(enemies, i) -- Remove all enemies
				end

				self.isSpinning = false
				self.rotation = math.rad(90)
				self.spinProgress = 0
				self.spinLaserSound:stop()
			end
		end
	end
end

function Player:reset()
	self.x = -100
	self.y = (self.screenHeight - self.height) / 2
	self.vx = 0 -- Velocity X
	self.vy = 0 -- Velocity Y
	self.projectiles = {}
	self.currentFrame = 1
	self.animationTimer = 0
	self.damageFlashTimer = 0
	self.animationSpeed = 0.1
	self.isSlowing = false
	self.isDead = false
	self.healthSystem = HealthSystem:init(Player.baseHeart)
	self.isCritical = false
	self.isRunningCutscene = true
	self.isLasering = false
	self.rotation = math.rad(90) -- Start at 0 degrees
	self.spinProgress = 0
	self.isSpinning = false
	self.maxRotation = math.rad(360)
end

function Player:draw()
	self.healthSystem:draw()
	if not self.isDead then
		if self.healthSystem.health > 1 then
			if self.damageFlashTimer > 0 then
				love.graphics.setColor(1, 0, 0, 1) -- Red tint
			else
				love.graphics.setColor(1, 1, 1, 1) -- Normal color
			end
		else
			if self.isCritical then
				love.graphics.setColor(1, 0, 0, 1) -- Red tint
			else
				love.graphics.setColor(1, 1, 1, 1) -- Normal color
			end
		end

		love.graphics.draw(
			self.spriteSheet,
			self.frames[self.currentFrame], -- Use the current frame
			self.x + self.width / 2,
			self.y + self.height / 2,
			self.rotation, -- Use dynamic rotation instead of static 90 degrees
			self.scale,
			self.scale,
			8, -- Adjust origin X (half of 16px)
			14 -- Adjust origin Y (half of 28px)
		)

		love.graphics.setColor(1, 1, 1, 1) -- Reset color after drawing
	end

	if not self.isRunningCutscene and self.isLasering or self.isSpinning then
		self.laserBeam:draw()
	end

	for _, projectile in ipairs(self.projectiles) do
		projectile:draw()
	end

	if self.isDead then
		if self.particleSystem then
			love.graphics.draw(self.particleSystem)
		end
	end
end

function TimeToggler(interval)
	local timer = 0
	local state = false

	return function(dt)
		timer = timer + dt
		if timer >= interval then
			timer = timer - interval -- Reset timer while keeping overflow
			state = not state -- Toggle the boolean
		end
		return state
	end
end

return Player
