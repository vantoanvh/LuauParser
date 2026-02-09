--!strict

--------------------------------------------------------------------------------
-- POSITION & LOCATION
--------------------------------------------------------------------------------

-- Represents a position in the source code (0-indexed line and column).
-- Used to pinpoint exact locations for error reporting and CST data.
export type Position = {
	line: number,
	column: number,
}

-- Represents a range in the source code from a beginning position to an ending position.
-- Every AST node has a location that spans the source text it was parsed from.
export type Location = {
	begin: Position,
	end_: Position,
}

--------------------------------------------------------------------------------
-- AST NAME & LOCAL
--------------------------------------------------------------------------------

-- Represents a simple name/identifier in the AST.
-- Used for variable names, function names, type names, etc.
export type AstName = {
	value: string,
}

-- Represents a local variable declaration in the AST.
-- Tracks the variable's name, location, shadowing information, scope depth, and optional type annotation.
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

-- Union type representing all possible expression nodes in the AST.
-- Expressions are constructs that evaluate to a value.
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

-- Union type representing all possible statement nodes in the AST.
-- Statements are constructs that perform actions but don't produce values.
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

-- Union type representing all possible type pack nodes.
-- Type packs represent multiple types, used for function return types and variadic arguments.
export type AstTypePack = AstTypePackExplicit
| AstTypePackVariadic
| AstTypePackGeneric

--------------------------------------------------------------------------------
-- TYPE ANNOTATION UNION TYPES
--------------------------------------------------------------------------------

-- Union type representing all possible type annotation nodes.
-- Type annotations specify the expected types of values in Luau's type system.
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

-- Union type representing all possible Concrete Syntax Tree nodes.
-- CST nodes store positional data for syntactic elements (commas, keywords, etc.)
-- that are not semantically significant but needed for source-accurate transformations.
export type CstNode = CstStatBlock
| CstStatRepeat
| CstStatDo | CstStatDo_DEPRECATED
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

-- Union type representing all possible AST nodes that can be stored in the CST map.
-- This includes statements, expressions, types, locals, and various helper nodes.
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

-- A parenthesized expression: `(expr)`.
-- Used to override operator precedence or for clarity.
export type AstExprGroup = {
	kind: "ExprGroup",
	location: Location,
	expr: AstExpr
}

-- The `nil` literal constant.
-- Represents the absence of a value in Luau.
export type AstExprConstantNil = {
	kind: "ExprConstantNil",
	location: Location
}

-- A boolean literal constant: `true` or `false`.
export type AstExprConstantBool = {
	kind: "ExprConstantBool",
	location: Location,
	value: boolean
}

-- A numeric literal constant (integer or floating-point).
export type AstExprConstantNumber = {
	kind: "ExprConstantNumber",
	location: Location,
	value: number,
	parseResult: "Ok" | "Imprecise" | "HexOverflow" | "BinOverflow" | "Malformed"
}

-- A string literal constant (single-quoted, double-quoted, or long bracket string).
export type AstExprConstantString = {
	kind: "ExprConstantString",
	location: Location,
	value: string,
	quoteStyle: number
}

-- A reference to a local variable.
export type AstExprLocal = {
	kind: "ExprLocal",
	location: Location,
	['local']: AstLocal,
	upvalue: boolean
}

-- A reference to a global variable.
export type AstExprGlobal = {
	kind: "ExprGlobal",
	location: Location,
	name: string
}

-- A reference to the varargs `...` in a vararg function.
-- Only valid inside functions declared with `...` parameter.
export type AstExprVarargs = {
	kind: "ExprVarargs",
	location: Location
}

-- A function call expression: `func(args)` or `obj:method(args)`.
export type AstExprCall = { 
	kind: "ExprCall", 
	location: Location, 
	func: AstExpr, 
	args: {AstExpr}, 
	self: boolean, 
	argLocation: Location,
	typeArguments: {AstTypeOrPack}?
}

