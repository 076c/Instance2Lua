--!strict
-- Instance2Lua
-- Convert any Roblox Instance into a Lua code snippet
-- that when ran, reproduces that instance.

-- For the ease of coding and integratability, this has all been compressed
-- into one script.

export type ExpressionBase = {
	kind: string,
}

export type NilNode = ExpressionBase & {
	kind: "Nil",
}

export type VarargNode = ExpressionBase & {
	kind: "VarargNode",
}

export type StringNode = ExpressionBase & {
	kind: "StringNode",
	string: string,
}

export type NumberNode = ExpressionBase & {
	kind: "NumberNode",
	number: number,
}

export type BooleanNode = ExpressionBase & {
	kind: "BooleanNode",
	boolean: boolean,
}

export type TableConstructorNode = ExpressionBase & {
	kind: "TableConstructorNode",
	entries: { TableEntryKind },
}

export type GlobalAccessNode = ExpressionBase & {
	kind: "GlobalAccessNode",
	globalIndex: string,
}

export type ElementAccessNode = ExpressionBase & {
	kind: "ElementAccessNode",
	base: Expression,
	index: Expression,
}

export type ExpressionListNode = ExpressionBase & {
	kind: "ExpressionListNode",
	list: { Expression },
}

export type FunctionInvocationNode = ExpressionBase & {
	kind: "FunctionInvocationNode",
	caller: Expression,
	arguments: ExpressionListNode,
}

export type BinaryOperationNode = ExpressionBase & {
	kind: "BinaryOperationNode",
	left: Expression,
	right: Expression,
	operator: string,
}

export type UnaryOperationNode = ExpressionBase & {
	kind: "UnaryOperationNode",
	expression: Expression,
	prefix: string,
}

export type ClosureNode = ExpressionBase & {
	kind: "ClosureNode",
	body: StatementListNode,
	parameters: ExpressionListNode,
	variadic: boolean,
}

export type MethodInvokationNode = ExpressionBase & {
	kind: "MethodInvokationNode",
	caller: Expression,
	method: string,
	arguments: ExpressionListNode,
}

export type Expression =
	NilNode
	| NumberNode
	| StringNode
	| BooleanNode
	| GlobalAccessNode
	| ElementAccessNode
	| ExpressionListNode
	| FunctionInvocationNode
	| BinaryOperationNode
	| UnaryOperationNode
	| ClosureNode
	| MethodInvokationNode
	| TableConstructorNode

export type StatementBase = {
	kind: string,
}

export type AssignmentNode = StatementBase & {
	kind: "AssignmentNode",
	left: Expression,
	right: Expression,
	isLocal: boolean,
}

export type StatementListNode = StatementBase & {
	kind: "StatementList",
	list: { Statement },
}

export type ReturnNode = StatementBase & {
	kind: "ReturnNode",
	expressions: ExpressionListNode,
}

export type Statement =
	AssignmentNode
	| StatementListNode
	| ReturnNode

export type Node = Statement | Expression

export type TableEntryKindBase = {
	kind: string
}

export type KeyedTableEntryKind = TableEntryKindBase & {
	kind: "KeyedTableEntryKind",
	key: Expression,
	value: Expression,
}

export type ExpressionTableEntryKind = TableEntryKindBase & {
	kind: "ExpressionTableEntryKind",
	expression: Expression,
}

export type TableEntryKind =
	KeyedTableEntryKind
	| ExpressionTableEntryKind

-- Services
local HttpService = game:GetService("HttpService")

-- Helper functions

-- Maps an array using a mapper function
local function map<T, U>(array: { T }, mapper: (T) -> U): { U }
	local mapped = {}
	for _, value in array do
		table.insert(mapped, mapper(value))
	end
	return mapped
end

-- Chains two arrays together by moving all of the values
-- from the second array into the first.
-- The second array is left emtpy.
local function chain<T>(arr1: { T }, arr2: { T }): { T }
	for i = 1, #arr2 do
		local v = table.remove(arr2)

		table.insert(arr1, v)
	end

	return arr1
