--!strict

--------------------------------------------------------------------------------
-- POSITION & LOCATION
--------------------------------------------------------------------------------

--- Represents a position in the source code (0-indexed line and column).
--- Used to pinpoint exact locations for error reporting and CST data.
export type Position = {
	line: number,
	column: number,
}

--- Represents a range in the source code from a beginning position to an ending position.
--- Every AST node has a location that spans the source text it was parsed from.
export type Location = {
	begin: Position,
	end_: Position,
}

--------------------------------------------------------------------------------
-- AST NAME & LOCAL
--------------------------------------------------------------------------------

--- Represents a simple name/identifier in the AST.
--- Used for variable names, function names, type names, etc.
export type AstName = {
	value: string,
}

--- Represents a local variable declaration in the AST.
--- Tracks the variable's name, location, shadowing information, scope depth, and optional type annotation.
--- @field name - The name of the local variable
--- @field location - Source location of the variable declaration
--- @field shadow - Reference to a shadowed local variable with the same name (if any)
--- @field functionDepth - The nesting depth of the function containing this local
--- @field loopDepth - The nesting depth of loops containing this local
--- @field annotation - Optional type annotation for the local variable
export type AstLocal = {
	name: string,
	location: Location,
	shadow: AstLocal?,
	functionDepth: number,
	loopDepth: number,
	annotation: AstType?,
}

--------------------------------------------------------------------------------
-- EXPRESSION UNION TYPES
--------------------------------------------------------------------------------

--- Union type representing all possible expression nodes in the AST.
--- Expressions are constructs that evaluate to a value.
export type AstExpr = AstExprGroup
| AstExprConstantNil
| AstExprConstantBool
| AstExprConstantNumber
| AstExprConstantString
| AstExprLocal
| AstExprGlobal
| AstExprVarargs
| AstExprCall
| AstExprIndexName
| AstExprIndexExpr
| AstExprFunction
| AstExprTable
| AstExprUnary
| AstExprBinary
| AstExprTypeAssertion
| AstExprIfElse
| AstExprInterpString
| AstExprInstantiate
| AstExprError

--------------------------------------------------------------------------------
-- STATEMENT UNION TYPES
--------------------------------------------------------------------------------

--- Union type representing all possible statement nodes in the AST.
--- Statements are constructs that perform actions but don't produce values.
export type AstStat = AstStatBlock
| AstStatIf
| AstStatWhile
| AstStatRepeat
| AstStatBreak
| AstStatContinue
| AstStatReturn
| AstStatExpr
| AstStatLocal
| AstStatFor
| AstStatForIn
| AstStatAssign
| AstStatCompoundAssign
| AstStatFunction
| AstStatLocalFunction
| AstStatTypeAlias
| AstStatTypeFunction
| AstStatDeclareGlobal
| AstStatDeclareFunction
| AstStatDeclareExternType
| AstStatError

--------------------------------------------------------------------------------
-- TYPE PACK UNION TYPES
--------------------------------------------------------------------------------

--- Union type representing all possible type pack nodes.
--- Type packs represent multiple types, used for function return types and variadic arguments.
export type AstTypePack = AstTypePackExplicit
| AstTypePackVariadic
| AstTypePackGeneric

--------------------------------------------------------------------------------
-- TYPE ANNOTATION UNION TYPES
--------------------------------------------------------------------------------

--- Union type representing all possible type annotation nodes.
--- Type annotations specify the expected types of values in Luau's type system.
export type AstType = AstTypeReference
| AstTypeTable
| AstTypeFunction
| AstTypeTypeof
| AstTypeUnion
| AstTypeIntersection
| AstTypeSingletonBool
| AstTypeSingletonString
| AstTypeGroup
| AstTypeError
| AstTypeOptional

--------------------------------------------------------------------------------
-- CST NODE UNION TYPES
--------------------------------------------------------------------------------

--- Union type representing all possible Concrete Syntax Tree nodes.
--- CST nodes store positional data for syntactic elements (commas, keywords, etc.)
--- that are not semantically significant but needed for source-accurate transformations.
export type CstNode = CstStatBlock
| CstStatRepeat
| CstStatDo
| CstStatFor
| CstStatForIn
| CstStatFunction
| CstStatLocalFunction
| CstStatLocal
| CstStatAssign
| CstStatCompoundAssign
| CstStatReturn
| CstStatTypeAlias
| CstStatTypeFunction
| CstExprFunction
| CstExprTable
| CstExprIfElse
| CstExprInterpString
| CstExprConstantString
| CstExprConstantNumber
| CstExprOp
| CstTypeTypeof
| CstTypeReference
| CstTypePackGeneric
| CstTypePackExplicit
| CstTypeFunction
| CstTypeUnion
| CstTypeIntersection
| CstTypeTable
| CstGenericType
| CstGenericTypePack
| CstExprCall
| CstExprIndexExpr
| CstExprTypeAssertion
| CstExprExplicitTypeInstantiation
| CstTypeSingletonString
| { kind: string, [any]: any }

--------------------------------------------------------------------------------
-- AST NODE UNION TYPE
--------------------------------------------------------------------------------

--- Union type representing all possible AST nodes that can be stored in the CST map.
--- This includes statements, expressions, types, locals, and various helper nodes.
export type AstNode = AstStat
| AstExpr
| AstType
| AstLocal
| AstArgumentName
| AstGenericType
| AstGenericTypePack
| AstTypePack
| AstTypeOrPack
| AstAttr

--------------------------------------------------------------------------------
-- EXPRESSION IMPLEMENTATIONS
--------------------------------------------------------------------------------

--- A parenthesized expression: `(expr)`.
--- Used to override operator precedence or for clarity.
--- @field expr - The inner expression wrapped in parentheses
export type AstExprGroup = {
	kind: "ExprGroup",
	location: Location,
	expr: AstExpr
}

--- The `nil` literal constant.
--- Represents the absence of a value in Luau.
export type AstExprConstantNil = {
	kind: "ExprConstantNil",
	location: Location
}

