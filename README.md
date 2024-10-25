# Instance2Lua
Converts Roblox Instances to Lua Code using the latest API dump (Relies on HttpService)


#How do i use it?

```luau
-- [[ Example Usage ]]
local roblox_httpget = function(url)
    return game.HttpService:GetAsync(url, true)
end
local httpget_loaders = function(url)
    return game:HttpGet(url, true)
end

httpget = roblox_httpget or httpget_loaders or httpget or get or https_get or httpsget or gethttp -- Add your HTTP function here

local Serializer = --later bruh forgot to copy url```