-- A named field access expression: `expr.name` or `expr:name`.
export type AstExprIndexName = { 
	kind: "ExprIndexName", 
	location: Location, 
	expr: AstExpr, 
	index: string, 
	indexLocation: Location, 
	opPosition: Position, 
	op: number 
}

-- A bracketed index expression: `expr[index]`.
export type AstExprIndexExpr = { 
	kind: "ExprIndexExpr", 
	location: Location, 
	expr: AstExpr, 
	index: AstExpr 
}

-- A function expression (anonymous function or lambda): `function(...) ... end`.
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

-- A table constructor expression: `{ items }`.
export type AstExprTable = { 
	kind: "ExprTable", 
	location: Location, 
	items: {AstExprTableItem} 
}

-- Represents a single item in a table constructor.
export type AstExprTableItem = {
	kind: "List" | "Record" | "General",
	key: AstExpr?,
	value: AstExpr
}

-- A unary operator expression: `-expr`, `not expr`, or `#expr`.
export type AstExprUnary = { 
	kind: "ExprUnary", 
	location: Location, 
	op: number, 
	expr: AstExpr 
}

-- A binary operator expression: `left op right`.
export type AstExprBinary = { 
	kind: "ExprBinary", 
	location: Location, 
	op: number, 
	left: AstExpr, 
	right: AstExpr 
}

-- A type assertion expression: `expr :: Type`.
-- Used to assert that an expression has a specific type.
export type AstExprTypeAssertion = { 
	kind: "ExprTypeAssertion", 
	location: Location, 
	expr: AstExpr, 
	annotation: AstType 
}

-- An explicit type instantiation expression: `expr<T, U>`.
-- Used to explicitly specify type arguments for a generic function or type.
export type AstExprInstantiate = {
	kind: "ExprInstantiate",
	location: Location,
	expr: AstExpr,
	typeArguments: {AstTypeOrPack}
}

-- An if-else expression: `if condition then trueExpr else falseExpr`.
-- The expression form of conditional logic (not the statement form).
export type AstExprIfElse = { 
	kind: "ExprIfElse", 
	location: Location, 
	condition: AstExpr, 
	hasThen: boolean, 
	trueExpr: AstExpr, 
	hasElse: boolean, 
	falseExpr: AstExpr 
}

-- An interpolated string expression: `` `text {expr} more text` ``.
-- Allows embedding expressions directly within string literals.
export type AstExprInterpString = { 
	kind: "ExprInterpString", 
	location: Location, 
	strings: {string}, 
	expressions: {AstExpr} 
}

-- An error expression node, created when parsing fails.
-- Used to allow partial parsing to continue after errors.
export type AstExprError = { 
	kind: "ExprError", 
	location: Location, 
	expressions: {AstExpr}, 
	messageIndex: number 
}

--------------------------------------------------------------------------------
-- STATEMENT IMPLEMENTATIONS
--------------------------------------------------------------------------------

-- A block of statements, representing a scope boundary.
-- Used for function bodies, control structure bodies, and the top-level chunk.
export type AstStatBlock = { 
	kind: "StatBlock", 
	location: Location, 
	body: {AstStat}, 
	hasEnd: boolean,
	hasSemicolon: boolean?
}

-- An if statement: `if condition then ... elseif ... else ... end`.
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

-- A while loop: `while condition do ... end`.
export type AstStatWhile = { 
	kind: "StatWhile", 
	location: Location, 
	condition: AstExpr, 
	body: AstStatBlock, 
	hasDo: boolean, 
	doLocation: Location,
	hasSemicolon: boolean?
}

-- A repeat-until loop: `repeat ... until condition`.
export type AstStatRepeat = { 
	kind: "StatRepeat", 
	location: Location, 
	condition: AstExpr, 
	body: AstStatBlock, 
	hasUntil: boolean,
	hasSemicolon: boolean?
}

-- A break statement: `break`.
export type AstStatBreak = { kind: "StatBreak", location: Location, hasSemicolon: boolean? }

-- A continue statement: `continue`.
export type AstStatContinue = { kind: "StatContinue", location: Location, hasSemicolon: boolean? }

