math.randomseed(os.time())

local Enemy = {}

Enemy.__index = Enemy -- Enable object-oriented behavior

function Enemy:new(screenWidth, screenHeight, targetX, targetY)
	local instance = setmetatable({}, Enemy)
	local spriteSheet = love.graphics.newImage("res/sprites/i_are_spaceship_128.png") -- Load spritesheet
	spriteSheet:setFilter("nearest", "nearest") -- Prevent pixel blurring

	instance.tracks = {
		love.audio.newSource("res/audio/effects/Explosion__006.ogg", "static"),
		love.audio.newSource("res/audio/effects/Explosion__007.ogg", "static"),
	}
	instance.spriteSheet = spriteSheet
	instance.sprite = love.graphics.newQuad(64, 0, 16, 16, spriteSheet:getDimensions())
	instance.scale = 4
	instance.width = 40
	instance.height = 40
	instance.vx = 0
	instance.vy = 0
	instance.x = 0
	instance.y = 0
	instance.speed = math.random(300, 600)
	instance.directions = { "right", "top" }
	instance.rotation = 0 -- Initial rotation angle
	instance.rotationSpeed = math.rad(5) / 0.1 -- Convert 5 degrees in 0.1s to radians per second

	instance.polygon = instance:generatePolygon(9, instance.width / 2)

	-- -- Select a random spawn side
	local side = instance.directions[math.random(#instance.directions)]

	if side == "right" then
		instance.x = screenWidth + math.random(1, 10)
		instance.y = math.random(0, screenHeight)
	elseif side == "top" then
		instance.x = math.random(0, screenWidth)
		instance.y = -math.random(1, 10) - instance.height
		-- elseif side == "left" then
		-- 	instance.x = -math.random(1, 10) - instance.width
		-- 	instance.y = math.random(0, screenHeight)
		-- elseif side == "bottom" then
		-- 	instance.x = math.random(0, screenWidth)
		-- 	instance.y = screenHeight + math.random(1, 10)
	end

	-- Set movement direction
	instance:launchTo(targetX, targetY)
	return instance
end

-- Generate a random polygon (asteroid-like shape)
function Enemy:generatePolygon(sides, radius)
	local vertices = {}
	for i = 1, sides do
		local angle = (i / sides) * math.pi * 2
		local r = radius * (0.75 + math.random() * 0.5) -- Slight variation for randomness
		local x = math.cos(angle) * r
		local y = math.sin(angle) * r
		table.insert(vertices, x)
		table.insert(vertices, y)
	end
	return vertices
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

	self:rotate(dt)
end

function Enemy:isOutOfBounds(screenWidth, screenHeight)
	return self.x < -self.width - 100
		or self.x > screenWidth + self.width
		or self.y < -self.height - 100
		or self.y > screenHeight + self.height
end

function Enemy:checkCollision(player)
	return self.x < player.x + player.width
		and self.x + self.width > player.x
		and self.y < player.y + player.height
		and self.y + self.height > player.y
end

function Enemy:destroy(enemies, activeExplosions, particleSystem, shakeCamera, applyEffects)
	if applyEffects then
		shakeCamera()
		self:emitParticles(activeExplosions, particleSystem)
		self.tracks[math.random(1, 2)]:play()
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
	local newParticles = particleSystem:clone() -- Create a separate particle system
	newParticles:setPosition(self.x + self.width / 2, self.y + self.height / 2)
	newParticles:emit(20)

	table.insert(activeExplosions, newParticles) -- Store it so it keeps rendering
end

function Enemy:draw(enemies)
	for _, enemy in ipairs(enemies) do
		love.graphics.push() -- Save current transformation

		-- Move the pivot point to the center of the sprite
		love.graphics.translate(enemy.x + enemy.width / 2, enemy.y + enemy.height / 2)
		love.graphics.rotate(enemy.rotation) -- Rotate around the new pivot point

		-- Draw the sprite at the adjusted position (0,0 now means the pivot point)
		love.graphics.draw(
			enemy.spriteSheet,
			enemy.sprite, -- Use the current frame
			0, -- X position relative to new origin
			0, -- Y position relative to new origin
			0, -- No extra rotation
			enemy.scale,
			enemy.scale,
			8, -- Adjust origin X (half of 16px)
			14 -- Adjust origin Y (half of 28px)
		)

		love.graphics.pop() -- Restore previous transformation
	end
end

return Enemy