--- A boolean literal constant: `true` or `false`.
--- @field value - The boolean value (true or false)
export type AstExprConstantBool = {
	kind: "ExprConstantBool",
	location: Location,
	value: boolean
}

--- A numeric literal constant (integer or floating-point).
--- @field value - The parsed numeric value
--- @field parseResult - The original source text of the number (e.g., "0x1F", "3.14")
export type AstExprConstantNumber = {
	kind: "ExprConstantNumber",
	location: Location,
	value: number,
	parseResult: "Ok" | "Imprecise" | "HexOverflow" | "BinOverflow" | "Malformed"
}

--- A string literal constant (single-quoted, double-quoted, or long bracket string).
--- @field value - The processed string value (with escape sequences resolved)
--- @field quoteStyle - The quote style used (0=single, 1=double, etc.)
export type AstExprConstantString = {
	kind: "ExprConstantString",
	location: Location,
	value: string,
	quoteStyle: number
}

--- A reference to a local variable.
--- @field local - The AstLocal representing the referenced variable
--- @field upvalue - True if this is an upvalue (captured from an outer scope)
export type AstExprLocal = {
	kind: "ExprLocal",
	location: Location,
	['local']: AstLocal,
	upvalue: boolean
}

--- A reference to a global variable.
--- @field name - The name of the global variable
export type AstExprGlobal = {
	kind: "ExprGlobal",
	location: Location,
	name: string
}

--- A reference to the varargs `...` in a vararg function.
--- Only valid inside functions declared with `...` parameter.
export type AstExprVarargs = {
	kind: "ExprVarargs",
	location: Location
}

--- A function call expression: `func(args)` or `obj:method(args)`.
--- @field func - The expression being called (function or callable object)
--- @field args - The list of argument expressions
--- @field self - True if this is a method call using `:` syntax
--- @field argLocation - The location spanning the argument list (including parentheses)
--- @field typeArguments - Optional explicit type arguments for generic functions
export type AstExprCall = { 
	kind: "ExprCall", 
	location: Location, 
	func: AstExpr, 
	args: {AstExpr}, 
	self: boolean, 
	argLocation: Location,
	typeArguments: {AstTypeOrPack}?
}

--- A named field access expression: `expr.name` or `expr:name`.
--- @field expr - The expression being indexed
--- @field index - The name of the field being accessed
--- @field indexLocation - The location of the field name
--- @field opPosition - The position of the `.` or `:` operator
--- @field op - The operator character code (46 for `.`, 58 for `:`)
export type AstExprIndexName = { 
	kind: "ExprIndexName", 
	location: Location, 
	expr: AstExpr, 
	index: string, 
	indexLocation: Location, 
	opPosition: Position, 
	op: number 
}

--- A bracketed index expression: `expr[index]`.
--- @field expr - The expression being indexed
--- @field index - The expression used as the index/key
export type AstExprIndexExpr = { 
	kind: "ExprIndexExpr", 
	location: Location, 
	expr: AstExpr, 
	index: AstExpr 
}

--- A function expression (anonymous function or lambda): `function(...) ... end`.
--- @field attributes - Function attributes like @native, @checked, @deprecated
--- @field generics - Generic type parameters (e.g., `<T, U>`)
--- @field genericPacks - Generic type pack parameters (e.g., `<T...>`)
--- @field self - The implicit `self` parameter for methods (nil for regular functions)
--- @field args - The list of function parameters
--- @field returnAnnotation - Optional return type annotation
--- @field vararg - True if the function accepts varargs `...`
--- @field varargLocation - Location of the `...` token (if vararg)
--- @field varargAnnotation - Optional type annotation for varargs
--- @field body - The function body (block of statements)
--- @field functionDepth - Nesting depth of this function
--- @field debugname - Debug name for the function (inferred from context)
--- @field argLocation - Location of the parameter list
export type AstExprFunction = { 
	kind: "ExprFunction", 
	location: Location,
	attributes: {AstAttr},
	generics: {AstGenericType},
	genericPacks: {AstGenericTypePack},
	self: AstLocal?,
	args: {AstLocal},
	returnAnnotation: AstTypePack?,
	vararg: boolean,
	varargLocation: Location,
	varargAnnotation: AstTypePack?,
	body: AstStatBlock,
	functionDepth: number,
	debugname: string,
	argLocation: Location?
}

--- A table constructor expression: `{ items }`.
--- @field items - The list of table items (key-value pairs or list elements)
export type AstExprTable = { 
	kind: "ExprTable", 
	location: Location, 
	items: {AstExprTableItem} 
}

--- Represents a single item in a table constructor.
--- @field kind - "List" for array-style `value`, "Record" for `key = value`, "General" for `[key] = value`
--- @field key - The key expression (nil for List items)
--- @field value - The value expression
export type AstExprTableItem = {
	kind: "List" | "Record" | "General",
	key: AstExpr?,
	value: AstExpr
}

--- A unary operator expression: `-expr`, `not expr`, or `#expr`.
--- @field op - The unary operator (0=not, 1=minus, 2=length)
--- @field expr - The operand expression
export type AstExprUnary = { 
	kind: "ExprUnary", 
	location: Location, 
	op: number, 
	expr: AstExpr 
}

--- A binary operator expression: `left op right`.
--- Covers arithmetic, comparison, logical, and concatenation operators.
--- @field op - The binary operator code (see BinaryOp enum in parser)
--- @field left - The left operand expression
--- @field right - The right operand expression
export type AstExprBinary = { 
	kind: "ExprBinary", 
	location: Location, 
	op: number, 
	left: AstExpr, 
	right: AstExpr 
}

--- A type assertion expression: `expr :: Type`.
--- Used to assert that an expression has a specific type.
--- @field expr - The expression being asserted
--- @field annotation - The type being asserted
export type AstExprTypeAssertion = { 
	kind: "ExprTypeAssertion", 
	location: Location, 
	expr: AstExpr, 
	annotation: AstType 
}

