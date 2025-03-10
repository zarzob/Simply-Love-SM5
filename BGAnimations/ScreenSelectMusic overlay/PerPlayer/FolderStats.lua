-- No folders in course mode to get stats
if GAMESTATE:IsCourseMode() then return end

-- Don't show folder stats if disabled in operator menu
if not ThemePrefs.Get("FolderStats") then return end

local player = ...
local pn = ToEnumShortString(player)

local IsNotWide = (GetScreenAspectRatio() < 16/9)

local currentFolder = ""
local currentDifficulty = ""	

local af = Def.ActorFrame{
	InitCommand=function(self)
		self:y(_screen.cy*0.3)
		if #GAMESTATE:GetHumanPlayers() > 1 and player == PLAYER_1 then 
			self:x(_screen.cx*1.305)
		else
			self:x(_screen.cx*1.77)
		end
	end,
	CurrentSongChangedMessageCommand=function(self)
		self:queuecommand("BuildSongLampArray")
	end,
	["CurrentSteps"..pn.."ChangedMessageCommand"]=function(self)
		self:queuecommand("BuildSongLampArray")
	end,
	PlayerJoinedMessageCommand=function(self, params)
		if #GAMESTATE:GetHumanPlayers() > 1 and player == PLAYER_1 then 
			self:x(_screen.cx*1.305)
		else
			self:x(_screen.cx*1.77)
		end
		if params.Player == player then
			self:visible(true)
		end
	end,
	PlayerUnjoinedMessageCommand=function(self, params)
		self:x(_screen.cx*1.77)
		if params.Player == player then
			self:visible(false)
		end
	end
}

local num_tiers = THEME:GetMetric("PlayerStageStats", "NumGradeTiersUsed")
local grades = {}
for i=1,num_tiers do
	grades[ ("Grade_Tier%02d"):format(i) ] = i-1
end
local columnWidth = IsNotWide and 62 or 80

-- assign the "Grade_Failed" key a value equal to num_tiers
grades["Grade_Failed"] = num_tiers

difficultyNames = {
	Difficulty_Beginner = "Beginner",
	Difficulty_Easy = "Easy",
	Difficulty_Medium = "Medium",
	Difficulty_Hard = "Hard",
	Difficulty_Challenge = "Expert",
	Difficulty_Edit = "Edit"

}

af2 = Def.ActorFrame {
	InitCommand=function(self)
		self:zoom(0.45)
	end
}

af2.BuildSongLampArrayCommand=function(self)
	if SCREENMAN:GetTopScreen():GetName() == "ScreenSelectMusic" then
		local profile = PROFILEMAN:GetProfile(player)
		local profileName = profile:GetDisplayName()
		if (not GAMESTATE:IsPlayerEnabled(player)) or profileName == "" or GAMESTATE:GetSortOrder() ~= 'SortOrder_Group' then 
			self:visible(false)
		else
			self:visible(true)
			local scores = {
				Grade_Tier00 = 0,
				Grade_Tier01 = 0,
				Grade_Tier02 = 0,
				Grade_Tier03 = 0,
				Grade_Tier04 = 0,
				Passes = 0
			}
			local countSongs = 0
			local folderName = SCREENMAN:GetTopScreen():GetMusicWheel():GetSelectedSection()
			local songs = SONGMAN:GetSongsInGroup(folderName)
			local stepstype = GAMESTATE:GetCurrentStyle():GetStepsType()
			local steps = GAMESTATE:GetCurrentSteps(player)
			if steps then
				local difficulty = steps:GetDifficulty()
				-- Get profile and current difficulty
				if folderName ~= currentFolder or difficulty ~= currentDifficulty then
					currentFolder = folderName
					currentDifficulty = difficulty
					for song in ivalues(songs) do
						local allsteps = song:GetAllSteps()
						for songsteps in ivalues(allsteps) do
							local stepsdiff = songsteps:GetDifficulty()
							if difficulty == stepsdiff and stepstype == songsteps:GetStepsType() then
								countSongs = countSongs + 1
								HighScoreList = profile:GetHighScoreListIfExists(song,songsteps)
								if HighScoreList ~= nil then 
									HighScores = HighScoreList:GetHighScores()
									-- Get highest score
									if #HighScores > 0 then
										local grade = HighScores[1]:GetGrade()
										if grade ~= "Grade_Failed" then
											scores["Passes"] = scores["Passes"] + 1
											if grades[grade] < 4 then
												if grade == "Grade_Tier01" and HighScores[1]:GetScore() == 0 then
													scores["Grade_Tier00"] = scores["Grade_Tier00"] + 1
												else
													scores[grade] = scores[grade] + 1
												end
											end
										end
									end
								end
							end
						end
					end
					local bestGrade = 0
					if scores["Grade_Tier00"] > 0 then bestGrade = 5
					else
						for i=1,4 do
							if scores["Grade_Tier0"..i] > 0 then
								bestGrade = 5 - i
								break
							end
						end
					end
					columnWidth = IsNotWide and (310/bestGrade) or (400/bestGrade)
					self:playcommand("FolderSummary", {folderName=folderName, profileName=profileName, countSongs=countSongs, scores=scores, difficulty=difficulty, bestGrade=bestGrade })
				end
			else
				self:visible(false)
			end
		end
	end
end

-- Banner size
local height = IsNotWide and 314 or 418
local width = IsNotWide and 123 or 164

