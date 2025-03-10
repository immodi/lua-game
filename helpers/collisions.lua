function CheckCollision(objectOne, onjectTwo)
	return objectOne.x < onjectTwo.x + onjectTwo.width
		and objectOne.x + objectOne.width > onjectTwo.x
		and objectOne.y < onjectTwo.y + onjectTwo.height
		and objectOne.y + objectOne.height > onjectTwo.y
end

return CheckCollision
