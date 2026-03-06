window.DOCS_DATA = {
  "title": "LuauParser Source Reference",
  "generatedFrom": "`gh-pages/docs-data.js`, rewritten from `src/Syntax.luau` with enum facts from `src/init.luau`.",
  "coverage": [
    "Every exported type from `src/Syntax.luau`.",
    "Descriptions rewritten from the actual stored fields instead of README-era prose.",
    "Short source-oriented examples for each exported record or union.",
    "Field-level notes derived from the typed shape and parser enums."
  ],
  "summary": {
    "total": 117,
    "views": {
      "overview": {
        "count": 117
      },
      "core": {
        "count": 12,
        "unions": 0,
        "entries": 12
      },
      "ast": {
        "count": 68,
        "unions": 5,
        "entries": 63
      },
      "cst": {
        "count": 37,
        "unions": 0,
        "entries": 37
      }
    }
  },
  "sections": [
    {
      "name": "Position",
      "anchor": "position",
      "group": "Core",
      "category": "core",
      "badges": [
        "CORE"
      ],
      "tags": [],
      "description": "0-based source coordinate used by AST nodes, CST nodes, and parse diagnostics.",
      "example": "local startPos: Position = { line = 4, column = 1 }\nlocal endPos: Position = { line = 4, column = 18 }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "line",
            "number",
            "1-based line component of this position record."
          ],
          [
            "column",
            "number",
            "1-based column component of this position record."
          ]
        ]
      }
    },
    {
      "name": "Location",
      "anchor": "location",
      "group": "Core",
      "category": "core",
      "badges": [
        "CORE"
      ],
      "tags": [],
      "description": "Half-open source span with a `begin` position and an `end_` position.",
      "example": "local startPos: Position = { line = 4, column = 1 }\nlocal loc: Location = { begin = startPos, end_ = endPos }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "begin",
            "[Position](#position)",
            "First included position in this location record."
          ],
          [
            "end_",
            "[Position](#position)",
            "Position immediately after the last covered character in this location record."
          ]
        ]
      }
    },
    {
      "name": "AstName",
      "anchor": "astname",
      "group": "Core",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [],
      "description": "Identifier wrapper used when the parser stores a structured field name.",
      "example": "local firstName: AstName = { value = \"enabled\" }\nlocal secondName: AstName = { value = \"count\" }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "value",
            "string",
            "Identifier text stored by this wrapper."
          ]
        ]
      }
    },
    {
      "name": "AstExpr",
      "anchor": "astexpr",
      "group": "Unions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression",
        "Union"
      ],
      "description": "Union of every AST expression shape the parser can produce.",
      "example": "local left = 10\nlocal total = left + 5",
      "table": {
        "type": "members",
        "headers": [
          "Member",
          "Description"
        ],
        "rows": [
          [
            "[AstExprGroup](#astexprgroup)",
            "Parenthesized expression used to preserve grouping."
          ],
          [
            "[AstExprConstantNil](#astexprconstantnil)",
            "Literal `nil` expression."
          ],
          [
            "[AstExprConstantBool](#astexprconstantbool)",
            "Boolean literal expression."
          ],
          [
            "[AstExprConstantNumber](#astexprconstantnumber)",
            "Numeric literal expression with parsed value and lexer status."
          ],
          [
            "[AstExprConstantString](#astexprconstantstring)",
            "String literal expression with decoded contents and quote style."
          ],
          [
            "[AstExprLocal](#astexprlocal)",
            "Reference to a resolved local binding."
          ],
          [
            "[AstExprGlobal](#astexprglobal)",
            "Reference to a global name."
          ],
          [
            "[AstExprVarargs](#astexprvarargs)",
            "Vararg expression `...`."
          ],
          [
            "[AstExprCall](#astexprcall)",
            "Function or method call expression."
          ],
          [
            "[AstExprIndexName](#astexprindexname)",
            "Named field access such as `obj.x` or `obj:x`."
          ],
          [
            "[AstExprIndexExpr](#astexprindexexpr)",
            "Computed index access such as `obj[key]`."
          ],
          [
            "[AstExprFunction](#astexprfunction)",
            "Function literal expression with parameters, attributes, and body."
          ],
          [
            "[AstExprTable](#astexprtable)",
            "Table constructor expression."
          ],
          [
            "[AstExprUnary](#astexprunary)",
            "Unary operator expression."
          ],
          [
            "[AstExprBinary](#astexprbinary)",
            "Binary operator expression."
          ],
          [
            "[AstExprTypeAssertion](#astexprtypeassertion)",
            "Type assertion expression using `::`."
          ],
          [
            "[AstExprIfElse](#astexprifelse)",
            "If-expression with explicit true and false branches."
          ],
          [
            "[AstExprInterpString](#astexprinterpstring)",
            "Interpolated string expression with literal segments and embedded expressions."
          ],
          [
            "[AstExprInstantiate](#astexprinstantiate)",
            "Explicit generic instantiation applied to an expression."
          ],
          [
            "[AstExprError](#astexprerror)",
            "Error-recovery expression created when expression parsing failed."
          ]
        ]
      }
    },
    {
      "name": "AstStat",
      "anchor": "aststat",
      "group": "Unions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement",
        "Union"
      ],
      "description": "Union of every AST statement shape the parser can produce.",
      "example": "local value = 1\nvalue += 2",
      "table": {
        "type": "members",
        "headers": [
          "Member",
          "Description"
        ],
        "rows": [
          [
            "[AstStatBlock](#aststatblock)",
            "Statement block with ordered child statements."
          ],
          [
            "[AstStatIf](#aststatif)",
            "Conditional statement with then and optional else branches."
          ],
          [
            "[AstStatWhile](#aststatwhile)",
            "While-loop statement."
          ],
          [
            "[AstStatRepeat](#aststatrepeat)",
            "Repeat-until loop statement."
          ],
          [
            "[AstStatBreak](#aststatbreak)",
            "Break statement."
          ],
          [
            "[AstStatContinue](#aststatcontinue)",
            "Continue statement."
          ],
          [
            "[AstStatReturn](#aststatreturn)",
            "Return statement."
          ],
          [
            "[AstStatExpr](#aststatexpr)",
            "Statement wrapper for an expression used in statement position."
          ],
          [
            "[AstStatLocal](#aststatlocal)",
            "Local variable declaration statement."
          ],
          [
            "[AstStatFor](#aststatfor)",
            "Numeric `for` loop statement."
          ],
          [
            "[AstStatForIn](#aststatforin)",
            "Generic `for ... in` loop statement."
          ],
          [
            "[AstStatAssign](#aststatassign)",
            "Assignment statement."
          ],
          [
            "[AstStatCompoundAssign](#aststatcompoundassign)",
            "Compound assignment statement such as `+=`."
          ],
          [
            "[AstStatFunction](#aststatfunction)",
            "Function declaration statement."
          ],
          [
            "[AstStatLocalFunction](#aststatlocalfunction)",
            "Local function declaration statement."
          ],
          [
            "[AstStatTypeAlias](#aststattypealias)",
            "Type alias declaration statement."
          ],
          [
            "[AstStatTypeFunction](#aststattypefunction)",
            "Type function declaration statement."
          ],
          [
            "[AstStatError](#aststaterror)",
            "Error-recovery statement created when statement parsing failed."
          ]
        ]
      }
    },
    {
      "name": "AstTypePack",
      "anchor": "asttypepack",
      "group": "Unions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type Pack",
        "Union"
      ],
      "description": "Union of every AST type-pack shape the parser can produce.",
      "example": "type Callback = (string, ...number) -> (...boolean)\ntype Wrapper<Args...> = (Args...) -> ()",
      "table": {
        "type": "members",
        "headers": [
          "Member",
          "Description"
        ],
        "rows": [
          [
            "[AstTypePackExplicit](#asttypepackexplicit)",
            "Explicit type pack with fixed entries and an optional tail pack."
          ],
          [
            "[AstTypePackVariadic](#asttypepackvariadic)",
            "Variadic type pack."
          ],
          [
            "[AstTypePackGeneric](#asttypepackgeneric)",
            "Reference to a generic type pack."
          ]
        ]
      }
    },
    {
      "name": "AstType",
      "anchor": "asttype",
      "group": "Unions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type",
        "Union"
      ],
      "description": "Union of every AST type shape the parser can produce.",
      "example": "type Value = string | number\ntype Callback = (string, number) -> boolean",
      "table": {
        "type": "members",
        "headers": [
          "Member",
          "Description"
        ],
        "rows": [
          [
            "[AstTypeReference](#asttypereference)",
            "Named type reference, optionally with a prefix and explicit parameters."
          ],
          [
            "[AstTypeTable](#asttypetable)",
            "Table type with named properties and an optional indexer."
          ],
          [
            "[AstTypeFunction](#asttypefunction)",
            "Function type with argument names, argument types, and a return pack."
          ],
          [
            "[AstTypeTypeof](#asttypetypeof)",
            "Type query wrapping an expression."
          ],
          [
            "[AstTypeUnion](#asttypeunion)",
            "Union type made from multiple branches."
          ],
          [
            "[AstTypeIntersection](#asttypeintersection)",
            "Intersection type made from multiple branches."
          ],
          [
            "[AstTypeSingletonBool](#asttypesingletonbool)",
            "Boolean singleton type."
          ],
          [
            "[AstTypeSingletonString](#asttypesingletonstring)",
            "String singleton type."
          ],
          [
            "[AstTypeGroup](#asttypegroup)",
            "Parenthesized type used to preserve grouping."
          ],
          [
            "[AstTypeError](#asttypeerror)",
            "Error-recovery type node."
          ],
          [
            "[AstTypeOptional](#asttypeoptional)",
            "Standalone optional-type placeholder used by parser recovery."
          ]
        ]
      }
    },
    {
      "name": "AstTypeList",
      "anchor": "asttypelist",
      "group": "Types",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Helper record for function argument types plus an optional tail pack.",
      "example": "local args: AstTypeList = { types = { leftType, rightType }, tailType = nil }\nlocal returns: AstTypeList = { types = { resultType }, tailType = restPack }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "types",
            "{ [AstType](#asttype) }",
            "Type entries stored by this type-list record, in source order."
          ],
          [
            "tailType",
            "[AstTypePack](#asttypepack)?",
            "Optional tail type stored by this type-list record."
          ]
        ]
      }
    },
    {
      "name": "AstTypeOrPack",
      "anchor": "asttypeorpack",
      "group": "Types",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Wrapper used where syntax accepts either a type or a type pack.",
      "example": "local first: AstTypeOrPack = { type = stringType, typePack = nil }\nlocal second: AstTypeOrPack = { type = nil, typePack = argsPack }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "type",
            "[AstType](#asttype)?",
            "Optional type stored by this type-or-pack record."
          ],
          [
            "typePack",
            "[AstTypePack](#asttypepack)?",
            "Optional type pack stored by this type-or-pack record."
          ]
        ]
      }
    },
    {
      "name": "AstArgumentName",
      "anchor": "astargumentname",
      "group": "Core",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [],
      "description": "Named function-type argument with its source location.",
      "example": "local leftArg: AstArgumentName = { name = \"left\", location = leftLoc }\nlocal rightArg: AstArgumentName = { name = \"right\", location = rightLoc }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "name",
            "string",
            "Name text stored by this argument-name record."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this argument-name record."
          ]
        ]
      }
    },
    {
      "name": "AstLocal",
      "anchor": "astlocal",
      "group": "Core",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [],
      "description": "Resolved local binding tracked by the parser, including scope and annotation data.",
      "example": "local first = 10\nlocal second: number = first + 5",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "name",
            "string",
            "Name text stored by this local-binding record."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this local-binding record."
          ],
          [
            "shadow",
            "[AstLocal](#astlocal)?",
            "Previous local with the same name that this binding shadows, when one exists."
          ],
          [
            "functionDepth",
            "number",
            "Function nesting depth where this local binding was introduced."
          ],
          [
            "loopDepth",
            "number",
            "Loop nesting depth where this local binding was introduced."
          ],
          [
            "annotation",
            "[AstType](#asttype)?",
            "Optional type annotation attached to this local binding."
          ]
        ]
      }
    },
    {
      "name": "AstAttr",
      "anchor": "astattr",
      "group": "Core",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [],
      "description": "Attribute payload attached to declarations and function types.",
      "example": "@checked\n@native\nlocal function runTask() end",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"Attr\"",
            "Tag string used for this attribute record."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this attribute record."
          ],
          [
            "type",
            "string?",
            "Optional attribute type name, when the attribute syntax provided one."
          ],
          [
            "args",
            "{ [AstExpr](#astexpr) }",
            "Argument expressions passed into this attribute, in source order."
          ],
          [
            "name",
            "string?",
            "Attribute identifier when the parser recorded one."
          ]
        ]
      }
    },
    {
      "name": "AstGenericType",
      "anchor": "astgenerictype",
      "group": "Generics",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Generic"
      ],
      "description": "Generic type parameter captured from a declaration or function signature.",
      "example": "function identity<T>(value: T): T\n    return value\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstGenericType](#cstgenerictype)?",
            "Attached CstGenericType payload for this generic-type parameter when storeCstData is enabled."
          ],
          [
            "kind",
            "\"GenericType\"",
            "Tag string used for this generic-type parameter."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this generic-type parameter."
          ],
          [
            "name",
            "string",
            "Name text stored by this generic-type parameter."
          ],
          [
            "defaultValue",
            "[AstType](#asttype)?",
            "Default type used when this generic parameter is omitted."
          ]
        ]
      }
    },
    {
      "name": "AstGenericTypePack",
      "anchor": "astgenerictypepack",
      "group": "Generics",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Generic"
      ],
      "description": "Generic type-pack parameter captured from a declaration or function signature.",
      "example": "type Callback<Args..., R> = (Args...) -> R\ntype Wrapper<Values...> = (Values...) -> ()",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstGenericTypePack](#cstgenerictypepack)?",
            "Attached CstGenericTypePack payload for this generic-type-pack parameter when storeCstData is enabled."
          ],
          [
            "kind",
            "\"GenericTypePack\"",
            "Tag string used for this generic-type-pack parameter."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this generic-type-pack parameter."
          ],
          [
            "name",
            "string",
            "Name text stored by this generic-type-pack parameter."
          ],
          [
            "defaultValue",
            "[AstTypePack](#asttypepack)?",
            "Default type pack used when this generic pack is omitted."
          ]
        ]
      }
    },
    {
      "name": "AstExprGroup",
      "anchor": "astexprgroup",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Parenthesized expression used to preserve grouping.",
      "example": "local value = (left + right) * scale\nlocal nextValue = (count - 1)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"ExprGroup\"",
            "Tag string used for this group expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this group expression."
          ],
          [
            "expr",
            "[AstExpr](#astexpr)",
            "Expression stored by this group expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprConstantNil",
      "anchor": "astexprconstantnil",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Literal `nil` expression.",
      "example": "local value = nil\nlocal fallback = value or 10",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"ExprConstantNil\"",
            "Tag string used for this constant nil expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this constant nil expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprConstantBool",
      "anchor": "astexprconstantbool",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Boolean literal expression.",
      "example": "local enabled = true\nlocal visible = false",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"ExprConstantBool\"",
            "Tag string used for this constant bool expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this constant bool expression."
          ],
          [
            "value",
            "boolean",
            "Parsed boolean literal value stored by this expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprConstantNumber",
      "anchor": "astexprconstantnumber",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Numeric literal expression with parsed value and lexer status.",
      "example": "local width = 128\nlocal doubled = width * 2",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstExprConstantNumber](#cstexprconstantnumber)?",
            "Attached CstExprConstantNumber payload for this constant number expression when storeCstData is enabled."
          ],
          [
            "kind",
            "\"ExprConstantNumber\"",
            "Tag string used for this constant number expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this constant number expression."
          ],
          [
            "value",
            "number",
            "Parsed numeric literal value stored by this expression."
          ],
          [
            "parseResult",
            "\"Ok\" | \"Imprecise\" | \"HexOverflow\" | \"BinOverflow\" | \"Malformed\"",
            "Numeric parse status preserved by this numeric literal expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprConstantString",
      "anchor": "astexprconstantstring",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "String literal expression with decoded contents and quote style.",
      "example": "local greeting = \"hello\"\nlocal label = greeting .. \" world\"",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstExprConstantString](#cstexprconstantstring)?",
            "Attached CstExprConstantString payload for this constant string expression when storeCstData is enabled."
          ],
          [
            "kind",
            "\"ExprConstantString\"",
            "Tag string used for this constant string expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this constant string expression."
          ],
          [
            "value",
            "string",
            "Decoded string contents stored by this expression."
          ],
          [
            "quoteStyle",
            "number",
            "Quote-style enum value used by this string literal expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprLocal",
      "anchor": "astexprlocal",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Reference to a resolved local binding.",
      "example": "local first = 10\nlocal second = first + 5",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"ExprLocal\"",
            "Tag string used for this local expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this local expression."
          ],
          [
            "[\"local\"]",
            "[AstLocal](#astlocal)",
            "Resolved local binding referenced by this expression."
          ],
          [
            "upvalue",
            "boolean",
            "Whether this local reference resolves to an outer captured binding."
          ]
        ]
      }
    },
    {
      "name": "AstExprGlobal",
      "anchor": "astexprglobal",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Reference to a global name.",
      "example": "local maximum = math.max(4, 9)\nlocal rounded = math.floor(3.8)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"ExprGlobal\"",
            "Tag string used for this global expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this global expression."
          ],
          [
            "name",
            "string",
            "Name text stored by this global expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprVarargs",
      "anchor": "astexprvarargs",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Vararg expression `...`.",
      "example": "local function pack(...: number)\n    return ...\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"ExprVarargs\"",
            "Tag string used for this varargs expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this varargs expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprCall",
      "anchor": "astexprcall",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Function or method call expression.",
      "example": "local built = buildValue(4, 8)\nlocal result = normalize(built)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstExprCall](#cstexprcall)?",
            "Attached CstExprCall payload for this call expression when storeCstData is enabled."
          ],
          [
            "kind",
            "\"ExprCall\"",
            "Tag string used for this call expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this call expression."
          ],
          [
            "func",
            "[AstExpr](#astexpr)",
            "Expression being called by this call expression."
          ],
          [
            "args",
            "{ [AstExpr](#astexpr) }",
            "Argument expressions passed into this call expression, in source order."
          ],
          [
            "self",
            "boolean",
            "Whether this call expression uses method syntax and passes an implicit self."
          ],
          [
            "typeArguments",
            "{ [AstTypeOrPack](#asttypeorpack) }",
            "Explicit type arguments applied before this call expression runs."
          ],
          [
            "argLocation",
            "[Location](#location)",
            "Source span covering the argument list of this call expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprIndexName",
      "anchor": "astexprindexname",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Named field access such as `obj.x` or `obj:x`.",
      "example": "local playerName = player.Name\nlocal playerTeam = player.Team",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"ExprIndexName\"",
            "Tag string used for this index name expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this index name expression."
          ],
          [
            "expr",
            "[AstExpr](#astexpr)",
            "Expression stored by this index name expression."
          ],
          [
            "index",
            "string",
            "Property name used by this named index expression."
          ],
          [
            "indexLocation",
            "[Location](#location)",
            "Source span covering the property name in this named index expression."
          ],
          [
            "opPosition",
            "[Position](#position)",
            "Source position of the indexing operator used by this named index expression."
          ],
          [
            "op",
            "number",
            "Indexer token kind recorded for this named index expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprIndexExpr",
      "anchor": "astexprindexexpr",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Computed index access such as `obj[key]`.",
      "example": "local current = values[index]\nlocal nextValue = values[index + 1]",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstExprIndexExpr](#cstexprindexexpr)?",
            "Attached CstExprIndexExpr payload for this index expr expression when storeCstData is enabled."
          ],
          [
            "kind",
            "\"ExprIndexExpr\"",
            "Tag string used for this index expr expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this index expr expression."
          ],
          [
            "expr",
            "[AstExpr](#astexpr)",
            "Expression stored by this index expr expression."
          ],
          [
            "index",
            "[AstExpr](#astexpr)",
            "Expression evaluated inside the brackets of this indexed access expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprFunction",
      "anchor": "astexprfunction",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Function literal expression with parameters, attributes, and body.",
      "example": "local fn = function(left: number, right: number): number\n    return left + right\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstExprFunction](#cstexprfunction)?",
            "Attached CstExprFunction payload for this function expression when storeCstData is enabled."
          ],
          [
            "kind",
            "\"ExprFunction\"",
            "Tag string used for this function expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this function expression."
          ],
          [
            "attributes",
            "{ [AstAttr](#astattr) }",
            "Attributes attached to this function literal."
          ],
          [
            "generics",
            "{ [AstGenericType](#astgenerictype) }",
            "Generic type parameters declared by this function literal."
          ],
          [
            "genericPacks",
            "{ [AstGenericTypePack](#astgenerictypepack) }",
            "Generic type-pack parameters declared by this function literal."
          ],
          [
            "self",
            "[AstLocal](#astlocal)?",
            "Synthetic local for the implicit self parameter of this function literal."
          ],
          [
            "args",
            "{ [AstLocal](#astlocal) }",
            "Parameter locals declared by this function literal, in source order."
          ],
          [
            "returnAnnotation",
            "[AstTypePack](#asttypepack)?",
            "Optional return type pack annotation of this function literal."
          ],
          [
            "vararg",
            "boolean",
            "Whether this function literal accepts `...`."
          ],
          [
            "varargLocation",
            "[Location](#location)?",
            "Source span covering the vararg token of this function literal."
          ],
          [
            "varargAnnotation",
            "[AstTypePack](#asttypepack)?",
            "Optional type annotation attached to the vararg pack of this function literal."
          ],
          [
            "body",
            "[AstStatBlock](#aststatblock)",
            "Body block executed by this function literal."
          ],
          [
            "functionDepth",
            "number",
            "Function nesting depth captured for this function literal."
          ],
          [
            "debugname",
            "string?",
            "Best-effort debug name assigned to this function literal."
          ],
          [
            "argLocation",
            "[Location](#location)?",
            "Source span covering the parameter list of this function literal."
          ]
        ]
      }
    },
    {
      "name": "AstExprTableItem",
      "anchor": "astexprtableitem",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Single table-constructor entry, covering list, record, and general forms.",
      "example": "local config = { enabled = true, retries = 3 }\nlocal result = { [key] = value, 42 }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"List\" | \"Record\" | \"General\"",
            "Tag string used for this table-constructor item."
          ],
          [
            "key",
            "[AstExpr](#astexpr)?",
            "Key expression stored for this table-constructor item, when the item is keyed."
          ],
          [
            "value",
            "[AstExpr](#astexpr)",
            "Value expression stored for this table-constructor item."
          ]
        ]
      }
    },
    {
      "name": "AstExprTable",
      "anchor": "astexprtable",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Table constructor expression.",
      "example": "local config = {\n    enabled = true,\n    retries = 3,\n}",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstExprTable](#cstexprtable)?",
            "Attached CstExprTable payload for this table expression when storeCstData is enabled."
          ],
          [
            "kind",
            "\"ExprTable\"",
            "Tag string used for this table expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this table expression."
          ],
          [
            "items",
            "{ [AstExprTableItem](#astexprtableitem) }",
            "Table-constructor items stored by this table expression, in source order."
          ]
        ]
      }
    },
    {
      "name": "AstExprUnary",
      "anchor": "astexprunary",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Unary operator expression.",
      "example": "local count = #items\nlocal inverse = -delta",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstExprOp](#cstexprop)?",
            "Attached CstExprOp payload for this unary expression when storeCstData is enabled."
          ],
          [
            "kind",
            "\"ExprUnary\"",
            "Tag string used for this unary expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this unary expression."
          ],
          [
            "op",
            "number",
            "Unary operator enum stored by this unary expression."
          ],
          [
            "expr",
            "[AstExpr](#astexpr)",
            "Expression stored by this unary expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprBinary",
      "anchor": "astexprbinary",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Binary operator expression.",
      "example": "local total = base + bonus\nlocal ratio = total / limit",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstExprOp](#cstexprop)?",
            "Attached CstExprOp payload for this binary expression when storeCstData is enabled."
          ],
          [
            "kind",
            "\"ExprBinary\"",
            "Tag string used for this binary expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this binary expression."
          ],
          [
            "op",
            "number",
            "Binary operator enum stored by this binary expression."
          ],
          [
            "left",
            "[AstExpr](#astexpr)",
            "left value stored by this binary expression."
          ],
          [
            "right",
            "[AstExpr](#astexpr)",
            "right value stored by this binary expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprTypeAssertion",
      "anchor": "astexprtypeassertion",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Type assertion expression using `::`.",
      "example": "local name = value :: string\nlocal count = size :: number",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstExprTypeAssertion](#cstexprtypeassertion)?",
            "Attached CstExprTypeAssertion payload for this type assertion expression when storeCstData is enabled."
          ],
          [
            "kind",
            "\"ExprTypeAssertion\"",
            "Tag string used for this type assertion expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this type assertion expression."
          ],
          [
            "expr",
            "[AstExpr](#astexpr)",
            "Expression stored by this type assertion expression."
          ],
          [
            "annotation",
            "[AstType](#asttype)",
            "Type annotation asserted by this type-assertion expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprInstantiate",
      "anchor": "astexprinstantiate",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Explicit generic instantiation applied to an expression.",
      "example": "local result = create<string, number>(\"id\", 4)\nlocal copy = wrap<boolean>(true)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstExprExplicitTypeInstantiation](#cstexprexplicittypeinstantiation)?",
            "Attached CstExprExplicitTypeInstantiation payload for this instantiate expression when storeCstData is enabled."
          ],
          [
            "kind",
            "\"ExprInstantiate\"",
            "Tag string used for this instantiate expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this instantiate expression."
          ],
          [
            "expr",
            "[AstExpr](#astexpr)",
            "Expression stored by this instantiate expression."
          ],
          [
            "typeArguments",
            "{ [AstTypeOrPack](#asttypeorpack) }",
            "Explicit type arguments applied by this instantiation expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprIfElse",
      "anchor": "astexprifelse",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "If-expression with explicit true and false branches.",
      "example": "local label = if ready then \"ready\" else \"waiting\"",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstExprIfElse](#cstexprifelse)?",
            "Attached CstExprIfElse payload for this if else expression when storeCstData is enabled."
          ],
          [
            "kind",
            "\"ExprIfElse\"",
            "Tag string used for this if else expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this if else expression."
          ],
          [
            "condition",
            "[AstExpr](#astexpr)",
            "Condition expression evaluated by this if else expression."
          ],
          [
            "hasThen",
            "boolean",
            "Whether this if-expression consumed an explicit `then` keyword."
          ],
          [
            "trueExpr",
            "[AstExpr](#astexpr)",
            "Expression evaluated when this if-expression condition is truthy."
          ],
          [
            "hasElse",
            "boolean",
            "Whether this if-expression consumed an explicit `else` branch."
          ],
          [
            "falseExpr",
            "[AstExpr](#astexpr)",
            "Expression evaluated when this if-expression condition is falsy."
          ]
        ]
      }
    },
    {
      "name": "AstExprInterpString",
      "anchor": "astexprinterpstring",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Interpolated string expression with literal segments and embedded expressions.",
      "example": "local label = `name = {name}`\nlocal line = `score = {score}`",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstExprInterpString](#cstexprinterpstring)?",
            "Attached CstExprInterpString payload for this interp string expression when storeCstData is enabled."
          ],
          [
            "kind",
            "\"ExprInterpString\"",
            "Tag string used for this interp string expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this interp string expression."
          ],
          [
            "strings",
            "{ string }",
            "Literal string segments stored by this interpolated string expression."
          ],
          [
            "expressions",
            "{ [AstExpr](#astexpr) }",
            "Embedded expressions evaluated between the literal segments of this interpolated string expression."
          ]
        ]
      }
    },
    {
      "name": "AstExprError",
      "anchor": "astexprerror",
      "group": "Expressions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Error-recovery expression created when expression parsing failed.",
      "example": "local ok, result = Parser.parse(\"foo(\")\nwarn(result.errors)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"ExprError\"",
            "Tag string used for this error expression."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this error expression."
          ],
          [
            "expressions",
            "{ [AstExpr](#astexpr) }",
            "Expression fragments recovered before this error expression was produced."
          ],
          [
            "messageIndex",
            "number",
            "Internal error-message index stored by this error expression."
          ]
        ]
      }
    },
    {
      "name": "AstStatBlock",
      "anchor": "aststatblock",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Statement block with ordered child statements.",
      "example": "do\n    local first = 1\n    local second = first + 1\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstStatDo](#cststatdo) | [CstStatDo_DEPRECATED](#cststatdo_deprecated) | nil",
            "Attached CstStatDo payload for this block statement when storeCstData is enabled."
          ],
          [
            "kind",
            "\"StatBlock\"",
            "Tag string used for this block statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this block statement."
          ],
          [
            "body",
            "{ [AstStat](#aststat) }",
            "Child statements stored by this block statement, in lexical order."
          ],
          [
            "hasEnd",
            "boolean",
            "Whether this block statement closed with an `end` keyword in source."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this block statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatIf",
      "anchor": "aststatif",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Conditional statement with then and optional else branches.",
      "example": "if ready then\n    start()\nelse\n    stop()\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"StatIf\"",
            "Tag string used for this if statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this if statement."
          ],
          [
            "condition",
            "[AstExpr](#astexpr)",
            "Condition expression evaluated by this if statement."
          ],
          [
            "thenbody",
            "[AstStatBlock](#aststatblock)",
            "Block executed when this if statement condition is truthy."
          ],
          [
            "elsebody",
            "[AstStat](#aststat)?",
            "Else branch or chained `elseif` branch stored by this if statement."
          ],
          [
            "thenLocation",
            "[Location](#location)?",
            "Source span covering the `then` keyword of this if statement."
          ],
          [
            "elseLocation",
            "[Location](#location)?",
            "Source span covering the `else` or `elseif` keyword of this if statement."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this if statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatWhile",
      "anchor": "aststatwhile",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "While-loop statement.",
      "example": "while running do\n    step()\n    running = shouldContinue()\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"StatWhile\"",
            "Tag string used for this while statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this while statement."
          ],
          [
            "condition",
            "[AstExpr](#astexpr)",
            "Condition expression evaluated by this while statement."
          ],
          [
            "body",
            "[AstStatBlock](#aststatblock)",
            "Loop body executed by this while statement."
          ],
          [
            "hasDo",
            "boolean",
            "Whether this while statement consumed a `do` keyword."
          ],
          [
            "doLocation",
            "[Location](#location)",
            "Source span covering the `do` keyword of this while statement."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this while statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatRepeat",
      "anchor": "aststatrepeat",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Repeat-until loop statement.",
      "example": "repeat\n    step()\nuntil done",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstStatRepeat](#cststatrepeat)?",
            "Attached CstStatRepeat payload for this repeat statement when storeCstData is enabled."
          ],
          [
            "kind",
            "\"StatRepeat\"",
            "Tag string used for this repeat statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this repeat statement."
          ],
          [
            "condition",
            "[AstExpr](#astexpr)",
            "Condition expression checked by this repeat-until statement."
          ],
          [
            "body",
            "[AstStatBlock](#aststatblock)",
            "Loop body executed before the condition check of this repeat-until statement."
          ],
          [
            "hasUntil",
            "boolean",
            "Whether this repeat-until statement consumed an `until` keyword."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this repeat-until statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatBreak",
      "anchor": "aststatbreak",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Break statement.",
      "example": "while true do\n    break\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"StatBreak\"",
            "Tag string used for this break statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this break statement."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this break statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatContinue",
      "anchor": "aststatcontinue",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Continue statement.",
      "example": "for index = 1, 10 do\n    if index % 2 == 0 then\n        continue\n    end\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"StatContinue\"",
            "Tag string used for this continue statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this continue statement."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this continue statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatReturn",
      "anchor": "aststatreturn",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Return statement.",
      "example": "local function sum(left, right)\n    return left + right\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstStatReturn](#cststatreturn)?",
            "Attached CstStatReturn payload for this return statement when storeCstData is enabled."
          ],
          [
            "kind",
            "\"StatReturn\"",
            "Tag string used for this return statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this return statement."
          ],
          [
            "list",
            "{ [AstExpr](#astexpr) }",
            "Returned expressions stored by this return statement, in source order."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this return statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatExpr",
      "anchor": "aststatexpr",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Statement wrapper for an expression used in statement position.",
      "example": "runTask()\ncleanupTask()",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"StatExpr\"",
            "Tag string used for this expr statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this expr statement."
          ],
          [
            "expr",
            "[AstExpr](#astexpr)",
            "Expression executed by this expression statement."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this expression statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatLocal",
      "anchor": "aststatlocal",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Local variable declaration statement.",
      "example": "local first = 10\nlocal second, third = first + 5, first * 2",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstStatLocal](#cststatlocal)?",
            "Attached CstStatLocal payload for this local statement when storeCstData is enabled."
          ],
          [
            "kind",
            "\"StatLocal\"",
            "Tag string used for this local statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this local statement."
          ],
          [
            "vars",
            "{ [AstLocal](#astlocal) }",
            "Local bindings declared by this local statement, in source order."
          ],
          [
            "values",
            "{ [AstExpr](#astexpr) }",
            "Initializer expressions assigned by this local statement, in source order."
          ],
          [
            "equalsSignLocation",
            "[Location](#location)?",
            "Source span covering the `=` token of this local statement."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this local statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatFor",
      "anchor": "aststatfor",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Numeric `for` loop statement.",
      "example": "for index = 1, 10, 2 do\n    print(index)\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstStatFor](#cststatfor)?",
            "Attached CstStatFor payload for this for statement when storeCstData is enabled."
          ],
          [
            "kind",
            "\"StatFor\"",
            "Tag string used for this for statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this for statement."
          ],
          [
            "var",
            "[AstLocal](#astlocal)",
            "Loop variable introduced by this numeric for statement."
          ],
          [
            "from",
            "[AstExpr](#astexpr)",
            "Initial numeric expression of this numeric for statement."
          ],
          [
            "to",
            "[AstExpr](#astexpr)",
            "Limit expression of this numeric for statement."
          ],
          [
            "step",
            "[AstExpr](#astexpr)?",
            "Optional step expression of this numeric for statement."
          ],
          [
            "body",
            "[AstStatBlock](#aststatblock)",
            "Loop body executed by this numeric for statement."
          ],
          [
            "hasDo",
            "boolean",
            "Whether this numeric for statement consumed a `do` keyword."
          ],
          [
            "doLocation",
            "[Location](#location)",
            "Source span covering the `do` keyword of this numeric for statement."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this numeric for statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatForIn",
      "anchor": "aststatforin",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Generic `for ... in` loop statement.",
      "example": "for key, value in pairs(map) do\n    print(key, value)\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstStatForIn](#cststatforin)?",
            "Attached CstStatForIn payload for this for in statement when storeCstData is enabled."
          ],
          [
            "kind",
            "\"StatForIn\"",
            "Tag string used for this for in statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this for in statement."
          ],
          [
            "vars",
            "{ [AstLocal](#astlocal) }",
            "Iterator variables introduced by this generic for statement."
          ],
          [
            "values",
            "{ [AstExpr](#astexpr) }",
            "Iterator expressions evaluated by this generic for statement."
          ],
          [
            "body",
            "[AstStatBlock](#aststatblock)",
            "Loop body executed by this generic for statement."
          ],
          [
            "hasIn",
            "boolean",
            "Whether this generic for statement consumed an `in` keyword."
          ],
          [
            "inLocation",
            "[Location](#location)",
            "Source span covering the `in` keyword of this generic for statement."
          ],
          [
            "hasDo",
            "boolean",
            "Whether this generic for statement consumed a `do` keyword."
          ],
          [
            "doLocation",
            "[Location](#location)",
            "Source span covering the `do` keyword of this generic for statement."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this generic for statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatAssign",
      "anchor": "aststatassign",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Assignment statement.",
      "example": "left, right = right, left\ncount = count + 1",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstStatAssign](#cststatassign)?",
            "Attached CstStatAssign payload for this assign statement when storeCstData is enabled."
          ],
          [
            "kind",
            "\"StatAssign\"",
            "Tag string used for this assign statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this assign statement."
          ],
          [
            "vars",
            "{ [AstExpr](#astexpr) }",
            "Assignment targets stored by this assignment statement, in source order."
          ],
          [
            "values",
            "{ [AstExpr](#astexpr) }",
            "Value expressions assigned by this assignment statement, in source order."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this assignment statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatCompoundAssign",
      "anchor": "aststatcompoundassign",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Compound assignment statement such as `+=`.",
      "example": "count += 1\nscore *= 2",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstStatCompoundAssign](#cststatcompoundassign)?",
            "Attached CstStatCompoundAssign payload for this compound assign statement when storeCstData is enabled."
          ],
          [
            "kind",
            "\"StatCompoundAssign\"",
            "Tag string used for this compound assign statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this compound assign statement."
          ],
          [
            "op",
            "number",
            "Compound operator enum stored by this compound assignment statement."
          ],
          [
            "var",
            "[AstExpr](#astexpr)",
            "Target expression updated by this compound assignment statement."
          ],
          [
            "value",
            "[AstExpr](#astexpr)",
            "Right-hand expression applied by this compound assignment statement."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this compound assignment statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatFunction",
      "anchor": "aststatfunction",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Function declaration statement.",
      "example": "function buildName(first, last)\n    return first .. last\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstStatFunction](#cststatfunction)?",
            "Attached CstStatFunction payload for this function statement when storeCstData is enabled."
          ],
          [
            "kind",
            "\"StatFunction\"",
            "Tag string used for this function statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this function statement."
          ],
          [
            "name",
            "[AstExpr](#astexpr)",
            "Target expression naming this function declaration."
          ],
          [
            "func",
            "[AstExprFunction](#astexprfunction)",
            "Function literal assigned by this function declaration."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this function declaration ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatLocalFunction",
      "anchor": "aststatlocalfunction",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Local function declaration statement.",
      "example": "local function normalize(value)\n    return value:lower()\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstStatLocalFunction](#cststatlocalfunction)?",
            "Attached CstStatLocalFunction payload for this local function statement when storeCstData is enabled."
          ],
          [
            "kind",
            "\"StatLocalFunction\"",
            "Tag string used for this local function statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this local function statement."
          ],
          [
            "name",
            "[AstLocal](#astlocal)?",
            "Local binding created for this local function declaration."
          ],
          [
            "func",
            "[AstExprFunction](#astexprfunction)",
            "Function literal assigned by this local function declaration."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this local function declaration ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatTypeAlias",
      "anchor": "aststattypealias",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Type alias declaration statement.",
      "example": "type UserId = number\ntype UserName = string",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstStatTypeAlias](#cststattypealias)?",
            "Attached CstStatTypeAlias payload for this type alias statement when storeCstData is enabled."
          ],
          [
            "kind",
            "\"StatTypeAlias\"",
            "Tag string used for this type alias statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this type alias statement."
          ],
          [
            "name",
            "string",
            "Alias name text declared by this type-alias statement."
          ],
          [
            "nameLocation",
            "[Location](#location)",
            "Source span covering the alias name of this type-alias statement."
          ],
          [
            "generics",
            "{ [AstGenericType](#astgenerictype) }",
            "Generic type parameters declared by this type-alias statement."
          ],
          [
            "genericPacks",
            "{ [AstGenericTypePack](#astgenerictypepack) }",
            "Generic type-pack parameters declared by this type-alias statement."
          ],
          [
            "type",
            "[AstType](#asttype)",
            "Aliased type expression stored by this type-alias statement."
          ],
          [
            "exported",
            "boolean",
            "Whether this type-alias statement uses the `export type` form."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this type-alias statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstStatTypeFunction",
      "anchor": "aststattypefunction",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Type function declaration statement.",
      "example": "type function id(value)\n    return value\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstStatTypeFunction](#cststattypefunction)?",
            "Attached CstStatTypeFunction payload for this type function statement when storeCstData is enabled."
          ],
          [
            "kind",
            "\"StatTypeFunction\"",
            "Tag string used for this type function statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this type function statement."
          ],
          [
            "name",
            "string",
            "Declared name text of this type-function statement."
          ],
          [
            "nameLocation",
            "[Location](#location)",
            "Source span covering the name of this type-function statement."
          ],
          [
            "body",
            "[AstExprFunction](#astexprfunction)",
            "Function literal body stored by this type-function statement."
          ],
          [
            "exported",
            "boolean",
            "Whether this type-function statement uses the `export` form."
          ],
          [
            "hasErrors",
            "boolean",
            "Whether this type-function statement was produced after parser recovery."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this type-function statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstTableProp",
      "anchor": "asttableprop",
      "group": "Core",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [],
      "description": "Named property entry inside a table type.",
      "example": "type Config = { enabled: boolean, retries: number }\ntype User = { name: string, age: number }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"TableProp\"",
            "Tag string used for this table-type property."
          ],
          [
            "name",
            "[AstName](#astname)",
            "Structured property name stored by this table-type property."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this table-type property."
          ],
          [
            "type",
            "[AstType](#asttype)",
            "Property type stored by this table-type property."
          ],
          [
            "access",
            "string",
            "Access modifier string stored by this table-type property."
          ],
          [
            "accessLocation",
            "[Location](#location)?",
            "Source span covering the access modifier of this table-type property."
          ]
        ]
      }
    },
    {
      "name": "AstTableIndexer",
      "anchor": "asttableindexer",
      "group": "Core",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [],
      "description": "Indexer entry inside a table type.",
      "example": "type Scores = { [string]: number }\ntype Nodes = { [AstExpr]: string }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"TableIndexer\"",
            "Tag string used for this table-type indexer."
          ],
          [
            "indexType",
            "[AstType](#asttype)",
            "Key type required by this table-type indexer."
          ],
          [
            "resultType",
            "[AstType](#asttype)",
            "Result type produced by this table-type indexer."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this table-type indexer."
          ],
          [
            "access",
            "string",
            "Access modifier string stored by this table-type indexer."
          ],
          [
            "accessLocation",
            "[Location](#location)?",
            "Source span covering the access modifier of this table-type indexer."
          ]
        ]
      }
    },
    {
      "name": "AstStatError",
      "anchor": "aststaterror",
      "group": "Statements",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Error-recovery statement created when statement parsing failed.",
      "example": "local ok, result = Parser.parse(\"local =\")\nwarn(result.errors)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"StatError\"",
            "Tag string used for this error statement."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this error statement."
          ],
          [
            "expressions",
            "{ [AstExpr](#astexpr) }",
            "Recovered expression fragments stored by this error statement."
          ],
          [
            "statements",
            "{ [AstStat](#aststat) }",
            "Recovered statement fragments stored by this error statement."
          ],
          [
            "messageIndex",
            "number",
            "Internal error-message index stored by this error statement."
          ],
          [
            "hasSemicolon",
            "boolean?",
            "Whether this error statement ended with a trailing semicolon in source."
          ]
        ]
      }
    },
    {
      "name": "AstTypeReference",
      "anchor": "asttypereference",
      "group": "Types",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Named type reference, optionally with a prefix and explicit parameters.",
      "example": "type UserId = number\ntype NameMap = Map<string, string>",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstTypeReference](#csttypereference)?",
            "Attached CstTypeReference payload for this reference type when storeCstData is enabled."
          ],
          [
            "kind",
            "\"TypeReference\"",
            "Tag string used for this reference type."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this reference type."
          ],
          [
            "hasParameterList",
            "boolean",
            "Whether this type reference used an explicit generic parameter list."
          ],
          [
            "prefix",
            "string?",
            "Namespace or module prefix stored by this type reference."
          ],
          [
            "prefixLocation",
            "[Location](#location)?",
            "Source span covering the prefix of this type reference."
          ],
          [
            "name",
            "string",
            "Referenced type name text stored by this type reference."
          ],
          [
            "nameLocation",
            "[Location](#location)",
            "Source span covering the type name of this type reference."
          ],
          [
            "parameters",
            "{ [AstTypeOrPack](#asttypeorpack) }",
            "Explicit type arguments applied by this type reference."
          ]
        ]
      }
    },
    {
      "name": "AstTypeTable",
      "anchor": "asttypetable",
      "group": "Types",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Table type with named properties and an optional indexer.",
      "example": "type Config = { enabled: boolean, retries: number }\ntype User = { name: string, age: number }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstTypeTable](#csttypetable)?",
            "Attached CstTypeTable payload for this table type when storeCstData is enabled."
          ],
          [
            "kind",
            "\"TypeTable\"",
            "Tag string used for this table type."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this table type."
          ],
          [
            "props",
            "{ [AstTableProp](#asttableprop) }",
            "Named properties stored by this table type, in source order."
          ],
          [
            "indexer",
            "[AstTableIndexer](#asttableindexer)?",
            "Optional indexer stored by this table type."
          ]
        ]
      }
    },
    {
      "name": "AstTypeFunction",
      "anchor": "asttypefunction",
      "group": "Types",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Function type with argument names, argument types, and a return pack.",
      "example": "type Mapper = (input: string, retries: number) -> boolean\ntype Loader = (id: number) -> string",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstTypeFunction](#csttypefunction)?",
            "Attached CstTypeFunction payload for this function type when storeCstData is enabled."
          ],
          [
            "kind",
            "\"TypeFunction\"",
            "Tag string used for this function type."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this function type."
          ],
          [
            "attributes",
            "{ [AstAttr](#astattr) }",
            "Attributes attached to this function type."
          ],
          [
            "generics",
            "{ [AstGenericType](#astgenerictype) }",
            "Generic type parameters declared by this function type."
          ],
          [
            "genericPacks",
            "{ [AstGenericTypePack](#astgenerictypepack) }",
            "Generic type-pack parameters declared by this function type."
          ],
          [
            "argTypes",
            "[AstTypeList](#asttypelist)",
            "Argument type list stored by this function type."
          ],
          [
            "argNames",
            "{ [AstArgumentName](#astargumentname) | boolean }",
            "Optional argument names aligned with the argument types of this function type."
          ],
          [
            "returnTypes",
            "[AstTypePack](#asttypepack)",
            "Return type pack stored by this function type."
          ]
        ]
      }
    },
    {
      "name": "AstTypeTypeof",
      "anchor": "asttypetypeof",
      "group": "Types",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Type query wrapping an expression.",
      "example": "type PartType = typeof(workspace.Part)\ntype ModelType = typeof(workspace.Model)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstTypeTypeof](#csttypetypeof)?",
            "Attached CstTypeTypeof payload for this typeof type when storeCstData is enabled."
          ],
          [
            "kind",
            "\"TypeTypeof\"",
            "Tag string used for this typeof type."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this typeof type."
          ],
          [
            "expr",
            "[AstExpr](#astexpr)",
            "Expression wrapped by this typeof type."
          ]
        ]
      }
    },
    {
      "name": "AstTypeUnion",
      "anchor": "asttypeunion",
      "group": "Types",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Union type made from multiple branches.",
      "example": "type Status = \"ready\" | \"waiting\" | \"done\"\ntype Id = string | number",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstTypeUnion](#csttypeunion)?",
            "Attached CstTypeUnion payload for this union type when storeCstData is enabled."
          ],
          [
            "kind",
            "\"TypeUnion\"",
            "Tag string used for this union type."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this union type."
          ],
          [
            "types",
            "{ [AstType](#asttype) }",
            "Union branches stored by this union type, in source order."
          ]
        ]
      }
    },
    {
      "name": "AstTypeIntersection",
      "anchor": "asttypeintersection",
      "group": "Types",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Intersection type made from multiple branches.",
      "example": "type Combined = Readable & Writable\ntype Entity = HasId & HasName",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstTypeIntersection](#csttypeintersection)?",
            "Attached CstTypeIntersection payload for this intersection type when storeCstData is enabled."
          ],
          [
            "kind",
            "\"TypeIntersection\"",
            "Tag string used for this intersection type."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this intersection type."
          ],
          [
            "types",
            "{ [AstType](#asttype) }",
            "Intersection branches stored by this intersection type, in source order."
          ]
        ]
      }
    },
    {
      "name": "AstTypeSingletonBool",
      "anchor": "asttypesingletonbool",
      "group": "Types",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Boolean singleton type.",
      "example": "type Enabled = true\ntype Disabled = false",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"TypeSingletonBool\"",
            "Tag string used for this singleton bool type."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this singleton bool type."
          ],
          [
            "value",
            "boolean",
            "Boolean literal stored by this singleton-bool type."
          ]
        ]
      }
    },
    {
      "name": "AstTypeSingletonString",
      "anchor": "asttypesingletonstring",
      "group": "Types",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type"
      ],
      "description": "String singleton type.",
      "example": "type Mode = \"auto\"\ntype State = \"idle\"",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"TypeSingletonString\"",
            "Tag string used for this singleton string type."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this singleton string type."
          ],
          [
            "value",
            "string",
            "String literal stored by this singleton-string type."
          ]
        ]
      }
    },
    {
      "name": "AstTypeGroup",
      "anchor": "asttypegroup",
      "group": "Types",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Parenthesized type used to preserve grouping.",
      "example": "type Value = (string | number) & HasId\ntype Result = (Readable & Writable) | nil",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"TypeGroup\"",
            "Tag string used for this group type."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this group type."
          ],
          [
            "type",
            "[AstType](#asttype)",
            "Grouped type stored by this parenthesized type."
          ]
        ]
      }
    },
    {
      "name": "AstTypeError",
      "anchor": "asttypeerror",
      "group": "Types",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Error-recovery type node.",
      "example": "local ok, result = Parser.parse(\"type Broken = |\")\nwarn(result.errors)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"TypeError\"",
            "Tag string used for this error type."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this error type."
          ],
          [
            "types",
            "{ [AstType](#asttype) }",
            "Recovered type fragments stored by this error type."
          ],
          [
            "isMissing",
            "boolean",
            "Whether this error type was inserted for a missing type."
          ],
          [
            "messageIndex",
            "number",
            "Internal error-message index stored by this error type."
          ]
        ]
      }
    },
    {
      "name": "AstTypeOptional",
      "anchor": "asttypeoptional",
      "group": "Types",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Standalone optional-type placeholder used by parser recovery.",
      "example": "local ok, result = Parser.parse(\"type Value = number?\")\nprint(ok, result.root)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"TypeOptional\"",
            "Tag string used for this optional type."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this optional type."
          ]
        ]
      }
    },
    {
      "name": "AstTypePackExplicit",
      "anchor": "asttypepackexplicit",
      "group": "Type Packs",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type Pack"
      ],
      "description": "Explicit type pack with fixed entries and an optional tail pack.",
      "example": "type Callback = (string, number, ...boolean) -> ()\ntype Loader = (number, ...string) -> (...boolean)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstTypePackExplicit](#csttypepackexplicit)?",
            "Attached CstTypePackExplicit payload for this explicit type pack when storeCstData is enabled."
          ],
          [
            "kind",
            "\"TypePackExplicit\"",
            "Tag string used for this explicit type pack."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this explicit type pack."
          ],
          [
            "types",
            "{ [AstType](#asttype) }",
            "Fixed type entries stored by this explicit type pack."
          ],
          [
            "tailType",
            "[AstTypePack](#asttypepack)?",
            "Optional tail type pack stored by this explicit type pack."
          ]
        ]
      }
    },
    {
      "name": "AstTypePackVariadic",
      "anchor": "asttypepackvariadic",
      "group": "Type Packs",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type Pack"
      ],
      "description": "Variadic type pack.",
      "example": "type Callback = (...string) -> ()\ntype Reducer = (...number) -> number",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"TypePackVariadic\"",
            "Tag string used for this variadic type pack."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this variadic type pack."
          ],
          [
            "variadicType",
            "[AstType](#asttype)",
            "Repeated element type stored by this variadic type pack."
          ]
        ]
      }
    },
    {
      "name": "AstTypePackGeneric",
      "anchor": "asttypepackgeneric",
      "group": "Type Packs",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Type Pack"
      ],
      "description": "Reference to a generic type pack.",
      "example": "type Callback<Args...> = (Args...) -> ()\ntype Wrapper<Values...> = (Values...) -> string",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "cstNode",
            "[CstTypePackGeneric](#csttypepackgeneric)?",
            "Attached CstTypePackGeneric payload for this generic type pack when storeCstData is enabled."
          ],
          [
            "kind",
            "\"TypePackGeneric\"",
            "Tag string used for this generic type pack."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this generic type pack."
          ],
          [
            "genericName",
            "string",
            "Referenced generic pack name stored by this generic type pack."
          ]
        ]
      }
    },
    {
      "name": "Binding",
      "anchor": "binding",
      "group": "Core",
      "category": "core",
      "badges": [
        "CORE"
      ],
      "tags": [],
      "description": "Binding record with a name, location, and optional annotation.",
      "example": "local firstBinding: Binding = { name = { value = \"value\" }, location = firstLoc, annotation = nil }\nlocal secondBinding: Binding = { name = { value = \"count\" }, location = secondLoc, annotation = numberType }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "name",
            "[AstName](#astname)",
            "Structured binding name stored by this binding record."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this binding record."
          ],
          [
            "annotation",
            "[AstType](#asttype)?",
            "Optional type annotation stored by this binding record."
          ],
          [
            "colonPosition",
            "[Position](#position)?",
            "Source position recorded for colon on this binding record."
          ]
        ]
      }
    },
    {
      "name": "BindingList",
      "anchor": "bindinglist",
      "group": "Core",
      "category": "core",
      "badges": [
        "CORE"
      ],
      "tags": [],
      "description": "Alias for { [Binding](#binding) }.",
      "example": "local bindings: BindingList = { firstBinding, secondBinding }\nlocal copy: BindingList = { table.unpack(bindings) }",
      "table": {
        "type": "members",
        "headers": [
          "Member",
          "Description"
        ],
        "rows": [
          [
            "{ [Binding](#binding) }",
            "BindingList keeps this exported collection shape."
          ]
        ]
      }
    },
    {
      "name": "Attrs",
      "anchor": "attrs",
      "group": "Core",
      "category": "core",
      "badges": [
        "CORE"
      ],
      "tags": [],
      "description": "Alias for { [AstAttr](#astattr) }.",
      "example": "local attrs: Attrs = { fastAttr, checkedAttr }\nlocal moreAttrs: Attrs = { deprecatedAttr }",
      "table": {
        "type": "members",
        "headers": [
          "Member",
          "Description"
        ],
        "rows": [
          [
            "{ [AstAttr](#astattr) }",
            "Attrs keeps this exported collection shape."
          ]
        ]
      }
    },
    {
      "name": "CstExprConstantNumber",
      "anchor": "cstexprconstantnumber",
      "group": "CST Expressions",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "CST payload for a numeric literal expression.",
      "example": "local width = 128\nlocal doubled = width * 2",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstExprConstantNumber\"",
            "Tag string used for this constant number expression CST payload."
          ],
          [
            "value",
            "string?",
            "Original numeric token text preserved by this CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstExprConstantString",
      "anchor": "cstexprconstantstring",
      "group": "CST Expressions",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "CST payload for a string literal expression.",
      "example": "local greeting = \"hello\"\nlocal label = greeting .. \" world\"",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstExprConstantString\"",
            "Tag string used for this constant string expression CST payload."
          ],
          [
            "sourceString",
            "string?",
            "Raw string token text preserved by this CST payload."
          ],
          [
            "quoteStyle",
            "number",
            "Quote-style enum value preserved by this CST string payload."
          ],
          [
            "blockDepth",
            "number",
            "Raw-string block depth preserved by this CST string payload."
          ]
        ]
      }
    },
    {
      "name": "CstTypeInstantiation",
      "anchor": "csttypeinstantiation",
      "group": "CST Types",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Token positions for an explicit type argument list.",
      "example": "local result = build<<string, number>>(\"id\", 4)\nlocal nextValue = wrap<<boolean>>(true)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstTypeInstantiation\"",
            "Tag string used for this instantiation type CST payload."
          ],
          [
            "leftArrow1Position",
            "[Position](#position)",
            "Source position recorded for left arrow1 on this instantiation type CST payload."
          ],
          [
            "leftArrow2Position",
            "[Position](#position)?",
            "Source position recorded for left arrow2 on this instantiation type CST payload."
          ],
          [
            "commaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for comma on this instantiation type CST payload."
          ],
          [
            "rightArrow1Position",
            "[Position](#position)?",
            "Source position recorded for right arrow1 on this instantiation type CST payload."
          ],
          [
            "rightArrow2Position",
            "[Position](#position)",
            "Source position recorded for right arrow2 on this instantiation type CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstExprCall",
      "anchor": "cstexprcall",
      "group": "CST Expressions",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Token positions collected for a call expression.",
      "example": "local built = buildValue(4, 8)\nlocal result = normalize(built)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstExprCall\"",
            "Tag string used for this call expression CST payload."
          ],
          [
            "openParens",
            "[Position](#position)?",
            "Optional open parens stored by this call expression CST payload."
          ],
          [
            "closeParens",
            "[Position](#position)?",
            "Optional close parens stored by this call expression CST payload."
          ],
          [
            "commaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for comma on this call expression CST payload."
          ],
          [
            "explicitTypes",
            "[CstTypeInstantiation](#csttypeinstantiation)?",
            "Optional explicit types stored by this call expression CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstExprIndexExpr",
      "anchor": "cstexprindexexpr",
      "group": "CST Expressions",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Bracket token positions for an index expression.",
      "example": "local current = values[index]\nlocal nextValue = values[index + 1]",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstExprIndexExpr\"",
            "Tag string used for this index expr expression CST payload."
          ],
          [
            "openBracketPosition",
            "[Position](#position)",
            "Source position recorded for open bracket on this index expr expression CST payload."
          ],
          [
            "closeBracketPosition",
            "[Position](#position)",
            "Source position recorded for close bracket on this index expr expression CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstExprFunction",
      "anchor": "cstexprfunction",
      "group": "CST Expressions",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Token positions collected for a function literal.",
      "example": "local fn = function(left: number, right: number): number\n    return left + right\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstExprFunction\"",
            "Tag string used for this function expression CST payload."
          ],
          [
            "functionKeywordPosition",
            "[Position](#position)",
            "Source position recorded for function keyword on this function expression CST payload."
          ],
          [
            "openGenericsPosition",
            "[Position](#position)",
            "Source position recorded for open generics on this function expression CST payload."
          ],
          [
            "genericsCommaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for generic parameters comma on this function expression CST payload."
          ],
          [
            "closeGenericsPosition",
            "[Position](#position)",
            "Source position recorded for close generics on this function expression CST payload."
          ],
          [
            "argsAnnotationColonPositions",
            "{ [Position](#position)? }",
            "Source positions recorded for arguments annotation colon on this function expression CST payload."
          ],
          [
            "argsCommaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for arguments comma on this function expression CST payload."
          ],
          [
            "varargAnnotationColonPosition",
            "[Position](#position)?",
            "Source position recorded for vararg annotation colon on this function expression CST payload."
          ],
          [
            "returnSpecifierPosition",
            "[Position](#position)",
            "Source position recorded for return specifier on this function expression CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstExprTableItem",
      "anchor": "cstexprtableitem",
      "group": "CST Expressions",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Per-item CST payload for a table constructor entry.",
      "example": "local config = { enabled = true, retries = 3 }\nlocal result = { [key] = value, 42 }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"Record\" | \"General\" | \"List\"",
            "Tag string used for this table item expression CST payload."
          ],
          [
            "equalsPosition",
            "[Position](#position)?",
            "Source position recorded for equals on this table item expression CST payload."
          ],
          [
            "separator",
            "number?",
            "Separator token kind stored by this table item expression CST payload."
          ],
          [
            "separatorPosition",
            "[Position](#position)",
            "Source position recorded for separator on this table item expression CST payload."
          ],
          [
            "indexerOpenPosition",
            "[Position](#position)?",
            "Source position recorded for indexer open on this table item expression CST payload."
          ],
          [
            "indexerClosePosition",
            "[Position](#position)?",
            "Source position recorded for indexer close on this table item expression CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstExprTable",
      "anchor": "cstexprtable",
      "group": "CST Expressions",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "CST payload for a table constructor.",
      "example": "local config = {\n    enabled = true,\n    retries = 3,\n}",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstExprTable\"",
            "Tag string used for this table expression CST payload."
          ],
          [
            "items",
            "{ [CstExprTableItem](#cstexprtableitem) }",
            "Ordered items entries stored by this table expression CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstExprOp",
      "anchor": "cstexprop",
      "group": "CST Expressions",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Operator token payload shared by unary and binary expressions.",
      "example": "local total = base + bonus\nlocal inverse = -delta",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstExprOp\"",
            "Tag string used for this op expression CST payload."
          ],
          [
            "opPosition",
            "[Position](#position)",
            "Source position recorded for operator on this op expression CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstExprTypeAssertion",
      "anchor": "cstexprtypeassertion",
      "group": "CST Expressions",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Token payload for a type assertion expression.",
      "example": "local name = value :: string\nlocal count = size :: number",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstExprTypeAssertion\"",
            "Tag string used for this type assertion expression CST payload."
          ],
          [
            "opPosition",
            "[Position](#position)",
            "Source position recorded for operator on this type assertion expression CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstExprIfElse",
      "anchor": "cstexprifelse",
      "group": "CST Expressions",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Keyword positions for an if-expression.",
      "example": "local label =\n    if ready then \"ready\"\n    else \"waiting\"",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstExprIfElse\"",
            "Tag string used for this if else expression CST payload."
          ],
          [
            "thenPosition",
            "[Position](#position)",
            "Source position recorded for then on this if else expression CST payload."
          ],
          [
            "elsePosition",
            "[Position](#position)",
            "Source position recorded for else on this if else expression CST payload."
          ],
          [
            "isElseIf",
            "boolean",
            "is else if value stored by this if else expression CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstExprInterpString",
      "anchor": "cstexprinterpstring",
      "group": "CST Expressions",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "Raw pieces and positions for an interpolated string.",
      "example": "local label = `name = {name}`\nlocal line = `score = {score}`",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstExprInterpString\"",
            "Tag string used for this interp string expression CST payload."
          ],
          [
            "sourceStrings",
            "{ string }",
            "Ordered source strings entries stored by this interp string expression CST payload."
          ],
          [
            "stringPositions",
            "{ [Position](#position) }",
            "Source positions recorded for string on this interp string expression CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstExprExplicitTypeInstantiation",
      "anchor": "cstexprexplicittypeinstantiation",
      "group": "CST Expressions",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Expression"
      ],
      "description": "CST wrapper for explicit type-instantiation syntax on expressions.",
      "example": "local result = create<<string, number>>(\"id\", 4)\nlocal copy = wrap<<boolean>>(true)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstExprExplicitTypeInstantiation\"",
            "Tag string used for this explicit type instantiation expression CST payload."
          ],
          [
            "instantiation",
            "[CstTypeInstantiation](#csttypeinstantiation)",
            "instantiation value stored by this explicit type instantiation expression CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstStatDo",
      "anchor": "cststatdo",
      "group": "CST Statements",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "CST payload for a `do ... end` block.",
      "example": "do\n    local first = 1\n    local second = first + 1\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstStatDo\"",
            "Tag string used for this do statement CST payload."
          ],
          [
            "statsStart",
            "[Position](#position)",
            "stats start value stored by this do statement CST payload."
          ],
          [
            "endPosition",
            "[Position](#position)",
            "Source position recorded for end on this do statement CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstStatDo_DEPRECATED",
      "anchor": "cststatdo_deprecated",
      "group": "CST Statements",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Older CST layout kept for `StatBlock` compatibility.",
      "example": "do\n    local first = 1\n    local second = first + 1\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstStatDo_DEPRECATED\"",
            "Tag string used for this do_deprecated statement CST payload."
          ],
          [
            "endPosition",
            "[Position](#position)",
            "Source position recorded for end on this do_deprecated statement CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstStatRepeat",
      "anchor": "cststatrepeat",
      "group": "CST Statements",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "CST payload for a repeat-until loop.",
      "example": "repeat\n    step()\nuntil done",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstStatRepeat\"",
            "Tag string used for this repeat statement CST payload."
          ],
          [
            "untilPosition",
            "[Position](#position)",
            "Source position recorded for until on this repeat statement CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstStatReturn",
      "anchor": "cststatreturn",
      "group": "CST Statements",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Comma token positions for a return statement.",
      "example": "local function sum(left, right)\n    return left, right\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstStatReturn\"",
            "Tag string used for this return statement CST payload."
          ],
          [
            "commaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for comma on this return statement CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstStatLocal",
      "anchor": "cststatlocal",
      "group": "CST Statements",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Token positions captured for a local declaration.",
      "example": "local first: number, second = 1, 2\nlocal third: string = \"value\"",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstStatLocal\"",
            "Tag string used for this local statement CST payload."
          ],
          [
            "varsAnnotationColonPositions",
            "{ [Position](#position)? }",
            "Source positions recorded for vars annotation colon on this local statement CST payload."
          ],
          [
            "varsCommaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for vars comma on this local statement CST payload."
          ],
          [
            "valuesCommaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for values comma on this local statement CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstStatFor",
      "anchor": "cststatfor",
      "group": "CST Statements",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Token positions captured for a numeric `for` loop.",
      "example": "for index: number = 1, 10, 2 do\n    print(index)\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstStatFor\"",
            "Tag string used for this for statement CST payload."
          ],
          [
            "annotationColonPosition",
            "[Position](#position)?",
            "Source position recorded for annotation colon on this for statement CST payload."
          ],
          [
            "equalsPosition",
            "[Position](#position)",
            "Source position recorded for equals on this for statement CST payload."
          ],
          [
            "endCommaPosition",
            "[Position](#position)",
            "Source position recorded for end comma on this for statement CST payload."
          ],
          [
            "stepCommaPosition",
            "[Position](#position)?",
            "Source position recorded for step comma on this for statement CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstStatForIn",
      "anchor": "cststatforin",
      "group": "CST Statements",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Token positions captured for a generic `for ... in` loop.",
      "example": "for key: string, value in pairs(map) do\n    print(key, value)\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstStatForIn\"",
            "Tag string used for this for in statement CST payload."
          ],
          [
            "varsAnnotationColonPositions",
            "{ [Position](#position)? }",
            "Source positions recorded for vars annotation colon on this for in statement CST payload."
          ],
          [
            "varsCommaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for vars comma on this for in statement CST payload."
          ],
          [
            "valuesCommaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for values comma on this for in statement CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstStatAssign",
      "anchor": "cststatassign",
      "group": "CST Statements",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Token positions captured for an assignment statement.",
      "example": "left, right = right, left\ncount = count + 1",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstStatAssign\"",
            "Tag string used for this assign statement CST payload."
          ],
          [
            "varsCommaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for vars comma on this assign statement CST payload."
          ],
          [
            "equalsPosition",
            "[Position](#position)",
            "Source position recorded for equals on this assign statement CST payload."
          ],
          [
            "valuesCommaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for values comma on this assign statement CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstStatCompoundAssign",
      "anchor": "cststatcompoundassign",
      "group": "CST Statements",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Operator token payload for a compound assignment statement.",
      "example": "count += 1\nscore *= 2",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstStatCompoundAssign\"",
            "Tag string used for this compound assign statement CST payload."
          ],
          [
            "opPosition",
            "[Position](#position)",
            "Source position recorded for operator on this compound assign statement CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstStatFunction",
      "anchor": "cststatfunction",
      "group": "CST Statements",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Keyword positions for a function declaration.",
      "example": "function buildName(first, last)\n    return first .. last\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstStatFunction\"",
            "Tag string used for this function statement CST payload."
          ],
          [
            "functionKeywordPosition",
            "[Position](#position)",
            "Source position recorded for function keyword on this function statement CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstStatLocalFunction",
      "anchor": "cststatlocalfunction",
      "group": "CST Statements",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Keyword positions for a local function declaration.",
      "example": "local function normalize(value)\n    return value:lower()\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstStatLocalFunction\"",
            "Tag string used for this local function statement CST payload."
          ],
          [
            "localKeywordPosition",
            "[Position](#position)",
            "Source position recorded for local keyword on this local function statement CST payload."
          ],
          [
            "functionKeywordPosition",
            "[Position](#position)",
            "Source position recorded for function keyword on this local function statement CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstGenericType",
      "anchor": "cstgenerictype",
      "group": "CST Generics",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Generic"
      ],
      "description": "CST payload for a generic parameter declaration.",
      "example": "type Box<T = string> = { value: T }\ntype Callback<Args... = ...string> = (Args...) -> ()",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstGenericType\"",
            "Tag string used for this generic type CST payload."
          ],
          [
            "defaultEqualsPosition",
            "[Position](#position)?",
            "Source position recorded for default equals on this generic type CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstGenericTypePack",
      "anchor": "cstgenerictypepack",
      "group": "CST Generics",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Generic"
      ],
      "description": "CST payload for a generic parameter declaration.",
      "example": "type Box<T = string> = { value: T }\ntype Callback<Args... = ...string> = (Args...) -> ()",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstGenericTypePack\"",
            "Tag string used for this generic type pack CST payload."
          ],
          [
            "ellipsisPosition",
            "[Position](#position)",
            "Source position recorded for ellipsis on this generic type pack CST payload."
          ],
          [
            "defaultEqualsPosition",
            "[Position](#position)?",
            "Source position recorded for default equals on this generic type pack CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstStatTypeAlias",
      "anchor": "cststattypealias",
      "group": "CST Statements",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Token positions captured for a type alias declaration.",
      "example": "type UserId<T> = T\ntype Pair<K, V> = { key: K, value: V }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstStatTypeAlias\"",
            "Tag string used for this type alias statement CST payload."
          ],
          [
            "typeKeywordPosition",
            "[Position](#position)",
            "Source position recorded for type keyword on this type alias statement CST payload."
          ],
          [
            "genericsOpenPosition",
            "[Position](#position)?",
            "Source position recorded for generic parameters open on this type alias statement CST payload."
          ],
          [
            "genericsCommaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for generic parameters comma on this type alias statement CST payload."
          ],
          [
            "genericsClosePosition",
            "[Position](#position)?",
            "Source position recorded for generic parameters close on this type alias statement CST payload."
          ],
          [
            "equalsPosition",
            "[Position](#position)",
            "Source position recorded for equals on this type alias statement CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstStatTypeFunction",
      "anchor": "cststattypefunction",
      "group": "CST Statements",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Statement"
      ],
      "description": "Token positions captured for a type function declaration.",
      "example": "type function id(value)\n    return value\nend",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstStatTypeFunction\"",
            "Tag string used for this type function statement CST payload."
          ],
          [
            "typeKeywordPosition",
            "[Position](#position)",
            "Source position recorded for type keyword on this type function statement CST payload."
          ],
          [
            "functionKeywordPosition",
            "[Position](#position)",
            "Source position recorded for function keyword on this type function statement CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstTypeReference",
      "anchor": "csttypereference",
      "group": "CST Types",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Type"
      ],
      "description": "CST payload for a type reference.",
      "example": "type NameMap = Map<string, string>\ntype Lookup = Result<number>",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstTypeReference\"",
            "Tag string used for this reference type CST payload."
          ],
          [
            "prefixPointPosition",
            "[Position](#position)?",
            "Source position recorded for prefix point on this reference type CST payload."
          ],
          [
            "openParametersPosition",
            "[Position](#position)?",
            "Source position recorded for open parameters on this reference type CST payload."
          ],
          [
            "parametersCommaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for parameters comma on this reference type CST payload."
          ],
          [
            "closeParametersPosition",
            "[Position](#position)?",
            "Source position recorded for close parameters on this reference type CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstTypeTableItem",
      "anchor": "csttypetableitem",
      "group": "CST Types",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Per-item CST payload for a table type entry.",
      "example": "type Scores = { [string]: number }\ntype User = { name: string, age: number }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"Property\" | \"StringProperty\" | \"Indexer\"",
            "Tag string used for this table item type CST payload."
          ],
          [
            "colonPosition",
            "[Position](#position)?",
            "Source position recorded for colon on this table item type CST payload."
          ],
          [
            "separator",
            "number?",
            "Separator token kind stored by this table item type CST payload."
          ],
          [
            "separatorPosition",
            "[Position](#position)?",
            "Source position recorded for separator on this table item type CST payload."
          ],
          [
            "indexerOpenPosition",
            "[Position](#position)?",
            "Source position recorded for indexer open on this table item type CST payload."
          ],
          [
            "indexerClosePosition",
            "[Position](#position)?",
            "Source position recorded for indexer close on this table item type CST payload."
          ],
          [
            "stringInfo",
            "[CstExprConstantString](#cstexprconstantstring)?",
            "Optional string info stored by this table item type CST payload."
          ],
          [
            "stringPosition",
            "[Position](#position)?",
            "Source position recorded for string on this table item type CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstTypeTable",
      "anchor": "csttypetable",
      "group": "CST Types",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Type"
      ],
      "description": "CST payload for a table type.",
      "example": "type Config = { enabled: boolean, retries: number }\ntype Scores = { [string]: number }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstTypeTable\"",
            "Tag string used for this table type CST payload."
          ],
          [
            "items",
            "{ [CstTypeTableItem](#csttypetableitem) }",
            "Ordered items entries stored by this table type CST payload."
          ],
          [
            "isArray",
            "boolean",
            "is array value stored by this table type CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstTypeFunction",
      "anchor": "csttypefunction",
      "group": "CST Types",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Token positions captured for a function type.",
      "example": "type Mapper<T> = (value: T, retries: number) -> boolean\ntype Loader = (id: number) -> string",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstTypeFunction\"",
            "Tag string used for this function type CST payload."
          ],
          [
            "openGenericsPosition",
            "[Position](#position)",
            "Source position recorded for open generics on this function type CST payload."
          ],
          [
            "genericsCommaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for generic parameters comma on this function type CST payload."
          ],
          [
            "closeGenericsPosition",
            "[Position](#position)",
            "Source position recorded for close generics on this function type CST payload."
          ],
          [
            "openArgsPosition",
            "[Position](#position)",
            "Source position recorded for open args on this function type CST payload."
          ],
          [
            "argumentNameColonPositions",
            "{ [Position](#position) | boolean }",
            "Source positions recorded for argument name colon on this function type CST payload."
          ],
          [
            "argumentsCommaPositions",
            "{ [Position](#position) }",
            "Source positions recorded for arguments comma on this function type CST payload."
          ],
          [
            "closeArgsPosition",
            "[Position](#position)",
            "Source position recorded for close args on this function type CST payload."
          ],
          [
            "returnArrowPosition",
            "[Position](#position)",
            "Source position recorded for return arrow on this function type CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstTypeTypeof",
      "anchor": "csttypetypeof",
      "group": "CST Types",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Parenthesis positions for a `typeof(...)` type.",
      "example": "type PartType = typeof(workspace.Part)\ntype ModelType = typeof(workspace.Model)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstTypeTypeof\"",
            "Tag string used for this typeof type CST payload."
          ],
          [
            "openPosition",
            "[Position](#position)",
            "Source position recorded for open on this typeof type CST payload."
          ],
          [
            "closePosition",
            "[Position](#position)",
            "Source position recorded for close on this typeof type CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstTypeUnion",
      "anchor": "csttypeunion",
      "group": "CST Types",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Separator positions for a union type.",
      "example": "type Status = \"ready\" | \"waiting\" | \"done\"\ntype Id = string | number",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstTypeUnion\"",
            "Tag string used for this union type CST payload."
          ],
          [
            "leadingPosition",
            "[Position](#position)?",
            "Source position recorded for leading on this union type CST payload."
          ],
          [
            "separatorPositions",
            "{ [Position](#position) }",
            "Source positions recorded for separator on this union type CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstTypeIntersection",
      "anchor": "csttypeintersection",
      "group": "CST Types",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Type"
      ],
      "description": "Separator positions for an intersection type.",
      "example": "type Combined = Readable & Writable\ntype Entity = HasId & HasName",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstTypeIntersection\"",
            "Tag string used for this intersection type CST payload."
          ],
          [
            "leadingPosition",
            "[Position](#position)?",
            "Source position recorded for leading on this intersection type CST payload."
          ],
          [
            "separatorPositions",
            "{ [Position](#position) }",
            "Source positions recorded for separator on this intersection type CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstTypePackExplicit",
      "anchor": "csttypepackexplicit",
      "group": "CST Types",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Type"
      ],
      "description": "CST payload for an explicit type pack.",
      "example": "type Callback = (string, number, ...boolean) -> ()\ntype Loader = (number, ...string) -> (...boolean)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstTypePackExplicit\"",
            "Tag string used for this pack explicit type CST payload."
          ],
          [
            "openParenthesesPosition",
            "[Position](#position)?",
            "Source position recorded for open parentheses on this pack explicit type CST payload."
          ],
          [
            "closeParenthesesPosition",
            "[Position](#position)?",
            "Source position recorded for close parentheses on this pack explicit type CST payload."
          ],
          [
            "commaPositions",
            "{ [Position](#position) }?",
            "Source positions recorded for comma on this pack explicit type CST payload."
          ]
        ]
      }
    },
    {
      "name": "CstTypePackGeneric",
      "anchor": "csttypepackgeneric",
      "group": "CST Types",
      "category": "cst",
      "badges": [
        "CST"
      ],
      "tags": [
        "Type"
      ],
      "description": "CST payload for a generic type pack.",
      "example": "type Callback<Args...> = (Args...) -> ()\ntype Wrapper<Values...> = (Values...) -> string",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "kind",
            "\"CstTypePackGeneric\"",
            "Tag string used for this pack generic type CST payload."
          ],
          [
            "ellipsisPosition",
            "[Position](#position)",
            "Source position recorded for ellipsis on this pack generic type CST payload."
          ]
        ]
      }
    },
    {
      "name": "AstNode",
      "anchor": "astnode",
      "group": "Unions",
      "category": "ast",
      "badges": [
        "AST"
      ],
      "tags": [
        "Internal",
        "Union"
      ],
      "description": "Union of AST categories used by the parser for attached metadata and CST links.",
      "example": "local ok, result = Parser.parse(\"return math.max(4, 8)\", { storeCstData = true })\nprint(result.root)",
      "table": {
        "type": "members",
        "headers": [
          "Member",
          "Description"
        ],
        "rows": [
          [
            "[AstExpr](#astexpr)",
            "AST expression record."
          ],
          [
            "[AstStat](#aststat)",
            "AST statement record."
          ],
          [
            "[AstType](#asttype)",
            "AST type record."
          ],
          [
            "[AstTypePack](#asttypepack)",
            "AST type-pack record."
          ],
          [
            "[AstGenericType](#astgenerictype)",
            "Generic type parameter captured from a declaration or function signature."
          ],
          [
            "[AstGenericTypePack](#astgenerictypepack)",
            "Generic type-pack parameter captured from a declaration or function signature."
          ],
          [
            "[AstAttr](#astattr)",
            "Attribute payload attached to declarations and function types."
          ],
          [
            "[AstLocal](#astlocal)",
            "Resolved local binding tracked by the parser, including scope and annotation data."
          ]
        ]
      }
    },
    {
      "name": "ParseError",
      "anchor": "parseerror",
      "group": "Core",
      "category": "core",
      "badges": [
        "CORE"
      ],
      "tags": [
        "API"
      ],
      "description": "Parser error with a final message and its source location.",
      "example": "local ok, result = Parser.parse(\"local =\")\nwarn(result.errors[1].message)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "location",
            "[Location](#location)",
            "Source span covering this parse-error record."
          ],
          [
            "message",
            "string",
            "Human-readable parse message stored by this parse-error record."
          ]
        ]
      }
    },
    {
      "name": "Options",
      "anchor": "options",
      "group": "Core",
      "category": "core",
      "badges": [
        "CORE"
      ],
      "tags": [
        "API"
      ],
      "description": "Options accepted by `Parser.parse` in the current implementation.",
      "example": "local ok, result = Parser.parse(source, {\n    storeCstData = true,\n    captureComments = true,\n})",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "allowDeclarationSyntax",
            "boolean?",
            "Optional flag that keeps the typed declaration-syntax setting on this parser options record."
          ],
          [
            "captureComments",
            "boolean?",
            "Optional flag that tells this parser options record to keep comment locations."
          ],
          [
            "parseFragment",
            "{ localMap: { [string]: [AstLocal](#astlocal)? }, localStack: { [AstLocal](#astlocal)? }, resumePosition: [Position](#position), }?",
            "Resume-state payload used when this parser options record continues parsing from an existing local environment."
          ],
          [
            "storeCstData",
            "boolean?",
            "Optional flag that tells this parser options record to attach CST payloads onto AST records."
          ]
        ]
      }
    },
    {
      "name": "Lexeme",
      "anchor": "lexeme",
      "group": "Core",
      "category": "core",
      "badges": [
        "CORE"
      ],
      "tags": [
        "Internal"
      ],
      "description": "Lexed token with its numeric token kind and source span.",
      "example": "local nameLexeme: Lexeme = { type = 281, location = nameLoc }\nlocal equalLexeme: Lexeme = { type = 257, location = equalLoc }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "type",
            "number",
            "type value stored by this lexeme record."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this lexeme record."
          ]
        ]
      }
    },
    {
      "name": "Comment",
      "anchor": "comment",
      "group": "Core",
      "category": "core",
      "badges": [
        "CORE"
      ],
      "tags": [],
      "description": "Captured comment token and its source span.",
      "example": "local firstComment: Comment = { type = 282, location = lineCommentLoc }\nlocal secondComment: Comment = { type = 283, location = blockCommentLoc }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "type",
            "number",
            "type value stored by this comment record."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this comment record."
          ]
        ]
      }
    },
    {
      "name": "HotComment",
      "anchor": "hotcomment",
      "group": "Core",
      "category": "core",
      "badges": [
        "CORE"
      ],
      "tags": [],
      "description": "Parsed `--!` comment payload stored separately from normal comments.",
      "example": "--!native\n--!optimize 2",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "header",
            "boolean",
            "Whether this hot-comment record came from the header form."
          ],
          [
            "content",
            "string",
            "Comment text stored by this hot-comment record after the marker is removed."
          ],
          [
            "location",
            "[Location](#location)",
            "Source span covering this hot-comment record."
          ]
        ]
      }
    },
    {
      "name": "FunctionState",
      "anchor": "functionstate",
      "group": "Core",
      "category": "core",
      "badges": [
        "CORE"
      ],
      "tags": [
        "Internal"
      ],
      "description": "Small internal parser state record for active function parsing.",
      "example": "local outerState: FunctionState = { vararg = false, loopDepth = 0 }\nlocal innerState: FunctionState = { vararg = true, loopDepth = 1 }",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "vararg",
            "boolean",
            "Whether this function-state record represents a vararg function scope."
          ],
          [
            "loopDepth",
            "number",
            "Loop nesting depth stored by this function-state record."
          ]
        ]
      }
    },
    {
      "name": "Result",
      "anchor": "result",
      "group": "Core",
      "category": "core",
      "badges": [
        "CORE"
      ],
      "tags": [
        "API"
      ],
      "description": "Return payload from `Parser.parse`, including the root block, comments, and errors.",
      "example": "local ok, result = Parser.parse(\"local first = 1\\nlocal second = first + 2\")\nprint(ok, result.root, #result.errors)",
      "table": {
        "type": "fields",
        "headers": [
          "Field",
          "Value",
          "Description"
        ],
        "rows": [
          [
            "root",
            "[AstStatBlock](#aststatblock)?",
            "Top-level block stored by this parse result record when parsing succeeds."
          ],
          [
            "commentLocations",
            "{ [Comment](#comment) }",
            "Captured comment records stored by this parse result record."
          ],
          [
            "hotcomments",
            "{ [HotComment](#hotcomment) }",
            "Captured hot-comment records stored by this parse result record."
          ],
          [
            "errors",
            "{ [ParseError](#parseerror) }",
            "Parse errors collected inside this parse result record."
          ]
        ]
      }
    }
  ]
};
