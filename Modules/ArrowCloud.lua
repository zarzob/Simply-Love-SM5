--[[
ArrowCloud Module for SimplyLove
Inspired and adapted from Kuro's discord leaderboard scraper: https://github.com/pogof/SimplyLove-DiscordLeaderboard
]]

-- Module configuration
local ArrowCloud = {}

-- Constants
local BASE_URL = "https://api.arrowcloud.dance"
local MODULE_TAG = "[ArrowCloud-SLmodule]"
local ENABLE_PENDING_SCORES = false -- Enable saving failed score submissions for retry when offline
local ENABLE_AUTO_ROTATION = false  -- Enable automatic rotation of event leaderboards every 3 seconds

-- Dialog Layout Configuration
--
-- Customize the leaderboard dialog appearance by modifying these values:
--
-- ROW_SPACING: Controls vertical distance between leaderboard entries (default: 18px)
--   - Increase for more spaced out rows, decrease for tighter display
--
-- DIALOG_PADDING: Inner margin around dialog content (default: 40px)
--   - Affects overall dialog size and text positioning
--
-- FONT_ZOOM: Text size multiplier for all dialog text (default: 0.7)
--   - Increase for larger text, decrease for smaller text
--
-- Column positioning (X coordinates):
--   RANK_COLUMN_X: Position of rank numbers (default: 24px from left)
--   ALIAS_COLUMN_X: Position of player names (default: 30px from left)
--   SCORE_COLUMN_OFFSET: Distance from right edge for scores (default: 64px)
--   DELTA_COLUMN_OFFSET: Distance from right edge for delta values (default: 0px)
--
-- Score Type Color Coding:
--   Scores are automatically colored based on their type (ITG=white, EX=blue, H.EX=pink)
--   Self/rival highlighting takes priority over score type colors when applicable
--
local DIALOG_LAYOUT = {
  ROW_SPACING = 18,         -- Vertical spacing between leaderboard rows
  DIALOG_PADDING = 40,      -- Inner padding for dialog content
  FONT_ZOOM = 0.7,          -- Font size multiplier for all text
  RANK_COLUMN_X = 24,       -- X position for rank column
  ALIAS_COLUMN_X = 30,      -- X position for alias/name column
  SCORE_COLUMN_OFFSET = 64, -- Offset from right edge for score column
  DELTA_COLUMN_OFFSET = 0,  -- Offset from right edge for delta column

  -- Vertical positioning for dialog elements
  TITLE_Y_OFFSET = 28,       -- Distance from top edge for title text
  FREEFORM_Y_OFFSET = 60,    -- Distance from top edge for freeform text (2-line capable)
  MODE_LABEL_Y_OFFSET = 118, -- Distance from top edge for mode label
  BOARD_Y_OFFSET = 140       -- Distance from top edge for leaderboard start
}

-- luacheck: globals GAMESTATE PREFSMAN THEME SL PLAYER_1 PLAYER_2 STATSMAN CRYPTMAN PROFILEMAN IniFile NETWORK IsHumanPlayer FormatPercentScore CalculateExScore GetTimingWindow GetWorstJudgment BinaryToHex clamp Trace ToEnumShortString ivalues MESSAGEMAN

-- forward declaration so isEligible can reference it
local debugPrint

-- Guarded stub declarations (only for tooling; real objects provided by engine at runtime)
if not GAMESTATE then GAMESTATE = {} end
if not PREFSMAN then PREFSMAN = { GetPreference = function(...) return 0 end } end
if not THEME then THEME = { GetMetric = function(...) return 0 end } end
if not SL then SL = { Global = { GameMode = "ITG", ActiveModifiers = { MusicRate = 1 }, Stages = { PlayedThisGame = 0 } }, P1 = { ActiveModifiers = { TimingWindows = { true, true, true, true, true } } }, P2 = { ActiveModifiers = { TimingWindows = { true, true, true, true, true } } } } end
if not PLAYER_1 then PLAYER_1 = 0 end
if not PLAYER_2 then PLAYER_2 = 1 end
if not STATSMAN then
  STATSMAN = {
    GetCurStageStats = function(...)
      return {
        GetPlayerStageStats = function(...)
          return {
            GetPercentDancePoints = function(...) return 0 end,
            GetGrade = function(...)
              return
              "Grade_Tier01"
            end,
            GetLifeRecord = function(...) return {} end,
            GetRadarActual = function(...) return { GetValue = function(...) return 0 end } end,
            GetRadarPossible = function(...) return { GetValue = function(...) return 0 end } end
          }
        end
      }
    end
  }
end
if not CRYPTMAN then CRYPTMAN = { SHA1File = function(...) return "" end } end
if not PROFILEMAN then PROFILEMAN = { GetProfileDir = function(...) return "" end } end
if not IniFile then IniFile = { WriteFile = function(...) end, ReadFile = function(...) return {} end } end
if not NETWORK then NETWORK = { HttpRequest = function(...) return {} end } end
if not IsHumanPlayer then IsHumanPlayer = function(...) return true end end
if not FormatPercentScore then FormatPercentScore = function(...) return "0%" end end
if not CalculateExScore then CalculateExScore = function(...) return 0 end end
if not GetTimingWindow then GetTimingWindow = function(...) return 0 end end
if not GetWorstJudgment then GetWorstJudgment = function(...) return 0 end end
if not BinaryToHex then BinaryToHex = function(...) return "" end end
if not clamp then clamp = function(v, min, max) if v < min then return min elseif v > max then return max else return v end end end
if not Trace then Trace = function(...) end end
if not GetTimeSinceStart then GetTimeSinceStart = function() return 0 end end
if not Year then Year = function() return 2024 end end
if not MonthOfYear then MonthOfYear = function() return 0 end end
if not DayOfMonth then DayOfMonth = function() return 1 end end
if not Hour then Hour = function() return 0 end end
if not Minute then Minute = function() return 0 end end
if not Second then Second = function() return 0 end end
if not ToEnumShortString then
  ToEnumShortString = function(v, ...)
    if v == PLAYER_1 then
      return "P1"
    elseif v == PLAYER_2 then
      return
      "P2"
    else
      return tostring(v)
    end
  end
end
if not ivalues then
  ivalues = function(t, ...)
    local i = 0
    return function()
      i = i + 1
      if t[i] ~= nil then return t[i] end
    end
  end
end
if not FILEMAN then FILEMAN = { DoesFileExist = function(...) return false end, GetDirListing = function(...) return {} end, Remove = function(...) return true end } end
if not RageFileUtil then RageFileUtil = { CreateRageFile = function() return { Open = function(...) return false end, Write = function(...) end, Read = function(...) return "" end, Close = function(...) end, destroy = function(...) end } end } end
if not JsonDecode then JsonDecode = function(...) return {} end end
if not MESSAGEMAN then MESSAGEMAN = { Broadcast = function(...) end } end
-- Screen dimensions (tooling stub only)
if not _screen then _screen = { w = 640, h = 480, cx = 320, cy = 240 } end
-- LoadFont (tooling stub only)
if not LoadFont then LoadFont = function(...) return Def.Actor end end
if not LoadActor then LoadActor = function(...) return Def.Actor end end
if not PlayerNumber then PlayerNumber = { PLAYER_1, PLAYER_2 } end
if not SCREENMAN then
  SCREENMAN = {
    GetTopScreen = function()
      return {
        AddInputCallback = function(...) end,
        RemoveInputCallback = function(...) end
      }
    end,
    set_input_redirected = function(...) end
  }
end

-- -------------------------------------------------------------------------------------------------
-- Pending score storage for offline retry
-- When a score submission fails due to being offline, we save the payload to disk
-- and retry it the next time the player reaches an evaluation screen while online.

local function getPendingScoresDir(player)
  if not player then return nil end
  local playerIndex = (player == PLAYER_1) and 0 or 1
  local profileDir = PROFILEMAN:GetProfileDir(playerIndex)
  if not profileDir or profileDir == "" then
    return nil
  end
  return profileDir .. "ArrowCloudPending/"
end

local function ensurePendingScoresDir(player)
  local dir = getPendingScoresDir(player)
  if not dir then return false end
  -- Directory will be created automatically when we write the first file
  return true
end

-- Forward declaration - will be defined after encodeJson
local savePendingScore

-- Load all pending score files
-- Returns array of { filename, data, hash }
local function loadPendingScores(player)
  local dir = getPendingScoresDir(player)
  if not dir or not FILEMAN:DoesFileExist(dir) then
    return {}
  end
  
  local files = FILEMAN:GetDirListing(dir)
  local pendingScores = {}
  
  for _, filename in ipairs(files) do
    if filename:match("%.json$") then
      -- Skip if there's a .completed marker for this file
      local completedMarker = dir .. filename .. ".completed"
      local cleanedMarker = dir .. filename .. ".cleaned"
      if not FILEMAN:DoesFileExist(completedMarker) and not FILEMAN:DoesFileExist(cleanedMarker) then
        local filepath = dir .. filename
        local file = RageFileUtil.CreateRageFile()
      
        if file:Open(filepath, 1) then -- mode 1 = read
          local content = file:Read()
          file:Close()
          file:destroy()
          
          -- Extract hash from filename: {timestamp}_{hash}.json
          local hash = filename:match("_%w+%.json$")
          if hash then
            hash = hash:sub(2, -6) -- remove leading _ and .json
          end
          
          -- For now, store raw JSON string; we'll pass it directly to HTTP
          table.insert(pendingScores, {
            filename = filename,
            filepath = filepath,
            data = content,
            hash = hash
          })
        else
          file:destroy()
        end
      end
    end
  end
  
  return pendingScores
end

-- Mark a pending score as completed after successful submission
-- Since FILEMAN:Remove() is not available, we rename the file with .completed suffix
local function deletePendingScore(player, filename)
  local dir = getPendingScoresDir(player)
  if not dir then return false end
  
  local filepath = dir .. filename
  local completedPath = dir .. filename .. ".completed"
  
  -- Create a marker file to indicate completion
  local file = RageFileUtil.CreateRageFile()
  if file:Open(completedPath, 2) then
    file:Write("completed")
    file:Close()
    file:destroy()
    debugPrint("Marked pending score as completed: " .. filename)
    return true
  else
    file:destroy()
    return false
  end
end

-- Count pending score files
local function countPendingScores(player)
  local dir = getPendingScoresDir(player)
  if not dir or not FILEMAN:DoesFileExist(dir) then
    return 0
  end
  
  local files = FILEMAN:GetDirListing(dir)
  local count = 0
  
  for _, filename in ipairs(files) do
    if filename:match("%.json$") then
      -- Skip if there's a .completed or .cleaned marker for this file
      local completedMarker = dir .. filename .. ".completed"
      local cleanedMarker = dir .. filename .. ".cleaned"
      if not FILEMAN:DoesFileExist(completedMarker) and not FILEMAN:DoesFileExist(cleanedMarker) then
        count = count + 1
      end
    end
  end
  
  return count
end

