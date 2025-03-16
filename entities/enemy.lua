math.randomseed(os.time())

local Enemy = {
	defaultSpawnTimer = 0.8,
	isSpecial = false,
	isMuted = false,
}

Enemy.__index = Enemy -- Enable object-oriented behavior

function Enemy:new(screenWidth, screenHeight, targetX, targetY, spawnX, spawnY, speed, isSpecial)
	local instance = setmetatable({}, Enemy)
	local spriteSheet = love.graphics.newImage("res/sprites/i_are_spaceship_128.png") -- Load spritesheet
	spriteSheet:setFilter("nearest", "nearest") -- Prevent pixel blurring

	instance.tracks = {
		love.audio.newSource("res/audio/effects/Explosion__006.ogg", "static"),
		love.audio.newSource("res/audio/effects/Explosion__007.ogg", "static"),
	}
	instance.spriteSheet = spriteSheet
	instance.sprite = love.graphics.newQuad(64, 0, 16, 16, spriteSheet:getDimensions())

	instance.isMuted = GameSettings.isSoundEffectsMuted or Enemy.isMuted

	-- Determine scale based on whether it's a special enemy
	instance.isSpecial = isSpecial or Enemy.isSpecial
	instance.scale = instance.isSpecial and 10 or 4

	-- Get correct width and height based on scale
	instance.width = 16 * instance.scale
	instance.height = 16 * instance.scale

	-- Initialize position and velocity
	instance.vx = 0
	instance.vy = 0
	instance.speed = speed or math.random(300, 600)
	instance.rotation = 0 -- Initial rotation angle
	instance.rotationSpeed = math.rad(5) / 0.1 -- Convert 5 degrees in 0.1s to radians per second

	-- Use given spawn coordinates if provided
	if spawnX and spawnY then
		instance.x = spawnX
		instance.y = spawnY
	else
		-- Random spawn logic
		local side = math.random(2)
		if side == 1 then
			instance.x = screenWidth + instance.width / 2 -- Start off-screen
			instance.y = math.random(0, screenHeight)
		else
			instance.x = math.random(0, screenWidth)
			instance.y = -instance.height / 2
		end
	end

	instance:launchTo(targetX, targetY)
	return instance
end

function Enemy:rotate(dt)
	self.rotation = self.rotation + self.rotationSpeed * dt -- Rotate over time
end

function Enemy:launchTo(targetX, targetY)
	local dx = targetX - self.x
	local dy = targetY - self.y
	local length = math.sqrt(dx * dx + dy * dy)

	-- Normalize direction and set velocity with constant speed
	if length > 0 then
		self.vx = (dx / length) * self.speed
		self.vy = (dy / length) * self.speed
	end
end

function Enemy:move(dt)
	-- Update position based on velocity scaled by dt
	self.x = self.x + self.vx * dt
	self.y = self.y + self.vy * dt

	self.isMuted = GameSettings.isSoundEffectsMuted or Enemy.isMuted
	self:rotate(dt)
end

function Enemy:isOutOfBounds(screenWidth, screenHeight)
	return self.x + self.width / 2 < 0
		or self.x - self.width / 2 > screenWidth
		or self.y + self.height / 2 < 0
		or self.y - self.height / 2 > screenHeight
end

function Enemy:isCollidingWithWall(screenWidth, screenHeight)
	local collided = false

	if self.isSpecial then
		-- Left wall
		if self.x - self.width / 2 <= 0 then
			self.x = self.width / 2
			self.vx = -self.vx -- Reverse velocity
			collided = true
		end

		-- Right wall
		if self.x + self.width / 2 >= screenWidth then
			self.x = screenWidth - self.width / 2
			self.vx = -self.vx
			collided = true
		end

		-- Top wall
		if self.y - self.height / 2 <= 0 then
			self.y = self.height / 2
			self.vy = -self.vy
			collided = true
		end

		-- Bottom wall
		if self.y + self.height / 2 >= screenHeight then
			self.y = screenHeight - self.height / 2
			self.vy = -self.vy
			collided = true
		end
	end

	return collided
end

function Enemy:checkCollision(object)
	local hitboxWidth = self.width * 0.8
	local hitboxHeight = self.height * 0.8

	return self.x - hitboxWidth / 2 < object.x + object.width
		and self.x + hitboxWidth / 2 > object.x
		and self.y - hitboxHeight / 2 < object.y + object.height
		and self.y + hitboxHeight / 2 > object.y
end

function Enemy:destroy(enemies, activeExplosions, particleSystem, shakeCamera, applyEffects)
	if applyEffects then
		shakeCamera()
		self:emitParticles(activeExplosions, particleSystem)
		if not self.isMuted then
			self.tracks[math.random(1, 2)]:play()
		end
	end

	-- Loop backwards to safely remove the enemy
	for i = #enemies, 1, -1 do
		if enemies[i] == self then
			table.remove(enemies, i)
			break
		end
	end
end

function Enemy:emitParticles(activeExplosions, particleSystem)
	local newParticles = particleSystem:clone()
	newParticles:setPosition(self.x, self.y) -- Centered particle emission
	newParticles:emit(20)

	table.insert(activeExplosions, newParticles)
end

function Enemy:draw(enemies)
	for _, enemy in ipairs(enemies) do
		love.graphics.push() -- Save current transformation

		-- Move the pivot point to the center of the sprite
		love.graphics.translate(enemy.x, enemy.y)
		love.graphics.rotate(enemy.rotation)

		-- Draw the sprite with center alignment
		love.graphics.draw(
			enemy.spriteSheet,
			enemy.sprite,
			0,
			0,
			0, -- X, Y, Rotation
			enemy.scale,
			enemy.scale,
			8, -- Origin X (half of 16px)
			8 -- Origin Y (half of 16px)
		)

		love.graphics.pop() -- Restore previous transformation
	end
end

function Enemy:drawHitbox()
	-- Get scaled width and height
	local width = self.width
	local height = self.height

	-- Draw hitbox centered
	love.graphics.setColor(1, 0, 0, 1) -- Red color for debugging
	love.graphics.rectangle("line", self.x - width / 2, self.y - height / 2, width, height)
	love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

return Enemy
