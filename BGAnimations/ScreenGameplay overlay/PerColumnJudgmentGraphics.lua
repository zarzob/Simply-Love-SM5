local player = ...
local pn = ToEnumShortString(player)

local mods = SL[pn].ActiveModifiers
if SL.Global.GameMode == "Casual" then return end

local column_mapping = GetColumnMapping(player)

-- Disable column cues if we couldn't compute valid column_mapping
if column_mapping == nil then return end

local playerState = GAMESTATE:GetPlayerState(player)

local numColumns = GAMESTATE:GetCurrentStyle():ColumnsPerPlayer()
local style = GAMESTATE:GetCurrentStyle(player)
local width = style:GetWidth(player)

local yOffset = 50
local zoom_factor = 1 - scale( mods.Mini:gsub("%%","")/100, 0, 2, 0, 1)

local available_graphics = GetHeldMissGraphics()
local held_to_load = (FindInTable(mods.HeldGraphic, available_graphics) ~= nil and mods.HeldGraphic or available_graphics[1]) or "None"

local TNSFrames = {
	TapNoteScore_W1 = 0,
	TapNoteScore_W2 = 1,
	TapNoteScore_W3 = 2,
	TapNoteScore_W4 = 3,
	TapNoteScore_W5 = 4,
	TapNoteScore_Miss = 5,
	TapNoteScore_CheckpointHit = -1,
	TapNoteScore_CheckpointMiss = 5
}
local available_judgments = GetJudgmentGraphics()
local judgments_to_load = (FindInTable(mods.JudgmentGraphic, available_judgments) ~= nil and mods.JudgmentGraphic or available_judgments[1]) or "None"

if held_to_load == "None" and judgments_to_load == "None" then
	return Def.Actor{
		InitCommand=function(self) self:visible(false) end
	}
end

local af = Def.ActorFrame{
	InitCommand=function(self)
		local opts = GAMESTATE:GetPlayerState(player):GetCurrentPlayerOptions()
		self:xy( GetNotefieldX(player), (opts:Reverse() == 1) and yOffset*2+10 or -yOffset)
		self:zoomx( zoom_factor )
	end,
}