-- Clean up old pending scores (older than 30 days)
local function cleanupOldPendingScores(player)
  local dir = getPendingScoresDir(player)
  if not dir or not FILEMAN:DoesFileExist(dir) then
    return
  end
  
  local files = FILEMAN:GetDirListing(dir)
  
  -- Calculate current date as YYYYMMDD number for comparison
  local currentYear = Year()
  local currentMonth = MonthOfYear() + 1
  local currentDay = DayOfMonth()
  local currentDate = currentYear * 10000 + currentMonth * 100 + currentDay
  
  for _, filename in ipairs(files) do
    if filename:match("%.json$") then
      -- Extract date from timestamp: YYYYMMDDHHMMSSmmm
      local timestampStr = filename:match("^%d+")
      if timestampStr and #timestampStr >= 8 then
        local fileYear = tonumber(timestampStr:sub(1, 4))
        local fileMonth = tonumber(timestampStr:sub(5, 6))
        local fileDay = tonumber(timestampStr:sub(7, 8))
        local fileDate = fileYear * 10000 + fileMonth * 100 + fileDay
        
        -- Simple day difference calculation (approximate)
        local daysDiff = currentDate - fileDate
        
        -- Mark old files as cleaned by creating a .cleaned marker
        -- (We can't actually delete files since FILEMAN:Remove is not available)
        if daysDiff > 30 then
          local cleanedMarker = dir .. filename .. ".cleaned"
          if not FILEMAN:DoesFileExist(cleanedMarker) then
            local file = RageFileUtil.CreateRageFile()
            if file:Open(cleanedMarker, 2) then
              file:Write("cleaned")
              file:Close()
              file:destroy()
              debugPrint("Marked old pending score for cleanup: " .. filename)
            else
              file:destroy()
            end
          end
        end
      end
    end
  end
end

-- -------------------------------------------------------------------------------------------------

-- Centralized sizing helpers for the Arrow Cloud dialog overlay
local function ACDialogSize()
  -- base margins from screen and max intended size (tweak here to affect all uses)
  local maxW, maxH = 300, 300
  local marginW, marginH = 80, 120
  local w = math.min(_screen.w - marginW, maxW)
  local h = math.min(_screen.h - marginH, maxH)
  return w, h
end

local function ACDialogWrapWidth()
  -- compute a safe wrap width based on dialog width and internal padding
  local w = ACDialogSize()
  local paddingLeft, paddingRight = 10, 10
  local wrap = w - (paddingLeft + paddingRight)
  -- clamp to reasonable bounds
  if wrap < 160 then wrap = 160 end
  return wrap
end

-- -------------------------------------------------------------------------------------------------
-- Eligibility checks (refactored from ValidForGrooveStats in SL-Helpers-GrooveStats.lua)
-- We only submit scores when a collection of sanity conditions are satisfied.  These are
-- intended to prevent accidental submission of obviously invalid scores – not to be
-- tamper‑proof.  This version is self‑contained for ArrowCloud usage and returns a rich result
-- for future UI/telemetry use.
--
-- ArrowCloud.isEligible(player, opts?) -> {
--    ok = boolean,
--    checks = { { id=string, pass=boolean, desc=string } ... },
--    failures = { <id>, ... }
-- }
-- opts.ignoreCourse (boolean)  : if true, we will not invalidate due to course mode.
-- opts.logger (function(msg))  : optional logger (defaults to debugPrint)
-- -------------------------------------------------------------------------------------------------

function ArrowCloud.isEligible(player, opts)
  opts = opts or {}
  local log = opts.logger or debugPrint
  local pn = ToEnumShortString(player)

  local results = { ok = true, checks = {}, failures = {} }

  local function addCheck(id, desc, pass)
    table.insert(results.checks, { id = id, desc = desc, pass = pass })
    if not pass then
      results.ok = false
      table.insert(results.failures, id)
    end
  end

  -- 1. Game must be dance
  addCheck("game", "Game type must be 'dance'", GAMESTATE:GetCurrentGame():GetName() == "dance")

  -- 2. Style not solo (GrooveStats / ArrowCloud currently single/versus/double only)
  local styleName = GAMESTATE:GetCurrentStyle():GetName()
  addCheck("style", "Style must not be 'solo'", styleName ~= "solo")

  -- 3. Not course mode (can be optionally ignored by caller – e.g. for Nonstop handler)
  if not opts.ignoreCourse then
    addCheck("course", "Not a course/nonstop/endless chart", not GAMESTATE:IsCourseMode())
  else
    addCheck("course", "Course mode ignored (override)", true)
  end

  -- 4. GameMode must be ITG (ArrowCloud currently tailored to ITG / FA+ scoring expectations)
  addCheck("gamemode", "GameMode must be ITG", SL.Global.GameMode == "ITG")

  -- 5. LifeDifficultyScale <= 1 (standard or harder)
  addCheck("lifediff", "LifeDifficultyScale must be standard or harder (<=1)",
    PREFSMAN:GetPreference("LifeDifficultyScale") <= 1)

  -- TimingWindowScale and granular timing window metric validation intentionally omitted:
  -- backend recomputes and validates precise timing data.

  -- 8. Rate between 0.10x and 10.00x (inclusive)
  -- This is super extreme ends of what will ever actually be done. The backend actually gates
  -- this on a per leaderboard basis and today all leaderboards require exactly 1.0 rate, so
  -- this is simply a future looking idea.
  local rate = SL.Global.ActiveModifiers.MusicRate * 100
  addCheck("rate", "Music Rate must be 0.10x - 10.00x", rate >= 10 and rate <= 1000)

  -- Player options for note removal/addition
  local po = GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred")
  local removes = (po:Little() or po:NoHolds() or po:NoStretch() or po:NoHands() or po:NoJumps() or po:NoFakes() or po:NoLifts() or po:NoQuads() or po:NoRolls())
  addCheck("no_remove", "No note-removal mods active", not removes)

  local adds = (po:Wide() or po:Skippy() or po:Quick() or po:Echo() or po:BMRize() or po:Stomp() or po:Big())
  addCheck("no_add", "No note-addition mods active", not adds)

  -- Fail type must be Immediate or ImmediateContinue
  local failType = GAMESTATE:GetPlayerFailType(player)
  local ftValid = (failType == "FailType_Immediate" or failType == "FailType_ImmediateContinue")
  addCheck("failtype", "Fail type must be Immediate/ImmediateContinue", ftValid)

  -- Must be a human player unless override provided via opts.allowAutoplay
  local allowAutoplay = opts.allowAutoplay == true
  addCheck("human", allowAutoplay and "Autoplay allowed (testing override)" or "Player must be human (no autoplay)",
    IsHumanPlayer(player) or allowAutoplay)

  -- MinTNSToScoreNotes cannot hide W1/W2 (must be Greats or worse)
  local minTNSToScoreNores = ToEnumShortString(PREFSMAN:GetPreference("MinTNSToScoreNotes"))
  local rehitsOk = (SL.Global.GameMode == "ITG") and (minTNSToScoreNores ~= "W1" and minTNSToScoreNores ~= "W2") or false
  addCheck("rehit", "MinTNSToScoreNotes must be >= W3", rehitsOk)

  -- Log summary (only if failing) – compact
  if not results.ok then
    local msgs = {}
    for _, c in ipairs(results.checks) do if not c.pass then table.insert(msgs, c.id) end end
    log("Eligibility failed for P" .. (pn == "P1" and "1" or "2") .. ": " .. table.concat(msgs, ","))
  end

  return results
end

-- Utility functions
debugPrint = function(message)
  if Trace then Trace(MODULE_TAG .. " " .. message) end
end

local function printTable(t, indent)
  indent = indent or 0
  local indentStr = string.rep("  ", indent)

  for k, v in pairs(t) do
    if type(v) == "table" then
      debugPrint(indentStr .. tostring(k) .. ":")
      printTable(v, indent + 1)
    else
      debugPrint(indentStr .. tostring(k) .. ": " .. tostring(v))
    end
  end
end

-- Profile and API key management (returns table { apiKey, allowAutoplay })
local function readApiKey(player)
  local playerIndex = (player == PLAYER_1) and 0 or 1
  local profilePath = PROFILEMAN:GetProfileDir(playerIndex)
  local filePath = profilePath .. "ArrowCloud.ini"
  local apiKey
  local allowAutoplay = false

  if not FILEMAN:DoesFileExist(filePath) then
    IniFile.WriteFile(filePath, {
      ["ArrowCloud"] = {
        ["ApiKey"] = "",
        ["AllowAutoplay"] = "0" -- set to 1 for testing autoplay submissions
      }
    })
  else
    local contents = IniFile.ReadFile(filePath)
    if contents["ArrowCloud"] then
      if contents["ArrowCloud"]["ApiKey"] then
        apiKey = contents["ArrowCloud"]["ApiKey"]
      end
      if contents["ArrowCloud"]["AllowAutoplay"] ~= nil then
        allowAutoplay = tostring(contents["ArrowCloud"]["AllowAutoplay"]) == "1"
      else
        contents["ArrowCloud"]["AllowAutoplay"] = "0"
        IniFile.WriteFile(filePath, contents)
      end
    end
  end

  return { apiKey = apiKey, allowAutoplay = allowAutoplay }
end

-- Simple JSON parsing utility using JsonDecode
local function parseArrowCloudResponse(jsonString)
  if not jsonString or type(jsonString) ~= "string" then
    return nil
  end

  -- Use JsonDecode to parse the entire response
  local success, decoded = pcall(JsonDecode, jsonString)
  if not success then
    debugPrint("ArrowCloud: Failed to parse JSON response")
    return nil
  end

  if not decoded or type(decoded) ~= "table" or not decoded.eventLeaderboards then
    return nil
  end

  return decoded
end

-- Format delta values for leaderboard display
-- Returns formatted text and color for delta values
local function formatDelta(deltaValue)
  local deltaText = ""
  local deltaColor = { 1, 1, 1, 1 } -- default white
  if deltaValue == nil then
    return deltaText, deltaColor
  end

  if deltaValue then
    local numValue = tonumber(deltaValue)
    if numValue and numValue == 0 then
      deltaText = "--"
    elseif numValue and numValue > 0 then
      deltaText = "+" .. tostring(numValue)
      deltaColor = { 0.4, 1, 0.4, 1 } -- green for positive
    elseif numValue and numValue < 0 then
      deltaText = tostring(numValue)  -- already has minus sign
      deltaColor = { 1, 0.4, 0.4, 1 } -- red for negative
    else
      deltaText = "--"                -- fallback for invalid numbers
    end
  else
    deltaText = "--"
  end

  debugPrint("Formatted delta value: " .. deltaText)

  return deltaText, deltaColor
end

-- JSON encoding utilities
local function escapeJsonString(str)
  local replacements = {
    ['"'] = '\\"',
    ['\\'] = '\\\\',
    ['\b'] = '\\b',
    ['\f'] = '\\f',
    ['\n'] = '\\n',
    ['\r'] = '\\r',
    ['\t'] = '\\t'
  }
  return str:gsub('[%z\1-\31\\"]', replacements)
end

local function encodeJsonValue(value)
  local valueType = type(value)

  if valueType == "string" then
    return '"' .. escapeJsonString(value) .. '"'
  elseif valueType == "number" or valueType == "boolean" then
    return tostring(value)
  elseif valueType == "table" then
    local isArray = true
    local maxIndex = 0

    for k, _ in pairs(value) do
      if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
        isArray = false
        break
      end
      if k > maxIndex then
        maxIndex = k
      end
    end

    local result = {}
    if isArray then
      for i = 1, maxIndex do
        table.insert(result, encodeJsonValue(value[i]))
      end
      return "[" .. table.concat(result, ",") .. "]"
    else
      for k, v in pairs(value) do
        table.insert(result, '"' .. escapeJsonString(k) .. '":' .. encodeJsonValue(v))
      end
      return "{" .. table.concat(result, ",") .. "}"
    end
  else
    return "null"
  end
end

local function encodeJson(value)
  return encodeJsonValue(value)
end

-- Save a failed score submission for later retry
-- Filename format: {timestamp}_{hash}.json where timestamp is YYYYMMDDHHMMSSmmm
savePendingScore = function(player, data, hash)
  if not ensurePendingScoresDir(player) then
    debugPrint("Could not create pending scores directory")
    return false
  end
  
  -- Create timestamp from year/month/day/hour/minute/second/millisecond
  local year = Year()
  local month = MonthOfYear() + 1
  local day = DayOfMonth()
  local hour = Hour()
  local minute = Minute()
  local second = Second()
  local millisecond = math.floor((GetTimeSinceStart() % 1) * 1000)
  local timestamp = string.format("%04d%02d%02d%02d%02d%02d%03d", year, month, day, hour, minute, second, millisecond)
  local filename = string.format("%s_%s.json", timestamp, hash)
  local filepath = getPendingScoresDir(player) .. filename
  
  local jsonBody = encodeJson(data)
  local file = RageFileUtil.CreateRageFile()
  
  if file:Open(filepath, 2) then -- mode 2 = write
    file:Write(jsonBody)
    file:Close()
    file:destroy()
    debugPrint("Saved pending score: " .. filename)
    return true
  else
    file:destroy()
    debugPrint("Failed to save pending score: " .. filename)
    return false
  end
end

-- HTTP communication
local function sendScoreData(data, apiKey, hash, player, isSilent, onComplete)
  local url = BASE_URL .. "/v1/chart/" .. hash .. "/play"

  local jsonBody = encodeJson(data)

  NETWORK:HttpRequest {
    url = url,
    method = "POST",
    body = jsonBody,
    headers = {
      ["Content-Type"] = "application/json",
      ["Authorization"] = "Bearer " .. apiKey
    },
    onResponse = function(response)
      local ok = false
      local status = nil
      local err = nil
      local body = ""
      local responseData = nil
      if type(response) == "table" then
        status = response.statusCode
        err = response.error and ToEnumShortString(response.error) or nil
        body = response.body or ""
        if type(body) ~= "string" then body = tostring(body) end

        ok = (status ~= nil and status >= 200 and status < 300)

        -- Try to parse JSON response for dialog content
        if ok and body and #body > 0 then
          responseData = parseArrowCloudResponse(body)
        end

        -- If submission failed due to being offline, save for retry
        if ENABLE_PENDING_SCORES and not ok and status == 0 then
          savePendingScore(player, data, hash)
        end

        -- Truncate body for logging after we've tried to parse it
        if #body > 256 then body = body:sub(1, 256) .. "…" end
      else
        -- Legacy path; treat as failure but log what we saw.
        body = tostring(response)
      end

      -- Log errors only
      if not ok then
        debugPrint("ArrowCloud submit failed: status=" .. tostring(status) .. (err and (" error=" .. err) or ""))
      end

      -- Notify UI listeners on evaluation screens (unless silent)
      if not isSilent then
        local pn = player and ToEnumShortString(player) or nil
        MESSAGEMAN:Broadcast("ArrowCloudSubmitResult", {
          ok = ok,
          player = pn,
          status = status,
          error = err,
          responseData = responseData
        })
      end

      -- Call completion callback if provided
      if onComplete then
        onComplete(ok, status)
      end
    end
  }
end

-- Retry pending scores from previous sessions
local function retryPendingScores(player, callback)
  if not ENABLE_PENDING_SCORES then
    if callback then callback(0, true) end
    return
  end
  
  local pendingScores = loadPendingScores(player)
  
  if #pendingScores == 0 then
    if callback then callback(0, true) end
    return
  end
  
  debugPrint("Retrying " .. #pendingScores .. " pending score(s)")
  
  local successCount = 0
  local remaining = #pendingScores
  
  for _, pending in ipairs(pendingScores) do
    -- Read API key from player profile for retry attempts
    local config = readApiKey(player)
    if config and config.apiKey and config.apiKey ~= "" then
      -- Send the raw JSON directly
      local url = BASE_URL .. "/v1/chart/" .. pending.hash .. "/play"
      
      NETWORK:HttpRequest {
        url = url,
        method = "POST",
        body = pending.data,
        headers = {
          ["Content-Type"] = "application/json",
          ["Authorization"] = "Bearer " .. config.apiKey
        },
        onResponse = function(response)
          local ok = false
          local status = nil
          
          if type(response) == "table" then
            status = response.statusCode
            ok = (status ~= nil and status >= 200 and status < 300)
          end
          
          if ok then
            deletePendingScore(player, pending.filename)
            successCount = successCount + 1
            debugPrint("Successfully retried pending score: " .. pending.filename)
          else
            debugPrint("Retry failed for: " .. pending.filename .. " (status: " .. tostring(status) .. ")")
          end
          
          remaining = remaining - 1
          local isComplete = (remaining == 0)
          if callback then
            callback(successCount, isComplete)
          end
        end
      }
    else
      remaining = remaining - 1
      local isComplete = (remaining == 0)
      if callback then
        callback(successCount, isComplete)
      end
    end
  end
end

-- Game data collection functions
local function getLifebarData(player)
  local steps = GAMESTATE:GetCurrentSteps(player)
  local timingData = steps:GetTimingData()
  local firstSecond = math.min(timingData:GetElapsedTimeFromBeat(0), 0)
  local chartStartSecond = GAMESTATE:GetCurrentSong():GetFirstSecond()
  local lastSecond = GAMESTATE:GetCurrentSong():GetLastSecond()
  local duration = lastSecond - firstSecond

  local lifebarData = {}
  local playerStageStats = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
  local lifeRecord = playerStageStats:GetLifeRecord(lastSecond, 100)

  for i, lifebarValue in ipairs(lifeRecord) do
    local stepSecond = chartStartSecond + (i - 1) * (duration / #lifeRecord)
    local xValue = stepSecond
    local yValue = lifebarValue
    table.insert(lifebarData, { x = xValue, y = yValue })
  end

  return lifebarData
end

local function getNPSData(player)
  if GAMESTATE:IsCourseMode() then return {} end

  local pn = ToEnumShortString(player)
  local steps = GAMESTATE:GetCurrentSteps(player)
  local song = GAMESTATE:GetCurrentSong()
  if not steps or not song then return {} end

  -- Ensure Streams data populated (wrapped to avoid hard crash if parser fails)
  pcall(ParseChartInfo, steps, pn)

  local peak = SL[pn] and SL[pn].Streams and SL[pn].Streams.PeakNPS or nil
  local perMeasure = SL[pn] and SL[pn].Streams and SL[pn].Streams.NPSperMeasure or nil
  if not (peak and perMeasure and #perMeasure > 1) then return {} end

  local timingData = steps:GetTimingData()
  local firstSecond = math.min(timingData:GetElapsedTimeFromBeat(0), 0)
  local lastSecond = song:GetLastSecond()

  local points = {}
  local started = false
  for i, nps in ipairs(perMeasure) do
    if nps > 0 then started = true end
    if started then
      local t = timingData:GetElapsedTimeFromBeat((i - 1) * 4)
      local normX = 0
      if lastSecond > firstSecond then
        normX = (t - firstSecond) / (lastSecond - firstSecond)
      end
      if normX < 0 then normX = 0 elseif normX > 1 then normX = 1 end
      local normY = 0
      if peak > 0 then normY = nps / peak end
      if normY < 0 then normY = 0 elseif normY > 1 then normY = 1 end
      table.insert(points, { x = normX, y = normY, nps = nps, measure = i - 1 })
    end
  end

  return {
    points = points,
    peakNPS = peak,
    firstSecond = firstSecond,
    lastSecond = lastSecond
  }
end

local function getTimingData(player)
  local pn = ToEnumShortString(player)
  local sequential_offsets = SL[pn].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1].sequential_offsets
  local worst_window = GetTimingWindow(math.max(2, GetWorstJudgment(sequential_offsets)))
  return sequential_offsets, worst_window
end

local function getRadarData(player)
  local playerStageStats = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
  local radarCategories = { 'Holds', 'Mines', 'Rolls' }
  local radarValues = {}

  for _, category in ipairs(radarCategories) do
    radarValues[category] = {}
    radarValues[category][1] = playerStageStats:GetRadarActual():GetValue("RadarCategory_" .. category)
    radarValues[category][2] = playerStageStats:GetRadarPossible():GetValue("RadarCategory_" .. category)
    radarValues[category][2] = clamp(radarValues[category][2], 0, 999)
  end

  return radarValues
end

-- Player modifiers analysis
local function getPlayerModifiers(player)
  local pn = ToEnumShortString(player)
  local playerOptions = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")

  -- Speed modifier detection
  local function getSpeedModifier()
    local cmod, cmodeSpeed = playerOptions:CMod()
    local mmod, mmodSpeed = playerOptions:MMod()
    local xmod, xmodSpeed = playerOptions:XMod()

    if cmod then
      return "C", cmod
    elseif mmod then
      return "M", mmod
    elseif xmod then
      return "X", tonumber(("%.2f"):format(xmod))
    else
      return "X", 1.0
    end
  end

  -- Mini percentage calculation
  local function getMiniPercentage()
    local mini = playerOptions:Mini()
    if mini and mini > 0 then
      return math.floor(100 * mini + 0.5)
    end
    return 100
  end

  -- Perspective detection
  local function getPerspective()
    if playerOptions:Overhead() then
      return "Overhead"
    elseif playerOptions:Hallway() then
      return "Hallway"
    elseif playerOptions:Distant() then
      return "Distant"
    elseif playerOptions:Incoming() then
      return "Incoming"
    elseif playerOptions:Space() then
      return "Space"
    else
      return "Overhead"
    end
  end

  -- Noteskin detection
  local function getNoteskin()
    local noteskin = playerOptions:NoteSkin()
    return noteskin or "default"
  end

  -- Turn modifier detection
  local function getTurnModifier()
    if playerOptions:Mirror() then
      return "Mirror"
    elseif playerOptions:Left() then
      return "Left"
    elseif playerOptions:Right() then
      return "Right"
    elseif playerOptions:LRMirror() then
      return "LR-Mirror"
    elseif playerOptions:UDMirror() then
      return "UD-Mirror"
    elseif playerOptions:Shuffle() then
      return "Shuffle"
    elseif playerOptions:SoftShuffle() then
      return "Shuffle"
    elseif playerOptions:SuperShuffle() then
      return "Shuffle"
    elseif playerOptions:HyperShuffle() then
      return "Shuffle"
    else
      return "None"
    end
  end

  -- Scroll modifier detection
  local function getScrollModifier()
    if playerOptions:Reverse() and playerOptions:Reverse() > 0.5 then
      return "Reverse"
    elseif playerOptions:Split() and playerOptions:Split() > 0.5 then
      return "Split"
    elseif playerOptions:Alternate() and playerOptions:Alternate() > 0.5 then
      return "Alternate"
    elseif playerOptions:Cross() and playerOptions:Cross() > 0.5 then
      return "Cross"
    elseif playerOptions:Centered() and playerOptions:Centered() > 0.5 then
      return "Centered"
    else
      return nil
    end
  end

  -- Disabled timing windows detection
  local function getDisabledTimingWindows()
    local disabledWindows = playerOptions:GetDisabledTimingWindows()
    if not disabledWindows or #disabledWindows == 0 then
      return "None"
    end

    local windowNames = {}
    for _, window in ipairs(disabledWindows) do
      if window == "TimingWindow_W5" then
        table.insert(windowNames, "Way Offs")
      elseif window == "TimingWindow_W4" then
        table.insert(windowNames, "Decents")
      elseif window == "TimingWindow_W1" then
        table.insert(windowNames, "Fantastics")
      elseif window == "TimingWindow_W2" then
        table.insert(windowNames, "Excellents")
      end
    end

    if #windowNames == 0 then
      return "None"
    elseif #windowNames == 1 then
      return windowNames[1]
    else
      return table.concat(windowNames, " + ")
    end
  end

  -- Acceleration modifiers detection
  local function getAccelerationModifiers()
    local accelMods = {}

    if playerOptions:Boost() and playerOptions:Boost() > 0 then
      table.insert(accelMods, "Boost")
    end
    if playerOptions:Brake() and playerOptions:Brake() > 0 then
      table.insert(accelMods, "Brake")
    end
    if playerOptions:Wave() and playerOptions:Wave() > 0 then
      table.insert(accelMods, "Wave")
    end
    if playerOptions:Expand() and playerOptions:Expand() > 0 then
      table.insert(accelMods, "Expand")
    end
    if playerOptions:Boomerang() and playerOptions:Boomerang() > 0 then
      table.insert(accelMods, "Boomerang")
    end

    return accelMods
  end

  -- Effect modifiers detection
  local function getEffectModifiers()
    local effectMods = {}

    if playerOptions:Drunk() and playerOptions:Drunk() > 0 then
      table.insert(effectMods, "Drunk")
    end
    if playerOptions:Dizzy() and playerOptions:Dizzy() > 0 then
      table.insert(effectMods, "Dizzy")
    end
    if playerOptions:Confusion() and playerOptions:Confusion() > 0 then
      table.insert(effectMods, "Confusion")
    end
    if playerOptions:Big() then
      table.insert(effectMods, "Big")
    end
    if playerOptions:Flip() and playerOptions:Flip() > 0 then
      table.insert(effectMods, "Flip")
    end
    if playerOptions:Invert() and playerOptions:Invert() > 0 then
      table.insert(effectMods, "Invert")
    end
    if playerOptions:Tornado() and playerOptions:Tornado() > 0 then
      table.insert(effectMods, "Tornado")
    end
    if playerOptions:Tipsy() and playerOptions:Tipsy() > 0 then
      table.insert(effectMods, "Tipsy")
    end
    if playerOptions:Bumpy() and playerOptions:Bumpy() > 0 then
      table.insert(effectMods, "Bumpy")
    end
    if playerOptions:Beat() and playerOptions:Beat() > 0 then
      table.insert(effectMods, "Beat")
    end

    return effectMods
  end

  -- Appearance modifiers detection
  local function getAppearanceModifiers()
    local appearanceMods = {}

    if playerOptions:Hidden() and playerOptions:Hidden() > 0 then
      table.insert(appearanceMods, "Hidden")
    end
    if playerOptions:Sudden() and playerOptions:Sudden() > 0 then
      table.insert(appearanceMods, "Sudden")
    end
    if playerOptions:Stealth() and playerOptions:Stealth() > 0 then
      table.insert(appearanceMods, "Stealth")
    end
    if playerOptions:Blink() and playerOptions:Blink() > 0 then
      table.insert(appearanceMods, "Blink")
    end
    if playerOptions:RandomVanish() and playerOptions:RandomVanish() > 0 then
      table.insert(appearanceMods, "R.Vanish")
    end

    return appearanceMods
  end

  -- Build complete modifiers structure
  local speedType, speedValue = getSpeedModifier()

  return {
    speed = {
      type = speedType,
      value = speedValue
    },
    mini = getMiniPercentage(),
    perspective = getPerspective(),
    noteskin = getNoteskin(),
    turn = getTurnModifier(),
    scroll = getScrollModifier(),
    disabledWindows = getDisabledTimingWindows(),
    acceleration = getAccelerationModifiers(),
    effect = getEffectModifiers(),
    appearance = getAppearanceModifiers(),
    visualDelay = playerOptions:VisualDelay() and math.floor(playerOptions:VisualDelay() * 1000 + 0.5) or 0
  }
end

-- Data formatting and aggregation functions
local function buildSongResultData(player, style)
  local pn = ToEnumShortString(player)
  local song = GAMESTATE:GetCurrentSong()

  -- Song metadata
  local songInfo = {
    name        = escapeJsonString(song:GetTranslitFullTitle()),
    artist      = escapeJsonString(song:GetTranslitArtist()),
    pack        = escapeJsonString(song:GetGroupName()),
    length      = string.format("%d:%02d", math.floor(song:MusicLengthSeconds() / 60),
      math.floor(song:MusicLengthSeconds() % 60)),
    stepartist  = escapeJsonString(GAMESTATE:GetCurrentSteps(player):GetAuthorCredit()),
    difficulty  = GAMESTATE:GetCurrentSteps(player):GetMeter(),
    description = escapeJsonString(GAMESTATE:GetCurrentSteps(player):GetDescription()),
    hash        = tostring(SL[pn].Streams.Hash),
    modifiers   = getPlayerModifiers(player)
  }

  -- Performance results
  local resultInfo = {
    score = FormatPercentScore(STATSMAN:GetCurStageStats():GetPlayerStageStats(player):GetPercentDancePoints()):gsub(
      "%%", ""),
    exscore = ("%.2f"):format(CalculateExScore(player)),
    grade = STATSMAN:GetCurStageStats():GetPlayerStageStats(player):GetGrade(),
    radar = getRadarData(player),
    passed = not STATSMAN:GetCurStageStats():GetPlayerStageStats(player):GetFailed(),
  }

  -- Gameplay data
  local timingData, worst_window = getTimingData(player)
  local lifebarInfo = getLifebarData(player)

  -- Combined result
  return {
    songName = songInfo.name,
    artist = songInfo.artist,
    pack = songInfo.pack,
    length = songInfo.length,
    stepartist = songInfo.stepartist,
    difficulty = songInfo.difficulty,
    description = songInfo.description,
    itgScore = resultInfo.score,
    exScore = resultInfo.exscore,
    grade = resultInfo.grade,
    passed = resultInfo.passed,
    hash = songInfo.hash,
    timingData = timingData,
    lifebarInfo = lifebarInfo,
    worstWindow = worst_window,
    style = style,
    modifiers = songInfo.modifiers,
    radar = resultInfo.radar,
    npsInfo = getNPSData(player),
    usedAutoplay = not IsHumanPlayer(player),
    musicRate = SL.Global.ActiveModifiers and SL.Global.ActiveModifiers.MusicRate or 1,
    _arrowCloudBodyVersion = "1.2"
  }
end

--------------------------------------------------------------------------------------------------

local function buildCourseResultData(player, style)
  local pn = ToEnumShortString(player)
  local course = GAMESTATE:GetCurrentCourse()
  local trail = GAMESTATE:GetCurrentTrail(player)

  -- Course metadata
  local courseInfo = {
    name        = escapeJsonString(course:GetTranslitFullTitle()),
    pack        = escapeJsonString(course:GetGroupName()),
    difficulty  = trail:GetMeter(),
    description = escapeJsonString(course:GetDescription()),
    entries     = "[",
    hash        = BinaryToHex(CRYPTMAN:SHA1File(course:GetCourseDir())):sub(1, 16),
    scripter    = escapeJsonString(course:GetScripter()),
    modifiers   = getPlayerModifiers(player)
  }

  -- Build course entries list
  local trailSteps = trail:GetTrailEntries()
  for i in ipairs(trailSteps) do
    courseInfo.entries = courseInfo.entries ..
        "{name: " .. escapeJsonString(trailSteps[i]:GetSong():GetTranslitFullTitle()) ..
        ", length: " .. trailSteps[i]:GetSong():MusicLengthSeconds() ..
        ", artist: " .. escapeJsonString(trailSteps[i]:GetSong():GetTranslitArtist()) ..
        ", difficulty: " .. trailSteps[i]:GetSteps():GetMeter() .. "},"
  end

  -- Clean up entries format
  if courseInfo.entries:sub(-1) == "," then
    courseInfo.entries = courseInfo.entries:sub(1, -2)
  end
  courseInfo.entries = courseInfo.entries .. "]"

  -- Performance results
  local resultInfo = {
    score = FormatPercentScore(STATSMAN:GetCurStageStats():GetPlayerStageStats(player):GetPercentDancePoints()):gsub(
      "%%", ""),
    exscore = ("%.2f"):format(CalculateExScore(player)),
    grade = STATSMAN:GetCurStageStats():GetPlayerStageStats(player):GetGrade(),
    radar = getRadarData(player),
    passed = not STATSMAN:GetCurStageStats():GetPlayerStageStats(player):GetFailed(),
  }

  local lifebarInfo = getLifebarData(player)

  -- Combined result
  return {
    courseName = courseInfo.name,
    pack = courseInfo.pack,
    entries = courseInfo.entries,
    hash = courseInfo.hash,
    scripter = courseInfo.scripter,
    difficulty = courseInfo.difficulty,
    description = courseInfo.description,
    itgScore = resultInfo.score,
    exScore = resultInfo.exscore,
    grade = resultInfo.grade,
    passed = resultInfo.passed,
    lifebarInfo = lifebarInfo,
    style = style,
    modifiers = courseInfo.modifiers,
    radar = resultInfo.radar,
    npsInfo = getNPSData(player),
    usedAutoplay = not IsHumanPlayer(player),
    musicRate = SL.Global.ActiveModifiers and SL.Global.ActiveModifiers.MusicRate or 1,
    _arrowCloudBodyVersion = "1.2"
  }
end

-- ---------------------------------------------------------------------------------------------
-- Simple dialog overlay used to present backend-controlled messages.
-- For now, it renders placeholder content and is dismissible via Back/Start/Select.
-- This mirrors the input redirection and dismissal behavior used by other prompts.

local function createACDialogActor(name)
  local af
  local dialogData = nil            -- will hold API response data
  local rotationActive = false      -- prevent multiple rotation timers
  local isRotating = false          -- prevent recursive calls during rotation
  local currentLeaderboardIndex = 1 -- Track which leaderboard we're showing
  local autoRotationEnabled = true -- track if auto-rotation should continue



  -- row highlight colors (aligned with scorebox styling)
  local function maybeColor(hex, fallback)
    local c = _G and rawget(_G, "color")
    if type(c) == "function" then return c(hex) end
    return fallback
  end
  local self_color  = maybeColor("#a1ff94", { 0.631, 1.0, 0.580, 1 })
  local rival_color = maybeColor("#c29cff", { 0.761, 0.612, 1.0, 1 })

  -- Score type colors (matching theme's color scheme)
  -- Try to use theme's existing judgment colors when available
  local itg_color   = (SL and SL.JudgmentColors and SL.JudgmentColors["ITG"] and SL.JudgmentColors["ITG"][1]) or
      maybeColor("#21CCE8", { 0.129, 0.8, 0.91, 1 })
  local ex_color    = itg_color                                     -- EX scores use the same blue as ITG
  local hex_color   = maybeColor("#ff00cc", { 1.0, 0.2, 0.406, 1 }) -- Pink for H.EX scores

  -- Determine score color based on score text content
  local function getScoreTypeColor(scoreText)
    if not scoreText or scoreText == "" then
      return { 1, 1, 1, 1 } -- default white
    end

    local scoreStr = tostring(scoreText):upper()
    if scoreStr:find("H%.EX") or scoreStr:find("H.EX") or scoreStr:find("HARDEX") then
      return hex_color
    elseif scoreStr:find("EX") then
      return ex_color
    elseif scoreStr:find("ITG") then
      return itg_color
    else
      return { 1, 1, 1, 1 } -- default white
    end
  end

  -- Apply content from API response to dialog elements
  local function applyContent()
    if not af or not dialogData then
      return
    end

    -- Extract leaderboards from response
    local allLeaderboards = {}
    if dialogData.eventLeaderboards and #dialogData.eventLeaderboards > 0 then
      local firstEvent = dialogData.eventLeaderboards[1]
      if firstEvent.leaderboards and #firstEvent.leaderboards > 0 then
        allLeaderboards = firstEvent.leaderboards
      end
    end

    -- If no leaderboards, don't show anything
    if #allLeaderboards == 0 then
      return
    end

    -- Get the current leaderboard to display
    local currentLeaderboard = allLeaderboards[currentLeaderboardIndex] or allLeaderboards[1]

    if not currentLeaderboard then
      return
    end

    local box = af:GetChild("Box")
    if not box then
      debugPrint("No box found - available children:")
      if af then
        for i = 0, af:GetNumChildren() - 1 do
          local child = af:GetChildAt(i)
          if child and child.GetName then
            debugPrint("  Child " .. i .. ": " .. tostring(child:GetName()))
          end
        end
      end
      return
    end

    -- Update freeform text from event messages
    local freeformText = box:GetChild("Freeform")
    if freeformText then
      local messages = {}
      -- Get messages from the first event
      if dialogData.eventLeaderboards and #dialogData.eventLeaderboards > 0 then
        local firstEvent = dialogData.eventLeaderboards[1]
        if firstEvent.messages and type(firstEvent.messages) == "table" then
          messages = firstEvent.messages
        end
      end

      -- Render up to first 2 messages
      local displayText = ""
      for i = 1, math.min(2, #messages) do
        if i > 1 then
          displayText = displayText .. "\n"
        end
        displayText = displayText .. tostring(messages[i])
      end

      -- If no messages, show default text
      if displayText == "" then
        displayText = "New Personal Best"
      end

      freeformText:settext(displayText)
      freeformText:diffuse(1, 1, 1, 1)
    end

    -- Update mode label
    local modeLabel = box:GetChild("ModeLabel")
    if modeLabel then
      local labelText = currentLeaderboard.type or ""
      modeLabel:settext(labelText)
      modeLabel:diffuse(1, 1, 1, 1)
      modeLabel:diffusealpha(0.8)
    end

    -- Update leaderboard data
    local board = box:GetChild("Board")
    if board then
      -- Prepare row data from API entries
      local apiEntries = currentLeaderboard.entries or {}
      local rowData = {}

      -- Take up to 8 entries for display
      for i = 1, math.min(8, #apiEntries) do
        local entry = apiEntries[i]

        local rowEntry = {
          rank = entry.rank,
          name = entry.userAlias,
          score = entry.score,
          delta = entry.delta,
          isSelf = entry.isSelf,  -- TODO: isSelf will come from backend later
          isRival = entry.isRival -- TODO: isRival will come from backend later
        }
        table.insert(rowData, rowEntry)
      end

      -- Apply data to board rows
      board:playcommand("SetMode", { data = rowData, leaderboardType = currentLeaderboard.type })
    end

    -- Don't set up rotation here - it will be set up after dialog is visible
  end

  -- Handle leaderboard rotation
  local function rotateToNextLeaderboard()
    if isRotating or not dialogData or not dialogData.eventLeaderboards then
      return
    end

    isRotating = true

    local allLeaderboards = {}
    if dialogData.eventLeaderboards[1] and dialogData.eventLeaderboards[1].leaderboards then
      allLeaderboards = dialogData.eventLeaderboards[1].leaderboards
    end

    if #allLeaderboards > 1 then
      currentLeaderboardIndex = (currentLeaderboardIndex % #allLeaderboards) + 1
      applyContent() -- Re-apply with new leaderboard

      -- Schedule the next rotation using the timer (only if auto-rotation is enabled)
      if af and af:GetVisible() and autoRotationEnabled then
        local timer = af:GetChild("RotationTimer")
        if timer then
          timer:sleep(3):queuecommand("TriggerRotation")
        end
      else
        rotationActive = false
      end
    else
      rotationActive = false
    end

    isRotating = false
  end

  -- Manual navigation functions
  local function navigateToNextLeaderboard()
    if not dialogData or not dialogData.eventLeaderboards then
      return
    end

    local allLeaderboards = {}
    if dialogData.eventLeaderboards[1] and dialogData.eventLeaderboards[1].leaderboards then
      allLeaderboards = dialogData.eventLeaderboards[1].leaderboards
    end

    if #allLeaderboards > 1 then
      -- Disable auto-rotation when manual navigation is used
      autoRotationEnabled = false
      rotationActive = false
      
      -- Stop any pending rotation timer
      if af then
        local timer = af:GetChild("RotationTimer")
        if timer then
          timer:stoptweening()
        end
      end

      currentLeaderboardIndex = (currentLeaderboardIndex % #allLeaderboards) + 1
      applyContent() -- Re-apply with new leaderboard
    end
  end

  local function navigateToPrevLeaderboard()
    if not dialogData or not dialogData.eventLeaderboards then
      return
    end

    local allLeaderboards = {}
    if dialogData.eventLeaderboards[1] and dialogData.eventLeaderboards[1].leaderboards then
      allLeaderboards = dialogData.eventLeaderboards[1].leaderboards
    end

    if #allLeaderboards > 1 then
      -- Disable auto-rotation when manual navigation is used
      autoRotationEnabled = false
      rotationActive = false
      
      -- Stop any pending rotation timer
      if af then
        local timer = af:GetChild("RotationTimer")
        if timer then
          timer:stoptweening()
        end
      end

      currentLeaderboardIndex = currentLeaderboardIndex - 1
      if currentLeaderboardIndex < 1 then
        currentLeaderboardIndex = #allLeaderboards
      end
      applyContent() -- Re-apply with new leaderboard
    end
  end

  return Def.ActorFrame {
    Name = name or "ACDialog",
    InitCommand = function(self)
      af = self
      self:visible(false):draworder(200)
    end,

    -- Reset dialog state when the ActorFrame is created/reset
    ResetDialogStateCommand = function(self)
      dialogData = nil
      rotationActive = false
      isRotating = false
      currentLeaderboardIndex = 1
      autoRotationEnabled = true
      self:visible(false)
      -- Ensure normal evaluation input is restored
      local overlay = SCREENMAN:GetTopScreen() and SCREENMAN:GetTopScreen():GetChild("Overlay")
      if overlay then
        local evalCommon = overlay:GetChild("ScreenEval Common")
        if evalCommon then
          evalCommon:queuecommand("DirectInputToEngine")
        end
      end
    end,

    -- external API: Show the dialog with API response data
    ShowDialogCommand = function(self, params)
      -- Reset state before showing new dialog
      rotationActive = false
      isRotating = false
      currentLeaderboardIndex = 1
      autoRotationEnabled = true
      
      -- Store response data for content application
      if params and params.responseData then
        dialogData = params.responseData
      else
        dialogData = nil
        return -- Don't show dialog without data
      end      -- apply content immediately since children should exist
      self:playcommand("ApplyDialogContent")

      -- Switch to event overlay input handling like ITL/SRPG
      local overlay = SCREENMAN:GetTopScreen():GetChild("Overlay"):GetChild("ScreenEval Common")
      if overlay then
        overlay:queuecommand("DirectInputToEventOverlayHandler")
      end

      self:visible(true)
      self:stoptweening():diffusealpha(0):linear(0.15):diffusealpha(1)
      self:GetChild("Snd"):play()

      -- Set up rotation after dialog becomes visible (only on first call)
      if ENABLE_AUTO_ROTATION and dialogData and dialogData.eventLeaderboards and dialogData.eventLeaderboards[1] and dialogData.eventLeaderboards[1].leaderboards then
        local allLeaderboards = dialogData.eventLeaderboards[1].leaderboards
        if #allLeaderboards > 1 and not rotationActive then
          rotationActive = true
          -- Use a separate timer instead of sleep on the main ActorFrame
          self:GetChild("RotationTimer"):playcommand("StartTimer")
        end
      end
    end,

    ApplyDialogContentCommand = function(self)
      applyContent()
    end,

    -- Handle input events via message broadcasting (like ITL/SRPG panels)
    EventOverlayInputEventMessageCommand = function(self, event)
      debugPrint("ArrowCloud EventOverlay Input - Event received: " .. tostring(event and event.GameButton or "nil"))
      debugPrint("ArrowCloud Dialog visible: " .. tostring(af and af:GetVisible() or "nil"))
      
      if not af or not af:GetVisible() then return end
      if not event or not event.PlayerNumber or not event.button then return end
      if event.type == "InputEventType_FirstPress" then
        debugPrint("ArrowCloud EventOverlay Input: " .. tostring(event.GameButton))
        
        if event.GameButton == "Back" or event.GameButton == "Start" or event.GameButton == "Select" then
          debugPrint("ArrowCloud: Dismissing dialog via EventOverlay")
          af:queuecommand("Hide")
        elseif event.GameButton == "MenuRight" then
          debugPrint("ArrowCloud: Navigate to next leaderboard via EventOverlay")
          navigateToNextLeaderboard()
        elseif event.GameButton == "MenuLeft" then
          debugPrint("ArrowCloud: Navigate to previous leaderboard via EventOverlay")
          navigateToPrevLeaderboard()
        end
      end
    end,

    -- Handle leaderboard rotation
    RotateLeaderboardCommand = function(self)
      rotateToNextLeaderboard()
    end,

    -- Manual navigation commands  
    NextLeaderboardCommand = function(self)
      navigateToNextLeaderboard()
    end,

    PrevLeaderboardCommand = function(self)
      navigateToPrevLeaderboard()
    end,    HideCommand = function(self)
      rotationActive = false -- reset rotation state
      isRotating = false     -- reset rotation guard
      
      -- Restore normal evaluation input handling
      local overlay = SCREENMAN:GetTopScreen():GetChild("Overlay"):GetChild("ScreenEval Common")
      if overlay then
        overlay:queuecommand("DirectInputToEngine")
      end
      
      self:stoptweening():linear(0.15):diffusealpha(0)
      self:sleep(0.16):queuecommand("AfterHide")
    end,

    AfterHideCommand = function(self)
      self:visible(false)
      -- Clear dialog data when fully hidden to prevent persistence
      dialogData = nil
      currentLeaderboardIndex = 1
      autoRotationEnabled = true
    end,

    -- sfx (re-use prompt sound)
    LoadActor(THEME:GetPathS("", "_prompt")) .. {
      Name = "Snd",
      IsAction = true,
      InitCommand = function(self) end,
    },

    -- darkened fullscreen underlay (slightly less opaque)
    Def.Quad {
      InitCommand = function(self) self:FullScreen():diffuse(0, 0, 0, 0.75) end
    },

    -- content box
    Def.ActorFrame {
      Name = "Box",
      InitCommand = function(self) self:xy(_screen.cx, _screen.cy) end,

      -- panel background (slightly less opaque black)
      Def.Quad {
        InitCommand = function(self)
          local w, h = ACDialogSize()
          self:zoomto(w, h)
          self:diffuse(0, 0, 0, 0.9)
        end
      },

      -- border around panel (static quads like ITL/SRPG)
      Def.Quad {
        Name = "BorderTop",
        InitCommand = function(self)
          local w, h = ACDialogSize()
          local bw = 2
          self:xy(0, -(h / 2))
          self:halign(0.5):valign(0)
          self:zoomto(w, bw)
          self:diffuse(1, 1, 1, 0.35)
        end
      },
      Def.Quad {
        Name = "BorderBottom",
        InitCommand = function(self)
          local w, h = ACDialogSize()
          local bw = 2
          self:xy(0, (h / 2))
          self:halign(0.5):valign(1)
          self:zoomto(w, bw)
          self:diffuse(1, 1, 1, 0.35)
        end
      },
      Def.Quad {
        Name = "BorderLeft",
        InitCommand = function(self)
          local w, h = ACDialogSize()
          local bw = 2
          self:xy(-(w / 2), 0)
          self:halign(0):valign(0.5)
          self:zoomto(bw, h - 2 * bw)
          self:diffuse(1, 1, 1, 0.35)
        end
      },
      Def.Quad {
        Name = "BorderRight",
        InitCommand = function(self)
          local w, h = ACDialogSize()
          local bw = 2
          self:xy((w / 2), 0)
          self:halign(1):valign(0.5)
          self:zoomto(bw, h - 2 * bw)
          self:diffuse(1, 1, 1, 0.35)
        end
      },

      -- header text (BLUE SHIFT) centered along the top
      LoadFont("Common" .. " Header") .. {
        Name = "LogoText",
        InitCommand = function(self)
          local w, h = ACDialogSize()
          self:xy(0, -(h / 2) + DIALOG_LAYOUT.TITLE_Y_OFFSET)
          self:halign(0.5)
          self:zoom(0.8)
          -- rgb(1,89,227)
          self:diffuse(1 / 255, 89 / 255, 227 / 255, 1)
          self:settext("BLUE SHIFT")
        end
      },

      -- centered freeform text under the header logo
      LoadFont("Common" .. " Normal") .. {
        Name = "Freeform",
        InitCommand = function(self)
          local w, h = ACDialogSize()
          self:xy(0, -(h / 2) + DIALOG_LAYOUT.FREEFORM_Y_OFFSET)
          self:halign(0.5)
          self:valign(0)
          self:zoom(1)
          self:diffuse(1, 1, 1, 1)
          self:settext("New Personal Best")
        end
      },

      -- leaderboard mode label (from API response)
      LoadFont("Common" .. " Normal") .. {
        Name = "ModeLabel",
        InitCommand = function(self)
          local w, h = ACDialogSize()
          self:xy(0, -(h / 2) + DIALOG_LAYOUT.MODE_LABEL_Y_OFFSET)
          self:halign(0.5)
          self:zoom(0.7)
          self:diffusealpha(0)
          self:settext("") -- will be set by applyContent()
        end
      },                   -- Hardcoded leaderboard table (rank, alias, score, point delta)
      Def.ActorFrame {
        Name = "Board",
        InitCommand = function(self)
          local w, h = ACDialogSize()
          self:xy(-(w / 2) + 20, -(h / 2) + DIALOG_LAYOUT.BOARD_Y_OFFSET)
          -- compute and stash column anchors for children to use
          self.innerW     = w - DIALOG_LAYOUT.DIALOG_PADDING
          self.rankRight  = DIALOG_LAYOUT.RANK_COLUMN_X                     -- right-aligned rank near left
          self.nameLeft   = DIALOG_LAYOUT.ALIAS_COLUMN_X                    -- name starts a bit after rank
          self.scoreRight = self.innerW - DIALOG_LAYOUT.SCORE_COLUMN_OFFSET -- score aligns near the right
          self.deltaRight = self.innerW - DIALOG_LAYOUT.DELTA_COLUMN_OFFSET -- delta flush-right, fills width
        end,
        SetModeCommand = function(self, params)
          local rows = params and params.data or {}
          local leaderboardType = params and params.leaderboardType or ""

          local function applyRow(rowName, data)
            local row = self:GetChild(rowName)
            if not row then
              return
            end
            local rankNode  = row:GetChild("Rank")
            local aliasNode = row:GetChild("Alias")
            local scoreNode = row:GetChild("Score")
            local deltaNode = row:GetChild("Delta")

            -- set texts
            local rankText  = data.rank and (tostring(data.rank) .. ".") or ""
            local aliasText = data.name or ""
            local scoreText = data.score or ""

            -- Add emojis for self/rival
            if data.isSelf then
              aliasText = aliasText .. " 🙂"
            elseif data.isRival then
              aliasText = aliasText .. " ⚔"
            end

            rankNode:settext(rankText)
            aliasNode:settext(aliasText)
            scoreNode:settext(scoreText)

            -- row highlight for self/rival (but preserve score type and delta colors)
            local rowColor = nil
            if data.isSelf then
              rowColor = self_color
            elseif data.isRival then
              rowColor = rival_color
            end

            -- Apply row highlighting to rank and alias columns
            if rowColor then
              rankNode:diffuse(rowColor)
              aliasNode:diffuse(rowColor)
            else
              rankNode:diffuse(1, 1, 1, 1)
              aliasNode:diffuse(1, 1, 1, 1)
            end

            -- Score column: self/rival color takes priority, otherwise use score type color
            if rowColor then
              scoreNode:diffuse(rowColor)
            else
              local scoreTypeColor = getScoreTypeColor(leaderboardType)
              scoreNode:diffuse(scoreTypeColor)
            end

            -- Format delta column using helper function
            local deltaText, deltaColor = formatDelta(data.delta)

            deltaNode:diffuse(deltaColor)
            deltaNode:settext(deltaText)
          end

          -- Apply data to each row (up to 8 entries)
          applyRow("Row2", rows[1] or {})
          applyRow("Row3", rows[2] or {})
          applyRow("Row4", rows[3] or {})
          applyRow("Row5", rows[4] or {})
          applyRow("Row6", rows[5] or {})
          applyRow("Row7", rows[6] or {})
          applyRow("Row8", rows[7] or {})
          applyRow("Row9", rows[8] or {})
        end,

        -- Row helper: four columns (rank, name, score, delta)
        Def.ActorFrame { Name = "Row2",
          InitCommand = function(self) self:y(DIALOG_LAYOUT.ROW_SPACING * 0) end,
          LoadFont("Common" .. " Normal") .. { Name = "Rank", InitCommand = function(self)
            local w = ACDialogSize()
            local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(DIALOG_LAYOUT.RANK_COLUMN_X, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Alias", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.ALIAS_COLUMN_X, 0):halign(0):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1, 1, 1):settext(
              "")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Score", InitCommand = function(self)
            local w = ACDialogSize()
            local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.SCORE_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Delta", InitCommand = function(self)
            local w = ACDialogSize()
            local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.DELTA_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1,
              1, 1):settext("")
          end },
        },
        Def.ActorFrame { Name = "Row3",
          InitCommand = function(self) self:y(DIALOG_LAYOUT.ROW_SPACING * 1) end,
          LoadFont("Common" .. " Normal") .. { Name = "Rank", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.RANK_COLUMN_X, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Alias", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.ALIAS_COLUMN_X, 0):halign(0):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1, 1, 1):settext(
              "")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Score", InitCommand = function(self)
            local w = ACDialogSize(); local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.SCORE_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Delta", InitCommand = function(self)
            local w = ACDialogSize(); local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.DELTA_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1,
              1, 1):settext("")
          end },
        },
        Def.ActorFrame { Name = "Row4",
          InitCommand = function(self) self:y(DIALOG_LAYOUT.ROW_SPACING * 2) end,
          LoadFont("Common" .. " Normal") .. { Name = "Rank", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.RANK_COLUMN_X, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Alias", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.ALIAS_COLUMN_X, 0):halign(0):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1, 1, 1):settext(
              "")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Score", InitCommand = function(self)
            local w = ACDialogSize(); local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.SCORE_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Delta", InitCommand = function(self)
            local w = ACDialogSize(); local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.DELTA_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1,
              1, 1):settext("")
          end },
        },
        Def.ActorFrame { Name = "Row5",
          InitCommand = function(self) self:y(DIALOG_LAYOUT.ROW_SPACING * 3) end,
          LoadFont("Common" .. " Normal") .. { Name = "Rank", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.RANK_COLUMN_X, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Alias", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.ALIAS_COLUMN_X, 0):halign(0):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1, 1, 1):settext(
              "")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Score", InitCommand = function(self)
            local w = ACDialogSize(); local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.SCORE_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Delta", InitCommand = function(self)
            local w = ACDialogSize(); local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.DELTA_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1,
              1, 1):settext("")
          end },
        },
        Def.ActorFrame { Name = "Row6",
          InitCommand = function(self) self:y(DIALOG_LAYOUT.ROW_SPACING * 4) end,
          LoadFont("Common" .. " Normal") .. { Name = "Rank", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.RANK_COLUMN_X, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Alias", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.ALIAS_COLUMN_X, 0):halign(0):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1, 1, 1):settext(
              "")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Score", InitCommand = function(self)
            local w = ACDialogSize(); local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.SCORE_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Delta", InitCommand = function(self)
            local w = ACDialogSize(); local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.DELTA_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1,
              1, 1):settext("")
          end },
        },
        Def.ActorFrame { Name = "Row7",
          InitCommand = function(self) self:y(DIALOG_LAYOUT.ROW_SPACING * 5) end,
          LoadFont("Common" .. " Normal") .. { Name = "Rank", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.RANK_COLUMN_X, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Alias", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.ALIAS_COLUMN_X, 0):halign(0):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1, 1, 1):settext(
              "")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Score", InitCommand = function(self)
            local w = ACDialogSize(); local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.SCORE_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Delta", InitCommand = function(self)
            local w = ACDialogSize(); local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.DELTA_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1,
              1, 1):settext("")
          end },
        },
        Def.ActorFrame { Name = "Row8",
          InitCommand = function(self) self:y(DIALOG_LAYOUT.ROW_SPACING * 6) end,
          LoadFont("Common" .. " Normal") .. { Name = "Rank", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.RANK_COLUMN_X, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Alias", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.ALIAS_COLUMN_X, 0):halign(0):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1, 1, 1):settext(
              "")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Score", InitCommand = function(self)
            local w = ACDialogSize(); local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.SCORE_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Delta", InitCommand = function(self)
            local w = ACDialogSize(); local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.DELTA_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1,
              1, 1):settext("")
          end },
        },
        Def.ActorFrame { Name = "Row9",
          InitCommand = function(self) self:y(DIALOG_LAYOUT.ROW_SPACING * 7) end,
          LoadFont("Common" .. " Normal") .. { Name = "Rank", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.RANK_COLUMN_X, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Alias", InitCommand = function(self)
            self:xy(DIALOG_LAYOUT.ALIAS_COLUMN_X, 0):halign(0):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1, 1, 1):settext(
              "")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Score", InitCommand = function(self)
            local w = ACDialogSize(); local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.SCORE_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):settext("")
          end },
          LoadFont("Common" .. " Normal") .. { Name = "Delta", InitCommand = function(self)
            local w = ACDialogSize(); local innerW = w - DIALOG_LAYOUT.DIALOG_PADDING
            self:xy(innerW - DIALOG_LAYOUT.DELTA_COLUMN_OFFSET, 0):halign(1):zoom(DIALOG_LAYOUT.FONT_ZOOM):diffuse(1, 1,
              1, 1):settext("")
          end },
        },
      }
    },

    -- Separate timer ActorFrame for rotation
    Def.ActorFrame {
      Name = "RotationTimer",
      StartTimerCommand = function(self)
        self:sleep(3.2):queuecommand("TriggerRotation")
      end,
      TriggerRotationCommand = function(self)
        af:playcommand("RotateLeaderboard")
      end
    }
  }
