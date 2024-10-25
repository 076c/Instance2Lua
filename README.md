# Instance2Lua
Converts Roblox Instances to Lua Code using the latest API dump (Relies on HttpService)


# How do i use it?

```luau
-- [[ Example Usage ]]
local roblox_httpget = function(url)
    return game.HttpService:GetAsync(url, true)
end
local httpget_loaders = function(url)
    return game:HttpGet(url, true)
end

httpget = roblox_httpget or httpget_loaders or httpget or get or https_get or httpsget or gethttp -- Add your HTTP function here

local Serializer = loadstring(httpget("https://github.com/076c/Instance2Lua/blob/main/source.luau"))()

local path = game:service("Workspace"):WaitForChild("Folder")
local OPTIONS: Serializer.Options = {
    ["WrapInFunction"] = true, -- If yes it will wrap code in a function
    ["FunctionName"] = "", -- Function Name (only valid if WrapInFunction equals true)
    ["UseUniversalNaming"] = false,
    ["IndentUsingSpaces"] = true, -- Indents using spaces e.x: [   ] Normal: [\t]
    ["RefByClass"] = false, -- false: l_FolderName_0 true: l_Folder_0
    ["ShowInstancesSerialized"] = true, -- Shows you all the Instances that were serialized.
    ["ShowInstancesSerializedAmount"] = true -- Shows the amount of Instances serialized
}
local serialized = Serializer.SerializeFolder(path, OPTIONS)
```
# Requirements

- HttpGet Function that gets HTTP stuff (or just paste the entire 3k loc into a module and require it)
- loadstring (or do the first step)
