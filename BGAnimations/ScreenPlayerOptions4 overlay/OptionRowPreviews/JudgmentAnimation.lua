local t = ...

local JudgmentAnimationOptRowIndex = nil

local LineNames = split(",", THEME:GetMetric("ScreenPlayerOptions4", "LineNames"))
for i, name in ipairs(LineNames) do
	if name == "JudgmentAnimation" then JudgmentAnimationOptRowIndex = i-1; break end
end

local PlayerOnJudgmentAnimationOptRow = function(p)
	return SCREENMAN:GetTopScreen():GetCurrentRowIndex(p) == JudgmentAnimationOptRowIndex
end

for player in ivalues(GAMESTATE:GetHumanPlayers()) do
	local pn = ToEnumShortString(player)
	local prev_anim = nil
	
	t[#t+1] = LoadActor( THEME:GetPathG("", "_judgments/" .. SL[pn].ActiveModifiers.JudgmentGraphic) )..{
			Name=(pn.."_JudgmentAnimation"),
			InitCommand=function(self)
				self:visible(false):animate(false)
			end,
			OptionRowChangedMessageCommand=function(self, params)
				if PlayerOnJudgmentAnimationOptRow(player) then
					if SL[pn].ActiveModifiers.JudgmentAnimation ~= prev_anim then
						prev_anim = SL[pn].ActiveModifiers.JudgmentAnimation
						self:finishtweening():stopeffect():zoom(1):playcommand("JudgmentAnimation")
					end
				else
					prev_anim = nil
					self:finishtweening():stopeffect():diffusealpha(1):zoom(1)
				end
			end,
			JudgmentAnimationCommand=function(self)
				SLCustom.JudgmentAnimations[SL[pn].ActiveModifiers.JudgmentAnimation](self, "W0", 1, 1)
			end
		}
end