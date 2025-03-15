local CheckCollision = require("helpers.collisions")

local Grid = {
	grid = {},
	cellSize = 75, -- You might adjust this based on your object sizes
}

Grid.__index = Grid

function Grid:init()
	local instance = setmetatable({}, Grid)
	return instance
end

-- Returns a string key for the grid cell based on an object's center coordinates.
function Grid:getCellKey(x, y)
	local cellX = math.floor(x / self.cellSize)
	local cellY = math.floor(y / self.cellSize)
	return cellX .. "," .. cellY
end

-- Build the grid from the enemies and projectiles lists.
-- We assume that each object's .x and .y represent its center.
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

-- Check collisions (using our CheckCollision function) among objects
-- in each cell and in a few neighboring cells.
-- Then, remove any objects that are either colliding or out-of-bounds.
function Grid:checkCollisions(
	enemies,
	projectiles,
	activeExplosions,
	particleSystem,
	screenWidth,
	screenHeight,
	shakeCamera,
	scoreCallback
)
	local toRemove = {} -- Table to mark objects for removal

	-- Iterate over each cell in the grid.
	for key, cell in pairs(self.grid) do
		-- Check collisions within the same cell.
		for i = 1, #cell do
			for j = i + 1, #cell do
				if CheckCollision(cell[i], cell[j]) then
					toRemove[cell[i]] = true
					toRemove[cell[j]] = true
				end
			end
		end

		-- Determine neighbor cell keys to check: right, top-right, bottom-right, and below.
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

	-- Remove objects that have gone out-of-bounds.
	for i = #enemies, 1, -1 do
		if enemies[i].isSpecial then
			enemies[i]:isCollidingWithWall(screenWidth, screenHeight)
		end

		if enemies[i]:isOutOfBounds(screenWidth, screenHeight) then
			enemies[i]:destroy(enemies, activeExplosions, particleSystem, shakeCamera, false)
		end
	end

	for i = #projectiles, 1, -1 do
		if projectiles[i]:isOutOfBounds(screenWidth, screenHeight) then
			projectiles[i]:destroy(projectiles, activeExplosions, particleSystem, shakeCamera, false)
		end
	end

	-- Remove objects marked for collision.
	for i = #enemies, 1, -1 do
		if toRemove[enemies[i]] then
			enemies[i]:destroy(enemies, activeExplosions, particleSystem, shakeCamera, true)
		end
	end

	for i = #projectiles, 1, -1 do
		if toRemove[projectiles[i]] then
			projectiles[i]:destroy(projectiles, activeExplosions, particleSystem, shakeCamera, true)
			scoreCallback()
		end
	end
end

function Grid:draw()
	-- Draw the grid
	love.graphics.setColor(0.3, 0.3, 0.3, 0.5) -- Grey color for grid lines
	for key, _ in pairs(self.grid) do
		local cellX, cellY = key:match("(-?%d+),(-?%d+)")
		cellX, cellY = tonumber(cellX), tonumber(cellY)
		local x, y = cellX * self.cellSize, cellY * self.cellSize

		-- Draw the cell boundary
		love.graphics.rectangle("line", x, y, self.cellSize, self.cellSize)

		-- Draw the cell coordinates
		love.graphics.setColor(1, 1, 1) -- White text
		love.graphics.print(key, x + 5, y + 5)
	end

	-- Draw enemies and projectiles
	for key, cell in pairs(self.grid) do
		for _, obj in ipairs(cell) do
			if obj.type == "enemy" then
				love.graphics.setColor(1, 0, 0) -- Red for enemies
			elseif obj.type == "projectile" then
				love.graphics.setColor(0, 0, 1) -- Blue for projectiles
			else
				love.graphics.setColor(1, 1, 1) -- Default white
			end
			love.graphics.circle("fill", obj.x, obj.y, 5) -- Draw object as a small circle
		end
	end
end

return Grid
