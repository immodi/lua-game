function CheckCollision(objectOne, objectTwo)
	-- Get objectOne dimensions: use getScaledWidth/Height if available
	local o1Width = objectOne.getScaledWidth and objectOne:getScaledWidth() or objectOne.width
	local o1Height = objectOne.getScaledHeight and objectOne:getScaledHeight() or objectOne.height

	-- Get objectTwo dimensions: use getScaledWidth/Height if available
	local o2Width = objectTwo.getScaledWidth and objectTwo:getScaledWidth() or objectTwo.width
	local o2Height = objectTwo.getScaledHeight and objectTwo:getScaledHeight() or objectTwo.height

	return objectOne.x < objectTwo.x + o2Width
		and objectOne.x + o1Width > objectTwo.x
		and objectOne.y < objectTwo.y + o2Height
		and objectOne.y + o1Height > objectTwo.y
end

return CheckCollision
