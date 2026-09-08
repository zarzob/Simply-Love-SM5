local t = Def.ActorFrame{}
local p = {{0,-51},{-58,51},{58,51}}

for i=1,#p do
 t[#t+1] = LoadActor("star.png")..{OnCommand=function(self) self:xy(p[i][1],p[i][2]):zoom(0.6):bob():effectmagnitude(0,7,0):effectoffset(math.random()*3.6):effecttiming(1.8) end}
end

return t