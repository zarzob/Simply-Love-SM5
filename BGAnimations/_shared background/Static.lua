-- --------------------------------------------------------
-- static background image

local file = ...

-- We want the Shared BG to be used on the following screens.
local SharedBackground = {
	["ScreenInit"] = true,
	["ScreenLogo"] = true,
	["ScreenTitleMenu"] = true,
	["ScreenTitleJoin"] = true,
	["ScreenSelectProfile"] = true,
	["ScreenSelectColor"] = true,
	["ScreenSelectStyle"] = true,
	["ScreenSelectPlayMode"] = true,
	["ScreenSelectPlayMode2"] = true,
	["ScreenProfileLoad"] = true, -- hidden screen	

	-- false until Technique is selected
	["ScreenSelectMusic"] = false,
	["ScreenEvaluation"] = false,

	-- Operator Menu screens and sub screens.
	["ScreenOptionsService"] = true,
	["ScreenSystemOptions"] = true,
	["ScreenMapControllers"] = true,
	["ScreenTestInput"] = true,
	["ScreenInputOptions"] = true,
	["ScreenGraphicsSoundOptions"] = true,
	["ScreenVisualOptions"] = true,
	["ScreenAppearanceOptions"] = true,
	["ScreenSetBGFit"] = true,
	["ScreenOverscanConfig"] = true,
	["ScreenArcadeOptions"] = true,
	["ScreenAdvancedOptions"] = true,
	["ScreenMenuTimerOptions"] = true,
	["ScreenUSBProfileOptions"] = true,
	["ScreenOptionsManageProfiles"] = true,
	["ScreenThemeOptions"] = true,
}

-- Show shared background on more screens if Technique visual style is selected
if ThemePrefs.Get("VisualStyle") == "Technique" then
	SharedBackground["ScreenSelectMusic"] = true
	SharedBackground["ScreenEvaluation"] = true
end

local shared_alpha = 0.6
local static_alpha = 1
local style = ThemePrefs.Get("VisualStyle")

