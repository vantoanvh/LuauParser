# [0.703] Luau Parser in pure Luau
Entire port of [Parser.cpp](https://github.com/luau-lang/luau/blob/master/Ast/src/Parser.cpp) (Lua*u* **[0.703]** Parser) both AST & CST.
Currently not built for speed, and not type-checked properly.

Lua*u* Parser only useful when building plugins or creating Lua*u* compilers.

# Public API

```luau
-- Parsing source code into: success, result
Parser.parse(source: string, options: Options): boolean, result

-- Contains Single ' or Double ", get string quotes from "ExprConstantString" nodes
QuoteStyle: {Single, Double}
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
	cstNodeMap: {CstNode},

	-- Contains all parsing errors
	errors: {ParseError},
}
```
# Change logs
Removed some useless options and unused variables, same as internal declaration features.

# Documentations
There's no AST and CST documentation for now, but In the future, I could type-check and build a documentation for better usability for sure