--- An explicit type instantiation expression: `expr<T, U>`.
--- Used to explicitly specify type arguments for a generic function or type.
--- @field expr - The expression being instantiated
--- @field typeArguments - The type arguments provided
export type AstExprInstantiate = {
	kind: "ExprInstantiate",
	location: Location,
	expr: AstExpr,
	typeArguments: {AstTypeOrPack}
}

--- An if-else expression: `if condition then trueExpr else falseExpr`.
--- The expression form of conditional logic (not the statement form).
--- @field condition - The condition expression
--- @field hasThen - True if the `then` keyword is present
--- @field trueExpr - Expression evaluated when condition is truthy
--- @field hasElse - True if the `else` keyword is present
--- @field falseExpr - Expression evaluated when condition is falsy
export type AstExprIfElse = { 
	kind: "ExprIfElse", 
	location: Location, 
	condition: AstExpr, 
	hasThen: boolean, 
	trueExpr: AstExpr, 
	hasElse: boolean, 
	falseExpr: AstExpr 
}

--- An interpolated string expression: `` `text {expr} more text` ``.
--- Allows embedding expressions directly within string literals.
--- @field strings - The literal string segments between expressions
--- @field expressions - The embedded expressions
export type AstExprInterpString = { 
	kind: "ExprInterpString", 
	location: Location, 
	strings: {string}, 
	expressions: {AstExpr} 
}

--- An error expression node, created when parsing fails.
--- Used to allow partial parsing to continue after errors.
--- @field expressions - Any expressions that were successfully parsed
--- @field messageIndex - Index into the error messages table
export type AstExprError = { 
	kind: "ExprError", 
	location: Location, 
	expressions: {AstExpr}, 
	messageIndex: number 
}

--------------------------------------------------------------------------------
-- STATEMENT IMPLEMENTATIONS
--------------------------------------------------------------------------------

--- A block of statements, representing a scope boundary.
--- Used for function bodies, control structure bodies, and the top-level chunk.
--- @field body - The list of statements in this block
--- @field hasEnd - True if the block is terminated by `end` keyword
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatBlock = { 
	kind: "StatBlock", 
	location: Location, 
	body: {AstStat}, 
	hasEnd: boolean,
	hasSemicolon: boolean?
}

--- An if statement: `if condition then ... elseif ... else ... end`.
--- @field condition - The condition expression
--- @field thenbody - The block executed when condition is truthy
--- @field elsebody - Optional else/elseif branch (can be another AstStatIf or AstStatBlock)
--- @field thenLocation - Location of the `then` keyword
--- @field elseLocation - Location of the `else`/`elseif` keyword (if present)
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatIf = { 
	kind: "StatIf", 
	location: Location, 
	condition: AstExpr, 
	thenbody: AstStatBlock, 
	elsebody: AstStat?, 
	thenLocation: Location?, 
	elseLocation: Location?,
	hasSemicolon: boolean?
}

--- A while loop: `while condition do ... end`.
--- @field condition - The loop condition expression
--- @field body - The loop body block
--- @field hasDo - True if the `do` keyword is present
--- @field doLocation - Location of the `do` keyword
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatWhile = { 
	kind: "StatWhile", 
	location: Location, 
	condition: AstExpr, 
	body: AstStatBlock, 
	hasDo: boolean, 
	doLocation: Location,
	hasSemicolon: boolean?
}

--- A repeat-until loop: `repeat ... until condition`.
--- Executes the body at least once, then continues while condition is falsy.
--- @field condition - The loop termination condition
--- @field body - The loop body block
--- @field hasUntil - True if the `until` keyword is present
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatRepeat = { 
	kind: "StatRepeat", 
	location: Location, 
	condition: AstExpr, 
	body: AstStatBlock, 
	hasUntil: boolean,
	hasSemicolon: boolean?
}

--- A break statement: `break`.
--- Exits the innermost loop immediately.
export type AstStatBreak = { kind: "StatBreak", location: Location, hasSemicolon: boolean? }

--- A continue statement: `continue` (Luau extension).
--- Skips to the next iteration of the innermost loop.
export type AstStatContinue = { kind: "StatContinue", location: Location, hasSemicolon: boolean? }

--- A return statement: `return expr1, expr2, ...`.
--- Returns values from the current function. Must be the last statement in a block.
--- @field list - The list of expressions to return
export type AstStatReturn = { kind: "StatReturn", location: Location, list: {AstExpr}, hasSemicolon: boolean? }

--- An expression statement: evaluates an expression for its side effects.
--- Typically function calls like `print("hello")`.
--- @field expr - The expression to evaluate
export type AstStatExpr = { kind: "StatExpr", location: Location, expr: AstExpr, hasSemicolon: boolean? }

--- A local variable declaration: `local a, b = expr1, expr2`.
--- @field vars - The list of local variables being declared
--- @field values - The list of initializer expressions
--- @field equalsSignLocation - Location of the `=` sign (if values are provided)
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatLocal = { 
	kind: "StatLocal", 
	location: Location, 
	vars: {AstLocal}, 
	values: {AstExpr}, 
	equalsSignLocation: Location?,
	hasSemicolon: boolean?
}

--- A numeric for loop: `for var = from, to, step do ... end`.
--- @field var - The loop variable
--- @field from - The starting value expression
--- @field to - The ending value expression
--- @field step - Optional step value expression (defaults to 1)
--- @field body - The loop body block
--- @field hasDo - True if the `do` keyword is present
--- @field doLocation - Location of the `do` keyword
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatFor = { 
	kind: "StatFor", 
	location: Location, 
	var: AstLocal, 
	from: AstExpr, 
	to: AstExpr, 
	step: AstExpr?, 
	body: AstStatBlock, 
	hasDo: boolean, 
	doLocation: Location,
	hasSemicolon: boolean?
}

