-- -----------------------------------------------------------------------
-- Difficulty colors, in the order of Beginner, Easy, Medium, Hard, Expert, Edit

SLCustom.DiffColors = SLCustom.InitTable({
	{
		name = "Simply Love", -- Default difficulty colors for the Simply Love theme
		custom = nil
	},
	{
		name = "ITG", -- Colors used by ITG for difficulties
		custom = {{"#a355b8", "#1ec51d", "#d6db41", "#ba3049", "#2691c5", "#f7f7f7"}, true} -- Extra true after the difficulty colors indicates the colors should be made brighter in-game
	},
	{
		name = "DDR",
		custom = {{"#2dccef", "#eaa910", "#ff344d", "#30d81e", "#e900ff", "#f7f7f7"}}
	},
	{
		name = "Waterfall",
		custom = {{"#80ffff", "#80ff80", "#ffff80", "#ff8080", "#ff80ff", "#b4b7ba"}}
	},
})
