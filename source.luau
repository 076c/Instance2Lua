-- Instance2Lua
-- To actually make this possible, we need the latest and greates API dump. https://anaminus.github.io/rbx/json/api/latest.json
-- You also need to have HttpService Enabled!
local HttpService = game:GetService("HttpService")
local Properties = HttpService:JSONDecode(HttpService:GetAsync("https://anaminus.github.io/rbx/json/api/latest.json")) -- json encoded

local TEMPLATE = {
    ["WrapInFunction"] = false, -- If yes it will wrap code in a function
    ["FunctionName"] = "", -- Function Name (only valid if WrapInFunction equals true)
    ["UseUniversalNaming"] = false,
    ["IndentUsingSpaces"] = true, -- Indents using spaces e.x: [   ] Normal: [\t]
    ["RefByClass"] = true, -- false: l_FolderName_0 true: l_Folder_0
    ["ShowInstancesSerialized"] = false, -- Shows you all the Instances that were serialized.
    ["ShowInstancesSerializedAmount"] = true -- Shows the amount of Instances serialized
}

local CodeFormats = { -- These are all the code formats
    ["NewInstanceOfClass_Parent"] = "local %s = Instance.new(%s, %s);",
    ["NewInstanceOfClass"] = "local %s = Instance.new(%s);",
    ["SetAttribute"] = "%s:SetAttribute(%s, %s);",
    ["SetValue"] = "%s['%s'] = %s;", -- To avoid errors, we will just do it like this
    ["VariableName"] = "l_%s_%d", -- lol this looks good totally not oracle frfr duh
    ["UniversalVariableName"] = "v%d"
}
type Property = {
    ["Class"]: string,
    ["Name"]: string,
    ["ValueType"]: string,
    ["tags"]: {
        {
           [number]: string
        }
    },
    ["type"]: string
}

local function GetAllTypes()
    local Types = {}
    for i, v in pairs(Properties) do
        if #Types == 0 then
            table.insert(Types, v.type)
        end
        if Types[i] ~= v.Type then
            table.insert(Types, v.type)
        end
    end
    return Types
end

local function Path(path)
    local Path = path
    local RealPath = string.split(Path, ".")
    local PathCombined = "game"
    for i, v in pairs(RealPath) do
        PathCombined ..= string.format("['%s']", v)
    end
    return PathCombined
end

function ValidateOptions(Options)
    -- Ensure Options is a table
    Options = Options or {}

    for key, defaultValue in pairs(TEMPLATE) do
        -- Only set the option if it's not already provided
        if Options[key] == nil then
            Options[key] = defaultValue
        end
    end
end

function HandleValue(val)
    local type_of = typeof(val)
    if type_of == "boolean" then
        return val
    elseif type_of == "string" then
        return string.format("'%s'", val)
    elseif type_of == "number" then
        return tostring(val)
    elseif type_of == "Color3" then
        local stuff = string.split(tostring(val), ",")
        for i, v in pairs(stuff) do
            v:gsub(" ", "")
        end
        return string.format("Color3.new(%s,%s,%s)", tostring(stuff[1]), tostring(stuff[2]), tostring(stuff[3]))
    elseif type_of == "Vector3" then
        local stuff = string.split(tostring(val), ",")
        for i, v in pairs(stuff) do
            v:gsub(" ", "")
        end
        return string.format("Vector3.new(%s,%s,%s)", tostring(stuff[1]), tostring(stuff[2]), tostring(stuff[3]))
    elseif type_of == 'CFrame' then
        local stuff = string.split(tostring(val), ",")
        for i, v in pairs(stuff) do
            v:gsub(" ", "")
        end
        return string.format("CFrame.new(%s,%s,%s)", tostring(stuff[1]), tostring(stuff[2]), tostring(stuff[3]))
    else
        return tostring(val)
    end
end