--- A generic for loop: `for var1, var2 in expr1, expr2 do ... end`.
--- Uses iterators to loop over collections.
--- @field vars - The loop variables
--- @field values - The iterator expressions
--- @field body - The loop body block
--- @field hasIn - True if the `in` keyword is present
--- @field inLocation - Location of the `in` keyword
--- @field hasDo - True if the `do` keyword is present
--- @field doLocation - Location of the `do` keyword
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatForIn = { 
	kind: "StatForIn", 
	location: Location, 
	vars: {AstLocal}, 
	values: {AstExpr}, 
	body: AstStatBlock, 
	hasIn: boolean, 
	inLocation: Location, 
	hasDo: boolean, 
	doLocation: Location,
	hasSemicolon: boolean?
}

--- An assignment statement: `var1, var2 = expr1, expr2`.
--- @field vars - The list of l-value expressions being assigned to
--- @field values - The list of expressions being assigned
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatAssign = { 
	kind: "StatAssign", 
	location: Location, 
	vars: {AstExpr}, 
	values: {AstExpr},
	hasSemicolon: boolean?
}

--- A compound assignment statement: `var += expr`, `var -= expr`, etc.
--- @field op - The binary operator code (Add, Sub, Mul, etc.)
--- @field var - The l-value expression being modified
--- @field value - The expression to apply with the operator
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatCompoundAssign = { 
	kind: "StatCompoundAssign", 
	location: Location, 
	op: number, 
	var: AstExpr, 
	value: AstExpr,
	hasSemicolon: boolean?
}

--- A function declaration statement: `function a.b.c:name(...) ... end`.
--- @field name - The l-value expression where the function is stored
--- @field func - The function expression
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatFunction = { 
	kind: "StatFunction", 
	location: Location, 
	name: AstExpr, 
	func: AstExprFunction,
	hasSemicolon: boolean?
}

--- A local function declaration: `local function name(...) ... end`.
--- The function is available within its own body (allows recursion).
--- @field name - The local variable holding the function
--- @field func - The function expression
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatLocalFunction = { 
	kind: "StatLocalFunction", 
	location: Location, 
	name: AstLocal, 
	func: AstExprFunction,
	hasSemicolon: boolean?
}

--- A type alias declaration: `type Name<T> = Type` or `export type Name = Type`.
--- @field name - The name of the type alias
--- @field nameLocation - Location of the type name
--- @field generics - Generic type parameters
--- @field genericPacks - Generic type pack parameters
--- @field type - The type being aliased
--- @field exported - True if this is an `export type` declaration
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatTypeAlias = { 
	kind: "StatTypeAlias", 
	location: Location, 
	name: string, 
	nameLocation: Location, 
	generics: {AstGenericType}, 
	genericPacks: {AstGenericTypePack}, 
	type: AstType, 
	exported: boolean,
	hasSemicolon: boolean?
}

--- A type function declaration (Luau extension): `type function Name(...) ... end`.
--- Defines a compile-time type-level function.
--- @field name - The name of the type function
--- @field nameLocation - Location of the type function name
--- @field body - The function body (as an AstExprFunction)
--- @field exported - True if this is an `export type function` declaration
--- @field hasErrors - True if parsing encountered errors
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatTypeFunction = { 
	kind: "StatTypeFunction", 
	location: Location, 
	name: string, 
	nameLocation: Location, 
	body: AstExprFunction, 
	exported: boolean, 
	hasErrors: boolean,
	hasSemicolon: boolean?
}

--- A global variable declaration (definition file syntax): `declare name: Type`.
--- @field name - The name of the global variable
--- @field nameLocation - Location of the variable name
--- @field type - The declared type of the global
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatDeclareGlobal = { 
	kind: "StatDeclareGlobal", 
	location: Location, 
	name: string, 
	nameLocation: Location, 
	type: AstType,
	hasSemicolon: boolean?
}

--- A function declaration (definition file syntax): `declare function name(...)`.
--- Note: Primarily used for type definition files.
--- @field attributes - Function attributes
--- @field name - The function name
--- @field nameLocation - Location of the function name
--- @field generics - Generic type parameters
--- @field genericPacks - Generic type pack parameters
--- @field params - The parameter types
--- @field paramNames - The parameter names (for documentation)
--- @field vararg - True if function accepts varargs
--- @field varargLocation - Location of vararg `...` token
--- @field retTypes - The return type pack
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatDeclareFunction = { 
	kind: "StatDeclareFunction", 
	location: Location, 
	attributes: {AstAttr},
	name: string, 
	nameLocation: Location, 
	generics: {AstGenericType}, 
	genericPacks: {AstGenericTypePack}, 
	params: AstTypeList, 
	paramNames: {AstArgumentName}, 
	vararg: boolean, 
	varargLocation: Location, 
	retTypes: AstTypePack,
	hasSemicolon: boolean?
}

--- An extern type declaration (definition file syntax): `declare extern type Name`.
--- Used to declare external classes/types in definition files.
--- @field name - The name of the extern type
--- @field superName - Optional parent type name (inheritance)
--- @field props - Properties and methods of the extern type
--- @field indexer - Optional indexer signature
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatDeclareExternType = { 
	kind: "StatDeclareExternType", 
	location: Location, 
	name: string, 
	superName: string?, 
	props: {AstDeclaredExternTypeProperty}, 
	indexer: AstTableIndexer?,
	hasSemicolon: boolean?
}

--- An error statement node, created when parsing fails.
--- Used to allow partial parsing to continue after errors.
--- @field expressions - Any expressions that were successfully parsed
--- @field statements - Any statements that were successfully parsed
--- @field messageIndex - Index into the error messages table
--- @field hasSemicolon - True if followed by an optional semicolon
export type AstStatError = { 
	kind: "StatError", 
	location: Location, 
	expressions: {AstExpr}, 
	statements: {AstStat}, 
	messageIndex: number,
	hasSemicolon: boolean?
}

--------------------------------------------------------------------------------
-- TYPE ANNOTATION IMPLEMENTATIONS
--------------------------------------------------------------------------------

--- A type reference: `TypeName` or `Module.TypeName<Params>`.
--- @field hasParameterList - True if type parameters are provided (even if empty)
--- @field prefix - Optional module/namespace prefix
--- @field prefixLocation - Location of the prefix
--- @field name - The type name
--- @field nameLocation - Location of the type name
--- @field parameters - Type arguments passed to generic types
export type AstTypeReference = { 
	kind: "TypeReference", 
	location: Location, 
	hasParameterList: boolean, 
	prefix: string?, 
	prefixLocation: Location?, 
	name: string, 
	nameLocation: Location, 
	parameters: {AstTypeOrPack} 
}

