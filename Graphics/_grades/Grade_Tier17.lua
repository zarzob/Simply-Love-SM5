if ThemePrefs.Get("OutlineGrade") then
	return LoadActor("./assets/outlined/d.png")..{ 	OnCommand=function(self) self:zoom(0.85) end }
else
	return LoadActor("./assets/d.png")..{ 	OnCommand=function(self) self:zoom(0.85) end }
end