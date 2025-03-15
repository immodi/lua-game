local Camera = {
	x = 0,
	y = 0,
	shakeIntensity = 0,
	shakeDuration = 0,
}

Camera.__index = Camera

function Camera:init()
	local instance = setmetatable({}, Camera)

	return instance
end

function Camera:update(dt)
	if self.shakeDuration > 0 then
		self.shakeDuration = self.shakeDuration - dt
		self.x = math.random(-self.shakeIntensity, self.shakeIntensity)
		self.y = math.random(-self.shakeIntensity, self.shakeIntensity)
	else
		self.x, self.y = 0, 0 -- Reset position after shaking
	end
end

function Camera:shake()
	self.shakeIntensity = 7
	self.shakeDuration = 0.3
end

return Camera
