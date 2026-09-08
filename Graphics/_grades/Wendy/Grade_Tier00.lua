local t = Def.ActorFrame{}
local p = {{0,-60},{-80,-10},{80,-10},{-48,65},{48,65}}

for i=1,#p do
 t[#t+1] = LoadActor("star.png")..{OnCommand=function(self) self:xy(p[i][1],p[i][2]):zoom(0.5):bob():effectmagnitude(0,5.5,0):effectoffset(math.random()*3.6):effecttiming(1.8) end}
end

return t