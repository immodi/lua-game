math.randomseed(os.time())

local HealthSystem = require("helpers.hearts")

local Boss = {
	width = 16, -- Actual sprite width
	height = 16, -- Actual sprite height
	scale = 50, -- Scale factor
	movementSpeed = 200,
	x = 0,
	y = 0,
	screenWidth = 0,
	screenHeight = 0,
	isSpawned = false,
	healthSystem = {},
	defaultHealth = 100,
	isDying = false,
	deathTimer = 0,
	deathCutsceneTime = 2,
	shakeIntensity = 0,
	flashbangAlpha = 0,
	finallyDeadCallback = {},
	inPhaseTwo = false,
	damageFlashTimer = 0, -- New: Timer for red flash effect
	flashDuration = 0.2, -- Duration of the red flash
}

Boss.__index = Boss

function Boss:init(screenWidth, screenHeight)
	local instance = setmetatable({}, Boss)
	instance.spriteSheet = love.graphics.newImage("res/sprites/i_are_spaceship_128.png")
	instance.spriteSheet:setFilter("nearest", "nearest")
	instance.screenWidth = screenWidth
	instance.screenHeight = screenHeight
	instance.sprite = love.graphics.newQuad(64, 0, 16, 16, instance.spriteSheet:getDimensions())
	instance.healthSystem = HealthSystem:init(self.defaultHealth)

	-- Scale width and height correctly
	instance.width = instance.width * instance.scale
	instance.height = instance.height * instance.scale

	-- Calculate position to center it on screen
	instance.x = screenWidth
	instance.y = (screenHeight / 2) - (instance.height / 2)

	return instance
end

function Boss:spawn(finallyDeadCallback)
	self.isSpawned = true
	self.finallyDeadCallback = finallyDeadCallback
end

function Boss:update(dt)
	if self.isDying then
		self.deathTimer = self.deathTimer + dt
		self.shakeIntensity = self.shakeIntensity + (dt * 10) -- Increase shake frequency

		local fadeOutDelay = self.deathCutsceneTime -- Extra delay before fading out
		local totalDeathTime = self.deathCutsceneTime + fadeOutDelay
		local fadeEndTime = totalDeathTime + self.deathCutsceneTime -- Total time including fade-out

		-- Step 1: Increase alpha (fade to white)
		if self.deathTimer < self.deathCutsceneTime then
			self.flashbangAlpha = math.min(self.deathTimer / self.deathCutsceneTime, 1)

		-- Step 2: Keep screen fully white for fadeOutDelay time
		elseif self.deathTimer < totalDeathTime then
			self.flashbangAlpha = 1
			self.isSpawned = false -- Boss disappears

		-- Step 3: Fade the screen back to normal gradually over deathCutsceneTime
		elseif self.deathTimer < fadeEndTime then
			local fadeOutProgress = (self.deathTimer - totalDeathTime) / self.deathCutsceneTime
			self.flashbangAlpha = math.max(1 - fadeOutProgress, 0)
		else
			self.flashbangAlpha = 0
			self.finallyDeadCallback()
		end
	else
		self:cutscene(dt)
	end

	-- Reduce the damage flash timer
	if self.damageFlashTimer > 0 then
		self.damageFlashTimer = self.damageFlashTimer - dt
	end
end

function Boss:takeDamage(cameraShakeCallback, deathCallback)
	if not self.isDying then
		cameraShakeCallback()

		-- Check if Boss is still alive
		if self.healthSystem.health > 0 then
			-- If Boss is about to enter phase two
			if self.healthSystem.health <= self.defaultHealth / 2 and not self.inPhaseTwo then
				self.inPhaseTwo = true
			end

			-- Apply damage
			self.healthSystem:damage()
			self.damageFlashTimer = self.flashDuration -- Start red flash effect

			-- Check if Boss should die after taking damage
			if self.healthSystem.health <= 0 then
				self.isDying = true
				self:die()
				deathCallback()
			end
		end
	end
end

function Boss:cutscene(dt)
	if self.isSpawned then
		if self.x > self.screenWidth - (self.width / 2) then
			self.x = self.x - self.movementSpeed * dt
		else
			self.x = self.screenWidth - (self.width / 2) -- Ensure it doesn't overshoot
		end
	end
end

function Boss:getPhaseOneEnemyPos()
	if self.isSpawned and self.healthSystem.health > 50 then
		local minY = self.screenHeight * 0.25 -- 25% from the top
		local maxY = self.screenHeight * 0.75 -- 75% from the top

		return self.screenWidth - (self.width / 3), math.random(minY, maxY), 1200
	else
		return nil
	end
end

function Boss:die()
	self.isDying = true
	self.deathTimer = 0
	self.shakeIntensity = 0
	self.flashbangAlpha = 0
end

function Boss:draw()
	if self.isSpawned then
		local shakeX, shakeY = 0, 0
		if self.isDying then
			-- Apply increasing shake effect
			local shakeAmount = math.sin(love.timer.getTime() * self.shakeIntensity) * (self.shakeIntensity * 2)
			shakeX = shakeAmount
			shakeY = shakeAmount
		end

		-- Apply a red tint if taking damage
		if self.damageFlashTimer > 0 then
			love.graphics.setColor(1, 0.2, 0.2) -- Red tint
		else
			love.graphics.setColor(1, 1, 1) -- Normal color
		end

		love.graphics.draw(
			self.spriteSheet,
			self.sprite,
			self.x + shakeX,
			self.y + shakeY,
			0, -- Rotation (0 means no rotation)
			self.scale, -- Scale X
			self.scale -- Scale Y
		)

		-- Reset color to default
		love.graphics.setColor(1, 1, 1)

		local barWidth = self.screenWidth - 2
		local barHeight = 20
		local barX = (self.screenWidth / 2) - (barWidth / 2) -- Center the origin
		local barY = self.screenHeight - 30 -- Position near the top

		-- Background (gray) health bar
		love.graphics.setColor(0.2, 0.2, 0.2) -- Dark gray
		love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

		-- Foreground (red) health bar
		local healthPercent = self.healthSystem.health / self.defaultHealth
		love.graphics.setColor(1, 0, 0) -- Red
		love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
	end

	-- Always draw the flashbang overlay if the boss is dying
	if self.isDying then
		love.graphics.setColor(1, 1, 1, self.flashbangAlpha)
		love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
		love.graphics.setColor(1, 1, 1)
	end
end

function Boss:reset()
	self.x = self.screenWidth
	self.y = (self.screenHeight / 2) - (self.height / 2)
	self.isSpawned = false
	self.isDying = false
	self.deathTimer = 0
	self.shakeIntensity = 0
	self.flashbangAlpha = 0
	self.damageFlashTimer = 0 -- New: Timer for red flash effect
	self.flashDuration = 0.2 -- Duration of the red flash
	self.healthSystem.health = self.defaultHealth
	self.inPhaseTwo = false
end

return Boss
