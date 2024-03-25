local GIFdir = THEME:GetCurrentThemeDirectory() .. "BGAnimations/ScreenGameplay underlay/PerPlayer/StepStatistics/GIFs/"
local GIFs = findFiles(GIFdir, "lua")

t = Def.ActorFrame {
	LoadActor(GIFs[math.random(1,#GIFs)])
}

return t