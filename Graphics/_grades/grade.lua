local grade, design, pss, q = unpack(...)
if grade == nil then grade = "Grade_Failed" end
if design == nil then design = ThemePrefs.Get("OutlineGrade") == true and "Default (Outlined)" or "Default" end
if q == nil then q = true end

local grds = {
	["Grade_Tier00"] = "star",["Grade_Tier01"]="star",["Grade_Tier02"]="star",["Grade_Tier03"]="star",["Grade_Tier04"]="star",
	["Grade_Tier05"] = "s-plus",
	["Grade_Tier06"] = "s",
	["Grade_Tier07"] = "s-minus",
	["Grade_Tier08"] = "a-plus",
	["Grade_Tier09"] = "a",
	["Grade_Tier10"] = "a-minus",
	["Grade_Tier11"] = "b-plus",
	["Grade_Tier12"] = "b",
	["Grade_Tier13"] = "b-minus",
	["Grade_Tier14"] = "c-plus",
	["Grade_Tier15"] = "c",
	["Grade_Tier16"] = "c-minus",
	["Grade_Tier17"] = "d",["Grade_Tier18"] = "d",["Grade_Tier19"] = "d",["Grade_Tier20"] = "d",
	["Grade_Tier99"] = "q",
	["Grade_Failed"] = "f"
}

if FILEMAN:DoesFileExist(THEME:GetCurrentThemeDirectory().."Graphics/_grades/"..design.."/"..grds[grade]..".lua") and grds[grade] ~= "star" then
	return Def.ActorFrame{LoadActor(THEME:GetPathG("","_grades/"..design.."/"..grds[grade]..".lua"), pss)..{OnCommand=function(self) self:zoom(0.85) end}}
elseif FILEMAN:DoesFileExist(THEME:GetCurrentThemeDirectory().."Graphics/_grades/"..design.."/"..grade..".lua") then
	return Def.ActorFrame{LoadActor(THEME:GetPathG("","_grades/"..design.."/"..grade..".lua"), pss)..{OnCommand=function(self) self:zoom(0.85) end}}
end

local img = "./assets/"..grds[grade]..".png"
local avl = false
local grd = "Grade_Failed"

local function CheckAvailability(g)
	img = "./assets/"..grds[g]..".png"
	avl = true
	if design ~= "Default" then
		if design == "Default (Outlined)" then
			img = "./assets/outlined/"..grds[g]..".png"
			avl = true
		elseif FILEMAN:DoesFileExist(THEME:GetCurrentThemeDirectory().."Graphics/_grades/"..design.."/"..grds[g]..".png") then
			img = "./"..design.."/"..grds[g]..".png"
			avl = true
		elseif FILEMAN:DoesFileExist(THEME:GetCurrentThemeDirectory().."Graphics/_grades/"..design.."/"..g..".png") then
			img = "./"..design.."/"..g..".png"
			avl = true
		else avl = false end
	end
	if avl then grd = g end
end

-- "I passd with a q though."
if q and GAMESTATE:GetCurrentSong():GetDisplayFullTitle() == "D" then
	CheckAvailability("Grade_Tier99")
end
if not avl then CheckAvailability(grade) end

local function Spin(self)
	r = math.min(math.random(3,51),36)
	s = math.random()*7+1
	z = self:GetZ()
	l = r/36

	if z >= 36 then
		z = z-36
		self:z(z)
		self:rotationz(z*10)
	end

	z = z + r
	self:linear(l)
	self:rotationz(z*10)
	self:z(z)
	self:sleep(s)
	self:queuecommand("Spin")
end

local t = Def.ActorFrame{}