-- A return statement: `return expr1, expr2, ...`.
-- Returns values from the current function. Must be the last statement in a block.
export type AstStatReturn = { kind: "StatReturn", location: Location, list: {AstExpr}, hasSemicolon: boolean? }

-- An expression statement: evaluates an expression for its side effects.
-- Typically function calls like `print("hello")`.
export type AstStatExpr = { kind: "StatExpr", location: Location, expr: AstExpr, hasSemicolon: boolean? }

-- A local variable declaration: `local a, b = expr1, expr2`.
export type AstStatLocal = { 
	kind: "StatLocal", 
	location: Location, 
	vars: {AstLocal}, 
	values: {AstExpr}, 
	equalsSignLocation: Location?,
	hasSemicolon: boolean?
}

-- A numeric for loop: `for var = from, to, step do ... end`.
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

-- A generic for loop: `for var1, var2 in expr1, expr2 do ... end`.
-- Uses iterators to loop over collections.
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

-- An assignment statement: `var1, var2 = expr1, expr2`.
export type AstStatAssign = { 
	kind: "StatAssign", 
	location: Location, 
	vars: {AstExpr}, 
	values: {AstExpr},
	hasSemicolon: boolean?
}

-- A compound assignment statement: `var += expr`, `var -= expr`, etc.
export type AstStatCompoundAssign = { 
	kind: "StatCompoundAssign", 
	location: Location, 
	op: number, 
	var: AstExpr, 
	value: AstExpr,
	hasSemicolon: boolean?
}

-- A function declaration statement: `function a.b.c:name(...) ... end`.
export type AstStatFunction = { 
	kind: "StatFunction", 
	location: Location, 
	name: AstExpr, 
	func: AstExprFunction,
	hasSemicolon: boolean?
}

-- A local function declaration: `local function name(...) ... end`.
export type AstStatLocalFunction = { 
	kind: "StatLocalFunction", 
	location: Location, 
	name: AstLocal, 
	func: AstExprFunction,
	hasSemicolon: boolean?
}

-- A type alias declaration: `type Name<T> = Type` or `export type Name = Type`.
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

-- A type function declaration (Luau extension): `type function Name(...) ... end`.
-- Defines a compile-time type-level function.
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

-- A global variable declaration (definition file syntax): `declare name: Type`.
-- Not used by the parser anymore, offers no practical real-world uses. Preserved as a placeholder.
export type AstStatDeclareGlobal = { 
	kind: "StatDeclareGlobal", 
	location: Location, 
	name: string, 
	nameLocation: Location, 
	type: AstType,
	hasSemicolon: boolean?
}

-- A function declaration (definition file syntax): `declare function name(...)`.
-- Not used by the parser anymore, offers no practical real-world uses. Preserved as a placeholder.
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

-- An extern type declaration (definition file syntax): `declare extern type Name`.
-- Used to declare external classes/types in definition files.
-- Not used by the parser anymore, offers no practical real-world uses. Preserved as a placeholder.
export type AstStatDeclareExternType = { 
	kind: "StatDeclareExternType", 
	location: Location, 
	name: string, 
	superName: string?, 
	props: {AstDeclaredExternTypeProperty}, 
	indexer: AstTableIndexer?,
	hasSemicolon: boolean?
}

-- An error statement node, created when parsing fails.
-- Used to allow partial parsing to continue after errors.
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

-- A type reference: `TypeName` or `Module.TypeName<Params>`.
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

-- A table type: `{ prop: Type, [Key]: Value }`.
export type AstTypeTable = { 
	kind: "TypeTable", 
	location: Location, 
	props: {AstTableProp}, 
	indexer: AstTableIndexer? 
}

-- A function type: `(Arg1, Arg2) -> (Ret1, Ret2)`.
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

-- A typeof type: `typeof(expr)`.
export type AstTypeTypeof = { 
	kind: "TypeTypeof", 
	location: Location, 
	expr: AstExpr 
}

-- A union type: `Type1 | Type2 | Type3`.
export type AstTypeUnion = { 
	kind: "TypeUnion", 
	location: Location, 
	types: {AstType} 
}

