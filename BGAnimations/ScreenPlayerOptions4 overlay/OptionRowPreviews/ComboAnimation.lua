local t = ...

local ComboAnimationOptRowIndex = nil

local LineNames = split(",", THEME:GetMetric("ScreenPlayerOptions4", "LineNames"))
for i, name in ipairs(LineNames) do
	if name == "ComboAnimation" then ComboAnimationOptRowIndex = i-1; break end
end

local PlayerOnComboAnimationOptRow = function(p)
	return SCREENMAN:GetTopScreen():GetCurrentRowIndex(p) == ComboAnimationOptRowIndex
end

-- -----------------------------------------------------------------------

for player in ivalues(GAMESTATE:GetHumanPlayers()) do
	local pn = ToEnumShortString(player)
	local prev_beat = nil

	t[#t+1] = LoadFont("_Combo Fonts/" .. SL[pn].ActiveModifiers.ComboFont .."/" .. SL[pn].ActiveModifiers.ComboFont)..{
		Name=(pn.."_ComboAnimation"),
		Text="1",
		InitCommand=function(self) self:visible(false) end,
		
		OptionRowChangedMessageCommand=function(self, params)
			self:finishtweening()
			if PlayerOnComboAnimationOptRow(player) then
				self:queuecommand("Loop")
			end
		end,
		ComboAnimationCommand=function(self)
			self:finishtweening()
			SLCustom.ComboAnimations[SL[pn].ActiveModifiers.ComboAnimation](self, 1)
		end,
		LoopCommand=function(self)
			if PlayerOnComboAnimationOptRow(player) then
				local beat = math.floor(GAMESTATE:GetSongBeat())

				if prev_beat ~= beat then
					self:finishtweening()
					self:settext( tonumber(self:GetText())+1 )
					prev_beat = beat

					if ThemePrefs.Get("nice")==2 and self:GetText()=="69" then
						SOUND:DimMusic(PREFSMAN:GetPreference("SoundVolume"),  1.3)
						SOUND:PlayOnce(THEME:GetPathS("", "nice.ogg"))
					end
					
					self:playcommand("ComboAnimation")
				end
				
				self:sleep(0.025):queuecommand("Loop")
			end
		end
	}
end