local style = ThemePrefs.Get("VisualStyle")
local colorTable = (style == "SRPG6") and SL.SRPG6.Colors or SL.DecorativeColors

-- Border Quad
af2[#af2+1] = Def.Quad {
	InitCommand=function(self)
		self:zoomto(height+2,width+2)
		self:diffuse(color(colorTable[SL.Global.ActiveColorIndex]))
	end
}

-- Background Quad, this is used for transparent backgrounds like Bangers Only 1
af2[#af2+1] = Def.Quad {
	InitCommand=function(self)
		self:zoomto(height,width):diffuse(Color.Black)
	end
}

-- Banner
af2[#af2+1] = Def.Banner{
	FolderSummaryCommand=function(self, params)
		self:LoadFromSongGroup(params.folderName)
		self:setsize(height,width)
	end
}

-- Transparent quad over the banner
af2[#af2+1] = Def.Quad {
	InitCommand=function(self)
		self:zoomto(height,width):diffuse(Color.Black):diffusealpha(0.8)
	end
}

-- Folder name
af2[#af2+1] = LoadFont(ThemePrefs.Get("ThemeFont") .. " Normal")..{
	Name="Folder",
	Text="",
	FolderSummaryCommand=function(self,params)
		self:settext(params.folderName)
		self:y(-60)
		self:zoom(2)
		self:maxwidth(200)
		
		if IsNotWide then
			self:zoom(1.5)
			self:y(-50)
		end
	end
}

-- Profile name
af2[#af2+1] = LoadFont(ThemePrefs.Get("ThemeFont") .. " Normal")..{
	Name="ProfileName",
	Text="",
	FolderSummaryCommand=function(self,params)
		self:settext(params.profileName)
		self:y(-20)
		self:zoom(2)
		self:maxwidth(200)
		if IsNotWide then
			self:zoom(1.5)
		end
	end
}

-- Total Song Count
af2[#af2+1] = LoadFont(ThemePrefs.Get("ThemeFont") .. " Normal")..{
	Name="TotalSongs",
	Text="",
	FolderSummaryCommand=function(self,params)
		local text = "Total " .. difficultyNames[params.difficulty] .. ": " .. params.scores["Passes"] .. "/" .. params.countSongs
		self:settext(text)
		self:y(15)
		self:zoom(1.25)
		if IsNotWide then
			self:zoom(0.94)
		end
	end
}

-- Grades and grade count
af2[#af2+1] = LoadFont(ThemePrefs.Get("ThemeFont") .. " Normal")..{
	Name="Grade0",
	Text="",
	FolderSummaryCommand=function(self,params)
		if params.scores["Grade_Tier00"] == 0 then
			self:visible(false)
			return
		end
		self:visible(true)
		local text = params.scores["Grade_Tier00"]
		self:settext(text)
		self:x(-220+columnWidth)
		self:y(52)
		self:zoom(1.4)
		if IsNotWide then
			self:zoom(1.05)
			self:x(-170+columnWidth)
			self:y(45)
		end
	end
}
af2[#af2+1] = Def.Sprite{
	Texture=THEME:GetPathG("MusicWheelItem","Grades/quint.png"),
	InitCommand=function(self) self:zoom( SL_WideScale(0.18, 0.3) ):animate(false) end,
	FolderSummaryCommand=function(self, params)
		if params.bestGrade < 5 then
			self:visible(false)
			return
		end
		self:visible(true)
		self:x(-260+columnWidth)
		self:y(52)
		self:zoom(0.5)
		if IsNotWide then
			self:zoom(0.38)
			self:x(-200+columnWidth)
			self:y(45)
		end
	end
}
for i=1,4 do
	af2[#af2+1] = LoadFont(ThemePrefs.Get("ThemeFont") .. " Normal")..{
		Name="Grade" ..i,
		Text="",
		FolderSummaryCommand=function(self,params)
			if params.bestGrade < 5-i then
				self:visible(false)
				return
			end
			self:visible(true)
			local text = params.scores["Grade_Tier0"..i]
			self:settext(text)
			self:x(-(columnWidth*params.bestGrade/2)+20+columnWidth*(i-(5-params.bestGrade)+0.5))
			self:y(52)
			self:zoom(1.4)
			if IsNotWide then
				self:zoom(1.05)
				self:x(-(columnWidth*params.bestGrade/2)+15+columnWidth*(i-(5-params.bestGrade)+0.5))
				self:y(45)
			end
		end
	}
	af2[#af2+1] = Def.Sprite{
		Texture=THEME:GetPathG("MusicWheelItem","Grades/grades 1x18.png"),
		InitCommand=function(self) self:zoom( SL_WideScale(0.18, 0.3) ):animate(false) end,
		FolderSummaryCommand=function(self, params)
			if params.bestGrade < 5-i then
				self:visible(false)
				return
			end
			self:visible(true)
			self:setstate(grades["Grade_Tier0"..i])
			self:x(-(columnWidth*params.bestGrade/2)-20+columnWidth*(i-(5-params.bestGrade)+0.5))
			self:y(52)
			self:zoom(0.5)
			if IsNotWide then
				self:zoom(0.38)
				self:x(-(columnWidth*params.bestGrade/2)-15+columnWidth*(i-(5-params.bestGrade)+0.5))
				self:y(45)
			end
		end
	}
end

af[#af+1] = af2

return af