local BgMusic = {
	tracks = {},
	menuTracks = {},
	currentTrackIndex = 1,
	isMenu = false, -- Always starts in game mode
	isMuted = false,
}

BgMusic.__index = BgMusic

function BgMusic:init()
	local instance = setmetatable({}, BgMusic)

	instance.tracks = {
		love.audio.newSource("res/audio/bg/orbital_colossus.mp3", "stream"),
		love.audio.newSource("res/audio/bg/track_23.ogg", "stream"),
	}

	instance.menuTracks = {
		love.audio.newSource("res/audio/menu/track_21.ogg", "stream"),
	}

	return instance
end

function BgMusic:update()
	local trackList = self.isMenu and self.menuTracks or self.tracks
	local currentTrack = trackList[self.currentTrackIndex]

	if not GameSettings.isBgMuted then
		if not currentTrack:isPlaying() then
			-- Move to the next track (loop back to first if at the end)
			self.currentTrackIndex = (self.currentTrackIndex % #trackList) + 1
			trackList[self.currentTrackIndex]:play()
		end
	else
		self:stop()
	end
end

function BgMusic:stop()
	local trackList = self.isMenu and self.menuTracks or self.tracks
	local currentTrack = trackList[self.currentTrackIndex]
	if currentTrack:isPlaying() then
		currentTrack:stop()
	end
end

function BgMusic:reset()
	self:stop() -- Stop any currently playing track

	self.isMenu = false -- Ensure it resets to game tracks
	self.currentTrackIndex = 1
	local trackList = self.tracks -- Always reset to game tracks

	if #trackList > 0 then
		if not self.isMuted then
			trackList[self.currentTrackIndex]:play()
		end
	end
end

function BgMusic:switchTracks()
	self:stop() -- Stop current track before switching

	self.isMenu = not self.isMenu -- Toggle between menu and game tracks
	self.currentTrackIndex = 1
	local trackList = self.isMenu and self.menuTracks or self.tracks

	if #trackList > 0 then
		if not self.isMuted then
			trackList[self.currentTrackIndex]:play()
		end
	end
end

return BgMusic
