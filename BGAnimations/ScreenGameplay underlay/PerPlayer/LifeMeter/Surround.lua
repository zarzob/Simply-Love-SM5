local player = ...
local pn = ToEnumShortString(player)

local height = _screen.h - 80
local _x = _screen.cx + (player==PLAYER_1 and -1 or 1) * SL_WideScale(302, 400)
local oldlife = 0

-- if double
if GAMESTATE:GetCurrentStyle():GetStyleType() == "StyleType_OnePlayerTwoSides"
-- or center1player preference is enabled and only one player is playing
or PREFSMAN:GetPreference("Center1Player") and #GAMESTATE:GetHumanPlayers() == 1 then
	_x =  _screen.cx + ((GetNotefieldWidth()/2 + 10) * (player==PLAYER_1 and -1 or 1))

-- for the highly-specific scenario where aspect ratio is ultrawide or wider
-- and both players are joined, and this player wants both a vertical lifemeter
-- and step stats, move their vertical lifemeter to the inside of the notefield
elseif GetScreenAspectRatio() > 21/9
and #GAMESTATE:GetHumanPlayers() > 1
and SL[pn].ActiveModifiers.DataVisualizations == "Step Statistics"
then
	_x = _screen.cx + (player==PLAYER_1 and -1 or 1) * 60
end

local af = Def.ActorFrame{
	Name="LifeMeter_"..ToEnumShortString(player),
	InitCommand=function(self)
		self:xy(0,0)
	end,
	HealthStateChangedMessageCommand=function(self,params)
		if (params.PlayerNumber == player) then
			if params.HealthState == "HealthState_Dead" then
				self:queuecommand("Dead")
			end
		end
	end,
	LifeChangedMessageCommand=function(self,params)
		if (params.Player == player) then
			self:playcommand("ChangeSize", {CropAmount=(1-params.LifeMeter:GetLife()) })
		end
	end,
}

-- if double style, we want two quads flanking the left/right sides of the screen that move in unison
if GAMESTATE:GetCurrentStyle():GetName():gsub("8","") == "double" then
	af[#af+1] = Def.Quad{
		Name="Left",
		InitCommand=function(self)
			self:vertalign(top):horizalign(left)
				:zoomto( _screen.w/2, _screen.h-80 ):diffuse(0.2,0.2,0.2,1)
				:faderight(0.8):xy(0, 80)
		end,
		ChangeSizeCommand=function(self, params)
			self:finishtweening():smooth(0.2):croptop(params.CropAmount)
		end,
		DeadCommand=function(self)
			self:finishtweening():smooth(0.2):croptop(1)
		end
	}

	af[#af+1] = Def.Quad{
		Name="Right",
		InitCommand=function(self)
			self:vertalign(top):horizalign(right)
				:zoomto( _screen.w/2, _screen.h-80 ):diffuse(0.2,0.2,0.2,1)
				:fadeleft(0.8):xy(_screen.w, 80)
		end,
		ChangeSizeCommand=function(self, params)
			self:finishtweening():smooth(0.2):croptop(params.CropAmount)
		end,
		DeadCommand=function(self)
			self:finishtweening():smooth(0.2):croptop(1)
		end
	}

-- if single or versus style, we want one uniquely-moving quad per player
else
	af[#af+1] = Def.Quad{
		InitCommand=function(self)
			self:vertalign(top)
				:zoomto( _screen.w/2, _screen.h-80 )

			if player == PLAYER_1 then
				self:horizalign(left):diffuse(0.2,0.2,0.2,1):faderight(0.8):xy(0, 80)
			else
				self:horizalign(right):diffuse(0.2,0.2,0.2,1):fadeleft(0.8):xy(_screen.w, 80)
			end
		end,
		ChangeSizeCommand=function(self, params)
			self:finishtweening():smooth(0.2):croptop(params.CropAmount)
			local absLife = 1-params.CropAmount
			if SL[pn].ActiveModifiers.ResponsiveColors then
				if absLife >= 0.9 then
					self:diffuse(0, 1, (absLife - 0.9) * 10, 0.2)
				elseif absLife >= 0.5 then
					self:diffuse((0.9 - absLife) * 10 / 4, 1, 0, 0.2)
				else
					self:diffuse(1, (absLife - 0.2) * 10 / 3, 0, 0.2)
				end
			end
			if absLife == 1 and SL[pn].ActiveModifiers.RainbowMax then
				self:rainbow()
			elseif SL[pn].ActiveModifiers.RainbowMax then
				self:stopeffect()
			end
		end,
		DeadCommand=function(self)
			self:finishtweening():smooth(0.2):croptop(1)
		end
	}
