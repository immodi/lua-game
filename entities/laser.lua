local Laser = {
	x = 0,
	y = 0,
	width = 11,
	height = 32,
	currentLaserFrame = 1,
	laserAnimateTimer = 0,
	laserAnimateSpeed = 0.1,
	isMuted = false,
}
Laser.__index = Laser

function Laser:init()
	local instance = setmetatable({}, Laser)
	-- Load the sprite sheet
	instance.laserSpriteSheet = love.graphics.newImage("res/sprites/laserSprite.png")

	instance.spriteWidth = 11
	instance.spriteHeight = instance.laserSpriteSheet:getHeight()
	instance.numSprites = math.ceil(instance.width / instance.spriteWidth)

	instance.laserSpriteFrames = {
		love.graphics.newQuad(
			0,
			0,
			instance.spriteWidth,
			instance.spriteHeight,
			instance.laserSpriteSheet:getDimensions()
		),
		love.graphics.newQuad(
			21,
			0,
			instance.spriteWidth,
			instance.spriteHeight,
			instance.laserSpriteSheet:getDimensions()
		),
	}

	instance.isMuted = GameSettings.isSoundEffectsMuted or Laser.isMuted

	-- Load and set up laser sound
	instance.laserSound = love.audio.newSource("res/audio/effects/laser5.wav", "static")

	instance.isFiring = false -- Track if laser is firing

	return instance
end

function Laser:update(dt, player)
	self.isMuted = GameSettings.isSoundEffectsMuted or Laser.isMuted

	self.player = player
	self.x = player.x + player.width * 2 - player.width / 2 -- Fix: Start at the right edge of the player
	self.y = player.y + player.height / 2 - 4 -- Center laser vertically
	self.width = player.screenWidth * 2 - self.x -- Extend to the right edge of the screen

	-- Ensure the correct number of laser segments
	self.numSprites = math.ceil(self.width / self.spriteWidth)

	self:animate(dt)
	self:fire()
	-- self:spin()
end

function Laser:fire()
	if not self.player.isRunningCutscene and self.player.isLasering then
		if love.keyboard.isDown("l") then
			if not self.isFiring then
				if not self.isMuted then
					self.laserSound:play()
				end
				self.isFiring = true
			end
		else
			if self.isFiring then
				if self.laserSound:isPlaying() then
					self.laserSound:stop()
				end
				self.isFiring = false
			end
		end
	end
end

-- function Laser:spin()
-- 	if not self.player.isRunningCutscene and self.player.isSpinning then
-- 		if love.keyboard.isDown("k") then
-- 			self.isFiring = true
-- 		else
-- 			self.isFiring = false
-- 		end
-- 	end
-- end

function Laser:animate(dt)
	self.laserAnimateTimer = self.laserAnimateTimer + dt
	if self.laserAnimateTimer >= self.laserAnimateSpeed then
		self.laserAnimateTimer = 0
		self.currentLaserFrame = (self.currentLaserFrame % 2) + 1
	end
end

function Laser:draw()
	love.graphics.push()

	-- Find the ship's center
	local centerX = self.player.x + self.player.width / 2
	local centerY = self.player.y + self.player.height / 2 - 2

	-- Move the laser sideways (perpendicular to the rotation)
	local sideOffset = self.player.width + 4 -- Adjust as needed
	local shipTipX = centerX + math.sin(self.player.rotation) * sideOffset
	local shipTipY = centerY - math.cos(self.player.rotation) * sideOffset

	-- Set the laser's origin
	love.graphics.translate(shipTipX, shipTipY)

	-- Rotate the laser with the player
	love.graphics.rotate(self.player.rotation)

	-- Draw the laser extending forward
	for i = 0, self.numSprites - 1 do
		love.graphics.draw(
			self.laserSpriteSheet,
			self.laserSpriteFrames[self.currentLaserFrame],
			0, -- Keep X constant
			-i * self.spriteHeight, -- Move **upward** in the rotated direction
			0, -- No extra rotation per sprite
			1,
			1,
			self.spriteWidth / 2,
			self.spriteHeight / 2
		)
	end

	love.graphics.pop()
end

return Laser
