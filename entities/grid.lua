-- local CheckCollision = require("helpers.collisions")

-- local Grid = {
-- 	grid = {},
-- 	cellSize = 50,
-- }

-- function Grid:getCellKey(x, y)
-- 	local cellX = math.floor(x / self.cellSize)
-- 	local cellY = math.floor(y / self.cellSize)
-- 	return cellX .. "," .. cellY -- Unique key for each cell
-- end

-- function Grid:updateGrid(enemies, projectiles)
-- 	self.grid = {} -- Reset grid each frame

-- 	for _, enemy in ipairs(enemies) do
-- 		local cellKey = self:getCellKey(enemy.x, enemy.y)
-- 		if not self.grid[cellKey] then
-- 			self.grid[cellKey] = {}
-- 		end
-- 		table.insert(self.grid[cellKey], enemy)
-- 	end

-- 	for _, projectile in ipairs(projectiles) do
-- 		local cellKey = self:getCellKey(projectile.x, projectile.y)
-- 		if not self.grid[cellKey] then
-- 			self.grid[cellKey] = {}
-- 		end
-- 		table.insert(self.grid[cellKey], projectile)
-- 	end
-- end

-- function Grid:checkCollisions(
-- 	enemies,
-- 	projectiles,
-- 	activeExplosions,
-- 	particleSystem,
-- 	screenWidth,
-- 	screenHeight,
-- 	shakeCamera
-- )
-- 	local toRemove = {} -- Store objects to be removed

-- 	-- Iterate over each cell in the grid
-- 	for key, cell in pairs(self.grid) do
-- 		-- Extract cell coordinates from the key
-- 		local cellX, cellY = key:match("(-?%d+),(-?%d+)")
-- 		cellX, cellY = tonumber(cellX), tonumber(cellY)

-- 		-- 1. Check collisions within the same cell
-- 		for i = 1, #cell do
-- 			for j = i + 1, #cell do
-- 				if CheckCollision(cell[i], cell[j]) then
-- 					toRemove[cell[i]] = true
-- 					toRemove[cell[j]] = true
-- 				end
-- 			end
-- 		end

-- 		-- 2. Check collisions with neighboring cells
-- 		-- Only check neighbors in one direction to avoid duplicate checks.
-- 		-- We'll check cells to the right (dx = 1, dy = 0), top-right (dx = 1, dy = -1),
-- 		-- and below (dx = 0, dy = 1), and bottom-right (dx = 1, dy = 1)
-- 		local neighborOffsets = {
-- 			{ dx = 1, dy = 0 },
-- 			{ dx = 1, dy = -1 },
-- 			{ dx = 0, dy = 1 },
-- 			{ dx = 1, dy = 1 },
-- 		}
-- 		for _, offset in ipairs(neighborOffsets) do
-- 			local neighborKey = (cellX + offset.dx) .. "," .. (cellY + offset.dy)
-- 			local neighbor = self.grid[neighborKey]
-- 			if neighbor then
-- 				for _, obj1 in ipairs(cell) do
-- 					for _, obj2 in ipairs(neighbor) do
-- 						if CheckCollision(obj1, obj2) then
-- 							toRemove[obj1] = true
-- 							toRemove[obj2] = true
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end

-- 	-- Check for objects going out of bounds
-- 	for _, enemy in ipairs(enemies) do
-- 		if enemy:isOutOfBounds(screenWidth, screenHeight) then
-- 			enemy:destroy(enemies, activeExplosions, particleSystem, shakeCamera, false)
-- 		end
-- 	end

-- 	for _, projectile in ipairs(projectiles) do
-- 		if projectile:isOutOfBounds(screenWidth, screenHeight) then
-- 			projectile:destroy(projectiles, activeExplosions, particleSystem, shakeCamera, false)
-- 		end
-- 	end

