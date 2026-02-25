local player = ...
local pn = ToEnumShortString(player)

if (not SL[pn].ActiveModifiers.DisplayScorebox or
		not IsServiceAllowed(SL.GrooveStats.GetScores) or
		SL[pn].ApiKey == "") then
	return
end

local n = player==PLAYER_1 and "1" or "2"
local IsUltraWide = (GetScreenAspectRatio() > 21/9)
local NoteFieldIsCentered = (GetNotefieldX(player) == _screen.cx)
local NumEntries = 7

local style = GAMESTATE:GetCurrentStyle():GetName()

local border = 5
local width = 162
local height = 80

-- Rows/spacing/zoom per style: GS/events use 5 rows; Arrow Cloud uses 7 rows
local GS_ROWS = 5
local AC_ROWS = 7
local function RowsForStyle(style)
	return (style >= 4) and AC_ROWS or GS_ROWS
end
local function RowSpacingForStyle(style)
	return height / RowsForStyle(style)
end
local function TextZoomForStyle(style)
	return (style >= 4) and 0.75 or 0.87
end
local function CrownZoomForStyle(style)
	return (style >= 4) and 0.075 or 0.09
end

local cur_style = 0
local num_styles = 7

local GrooveStatsBlue = color("#007b85")
local RpgYellow = color("1,0.972,0.792,1")
local ItlPink = color("1,0.2,0.406,1")
local BoogieStatsPurple = color("#8000ff")

local style_color = {
	[0] = GrooveStatsBlue,  -- Either GrooveStats or GrooveStats EX score
	[1] = GrooveStatsBlue,  -- Either GrooveStats or GrooveStats EX score
	[2] = RpgYellow,
	[3] = ItlPink,
	[4] = SL.JudgmentColors["FA+"][2], -- AC ITG
	[5] = SL.JudgmentColors["FA+"][1], -- AC EX
	[6] = SL.JudgmentColors["FA+"][7], -- AC HardEX
}

local self_color = color("#a1ff94")
local rival_color = color("#c29cff")

local loop_seconds = 5
local transition_seconds = 1

local all_data = {}

