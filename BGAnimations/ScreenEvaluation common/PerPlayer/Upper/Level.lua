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
		LoadFont(ThemePrefs.Get("ThemeFont") .. " Normal")..{
			InitCommand=function(self)
				self:xy(0, _screen.cy - 60):align(player==PLAYER_1 and 1 or 0, 1):zoom(0.8):settext("+" .. (earnExp == 69 and ThemePrefs.Get("nice") > 0 and "nice" or earnExp) .. " EXP")
				if ThemePrefs.Get("RainbowMode") then
					self:diffuse(Color.Black)
				end
				if ThemePrefs.Get("VisualStyle") == "Transistor" then
					self:diffuse(color(SL.SRPG8.TextColor))
					self:shadowlength(0.4)
				end
			end
		}
	}
else return end