-- An intersection type: `Type1 & Type2 & Type3`.
-- Represents a value that is all of the constituent types simultaneously.
export type AstTypeIntersection = { 
	kind: "TypeIntersection", 
	location: Location, 
	types: {AstType} 
}

-- A boolean singleton type: `true` or `false` as a type.
-- Represents a type that can only be one specific boolean value.
export type AstTypeSingletonBool = { 
	kind: "TypeSingletonBool", 
	location: Location, 
	value: boolean 
}

-- A string singleton type: `"literal"` as a type.
-- Represents a type that can only be one specific string value.
export type AstTypeSingletonString = { 
	kind: "TypeSingletonString", 
	location: Location, 
	value: string 
}

-- A parenthesized type: `(Type)`.
-- Used for grouping in complex type expressions.
export type AstTypeGroup = { 
	kind: "TypeGroup", 
	location: Location, 
	type: AstType 
}

-- An error type node, created when parsing fails.
-- Used to allow partial parsing to continue after errors.
export type AstTypeError = { 
	kind: "TypeError", 
	location: Location, 
	types: {AstType}, 
	isMissing: boolean, 
	messageIndex: number 
}

-- A special optional type marker used internally.
-- Represents the `?` suffix in optional types like `Type?`.
export type AstTypeOptional = {
	kind: "TypeOptional",
	location: Location
}

--------------------------------------------------------------------------------
-- TYPE PACK IMPLEMENTATIONS
--------------------------------------------------------------------------------

-- An explicit type pack: `(Type1, Type2, ...T)`.
-- Represents an explicit list of types, optionally ending with a variadic type.
export type AstTypePackExplicit = { 
	kind: "TypePackExplicit", 
	location: Location, 
	types: {AstType},
	tailType: AstTypePack?
}

-- A variadic type pack: `...Type`.
-- Represents zero or more values of the specified type.
export type AstTypePackVariadic = { 
	kind: "TypePackVariadic", 
	location: Location, 
	variadicType: AstType 
}

-- A generic type pack reference: `T...`.
-- References a generic type pack parameter.
export type AstTypePackGeneric = { 
	kind: "TypePackGeneric", 
	location: Location, 
	genericName: string 
}

--------------------------------------------------------------------------------
-- HELPER STRUCTS
--------------------------------------------------------------------------------

-- A function attribute: `@native`, `@checked`, `@deprecated`, etc.
export type AstAttr = {
	kind: "Attr",
	location: Location,
	type: string,
	args: {AstExpr},
	name: string?
}

-- A generic type parameter in a generic declaration: `<T, U = Default>`.
export type AstGenericType = {
	kind: "GenericType",
	location: Location,
	name: string,
	defaultValue: AstType?
}

-- A generic type pack parameter in a generic declaration: `<T...>`.
export type AstGenericTypePack = {
	kind: "GenericTypePack",
	location: Location,
	name: string,
	defaultValue: AstTypePack?
}

-- A list of types with an optional variadic tail.
-- Used for function parameter and return types.
export type AstTypeList = {
	types: {AstType},
	tailType: AstTypePack?
}

-- A wrapper for either a type or a type pack.
-- Used in generic type arguments where either could be valid.
export type AstTypeOrPack = {
	type: AstType?,
	typePack: AstTypePack?
}

-- A named function argument (for documentation purposes).
export type AstArgumentName = {
	name: string,
	location: Location
}

-- A binding in a local declaration or function parameter.
export type Binding = {
	name: AstName,
	location: Location,
	annotation: AstType?,
	colonPosition: Position?
}

-- A list of bindings (used in local declarations).
export type BindingList = {Binding}

-- A property declaration in an extern type.
export type AstDeclaredExternTypeProperty = {
	name: string,
	nameLocation: Location,
	ty: AstType,
	isMethod: boolean,
	location: Location
}

-- A property in a table type.
export type AstTableProp = {
	kind: "TableProp",
	name: AstName,
	location: Location,
	type: AstType,
	access: string,
	accessLocation: Location?
}