if grds[grade] ~= "star" then
	t[#t+1] = LoadActor(img)..{ OnCommand=function(self) self:zoom(0.85) end }
elseif grade == "Grade_Tier03" then
	t[#t+1] = LoadActor("star.lua", {pss, img})..{
		OnCommand=function(self) self:x(-39):y(40):zoom(0.6):pulse():effectmagnitude(1,0.9,0) end
	}
	t[#t+1] = LoadActor("star.lua", {pss, img})..{
		OnCommand=function(self) self:x(39):y(-40):zoom(0.6):effectoffset(0.2):pulse():effectmagnitude(0.9,1,0) end
	}
elseif grade == "Grade_Tier02" then
	t[#t+1] = LoadActor("star.lua", {pss, img})..{
		OnCommand=function(self) self:x(-45):y(40):zoom(0.5):pulse():effectmagnitude(1,0.9,0) end
	}
	t[#t+1] = LoadActor("star.lua", {pss, img})..{
		OnCommand=function(self) self:x(0):y(-40):zoom(0.5):effectoffset(0.2):pulse():effectmagnitude(0.9,1,0) end
	}
	t[#t+1] = LoadActor("star.lua", {pss, img})..{
		OnCommand=function(self) self:x(45):y(40):zoom(0.5):effectoffset(0.4):pulse():effectmagnitude(0.9,1,0) end
	}
elseif grade == "Grade_Tier01" then
	t[#t+1] = LoadActor("star.lua", {pss, img})..{ --top left
		OnCommand=function(self) self:x(-46):y(-46):zoom(0.5):pulse():effectmagnitude(1,0.9,0):sleep(60):queuecommand("Spin") end,
		SpinCommand=function(self) Spin(self) end
	}
	t[#t+1] = LoadActor("star.lua", {pss, img})..{ --top right
		OnCommand=function(self) self:x(46):y(-46):zoom(0.5):effectoffset(0.2):pulse():effectmagnitude(0.9,1,0):sleep(3):queuecommand("Spin") end,
		SpinCommand=function(self) Spin(self) end
	}
	t[#t+1] = LoadActor("star.lua", {pss, img})..{ -- bottom left
		OnCommand=function(self) self:x(-46):y(46):zoom(0.5):effectoffset(0.4):pulse():effectmagnitude(0.9,1,0):sleep(11):queuecommand("Spin") end,
		SpinCommand=function(self) Spin(self) end
	}
	t[#t+1] = LoadActor("star.lua", {pss, img})..{ --  bottom right
		OnCommand=function(self) self:x(46):y(46):zoom(0.5):effectoffset(0.6):pulse():effectmagnitude(1,0.9,0):sleep(48):queuecommand("Spin") end,
		SpinCommand=function(self) Spin(self) end
	}
elseif grade == "Grade_Tier00" then
	t[#t+1] = LoadActor("star.lua", {pss, img})..{ --top middle
		OnCommand=function(self) self:x(0):y(-54):zoom(0.35):pulse():effectmagnitude(1,0.9,0):sleep(5):queuecommand("Spin") end,
		SpinCommand=function(self) Spin(self) end
	}
	t[#t+1] = LoadActor("star.lua", {pss, img})..{ --top left
		OnCommand=function(self) self:x(-52):y(-16):zoom(0.35):pulse():effectmagnitude(1,0.9,0):sleep(60):queuecommand("Spin") end,
		SpinCommand=function(self) Spin(self) end
	}
	t[#t+1] = LoadActor("star.lua", {pss, img})..{ --top right
		OnCommand=function(self) self:x(52):y(-16):zoom(0.35):effectoffset(0.2):pulse():effectmagnitude(0.9,1,0):sleep(3):queuecommand("Spin") end,
		SpinCommand=function(self) Spin(self) end
	}
	t[#t+1] = LoadActor("star.lua", {pss, img})..{ -- bottom left
		OnCommand=function(self) self:x(-32):y(50):zoom(0.35):effectoffset(0.4):pulse():effectmagnitude(0.9,1,0):sleep(11):queuecommand("Spin") end,
		SpinCommand=function(self) Spin(self) end
	}
	t[#t+1] = LoadActor("star.lua", {pss, img})..{ --  bottom right
		OnCommand=function(self) self:x(32):y(50):zoom(0.35):effectoffset(0.6):pulse():effectmagnitude(1,0.9,0):sleep(48):queuecommand("Spin") end,
		SpinCommand=function(self) Spin(self) end
	}
else -- Grade_Tier04 (one star)
	t[#t+1] = Def.ActorFrame{ LoadActor("star.lua", {pss, img})..{ OnCommand=function(self) self:pulse():effectmagnitude(1,0.9,0) end } }
end

return t