local ResetAllData = function()
	SL[pn].Rival = {}
	SL[pn].Rival.Score = 0
	SL[pn].Rival.ExScore = 0
	SL[pn].Rival.WRScore = 0
	SL[pn].Rival.WRExScore = 0
	
	for i=1,num_styles do
		local data = {
			["has_data"]=false,
			["scores"]={}
		}
		local scores = data["scores"]
		for i=1,NumEntries do
			scores[#scores+1] = {
				["rank"]="",
				["name"]="",
				["score"]="",
				["isSelf"]=false,
				["isRival"]=false,
				["isFail"]=false,
				["isEx"]=false,
			}
		end
		all_data[#all_data + 1] = data
	end
end
-- Initialize the all_data object.
ResetAllData()

-- Checks to see if any data is available.
local HasData = function(idx)
	return all_data[idx+1] and all_data[idx+1].has_data
end

local SetScoreData = function(data_idx, score_idx, rank, name, score, isSelf, isRival, isFail, isEx)
	if score_idx > NumEntries then return end
	all_data[data_idx].has_data = true

	local score_data = all_data[data_idx]["scores"][score_idx]
	score_data.rank = rank..((#rank > 0) and "." or "")
	score_data.name = name
	score_data.score = score
	score_data.isSelf = isSelf
	score_data.isRival = isRival
	score_data.isFail = isFail
	score_data.isEx = isEx
	
	if not isFail and (isRival or isSelf) then
		if data_idx == 3 then
			if tonumber(score) > SL[pn].Rival.ExScore then
				SL[pn].Rival.ExScore = tonumber(score)
			end
		else
			if tonumber(score) > SL[pn].Rival.Score then
				SL[pn].Rival.Score = tonumber(score)
			end
		end
	end
	
	if score_data.rank == 1 then
		if data_idx == 3 then
			SL[pn].Rival.WRExScore = tonumber(score)
		else
			if tonumber(score) > SL[pn].Rival.WRScore then
				SL[pn].Rival.WRScore = tonumber(score)
			end
		end
	end
end

-- ArrowCloud integration (gameplay) --------------------------------------
-- Temporary restriction: only enable Arrow Cloud behavior for packs containing "Blue Shift".
local function ShouldAllowArrowCloudForCurrentPack()
	local song = GAMESTATE:GetCurrentSong()
	if not song then return false end
	local group = song:GetGroupName() or ""
	return string.find(string.lower(group), "blue shift", 1, true) ~= nil
end

local ArrowCloudRequestProcessor = function(res)
	-- Expect res.statusCode and res.body (raw JSON string)
	if not res then return end
	if res.statusCode ~= 200 then return end
	if not res.body then return end
	local ok, parsed = pcall(JsonDecode, res.body)
	if not ok or type(parsed) ~= "table" then return end
	if type(parsed.leaderboards) ~= "table" then return end

	-- Our arrays are 1-based in all_data, but cur_style is 0-based; we use indices 4..6 as 0-based,
	-- which correspond to all_data[5..7]. Adjust when setting.
	for _, board in ipairs(parsed.leaderboards) do
		local zero_based = ({ ITG = 4, EX = 5, HardEX = 6 })[board.type]
		if zero_based ~= nil then
			local data_idx = zero_based + 1  -- 1-based for all_data
			if all_data[data_idx] then
				local isExType = (board.type == "EX" or board.type == "HardEX")
				local slot = 1
				local any = false
				if type(board.scores) == "table" then
					for _, entry in ipairs(board.scores) do
						if slot > NumEntries then break end
						any = true
						local rank = tostring(entry.rank or "")
						local name = tostring(entry.alias or "--")
						local score = tostring(entry.score or "")
						local isSelf = not not entry.isSelf
						local isRival = not not entry.isRival
						SetScoreData(data_idx, slot, rank, name, score, isSelf, isRival, false, isExType)
						slot = slot + 1
					end
				end
				if not any then
					-- Present but empty leaderboard -> show No Scores
					SetScoreData(data_idx, 1, "", "No Scores", "", false, false, false, isExType)
					slot = 2
				end
				for i=slot, NumEntries do
					SetScoreData(data_idx, i, "", "", "", false, false, false, isExType)
				end
			end
		end
	end
end

local LeaderboardRequestProcessor = function(res, master)
	if master == nil then return end

	if res.error or res.statusCode ~= 200 then
		local error = res.error and ToEnumShortString(res.error) or nil
		local text = ""
		if error == "Timeout" then
			text = "Timed Out"
		elseif error or (res.statusCode ~= nil and res.statusCode ~= 200) then
			text = "Failed to Load 😞"
		end
		SetScoreData(1, 1, "", text, "", false, false, false, false)
		if master ~= nil then
			master:queuecommand("CheckScorebox")
		end
		return
	end

	local playerStr = "player"..n
	local data = JsonDecode(res.body)

	-- BoogieStats integration
	-- Find out whether this chart is ranked on GrooveStats. 
	-- If it is unranked, alter groovestats logo and the box border color to the BoogieStats theme
	local headers = res.headers
	local boogie = false
	local boogie_ex = false
	if headers["bs-leaderboard-player-" .. n] == "BS" then
		boogie = true
	elseif headers["bs-leaderboard-player-" .. n] == "BS-EX" then
		boogie_ex = true
	end
	if not SCREENMAN:GetTopScreen():GetChild("Underlay") then return end
	local gsBox = SCREENMAN:GetTopScreen():GetChild("Underlay"):GetChild("StepStatsPane" .. pn):GetChild("BannerAndData"):GetChild("ScoreBox" .. pn)
	if boogie then
		style_color[0] = BoogieStatsPurple
		style_color[1] = BoogieStatsPurple
		gsBox:queuecommand("BoogieStats")
	end

	-- First check to see if the leaderboard even exists.
	if data and data[playerStr] then
		-- These will get overwritten if we have any entries in the leaderboard below.
		SetScoreData(1, 1, "", "No Scores", "", false, false, false, false)
		SetScoreData(2, 1, "", "No Scores", "", false, false, false, false)
		
		all_data[1].has_data = false
		all_data[2].has_data = false
		
		local showITG = SL["P"..n].ActiveModifiers.SBITGScore
		local showEX = SL["P"..n].ActiveModifiers.SBExScore
		local showEvents = SL["P"..n].ActiveModifiers.SBEvents

		local numEntries = 0
		if SL["P"..n].ActiveModifiers.ShowExScore then
			-- If the player is using EX scoring, then we want to display the EX leaderboard first.
			if showEX then
				if data[playerStr]["exLeaderboard"] then
					local added = {}
					numEntries = 0
					for entry in ivalues(data[playerStr]["exLeaderboard"]) do
						if not added[entry["name"]] then
							added[entry["name"]] = true
							numEntries = numEntries + 1
							SetScoreData(1, numEntries,
											tostring(entry["rank"]),
											entry["name"],
											string.format("%.2f", entry["score"]/100),
											entry["isSelf"],
											entry["isRival"],
											entry["isFail"],
											true
										)
						end
					end
				end
			end

			if showITG then
				if data[playerStr]["gsLeaderboard"] then
					local added = {}
					numEntries = 0
					for entry in ivalues(data[playerStr]["gsLeaderboard"]) do
						if not added[entry["name"]] then
							added[entry["name"]] = true
							numEntries = numEntries + 1
							SetScoreData(2, numEntries,
											tostring(entry["rank"]),
											entry["name"],
											string.format("%.2f", entry["score"]/100),
											entry["isSelf"],
											entry["isRival"],
											entry["isFail"],
											boogie_ex
										)
						end
					end
				end
			end
		else
			-- Display the main GrooveStats leaderboard first if player is not using EX scoring.
			if showITG then
				if data[playerStr]["gsLeaderboard"] then
					local added = {}
					numEntries = 0
					for entry in ivalues(data[playerStr]["gsLeaderboard"]) do
						if not added[entry["name"]] then
							added[entry["name"]] = true
							numEntries = numEntries + 1
							SetScoreData(1, numEntries,
											tostring(entry["rank"]),
											entry["name"],
											string.format("%.2f", entry["score"]/100),
											entry["isSelf"],
											entry["isRival"],
											entry["isFail"],
											boogie_ex
										)
						end
					end
					numEntries = numEntries + 1
					for i=math.max(2,numEntries),NumEntries,1 do
						SetScoreData(1, i, "", "", "", "", "", "", true)
					end
				end
			end

			if showEX then
				if data[playerStr]["exLeaderboard"] then
					local added = {}
					numEntries = 0
					for entry in ivalues(data[playerStr]["exLeaderboard"]) do
						if not added[entry["name"]] then
							added[entry["name"]] = true
							numEntries = numEntries + 1
							SetScoreData(2, numEntries,
											tostring(entry["rank"]),
											entry["name"],
											string.format("%.2f", entry["score"]/100),
											entry["isSelf"],
											entry["isRival"],
											entry["isFail"],
											true
										)
						end
					end
					numEntries = numEntries + 1
					for i=math.max(2,numEntries),NumEntries,1 do
						SetScoreData(2, i, "", "", "", "", "", "", true)
					end
				end
			end
		end

		-- Display event boxes first if they are applicable
		if showEvents then
			if data[playerStr]["rpg"] then
				cur_style = 3
				local numEntries = 0
				SetScoreData(3, 1, "", "No Scores", "", false, false, false)

				if data[playerStr]["rpg"]["rpgLeaderboard"] then
					local added = {}
					for entry in ivalues(data[playerStr]["rpg"]["rpgLeaderboard"]) do
						if not added[entry["name"]] then
							added[entry["name"]] = true
							numEntries = numEntries + 1
							SetScoreData(3, numEntries,
											tostring(entry["rank"]),
											entry["name"],
											string.format("%.2f", entry["score"]/100),
											entry["isSelf"],
											entry["isRival"],
											entry["isFail"],
											false
										)
						end
					end
					numEntries = numEntries + 1
					for i=math.max(2,numEntries),NumEntries,1 do
						SetScoreData(3, i, "", "", "", "", "", "", true)
					end
				end
			end

			if data[playerStr]["itl"] then
				cur_style = 4
				local numEntries = 0
				SetScoreData(4, 1, "", "No Scores", "", false, false, false)

				if data[playerStr]["itl"]["itlLeaderboard"] then
					local added = {}
					for entry in ivalues(data[playerStr]["itl"]["itlLeaderboard"]) do
						if not added[entry["name"]] then
							added[entry["name"]] = true
							numEntries = numEntries + 1
							SetScoreData(4, numEntries,
											tostring(entry["rank"]),
											entry["name"],
											string.format("%.2f", entry["score"]/100),
											entry["isSelf"],
											entry["isRival"],
											entry["isFail"],
											true
										)
						end
					end
					numEntries = numEntries + 1
					for i=math.max(2,numEntries),NumEntries,1 do
						SetScoreData(4, i, "", "", "", "", "", "", true)
					end
				end
			end
		end
 	end
	if master ~= nil then
		master:queuecommand("CheckScorebox")
	end
end

local af = Def.ActorFrame{
	Name="ScoreBox"..pn,
	InitCommand=function(self)
		if style ~= "double" then
			self:xy(70 * (player==PLAYER_1 and 1 or -1), -115)
			-- offset a bit more when NoteFieldIsCentered
			if NoteFieldIsCentered and IsUsingWideScreen() then
				self:addx( 2 * (player==PLAYER_1 and 1 or -1) )
			end

			-- ultrawide and both players joined
			if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
				self:x(self:GetX() * -1)
			end
		else
			self:xy(GetNotefieldWidth() - 140, -115)
		end
		
		self.isFirst = true
	end,
	CheckScoreboxCommand=function(self)
		self:queuecommand("LoopScorebox")
	end,
	LoopScoreboxCommand=function(self)
		if #all_data == 0 then return end

		local start = cur_style

		cur_style = (cur_style + 1) % num_styles
		if cur_style ~= start or self.isFirst then
			-- Make sure we have the next set of data.
			while cur_style ~= start do
				if HasData(cur_style) then
					-- If this is the first time we're looping, update the start variable
					-- since it may be different than the default
					if self.isFirst then
						start = cur_style
						self.isFirst = false
						-- Continue looping to figure out the next style.
					else
						break
					end
				end
				cur_style = (cur_style + 1) % num_styles
			end
		end

		-- Loop only if there's something new to loop to.
		if start ~= cur_style then
			self:sleep(loop_seconds):queuecommand("LoopScorebox")
		end
	end,

	RequestResponseActor(0, 0)..{
		OnCommand=function(self)
			self:queuecommand("MakeRequest")
		end,
		CurrentSongChangedMessageCommand=function(self)
				if not self.isFirst then
						ResetAllData()
						self:queuecommand("MakeRequest")
				end
		end,
		MakeRequestCommand=function(self)
			local sendRequest = false
			local headers = {}
			local query = {
				-- GS returns 5 rows; AC panes will render up to 7 independently
				maxLeaderboardResults=GS_ROWS,
			}

			if SL[pn].ApiKey ~= "" and SL[pn].Streams.Hash ~= "" then
				query["chartHashP"..n] = SL[pn].Streams.Hash
				headers["x-api-key-player-"..n] = SL[pn].ApiKey
				sendRequest = true
			end

			-- We technically will send two requests in ultrawide versus mode since
			-- both players will have their own individual scoreboxes.
			-- Should be fine though.
			-- ArrowCloud parallel request (independent of GS)
			local acEnabled = (SL.ArrowCloud and SL.ArrowCloud.Enabled) or false
			local acKey = (SL[pn] and SL[pn].ArrowCloudApiKey and #SL[pn].ArrowCloudApiKey > 0) or false
			local acHash = (SL[pn] and SL[pn].Streams and SL[pn].Streams.Hash and #SL[pn].Streams.Hash > 0) or false
			local willDoArrowCloud = acEnabled and acKey and acHash

			if willDoArrowCloud and ShouldAllowArrowCloudForCurrentPack() then
				local ach = SL[pn].Streams.Hash
				local acHeaders = { Authorization = "Bearer " .. SL[pn].ArrowCloudApiKey }
				NETWORK:HttpRequest{
					url = SL.ArrowCloud.BaseURL .. "/v1/chart/" .. ach .. "/leaderboards",
					method = "GET",
					headers = acHeaders,
					connectTimeout = SL.ArrowCloud.RequestTimeout,
					transferTimeout = SL.ArrowCloud.RequestTimeout,
					onResponse = function(acres)
						ArrowCloudRequestProcessor(acres)
						self:GetParent():queuecommand("CheckScorebox")
					end
				}
			end

			if sendRequest then
				-- Clear all rows; mark first as Loading
				for i=1,NumEntries do
					local nameActor = self:GetParent():GetChild("Name"..i)
					local scoreActor = self:GetParent():GetChild("Score"..i)
					local rankActor = self:GetParent():GetChild("Rank"..i)
					if nameActor then nameActor:settext(i==1 and "Loading..." or "") end
					if scoreActor then scoreActor:settext("") end
					if rankActor then
						if i==1 and rankActor.GetTexture then
							-- crown sprite: fade out
							rankActor:diffusealpha(0)
						else
							rankActor:settext("")
						end
					end
				end
				self:playcommand("MakeGrooveStatsRequest", {
					endpoint="player-leaderboards.php?"..NETWORK:EncodeQueryParameters(query),
					method="GET",
					headers=headers,
					timeout=10,
					callback=LeaderboardRequestProcessor,
					args=self:GetParent(),
				})
			end
		end
	},

	-- Outline
	Def.Quad{
		Name="Outline",
		InitCommand=function(self)
			self:diffuse(GrooveStatsBlue):setsize(width + border, height + border)
		end,
		LoopScoreboxCommand=function(self)
			self:linear(transition_seconds):diffuse(style_color[cur_style])
		end
	},
	-- Main body
	Def.Quad{
		Name="Background",
		InitCommand=function(self)
			self:diffuse(color("#000000")):setsize(width, height)
		end,
	},
	-- GrooveStats Logo
	Def.Sprite{
		Texture=THEME:GetPathG("", "GrooveStats.png"),
		Name="GrooveStatsLogo",
		InitCommand=function(self)
			self:zoom(0.8):diffusealpha(0.5)
		end,
		BoogieStatsCommand=function(self)
			self:Load(THEME:GetPathG("", "BoogieStats.png"))
		end,
		BoogieStatsEXCommand=function(self)
			self:Load(THEME:GetPathG("", "BoogieStatsEX.png"))
		end,
		LoopScoreboxCommand=function(self)
			if cur_style == 0 or cur_style == 1 then
				self:sleep(transition_seconds/2):linear(transition_seconds/2):diffusealpha(0.5)
			else
				self:linear(transition_seconds/2):diffusealpha(0)
			end
		end
	},
	-- EX Text
	Def.BitmapText{
		Font=ThemePrefs.Get("ThemeFont") .. " Normal",
		Text="EX",
		InitCommand=function(self)
			self:diffusealpha(0.3):x(2):y(-5)
		end,
		LoopScoreboxCommand=function(self)
			if (cur_style == 1 and not SL["P"..n].ActiveModifiers.ShowExScore) or (cur_style == 0 and SL["P"..n].ActiveModifiers.ShowExScore) then
				self:sleep(transition_seconds/2):linear(transition_seconds/2):diffusealpha(0.3)
			else
				self:linear(transition_seconds/2):diffusealpha(0)
			end
		end
	},
	-- SRPG Logo
	Def.Sprite{
		Texture=THEME:GetPathG("", "_VisualStyles/SRPG9/logo_alt (doubleres).png"),
		Name="SRPG9Logo",
		InitCommand=function(self)
			self:diffusealpha(0.4):zoom(0.07):diffusealpha(0)
		end,
		LoopScoreboxCommand=function(self)
			if cur_style == 2 then
				self:linear(transition_seconds/2):diffusealpha(0.5)
			else
				self:sleep(transition_seconds/2):linear(transition_seconds/2):diffusealpha(0)
			end
		end
	},
	-- ITL Logo
	Def.Sprite{
		Texture=THEME:GetPathG("", "ITL.png"),
		Name="ITLLogo",
		InitCommand=function(self)
			self:diffusealpha(0.2):zoom(0.45):diffusealpha(0)
		end,
		LoopScoreboxCommand=function(self)
			if cur_style == 3 then
				self:linear(transition_seconds/2):diffusealpha(0.2)
			else
				self:sleep(transition_seconds/2):linear(transition_seconds/2):diffusealpha(0)
			end
		end
	},

	-- ArrowCloud Logo
	Def.Sprite{
		Texture=THEME:GetPathG("", "Arrow Cloud/ac logo.png"),
		Name="ACLogo",
		InitCommand=function(self)
			self:diffusealpha(0):zoom(0.08)
		end,
		LoopScoreboxCommand=function(self)
			if cur_style >= 4 then
				self:sleep(transition_seconds/2):linear(transition_seconds/2):diffusealpha(0.25)
			else
				self:linear(transition_seconds/2):diffusealpha(0)
			end
		end
	},

	-- ArrowCloud Mode Text (ITG / EX / H.EX)
	LoadFont(ThemePrefs.Get("ThemeFont") .. " Normal")..{
		Name="ACModeLabel",
		Text="",
		InitCommand=function(self)
			self:diffusealpha(0):zoom(1.0):horizalign(center):vertalign(middle)
			self:xy(0,0)
		end,
		LoopScoreboxCommand=function(self)
			local label = ""
			if     cur_style == 4 then label = "ITG"
			elseif cur_style == 5 then label = "EX"
			elseif cur_style == 6 then label = "H.EX" end
			if label ~= "" then
				if label == "ITG" then
					self:diffuse(SL.JudgmentColors["FA+"][2])
				elseif label == "EX" then
					self:diffuse(SL.JudgmentColors["FA+"][1])
				elseif label == "H.EX" then
					self:diffuse(SL.JudgmentColors["FA+"][7])
				end
				self:settext(label)
				self:sleep(transition_seconds/2):linear(transition_seconds/2):diffusealpha(0.65)
			else
				self:linear(transition_seconds/2):diffusealpha(0)
			end
		end
	},
}

for i=1,NumEntries do
	local y = -height/2 + (height/GS_ROWS) * i - ((height/GS_ROWS)/2)
	local zoom = TextZoomForStyle(0)

	-- Rank 1 gets a crown.
	if i == 1 then
		af[#af+1] = Def.Sprite{
			Name="Rank"..i,
			Texture=THEME:GetPathG("", "crown.png"),
			InitCommand=function(self)
				self:zoom(CrownZoomForStyle(0)):xy(-width/2 + 14, y):diffusealpha(0)
			end,
			LoopScoreboxCommand=function(self)
				self:linear(transition_seconds/2):diffusealpha(0):queuecommand("SetScorebox")
			end,
			SetScoreboxCommand=function(self)
				local displayRows = RowsForStyle(cur_style)
				if i > displayRows then self:visible(false) return end
				local spacing = RowSpacingForStyle(cur_style)
				local yy = -height/2 + spacing * i - spacing/2
				self:y(yy):zoom(CrownZoomForStyle(cur_style)):visible(true)
				local score = all_data[cur_style+1]["scores"][i]
				if score.rank ~= "" then
					self:linear(transition_seconds/2):diffusealpha(1)
				else
					self:diffusealpha(0)
				end
			end
		}
	else
		af[#af+1] = LoadFont(ThemePrefs.Get("ThemeFont") .. " Normal")..{
			Name="Rank"..i,
			Text="",
			InitCommand=function(self)
				self:diffuse(Color.White):xy(-width/2 + 27, y):maxwidth(30):horizalign(right):zoom(zoom)
			end,
			LoopScoreboxCommand=function(self)
				self:linear(transition_seconds/2):diffusealpha(0):queuecommand("SetScorebox")
			end,
			SetScoreboxCommand=function(self)
				local displayRows = RowsForStyle(cur_style)
				if i > displayRows then self:visible(false) return end
				local spacing = RowSpacingForStyle(cur_style)
				local yy = -height/2 + spacing * i - spacing/2
				self:y(yy):zoom(TextZoomForStyle(cur_style)):visible(true)
				local score = all_data[cur_style+1]["scores"][i]
				local clr = Color.White
				if score.isSelf then
					clr = self_color
				elseif score.isRival then
					clr = rival_color
				end
				self:settext(score.rank)
				self:linear(transition_seconds/2):diffusealpha(1):diffuse(clr)
			end
		}
	end

	af[#af+1] = LoadFont(ThemePrefs.Get("ThemeFont") .. " Normal")..{
		Name="Name"..i,
		Text="",
		InitCommand=function(self)
			self:diffuse(Color.White):xy(-width/2 + 30, y):maxwidth(100):horizalign(left):zoom(zoom)
		end,
		LoopScoreboxCommand=function(self)
			self:linear(transition_seconds/2):diffusealpha(0):queuecommand("SetScorebox")
		end,
		SetScoreboxCommand=function(self)
			local displayRows = RowsForStyle(cur_style)
			if i > displayRows then self:visible(false) return end
			local spacing = RowSpacingForStyle(cur_style)
			local yy = -height/2 + spacing * i - spacing/2
			self:y(yy):zoom(TextZoomForStyle(cur_style)):visible(true)
			local score = all_data[cur_style+1]["scores"][i]
			local clr = Color.White
			if score.isSelf then
				clr = self_color
			elseif score.isRival then
				clr = rival_color
			end
			self:settext(score.name)
			self:linear(transition_seconds/2):diffusealpha(1):diffuse(clr)
		end
	}

	af[#af+1] = LoadFont(ThemePrefs.Get("ThemeFont") .. " Normal")..{
		Name="Score"..i,
		Text="",
		InitCommand=function(self)
			self:diffuse(Color.White):xy(-width/2 + 160, y):horizalign(right):zoom(zoom)
		end,
		LoopScoreboxCommand=function(self)
			self:linear(transition_seconds/2):diffusealpha(0):queuecommand("SetScorebox")
		end,
		SetScoreboxCommand=function(self)
			local displayRows = RowsForStyle(cur_style)
			if i > displayRows then self:visible(false) return end
			local spacing = RowSpacingForStyle(cur_style)
			local yy = -height/2 + spacing * i - spacing/2
			self:y(yy):zoom(TextZoomForStyle(cur_style)):visible(true)
			local score = all_data[cur_style+1]["scores"][i]
			local clr = Color.White
			if score.isFail then
				clr = Color.Red
			elseif cur_style == 6 then
				-- HardEX pane: render scores in pink
				clr = SL.JudgmentColors["FA+"][7]
			elseif score.isEx then
				-- EX scoring (non-HardEX) in red
				clr = SL.JudgmentColors["FA+"][1]
			elseif score.isSelf then
				clr = self_color
			elseif score.isRival then
				clr = rival_color
			end
			self:settext(score.score)
			self:linear(transition_seconds/2):diffusealpha(1):diffuse(clr)
		end
	}
end
return af