end

-- Module registration and event handlers
local moduleRegistration = {}

moduleRegistration["ScreenEvaluationStage"] = Def.ActorFrame {
  InitCommand = function(self)
    self.waiting = { P1 = false, P2 = false }
    self.dialogShown = false
  end,
  ModuleCommand = function(self)
    -- reset dialog visibility guard on each screen entry
    self.dialogShown = false

    -- Reset dialog state to prevent persistence from previous visits
    local dialog = self:GetChild("ACDialog")
    if dialog then
      dialog:playcommand("ResetDialogState")
    end

    -- Clear previous texts
    local p1Text = self:GetChild("ACSubmitP1")
    local p2Text = self:GetChild("ACSubmitP2")
    local p1ErrMsg = self:GetChild("ACErrorP1")
    local p2ErrMsg = self:GetChild("ACErrorP2")
    local p1Pending = self:GetChild("ACPendingP1")
    local p2Pending = self:GetChild("ACPendingP2")
    if p1Text then p1Text:settext("") end
    if p2Text then p2Text:settext("") end
    if p1ErrMsg then p1ErrMsg:settext("") end
    if p2ErrMsg then p2ErrMsg:settext("") end
    if p1Pending then p1Pending:settext("") end
    if p2Pending then p2Pending:settext("") end
    self.waiting = { P1 = false, P2 = false }

    local style = GAMESTATE:GetCurrentStyle():GetName()
    if style == "versus" then
      style = "single"
    end

    local players = GAMESTATE:GetHumanPlayers()
    for _, player in ipairs(players) do
      local pn = ToEnumShortString(player)
      local label = (pn == "P1") and p1Text or p2Text
      local pendingLabel = (pn == "P1") and p1Pending or p2Pending
      
      -- Clean up old pending scores for this player
      if ENABLE_PENDING_SCORES then
        cleanupOldPendingScores(player)
        
        -- Show initial pending count for this player
        local pendingCount = countPendingScores(player)
        if pendingCount > 0 and pendingLabel then
          local pendingText = pendingCount .. " pending score" .. (pendingCount == 1 and "" or "s")
          pendingLabel:settext(pendingText)
        end
      end
      
      local profileCfg = readApiKey(player)
      local eligibility = ArrowCloud.isEligible(player, { allowAutoplay = profileCfg.allowAutoplay })
      local apiKey = profileCfg.apiKey

      if apiKey ~= nil and apiKey ~= "" and eligibility.ok then
        if label then label:settext("Arrow Cloud: submitting…") end
        self.waiting[pn] = true
        local data = buildSongResultData(player, style)
        local hash = tostring(SL[pn].Streams.Hash)
        sendScoreData(data, apiKey, hash, player)
      else
        if label then label:settext("❌ Arrow Cloud") end

        if apiKey == nil or apiKey == "" then
          debugPrint("No API key configured for " .. pn)
          local errLabel = (pn == "P1") and p1ErrMsg or p2ErrMsg
          if errLabel then
            errLabel:settext("Arrow Cloud API key not configured.")
          end
        end

        if apiKey ~= nil and not eligibility.ok then
          debugPrint("Skipping submission (ineligible)")
        end
      end
    end

    -- After normal submissions, retry pending scores
    self:sleep(1):queuecommand("RetryPending")
  end,

  RetryPendingCommand = function(self)
    local p1Pending = self:GetChild("ACPendingP1")
    local p2Pending = self:GetChild("ACPendingP2")
    
    local players = GAMESTATE:GetHumanPlayers()
    for _, player in ipairs(players) do
      local pn = ToEnumShortString(player)
      local pendingLabel = (pn == "P1") and p1Pending or p2Pending
      
      retryPendingScores(player, function(successCount, isComplete)
        local remainingCount = countPendingScores(player)
        
        if remainingCount == 0 and successCount > 0 then
          -- All scores submitted successfully
          if pendingLabel then
            pendingLabel:settext("✔ All scores submitted")
            pendingLabel:diffusecolor({ 0.2, 1, 0.2, 1 }) -- Green
            if isComplete then
              pendingLabel:sleep(3):smooth(0.5):diffusealpha(0)
            end
          end
        elseif remainingCount > 0 then
          -- Update count after each score is processed
          local pendingText = remainingCount .. " pending score" .. (remainingCount == 1 and "" or "s")
          if pendingLabel then pendingLabel:settext(pendingText) end
        end
      end)
    end
  end,

  ArrowCloudSubmitResultMessageCommand = function(self, params)
    if not params or not params.player then
      return
    end
    local pn = params.player

    local label = self:GetChild(pn == "P1" and "ACSubmitP1" or "ACSubmitP2")
    local errLabel = self:GetChild(pn == "P1" and "ACErrorP1" or "ACErrorP2")
    local pendingLabel = self:GetChild(pn == "P1" and "ACPendingP1" or "ACPendingP2")

    if not label then return end
    if self.waiting[pn] then
      label:settext(params.ok and "✔ Arrow Cloud" or "❌ Arrow Cloud")

      if not params.ok and params.status == 401 then
        errLabel:settext("Status: 401. Check your API key.")
      elseif not params.ok and params.status == 0 then
        errLabel:settext("You are offline.")
        -- Show pending count immediately
        if ENABLE_PENDING_SCORES then
          local player = (pn == "P1") and PLAYER_1 or PLAYER_2
          local pendingCount = countPendingScores(player)
          if pendingCount > 0 and pendingLabel then
            local pendingText = pendingCount .. " pending score" .. (pendingCount == 1 and "" or "s")
            pendingLabel:settext(pendingText)
          end
        end
      elseif not params.ok then
        errLabel:settext("Status: " .. tostring(params.status) .. ". " .. (params.message or "Unknown error."))
      end

      self.waiting[pn] = false
    end
    -- Show dialog only if we have valid response data with eventLeaderboards
    -- Skip dialog in versus mode (two players) since each gets separate responses
    local players = GAMESTATE:GetHumanPlayers()
    if not self.dialogShown and params.responseData and params.responseData.eventLeaderboards and #players == 1 then
      self.dialogShown = true
      local dialog = self:GetChild("ACDialog")
      if dialog then
        dialog:playcommand("ShowDialog", { responseData = params.responseData })
      end
    end
  end,

  -- Clean up dialog state when leaving the screen
  OffCommand = function(self)
    local dialog = self:GetChild("ACDialog")
    if dialog then
      dialog:playcommand("ResetDialogState")
    end
  end,

  LoadFont("Common Normal") .. {
    Name = "ACSubmitP1",
    InitCommand = function(self)
      self:xy(10, _screen.h - 48):zoom(0.6):halign(0)
      self:settext("")
    end
  },
  LoadFont("Common Normal") .. {
    Name = "ACSubmitP2",
    InitCommand = function(self)
      self:xy(_screen.w - 10, _screen.h - 48):zoom(0.6):halign(1)
      self:settext("")
    end
  },
  LoadFont("Common Normal") .. {
    Name = "ACErrorP1",
    InitCommand = function(self)
      self:xy(10, _screen.h - 64):zoom(0.5):halign(0)
      self:settext("")
      self:diffusecolor({ 1, 1, 1, 1 })
    end
  },
  LoadFont("Common Normal") .. {
    Name = "ACErrorP2",
    InitCommand = function(self)
      self:xy(_screen.w - 10, _screen.h - 64):zoom(0.5):halign(1)
      self:settext("")
      self:diffusecolor({ 1, 1, 1, 1 })
    end
  },
  LoadFont("Common Normal") .. {
    Name = "ACPendingP1",
    InitCommand = function(self)
      self:xy(10, _screen.h - 80):zoom(0.5):halign(0)
      self:settext("")
      self:diffusecolor({ 1, 0.8, 0.2, 1 }) -- Yellow/orange for pending
    end
  },
  LoadFont("Common Normal") .. {
    Name = "ACPendingP2",
    InitCommand = function(self)
      self:xy(_screen.w - 10, _screen.h - 80):zoom(0.5):halign(1)
      self:settext("")
      self:diffusecolor({ 1, 0.8, 0.2, 1 }) -- Yellow/orange for pending
    end
  },

  -- dialog overlay used after submission
  createACDialogActor("ACDialog")
}