-- An indexer in a table type: `[KeyType]: ValueType`.
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

-- CST data for a block statement.
export type CstStatBlock = {
	kind: "CstStatBlock",
	bodyCommaPositions: {Position}
}

-- CST data for a repeat statement.
export type CstStatRepeat = {
	kind: "CstStatRepeat",
	untilPosition: Position
}

-- CST data for a do statement.
export type CstStatDo = {
	kind: "CstStatDo",
	statsStart: Position,
	endPosition: Position
}

export type CstStatDo_DEPRECATED = {
	kind: "CstStatDo_DEPRECATED",
	endPosition: Position
}

-- CST data for a numeric for loop.
export type CstStatFor = {
	kind: "CstStatFor",
	annotationColonPosition: Position?,
	equalsPosition: Position,
	endCommaPosition: Position,
	stepCommaPosition: Position?
}

-- CST data for a generic for loop.
export type CstStatForIn = {
	kind: "CstStatForIn",
	varsAnnotationColonPositions: {Position?},
	varsCommaPositions: {Position},
	valuesCommaPositions: {Position}
}

-- CST data for a function declaration statement.
export type CstStatFunction = {
	kind: "CstStatFunction",
	functionKeywordPosition: Position
}

-- CST data for a local function declaration.
export type CstStatLocalFunction = {
	kind: "CstStatLocalFunction",
	localKeywordPosition: Position,
	functionKeywordPosition: Position
}

-- CST data for a local variable declaration.
export type CstStatLocal = {
	kind: "CstStatLocal",
	varsAnnotationColonPositions: {Position?},
	varsCommaPositions: {Position},
	valuesCommaPositions: {Position}
}

-- CST data for an assignment statement.
export type CstStatAssign = {
	kind: "CstStatAssign",
	varsCommaPositions: {Position},
	equalsPosition: Position,
	valuesCommaPositions: {Position}
}

-- CST data for a compound assignment statement.
export type CstStatCompoundAssign = {
	kind: "CstStatCompoundAssign",
	opPosition: Position
}

-- CST data for a return statement.
export type CstStatReturn = {
	kind: "CstStatReturn",
	commaPositions: {Position}
}

-- CST data for a type alias declaration.
export type CstStatTypeAlias = {
	kind: "CstStatTypeAlias",
	typeKeywordPosition: Position,
	genericsOpenPosition: Position?,
	genericsCommaPositions: {Position},
	genericsClosePosition: Position?,
	equalsPosition: Position
}

-- CST data for a type function declaration.
export type CstStatTypeFunction = {
	kind: "CstStatTypeFunction",
	typeKeywordPosition: Position,
	functionKeywordPosition: Position
}

-- CST data for a function expression.
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

-- CST data for a table constructor expression.
export type CstExprTable = {
	kind: "CstExprTable",
	items: {CstExprTableItem}
}

-- CST data for a single table item.
export type CstExprTableItem = {
	kind: "Record" | "General" | "List",
	equalsPosition: Position?,
	separator: number?,
	separatorPosition: Position,
	indexerOpenPosition: Position?,
	indexerClosePosition: Position?
}

-- CST data for an if-else expression.
export type CstExprIfElse = {
	kind: "CstExprIfElse",
	thenPosition: Position,
	elsePosition: Position,
	isElseIf: boolean
}

-- CST data for an interpolated string expression.
export type CstExprInterpString = {
	kind: "CstExprInterpString",
	sourceStrings: {string},
	stringPositions: {Position}
}

-- CST data for a string constant expression.
export type CstExprConstantString = {
	kind: "CstExprConstantString",
	sourceString: string?,
	quoteStyle: number,
	blockDepth: number
}

-- CST data for type instantiation syntax: `<T, U>`.
export type CstTypeInstantiation = {
	kind: "CstTypeInstantiation",
	leftArrow1Position: Position,
	leftArrow2Position: Position,

	rightArrow1Position: Position,
	rightArrow2Position: Position,
	commaPositions: {Position}
}