--- A table type: `{ prop: Type, [Key]: Value }`.
--- @field props - The named properties of the table type
--- @field indexer - Optional indexer signature `[KeyType]: ValueType`
export type AstTypeTable = { 
	kind: "TypeTable", 
	location: Location, 
	props: {AstTableProp}, 
	indexer: AstTableIndexer? 
}

--- A function type: `(Arg1, Arg2) -> (Ret1, Ret2)`.
--- @field attributes - Function type attributes
--- @field generics - Generic type parameters
--- @field genericPacks - Generic type pack parameters
--- @field argTypes - The parameter types
--- @field argNames - Optional parameter names (for documentation)
--- @field returnTypes - The return type pack
export type AstTypeFunction = { 
	kind: "TypeFunction", 
	location: Location, 
	attributes: {AstAttr},
	generics: {AstGenericType}, 
	genericPacks: {AstGenericTypePack}, 
	argTypes: AstTypeList, 
	argNames: {AstArgumentName?}, 
	returnTypes: AstTypePack 
}

--- A typeof type: `typeof(expr)`.
--- Infers the type from the given expression at compile time.
--- @field expr - The expression whose type is inferred
export type AstTypeTypeof = { 
	kind: "TypeTypeof", 
	location: Location, 
	expr: AstExpr 
}

--- A union type: `Type1 | Type2 | Type3`.
--- Represents a value that can be any one of the constituent types.
--- @field types - The types in the union
export type AstTypeUnion = { 
	kind: "TypeUnion", 
	location: Location, 
	types: {AstType} 
}

--- An intersection type: `Type1 & Type2 & Type3`.
--- Represents a value that is all of the constituent types simultaneously.
--- @field types - The types in the intersection
export type AstTypeIntersection = { 
	kind: "TypeIntersection", 
	location: Location, 
	types: {AstType} 
}

--- A boolean singleton type: `true` or `false` as a type.
--- Represents a type that can only be one specific boolean value.
--- @field value - The boolean value (true or false)
export type AstTypeSingletonBool = { 
	kind: "TypeSingletonBool", 
	location: Location, 
	value: boolean 
}

--- A string singleton type: `"literal"` as a type.
--- Represents a type that can only be one specific string value.
--- @field value - The string value
export type AstTypeSingletonString = { 
	kind: "TypeSingletonString", 
	location: Location, 
	value: string 
}

--- A parenthesized type: `(Type)`.
--- Used for grouping in complex type expressions.
--- @field type - The inner type
export type AstTypeGroup = { 
	kind: "TypeGroup", 
	location: Location, 
	type: AstType 
}

--- An error type node, created when parsing fails.
--- Used to allow partial parsing to continue after errors.
--- @field types - Any types that were successfully parsed
--- @field isMissing - True if the type was completely missing
--- @field messageIndex - Index into the error messages table
export type AstTypeError = { 
	kind: "TypeError", 
	location: Location, 
	types: {AstType}, 
	isMissing: boolean, 
	messageIndex: number 
}

--- A special optional type marker used internally.
--- Represents the `?` suffix in optional types like `Type?`.
export type AstTypeOptional = {
	kind: "TypeOptional",
	location: Location
}

--------------------------------------------------------------------------------
-- TYPE PACK IMPLEMENTATIONS
--------------------------------------------------------------------------------

--- An explicit type pack: `(Type1, Type2, ...T)`.
--- Represents an explicit list of types, optionally ending with a variadic type.
--- @field types - The list of types in the pack
--- @field tailType - Optional variadic tail type
export type AstTypePackExplicit = { 
	kind: "TypePackExplicit", 
	location: Location, 
	types: {AstType},
	tailType: AstTypePack?
}

--- A variadic type pack: `...Type`.
--- Represents zero or more values of the specified type.
--- @field variadicType - The type of each variadic element
export type AstTypePackVariadic = { 
	kind: "TypePackVariadic", 
	location: Location, 
	variadicType: AstType 
}

--- A generic type pack reference: `T...`.
--- References a generic type pack parameter.
--- @field genericName - The name of the generic type pack
export type AstTypePackGeneric = { 
	kind: "TypePackGeneric", 
	location: Location, 
	genericName: string 
}

--------------------------------------------------------------------------------
-- HELPER STRUCTS
--------------------------------------------------------------------------------

--- A function attribute: `@native`, `@checked`, `@deprecated`, etc.
--- @field type - The attribute type ("Native", "Checked", "Deprecated")
--- @field args - Arguments passed to the attribute (for @deprecated)
--- @field name - The raw attribute name from source
export type AstAttr = {
	kind: "Attr",
	location: Location,
	type: string,
	args: {AstExpr},
	name: string?
}

--- A generic type parameter in a generic declaration: `<T, U = Default>`.
--- @field name - The name of the generic type parameter
--- @field defaultValue - Optional default type value
export type AstGenericType = {
	kind: "GenericType",
	location: Location,
	name: string,
	defaultValue: AstType?
}

--- A generic type pack parameter in a generic declaration: `<T...>`.
--- @field name - The name of the generic type pack parameter
--- @field defaultValue - Optional default type pack value
export type AstGenericTypePack = {
	kind: "GenericTypePack",
	location: Location,
	name: string,
	defaultValue: AstTypePack?
}

--- A list of types with an optional variadic tail.
--- Used for function parameter and return types.
--- @field types - The list of types
--- @field tailType - Optional variadic tail type pack
export type AstTypeList = {
	types: {AstType},
	tailType: AstTypePack?
}

--- A wrapper for either a type or a type pack.
--- Used in generic type arguments where either could be valid.
--- @field type - The type (if this is a type argument)
--- @field typePack - The type pack (if this is a type pack argument)
export type AstTypeOrPack = {
	type: AstType?,
	typePack: AstTypePack?
}

