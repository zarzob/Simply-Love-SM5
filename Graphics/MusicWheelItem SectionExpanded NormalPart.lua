local num_items = THEME:GetMetric("MusicWheel", "NumWheelItems")
-- subtract 2 from the total number of MusicWheelItems
-- one MusicWheelItem will be offsceen above, one will be offscreen below
local num_visible_items = num_items - 2

local item_width = _screen.w / 2.125

local af = Def.ActorFrame{
	-- the MusicWheel is centered via metrics under [ScreenSelectMusic]; offset by a slight amount to the right here
	InitCommand=function(self) self:x(WideScale(28,33)) end,
	Def.Quad{
		InitCommand=function(self) 
			self:horizalign(left):diffuse(color("#000000")):zoomto(item_width, _screen.h/num_visible_items)
			if ThemePrefs.Get("VisualStyle") == "Technique" or ThemePrefs.Get("VisualStyle") == "Transistor" then
				self:diffusealpha(0.5)
			end
		end
	},
	Def.Quad{
		InitCommand=function(self) 
			self:horizalign(left):diffuse(color("#4c565d")):zoomto(item_width, _screen.h/num_visible_items - 1)
			if ThemePrefs.Get("VisualStyle") == "Technique" or ThemePrefs.Get("VisualStyle") == "Transistor" then
				self:diffusealpha(0.5)
			end
		end
	}
}

if ThemePrefs.Get("SongSelectBG") ~= "Off" then
	af[#af+1] = Def.Banner{
		InitCommand=function(self)
			self:horizalign(left):zoom(0.5):scaletoclipped(item_width, _screen.h/num_visible_items):visible(true)
			self:diffusealpha(0.5):fadeleft(0.1):SetDecodeMovie(false)
		end,
		SetCommand=function(self, params)
			group = params.Text
			if group then
				self:LoadFromSongGroup(group):visible(true)
			else
				self:visible(false)
			end
		end,
	}
end

return af


-- Folder Lamps

-- local players = GAMESTATE:GetHumanPlayers()

-- local num_tiers = THEME:GetMetric("PlayerStageStats", "NumGradeTiersUsed")
-- local grades = {}
-- for i=1,num_tiers do
	-- grades[ ("Grade_Tier%02d"):format(i) ] = i-1
-- end
-- -- assign the "Grade_Failed" key a value equal to num_tiers
-- grades["Grade_Failed"] = num_tiers


-- for player in ivalues(players) do
	-- local pn = ToEnumShortString(player)
	-- af[#af+1] = Def.Sprite {
		-- Texture=THEME:GetPathG("MusicWheelItem","Grades/grades 1x18.png"),
		-- InitCommand=function(self) 
			-- self:zoom( SL_WideScale(0.18, 0.3) ):animate(false) 
			-- self:x(5)
			-- self:horizalign("left")
			-- self:visible(false)
		-- end,
		-- SetMessageCommand=function(self,params)
						-- -- Set blank first
						-- self:visible(false)
			-- local wheeltype = self:GetParent():GetParent():GetParent():GetSelectedType()
			-- if wheeltype == "WheelItemDataType_Section" then
				-- self:queuecommand("SetFolder")
			-- end
		-- end,
		-- --SetCommand=function(self,params)
		-- --				-- Set blank first
		-- --				self:visible(false)
		-- --	local wheeltype = self:GetParent():GetParent():GetParent():GetSelectedType()
		-- --	if wheeltype == "WheelItemDataType_Section" then
		-- --		self:queuecommand("SetFolder")
		-- --	end
		-- --end,
		-- SetFolderCommand=function(self,params)
			-- -- Get all songs in group
			-- local group = self:GetParent():GetParent():GetText()
			-- --SM(group)
			-- local songs = SONGMAN:GetSongsInGroup(group)
			-- local stepstype = GAMESTATE:GetCurrentStyle():GetStepsType()
			-- -- use steps for current selected difficulty.
			-- -- steps will be whatever was selected last if scrolling over a folder
			-- local steps = GAMESTATE:GetCurrentSteps(player)
			-- if steps then
				-- -- Get profile and current difficulty
				-- local profile = PROFILEMAN:GetProfile(pn)
				-- local difficulty = steps:GetDifficulty()
				-- local allsongspassed = true
				-- --SM("Difficulty " .. difficulty)
				-- local worstgrade = 0
				-- for song in ivalues(songs) do
					-- --SM("- " ..song:GetDisplayFullTitle())
					-- if allsongspassed == true then 
						-- local allsteps = song:GetAllSteps()
						-- for songsteps in ivalues(allsteps) do
							-- -- Check if the song has a chart for the current difficulty
							-- local stepsdiff = songsteps:GetDifficulty()
							-- if difficulty == stepsdiff then
								-- -- Check if the player has passed this song
								-- HighScoreList = profile:GetHighScoreListIfExists(song,songsteps)	
								-- if HighScoreList ~= nil then 
									-- HighScores = HighScoreList:GetHighScores()
									-- -- Get highest score
									-- if #HighScores > 0 then
										-- local grade = HighScores[1]:GetGrade()
										-- grade = grades[grade]
										-- if grade > worstgrade then 
											-- worstgrade = grade
											-- self:visible(true):setstate(worstgrade) 
										-- end
									-- else
										-- self:visible(false)
										-- allsongspassed = false
									-- end
								-- end																
							-- end
						-- end
					-- else
						-- self:visible(false)
					-- end
				-- end			
			-- end	


		-- end,
		-- ["CurrentSteps"..pn.."ChangedMessageCommand"] = function(self)
			-- self:queuecommand("SetFolder")
		-- end
	-- }
-- end
