t = Def.ActorFrame {}

t[#t+1] = Def.Sprite {
	
	Texture="Flandre 5x6.png",
	Frame0000=14,	Delay0000=0.033,
	Frame0001=15,	Delay0001=0.033,
	Frame0002=16,	Delay0002=0.033,
	Frame0003=17,	Delay0003=0.033,
	Frame0004=18,	Delay0004=0.033,
	Frame0005=19,	Delay0005=0.033,
	Frame0006=20,	Delay0006=0.033,
	Frame0007=21,	Delay0007=0.033,
	Frame0008=22,	Delay0008=0.033,
	Frame0009=23,	Delay0009=0.033,
	Frame0010=24,	Delay0010=0.033,
	Frame0011=25,	Delay0011=0.033,
	Frame0012=26,	Delay0012=0.033,
	Frame0013=27,	Delay0013=0.033,
	Frame0014=28,	Delay0014=0.033,
	Frame0015=29,	Delay0015=0.033,
	Frame0016=0,	Delay0016=0.043,
	Frame0017=1,	Delay0017=0.033,
	Frame0018=2,	Delay0018=0.033,
	Frame0019=3,	Delay0019=0.033,
	Frame0020=4,	Delay0020=0.033,
	Frame0021=5,	Delay0021=0.033,
	Frame0022=6,	Delay0022=0.033,
	Frame0023=7,	Delay0023=0.033,
	Frame0024=8,	Delay0024=0.033,
	Frame0025=9,	Delay0025=0.033,
	Frame0026=10,	Delay0026=0.033,
	Frame0027=11,	Delay0027=0.033,
	Frame0028=12,	Delay0028=0.033,
	Frame0029=13,	Delay0029=0.033,
	
	OnCommand=function(self)
		self:effectclock("bgm")
		self:zoom(0.4)
	end
	
}

return t