moduleRegistration["ScreenEvaluationNonstop"] = Def.ActorFrame {
  InitCommand = function(self)
    self.waiting = { P1 = false, P2 = false }
    self.dialogShown = false
  end,
  ModuleCommand = function(self)
    -- reset dialog visibility guard on each screen entry
    self.dialogShown = false

    -- Reset dialog state to prevent persistence from previous visits
    local dialog = self:GetChild("ACDialog")
    if dialog then
      dialog:playcommand("ResetDialogState")
    end

    local p1Text = self:GetChild("ACSubmitP1")
    local p2Text = self:GetChild("ACSubmitP2")
    local p1ErrMsg = self:GetChild("ACErrorP1")
    local p2ErrMsg = self:GetChild("ACErrorP2")
    local p1Pending = self:GetChild("ACPendingP1")
    local p2Pending = self:GetChild("ACPendingP2")
    if p1Text then p1Text:settext("") end
    if p2Text then p2Text:settext("") end
    if p1ErrMsg then p1ErrMsg:settext("") end
    if p2ErrMsg then p2ErrMsg:settext("") end
    if p1Pending then p1Pending:settext("") end
    if p2Pending then p2Pending:settext("") end

    local fixed = GAMESTATE:GetCurrentCourse():AllSongsAreFixed()
    local autogen = GAMESTATE:GetCurrentCourse():IsAutogen()
    local endless = GAMESTATE:GetCurrentCourse():IsEndless()

    -- Only process fixed, non-autogen, non-endless courses
    if fixed and not autogen and not endless then
      self.waiting = { P1 = false, P2 = false }

      local style = GAMESTATE:GetCurrentStyle():GetName()
      if style == "versus" then
        style = "single"
      end

      local players = GAMESTATE:GetHumanPlayers()
      for _, player in ipairs(players) do
        local pn = ToEnumShortString(player)
        local pendingLabel = (pn == "P1") and p1Pending or p2Pending
        
        -- Clean up old pending scores for this player
        if ENABLE_PENDING_SCORES then
          cleanupOldPendingScores(player)
          
          -- Show initial pending count for this player
          local pendingCount = countPendingScores(player)
          if pendingCount > 0 and pendingLabel then
            local pendingText = pendingCount .. " pending score" .. (pendingCount == 1 and "" or "s")
            pendingLabel:settext(pendingText)
          end
        end
        
        local profileCfg = readApiKey(player)
        -- Ignore the course restriction for nonstop; reuse other checks.
        local eligibility = ArrowCloud.isEligible(player,
          { ignoreCourse = true, allowAutoplay = profileCfg.allowAutoplay })

        local apiKey = profileCfg.apiKey
        if eligibility.ok and apiKey ~= nil and apiKey ~= "" then
          local pn = ToEnumShortString(player)
          local label = (pn == "P1") and p1Text or p2Text
          if label then label:settext("Arrow Cloud: submitting…") end
          self.waiting[pn] = true
          local data = buildCourseResultData(player, style)
          local course = GAMESTATE:GetCurrentCourse()
          local hash = BinaryToHex(CRYPTMAN:SHA1File(course:GetCourseDir())):sub(1, 16)
          sendScoreData(data, apiKey, hash, player)
        else
          local pn = ToEnumShortString(player)
          local label = (pn == "P1") and p1Text or p2Text
          if label then label:settext("❌ Arrow Cloud") end
          if apiKey == nil or apiKey == "" then
            debugPrint("No API key configured for " .. pn)
            local errLabel = (pn == "P1") and p1ErrMsg or p2ErrMsg
            if errLabel then
              errLabel:settext("Arrow Cloud API key not configured.")
            end
          end
          if apiKey ~= nil and not eligibility.ok then
            debugPrint("Skipping course submission (ineligible)")
          end
        end
      end
    end

    -- After normal submissions, retry pending scores
    self:sleep(1):queuecommand("RetryPending")
  end,

  RetryPendingCommand = function(self)
    local p1Pending = self:GetChild("ACPendingP1")
    local p2Pending = self:GetChild("ACPendingP2")
    
    local players = GAMESTATE:GetHumanPlayers()
    for _, player in ipairs(players) do
      local pn = ToEnumShortString(player)
      local pendingLabel = (pn == "P1") and p1Pending or p2Pending
      
      retryPendingScores(player, function(successCount, isComplete)
        local remainingCount = countPendingScores(player)
        
        if remainingCount == 0 and successCount > 0 then
          -- All scores submitted successfully
          if pendingLabel then
            pendingLabel:settext("✅ All scores submitted")
            pendingLabel:diffusecolor({ 0.2, 1, 0.2, 1 }) -- Green
            if isComplete then
              pendingLabel:sleep(3):smooth(0.5):diffusealpha(0)
            end
          end
        elseif remainingCount > 0 then
          -- Update count after each score is processed
          local pendingText = remainingCount .. " pending score" .. (remainingCount == 1 and "" or "s")
          if pendingLabel then pendingLabel:settext(pendingText) end
        end
      end)
    end
  end,

  ArrowCloudSubmitResultMessageCommand = function(self, params)
    if not params or not params.player then return end
    local pn = params.player
    local label = self:GetChild(pn == "P1" and "ACSubmitP1" or "ACSubmitP2")
    local errLabel = self:GetChild(pn == "P1" and "ACErrorP1" or "ACErrorP2")
    local pendingLabel = self:GetChild(pn == "P1" and "ACPendingP1" or "ACPendingP2")
    if not label then return end
    if self.waiting[pn] then
      label:settext(params.ok and "✔ Arrow Cloud" or "❌ Arrow Cloud")

      if not params.ok and params.status == 401 then
        if errLabel then errLabel:settext("Status: 401. Check your API key.") end
      elseif not params.ok and params.status == 0 then
        if errLabel then errLabel:settext("You are offline.") end
        -- Show pending count immediately
        if ENABLE_PENDING_SCORES then
          local player = (pn == "P1") and PLAYER_1 or PLAYER_2
          local pendingCount = countPendingScores(player)
          if pendingCount > 0 and pendingLabel then
            local pendingText = pendingCount .. " pending score" .. (pendingCount == 1 and "" or "s")
            pendingLabel:settext(pendingText)
          end
        end
      elseif not params.ok then
        if errLabel then errLabel:settext("Status: " .. tostring(params.status) .. ". " .. (params.message or "Unknown error.")) end
      end

      self.waiting[pn] = false
    end
    -- Show dialog only if we have valid response data with eventLeaderboards
    -- Skip dialog in versus mode (two players) since each gets separate responses
    local players = GAMESTATE:GetHumanPlayers()
    if not self.dialogShown and params.responseData and params.responseData.eventLeaderboards and #players == 1 then
      self.dialogShown = true
      local dialog = self:GetChild("ACDialog")
      if dialog then
        dialog:playcommand("ShowDialog", { responseData = params.responseData })
      end
    end
  end,

  -- Clean up dialog state when leaving the screen
  OffCommand = function(self)
    local dialog = self:GetChild("ACDialog")
    if dialog then
      dialog:playcommand("ResetDialogState")
    end
  end,

  LoadFont("Common Normal") .. {
    Name = "ACSubmitP1",
    InitCommand = function(self)
      self:xy(10, _screen.h - 48):zoom(0.6):halign(0)
      self:settext("")
    end
  },
  LoadFont("Common Normal") .. {
    Name = "ACSubmitP2",
    InitCommand = function(self)
      self:xy(_screen.w - 10, _screen.h - 48):zoom(0.6):halign(1)
      self:settext("")
    end
  },
  LoadFont("Common Normal") .. {
    Name = "ACErrorP1",
    InitCommand = function(self)
      self:xy(10, _screen.h - 64):zoom(0.5):halign(0)
      self:settext("")
      self:diffusecolor({ 1, 1, 1, 1 })
    end
  },
  LoadFont("Common Normal") .. {
    Name = "ACErrorP2",
    InitCommand = function(self)
      self:xy(_screen.w - 10, _screen.h - 64):zoom(0.5):halign(1)
      self:settext("")
      self:diffusecolor({ 1, 1, 1, 1 })
    end
  },
  LoadFont("Common Normal") .. {
    Name = "ACPendingP1",
    InitCommand = function(self)
      self:xy(10, _screen.h - 80):zoom(0.5):halign(0)
      self:settext("")
      self:diffusecolor({ 1, 0.8, 0.2, 1 }) -- Yellow/orange for pending
    end
  },
  LoadFont("Common Normal") .. {
    Name = "ACPendingP2",
    InitCommand = function(self)
      self:xy(_screen.w - 10, _screen.h - 80):zoom(0.5):halign(1)
      self:settext("")
      self:diffusecolor({ 1, 0.8, 0.2, 1 }) -- Yellow/orange for pending
    end
  },

  -- dialog overlay used after submission
  createACDialogActor("ACDialog")
}

