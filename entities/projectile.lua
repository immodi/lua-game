local Projectile = {}

Projectile.__index = Projectile -- Enable object-oriented behavior

function Projectile:spawn(screenWidth, targetY, initialX, initialY)
	local instance = setmetatable({}, Projectile)

	instance.width = 8
	instance.height = 8
	instance.vx = 0
	instance.vy = 0
	instance.x = initialX
	instance.y = initialY
	instance.speed = 1000
	instance.currentFrame = 1 -- Start with the first frame
	instance.animationTimer = 1 -- Timer for animation
	instance.animationSpeed = 0.2 -- Seconds per frame
	instance.scale = 6

	instance.spriteSheet = love.graphics.newImage("res/sprites/i_are_spaceship_128.png")
	instance.spriteSheet:setFilter("nearest", "nearest") -- Prevent pixel blurring

	-- Define animation frames
	instance.frames = {
		love.graphics.newQuad(104, 8, 8, 8, instance.spriteSheet:getDimensions()),
		love.graphics.newQuad(104, 0, 8, 8, instance.spriteSheet:getDimensions()),
		love.graphics.newQuad(96, 8, 8, 8, instance.spriteSheet:getDimensions()),
		love.graphics.newQuad(96, 0, 8, 8, instance.spriteSheet:getDimensions()),
	}

	instance:launchTo(screenWidth, targetY + 100)
	return instance
end

function Projectile:launchTo(targetX, targetY)
	local dx = targetX - self.x -- Get horizontal distance
	local dy = targetY - self.y -- Get vertical distance

	-- Flip dy if needed (some systems use inverted Y-axis)
	-- dy = -dy  -- Uncomment this if projectiles are going in the wrong direction

	local length = math.sqrt(dx * dx + dy * dy)

	-- Normalize direction and set velocity with constant speed
	if length > 0 then
		self.vx = (dx / length) * self.speed
		self.vy = (dy / length) * self.speed
	end
end

function Projectile:move(dt)
	-- Update position based on velocity scaled by dt
	self.x = self.x + self.vx * dt
	self.y = self.y + self.vy * dt
	self:animate(dt)
end

function Projectile:isOutOfBounds(screenWidth, screenHeight)
	return self.x < -self.width - 100
		or self.x > screenWidth + self.width
		or self.y < -self.height - 100
		or self.y > screenHeight + self.height
end

function Projectile:destroy(projectiles, activeExplosions, particleSystem, shakeCamera, applyEffects)
	if applyEffects then
		shakeCamera()
		self:emitParticles(activeExplosions, particleSystem)
	end

	-- Loop backwards to safely remove the enemy
	for i = #projectiles, 1, -1 do
		if projectiles[i] == self then
			table.remove(projectiles, i)
			break
		end
	end
end

function Projectile:animate(dt)
	self.animationTimer = self.animationTimer + dt
	if self.animationTimer >= self.animationSpeed then
		self.animationTimer = 0
		local startFrame = 1
		self.currentFrame = startFrame + (self.currentFrame % 2)
	end
end

function Projectile:emitParticles(activeExplosions, particleSystem)
	local newParticles = particleSystem:clone() -- Create a separate particle system
	newParticles:setPosition(self.x + self.width / 2, self.y + self.height / 2)
	newParticles:emit(20)

	table.insert(activeExplosions, newParticles) -- Store it so it keeps rendering
end

function Projectile:draw()
	love.graphics.draw(
		self.spriteSheet,
		self.frames[self.currentFrame], -- Use the current frame
		self.x + self.width / 2,
		self.y + self.height / 2 - 8,
		math.rad(90), -- Rotate 90 degrees to the right
		self.scale,
		self.scale,
		4, -- Adjust origin X (half of 16px)
		4 -- Adjust origin Y (half of 28px)
	)
	-- love.graphics.draw(self.image, self.x, self.y, 0, self.scale, self.scale)
end

return Projectile
