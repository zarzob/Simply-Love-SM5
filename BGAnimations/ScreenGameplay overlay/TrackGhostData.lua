------------------------------------------------------------
-- This file keeps track of realtime ITG and EX dance points for Subtractive Scoring
-- This needs to record regardless of if the user has subtractive scoring enabled or not.
-- If the user passed, it will compare ITG and EX and update ghost data if necessary
------------------------------------------------------------

-- don't bother tracking for Casual gamemode
if SL.Global.GameMode == "Casual" then return end

local player = ...

local pn = ToEnumShortString(player)
local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
SL[pn].CurrentSongJudgments = {}
SL[pn].CurrentSongJudgments.ITG = {}
SL[pn].CurrentSongJudgments.EX = {}
local itg = SL[pn].CurrentSongJudgments.ITG
local ex = SL[pn].CurrentSongJudgments.EX


local currentdp_itg = 0
local currentdp_ex = 0
local game = SL.Global.GameMode

local valid_tns = {
	-- Emulated, not a real TNS.
	W0 = true,
	W015 = true,

	-- Actual TNS's
	W1 = true,
	W2 = true,
	W3 = true,
	W4 = true,
	W5 = true,
	Miss = true,
	HitMine = true
}

local valid_hns = {
	LetGo = true,
	Held = true
}

