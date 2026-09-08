-- -----------------------------------------------------------------------
-- Judgment animations (tap only)

SLCustom.JudgmentAnimations = SLCustom.InitTable({ -- t,j,z,a = target,judgment,zoom,alpha
	{
		name = "Default", -- this should match the custom JudgmentTween() from SL for 3.95
		custom = function(t,j,z) t:zoom(z*16/15):decelerate(0.1):zoom(z):sleep(0.6):accelerate(0.2):zoom(0) end
	},
	{
		name = "Still", -- this should match the behaviour of Etterna
		custom = function(t,j,z) t:zoom(z):sleep(0.9):linear(0):zoom(0) end
	},
	{
		name = "ITG", -- this should match the behaviour of ITG2/ITG3
		custom = function(t,j,z) t:zoom(z*4/3):decelerate(0.2):zoom(z):sleep(0.6):accelerate(0.2):zoom(0) end
	},
	{
		name = "Hold",
		custom = function(t,j,z) t:zoom(z*0.8):linear(0.3):zoom(z):sleep(0.5):linear(0):zoom(0) end
	},
	{
		name = "Fade",
		custom = function(t,j,z,a) t:zoom(z):diffusealpha(0):linear(0.1):diffusealpha(a):sleep(0.6):linear(0.2):diffusealpha(0):linear(0):zoom(0):diffusealpha(a) end
	},
	{
		name = "Glow",
		custom = function(t,j,z)
			t:glowshift():effectperiod(0.6)
			if j == "W0" then -- W0 will always be used for Fantastic when the FA+ window is disabled
				t:effectcolor1(color("#21cce800")):effectcolor2(color("#21cce8"))
			elseif j == "W1" then -- W1 is exclusively used for the white Fantastic when the FA+ window is enabled
				t:effectcolor1(color("#ffffff00")):effectcolor2(color("#ffffff"))
			elseif j == "W2" then
				t:effectcolor1(color("#e29c1800")):effectcolor2(color("#e29c18"))
			elseif j == "W3" then
				t:effectcolor1(color("#66c95500")):effectcolor2(color("#66c955"))
			elseif j == "W4" then
				t:effectcolor1(color("#b45cff00")):effectcolor2(color("#b45cff"))
			elseif j == "W5" then
				t:effectcolor1(color("#c9855e00")):effectcolor2(color("#c9855e"))
			elseif j == "Miss" then
				t:effectcolor1(color("#ff303000")):effectcolor2(color("#ff3030"))
			end
			t:zoom(z*16/15):decelerate(0.1):zoom(z):sleep(0.6):accelerate(0.2):zoom(0)
		end
	},
})

-- -----------------------------------------------------------------------
-- Combo animations

SLCustom.ComboAnimations = SLCustom.InitTable({ -- t,z = target,zoom
	{
		name = "Still",
		custom = function(t) end
	},
	{
		name = "Grow",
		custom = function(t,z) t:zoom(z*1.1):decelerate(0.1):zoom(z) end
	},
	{
		name = "Shrink",
		custom = function(t,z) t:zoom(z/1.125):decelerate(0.1):zoom(z) end
	},
	{
		name = "Pulse",
		custom = function(t,z) t:decelerate(0.06):zoom(z*1.1):accelerate(0.06):zoom(z) end
	},
	{
		name = "Left",
		custom = function(t) t:addx(-6):decelerate(0.1):addx(6) end
	},
	{
		name = "Down",
		custom = function(t)t:addy(6):decelerate(0.1):addy(-6) end
	},
	{
		name = "Up",
		custom = function(t) t:addy(-6):decelerate(0.1):addy(6) end
	},
	{
		name = "Right",
		custom = function(t) t:addx(6):decelerate(0.1):addx(-6) end
	},
	{
		name = "Hop",
		custom = function(t) t:decelerate(0.06):addy(-6):accelerate(0.06):addy(6) end
	},
	{
		name = "Fade",
		custom = function(t) t:diffusealpha(0):linear(0.1):diffusealpha(1) end
	},
})