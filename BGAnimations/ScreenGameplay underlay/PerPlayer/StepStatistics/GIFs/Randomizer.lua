local GIFdir = THEME:GetCurrentThemeDirectory() .. "BGAnimations/ScreenGameplay underlay/PerPlayer/StepStatistics/GIFs/"
local GIFs = findFiles(GIFdir, "lua")

t = Def.ActorFrame {
	local rand = GIFs[math.random(1,#GIFs)]
	while rand == "Randomizer"
		rand = GIFs[math.random(1,#GIFs)]
	end
	LoadActor(GIFs[math.random(1,#GIFs)])
}

return t