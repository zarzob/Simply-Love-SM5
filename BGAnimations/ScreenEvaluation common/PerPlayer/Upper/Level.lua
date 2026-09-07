-- Leveling system, based on that of ITG 3 Encore
-- https://github.com/DarkBahamut162/itg3encore/blob/master/BGAnimations/ScreenEvaluation%20underlay/Score.lua

if ThemePrefs.Get("EnableLevelSystem") > 0 and SL.Global.GameMode ~= "Casual" then 
	local player = ...
	local pn = ToEnumShortString(player)

	local stats = STATSMAN:GetCurStageStats()
	if ToEnumShortString(GAMESTATE:GetCurrentStyle():GetStyleType()) == "TwoPlayersSharedSides" then
		stats = stats:GetRoutineStageStats()
	else
		stats = stats:GetPlayerStageStats(player)
	end

	local song = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong()

	local earn = 0
	if GAMESTATE:IsHumanPlayer(pn) then
		if GAMESTATE:IsCourseMode() then
			earn = (stats:GetSongsPassed() + (stats:GetFailed() and 0 or 1)) / (song:GetNumCourseEntries() + 1) / (stats:GetFailed() and 2 or 1)
		else
			earn = stats:GetFailed() and 0.25 or 1
		end
	end

	local step = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player) or GAMESTATE:GetCurrentSteps(player)
	local length = GAMESTATE:IsCourseMode() and TotalCourseLength(player) * SL.Global.ActiveModifiers.MusicRate or math.max(0.01,song:GetLastSecond() - song:GetFirstSecond())
	local nps = 0
	if GAMESTATE:IsCourseMode() then
		for te in ivalues(step:GetTrailEntries()) do nps = nps + te:GetSteps():GetRadarValues(pn):GetValue("RadarCategory_Notes") end
	else
		nps = step:GetRadarValues(pn):GetValue("RadarCategory_Notes") -- this means jumps count as double and so on
	end
	if nps ~= 0 then nps = nps / length * SL.Global.ActiveModifiers.MusicRate end

	local maxExp = math.floor(nps * length / 1.2)
	local earnExp = math.max(0,math.floor(stats:GetPercentDancePoints() * maxExp * earn))
	SL[pn].StyleEXP = GetPlayerEXP(player, false) + earnExp
	SL[pn].TotalEXP = GetPlayerEXP(player, true) + earnExp

	return Def.ActorFrame{
		Def.Quad{
			Name="ExpBG",
			InitCommand=function(self)
				local c1 = ThemePrefs.Get("RainbowMode") and not HolidayCheer() and Color.White or Color.Black
				local c2 = earnExp > 0 and SL.JudgmentColors.ITG[earnExp >= maxExp and 2 or 3] or c1
				self:align(0.5, 0.5):zoom(0.75):xy(70 * (player==PLAYER_1 and -1 or 1), _screen.cy - 168):diffuseshift():effectperiod(3):effectcolor1(c1):effectcolor2(lerp_color(0.5, c1, c2)):diffusealpha(0.7)
			end
		},
		LoadFont(ThemePrefs.Get("ThemeFont") .. " Normal")..{
			InitCommand=function(self)
				local bg = self:GetParent():GetChild("ExpBG")
				self:align(0.5, 0.5):zoom(bg:GetZoom()):xy(bg:GetX(), bg:GetY()):maxwidth(100):maxheight(15):settext("+" .. (earnExp == 69 and ThemePrefs.Get("nice") > 0 and "nice" or earnExp) .. " EXP"):diffuse(Color.White)
				if ThemePrefs.Get("RainbowMode") and not HolidayCheer() then self:diffuse(Color.Black) end
				bg:SetWidth(math.min(100,self:GetWidth())+16):SetHeight(math.min(15,self:GetHeight())+3):fadeleft(0.1):faderight(0.1)
			end
		}
	}
else return end