local af = Def.ActorFrame {
	InitCommand=function(self)
		self:diffusealpha(0)
		self:visible(style == "SRPG7" or style == "Transistor")
	end,
	OnCommand=function(self)
		self:accelerate(0.8):diffusealpha(1)
	end,
	VisualStyleSelectedMessageCommand=function(self)
		local style = ThemePrefs.Get("VisualStyle")
		if style == "SRPG7" or style == "Transistor" then
			self:visible(true)
		else
			self:visible(false)
		end
	end,
	Def.Sprite {
		Name="Background",
		InitCommand= function(self)
			if style ~= "SRPG7" and style ~= "Transistor" then self:Load(nil) return end

			if style == "SRPG7" then
				local video_allowed = ThemePrefs.Get("AllowThemeVideos")
				if video_allowed then
					self:Load(THEME:GetPathG("", "_VisualStyles/SRPG7/BackgroundVideo.mp4"))
				else
					self:Load(THEME:GetPathG("", "_VisualStyles/SRPG7/SharedBackground.png"))
				end
				self:xy(_screen.cx, _screen.cy)
					:zoomto(_screen.h * 16 / 9, _screen.h)
						:blend("BlendMode_Add")
						:diffusealpha(0.8)
						:diffuse(GetCurrentColor(true))
			elseif style == "Transistor" then
				self:Load(THEME:GetPathG("", "_VisualStyles/Transistor/bgs/sword.png"))
				self:xy(_screen.cx, _screen.cy)
					:zoomto(_screen.h * 16 / 9, _screen.h)
						:blend("BlendMode_Normal")
						:diffusealpha(0.8)
						:diffuse(GetCurrentColor(true))
			end
			
			self:visible(style == "SRPG7" or style == "Transistor")
		end,
		ScreenChangedMessageCommand=function(self)
			if style == "Transistor" then
				local screen = SCREENMAN:GetTopScreen()
				if screen:GetName() == "ScreenSelectMusic" or screen:GetName() == "ScreenSelectCourse" then
					self:Load(THEME:GetPathG("", "_VisualStyles/Transistor/bgs/city.png"))
						:blend("BlendMode_Normal")
						:diffusealpha(0.8)
						:diffuse(1,1,1,1)
						:xy(_screen.cx, _screen.cy)
						:zoomto(_screen.h * 16 / 9, _screen.h)
				elseif string.find(screen:GetName(), "ScreenPlayerOptions") then
					self:Load(THEME:GetPathG("", "_VisualStyles/Transistor/bgs/red2.png"))
						:blend("BlendMode_Normal")
						:diffusealpha(0.8)
						:diffuse(1,1,1,1)
						:xy(_screen.cx, _screen.cy)
						:zoomto(_screen.h * 16 / 9, _screen.h)
				elseif screen:GetName() == "ScreenEvaluationStage" or screen:GetName() == "ScreenEvaluationNonstop" then
					self:Load(THEME:GetPathG("", "_VisualStyles/Transistor/bgs/red.png"))
						:blend("BlendMode_Normal")
						:diffusealpha(0.8)
						:diffuse(1,1,1,1)
						:xy(_screen.cx, _screen.cy)
						:zoomto(_screen.h * 16 / 9, _screen.h)
				elseif screen:GetName() == "ScreenEvaluationSummary" or screen:GetName() == "ScreenNameEntryTraditional" then
					self:Load(THEME:GetPathG("", "_VisualStyles/Transistor/bgs/goodbye.png"))
						:blend("BlendMode_Normal")
						:diffusealpha(0.8)
						:diffuse(1,1,1,1)
						:xy(_screen.cx, _screen.cy)
						:zoomto(_screen.h * 16 / 9 * 1.2, _screen.h * 1)
				elseif screen:GetName() == "ScreenGameOver" then
					self:Load(THEME:GetPathG("", "_VisualStyles/Transistor/bgs/gameover.png"))
						:blend("BlendMode_Normal")
						:diffusealpha(0.8)
						:diffuse(1,1,1,1)
						:xy(_screen.cx, _screen.cy)
						:zoomto(_screen.h * 16 / 9 * 1.2, _screen.h * 1)
				elseif screen:GetName() == "ScreenSelectStyle" or screen:GetName() == "ScreenSelectPlayMode" or screen:GetName() == "ScreenSelectPlayMode2" or screen:GetName() == "ScreenProfileLoad" then
					self:Load(THEME:GetPathG("", "_VisualStyles/Transistor/bgs/running.png"))
						:blend("BlendMode_Normal")
						:diffusealpha(0.8)
						:diffuse(1,1,1,1)
						:xy(_screen.cx, _screen.cy)
						:zoomto(_screen.h * 16 / 9 * 1.2, _screen.h * 1)
				else
					self:Load(THEME:GetPathG("", "_VisualStyles/Transistor/bgs/sword.png"))
						:blend("BlendMode_Normal")
						:diffusealpha(0.8)
						:diffuse(0.5,0.5,0.5,1)
						:xy(_screen.cx, _screen.cy)
						:zoomto(_screen.h * 16 / 9, _screen.h)
				end
			end
		end,
		VisualStyleSelectedMessageCommand=function(self)
			if style ~= "SRPG7" and style ~= "Transistor" then self:Load(nil) return end

			if style == "SRPG7" then
				local video_allowed = ThemePrefs.Get("AllowThemeVideos")
				if video_allowed then
					self:Load(THEME:GetPathG("", "_VisualStyles/SRPG7/BackgroundVideo.mp4"))
				else
					self:Load(THEME:GetPathG("", "_VisualStyles/SRPG7/SharedBackground.png"))
				end
				self:xy(_screen.cx, _screen.cy)
					:zoomto(_screen.h * 16 / 9, _screen.h)
						:blend("BlendMode_Add")
						:diffusealpha(0.8)
						:diffuse(GetCurrentColor(true))
			elseif style == "Transistor" then
				self:Load(THEME:GetPathG("", "_VisualStyles/Transistor/bgs/sword.png"))
				self:xy(_screen.cx, _screen.cy)
					:zoomto(_screen.h * 16 / 9, _screen.h)
						:blend("BlendMode_Normal")
						:diffusealpha(0.8)
						:diffuse(1,1,1,1)
			end
			
			self:visible(style == "SRPG7" or style == "Transistor")
		end,
		AllowThemeVideoChangedMessageCommand=function(self)
			if style ~= "SRPG7" and style ~= "Transistor" then self:Load(nil) return end

			if style == "SRPG7" then
				local video_allowed = ThemePrefs.Get("AllowThemeVideos")
				if video_allowed then
					self:Load(THEME:GetPathG("", "_VisualStyles/SRPG7/BackgroundVideo.mp4"))
				else
					self:Load(THEME:GetPathG("", "_VisualStyles/SRPG7/SharedBackground.png"))
				end
				self:xy(_screen.cx, _screen.cy)
					:zoomto(_screen.h * 16 / 9, _screen.h)
						:blend("BlendMode_Add")
						:diffusealpha(0.8)
						:diffuse(GetCurrentColor(true))
			elseif style == "Transistor" then
				self:Load(THEME:GetPathG("", "_VisualStyles/Transistor/bgs/sword.png"))
				self:xy(_screen.cx, _screen.cy)
					:zoomto(_screen.h * 16 / 9, _screen.h)
						:blend("BlendMode_Normal")
						:diffusealpha(0.8)
						:diffuse(1,1,1,1)
			end
		end,
	},
	Def.Sprite {
		Name="Fog",
		Texture=THEME:GetPathG("", "_VisualStyles/Transistor/bgs/Fog.mp4"),
		InitCommand= function(self)
			self:xy(_screen.cx, _screen.cy):zoomto(_screen.w, _screen.h):blend("BlendMode_Add"):diffusealpha(1):diffuse(GetCurrentColor(true))
			if ThemePrefs.Get("RainbowMode") then
				self:diffusealpha(0.3):rainbow()
			else
				self:diffusealpha(1):stopeffect()
			end
		end,
		ColorSelectedMessageCommand=function(self)
			self:diffuse(GetCurrentColor(true))
		end,
	},
}

return af
