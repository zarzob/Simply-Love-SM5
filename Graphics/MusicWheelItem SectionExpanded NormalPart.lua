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
	},
	Def.BitmapText {
		Font=ThemePrefs.Get("ThemeFont") .. " Normal",
		InitCommand=function(self)
			self:halign(0):xy(41,0):maxwidth(WideScale(210,310))
		end,
		SetCommand=function(self, params)
			self:settext(params.Text):diffuse(params.Color)
			DiffuseEmojis(self)
		end,
	},
	Def.BitmapText {
		Font=ThemePrefs.Get("ThemeFont") .. " Normal",
		InitCommand=function(self)
			self:halign(1):xy(_screen.w/2 - WideScale(37, 43),0):zoom(0.75)
		end,
		SetCommand=function(self, params)
			if (not params.Song or params.Course) then
				local count = #SONGMAN:GetSongsInGroup(params.Text) or 0
				self:settext((ThemePrefs.Get("nice")>0 and count==69) and "nice" or count)
			else
				self:settext("")
			end
		end,
	},
	Def.ActorFrame{
		Name="FolderStack",
		InitCommand=function(self)
			self:x(-3)
		end,
		SetCommand=function(self, params)
			local is_parent = params and params.IsParentSection
			self:GetChild("FolderBack"):visible(is_parent)
			self:GetChild("FolderFront"):visible(is_parent)
			self:GetChild("FolderMid"):visible(true)
			if not is_parent then
				self:GetChild("FolderMid"):diffuse(params.Color)
			else
				self:GetChild("FolderMid"):diffuse(color("#677f91"))
			end
			local has_parent = params.ParentSection and params.ParentSection ~= ""
			if (not is_parent and has_parent) then
				self:x(8)
			else
				self:x(-3)
			end
		end,

		Def.Sprite{
			Name="FolderBack",
			Texture=THEME:GetPathG("", "folder-solid.png"),
			InitCommand=function(self)
				self:horizalign(left):zoom(0.175)
				self:x(-4 + self:GetWidth()*self:GetZoom() - 8, -4)
				self:diffuse(color("#516777"))
			end
		},
		Def.Sprite{
			Name="FolderMid",
			Texture=THEME:GetPathG("", "folder-solid.png"),
			InitCommand=function(self)
				self:horizalign(left):zoom(0.175)
				self:xy( 0 + self:GetWidth()*self:GetZoom() - 8, 1 )
			end,
		},
		Def.Sprite{
			Name="FolderFront",
			Texture=THEME:GetPathG("", "folder-solid.png"),
			InitCommand=function(self)
				self:horizalign(left):zoom(0.175)
				self:xy( 4 + self:GetWidth()*self:GetZoom() - 8, 2)
				self:diffuse(color("#7793a7"))
			end
		},
	},
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
