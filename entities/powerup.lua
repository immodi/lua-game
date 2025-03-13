local Powerup = {
	x = 0,
	y = 0,
	width = 32,
	height = 32,
	scale = 2,
	speed = 200, -- Constant speed towards x = 0
	bobbingFrequency = 3,
	bobbingAmplitude = 30,
	spawnRate = 0.0005,
	powerUpCallback = nil,
	powerUpSound = nil,
}

local PowerUpsSprites = {
	spinAttack = love.graphics.newImage("res/sprites/ball_only.png"),
	heal = love.graphics.newImage("res/sprites/ball_only_green.png"),
}

local PowerUpsSounds = {
	spinAttack = love.audio.newSource("res/audio/effects/spin.wav", "static"),
	heal = love.audio.newSource("res/audio/effects/heal.wav", "static"),
}

Powerup.__index = Powerup

-- Initialize power-up with random sprite
function Powerup:init(randomKey, powerUpCallback)
	local instance = setmetatable({}, Powerup)

	instance.spriteSheet = PowerUpsSprites[randomKey]
	instance.spriteSheet:setFilter("nearest", "nearest")
	instance.powerUpCallback = powerUpCallback
	instance.powerUpSound = PowerUpsSounds[randomKey]

	return instance
end

function Powerup:getRandomKey()
	local keys = {}
	for key in pairs(PowerUpsSprites) do
		table.insert(keys, key)
	end

	local randomKey = keys[math.random(#keys)]

	return randomKey
end

-- Spawn the power-up off-screen (right side)
function Powerup:spawn(screenWidth, screenHeight)
	self.x = screenWidth + math.random(0, 100) -- Randomly spawn beyond the screen
	self.y = math.random(50, screenHeight - 50) -- Random Y position (avoiding top/bottom edges)
end

function Powerup:update(powerups, dt, screenWidth, screenHeight, effectsCallbacks)
	if math.random() < self.spawnRate then
		local randomKey = Powerup:getRandomKey()

		local p = Powerup:init(randomKey, effectsCallbacks[randomKey])
		p:spawn(screenWidth, screenHeight)
		table.insert(powerups, p)
	end

	-- Update all power-ups
	for i = #powerups, 1, -1 do
		powerups[i]:move(dt)

		-- Remove off-screen power-ups
		if powerups[i].toBeRemoved then
			table.remove(powerups, i)
		end
	end
end

function Powerup:run(dt)
	self.powerUpSound:play()
	self.powerUpCallback(dt)
end

-- Move the power-up towards x = 0 at a constant speed
function Powerup:move(dt)
	self.x = self.x - self.speed * dt

	-- Remove power-up when it leaves the screen
	if self.x + self.width < -100 then
		self.toBeRemoved = true -- Mark for removal in the game update
	end

	self:animate(dt)
end

function Powerup:animate(dt)
	-- Sine wave oscillation for vertical movement
	self.y = self.y + math.sin(love.timer.getTime() * self.bobbingFrequency) * self.bobbingAmplitude * dt
end

-- Draw the power-up at its position
function Powerup:draw()
	if self.spriteSheet then
		love.graphics.draw(
			self.spriteSheet,
			self.x,
			self.y,
			0,
			self.scale, -- Scale X
			self.scale -- Scale Y
		)
	end
end

return Powerup
