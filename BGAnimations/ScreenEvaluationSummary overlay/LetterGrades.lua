local p = ...
if p == nil then p = PLAYER_1 end
local g = SL[ToEnumShortString(p)].ActiveModifiers.GradeDesign

-- hide the entire ActorFrame (and, thus, its children) in the InitCommand
local af = Def.ActorFrame{
	Name="LetterGradesAF_"..ToEnumShortString(p),
	InitCommand=function(self) self:visible(false) end
}

-- how many GradeTiers are defined in Metrics.ini?
local num_grade_tiers = THEME:GetMetric("PlayerStageStats", "NumGradeTiersUsed")

-- Loop num_grade_tiers times, adding each letter grade Actor to this hidden ActorFrame.
-- We won't show these Actors directly; we may not need them all, or we may need some repeatedly.
-- Instead, we'll have an ActorProxy for each player in each StageStats row that will refer to the
-- appropriate letter grade Actor as needed.
for i=0,num_grade_tiers do
	local tier_string = "Grade_Tier"..string.format("%02d",i)
	af[#af+1] = LoadActor( THEME:GetPathG("", "_grades/grade.lua"), {tier_string, g, nil, false})..{ Name=tier_string }
end

-- "Failed" is not a grade tier, but players don't need to worry about such details. :)
af[#af+1] = LoadActor( THEME:GetPathG("", "_grades/grade.lua"), {"Grade_Failed", g, nil, false})..{ Name="Grade_Failed" }

return af