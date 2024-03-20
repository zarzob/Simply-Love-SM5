-- Twitch chat module (Nico Style) for Simply Love
--
-- Copyright (c) 2022 Martin Natano
-- Modification by Zankoku
--
-- Permission to use, copy, modify, and/or distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
-- SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
-- OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
-- CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-------------------------------------------
-------( Configuration Parameters )--------
-------------------------------------------

-- twitch channel, all lower case
local CHANNEL = "sugoifactory"

-- debug flag, keep this off
local DEBUG = false

-- hide silent chat (prefixed with !)
local HIDE_SILENT = true

-- minimum height above the bottom of the screen for the text to appear
local MINIMUM_HEIGHT = 0.5

-- maximum number of messages to display at the same time
local MAXNICO = 20

-- text scroll speed
local SCROLLSPEED = 100

-- maximum text size
local MAXZOOM = 5

-- text opacity
local OPACITY = 80

-- "justinfanNNN" can be used as login name to get anonymous read access to twitch chat.
local NICK = "justinfan" .. tostring(math.floor(MersenneTwister.Random(4096)))
local PASS = CRYPTMAN:GenerateRandomUUID()

local FONT = "Common Normal"

local SHOW_BADGES = true
local SHOW_EMOTES = true

-------------------------------------------
----( End of configuration parameters )----
-------------------------------------------

local BADGES = {
	artist="🖌",
	broadcaster="🎥",
	moderator="🗡",
	no_audio="🔇",
	no_video="👁",
	subscriber="💃",
	vip="💎",
}

local EMOTES = {
	-- ADD YOUR OWN EMOTES HERE

	-- SL specific emotes
	Crab="🦀",
	Snowman="⛄",
	Hug="🤗",
	Thonk="🤔",
	Wave="🌊",
	Burger="🍔",
	Baguette="🥖",
	Strong="💪",
	Lips="👄",
	Rainbow="🌈",
	Copter="🚁",
	Candle="🕯",
	Tulip="🌷",
	Sweat="💦",
	Tower="🗼",
	RedHeart="❤",
	YellowHeart="💛",
	GreenHeart="💚",
	BlueHeart="💙",
	PurpleHeart="💜",
	BlackHeart="🖤",
	Airplane="✈",
	Star="⭐",
	Quad="🌟🌟🌟🌟",
	Tada="🎉",

	-- global twitch emotes
	[":("]="🙁",
	[":-("]="🙁",
	[":)"]="🙂",
	[":-)"]="🙂",
	[":/"]="😕",
	[":\\"]="😕",
	[":-/"]="😕",
	[":-\\"]="😕",
	[":|"]="😐",
	[":-|"]="😐",
	[";)"]="😉",
	[";-)"]="😉",
	[">("]="😠",
	["<3"]="💜",
	["8-)"]="😎",
	["B)"]="😎",
	["B-)"]="😎",
	[":-D"]="😀",
	[":D"]="😀",
	[":-o"]="😮",
	[":o"]="😮",
	[":-O"]="😮",
	[":O"]="😮",
	["o.o"]="👀",
	["o.O"]="👀",
	["O.o"]="👀",
	["O.O"]="👀",
	["o_o"]="👀",
	["o_O"]="👀",
	["O_o"]="👀",
	["O_O"]="👀",
	[":p"]="😛",
	[":P"]="😛",
	[":-p"]="😛",
	[":-P"]="😛",
	[";p"]="😜",
	[";P"]="😜",
	[";-p"]="😜",
	[";-P"]="😜",
	[":-z"]="😑",
	[":z"]="😑",
	[":-Z"]="😑",
	[":Z"]="😑",
	HolidayPresent="🎁",
	HolidayTree="🎄",
	HolidaySanta="🎅",
	PopCorn="🍿",
}


local ws = nil

local nicoNum = 1
local nicos = ""
local nicoLine = {}

local function addMessage(msg)
	if nicoLine[nicoNum] then
		nicos = msg
		nicoLine[nicoNum]:queuecommand("MakeText")
		nicoNum = nicoNum + 1
		if nicoNum > MAXNICO then nicoNum = 1 end
	end
end

local function parseMessage(s)
	if s:sub(1, 5) == "PING " then
		local text = s:sub(6):gsub("[\r\n]*$", "")
		ws:Send("PONG " .. text)
		return
	end


	local _, _, tagsStr, sender, command, paramsStr = string.find(s, "^@([^ ]+) :([^! ]+)!?[^ ]* ([^ ]+) ?(.-)\r\n$")
	if tagsStr == nil or sender == nil or command == nil or paramsStr == nil then
		return
	end

	local tags = {}
	for key, value in string.gmatch(tagsStr, "([^;=]+)=([^;]*)") do
		if value ~= "" then
			tags[key] = value:gsub("\\s", " ")
		end
	end

	if command == "PRIVMSG" then
		local _, _, text = string.find(paramsStr, "^#[^ ]+ :?(.*)$")
		if text == nil then
			return
		end

		if SHOW_EMOTES then
			text = text:gsub("[%w_-<>:;()|/\\]+", EMOTES)
		end

		addMessage({
			type="privmsg",
			sender=sender,
			text=text,
			tags=tags,
		})
	elseif command == "USERNOTICE" then
		if tags["system-msg"] then
			addMessage({
				type="status",
				text=tags["system-msg"],
				msgId=tags["msg-id"],
			})
		end

		local _, _, text = string.find(paramsStr, "^#[^ ]+ :?(.*)$")
		if text then
			addMessage({
				type="privmsg",
				sender=sender,
				text=text,
				tags=tags,
			})
		end
	end
end