end

-- Turns any string into a quoted string
local function formatQuotedString(str: string): string
	local formattedStr = ""
	
	for i = 1, #str do
		local code = str:byte(i, i)
		
		if code >= 32 and code <= 0x7E then
			formattedStr = formattedStr .. str:sub(i, i)
		else
			formattedStr = formattedStr .. string.format("\\%03d", code)
		end
	end
	
	return "\""
		.. formattedStr
			:gsub("\n", "\\n")
			:gsub("\"", "\\\"")
			:gsub("\t", "\\t")
			:gsub("\r", "\\r")
		.. "\""
end

-- Constants
local API_DUMP = HttpService:JSONDecode(HttpService:GetAsync("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/refs/heads/roblox/API-Dump.json", true))

local INDENT_STRING = string.rep(" ", 4)

-- Properties of every type we custom parse
local PROPERTIES = {
	CatalogSearchParams = {
		"Limit",
		"MaxPrice",
		"SearchKeyword",
		"MinPrice",
		"SortType",
		"SortAggregation",
		"CategoryFilter",
		"SalesTypeFilter",
		"BundleTypes",
		"AssetTypes",
		"IncludeOffSale",
		"CreatorName",
		"CreatorType",
		"CreatorId",
		"Limit",
	}
}
--[[
	-- Remap enum entries to avoid O(1) wherever possible
	local ENUM_ENTRIES = {}

	for _, enum in ipairs(API_DUMP.Enums) do
		local entries = {}
		
		for _, item in ipairs(enum.Items) do
			entries[item.Name] = item
		end
		
		ENUM_ENTRIES[enum.Name] = entries
	end
]]

local Instance2Lua = {}