-- 	-- Remove marked enemies
-- 	for i = #enemies, 1, -1 do
-- 		if toRemove[enemies[i]] then
-- 			enemies[i]:destroy(enemies, activeExplosions, particleSystem, shakeCamera, true)
-- 		end
-- 	end

-- 	-- Remove marked projectiles
-- 	for i = #projectiles, 1, -1 do
-- 		if toRemove[projectiles[i]] then
-- 			projectiles[i]:destroy(projectiles, activeExplosions, particleSystem, shakeCamera, true)
-- 		end
-- 	end
-- end

-- return Grid

local CheckCollision = require("helpers.collisions")

local Grid = {
	grid = {},
	cellSize = 50,
}

-- Returns a string key for the grid cell based on object position
function Grid:getCellKey(x, y)
	local cellX = math.floor(x / self.cellSize)
	local cellY = math.floor(y / self.cellSize)
	return cellX .. "," .. cellY
end

-- Build the grid from the enemies and projectiles lists
function Grid:updateGrid(enemies, projectiles)
	self.grid = {} -- Clear grid

	local function addToGrid(obj)
		local key = self:getCellKey(obj.x, obj.y)
		if not self.grid[key] then
			self.grid[key] = {}
		end
		table.insert(self.grid[key], obj)
	end

	for _, enemy in ipairs(enemies) do
		addToGrid(enemy)
	end

	for _, projectile in ipairs(projectiles) do
		addToGrid(projectile)
	end
end

-- Check collisions and out-of-bounds objects and remove them accordingly
function Grid:checkCollisions(
	enemies,
	projectiles,
	activeExplosions,
	particleSystem,
	screenWidth,
	screenHeight,
	shakeCamera,
	score
)
	local toRemove = {} -- Table to mark objects for removal

	-- Iterate over each cell in the grid
	for key, cell in pairs(self.grid) do
		-- Check collisions within the same cell
		for i = 1, #cell do
			for j = i + 1, #cell do
				if CheckCollision(cell[i], cell[j]) then
					toRemove[cell[i]] = true
					toRemove[cell[j]] = true
				end
			end
		end

		-- Determine neighbor cell keys to check (right, top-right, bottom-right, and below)
		local cellX, cellY = key:match("(-?%d+),(-?%d+)")
		cellX, cellY = tonumber(cellX), tonumber(cellY)
		local neighborKeys = {
			(cellX + 1) .. "," .. cellY,
			(cellX + 1) .. "," .. (cellY - 1),
			(cellX + 1) .. "," .. (cellY + 1),
			cellX .. "," .. (cellY + 1),
		}

		for _, nKey in ipairs(neighborKeys) do
			local neighbor = self.grid[nKey]
			if neighbor then
				for _, obj1 in ipairs(cell) do
					for _, obj2 in ipairs(neighbor) do
						if CheckCollision(obj1, obj2) then
							toRemove[obj1] = true
							toRemove[obj2] = true
						end
					end
				end
			end
		end
	end

	-- Remove objects that have gone out-of-bounds
	for i = #enemies, 1, -1 do
		if enemies[i]:isOutOfBounds(screenWidth, screenHeight) then
			enemies[i]:destroy(enemies, activeExplosions, particleSystem, shakeCamera, false)
		end
	end

	for i = #projectiles, 1, -1 do
		if projectiles[i]:isOutOfBounds(screenWidth, screenHeight) then
			projectiles[i]:destroy(projectiles, activeExplosions, particleSystem, shakeCamera, false)
		end
	end

	-- Remove objects marked for collision
	for i = #enemies, 1, -1 do
		if toRemove[enemies[i]] then
			enemies[i]:destroy(enemies, activeExplosions, particleSystem, shakeCamera, true)
		end
	end

	for i = #projectiles, 1, -1 do
		if toRemove[projectiles[i]] then
			projectiles[i]:destroy(projectiles, activeExplosions, particleSystem, shakeCamera, true)
			score()
		end
	end
end

return Grid
