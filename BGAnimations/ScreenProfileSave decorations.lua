return Def.ActorFrame{
	Def.Actor{
		BeginCommand=function(self)
			self:queuecommand("Load")
		end,
		LoadCommand=function()
			if SL.NewDownloadsCompleted and SCREENMAN:GetTopScreen():GetNextScreenName() == "ScreenSelectMusic" then
				SL.NewDownloadsCompleted = false
				SCREENMAN:GetTopScreen():SetNextScreenName("ScreenReloadSongsSSM")
			end
			if SCREENMAN:GetTopScreen():GetNextScreenName() == "ScreenSelectMusic" or SCREENMAN:GetTopScreen():GetNextScreenName() == "ScreenSelectCourse" then
				SaveProfileEXP(PLAYER_1)
				SaveProfileEXP(PLAYER_2)
			end
			SCREENMAN:GetTopScreen():Continue()
		end
	}
}
