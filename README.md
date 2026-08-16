# Instance2Lua
Instance2Lua is a module that aims to reconstruct any Instance (or Roblox data type) into static Lua code that can accurately restore the Instance
to it's original state.

# Where is the source code?
The old (and deprecated) source code can be found within `source.luau`. The new rewrite version (which is work in progress) can be found under `rewrite.luau`.

# How does this work?
Instance2Lua uses a custom-written Abstract Syntax Tree module to interpret any datatype with statements and expressions. You can
then run optimizations on that tree, or convert it to Lua source code using to `NodeToString` function.

# Why?
Instance2Lua was originally designed for places where importing Roblox XML-encoded/binary-encoded models is impossible (for example in Scripts).
This aims to fix that by encoding the instances in a syntax tree instead of XML/binary.

# Usage
To use this, simply paste the source code from this GitHub repository in your game (or alternatively, make the script perform a `require`-`loadstring` chain) to import
the module.

```luau
local colorSyntaxTree = Instance2Lua:SerializeValueIntoExpression(Color3.new(1, 1, 1))

print(Instance2Lua.AST.NodeToString(colorSyntaxTree))
```

# NOTE:
- The API will change over time, with new adjustments since this rewrite was kind of rushed.
- There are a lot of unhandled Roblox types (including Instances, which will be added last).
- The AST follows a Roslyn-style naming convention adapted to Luau (to not complicate things).
