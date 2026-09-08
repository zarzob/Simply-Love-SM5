local t = Def.ActorFrame{}
local p = {-55,55}

for i=1,#p do
 t[#t+1] = LoadActor("star.png")..{OnCommand=function(self) self:x(p[i]):zoom(0.6):bob():effectmagnitude(0,7,0):effectoffset(math.random()*3.6):effecttiming(1.8) end}
end

return t