local player, controller = unpack(...)

local percent = nil
local diffuse = nil

if SL[ToEnumShortString(player)].ActiveModifiers.ShowEXScore then
	percent = CalculateExScore(player, GetExJudgmentCounts(player))
	diffuse = SL.JudgmentColors[SL.Global.GameMode][1]
else
	local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
	local PercentDP = stats:GetPercentDancePoints()
	percent = FormatPercentScore(PercentDP):gsub("%%", "")
	-- Format the Percentage string, removing the % symbol
	percent = tonumber(percent)
	diffuse = Color.White
end

return Def.ActorFrame{
	Name="PercentageContainer"..ToEnumShortString(player),
	OnCommand=function(self)
		self:y( _screen.cy-26 )
	end,

	-- dark background quad behind player percent score
	Def.Quad{
		InitCommand=function(self)
			self:diffuse(color("#101519")):zoomto(158.5, SL.Global.GameMode == "Casual" and 60 or 88)
			self:horizalign(controller==PLAYER_1 and left or right)
			self:x(150 * (controller == PLAYER_1 and -1 or 1))
			if SL.Global.GameMode ~= "Casual" then
				self:y(14)
			end
			if ThemePrefs.Get("VisualStyle") == "Technique" then
				self:diffusealpha(0.5)
			elseif ThemePrefs.Get("VisualStyle") == "Transistor"  then
				self:diffusealpha(0.7)
			end
		end
	},

	LoadFont(ThemePrefs.Get("ThemeFont") .. " Bold")..{
		Name="Percent",
		Text=("%.2f"):format(percent),
		InitCommand=function(self)
			self:horizalign(right):zoom(0.95)
			self:x( (controller == PLAYER_1 and 1.5 or 141))
			self:diffuse(diffuse)
		end
	}
}
