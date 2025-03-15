math.randomseed(os.time())

local Background = {
	currentFrame = 1, -- Start with the first frame
	animationTimer = 0, -- Timer for animation
	animationSpeed = math.random(0.3, 0.8), -- Seconds per frame
	scale = math.random(0.8, 1.4),
	stars = {},
	starsCount = 20, -- Number of stars
	speed = { -100, -200 }, -- Speed range for parallax effect
	screenWidth = 800, -- Placeholder, will be set in init()
	screenHeight = 600,
}

function Background:init(screenWidth, screenHeight)
	self.spriteSheet = love.graphics.newImage("res/sprites/i_are_spaceship_128.png")
	self.spriteSheet:setFilter("nearest", "nearest") -- Prevent pixel blurring

	self.screenWidth = screenWidth
	self.screenHeight = screenHeight

	-- Define animation frames
	self.frames = {
		{
			love.graphics.newQuad(88, 8, 8, 8, self.spriteSheet:getDimensions()),
			love.graphics.newQuad(88, 0, 8, 8, self.spriteSheet:getDimensions()),
			love.graphics.newQuad(80, 8, 8, 8, self.spriteSheet:getDimensions()),
			love.graphics.newQuad(80, 0, 8, 8, self.spriteSheet:getDimensions()),
		},
		{
			love.graphics.newQuad(8, 56, 8, 8, self.spriteSheet:getDimensions()),
			love.graphics.newQuad(8, 48, 8, 8, self.spriteSheet:getDimensions()),
			love.graphics.newQuad(0, 56, 8, 8, self.spriteSheet:getDimensions()),
			love.graphics.newQuad(0, 48, 8, 8, self.spriteSheet:getDimensions()),
		},
	}

	-- Pre-generate stars
	for i = 1, self.starsCount do
		self:addStar(math.random(0, screenWidth)) -- Random X position for initial stars
	end
end

-- Add a new star at a given X position
function Background:addStar(x)
	table.insert(self.stars, {
		x = x or self.screenWidth, -- If no X is given, spawn at the right edge
		y = math.random(0, self.screenHeight - 4),
		speed = math.random(self.speed[1], self.speed[2]), -- Different speeds for parallax
		frameSet = math.random(1, 2), -- Pick one of the two frame sets
		currentFrame = 1,
	})
end

function Background:animate(dt)
	self.animationTimer = self.animationTimer + dt
	if self.animationTimer >= self.animationSpeed then
		self.animationTimer = 0
		for _, star in ipairs(self.stars) do
			local frameSet = self.frames[star.frameSet] -- Get the frame set
			local numFrames = #frameSet -- Count the frames
			star.currentFrame = (star.currentFrame % numFrames) + 1 -- Cycle through frames
		end
	end

	-- Move stars to the right & remove old ones
	for i = #self.stars, 1, -1 do
		local star = self.stars[i]
		star.x = star.x + star.speed * dt -- Move to the left

		-- If the star moves off-screen to the right, remove it & create a new one
		if star.x < -10 then
			table.remove(self.stars, i)
			self:addStar(self.screenWidth + 10) -- Spawn a new star slightly off-screen on the left
		end
	end
end

function Background:draw()
	for _, star in ipairs(self.stars) do
		love.graphics.draw(
			self.spriteSheet,
			self.frames[star.frameSet][star.currentFrame], -- Select correct frame
			star.x,
			star.y,
			0,
			self.scale,
			self.scale,
			4,
			4
		)
	end
end

return Background
