local BgMusic = {
	tracks = {},
	currentTrackIndex = 1,
}

function BgMusic:init()
	self.tracks = {
		love.audio.newSource("res/audio/bg/track_23.ogg", "stream"),
		-- love.audio.newSource("res/audio/bg/track_22.ogg", "stream"),
		love.audio.newSource("res/audio/bg/track_21.ogg", "stream"),
	}

	self.tracks[self.currentTrackIndex]:play() -- Start playing
end

function BgMusic:update()
	local currentTrack = self.tracks[self.currentTrackIndex]

	if not currentTrack:isPlaying() then
		-- Move to the next track (loop back to first if at the end)
		self.currentTrackIndex = (self.currentTrackIndex % #self.tracks) + 1
		self.tracks[self.currentTrackIndex]:play()
	end
end

return BgMusic
