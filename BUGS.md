# Bugs

Bugs will be listed here.

# Instance expression at last:
- In code generation, the Instance serialization is last in the table thus making the entire code invalid.
- Example:
```lua
  -- Generated using Instance2Lua: https://github.com/076c/Instance2Lua/
-- Took 0 seconds
--Instances Serialized: 0
-- ...
l_Part_0['Resize'] = function: 0x7a16685e24973691;
l_Part_0['CFrame'] = -0.810000002, 1.50000501, -0.50999999, 1, 0, 0, 0, 1, 0, 0, 0, 1;
l_Part_0['Material'] = Enum.Material.Plastic;
l_Part_0['Name'] = Part;
local l_Part_0 = Instance.new('Part', game['Workspace']);```
- As you can see, the Instance decleration is last in code production.

# Several Roblox types not being supported
- A lot of Roblox types are not supported by this producer, including some vanilla types.
- Example:
```lua
l_Part_0['CFrame'] = -0.810000002, 1.50000501, -0.50999999, 1, 0, 0, 0, 1, 0, 0, 0, 1;```

# Multiple non-modifiable properties getting assigned
- Multiple non-modifiable properties are being modified in given code.
- Example:
```lua
l_Part_0['Resize'] = function: 0x7a16685e24973691;```
- As you can see, the Resize function is being modified.
