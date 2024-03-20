t = Def.ActorFrame {}

t[#t+1] = Def.Sprite {
	
	Texture="Internet Yamero 5x4.png",
	Frame0000=4,	Delay0000=0.2,
	Frame0001=5,	Delay0001=0.2,
	Frame0002=6,	Delay0002=0.2,
	Frame0003=7,	Delay0003=0.2,
	Frame0004=8,	Delay0004=0.2,
	Frame0005=9,	Delay0005=0.2,
	Frame0006=10,	Delay0006=0.2,
	Frame0007=11,	Delay0007=0.2,
	Frame0008=12,	Delay0008=0.2,
	Frame0009=13,	Delay0009=0.2,
	Frame0010=14,	Delay0010=0.2,
	Frame0011=15,	Delay0011=0.2,
	Frame0012=16,	Delay0012=0.2,
	Frame0013=17,	Delay0013=0.2,
	Frame0014=18,	Delay0014=0.2,
	Frame0015=19,	Delay0015=0.2,
	Frame0016=0,	Delay0016=0.2,
	Frame0017=1,	Delay0017=0.2,
	Frame0018=2,	Delay0018=0.2,
	Frame0019=3,	Delay0019=0.2,
	
	OnCommand=function(self)
		self:effectclock("bgm")
		self:zoom(0.6)
	end
	
}

return t