return Def.Actor{
	JudgmentMessageCommand=function(self, params)
		if params.Player ~= player then return end
		if IsAutoplay(player) then return end

		if params.HoldNoteScore then
			local HNS = ToEnumShortString(params.HoldNoteScore)
			-- Only track the HoldNoteScores we care about
			if valid_hns[HNS] then
				if not stats:GetFailed() then
					-- ITG
					currentdp_itg = currentdp_itg + SL["Metrics"][game]["GradeWeight"..HNS]
					-- EX
					currentdp_ex = currentdp_ex + SL["ExWeights"][HNS]
				end
			end
		-- HNS also contain TNS. We don't want to double count so add an else if.
	elseif params.TapNoteScore then
		local TNS = ToEnumShortString(params.TapNoteScore)
		if valid_tns[TNS] then
			-- ITG
			currentdp_itg = currentdp_itg + SL["Metrics"][game]["GradeWeight"..TNS]

			-- EX
			if SL.Global.GameMode == "ITG" then
				if TNS == "W1" then
					-- Check if this W1 is actually in the W0 window
					local is_W0 = IsW0Judgment(params, player)
					if is_W0 then
						if not stats:GetFailed() then
							currentdp_ex = currentdp_ex + SL["ExWeights"]["W0"]
						end
					elseif is_W015 then
						if not stats:GetFailed() then
							currentdp_ex = currentdp_ex + SL["ExWeights"]["W1"]
						end
					else
						if not stats:GetFailed() then
							currentdp_ex = currentdp_ex + SL["ExWeights"][TNS]
						end
					end
				else
					-- Only track the TapNoteScores we care about
					if valid_tns[TNS] then
						if not stats:GetFailed() then
							currentdp_ex = currentdp_ex + SL["ExWeights"][TNS]
						end
					end
				end
			else
				adjusted_TNS = TNS
				tier = string.match(TNS, "W(%d)")

				-- In FA+ mode, we need to shift the windows up 1 so that the key we're using is accurate.
				-- E.g. W1 window becomes W0, W2 becomes W1, etc.
				if tier ~= nil then
					adjusted_TNS = "W"..(tonumber(tier)-1)
				end
				
				-- Only track the TapNoteScores we care about
				if valid_tns[adjusted_TNS] then
					if not stats:GetFailed() then
						-- 10ms logic for FA+ mode
						if adjusted_TNS == "W0" and SL[pn].ActiveModifiers.SmallerWhite then
							local is_W0 = IsW0Judgment(params, player)
							if is_W0 then
								currentdp_ex = currentdp_ex + SL["ExWeights"]["W0"]
							end
						else
							if adjusted_TNS == "W0" then
								currentdp_ex = currentdp_ex + SL["ExWeights"]["W0"]
							end
							count_updated = true
						end
					end
				end
			end
			itg[#itg+1] = currentdp_itg
			ex[#ex+1] = currentdp_ex
			--storage[#storage+1] = { currentdp_itg, currentdp_ex } 
			--SM("itg = " .. currentdp_itg .. " / ex = " .. currentdp_ex)
		end
		
	end

			--- my stuff
		-- if tns then
		-- 	if not (tns == "AvoidMine") then
		-- 		-- ITG
				--currentdp_itg = currentdp_itg + SL["Metrics"][game]["GradeWeight"..tns]

				-- EX
				-- if valid_tns(tns) then
				-- 	if game == "ITG" then 						
				-- 		if valid(tns) then 
				-- 			if tns == "W1" then
				-- 				-- Check if this W1 is actually in the W0 window
				-- 				local is_W0 = IsW0Judgment(params, player)
				-- 				if is_W0 then tns = "W0" else tns = "W1" end
				-- 			end							
				-- 		end
				-- 		SM(params)
				-- 		currentdp_ex = currentdp_ex + SL["ExWeights"][tns]
				-- 	else
				-- 		if tns == "W1" then tns = "W0" end 
				-- 		if tns == "W2" then tns = "W1" end 
				-- 		if tns == "W3" then tns = "W2" end 
				-- 		if tns == "W4" then tns = "W3" end 
				-- 		if tns == "W5" then tns = "W4" end 
				-- 		currentdp_ex = currentdp_ex + SL["ExWeights"][tns]
				-- 	end
				-- end
		-- 	end			
		-- end 
		-- if hns and not (hns == "MissedHold") then
		-- 	currentdp_itg = currentdp_itg + SL["Metrics"][game]["GradeWeight"..hns]
		-- 	-- Calculate EX dance points
		-- end 
		-- storage[#storage+1] = { itg = currentdp_itg, ex = currentdp_ex}
		--SM(currentdp_ex)

		-- local count_updated = false
		-- if params.HoldNoteScore then
		-- 	local HNS = ToEnumShortString(params.HoldNoteScore)
		-- 	-- Only track the HoldNoteScores we care about
		-- 	if valid_hns[HNS] then
		-- 		if not stats:GetFailed() then
		-- 			storage.ex_counts[HNS] = storage.ex_counts[HNS] + 1
		-- 			count_updated = true
		-- 		end
		-- 	end
		-- -- HNS also contain TNS. We don't want to double count so add an else if.
		-- elseif params.TapNoteScore then
		-- 	local TNS = ToEnumShortString(params.TapNoteScore)

		-- 	if SL.Global.GameMode == "ITG" then
		-- 		if TNS == "W1" then
		-- 			-- Check if this W1 is actually in the W0 window
		-- 			local is_W0 = IsW0Judgment(params, player)
		-- 			local is_W015 = IsW015Judgment(params, player)
		-- 			if is_W0 then
		-- 				if not stats:GetFailed() then
		-- 					storage.ex_counts.W0 = storage.ex_counts.W0 + 1
		-- 					storage.ex_counts.W015 = storage.ex_counts.W015 + 1
		-- 					count_updated = true
		-- 				end
		-- 				storage.ex_counts.W0_total = storage.ex_counts.W0_total + 1
		-- 				storage.ex_counts.W015_total = storage.ex_counts.W015_total + 1
		-- 			elseif is_W015 then
		-- 				if not stats:GetFailed() then
		-- 					storage.ex_counts.W015 = storage.ex_counts.W015 + 1
		-- 					count_updated = true
		-- 				end
		-- 				storage.ex_counts.W015_total = storage.ex_counts.W015_total + 1
		-- 			else
		-- 				if not stats:GetFailed() then
		-- 					storage.ex_counts.W1 = storage.ex_counts.W1 + 1
		-- 					count_updated = true
		-- 				end
		-- 			end
		-- 		else
		-- 			-- Only track the TapNoteScores we care about
		-- 			if valid_tns[TNS] then
		-- 				if not stats:GetFailed() then
		-- 					storage.ex_counts[TNS] = storage.ex_counts[TNS] + 1
		-- 					count_updated = true
		-- 				end
		-- 			end
		-- 		end
		-- 	else
		-- 		adjusted_TNS = TNS
		-- 		tier = string.match(TNS, "W(%d)")

		-- 		-- In FA+ mode, we need to shift the windows up 1 so that the key we're using is accurate.
		-- 		-- E.g. W1 window becomes W0, W2 becomes W1, etc.
		-- 		if tier ~= nil then
		-- 			adjusted_TNS = "W"..(tonumber(tier)-1)
		-- 		end
				
		-- 		-- Only track the TapNoteScores we care about
		-- 		if valid_tns[adjusted_TNS] then
		-- 			if not stats:GetFailed() then
		-- 				-- 10ms logic for FA+ mode
		-- 				if adjusted_TNS == "W0" and SL[pn].ActiveModifiers.SmallerWhite then
		-- 					local is_W0 = IsW0Judgment(params, player)
		-- 					if is_W0 then
		-- 						storage.ex_counts["W0"] = storage.ex_counts["W0"] + 1
		-- 						storage.ex_counts["W015"] = storage.ex_counts["W015"] + 1
		-- 					else
		-- 						storage.ex_counts["W1"] = storage.ex_counts["W1"] + 1
		-- 						storage.ex_counts["W015"] = storage.ex_counts["W015"] + 1
		-- 					end
		-- 					count_updated = true
		-- 				else
		-- 					storage.ex_counts[adjusted_TNS] = storage.ex_counts[adjusted_TNS] + 1
		-- 					if adjusted_TNS == "W0" then
		-- 						storage.ex_counts["W015"] = storage.ex_counts["W015"] + 1
		-- 					end
		-- 					count_updated = true
		-- 				end
		-- 			end
		-- 		end
		-- 	end
		-- end
		-- if count_updated then
		-- 	-- Broadcast so other elements on ScreenGameplay can process the updated count.
		-- 	local ExScore, actual_points, actual_possible=CalculateExScore(player)

		-- 	MESSAGEMAN:Broadcast(
		-- 		"ExCountsChanged",
		-- 		{
		-- 			Player=player, 
		-- 			ExCounts=storage.ex_counts, 
		-- 			ExScore=CalculateExScore(player), 
		-- 			actual_points=actual_points, 
		-- 			actual_possible=actual_possible 
		-- 		}
		-- 	)
		-- end
	end,
}