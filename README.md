# [0.705] Luau Parser in pure Luau
Entire port of [Parser.cpp](https://github.com/luau-lang/luau/blob/master/Ast/src/Parser.cpp) (Lua*u* **[0.705]** Parser) both AST ( Abstract Syntax Tree ) & CST ( Concrete Syntax Tree ).
Not trying to misleading but this is a "full" port, so the CST won't have things like whitespace trivia.

Currently not built for speed, but still pretty fast.

Lua*u* Parser only useful when building plugins or creating Lua*u* compilers.

# Public API

```luau
-- Parsing source code into: success, result
Parser.parse(source: string, options: Options): boolean, result

-- Contains Single ' or Double ", get string quotes from "ExprConstantString" nodes
QuoteStyle: {Single, Double}

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
# Change logs
Finally! Type-checking added! That was long! It's not that type-check that properly but it works! stict-typing of course with luau's NewTypeSolver.
Autocomplete when parsing now visible, so you can see what types is it, make it wayy easier to use.

# Documentations
There's no AST and CST documentation for now, but In the future, I could build a documentation for better usability for sure
