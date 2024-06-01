local sort_wheel = ...

-- this handles user input while in the SortMenu
local input = function(event)
	if not (event and event.PlayerNumber and event.button) then
		return false
	end
	SOUND:StopMusic()
	local screen   = SCREENMAN:GetTopScreen()
	local overlay  = screen:GetChild("Overlay")
	local sortmenu = overlay:GetChild("SortMenu")
	if event.type ~= "InputEventType_Release" then
		if event.GameButton == "MenuRight" or event.GameButton == "MenuDown" then
			sort_wheel:scroll_by_amount(1)
			sortmenu:GetChild("change_sound"):play()
		elseif event.GameButton == "MenuLeft" or event.GameButton == "MenuUp" then
			sort_wheel:scroll_by_amount(-1)
			sortmenu:GetChild("change_sound"):play()
		elseif event.GameButton == "Start" then
			sortmenu:GetChild("start_sound"):play()
			local focus = sort_wheel:get_actor_item_at_focus_pos()
			if focus.kind == "SortBy" then
				MESSAGEMAN:Broadcast('Sort', { order = focus.sort_by })
				MESSAGEMAN:Broadcast('ResetHeaderText')
				overlay:queuecommand("DirectInputToEngine")

				-- the player wants to change modes, for example from ITG to FA+
			elseif focus.kind == "ChangeMode" then
				SL.Global.GameMode = focus.change
				for player in ivalues(GAMESTATE:GetHumanPlayers()) do
					ApplyMods(player)
				end
				SetGameModePreferences()
				THEME:ReloadMetrics()
				-- Broadcast that the SL GameMode has changed
				-- SSM's header will update its text and highscore names in the PaneDisplays will refresh
				MESSAGEMAN:Broadcast("SLGameModeChanged")
				-- Reload the SortMenu's available options and queue "DirectInputToEngine"
				-- to return input from Lua back to the engine and hide the SortMenu from view
				sortmenu:playcommand("AssessAvailableChoices"):queuecommand("DirectInputToEngine")
				-- the player is switching to casual mode which uses a different SelectMusic screen
				if focus.change == "Casual" then
					screen:SetNextScreenName("ScreenSelectMusicCasual")
					screen:StartTransitioningScreen("SM_GoToNextScreen")
				end
				-- the player wants to change styles, for example from single to double
			elseif focus.kind == "ChangeStyle" then
				-- If the MenuTimer is in effect, we need to make sure the current number of seconds
				-- remaining is preserved so we can reinstate it later. ShowPressStartForOptions
				-- will save the current number of seconds before transitioning to the next screen.
				if PREFSMAN:GetPreference("MenuTimer") then
					overlay:playcommand("ShowPressStartForOptions")
				end
				-- Get the style we want to change to
				local new_style = focus.change:lower()
				-- accommodate techno game
				if GAMESTATE:GetCurrentGame():GetName() == "techno" then new_style = new_style .. "8" end
				-- set it in the engine
				GAMESTATE:SetCurrentStyle(new_style)
				-- Make sure we cancel the request if it's active before trying to switch screens.
				-- This prevents the "Stale ActorFrame" error.
				overlay:GetChild("PaneDisplayMaster"):GetChild("GetScoresRequester"):playcommand("Cancel")
				-- finally, reload the screen
				screen:SetNextScreenName("ScreenReloadSSM")
				screen:StartTransitioningScreen("SM_GoToNextScreen")
			elseif focus.new_overlay then
				if focus.new_overlay == "TestInput" then
					sortmenu:queuecommand("DirectInputToTestInput")
				elseif focus.new_overlay == "Leaderboard" then
					-- The leaderboard entry is removed altogether if the service isn't available.
					sortmenu:queuecommand("DirectInputToLeaderboard")
				elseif focus.new_overlay == "SongSearch" then
					-- Direct the input back to the engine, so that the ScreenTextEntry overlay
					-- works correctly.
					overlay:queuecommand("DirectInputToEngineForSongSearch")
				elseif focus.new_overlay == "LoadNewSongs" then
					-- Make sure we cancel the request if it's active before trying to switch screens.
					-- This prevents the "Stale ActorFrame" error.
					overlay:GetChild("PaneDisplayMaster"):GetChild("GetScoresRequester"):playcommand("Cancel")
					overlay:playcommand("DirectInputToEngine")
					SCREENMAN:SetNewScreen("ScreenReloadSongsSSM")
				elseif focus.new_overlay == "ViewDownloads" then
					-- Make sure we cancel the request if it's active before trying to switch screens.
					-- This prevents the "Stale ActorFrame" error.
					overlay:GetChild("PaneDisplayMaster"):GetChild("GetScoresRequester"):playcommand("Cancel")
					overlay:playcommand("DirectInputToEngine")
					SCREENMAN:SetNewScreen("ScreenViewDownloads")
				elseif focus.new_overlay == "SwitchProfile" then
					SL.Global.FastProfileSwitchInProgress = true

					-- Make sure we save any currently active profiles before potentially switching
					-- to different ones.
					GAMESTATE:SaveProfiles()
					PROFILEMAN:SaveMachineProfile()

					overlay:queuecommand("DirectInputToEngineForSelectProfile")
				elseif focus.new_overlay == "AddFavorite" then
					addOrRemoveFavorite(event.PlayerNumber)
					-- Nudge the wheel a bit so that that the icon is correctly updated.
					overlay:queuecommand("DirectInputToEngine")
					local screen = SCREENMAN:GetTopScreen()
					screen:GetMusicWheel():Move(1)
					screen:GetMusicWheel():Move(-1)
					screen:GetMusicWheel():Move(0)
				elseif focus.new_overlay == "Preferred" then
					-- Only allow sorting by favorites if there are favorites available
					if (#SL[ToEnumShortString(event.PlayerNumber)].Favorites > 0) then
						-- The 2nd argument, isAbsolute, is ITGmania 0.6.0 specific. It
						-- allows absolute paths to be used for the favorites file which is
						-- how it works to load from the profile directory.
						SONGMAN:SetPreferredSongs(getFavoritesPath(event.PlayerNumber), --[[isAbsolute=]]true);
						if SONGMAN:GetPreferredSortSongs() then
							overlay:queuecommand("DirectInputToEngine")
							SCREENMAN:GetTopScreen():GetMusicWheel():ChangeSort("SortOrder_Preferred")
						else 
							SM(ToEnumShortString(event.PlayerNumber).." has no favorites!")
						end
					else
						SM("No Favorites Available")
					end
				elseif focus.new_overlay == "CustomPacks" then
					SM(getPackListFiles(event.PlayerNumber))
					local getSort = generatePackList(event.PlayerNumber, "test")
					SONGMAN:SetPreferredSongs(getSort, --[[isAbsolute=]]true);
					overlay:queuecommand("DirectInputToEngine")
					SCREENMAN:GetTopScreen():GetMusicWheel():ChangeSort("SortOrder_Preferred")
				elseif focus.new_overlay == "StaminaSort" then
					local getSort = generatePackList(event.PlayerNumber, "stam")
					SONGMAN:SetPreferredSongs(getSort, --[[isAbsolute=]]true);
					overlay:queuecommand("DirectInputToEngine")
					SCREENMAN:GetTopScreen():GetMusicWheel():ChangeSort("SortOrder_Preferred")
				elseif focus.new_overlay == "TechSort" then
					local getSort = generatePackList(event.PlayerNumber, "tech")
					SONGMAN:SetPreferredSongs(getSort, --[[isAbsolute=]]true);
					overlay:queuecommand("DirectInputToEngine")
					SCREENMAN:GetTopScreen():GetMusicWheel():ChangeSort("SortOrder_Preferred")
				elseif focus.new_overlay == "EventSort" then
					local getSort = generatePackList(event.PlayerNumber, "event")
					SONGMAN:SetPreferredSongs(getSort, --[[isAbsolute=]]true);
					overlay:queuecommand("DirectInputToEngine")
					SCREENMAN:GetTopScreen():GetMusicWheel():ChangeSort("SortOrder_Preferred")
				end
			end

		elseif event.GameButton == "Back" or event.GameButton == "Select" then
			overlay:queuecommand("DirectInputToEngine")
		end
	end
	return false
end
return input
