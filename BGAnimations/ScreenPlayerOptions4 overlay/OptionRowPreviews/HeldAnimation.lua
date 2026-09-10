local t = ...

local HeldAnimationOptRowIndex = nil

local LineNames = split(",", THEME:GetMetric("ScreenPlayerOptions4", "LineNames"))
for i, name in ipairs(LineNames) do
	if name == "HeldAnimation" then HeldAnimationOptRowIndex = i-1; break end
end

local PlayerOnHeldAnimationOptRow = function(p)
	return SCREENMAN:GetTopScreen():GetCurrentRowIndex(p) == HeldAnimationOptRowIndex
end

for player in ivalues(GAMESTATE:GetHumanPlayers()) do
	local pn = ToEnumShortString(player)
	local prev_anim = nil
	
	t[#t+1] = LoadActor( THEME:GetPathG("", "_HeldMiss/" .. (SL[pn].ActiveModifiers.HeldGraphic ~= "None" and SL[pn].ActiveModifiers.HeldGraphic or "Love (doubleres).png")) )..{
			Name=(pn.."_HeldAnimation"),
			InitCommand=function(self)
				self:visible(false):animate(false)
			end,
			OptionRowChangedMessageCommand=function(self, params)
				if PlayerOnHeldAnimationOptRow(player) then
					if SL[pn].ActiveModifiers.HeldAnimation ~= prev_anim then
						prev_anim = SL[pn].ActiveModifiers.HeldAnimation
						self:finishtweening():stopeffect():zoom(1):playcommand("HeldAnimation")
					end
				else
					prev_anim = nil
					self:finishtweening():stopeffect():diffusealpha(1):zoom(1)
				end
			end,
			HeldAnimationCommand=function(self)
				SLCustom.JudgmentAnimations[SL[pn].ActiveModifiers.HeldAnimation](self, "HeldMiss", 1, 1)
			end
		}
end