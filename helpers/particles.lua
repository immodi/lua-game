-- Load the spritesheet
local spriteSheet = love.graphics.newImage("res/sprites/i_are_spaceship_128.png")
spriteSheet:setFilter("nearest", "nearest") -- Prevent pixel blurring

-- Define the part of the image to use (x, y, width, height)
local quad = love.graphics.newQuad(72, 16, 8, 8, spriteSheet:getDimensions())

-- Function to extract the quad as an image
local function createParticleImage()
	local canvas = love.graphics.newCanvas(16, 16) -- Create a small canvas (same size as quad)
	love.graphics.setCanvas(canvas) -- Start drawing on the canvas
	love.graphics.clear(0, 0, 0, 0) -- Clear to transparent
	love.graphics.draw(spriteSheet, quad, 0, 0) -- Draw the specific quad onto the canvas
	love.graphics.setCanvas() -- Reset drawing to default
	return love.graphics.newImage(canvas:newImageData()) -- Convert canvas to an image
end

local particleImage = createParticleImage() -- Generate the particle image

-- Create a particle system
local ParticleSystem = {
	ps = love.graphics.newParticleSystem(particleImage, 100), -- Use extracted image
	activeExplosions = {},
}

function ParticleSystem:init()
	local ps = self.ps

	ps:setParticleLifetime(0.5, 1.5)
	ps:setEmissionRate(0)
	ps:setSizeVariation(0.5)
	ps:setSizes(1.3)

	ps:setSpread(math.rad(360))
	ps:setSpeed(600, 800)
	ps:setLinearAcceleration(-300, -300, 300, 300)
	ps:setRadialAcceleration(-500, 500)
	ps:setColors(1, 1, 1, 1, 1, 0.5, 0.5, 0.5, 1, 1, 1, 0)
end

return ParticleSystem
