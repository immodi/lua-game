local HealthSystem = {
	health = 3, -- default before override
	scale = 3, -- Scale factor for the hearts
	image = {},
	screenWidth = 0,
}

HealthSystem.__index = HealthSystem

function HealthSystem:init(health)
	local instance = setmetatable({}, HealthSystem)

	local image = love.graphics.newImage("res/assets/heart.png")
	image:setFilter("nearest", "nearest") -- Prevent pixel blurring

	instance.image = image
	instance.health = health or HealthSystem.health
	instance.imageWidth = instance.image:getWidth() * instance.scale
	instance.screenWidth = love.graphics.getWidth()

	return instance
end

function HealthSystem:damage()
	self.health = self.health - 1
end

function HealthSystem:heal()
	self.health = self.health + 1
end

function HealthSystem:draw()
	for i = 1, self.health, 1 do
		love.graphics.draw(self.image, self.screenWidth - i * self.imageWidth, 0, 0, self.scale, self.scale)
	end
end

return HealthSystem
