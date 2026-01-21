# 🌳 Lua*u*Parser
 
![Ver](https://img.shields.io/badge/version-v0.705-blue) ![License](https://img.shields.io/github/license/vantoanvh/LuauParser) [![Docs](https://img.shields.io/badge/documentation-online-red?logo=github)](https://vantoanvh.github.io/LuauParser) [![Release](https://img.shields.io/badge/release-latest-blue?logo=lua&logoColor=white)](https://github.com/vantoanvh/LuauParser/releases/latest)

A modern, fully featured **[Lua*u*](https://luau.org/)** parser written entirely in Luau<br>
Fully type-checked with the New Type Solver and optimized for high performance.

## Introduction
A complete port of **[Parser.cpp](https://github.com/luau-lang/luau/blob/master/Ast/src/Parser.cpp)** providing both *AST* **(Abstract Syntax Tree)** & *CST* **(Concrete Syntax Tree)**.<br>
**To stay true to the original implementation**, the CST does not include low-level trivia such as whitespace.

This Lua*u* parser is primarily intended for plugin development and for building Lua*u* compilers or tooling. It provides detailed syntax information through both **AST** and **CST** representations, making it well suited for advanced language tooling such as linters, formatters, highlighter, refactoring tools, or even a full lua*u* compiler/transpiler.
## Usage
```luau
local Parser = require(path.to.LuauParser)

local success, result = Parser.parse('local foo: (string, ...number) -> (...any)')

if success then
	print(result.root) -- do anything you want
else
	warn(result.errors)
end
```
