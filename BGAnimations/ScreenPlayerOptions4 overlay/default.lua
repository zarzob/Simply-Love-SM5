local t = Def.ActorFrame{
	InitCommand=function(self) self:xy(_screen.cx,0) end,
	OnCommand=function(self)
		self:diffusealpha(1)
	end,
	OffCommand=function(self) self:linear(0.2):diffusealpha(0) end
}

LoadActor("./OptionRowPreviews/JudgmentAnimation.lua", t)
LoadActor("./OptionRowPreviews/ComboAnimation.lua", t)

t[#t+1] = LoadActor(THEME:GetPathB("ScreenPlayerOptions", "common"))

return t