--- A named function argument (for documentation purposes).
--- @field name - The argument name
--- @field location - Location of the argument name
export type AstArgumentName = {
	name: string,
	location: Location
}

--- A binding in a local declaration or function parameter.
--- @field name - The variable name
--- @field location - Location of the binding
--- @field annotation - Optional type annotation
--- @field colonPosition - Position of the `:` before type annotation
export type Binding = {
	name: AstName,
	location: Location,
	annotation: AstType?,
	colonPosition: Position?
}

--- A list of bindings (used in local declarations).
export type BindingList = {Binding}

--- A property declaration in an extern type.
--- @field name - The property name
--- @field nameLocation - Location of the property name
--- @field ty - The property type
--- @field isMethod - True if this is a method (has implicit self)
--- @field location - Location of the entire property declaration
export type AstDeclaredExternTypeProperty = {
	name: string,
	nameLocation: Location,
	ty: AstType,
	isMethod: boolean,
	location: Location
}

--- A property in a table type.
--- @field name - The property name
--- @field location - Location of the property declaration
--- @field type - The property type
--- @field access - Access specifier ("read", "write", or "readwrite")
--- @field accessLocation - Location of the access specifier (if present)
export type AstTableProp = {
	kind: "TableProp",
	name: AstName,
	location: Location,
	type: AstType,
	access: string,
	accessLocation: Location?
}

--- An indexer in a table type: `[KeyType]: ValueType`.
--- @field indexType - The key/index type
--- @field resultType - The value type
--- @field location - Location of the indexer declaration
--- @field access - Access specifier ("read", "write", or "readwrite")
--- @field accessLocation - Location of the access specifier (if present)
export type AstTableIndexer = {
	kind: "TableIndexer",
	indexType: AstType,
	resultType: AstType,
	location: Location,
	access: string,
	accessLocation: Location?
}

--------------------------------------------------------------------------------
-- CST NODES (Concrete Syntax Tree)
-- These nodes store positional information for syntactic elements
-- that are not semantically significant but needed for lossless transforms.
--------------------------------------------------------------------------------

--- CST data for a block statement.
--- @field bodyCommaPositions - Positions of semicolons between statements (if any)
export type CstStatBlock = {
	kind: "CstStatBlock",
	bodyCommaPositions: {Position}
}

--- CST data for a repeat statement.
--- @field untilPosition - Position of the `until` keyword
export type CstStatRepeat = {
	kind: "CstStatRepeat",
	untilPosition: Position
}

--- CST data for a do statement.
--- @field endPosition - Position of the `end` keyword
export type CstStatDo = {
	kind: "CstStatDo",
	endPosition: Position
}

--- CST data for a numeric for loop.
--- @field annotationColonPosition - Position of `:` before loop variable type annotation
--- @field equalsPosition - Position of the `=` sign
--- @field endCommaPosition - Position of comma after `to` expression
--- @field stepCommaPosition - Position of comma before `step` expression (if present)
export type CstStatFor = {
	kind: "CstStatFor",
	annotationColonPosition: Position?,
	equalsPosition: Position,
	endCommaPosition: Position,
	stepCommaPosition: Position?
}

--- CST data for a generic for loop.
--- @field varsAnnotationColonPositions - Positions of `:` before variable type annotations
--- @field varsCommaPositions - Positions of commas between loop variables
--- @field valuesCommaPositions - Positions of commas between iterator expressions
export type CstStatForIn = {
	kind: "CstStatForIn",
	varsAnnotationColonPositions: {Position?},
	varsCommaPositions: {Position},
	valuesCommaPositions: {Position}
}

--- CST data for a function declaration statement.
--- @field functionKeywordPosition - Position of the `function` keyword
export type CstStatFunction = {
	kind: "CstStatFunction",
	functionKeywordPosition: Position
}

--- CST data for a local function declaration.
--- @field localKeywordPosition - Position of the `local` keyword
--- @field functionKeywordPosition - Position of the `function` keyword
export type CstStatLocalFunction = {
	kind: "CstStatLocalFunction",
	localKeywordPosition: Position,
	functionKeywordPosition: Position
}

--- CST data for a local variable declaration.
--- @field varsAnnotationColonPositions - Positions of `:` before variable type annotations
--- @field varsCommaPositions - Positions of commas between variable names
--- @field valuesCommaPositions - Positions of commas between initializer expressions
export type CstStatLocal = {
	kind: "CstStatLocal",
	varsAnnotationColonPositions: {Position?},
	varsCommaPositions: {Position},
	valuesCommaPositions: {Position}
}

--- CST data for an assignment statement.
--- @field varsCommaPositions - Positions of commas between l-values
--- @field equalsPosition - Position of the `=` sign
--- @field valuesCommaPositions - Positions of commas between r-values
export type CstStatAssign = {
	kind: "CstStatAssign",
	varsCommaPositions: {Position},
	equalsPosition: Position,
	valuesCommaPositions: {Position}
}

--- CST data for a compound assignment statement.
--- @field opPosition - Position of the compound operator (+=, -=, etc.)
export type CstStatCompoundAssign = {
	kind: "CstStatCompoundAssign",
	opPosition: Position
}

--- CST data for a return statement.
--- @field commaPositions - Positions of commas between return values
export type CstStatReturn = {
	kind: "CstStatReturn",
	commaPositions: {Position}
}

--- CST data for a type alias declaration.
--- @field typeKeywordPosition - Position of the `type` keyword
--- @field genericsOpenPosition - Position of `<` for generics (if present)
--- @field genericsCommaPositions - Positions of commas between generic parameters
--- @field genericsClosePosition - Position of `>` for generics (if present)
--- @field equalsPosition - Position of the `=` sign
export type CstStatTypeAlias = {
	kind: "CstStatTypeAlias",
	typeKeywordPosition: Position,
	genericsOpenPosition: Position?,
	genericsCommaPositions: {Position},
	genericsClosePosition: Position?,
	equalsPosition: Position
}