-- CST data for a function call expression.
export type CstExprCall = {
	kind: "CstExprCall",
	openParens: Position?,
	closeParens: Position?,
	commaPositions: {Position},
	explicitTypes: CstTypeInstantiation?
}

-- CST data for a bracketed index expression.
export type CstExprIndexExpr = {
	kind: "CstExprIndexExpr",
	openBracketPosition: Position,
	closeBracketPosition: Position
}

-- CST data for a type assertion expression.
export type CstExprTypeAssertion = {
	kind: "CstExprTypeAssertion",
	opPosition: Position
}

-- CST data for explicit type instantiation expression.
export type CstExprExplicitTypeInstantiation = {
	kind: "CstExprExplicitTypeInstantiation",
	instantiation: CstTypeInstantiation
}

-- CST data for a numeric constant expression.
export type CstExprConstantNumber = {
	kind: "CstExprConstantNumber",
	value: string
}

-- CST data for unary/binary operator expressions.
export type CstExprOp = {
	kind: "CstExprOp",
	opPosition: Position
}

-- CST data for a typeof type.
export type CstTypeTypeof = {
	kind: "CstTypeTypeof",
	openPosition: Position,
	closePosition: Position
}

-- CST data for a type reference.
export type CstTypeReference = {
	kind: "CstTypeReference",
	prefixPointPosition: Position?,
	openParametersPosition: Position?,
	parametersCommaPositions: {Position},
	closeParametersPosition: Position?
}

-- CST data for a generic type pack reference.
export type CstTypePackGeneric = {
	kind: "CstTypePackGeneric",
	ellipsisPosition: Position
}

-- CST data for an explicit type pack.
export type CstTypePackExplicit = {
	kind: "CstTypePackExplicit",
	openParenthesesPosition: Position?,
	closeParenthesesPosition: Position?,
	commaPositions: {Position}?
}

-- CST data for a function type.
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

-- CST data for a union type.
export type CstTypeUnion = {
	kind: "CstTypeUnion",
	leadingPosition: Position?,
	separatorPositions: {Position}
}

-- CST data for an intersection type.
export type CstTypeIntersection = {
	kind: "CstTypeIntersection",
	leadingPosition: Position?,
	separatorPositions: {Position}
}

-- CST data for a table type.
export type CstTypeTable = {
	kind: "CstTypeTable",
	items: {CstTypeTableItem},
	isArray: boolean
}

-- CST data for a table type item.
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

-- CST data for a generic type parameter.
export type CstGenericType = {
	kind: "CstGenericType",
	defaultEqualsPosition: Position?
}

-- CST data for a generic type pack parameter.
export type CstGenericTypePack = {
	kind: "CstGenericTypePack",
	ellipsisPosition: Position,
	defaultEqualsPosition: Position?,
}

-- CST data for a string singleton type.
export type CstTypeSingletonString = {
	kind: "CstTypeSingletonString",
	sourceString: {string},
	quoteStyle: number,
	blockDepth: number
}

--------------------------------------------------------------------------------
-- PARSER RESULT TYPES
--------------------------------------------------------------------------------

-- Represents a parse error with location and message.
export type ParseError = {
	location: Location,
	message: string
}

-- Parser configuration options.
export type Options = {
	captureComments: boolean,
	storeCstData: boolean
}

-- Represents a lexer token with type and location.
export type Lexeme = {type: number, location: Location}

-- Shorthand for an array of attributes.
export type Attrs = {AstAttr}

-- Represents a captured comment.
export type Comment = {
	type: number,
	location: Location
}

-- Represents a hot comment (special directive comment like --!strict).
export type HotComment = {
	header: boolean,
	content: string,
	location: Location
}

-- Internal parser state for tracking function context.
export type FunctionState = {
	vararg: boolean,
	loopDepth: number
}

-- The result of parsing a Luau source file.
export type Result = {
	root: AstStatBlock,
	commentLocations: {Comment},
	hotcomments: {HotComment},
	cstNodeMap: {[AstNode]: CstNode},
	errors: {ParseError}
}

return {}