-- AST
do
	local ast = {}

	-- Creates a new NilNode.
	-- Luau: `nil`
	function ast.NilNode(): NilNode
		return {
			kind = "NilNode",
		} :: NilNode
	end

	-- Creates a new VarargNode.
	-- Luau: `...`
	function ast.VarargNode(): VarargNode
		return {
			kind = "VarargNode",
		} :: VarargNode
	end

	-- Creates a new StringNode with the given string `string`.
	-- Luau: (string)
	function ast.StringNode(string: string): StringNode
		return {
			kind = "StringNode",
			string = string,
		} :: StringNode
	end

	-- Creates a new NumberNode with the given number `number`.
	-- Luau: (number)
	function ast.NumberNode(number: number): NumberNode
		return {
			kind = "NumberNode",
			number = number,
		} :: NumberNode
	end

	-- Creates a new BooleanNode with the given boolean `boolean`.
	-- Luau: (boolean)
	function ast.BooleanNode(boolean: boolean): BooleanNode
		return {
			kind = "BooleanNode",
			boolean = boolean,
		} :: BooleanNode
	end

	-- Sub-class of AST
	ast.TableEntryKinds = {}

	-- Creates a new KeyedTableEntryKind with the given key and value.
	-- Luau: ![ [(K)] = (V) || (K) = (V) ]
	function ast.TableEntryKinds.KeyedTableEntryKind(key: Expression, value: Expression): KeyedTableEntryKind
		return {
			kind = "KeyedTableEntryKind",
			key = key,
			value = value,
		} :: KeyedTableEntryKind
	end
	
	-- Creates a new ExpressionTableEntryKind with the given value.
	-- Luau: [ (V) ]
	function ast.TableEntryKinds.ExpressionTableEntryKind(expression: Expression): ExpressionTableEntryKind
		return {
			kind = "ExpressionTableEntryKind",
			expression = expression,
		} :: ExpressionTableEntryKind
	end

	-- Creates a new TableConstructorNode with the given list of entries `entries`.
	-- Luau: { ![ [(K that is not String)] = (V) || (K is String) = (V) || (V) ] }
	function ast.TableConstructorNode(entries: { TableEntryKind }): TableConstructorNode
		return {
			kind = "TableConstructorNode",
			entries = entries,
		} :: TableConstructorNode
	end

	-- Creates a new GlobalAccessNode with the given global index `globalIndex`.
	-- Luau: (globalIndex as String)
	function ast.GlobalAccessNode(globalIndex: string): GlobalAccessNode
		return {
			kind = "GlobalAccessNode",
			globalIndex = globalIndex,
		} :: GlobalAccessNode
	end

	-- Creates a new ElementAccessNode with the given base `base` and the indexer `index`.
	-- Luau: (base)[(index)]
	function ast.ElementAccessNode(base: Expression, index: Expression): ElementAccessNode
		return {
			kind = "ElementAccessNode",
			base = base,
			index = index,
		} :: ElementAccessNode
	end

	-- Creates a new ExpressionListNode with the given list of expressions `expressions`.
	-- Luau: (expressions as Tuple)
	function ast.ExpressionListNode(...: Expression): ExpressionListNode
		return {
			kind = "ExpressionListNode",
			list = {...},
		} :: ExpressionListNode
	end

	-- Creates a new FunctionInvocationNode with the given arguments `arguments`.
	-- Luau: (function)(arguments)
	function ast.FunctionInvocationNode(
		caller: Expression,
		arguments: ExpressionListNode
	): FunctionInvocationNode
		return {
			kind = "FunctionInvocationNode",
			caller = caller,
			arguments = arguments,
		} :: FunctionInvocationNode
	end

	-- Creates a new MethodInvokationNode with the given method `method` and the given
	-- arguments `arguments`.
	-- Luau: (caller):(method)(arguments)
	function ast.MethodInvokationNode(
		caller: Expression,
		method: string,
		arguments: ExpressionListNode
	): MethodInvokationNode
		return {
			kind = "MethodInvokationNode",
			caller = caller,
			method = method,
			arguments = arguments,
		} :: MethodInvokationNode
	end

	-- Creates a new BinaryOperationNode with the given left and right expressions and the operator `op`.
	-- Luau: (left) (op) (right)
	function ast.BinaryOperationNode(
		left: Expression,
		right: Expression,
		op: string
	): BinaryOperationNode
		return {
			kind = "BinaryOperationNode",
			left = left,
			right = right,
			op = op,
		} :: BinaryOperationNode
	end

	-- Creates a new UnaryOperationNode with the given expression and prefix `prefix`.
	-- Luau: (prefix)(exp)
	function ast.UnaryOperationNode(
		expression: Expression,
		prefix: string
	): UnaryOperationNode
		return {
			kind = "UnaryOperationNode",
			expression = expression,
			prefix = prefix,
		} :: UnaryOperationNode
	end

	-- Creates a new ClosureNode with the given body `body`.
	-- Luau: function((parameters)) (body) end
	function ast.ClosureNode(
		body: StatementListNode,
		parameters: ExpressionListNode,
		variadic: boolean
	): ClosureNode
		return {
			kind = "ClosureNode",
			body = body,
			parameters = parameters,
			variadic = variadic,
		} :: ClosureNode
	end

	-- Creates a new AssignmentNode with the given left and right expressions.
	-- Luau: local (left) = (right)
	function ast.AssignmentNode(
		left: Expression,
		right: Expression,
		isLocal: boolean
	): AssignmentNode
		return {
			kind = "AssignmentNode",
			left = left,
			right = right,
			isLocal = isLocal,
		} :: AssignmentNode
	end

	-- Creates a new ReturnNode with the given expression `expressions`
	-- Luau: return (expressions)
	function ast.ReturnNode(expressions: ExpressionListNode): ReturnNode
		return {
			kind = "ReturnNode",
			expressions = expressions,
		} :: ReturnNode
	end

	-- Creates a new StatementListNode with the given list of statements `statements`.
	function ast.StatementListNode(...: Statement): StatementListNode
		return {
			kind = "StatementListNode",
			list = {...},
		} :: StatementListNode
	end
	
	function ast.TableEntryKindToString(tableEntryKind: TableEntryKind, depth: number?): string
		if tableEntryKind.kind == "KeyedTableEntryKind" then
			if tableEntryKind.key.kind == "StringNode" and tableEntryKind.key.string:match("^[%a_][%w_]*$") then
				return `{tableEntryKind.key.string} = {ast.NodeToString(tableEntryKind.value, depth)}`
			else
				return `[{ast.NodeToString(tableEntryKind.key, depth)}]  = {ast.NodeToString(tableEntryKind.value, depth)}`
			end
		elseif tableEntryKind.kind == "ExpressionTableEntryKind" then
			return `{ast.NodeToString(tableEntryKind.expression, depth)}`
		else
			error("=> Instance2Lua: Unknown table entry kind.")
		end
	end
	
	-- Converts any node into a string
	function ast.NodeToString(node: Node, depth: number?): string
		if node.kind == "NilNode" then
			return "nil"
		elseif node.kind == "StringNode" then
			return formatQuotedString(node.string)
		elseif node.kind == "NumberNode" then
			return tostring(node.number)
		elseif node.kind == "BooleanNode" then
			return node.boolean and "true" or "false"
		elseif node.kind == "GlobalAccessNode" then
			return node.globalIndex
		elseif node.kind == "ElementAccessNode" then
			-- If possible, use the dot notation instead
			if node.index.kind == "StringNode" and node.index.string:match("^[%a_][%w_]*$") then
				return `{ast.NodeToString(node.base)}.{node.index.string}`
			end

			return `{ast.NodeToString(node.base)}[{ast.NodeToString(node.index)}]`
		elseif node.kind == "ExpressionListNode" then
			return table.concat(map(node.list, function(e: Expression): string
				return ast.NodeToString(e)
			end), ", ")
		elseif node.kind == "FunctionInvocationNode" then
			local needsParen = true
			
			if
				node.caller.kind == "FunctionInvocationNode"
					or node.caller.kind == "ElementAccessNode"
					or node.caller.kind == "GlobalAccessNode"
			then
				needsParen = false
			end
			
			return `{needsParen and `({ast.NodeToString(node.caller)})` or ast.NodeToString(node.caller)}({ast.NodeToString(node.arguments)})`
		elseif node.kind == "BinaryOperationNode" then
			return `{ast.NodeToString(node.left)} {node.operator} {ast.NodeToString(node.right)}`
		elseif node.kind == "UnaryOperationNode" then
			local expression = ast.NodeToString(node.expression)
			local prefix = node.prefix

			-- Keyword unary operators require whitespace:
			-- `not x`, `typeof x`
			--
			-- Symbolic unary operators don't:
			-- `-x`, `+x`, `~x`
			if prefix:match("^[%a_][%w_]*$") then
				return `{prefix} {expression}`
			else
				-- Prevent `--x` from being interpreted as a comment.
				if prefix == "-" and expression:sub(1, 1) == "-" then
					return `- {expression}`
				end

				return `{prefix}{expression}`
			end
		elseif node.kind == "ClosureNode" then
			local parameters = (table.concat :: any)((chain :: any)(map(node.parameters.list, function(p: Expression)
				return ast.NodeToString(p) :: string
			end), if node.variadic then { ast.VarargNode() } else {}), ", ")

			local indent = string.rep(INDENT_STRING, depth or 0)
			local bodyIndent = string.rep(INDENT_STRING, (depth or 0) + 1)

			return `function({parameters})\n`
				.. table.concat(map(node.body.list, function(stmt: Statement)
					return bodyIndent .. ast.NodeToString(stmt, (depth or 0) + 1) .. "\n"
				end))
				.. indent .. "end"
		elseif node.kind == "AssignmentNode" then
			return `{if node.isLocal then "local " else ""}{ast.NodeToString(node.left)} = {ast.NodeToString(node.right)}`
		elseif node.kind == "StatementList" then
			return table.concat(map(node.list, function(e: Statement): string
				return ast.NodeToString(e)
			end))
		elseif node.kind == "ReturnNode" then
			return `return {ast.NodeToString(node.expressions)}`
		elseif node.kind == "TableConstructorNode" then
			if #node.entries == 0 then
				return "{}"
			end
			
			local indent = string.rep(INDENT_STRING, depth or 0)
			local bodyIndent = string.rep(INDENT_STRING, (depth or 0) + 1)
			
			local formattedEntries = table.concat(map(node.entries, function(field: TableEntryKind): string
				return bodyIndent .. ast.TableEntryKindToString(field, (depth or 0) + 1)
			end), ",\n")
			
			return "{\n"
				.. formattedEntries
				.. "\n" .. indent .. "}"
		else
			error(`=> Instance2Lua: Unknown node type: {node.kind}`)
		end
	end

	Instance2Lua.AST = ast