-- ---------------------------------------------------------------------------------------------
-- Title screen connection status for Arrow Cloud
-- Simple check: hit /auth-check with the first available ArrowCloud API key. No partial states.
-- Renders a compact label in the top-right: "✔ Arrow Cloud" or "❌ Arrow Cloud".

moduleRegistration["ScreenTitleMenu"] = Def.ActorFrame {
  InitCommand = function(self)
    -- position near top-right
    self:xy(_screen.w - 10, 15):zoom(0.8):halign(1)
  end,
  ModuleCommand = function(self)
    self:queuecommand("CheckConnection")
  end,

  -- Perform the auth check.
  CheckConnectionCommand = function(self)
    local bmt = self:GetChild("Status")
    local errMsg = self:GetChild("ErrorMessage")
    if not bmt then return end

    -- start with a neutral label while checking
    bmt:settext("Arrow Cloud: checking…")

    -- Hit the hello-world endpoint (root) without auth headers.
    local url = BASE_URL .. "/"
    NETWORK:HttpRequest {
      url = url,
      method = "GET",
      connectTimeout = 6,
      transferTimeout = 6,
      onResponse = function(response)
        -- Treat HTTP 200 as success; anything else (including errors) as failure.
        local ok = false
        if type(response) == "table" and response.statusCode == 200 then
          ok = true
        end
        -- Log details safely (truncate body, avoid secrets)
        local status = response and response.statusCode or "(nil)"
        local err = response and response.error and ToEnumShortString(response.error) or nil
        local body = response and response.body or ""
        if type(body) ~= "string" then body = tostring(body) end
        if #body > 256 then body = body:sub(1, 256) .. "…" end
        debugPrint("Hello-check: status=" .. tostring(status) .. (err and (" error=" .. err) or "") .. " body=" .. body)

        if ok then
          bmt:settext("✔ Arrow Cloud")
        else
          bmt:settext("❌ Arrow Cloud")
          if err == "Blocked" then
            errMsg:settext("Host not configured in Preferences.ini\nAdd \"*.arrowcloud.dance\" to HttpAllowHosts")
          end
        end
      end
    }
  end,

  -- The text node we update
  LoadFont("Common Normal") .. {
    Name = "Status",
    InitCommand = function(self)
      self:halign(1)
      self:settext("Arrow Cloud")
    end
  },

  LoadFont("Common Normal") .. {
    Name = "ErrorMessage",
    InitCommand = function(self)
      self:xy(0, 24):halign(1)
      self:zoom(0.6)
      self:settext("")
    end
  }
}

return moduleRegistration
