local AwardMap = {
	["StageAward_FullComboW1"] = 1,
	["StageAward_FullComboW2"] = 2,
	["StageAward_SingleDigitW2"] = 2,
	["StageAward_OneW2"] = 2,
	["StageAward_FullComboW3"] = 3,
	["StageAward_SingleDigitW3"] = 3,
	["StageAward_OneW3"] = 3,
	["StageAward_100PercentW3"] = 3,
	-- FullComboW4 technically doesn't exist, but we create it on the fly below.
	["StageAward_FullComboW4"] = 4,
}

local ClearLamp = { color("#0000CC"), color("#990000") }

local function GetLamp(song)
	if not song then return nil end
	
	if not GAMESTATE:GetCurrentSteps(pn) then return nil end
	
	local diff = GAMESTATE:GetCurrentSteps(pn):GetDifficulty()
	
	local stepsList = song:GetAllSteps()
	local steps = nil
	
	for check in ivalues(stepsList) do
		if check:GetDifficulty() == diff then
			steps = check
			break
		end
	end
	
	if steps == nil then return nil end
	
	local profile = PROFILEMAN:GetProfile(player)
	local high_score_list = profile:GetHighScoreListIfExists(song, steps)
			
	-- If no scores then just return.
	if high_score_list == nil or #high_score_list:GetHighScores() == 0 then
		return nil
	end

	local best_lamp = nil

	for score in ivalues(high_score_list:GetHighScores()) do
		local award = score:GetStageAward()

		if award == nil and SL.Global.GameMode == "FA+" and score:GetGrade() ~= "Grade_Failed" then
			-- Dropping a roll/hold breaks the StageAward, but hitting a mine does not.
			local misses = score:GetTapNoteScore("TapNoteScore_Miss") +
					score:GetHoldNoteScore("HoldNoteScore_LetGo") +
					score:GetTapNoteScore("TapNoteScore_CheckpointMiss")
			if misses + score:GetTapNoteScore("TapNoteScore_W5") == 0 then
				award = "StageAward_FullComboW4"
			end
		end
		
		if award and AwardMap[award] ~= nil then
			best_lamp = math.min(best_lamp and best_lamp or 999, AwardMap[award])
		end
		
		if best_lamp == nil then
			if score:GetGrade() == "Grade_Failed" then best_lamp = 52
			else best_lamp = 51 end
		end
	end

	return best_lamp
end