--- CST data for a type function declaration.
--- @field typeKeywordPosition - Position of the `type` keyword
--- @field functionKeywordPosition - Position of the `function` keyword
export type CstStatTypeFunction = {
	kind: "CstStatTypeFunction",
	typeKeywordPosition: Position,
	functionKeywordPosition: Position
}

--- CST data for a function expression.
--- @field functionKeywordPosition - Position of the `function` keyword
--- @field openGenericsPosition - Position of `<` for generics (if present)
--- @field genericsCommaPositions - Positions of commas between generic parameters
--- @field closeGenericsPosition - Position of `>` for generics (if present)
--- @field argsAnnotationColonPositions - Positions of `:` before parameter type annotations
--- @field argsCommaPositions - Positions of commas between parameters
--- @field varargAnnotationColonPosition - Position of `:` before vararg type annotation
--- @field returnSpecifierPosition - Position of `:` or `->` before return type
export type CstExprFunction = {
	kind: "CstExprFunction",
	functionKeywordPosition: Position,
	openGenericsPosition: Position?,
	genericsCommaPositions: {Position},
	closeGenericsPosition: Position?,
	argsAnnotationColonPositions: {Position?},
	argsCommaPositions: {Position},
	varargAnnotationColonPosition: Position?,
	returnSpecifierPosition: Position?
}

--- CST data for a table constructor expression.
--- @field items - CST data for each table item
export type CstExprTable = {
	kind: "CstExprTable",
	items: {CstExprTableItem}
}

--- CST data for a single table item.
--- @field kind - The item kind ("Record", "General", or "List")
--- @field equalsPosition - Position of `=` for Record/General items
--- @field separator - The separator character code (`,` or `;`)
--- @field separatorPosition - Position of the separator
--- @field indexerOpenPosition - Position of `[` for General items
--- @field indexerClosePosition - Position of `]` for General items
export type CstExprTableItem = {
	kind: "Record" | "General" | "List",
	equalsPosition: Position?,
	separator: number?,
	separatorPosition: Position,
	indexerOpenPosition: Position?,
	indexerClosePosition: Position?
}

--- CST data for an if-else expression.
--- @field thenPosition - Position of the `then` keyword
--- @field elsePosition - Position of the `else`/`elseif` keyword
--- @field isElseIf - True if this is an `elseif` branch
export type CstExprIfElse = {
	kind: "CstExprIfElse",
	thenPosition: Position,
	elsePosition: Position,
	isElseIf: boolean
}

--- CST data for an interpolated string expression.
--- @field sourceStrings - The raw source strings (before escape processing)
--- @field stringPositions - Positions of each string segment
export type CstExprInterpString = {
	kind: "CstExprInterpString",
	sourceStrings: {string},
	stringPositions: {Position}
}

--- CST data for a string constant expression.
--- @field sourceString - The raw source string (before escape processing)
--- @field quoteStyle - The quote style (0=single, 1=double)
--- @field blockDepth - The bracket depth for long strings (0 for quoted strings)
export type CstExprConstantString = {
	kind: "CstExprConstantString",
	sourceString: string?,
	quoteStyle: number,
	blockDepth: number
}

--- CST data for type instantiation syntax: `<T, U>`.
--- @field leftArrow1Position - Position of first `<` character
--- @field leftArrow2Position - Position of second `<` for `<<` (if applicable)
--- @field rightArrow1Position - Position of first `>` character
--- @field rightArrow2Position - Position of second `>` for `>>` (if applicable)
--- @field commaPositions - Positions of commas between type arguments
export type CstTypeInstantiation = {
	kind: "CstTypeInstantiation",
	leftArrow1Position: Position,
	leftArrow2Position: Position,

	rightArrow1Position: Position,
	rightArrow2Position: Position,
	commaPositions: {Position}
}

--- CST data for a function call expression.
--- @field openParens - Position of `(` (nil for string/table calls)
--- @field closeParens - Position of `)` (nil for string/table calls)
--- @field commaPositions - Positions of commas between arguments
--- @field explicitTypes - CST data for explicit type instantiation (if present)
export type CstExprCall = {
	kind: "CstExprCall",
	openParens: Position?,
	closeParens: Position?,
	commaPositions: {Position},
	explicitTypes: CstTypeInstantiation?
}

--- CST data for a bracketed index expression.
--- @field openBracketPosition - Position of `[`
--- @field closeBracketPosition - Position of `]`
export type CstExprIndexExpr = {
	kind: "CstExprIndexExpr",
	openBracketPosition: Position,
	closeBracketPosition: Position
}

--- CST data for a type assertion expression.
--- @field opPosition - Position of the `::` operator
export type CstExprTypeAssertion = {
	kind: "CstExprTypeAssertion",
	opPosition: Position
}

--- CST data for explicit type instantiation expression.
--- @field instantiation - The type instantiation syntax data
export type CstExprExplicitTypeInstantiation = {
	kind: "CstExprExplicitTypeInstantiation",
	instantiation: CstTypeInstantiation
}

--- CST data for a numeric constant expression.
--- @field value - The raw source text of the number literal
export type CstExprConstantNumber = {
	kind: "CstExprConstantNumber",
	value: string
}

--- CST data for unary/binary operator expressions.
--- @field opPosition - Position of the operator
export type CstExprOp = {
	kind: "CstExprOp",
	opPosition: Position
}

--- CST data for a typeof type.
--- @field openPosition - Position of `(` after typeof
--- @field closePosition - Position of `)` closing typeof
export type CstTypeTypeof = {
	kind: "CstTypeTypeof",
	openPosition: Position,
	closePosition: Position
}

--- CST data for a type reference.
--- @field prefixPointPosition - Position of `.` after prefix (if present)
--- @field openParametersPosition - Position of `<` for type parameters
--- @field parametersCommaPositions - Positions of commas between type parameters
--- @field closeParametersPosition - Position of `>` for type parameters
export type CstTypeReference = {
	kind: "CstTypeReference",
	prefixPointPosition: Position?,
	openParametersPosition: Position?,
	parametersCommaPositions: {Position},
	closeParametersPosition: Position?
}

