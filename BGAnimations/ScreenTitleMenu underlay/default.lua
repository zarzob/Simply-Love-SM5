-- - - - - - - - - - - - - - - - - - - - -
-- first, reset the global SL table to default values
-- this is defined in:  ./Scripts/SL_Init.lua
InitializeSimplyLove()

if ThemePrefs.Get("VisualStyle") == "SRPG7" then
	SL.SRPG7:MaybeRandomizeColor()
end

-- -----------------------------------------------------------------------
-- preliminary Lua setup is done
-- now define actors to be passed back to the SM engine

local af = Def.ActorFrame{}
af.InitCommand=function(self) self:Center() end


-- IsSpooky() will be true during October if EasterEggs are enabled
-- this is the content found in ./Graphics/_VisualStyles/Spooky/ExtraSpooky
-- it needs to be layered appropriately, some assets behind, some in front
-- Spooky.lua includes a quad that fades the screen to black and the glowing pumpkin that remains
-- SpookyButFadeOut.lua includes cobwebs in the upper-right and upper-left
if IsSpooky() then
	af[#af+1] = LoadActor("./Spooky.lua")
end

-- -----------------------------------------------------------------------
-- af2 contains things that should fade out during the OffCommand
local af2 = Def.ActorFrame{}
af2.OffCommand=function(self) self:smooth(0.65):diffusealpha(0) end
af2.Name="SLInfo"


-- the big blocky Wendy text that says SIMPLY LOVE (or SIMPLY THONK, or SIMPLY DUCKS, etc.)
-- and the arrows graphic that appears between the two words
af2[#af2+1] = LoadActor("./Logo.lua")

-- 3 lines of text:
--    theme_name   theme_version
--    stepmania_version
--    num_songs in num_groups, num_courses
af2[#af2+1] = LoadActor("./UserContentText.lua")

-- "The chills, I have them down my spine."
if IsSpooky() then
	af2[#af2+1] = LoadActor("./SpookyButFadeOut.lua")
end

-- the best way to spread holiday cheer is singing loud for all to hear
if HolidayCheer() then
	af2[#af2+1] = Def.Sprite{
		Texture=THEME:GetPathB("ScreenTitleMenu", "underlay/hat.png"),
		InitCommand=function(self) self:zoom(0.225):xy( 130, -self:GetHeight()/2 ):rotationz(15):queuecommand("Drop") end,
		DropCommand=function(self) self:decelerate(1.333):y(-110) end,
	}
end

-- ensure that af2 is added as a child of af
af[#af+1] = af2

-- Tutorial stuff
-- Create rounded quads 


af[#af+1] = Def.ActorFrame {

	-- Background
	Def.ActorMultiVertex {
		OnCommand=function(self)
			self:SetDrawState({Mode="DrawMode_Fan"})
			local width = 202
			local height = 202
			local color = Color.White
			local intensity = 0.1
			self:SetVertices(createRoundedQuad(width,height, color, intensity,false,true,true,false))
		end
	},
	-- Background border
	Def.ActorMultiVertex {
		OnCommand=function(self)
			self:SetDrawState({Mode="DrawMode_Fan"})
			local width = 200
			local height = 200
			local color = Color.Red
			local intensity = 0.1
			self:SetVertices(createRoundedQuad(width,height, color, intensity,false,true,true,false))
		end
	},

	-- Tab 1
	Def.ActorFrame {
		-- Tab 1 background
		Def.ActorMultiVertex {
			OnCommand=function(self)
				self:SetDrawState({Mode="DrawMode_Fan"})
				local width = 42
				local height = 10
				local color = Color.White
				local intensity = 0.5
				self:SetVertices(createRoundedQuad(width,height, color, intensity,true,false,false,true))
				self:xy(-160,-210)
			end
		},
		-- Inside
		Def.ActorMultiVertex {
			OnCommand=function(self)
				self:SetDrawState({Mode="DrawMode_Fan"})
				local width = 40
				local height = 8
				local color = Color.Blue
				local intensity = 0.5
				self:SetVertices(createRoundedQuad(width,height, color, intensity,true,false,false,true))
				self:xy(-160,-210)
			end
		},
	},
	-- Tab 2
	Def.ActorFrame {
		-- Background
		Def.ActorMultiVertex {
			OnCommand=function(self)
				self:SetDrawState({Mode="DrawMode_Fan"})
				local width = 42
				local height = 10
				local color = Color.White
				local intensity = 0.5
				self:SetVertices(createRoundedQuad(width,height, color, intensity,true,false,false,true))
				self:xy(-78,-210)
			end
		},
		-- Inside
		Def.ActorMultiVertex {
			OnCommand=function(self)
				self:SetDrawState({Mode="DrawMode_Fan"})
				local width = 40
				local height = 8
				local color = color("#808080")
				local intensity = 0.5
				self:SetVertices(createRoundedQuad(width,height, color, intensity,true,false,false,true))
				self:xy(-78,-210)
			end
		},
	},
	-- Tab 3
	Def.ActorFrame {
		-- Background
		Def.ActorMultiVertex {
			OnCommand=function(self)
				self:SetDrawState({Mode="DrawMode_Fan"})
				local width = 42
				local height = 10
				local color = Color.White
				local intensity = 0.5
				self:SetVertices(createRoundedQuad(width,height, color, intensity,true,false,false,true))
				self:xy(4,-210)
			end
		},
		-- Inside
		Def.ActorMultiVertex {
			OnCommand=function(self)
				self:SetDrawState({Mode="DrawMode_Fan"})
				local width = 40
				local height = 8
				local color = color("#808080")
				local intensity = 0.5
				self:SetVertices(createRoundedQuad(width,height, color, intensity,true,false,false,true))
				self:xy(4,-210)
			end
		},
	},
	-- Tab 4
	Def.ActorFrame {
		-- Background
		Def.ActorMultiVertex {
			OnCommand=function(self)
				self:SetDrawState({Mode="DrawMode_Fan"})
				local width = 42
				local height = 10
				local color = Color.White
				local intensity = 0.5
				self:SetVertices(createRoundedQuad(width,height, color, intensity,true,false,false,true))
				self:xy(86,-210)
			end
		},
		-- Inside
		Def.ActorMultiVertex {
			OnCommand=function(self)
				self:SetDrawState({Mode="DrawMode_Fan"})
				local width = 40
				local height = 8
				local color = color("#808080")
				local intensity = 0.5
				self:SetVertices(createRoundedQuad(width,height, color, intensity,true,false,false,true))
				self:xy(86,-210)
			end
		},
	},
	

}
-- -----------------------------------------------------------------------

return af
