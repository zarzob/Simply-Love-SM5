local t = ...

local HoldAnimationOptRowIndex = nil

local LineNames = split(",", THEME:GetMetric("ScreenPlayerOptions4", "LineNames"))
for i, name in ipairs(LineNames) do
	if name == "HoldAnimation" then HoldAnimationOptRowIndex = i-1; break end
end

local PlayerOnHoldAnimationOptRow = function(p)
	return SCREENMAN:GetTopScreen():GetCurrentRowIndex(p) == HoldAnimationOptRowIndex
end

for player in ivalues(GAMESTATE:GetHumanPlayers()) do
	local pn = ToEnumShortString(player)
	local prev_anim = nil
	
	t[#t+1] = LoadActor( THEME:GetPathG("", "_HoldJudgments/" .. (SL[pn].ActiveModifiers.HoldJudgment ~= "None 1x2.png" and SL[pn].ActiveModifiers.HoldJudgment ~= "None" and SL[pn].ActiveModifiers.HoldJudgment or "Love 1x2 (doubleres).png")) )..{
			Name=(pn.."_HoldAnimation"),
			InitCommand=function(self)
				self:visible(false):animate(false)
			end,
			OptionRowChangedMessageCommand=function(self, params)
				if PlayerOnHoldAnimationOptRow(player) then
					if SL[pn].ActiveModifiers.HoldAnimation ~= prev_anim then
						prev_anim = SL[pn].ActiveModifiers.HoldAnimation
						self:finishtweening():stopeffect():zoom(1):playcommand("HoldAnimation")
					end
				else
					prev_anim = nil
					self:finishtweening():stopeffect():diffusealpha(1):zoom(1)
				end
			end,
			HoldAnimationCommand=function(self)
				SLCustom.JudgmentAnimations[SL[pn].ActiveModifiers.HoldAnimation](self, "Held", 1, 1)
			end
		}
end