local function colorForSender(s)
	-- djb2 hash
	local hash = 5381
	for i = 1, #s do
		local c = string.byte(s, i)
		hash = (hash * 33 + c) % 4294967296
	end

	return color(SL.Colors[hash % #SL.Colors + 1])
end

ws = NETWORK:WebSocket{
	url="wss://irc-ws.chat.twitch.tv/",
	pingInterval=60,
	automaticReconnect=true,
	onMessage=function(msg)
		local msgType = ToEnumShortString(msg.type)
		if msgType == "Open" then
			addMessage({
				type="status",
				text="Welcome to the chat room!",
			})

			ws:Send("CAP REQ :twitch.tv/commands twitch.tv/tags")
			ws:Send("PASS " .. PASS)
			ws:Send("NICK " .. NICK)
			ws:Send("JOIN #" .. CHANNEL)
		elseif msgType == "Close" then
			addMessage({
				type="status",
				text="Disconnected",
			})
		elseif msgType == "Error" then
			addMessage({
				type="error",
				text=msg.reason,
			})
		elseif msgType == "Message" then
			parseMessage(msg.data)
		end

	end,
}

local function NicoActor(params)
	local nicoScreen = Def.ActorFrame{}
	for i = 1, MAXNICO do
		nicoScreen[#nicoScreen + 1] = LoadFont(FONT)..{
			Text="",
			ModuleCommand=function(self)
				nicoLine[i] = self
			end,
			InitCommand=function(self)
				self:align(0, 0)
				self:diffuse(color("#ffffff"))
				self:xy(_screen.cx*2,_screen.cy)
			end,
			MakeTextCommand=function(self)
				local text = ""
				local attributes = {}
				local msg = nicos
				local position = text:utf8len()
				
				if msg.type == "privmsg" then
					if string.sub(msg.text,1,1) == "!" and HIDE_SILENT then return end
					local displayName = msg.tags["display-name"]
					if not displayName or displayName == "" then
						displayName = msg.sender
					end

					local displayColor
					if msg.tags.color then
						displayColor = color(msg.tags.color)
					else
						displayColor = colorForSender(msg.sender)
					end

					local badges = ""
					if msg.tags["msg-id"] == "announcement" then
						badges = badges .. "📣"
					end
					if SHOW_BADGES then
						for name in string.gmatch(msg.tags.badges or "", "([^,/]+)/[^,/]+") do
							if BADGES[name] then
								badges = badges .. BADGES[name]
							end
						end
					end

					if badges == "" then
						text = text .. displayName .. ": " .. msg.text
					else
						text = text .. badges .. " " .. displayName .. ": " .. msg.text
						position = position + badges:utf8len() + 1
					end

					attributes = {
						position=position,
						data={
							Length=displayName:utf8len(),
							Diffuse=displayColor,
						},
					}
				elseif msg.type == "status" then
					if msg.msgId == "subgift" or msg.msgId == "submysterygift" then
						text = text .. "🎁 "
						position = position + 2
					elseif msg.msgId == "sub" or msg.msgId == "resub" then
						text = text .. "🎉 "
						position = position + 2
					end

					text = text .. msg.text
					attributes = {
						position=position,
						data={
							Length=msg.text:utf8len(),
							Diffuse=color("#aaaaaa"),
						},
					}
				elseif msg.type == "error" then
					text = text .. msg.text
					attributes = {
						position=position,
						data={
							Length=msg.text:utf8len(),
							Diffuse=color("#ff0000"),
						},
					}
				end

				self:settext(text)
				self:AddAttribute(attributes.position, attributes.data)
				self:finishtweening():zoom(math.max(1, math.random()*MAXZOOM)):diffusealpha(OPACITY / 100)
				self:x(_screen.cx*2):y(math.random()*_screen.cy*MINIMUM_HEIGHT*2)
				if DEBUG then
					self:zoom(MAXZOOM):y(_screen.cy*MINIMUM_HEIGHT*2)
				end
				self:linear(math.max(0.5, math.random())*4/SCROLLSPEED*self:GetWidth()):addx(-(_screen.cx*2+self:GetWidth()*self:GetZoom()))
				self:linear(0.1):diffusealpha(0)
			end
		}
	end
	return nicoScreen
end

local t = {}

t.ScreenTitleMenu = NicoActor{}
t.ScreenOptionsService = t.ScreenTitleMenu
t.ScreenSystemOptions = t.ScreenTitleMenu
t.ScreenInputOptions = t.ScreenTitleMenu
t.ScreenGraphicsSoundOptions = t.ScreenTitleMenu
t.ScreenVisualOptions = t.ScreenTitleMenu
t.ScreenAdvancedOptions = t.ScreenTitleMenu
t.ScreenMenuTimerOptions = t.ScreenTitleMenu
t.ScreenUSBProfileOptions = t.ScreenTitleMenu
t.ScreenOptionsManageProfiles = t.ScreenTitleMenu
t.ScreenThemeOptions = t.ScreenTitleMenu
t.ScreenGrooveStatsOptions = t.ScreenTitleMenu
t.ScreenTestInput = t.ScreenTitleMenu
t.ScreenSelectProfile = t.ScreenTitleMenu
t.ScreenSelectColor = t.ScreenTitleMenu
t.ScreenSelectStyle = t.ScreenTitleMenu
t.ScreenSelectPlayMode = t.ScreenTitleMenu
t.ScreenSelectPlayMode2 = t.ScreenTitleMenu
t.ScreenSelectMusic = t.ScreenTitleMenu
t.ScreenGameplay = t.ScreenTitleMenu
t.ScreenEvaluationStage = t.ScreenTitleMenu
t.ScreenNameEntryTraditional = t.ScreenTitleMenu

return t
