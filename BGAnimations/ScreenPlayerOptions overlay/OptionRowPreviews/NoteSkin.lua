local t = ...

-- Add noteskin actors to the primary AF and hide them immediately.
-- We'll refer to these later via ActorProxy in ./Graphics/OptionRow Frame.lua
for noteskin in ivalues( CustomOptionRow("NoteSkin").Choices ) do
	local arrows = Def.ActorFrame{
		Name="NoteSkin_"..noteskin,
		InitCommand=function(self)
			self:visible(false)
		end
	}
	t[#t+1] = arrows
	arrows[#arrows+1] = LoadActor(THEME:GetPathB("","_modules/NoteSkinPreview.lua"), {noteskin_name=noteskin,column="Left",offset=-96,quant=0})
	arrows[#arrows+1] = LoadActor(THEME:GetPathB("","_modules/NoteSkinPreview.lua"), {noteskin_name=noteskin,column="Down",offset=-32,quant=1})
	arrows[#arrows+1] = LoadActor(THEME:GetPathB("","_modules/NoteSkinPreview.lua"), {noteskin_name=noteskin,column="Up",offset=32,quant=3})
	arrows[#arrows+1] = LoadActor(THEME:GetPathB("","_modules/NoteSkinPreview.lua"), {noteskin_name=noteskin,column="Right",offset=96,quant=2})
end