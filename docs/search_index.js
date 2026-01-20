window.SEARCH_INDEX = [
  {
    "name": "Position",
    "desc": "Represents a position in the source code. Used to pinpoint exact locations for error reporting and CST data.",
    "file": "core.html",
    "tags": []
  },
  {
    "name": "Location",
    "desc": "Represents a range in the source code from a beginning position to an ending position. Every AST node has a location that spans the source text it was parsed from.",
    "file": "core.html",
    "tags": []
  },
  {
    "name": "AstAttr",
    "desc": "A function attribute: `@native`, `@checked`, `@deprecated`, etc.",
    "file": "core.html",
    "tags": [
      "Helper",
      "AST"
    ]
  },
  {
    "name": "AstGenericType",
    "desc": "A generic type parameter in a generic declaration: `<T, U = Default>`.",
    "file": "core.html",
    "tags": [
      "Type",
      "Helper",
      "AST"
    ]
  },
  {
    "name": "AstGenericTypePack",
    "desc": "A generic type pack parameter in a generic declaration: `<T...>`.",
    "file": "core.html",
    "tags": [
      "Pack",
      "Type",
      "Helper",
      "AST"
    ]
  },
  {
    "name": "AstTypeList",
    "desc": "A list of types with an optional variadic tail. Used for function parameter and return types.",
    "file": "core.html",
    "tags": [
      "Type",
      "Helper",
      "AST"
    ]
  },
  {
    "name": "AstTypeOrPack",
    "desc": "A wrapper for either a type or a type pack. Used in generic type arguments where either could be valid.",
    "file": "core.html",
    "tags": [
      "Type",
      "Helper",
      "AST"
    ]
  },
  {
    "name": "AstArgumentName",
    "desc": "A named function argument (for documentation purposes).",
    "file": "core.html",
    "tags": [
      "Helper",
      "AST"
    ]
  },
  {
    "name": "Binding",
    "desc": "A binding in a local declaration or function parameter.",
    "file": "core.html",
    "tags": [
      "Helper"
    ]
  },
  {
    "name": "BindingList",
    "desc": "A list of bindings (used in local declarations).",
    "file": "core.html",
    "tags": [
      "Helper"
    ]
  },
  {
    "name": "AstDeclaredExternTypeProperty",
    "desc": "A property declaration in an extern type.",
    "file": "core.html",
    "tags": [
      "Type",
      "Helper",
      "AST"
    ]
  },
  {
    "name": "AstTableProp",
    "desc": "A property in a table type.",
    "file": "core.html",
    "tags": [
      "Helper",
      "AST"
    ]
  },
  {
    "name": "AstTableIndexer",
    "desc": "An indexer in a table type: `[KeyType]: ValueType`.",
    "file": "core.html",
    "tags": [
      "Helper",
      "AST"
    ]
  },
  {
    "name": "ParseError",
    "desc": "Represents a parse error with location and message.",
    "file": "core.html",
    "tags": [
      "Error",
      "Result"
    ]
  },
  {
    "name": "Options",
    "desc": "Parser configuration options.",
    "file": "core.html",
    "tags": [
      "Result"
    ]
  },
  {
    "name": "Lexeme",
    "desc": "Represents a lexer token with type and location.",
    "file": "core.html",
    "tags": [
      "Result"
    ]
  },
  {
    "name": "Attrs",
    "desc": "Shorthand for an array of attributes.",
    "file": "core.html",
    "tags": [
      "Result"
    ]
  },
  {
    "name": "Comment",
    "desc": "Represents a captured comment.",
    "file": "core.html",
    "tags": [
      "Result"
    ]
  },
  {
    "name": "HotComment",
    "desc": "Represents a hot comment (special directive comment like --!strict).",
    "file": "core.html",
    "tags": [
      "Result"
    ]
  },
  {
    "name": "FunctionState",
    "desc": "Internal parser state for tracking function context.",
    "file": "core.html",
    "tags": [
      "Statement",
      "Result"
    ]
  },
  {
    "name": "Result",
    "desc": "The result of parsing a Luau source file.",
    "file": "core.html",
    "tags": [
      "Result"
    ]
  },
  {
    "name": "AstName",
    "desc": "Represents a simple name/identifier in the AST. Used for variable names, function names, type names, etc.",
    "file": "ast.html",
    "tags": [
      "AST"
    ]
  },
  {
    "name": "AstLocal",
    "desc": "Represents a local variable declaration in the AST. Tracks the variable's name, location, shadowing information, scope depth, and optional type annotation.",
    "file": "ast.html",
    "tags": [
      "AST"
    ]
  },
  {
    "name": "AstExpr",
    "desc": "Union type representing all possible expression nodes in the AST. Expressions are constructs that evaluate to a value.",
    "file": "ast.html",
    "tags": [
      "Union",
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstStat",
    "desc": "Union type representing all possible statement nodes in the AST. Statements are constructs that perform actions but don't produce values.",
    "file": "ast.html",
    "tags": [
      "Union",
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstTypePack",
    "desc": "Union type representing all possible type pack nodes. Type packs represent multiple types, used for function return types and variadic arguments.",
    "file": "ast.html",
    "tags": [
      "Union",
      "Pack",
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstType",
    "desc": "Union type representing all possible type annotation nodes. Type annotations specify the expected types of values in Luau's type system.",
    "file": "ast.html",
    "tags": [
      "Union",
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstNode",
    "desc": "Union type representing all possible AST nodes that can be stored in the CST map. This includes statements, expressions, types, locals, and various helper nodes.",
    "file": "ast.html",
    "tags": [
      "Union",
      "AST"
    ]
  },
  {
    "name": "AstExprGroup",
    "desc": "A parenthesized expression: `(expr)`. Used to override operator precedence or for clarity.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprConstantNil",
    "desc": "The `nil` literal constant. Represents the absence of a value in Luau.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprConstantBool",
    "desc": "A boolean literal constant: `true` or `false`.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprConstantNumber",
    "desc": "A numeric literal constant (integer or floating-point). The original source text is stored in the CST node (CstExprConstantNumber.value).                      \"HexOverflow\" = hex literal exceeds 64 bits, \"BinOverflow\" = binary literal exceeds 64 bits,                      \"Malformed\" = failed to parse (typically produces an error node instead)",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprConstantString",
    "desc": "A string literal constant (single-quoted, double-quoted, or long bracket string). The original source string (before escape processing) is stored in CstExprConstantString.sourceString.                     1=QuotedSingle (single quotes), 2=QuotedRaw (long brackets [[]]),                     3=Unquoted (identifier-style key in table constructor like {foo = 1})",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprLocal",
    "desc": "A reference to a local variable.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprGlobal",
    "desc": "A reference to a global variable.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprVarargs",
    "desc": "A reference to the varargs `...` in a vararg function. Only valid inside functions declared with `...` parameter.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprCall",
    "desc": "A function call expression: `func(args)` or `obj:method(args)`.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprIndexName",
    "desc": "A named field access expression: `expr.name` or `expr:name`.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprIndexExpr",
    "desc": "A bracketed index expression: `expr[index]`.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprFunction",
    "desc": "A function expression (anonymous function or lambda): `function(...) ... end`.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprTable",
    "desc": "A table constructor expression: `{ items }`.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprTableItem",
    "desc": "Represents a single item in a table constructor.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprUnary",
    "desc": "A unary operator expression: `-expr`, `not expr`, or `#expr`.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprBinary",
    "desc": "A binary operator expression: `left op right`. Covers arithmetic, comparison, logical, and concatenation operators.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprTypeAssertion",
    "desc": "A type assertion expression: `expr :: Type`. Used to assert that an expression has a specific type.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstExprInstantiate",
    "desc": "An explicit type instantiation expression: `expr<<T, U>>`. Used to explicitly specify type arguments for a generic function or type.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprIfElse",
    "desc": "An if-else expression: `if condition then trueExpr else falseExpr`. The expression form of conditional logic (not the statement form).",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprInterpString",
    "desc": "An interpolated string expression: `` `text {expr} more text` ``. Allows embedding expressions directly within string literals.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstExprError",
    "desc": "An error expression node, created when parsing fails. Used to allow partial parsing to continue after errors.",
    "file": "ast.html",
    "tags": [
      "Error",
      "Expression",
      "AST"
    ]
  },
  {
    "name": "AstStatBlock",
    "desc": "A block of statements, representing a scope boundary. Used for function bodies, control structure bodies, and the top-level chunk.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatIf",
    "desc": "An if statement: `if condition then ... elseif ... else ... end`.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatWhile",
    "desc": "A while loop: `while condition do ... end`.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatRepeat",
    "desc": "A repeat-until loop: `repeat ... until condition`. Executes the body at least once, then continues while condition is falsy.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatBreak",
    "desc": "A break statement: `break`. Exits the innermost loop immediately.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatContinue",
    "desc": "A continue statement: `continue` (Luau extension). Skips to the next iteration of the innermost loop.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatReturn",
    "desc": "A return statement: `return expr1, expr2, ...`. Returns values from the current function. Must be the last statement in a block.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatExpr",
    "desc": "An expression statement: evaluates an expression for its side effects. Typically function calls like `print(\"hello\")`.",
    "file": "ast.html",
    "tags": [
      "Expression",
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatLocal",
    "desc": "A local variable declaration: `local a, b = expr1, expr2`.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatFor",
    "desc": "A numeric for loop: `for var = from, to, step do ... end`.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatForIn",
    "desc": "A generic for loop: `for var1, var2 in expr1, expr2 do ... end`. Uses iterators to loop over collections.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatAssign",
    "desc": "An assignment statement: `var1, var2 = expr1, expr2`.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatCompoundAssign",
    "desc": "A compound assignment statement: `var += expr`, `var -= expr`, etc.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatFunction",
    "desc": "A function declaration statement: `function a.b.c:name(...) ... end`.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatLocalFunction",
    "desc": "A local function declaration: `local function name(...) ... end`. The function is available within its own body (allows recursion).",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatTypeAlias",
    "desc": "A type alias declaration: `type Name<T> = Type` or `export type Name = Type`.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstStatTypeFunction",
    "desc": "A type function declaration (Luau extension): `type function Name(...) ... end`. Defines a compile-time type-level function.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstStatDeclareGlobal",
    "desc": "A global variable declaration (definition file syntax): `declare name: Type`.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatDeclareFunction",
    "desc": "A function declaration (definition file syntax): `declare function name(...)`. Note: Primarily used for type definition files.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstStatDeclareExternType",
    "desc": "An extern type declaration (definition file syntax): `declare extern type Name`. Used to declare external classes/types in definition files.",
    "file": "ast.html",
    "tags": [
      "Statement",
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstStatError",
    "desc": "An error statement node, created when parsing fails. Used to allow partial parsing to continue after errors.",
    "file": "ast.html",
    "tags": [
      "Error",
      "Statement",
      "AST"
    ]
  },
  {
    "name": "AstTypeReference",
    "desc": "A type reference: `TypeName` or `Module.TypeName<Params>`.",
    "file": "ast.html",
    "tags": [
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstTypeTable",
    "desc": "A table type: `{ prop: Type, [Key]: Value }`.",
    "file": "ast.html",
    "tags": [
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstTypeFunction",
    "desc": "A function type: `(Arg1, Arg2) -> (Ret1, Ret2)`.",
    "file": "ast.html",
    "tags": [
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstTypeTypeof",
    "desc": "A typeof type: `typeof(expr)`. Infers the type from the given expression at compile time.",
    "file": "ast.html",
    "tags": [
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstTypeUnion",
    "desc": "A union type: `Type1 | Type2 | Type3`. Represents a value that can be any one of the constituent types.",
    "file": "ast.html",
    "tags": [
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstTypeIntersection",
    "desc": "An intersection type: `Type1 & Type2 & Type3`. Represents a value that is all of the constituent types simultaneously.",
    "file": "ast.html",
    "tags": [
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstTypeSingletonBool",
    "desc": "A boolean singleton type: `true` or `false` as a type. Represents a type that can only be one specific boolean value.",
    "file": "ast.html",
    "tags": [
      "Singleton",
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstTypeSingletonString",
    "desc": "A string singleton type: `\"literal\"` as a type. Represents a type that can only be one specific string value.",
    "file": "ast.html",
    "tags": [
      "Singleton",
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstTypeGroup",
    "desc": "A parenthesized type: `(Type)`. Used for grouping in complex type expressions.",
    "file": "ast.html",
    "tags": [
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstTypeError",
    "desc": "An error type node, created when parsing fails. Used to allow partial parsing to continue after errors.",
    "file": "ast.html",
    "tags": [
      "Error",
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstTypeOptional",
    "desc": "A special optional type marker used internally. Represents the `?` suffix in optional types like `Type?`.",
    "file": "ast.html",
    "tags": [
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstTypePackExplicit",
    "desc": "An explicit type pack: `(Type1, Type2, ...T)`. Represents an explicit list of types, optionally ending with a variadic type.",
    "file": "ast.html",
    "tags": [
      "Pack",
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstTypePackVariadic",
    "desc": "A variadic type pack: `...Type`. Represents zero or more values of the specified type.",
    "file": "ast.html",
    "tags": [
      "Pack",
      "Type",
      "AST"
    ]
  },
  {
    "name": "AstTypePackGeneric",
    "desc": "A generic type pack reference: `T...`. References a generic type pack parameter.",
    "file": "ast.html",
    "tags": [
      "Pack",
      "Type",
      "AST"
    ]
  },
  {
    "name": "CstNode",
    "desc": "Union type representing all possible Concrete Syntax Tree nodes. CST nodes store positional data for syntactic elements (commas, keywords, etc.) that are not semantically significant but needed for source-accurate transformations.",
    "file": "cst.html",
    "tags": [
      "Union",
      "CST"
    ]
  },
  {
    "name": "CstStatBlock",
    "desc": "CST data for a block statement.",
    "file": "cst.html",
    "tags": [
      "Statement",
      "CST"
    ]
  },
  {
    "name": "CstStatRepeat",
    "desc": "CST data for a repeat statement.",
    "file": "cst.html",
    "tags": [
      "Statement",
      "CST"
    ]
  },
  {
    "name": "CstStatDo",
    "desc": "CST data for a do statement.",
    "file": "cst.html",
    "tags": [
      "Statement",
      "CST"
    ]
  },
  {
    "name": "CstStatFor",
    "desc": "CST data for a numeric for loop.",
    "file": "cst.html",
    "tags": [
      "Statement",
      "CST"
    ]
  },
  {
    "name": "CstStatForIn",
    "desc": "CST data for a generic for loop.",
    "file": "cst.html",
    "tags": [
      "Statement",
      "CST"
    ]
  },
  {
    "name": "CstStatFunction",
    "desc": "CST data for a function declaration statement.",
    "file": "cst.html",
    "tags": [
      "Statement",
      "CST"
    ]
  },
  {
    "name": "CstStatLocalFunction",
    "desc": "CST data for a local function declaration.",
    "file": "cst.html",
    "tags": [
      "Statement",
      "CST"
    ]
  },
  {
    "name": "CstStatLocal",
    "desc": "CST data for a local variable declaration.",
    "file": "cst.html",
    "tags": [
      "Statement",
      "CST"
    ]
  },
  {
    "name": "CstStatAssign",
    "desc": "CST data for an assignment statement.",
    "file": "cst.html",
    "tags": [
      "Statement",
      "CST"
    ]
  },
  {
    "name": "CstStatCompoundAssign",
    "desc": "CST data for a compound assignment statement.",
    "file": "cst.html",
    "tags": [
      "Statement",
      "CST"
    ]
  },
  {
    "name": "CstStatReturn",
    "desc": "CST data for a return statement.",
    "file": "cst.html",
    "tags": [
      "Statement",
      "CST"
    ]
  },
  {
    "name": "CstStatTypeAlias",
    "desc": "CST data for a type alias declaration.",
    "file": "cst.html",
    "tags": [
      "Statement",
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstStatTypeFunction",
    "desc": "CST data for a type function declaration.",
    "file": "cst.html",
    "tags": [
      "Statement",
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstExprFunction",
    "desc": "CST data for a function expression.",
    "file": "cst.html",
    "tags": [
      "Expression",
      "CST"
    ]
  },
  {
    "name": "CstExprTable",
    "desc": "CST data for a table constructor expression.",
    "file": "cst.html",
    "tags": [
      "Expression",
      "CST"
    ]
  },
  {
    "name": "CstExprTableItem",
    "desc": "CST data for a single table item.",
    "file": "cst.html",
    "tags": [
      "Expression",
      "CST"
    ]
  },
  {
    "name": "CstExprIfElse",
    "desc": "CST data for an if-else expression.",
    "file": "cst.html",
    "tags": [
      "Expression",
      "CST"
    ]
  },
  {
    "name": "CstExprInterpString",
    "desc": "CST data for an interpolated string expression.",
    "file": "cst.html",
    "tags": [
      "Expression",
      "CST"
    ]
  },
  {
    "name": "CstExprConstantString",
    "desc": "CST data for a string constant expression.                     2=QuotedRaw ([[]]), 3=QuotedInterp (``)",
    "file": "cst.html",
    "tags": [
      "Expression",
      "CST"
    ]
  },
  {
    "name": "CstTypeInstantiation",
    "desc": "CST data for type instantiation syntax: `<<T, U>>`.",
    "file": "cst.html",
    "tags": [
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstExprCall",
    "desc": "CST data for a function call expression.",
    "file": "cst.html",
    "tags": [
      "Expression",
      "CST"
    ]
  },
  {
    "name": "CstExprIndexExpr",
    "desc": "CST data for a bracketed index expression.",
    "file": "cst.html",
    "tags": [
      "Expression",
      "CST"
    ]
  },
  {
    "name": "CstExprTypeAssertion",
    "desc": "CST data for a type assertion expression.",
    "file": "cst.html",
    "tags": [
      "Expression",
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstExprExplicitTypeInstantiation",
    "desc": "CST data for explicit type instantiation expression.",
    "file": "cst.html",
    "tags": [
      "Expression",
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstExprConstantNumber",
    "desc": "CST data for a numeric constant expression.",
    "file": "cst.html",
    "tags": [
      "Expression",
      "CST"
    ]
  },
  {
    "name": "CstExprOp",
    "desc": "CST data for unary/binary operator expressions.",
    "file": "cst.html",
    "tags": [
      "Expression",
      "CST"
    ]
  },
  {
    "name": "CstTypeTypeof",
    "desc": "CST data for a typeof type.",
    "file": "cst.html",
    "tags": [
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstTypeReference",
    "desc": "CST data for a type reference.",
    "file": "cst.html",
    "tags": [
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstTypePackGeneric",
    "desc": "CST data for a generic type pack reference.",
    "file": "cst.html",
    "tags": [
      "Pack",
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstTypePackExplicit",
    "desc": "CST data for an explicit type pack.",
    "file": "cst.html",
    "tags": [
      "Pack",
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstTypeFunction",
    "desc": "CST data for a function type.",
    "file": "cst.html",
    "tags": [
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstTypeUnion",
    "desc": "CST data for a union type.",
    "file": "cst.html",
    "tags": [
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstTypeIntersection",
    "desc": "CST data for an intersection type.",
    "file": "cst.html",
    "tags": [
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstTypeTable",
    "desc": "CST data for a table type.",
    "file": "cst.html",
    "tags": [
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstTypeTableItem",
    "desc": "CST data for a table type item.",
    "file": "cst.html",
    "tags": [
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstGenericType",
    "desc": "CST data for a generic type parameter.",
    "file": "cst.html",
    "tags": [
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstGenericTypePack",
    "desc": "CST data for a generic type pack parameter.",
    "file": "cst.html",
    "tags": [
      "Pack",
      "Type",
      "CST"
    ]
  },
  {
    "name": "CstTypeSingletonString",
    "desc": "CST data for a string singleton type.",
    "file": "cst.html",
    "tags": [
      "Singleton",
      "Type",
      "CST"
    ]
  }
];