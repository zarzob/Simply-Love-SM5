-- Minimal ArrowCloud helper (logging-only phase)
-- Provides a single function ArrowCloudRequest(chartHash) that fetches
-- /v1/charts/{hash}/leaderboards and appends the raw JSON (or error metadata)
-- as one JSON object per line to a log file.

SL = SL or {}
SL.ArrowCloud = SL.ArrowCloud or {
	Enabled = true,
	-- Current temporary API base (no trailing slash)
	BaseURL = "https://api.arrowcloud.dance",
	RequestTimeout = 5,
	LogPath = THEME:GetCurrentThemeDirectory() .. "Other/ArrowCloud_Responses.ndjson"
}

local function AppendJSONLine(path, jsonLine)
	-- Naive append: read existing (if small) then rewrite with added line.
	-- For early phase low volume usage this is acceptable. Optimize later if needed.
	local existing = nil
	if FILEMAN:DoesFileExist(path) then
		local rf = RageFileUtil:CreateRageFile()
		if rf:Open(path, 1) then
			existing = rf:Read()
		end
		rf:destroy()
	end
	local wf = RageFileUtil:CreateRageFile()
	if wf:Open(path, 2) then
		if existing and #existing > 0 then
			wf:Write(existing .. "\n" .. jsonLine)
		else
			wf:Write(jsonLine)
		end
	end
	wf:destroy()
end

ArrowCloudRequest = function(chartHash)

	-- If config table disappeared (e.g. SL reassigned), recreate minimal default
	if SL and SL.ArrowCloud == nil then
		SL.ArrowCloud = {
			Enabled = true,
			BaseURL = "https://api.arrowcloud.dance",
			RequestTimeout = 5,
			LogPath = THEME:GetCurrentThemeDirectory() .. "Other/ArrowCloud_Responses.ndjson"
		}
		-- silently reinitialize if missing
	end

	if not SL.ArrowCloud or not SL.ArrowCloud.Enabled then
		SM("ArrowCloud: Disabled or not configured")
		return
	end
	if not chartHash or #chartHash == 0 then 
    SM("ArrowCloud: No chart hash provided")
    return 
  end

	-- Prefer P1 key, else P2.
	local apiKey = (SL.P1 and SL.P1.ArrowCloudApiKey and #SL.P1.ArrowCloudApiKey>0) and SL.P1.ArrowCloudApiKey
		or (SL.P2 and SL.P2.ArrowCloudApiKey and #SL.P2.ArrowCloudApiKey>0) and SL.P2.ArrowCloudApiKey

	local headers = {}
	local masked = nil
	if apiKey and #apiKey > 0 then
		headers["Authorization"] = "Bearer " .. apiKey
		-- Mask API key for on-screen debug (show first 4 + last 4 if long enough)
		if #apiKey > 8 then
			masked = apiKey:sub(1,4) .. string.rep("*", #apiKey-8) .. apiKey:sub(-4)
		else
			masked = string.rep("*", #apiKey)
		end
	end

	-- Request (debug output removed for cleanliness)

	NETWORK:HttpRequest{
		url = SL.ArrowCloud.BaseURL .. "/v1/chart/" .. chartHash .. "/leaderboards",
		method = "GET",
		headers = headers,
		connectTimeout = SL.ArrowCloud.RequestTimeout,
		transferTimeout = SL.ArrowCloud.RequestTimeout,
			onResponse = function(res)
			local out = {
				chartHash = chartHash,
				statusCode = res.statusCode,
				error = res.error and ToEnumShortString(res.error) or nil,
				body = res.body, -- keep raw body even on non-200 for debugging
			}
			local encoded = JsonEncode(out)
			if encoded then
				AppendJSONLine(SL.ArrowCloud.LogPath, encoded)
			end
			if out.error then
				SM("ArrowCloud: response error status=" .. tostring(out.statusCode) .. " err=" .. tostring(out.error))
			else
				-- SM("ArrowCloud: response ok status=" .. tostring(out.statusCode) .. " logged")
			end
		end
	}
end