function Serialize_Instance<Instance>(Instance : Instance, Options, TotalVars)
    Options = Options or TEMPLATE
    local Code = {} -- Here we will insert our bits and pieces of code.
    ValidateOptions(Options)
    local Attributes = Instance:GetAttributes()
    local hasParent = Instance.Parent ~= nil
    local CodeBracket_Decl
    local Decl_Var = string.format(CodeFormats.VariableName, Instance.Name, TotalVars)
    if Options.UseUniversalNaming == false and Options.RefByClass == true then
        Decl_Var = string.format(CodeFormats.VariableName, Instance.ClassName, TotalVars)
    end
    if Options.UseUniversalNaming == true then
        Decl_Var = string.format(CodeFormats.UniversalVariableName, TotalVars)
    end
    if hasParent == true then
        local ClassName = string.format("'%s'", Instance.ClassName)
        CodeBracket_Decl = string.format(CodeFormats.NewInstanceOfClass_Parent, Decl_Var, ClassName, Path(Instance.Parent:GetFullName()))
    else
        local ClassName = string.format("'%s'", Instance.ClassName)
        CodeBracket_Decl = string.format(CodeFormats.NewInstanceOfClass, Decl_Var, ClassName)
    end
    local function SerializeInstance(Attributes, Instance)
        for i, v in pairs(Attributes) do
            local toset
            local type_of = typeof(v)
            if type_of == "boolean" then
                toset = v
            elseif type_of == "string" then
                toset = string.format("'%s'", v)
            elseif type_of == "number" then
                toset = tostring(v)
            elseif type_of == "Color3" then
                local stuff = string.split(tostring(v), ",")
                for i, v in pairs(stuff) do
                    v:gsub(" ", "")
                end
                toset = string.format("Color3.new(%s,%s,%s)", tostring(stuff[1]), tostring(stuff[2]), tostring(stuff[3]))
            elseif type_of == "Vector3" then
                local stuff = string.split(tostring(v), ",")
                for i, v in pairs(stuff) do
                    v:gsub(" ", "")
                end
                toset = string.format("Vector3.new(%s,%s,%s)", tostring(stuff[1]), tostring(stuff[2]), tostring(stuff[3]))
            elseif type_of == 'CFrame' then
                local stuff = string.split(tostring(v), ",")
                for i, v in pairs(stuff) do
                    v:gsub(" ", "")
                end
                toset = string.format("CFrame.new(%s,%s,%s)", tostring(stuff[1]), tostring(stuff[2]), tostring(stuff[3]))
            else
                toset = tostring(v)
            end
            table.insert(Code, string.format(CodeFormats.SetAttribute, Decl_Var, string.format("'%s'", tostring(i)), tostring(toset)))
        end
        for i, v : Property in pairs(Properties) do
            local isReadOnly = false
            for i, v in pairs(v.tags) do
                if v == "readonly" or v == "notbrowsable" or v == "deprecated" then
                    isReadOnly = true
                end
            end
            if v["type"] ~= "Function" and v["type"] ~= "Event" and not isReadOnly and v["Name"] ~= "Clone" then -- Iterate over Functions and Events
                local PropertyName = v.Name
                local is, val = pcall(function()
                    return Instance[PropertyName]
                end)
                local toset
                local type_of = typeof(val)
                if type_of == "boolean" then
                    toset = v
                elseif type_of == "string" then
                    toset = string.format("'%s'", val)
                elseif type_of == "number" then
                    toset = tostring(val)
                elseif type_of == "Color3" then
                    local stuff = string.split(tostring(val), ",")
                    for i, v in pairs(stuff) do
                        v:gsub(" ", "")
                    end
                    toset = string.format("Color3.new(%s,%s,%s)", tostring(stuff[1]), tostring(stuff[2]), tostring(stuff[3]))
                elseif type_of == "Vector3" then
                    local stuff = string.split(tostring(val), ",")
                    for i, v in pairs(stuff) do
                        v:gsub(" ", "")
                    end
                    toset = string.format("Vector3.new(%s,%s,%s)", tostring(stuff[1]), tostring(stuff[2]), tostring(stuff[3]))
                elseif type_of == 'CFrame' then
                    local stuff = string.split(tostring(val), ",")
                    for i, v in pairs(stuff) do
                        v:gsub(" ", "")
                    end
                    toset = string.format("CFrame.new(%s,%s,%s)", tostring(stuff[1]), tostring(stuff[2]), tostring(stuff[3]))
                else
                    toset = "'" .. tostring(val) .. "'"
                end
                if is == true then
                    local formatted = string.format(CodeFormats.SetValue, Decl_Var, tostring(PropertyName), tostring(val))
                    if v["Name"] == "Parent" then
                        string.format(CodeFormats.SetValue, Decl_Var, tostring(PropertyName), string.format("game['%s']", tostring(val)))
                    end
                    table.insert(Code, formatted)
                end
            end
        end
        TotalVars += 1
        table.insert(Code, CodeBracket_Decl)
    end
    local function SerializeInstances(Instance)
        SerializeInstance(Instance:GetAttributes(), Instance)
        for i, v in pairs(Instance:GetChildren()) do
            SerializeInstances(v)
        end
    end
    SerializeInstances(Instance)
    return Code, TotalVars
end

local Header = [[
-- Generated using Instance2Lua: https://github.com/076c/Instance2Lua/
-- Took %d seconds
]]

local function SerializeFolderToScript(Folder : Folder, Options)
    local beingTime = tick()
    Options = Options or TEMPLATE
    local InstancesSerialized = {}
    local Code = {} -- Here we will insert our bits and pieces of code.
    ValidateOptions(Options)
    local TotalVariables = 0
    local Indent = 0
    local function table_insert(tabl, value)
        if Options.IndentUsingSpaces then
            table.insert(tabl, (tostring(string.rep("    ", Indent)) .. (tostring(value))))
        else
            table.insert(tabl, (tostring(string.rep("\t", Indent)) .. (tostring(value))))
        end
    end
    local FunctionName
    if Options.WrapInFunction == true and Options.FunctionName == "" then
        FunctionName = string.format("create_%s", Folder.ClassName)
    end
    if Options.WrapInFunction == true then
        table_insert(Code, string.format("local function %s()", FunctionName))
        Indent += 1
    end
    local tab, totalVars = Serialize_Instance(Folder, Options, TotalVariables)
    for i, v in pairs(tab) do
        table_insert(Code, v)
    end
    for i, v in pairs(Folder:GetChildren()) do
        local tab, totalvars = Serialize_Instance(v, Options, TotalVariables)
        table.insert(InstancesSerialized, v.Name)
        for i, v in pairs(tab) do
            table_insert(Code, v)
        end
        TotalVariables = totalvars
    end
    if Options.WrapInFunction == true then
        Indent -= 1
        table_insert(Code, "end;")
    end
    local header1 = ""
    local header2 = ""
    if Options.ShowInstancesSerializedAmount then
        header1 = string.format("--Instances Serialized: %d", #InstancesSerialized)
    end
    if Options.ShowInstancesSerialized then
        header2 = string.format("-- Instances Serialized: {%s}", table.concat(InstancesSerialized, ", "))
    end
    local timetaken = tick() - beingTime
    local formattedHeader = string.format(Header, timetaken)
    return formattedHeader ..  header1 .. "\n" .. header2 .. "\n" .. table.concat(Code, "\n")
end

export type Options = OPTIONS

return {
    SerializeFolder = SerializeFolderToScript,
    SerializeInstance = Serialize_Instance
}