end

local ast = Instance2Lua.AST

-- Serializes a value of any type into an expression.
function Instance2Lua:SerializeValueIntoExpression<T>(value: T): Expression
	local type = typeof(value)

	if type == "nil" then
		return ast.NilNode()
	elseif type == "string" then
		return ast.StringNode(value)
	elseif type == "number" then
		return ast.NumberNode(value)
	elseif type == "boolean" then
		return ast.BooleanNode(value)
	elseif type == "Vector3" then
		return ast.FunctionInvocationNode(
			ast.ElementAccessNode(ast.GlobalAccessNode("Vector3"), ast.StringNode("new")),
			ast.ExpressionListNode(
				ast.NumberNode((value :: Vector3).X),
				ast.NumberNode((value :: Vector3).Y),
				ast.NumberNode((value :: Vector3).Z)
			)
		)
	elseif type == "table" then
		local fields = {}
		
		for key, value in pairs(value) do
			table.insert(
				fields,
				ast.TableEntryKinds.KeyedTableEntryKind(
					Instance2Lua:SerializeValueIntoExpression(key),
					Instance2Lua:SerializeValueIntoExpression(value)
				)
			)
		end
		
		return ast.TableConstructorNode(fields)
	elseif type == "CFrame" then
		local x, y, z,
			r00, r01, r02,
			r10, r11, r12,
			r20, r21, r22 = (value :: CFrame):GetComponents()

		local argumentsOrdered = map({
			x, y, z,
			r00, r01, r02,
			r10, r11, r12,
			r20, r21, r22
		}, function(n: number): Expression
			return ast.NumberNode(n)
		end)

		return ast.FunctionInvocationNode(
			ast.ElementAccessNode(ast.GlobalAccessNode("CFrame"), ast.StringNode("new")),
			ast.ExpressionListNode(unpack(argumentsOrdered))
		)
	elseif type == "Color3" then
		return ast.FunctionInvocationNode(
			ast.ElementAccessNode(ast.GlobalAccessNode("Color3"), ast.StringNode("new")),
			ast.ExpressionListNode(
				ast.NumberNode((value :: Color3).R),
				ast.NumberNode((value :: Color3).G),
				ast.NumberNode((value :: Color3).B)
			)
		)
	elseif type == "BrickColor" then
		return ast.FunctionInvocationNode(
			ast.ElementAccessNode(ast.GlobalAccessNode("BrickColor"), ast.StringNode("new")),
			ast.ExpressionListNode(ast.NumberNode((value :: BrickColor).Number))
		)
	elseif type == "AdReward" then
		-- TODO: Unfortunately, Roblox doesn't allow us to index this type
		-- to extract data. The only way we can do this is by converting
		-- the value into a string and then pattern matching the product ID.

		local pat = "productId = (%d+)"
		local str = tostring(value :: AdReward)

		local productId = str:match(pat)

		if not productId then
			error(`=> Instance2Lua: Failed to extract AdReward product ID from string: {str}`)
		end

		return ast.MethodInvokationNode(
			ast.MethodInvokationNode(
				ast.GlobalAccessNode("game"),
				"GetService",
				ast.ExpressionListNode(ast.StringNode("AdService"))
			),
			"CreateAdRewardFromDevProductId",
			ast.ExpressionListNode(ast.NumberNode(tonumber(productId) or error("=> Instance2Lua: Product ID is not a number.")))
		)
	elseif type == "Axes" then
		local baseEnumAxisEntry = ast.ElementAccessNode(ast.GlobalAccessNode("Enum"), ast.StringNode("Axis"))

		local arguments = {}

		for _, axis in ipairs({ "X", "Y", "Z" }) do
			if (value :: any)[axis] then
				table.insert(arguments, ast.ElementAccessNode(baseEnumAxisEntry, ast.StringNode(axis)))
			end
		end

		return ast.FunctionInvocationNode(
			ast.ElementAccessNode(ast.GlobalAccessNode("Axes"), ast.StringNode("new")),
			ast.ExpressionListNode(unpack(arguments))
		)
	elseif type == "CatalogSearchParams" then
		local var = ast.GlobalAccessNode("searchParams")
		
		local propertyAssignments = {}
		
		for _, property in ipairs(PROPERTIES.CatalogSearchParams) do
			local value = (value :: any)[property]
			
			if value == nil then
				continue
			end
			
			table.insert(propertyAssignments, ast.AssignmentNode(
				ast.ElementAccessNode(var, ast.StringNode(property)),
				Instance2Lua:SerializeValueIntoExpression(value),
				false
			))
		end
		
		local body = {
			ast.AssignmentNode(
				var,
				ast.FunctionInvocationNode(
					ast.ElementAccessNode(ast.GlobalAccessNode("CatalogSearchParams"), ast.StringNode("new")),
					ast.ExpressionListNode()
				),
				true
			),
		}
		
		for _, stmt in ipairs(propertyAssignments) do
			table.insert(body :: any, stmt)
		end
		
		table.insert(body :: any, ast.ReturnNode(ast.ExpressionListNode(var)))
		
		return ast.FunctionInvocationNode(
			ast.ClosureNode(
				ast.StatementListNode(
					unpack(body)
				),
				ast.ExpressionListNode(),
				false
			),
			ast.ExpressionListNode()
		)
	elseif type == "EnumItem" then
		-- This method doesn't use the Roblox API
		-- although it's very bad and not recommended
		return ast.ElementAccessNode(
			ast.ElementAccessNode(
				ast.GlobalAccessNode("Enum"),
				ast.StringNode(tostring((value ::EnumItem).EnumType))
			),
			ast.StringNode((value ::EnumItem).Name)
		)
	elseif type == "Enum" then
		return ast.ElementAccessNode(ast.GlobalAccessNode("Enum"), ast.StringNode(tostring(value)))
	elseif type == "Collection" then
		-- ? This method doesn't exist in Studio, but the official
		-- ? Roblox docs have it?
		-- ? https://create.roblox.com/docs/reference/engine/classes/CollectionService#CreateCollection
		return ast.MethodInvokationNode(
			ast.MethodInvokationNode(
				ast.GlobalAccessNode("game"),
				"GetService",
				ast.ExpressionListNode(ast.StringNode("CollectionService"))
			),
			"CreateCollection",
			ast.ExpressionListNode()
		)
	elseif type == "ColorSequenceKeypoint" then
		return ast.FunctionInvocationNode(
			ast.ElementAccessNode(
				ast.GlobalAccessNode("ColorSequenceKeypoint"),
				ast.StringNode("new")
			),
			ast.ExpressionListNode(
				ast.NumberNode((value :: ColorSequenceKeypoint).Time),
				Instance2Lua:SerializeValueIntoExpression((value :: ColorSequenceKeypoint).Value)
			)
		)
	elseif type == "ColorSequence" then
		return ast.FunctionInvocationNode(
			ast.ElementAccessNode(
				ast.GlobalAccessNode("ColorSequence"),
				ast.StringNode("new")
			),
			ast.ExpressionListNode(
				map((value :: ColorSequence).Keypoints, function(keyPoint: ColorSequenceKeypoint): Expression
					return Instance2Lua:SerializeValueIntoExpression(keyPoint)
				end)
			)
		)
	else -- unknown
		error(`=> Instance2Lua: Encountered unknown value type when serializing: {type}`)
	end
end

return Instance2Lua