local IsReversedColumn = function(player, columnIndex)
	local columns = {}
	for i=1, numColumns do
		columns[#columns + 1] = false
	end

	local opts = GAMESTATE:GetPlayerState(player):GetCurrentPlayerOptions()
	if opts:Reverse() == 1 then
		for column,val in ipairs(columns) do
			columns[column] = not val
		end
	end

	if opts:Alternate() == 1 then
		for column,val in ipairs(columns) do
			if column % 2 == 0 then
				columns[column] = not val
			end
		end
	end

	if opts:Split() == 1 then
		for column,val in ipairs(columns) do
			if column > numColumns / 2 then
				columns[column] = not val
			end
		end
	end

	if opts:Cross() == 1 then
		local firstChunk = numColumns / 4
		local lastChunk = numColumns - firstChunk
		for column,val in ipairs(columns) do
			if column > firstChunk and column <= lastChunk then
				columns[column] = not val
			end
		end
	end

	return columns[columnIndex]
end

for columnIndex=1,numColumns do
	local held_sprite, judgment_sprite
	af[#af+1] = Def.ActorFrame{
		Name="Column"..columnIndex,
		InitCommand=function(self)
			self:x((columnIndex - (numColumns/2 + 0.5)) * (width/numColumns))
					:vertalign('VertAlign_Top')
					:setsize(width/numColumns, _screen.h - yOffset)
			
			local spacing = mods.Spacing:gsub("%%","")/100
			self:addx((columnIndex - (numColumns/2 + 0.5))*2 * (width/numColumns) * spacing)
					
			local kids = self:GetChildren()
			held_sprite = kids.HeldMiss
			judgment_sprite = kids.Judgment
			
			local mini = mods.Mini:gsub("%%","") / 100
			held_sprite:SetHeight(held_sprite:GetHeight() * (1 - mini/2))
			judgment_sprite:SetHeight(judgment_sprite:GetHeight() * (1 - mini/2))
		end,
		JudgmentMessageCommand=function(self, param)
			if param.Player ~= player then return end
			if not param.TapNoteScore then return end
			if param.HoldNoteScore then return end

			local tns = ToEnumShortString(param.TapNoteScore)
			
			if tns == "Miss" and held_to_load ~= "None" then
				for col,tapnote in pairs(param.Notes) do
					local tnt = ToEnumShortString(tapnote:GetTapNoteType())
					if tnt == "Tap" or tnt == "HoldHead" or tnt == "Lift" then
						local tns = ToEnumShortString(param.TapNoteScore)
						if tnt ~= "Lift" and tns == "Miss" and tapnote:GetTapNoteResult():GetHeld() and ("Column"..col) == self:GetName() then
							held_sprite:visible(true)
							held_sprite:finishtweening():stopeffect()
							-- this should match the custom JudgmentTween() from SL for 3.95
							local mini = mods.Mini:gsub("%%","") / 100
							SLCustom.JudgmentAnimations[SL[pn].ActiveModifiers.HeldAnimation](held_sprite, "HeldMiss", 0.75, 1)
						end
					end
				end
			end
		end,
		EarlyHitMessageCommand=function(self, param)
			if param.Player ~= player then return end
			if not param.TapNoteScore then return end
			if param.HoldNoteScore then return end

			local tns = ToEnumShortString(param.TapNoteScore)
			
			if (tns == "W4" or tns == "W5") and judgments_to_load ~= "None" and mods.ShowEarlyDecentWayOffColumn then
				-- "frame" is the number we'll use to display the proper portion of the judgment sprite sheet
				-- Sprite actors expect frames to be 0-indexed when using setstate() (not 1-indexed as is more common in Lua)
				-- an early W1 judgment would be frame 0, a late W2 judgment would be frame 3, and so on
				local frame = TNSFrames[ param.TapNoteScore ]
				if not frame then return end

				-- If the judgment font contains a graphic for the additional white fantastic window...
				if judgment_sprite:GetNumStates() == 7 or judgment_sprite:GetNumStates() == 14 then
					-- Everything outside of W1 needs to be shifted down a row if not in FA+ mode.
					-- Some people might be using 2x7s in FA+ mode (by copying ITG graphics to FA+).
					-- In that case, we need to shift the Way Off down to a Miss
					frame = frame + 1
				end


				-- most judgment sprite sheets have 12 or 14 frames; 6/7 for early judgments, 6/7 for late judgments
				-- some (the original 3.9 judgment sprite sheet for example) do not visibly distinguish
				-- early/late judgments, and thus only have 6/7 frames
				if judgment_sprite:GetNumStates() == 12 or judgment_sprite:GetNumStates() == 14 or judgment_sprite:GetNumStates() == 22 then
					frame = frame * 2
				end
				
				local tns = ToEnumShortString(param.TapNoteScore)
				if ("Column"..(param.Column + 1)) == self:GetName() then
					judgment_sprite:visible(true):setstate(frame)
					judgment_sprite:finishtweening():stopeffect()
					-- this should match the custom JudgmentTween() from SL for 3.95
					local mini = mods.Mini:gsub("%%","") / 100
					if SL[pn].ActiveModifiers.JudgmentAnimation == "Default" then
						judgment_sprite:zoom(0.325):zoomx(0.4):decelerate(0.1):zoomx(0.325):sleep(0.2):accelerate(0.2):zoom(0)
					else
						SLCustom.JudgmentAnimations[SL[pn].ActiveModifiers.JudgmentAnimation](judgment_sprite, tns, 0.325, 1)
					end
				end
			end
		end,
		Def.Sprite{
			Name="HeldMiss",
			InitCommand=function(self)
				-- animate(false) is needed so that this held_sprite does not automatically
				-- animate its way through all available frames; we want to control which
				-- frame displays based on what judgment the player earns
				self:animate(false):visible(false)

				local mini = mods.Mini:gsub("%%","") / 100
				self:addx(((mods.NoteFieldOffsetX * -1) * (1 + mini)) * 2)
				self:addy((mods.NoteFieldOffsetY * (1 + mini)) * 2)
				
				-- if we are on ScreenEdit, judgment graphic is always "Love"
				-- because ScreenEdit is a mess and not worth bothering with.
				if string.match(tostring(SCREENMAN:GetTopScreen()), "ScreenEdit") then
					self:Load( THEME:GetPathG("", "_HeldMiss/Love") )
				elseif held_to_load ~= "None" then
					self:Load( THEME:GetPathG("", "_HeldMiss/" .. held_to_load) )
				end
			end,
		},
		Def.Sprite{
			Name="Judgment",
			InitCommand=function(self)
				-- animate(false) is needed so that this held_sprite does not automatically
				-- animate its way through all available frames; we want to control which
				-- frame displays based on what judgment the player earns
				self:animate(false):visible(false)
				
				-- if we are on ScreenEdit, judgment graphic is always "Love"
				-- because ScreenEdit is a mess and not worth bothering with.
				if string.match(tostring(SCREENMAN:GetTopScreen()), "ScreenEdit") then
					self:Load( THEME:GetPathG("", "_judgments/Love") )

				else
					self:Load( THEME:GetPathG("", "_judgments/" .. judgments_to_load) )
				end
			end,
		},
	}
end

return af