end


af[#af+1] = Def.Quad { -- frame
	InitCommand=function(self)
		self:visible(SL[pn].ActiveModifiers.ShowLifePercent)
		self:zoomto(44, 18):diffuse(PlayerColor(player,true)):horizalign("left")
		if player==PLAYER_1 then
			self:x(_x+10)
		else
			self:x(_x-11):horizalign("right")
		end
	end,
	HealthStateChangedMessageCommand=function(self,params)
		if params.PlayerNumber == player then
			if params.HealthState == 'HealthState_Hot' then
				self:finishtweening()
				self:zoomto(52, 18)
				self:accelerate(1)
				self:diffusealpha(0)
			else
				-- ~~man's~~ lifebar's not hot
				self:zoomto(44, 18):finishtweening():diffusealpha(1)
			end
		end
	end,
	-- check life (LifeMeterBar)
	LifeChangedMessageCommand=function(self,params)
		if params.Player == player then
			local life = params.LifeMeter:GetLife() * 100
			if life < 100 then
				self:finishtweening()
			end
			if oldlife ~= 250 or life ~= 100 then
				self:bouncebegin(0.1):y(math.max(89,71+height-(life*(height/100))))
			else
				self:y(math.max(89,71+height-(life*(height/100))))
			end
		end
	end,
}

-- percent
af[#af+1] = Def.Quad {
	InitCommand=function(self)
		self:visible(SL[pn].ActiveModifiers.ShowLifePercent)
		self:zoomto(42, 16):diffuse(0,0,0,1):horizalign("left")
		if player==PLAYER_1 then
			self:x(_x+11)
		else
			self:x(_x-12):horizalign("right")
		end
	end,
	HealthStateChangedMessageCommand=function(self,params)
		if params.PlayerNumber == player then
			if params.HealthState == 'HealthState_Hot' then
				self:finishtweening()
				self:zoomto(50, 16)
				self:accelerate(1)
				self:diffusealpha(0)
			else
				-- ~~man's~~ lifebar's not hot
				self:zoomto(42, 16):finishtweening():diffusealpha(1)
			end
		end
	end,
	-- check life (LifeMeterBar)
	LifeChangedMessageCommand=function(self,params)
		if params.Player == player then
			local life = params.LifeMeter:GetLife() * 100
			if life < 100 then
				self:finishtweening()
			end
			if oldlife ~= 250 or life ~= 100 then
				self:bouncebegin(0.1):y(math.max(89,71+height-(life*(height/100))))
			else
				self:y(math.max(89,71+height-(life*(height/100))))
			end
		end
	end,
}

af[#af+1] = Def.BitmapText {
	Font=ThemePrefs.Get("ThemeFont") .. " Normal",
	InitCommand=function(self)
		self:visible(SL[pn].ActiveModifiers.ShowLifePercent)
		self:diffuse(PlayerColor(player,true)):horizalign("left")
		if player==PLAYER_1 then
			self:x(_x+12)
		else
			self:x(_x-13):horizalign("right")
		end
	end,
	HealthStateChangedMessageCommand=function(self,params)
		if params.PlayerNumber == player then
			if params.HealthState == 'HealthState_Hot' then
				self:accelerate(1):diffusealpha(0)
			else
				-- ~~man's~~ lifebar's not hot
				self:finishtweening():diffusealpha(1)
			end
		end
	end,
	-- check life (LifeMeterBar)
	LifeChangedMessageCommand=function(self,params)
		if params.Player == player then
			local life = params.LifeMeter:GetLife() * 100
			if life < 100 then
				self:finishtweening()
			end
			if oldlife ~= 250 or life ~= 100 then
				self:bouncebegin(0.1):y(math.max(89,71+height-(life*(height/100))))
			end
			self:settext(("%.1f%%"):format(life))
		end
	end,
}

return af
