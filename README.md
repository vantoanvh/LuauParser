<div align="center">

# Lua*u*Parser

![Ver](https://img.shields.io/badge/version-0.705-blue) ![License](https://img.shields.io/github/license/vantoanvh/LuauParser) [![Docs](https://img.shields.io/badge/documentation-online-red)](https://vantoanvh.github.io/LuauParser/)

A modern, fully featured **[Lua*u*](https://luau.org/)** parser written entirely in Luau<br>
Fully type-checked with the New Type Solver and optimized for high performance.

</div>

## Introduction
A complete port of **[Parser.cpp](https://github.com/luau-lang/luau/blob/master/Ast/src/Parser.cpp)** providing both *AST* **(Abstract Syntax Tree)** & *CST* **(Concrete Syntax Tree)**.<br>
This Lua*u* parser is primarily intended for plugin development and for building Luau compilers or tooling.

## Public API

```luau
-- Parsing source code into: success, result
Parser.parse(source: string, options: Options): boolean, result

-- Contains Alot of quote styles
QuoteStyle: {
--[=[
		A string created using double quotes or an interpolated string,
		as in:
	
			"foo", `My name is {protagonist}! / And I'm {antagonist}!`
	]=]
	QuotedSimple = 0,
	
	--[=[
		A string created using single quotes, as in:
    
    		'bar'
	]=]
	QuotedSingle = 1,
	
	--[=[
		A string created using `[[ ... ]]` as in:
		as in:
	
			[[ Gee, this sure is a long string.
			it even has a new line in it! ]]
	]=]
	QuotedRaw = 2,
	
	--[=[
		A "string" in the context of a table literal, as in:
	
			{ foo = 42 } -- `foo` here is a "constant string"
	]=]
	Unquoted = 3,
}

-- Contains things that define node is a normal string or an interpolated string
BraceType: {Normal, InterpolatedString}

-- See what unary ops is it, could be length `#`, negative `-` or `not`
UnaryOp: {Not, Minus, Len}

-- Contains all operators, helpful for which operators `AstExprBinary` contains
BinaryOp: {
	Add, -- `+`
	Sub, -- `-`
	Mul, -- `*`
	Div, -- `/`
	FloorDiv, -- `//`
	Mod, -- `%`
	Pow, -- `^`
	Concat, -- `..`
	CompareNe, -- `~=`
	CompareEq, -- `==`
	CompareLt, -- `<`
	CompareLe, -- `<=`
	CompareGt, -- `>`
	CompareGe, -- `>=`
	And, -- `and`
	Or -- `or`
}

-- Contains what a CstExprConstantString's style
CstQuotes = {
	QuotedSingle = 0, -- ''
	QuotedDouble = 1, -- ""
	QuotedRaw = 2, -- [[]]
	QuotedInterp = 3, -- ``
}
```


## Every options you can use currently:
```luau
{
	-- Turns off by default, Defines parser will save comments or not
	captureComments: boolean,

	-- Turns off by default, Defines parser will store CST (result.cstNodeMap) or not
	storeCstData: boolean,
}
```

## The result that returned by the Parser:
```luau
{
	-- Contains all AST nodes of the source
	root: {AstNode},

	-- Contains all the comments locations (if captureComments is enabled)
	commentLocations: {Comment},

	-- Contains all the "--!" comments
	hotcomments: {Comment},

	-- Contains all CST nodes of the source, which you can get it by indexing cstNodeMap[AstNode] = CstNode
	cstNodeMap: {[AstNode] = CstNode},

	-- Contains all parsing errors
	errors: {ParseError},
}
```