--- CST data for a generic type pack reference.
--- @field ellipsisPosition - Position of the `...` after the name
export type CstTypePackGeneric = {
	kind: "CstTypePackGeneric",
	ellipsisPosition: Position
}

--- CST data for an explicit type pack.
--- @field openParenthesesPosition - Position of `(`
--- @field closeParenthesesPosition - Position of `)`
--- @field commaPositions - Positions of commas between types
export type CstTypePackExplicit = {
	kind: "CstTypePackExplicit",
	openParenthesesPosition: Position?,
	closeParenthesesPosition: Position?,
	commaPositions: {Position}?
}

--- CST data for a function type.
--- @field openGenericsPosition - Position of `<` for generics
--- @field genericsCommaPositions - Positions of commas between generic parameters
--- @field closeGenericsPosition - Position of `>` for generics
--- @field openArgsPosition - Position of `(` for parameters
--- @field argumentNameColonPositions - Positions of `:` after parameter names
--- @field argumentsCommaPositions - Positions of commas between parameters
--- @field closeArgsPosition - Position of `)` for parameters
--- @field returnArrowPosition - Position of `->` return type separator
export type CstTypeFunction = {
	kind: "CstTypeFunction",
	openGenericsPosition: Position?,
	genericsCommaPositions: {Position},
	closeGenericsPosition: Position?,
	openArgsPosition: Position,
	argumentNameColonPositions: {Position?},
	argumentsCommaPositions: {Position},
	closeArgsPosition: Position,
	returnArrowPosition: Position
}

--- CST data for a union type.
--- @field leadingPosition - Position of leading `|` (if present)
--- @field separatorPositions - Positions of `|` between types
export type CstTypeUnion = {
	kind: "CstTypeUnion",
	leadingPosition: Position?,
	separatorPositions: {Position}
}

--- CST data for an intersection type.
--- @field leadingPosition - Position of leading `&` (if present)
--- @field separatorPositions - Positions of `&` between types
export type CstTypeIntersection = {
	kind: "CstTypeIntersection",
	leadingPosition: Position?,
	separatorPositions: {Position}
}

--- CST data for a table type.
--- @field items - CST data for each table item
--- @field isArray - True if this is an array shorthand type `{T}`
export type CstTypeTable = {
	kind: "CstTypeTable",
	items: {CstTypeTableItem},
	isArray: boolean
}

--- CST data for a table type item.
--- @field kind - "Property", "StringProperty", or "Indexer"
--- @field colonPosition - Position of `:` after property name
--- @field separator - The separator character code
--- @field separatorPosition - Position of the separator
--- @field indexerOpenPosition - Position of `[` for indexers
--- @field indexerClosePosition - Position of `]` for indexers
--- @field stringInfo - String constant info for string properties
--- @field stringPosition - Location of string key
--- @field equalsPosition - Position of `=` for string properties
export type CstTypeTableItem = {
	kind: "Property" | "StringProperty" | "Indexer",
	colonPosition: Position?,
	separator: number?,
	separatorPosition: Position?,
	indexerOpenPosition: Position?,
	indexerClosePosition: Position?,
	stringInfo: CstExprConstantString?,
	stringPosition: Location?,
	equalsPosition: Position?
}

--- CST data for a generic type parameter.
--- @field defaultEqualsPosition - Position of `=` before default value
export type CstGenericType = {
	kind: "CstGenericType",
	defaultEqualsPosition: Position?
}

--- CST data for a generic type pack parameter.
--- @field ellipsisPosition - Position of `...` after name
--- @field defaultEqualsPosition - Position of `=` before default value
export type CstGenericTypePack = {
	kind: "CstGenericTypePack",
	ellipsisPosition: Position,
	defaultEqualsPosition: Position?,
}

--- CST data for a string singleton type.
--- @field sourceString - The raw source strings
--- @field quoteStyle - The quote style used
--- @field blockDepth - The bracket depth for long strings
export type CstTypeSingletonString = {
	kind: "CstTypeSingletonString",
	sourceString: {string},
	quoteStyle: number,
	blockDepth: number
}

--------------------------------------------------------------------------------
-- PARSER RESULT TYPES
--------------------------------------------------------------------------------

--- Represents a parse error with location and message.
--- @field location - Where the error occurred
--- @field message - Human-readable error description
export type ParseError = {
	location: Location,
	message: string
}

--- Parser configuration options.
--- @field captureComments - If true, capture comment locations in the result
--- @field storeCstData - If true, store CST data for source-accurate transforms
export type Options = {
	captureComments: boolean,
	storeCstData: boolean
}

--- Represents a lexer token with type and location.
--- @field type - The token type (see Types enum in parser)
--- @field location - The source location of the token
export type Lexeme = {type: number, location: Location}

--- Shorthand for an array of attributes.
export type Attrs = {AstAttr}

--- Represents a captured comment.
--- @field type - The comment type (single-line or block)
--- @field location - The source location of the comment
export type Comment = {
	type: number,
	location: Location
}

--- Represents a hot comment (special directive comment like --!strict).
--- @field header - True if this is a header comment (at the start of the file)
--- @field content - The content of the hot comment (after --!)
--- @field location - The source location of the hot comment
export type HotComment = {
	header: boolean,
	content: string,
	location: Location
}

--- Internal parser state for tracking function context.
--- @field vararg - True if the current function accepts varargs
--- @field loopDepth - Current nesting depth of loops
export type FunctionState = {
	vararg: boolean,
	loopDepth: number
}

--- The result of parsing a Luau source file.
--- @field root - The root AST node (top-level block)
--- @field commentLocations - List of all captured comments
--- @field hotcomments - List of all hot comments (directives)
--- @field cstNodeMap - Map from AST nodes to their CST data
--- @field errors - List of all parse errors encountered
export type Result = {
	root: AstStatBlock,
	commentLocations: {Comment},
	hotcomments: {HotComment},
	cstNodeMap: {[AstNode]: CstNode},
	errors: {ParseError}
}

return {}
