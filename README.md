<img align="right" width="220" height="220" alt="LuauParser" src="https://github.com/user-attachments/assets/69223bf1-05a5-4825-baa6-c9603cb768bf" />

<div id="toc">
  <ul style="list-style: none">
    <summary>
      <h1> LuauParser </h1>
    </summary>
  </ul>
</div>
	
![Ver](https://img.shields.io/badge/version-v0.708-blue) ![License](https://img.shields.io/github/license/vantoanvh/LuauParser) [![Docs](https://img.shields.io/badge/documentation-online-red?logo=github)](https://vantoanvh.github.io/LuauParser) [![Release](https://img.shields.io/badge/release-latest-darkblue?logo=lua&logoColor=white)](https://github.com/vantoanvh/LuauParser/releases/latest)

A modern, fully featured **[Lua*u*](https://luau.org/)** parser written entirely in Luau<br>
Fully type-checked with the New Type Solver and optimized for high performance.

## Introduction
A complete port of **[Parser.cpp](https://github.com/luau-lang/luau/blob/master/Ast/src/Parser.cpp)** providing both *AST* **(Abstract Syntax Tree)** & *CST* **(Concrete Syntax Tree)**.<br>
**To stay true to the original implementation**, the CST does not include low-level trivia such as whitespace.

This Lua*u* parser is primarily intended for plugin development and for building Lua*u* compilers or tooling. It provides detailed syntax information through both **AST** and **CST** representations, making it well suited for advanced language tooling such as linters, formatters, highlighter, refactoring tools, or even a full lua*u* compiler/transpiler.

This **LuauParser** only compatibles with New Type Solver.

## Performance

Why this *Luau Parser* so **fast** because it doesn’t use **OOP**, **ECS**, or any heavy architecture. It’s built as a *simple singleton-style procedural system* that just resets its internal variables and runs. This avoids the overhead that comes with more complex designs.

It also uses an inlined lexer, *table-less* position & location tracking, buffer-based byte reading, and several other low-level optimizations.

Because of this, its speed is almost identical to **[luaup](https://github.com/jackdotink/luaup)**. It just a little bit slower than **luaup** because each node contains way more data and supports more features, including advanced string escaping, full error recovery, detailed error reporting, modern syntax features, and ambiguous syntax handling which luaup doesn't have.

## Code Examples
```luau
local Parser = require(path.to.LuauParser)

local success, result = Parser.parse('local foo: (string, ...number) -> (...any)')

if success then
	print(result.root) -- do anything you want
else
	warn(result.errors)
end
```
