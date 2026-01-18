--!strict

export type Position = {
	line: number,
	column: number,
}

export type Location = {
	begin: Position,
	end_: Position,
}

export type AstName = {
	value: string,
}

export type AstLocal = {
	name: string,
	location: Location,
	shadow: AstLocal?,
	functionDepth: number,
	loopDepth: number,
	annotation: AstType?,
}

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

export type AstTypePack = AstTypePackExplicit
| AstTypePackVariadic
| AstTypePackGeneric

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

-- Expression Implementations
export type AstExprGroup = {
	kind: "ExprGroup",
	location: Location,
	expr: AstExpr
}

export type AstExprConstantNil = {
	kind: "ExprConstantNil",
	location: Location
}

export type AstExprConstantBool = {
	kind: "ExprConstantBool",
	location: Location,
	value: boolean
}

export type AstExprConstantNumber = {
	kind: "ExprConstantNumber",
	location: Location,
	value: number,
	parseResult: string
}

export type AstExprConstantString = {
	kind: "ExprConstantString",
	location: Location,
	value: string,
	quoteStyle: number
}

export type AstExprLocal = {
	kind: "ExprLocal",
	location: Location,
	['local']: AstLocal,
	upvalue: boolean
}

export type AstExprGlobal = {
	kind: "ExprGlobal",
	location: Location,
	name: string
}

export type AstExprVarargs = {
	kind: "ExprVarargs",
	location: Location
}

export type AstExprCall = { 
	kind: "ExprCall", 
	location: Location, 
	func: AstExpr, 
	args: {AstExpr}, 
	self: boolean, 
	argLocation: Location,
	typeArguments: {AstTypeOrPack}?
}

export type AstExprIndexName = { 
	kind: "ExprIndexName", 
	location: Location, 
	expr: AstExpr, 
	index: string, 
	indexLocation: Location, 
	opPosition: Position, 
	op: number 
}

export type AstExprIndexExpr = { 
	kind: "ExprIndexExpr", 
	location: Location, 
	expr: AstExpr, 
	index: AstExpr 
}

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

export type AstExprTable = { 
	kind: "ExprTable", 
	location: Location, 
	items: {AstExprTableItem} 
}

export type AstExprTableItem = {
	kind: "List" | "Record" | "General",
	key: AstExpr?,
	value: AstExpr
}

export type AstExprUnary = { 
	kind: "ExprUnary", 
	location: Location, 
	op: number, 
	expr: AstExpr 
}

export type AstExprBinary = { 
	kind: "ExprBinary", 
	location: Location, 
	op: number, 
	left: AstExpr, 
	right: AstExpr 
}

export type AstExprTypeAssertion = { 
	kind: "ExprTypeAssertion", 
	location: Location, 
	expr: AstExpr, 
	annotation: AstType 
}

export type AstExprInstantiate = {
	kind: "ExprInstantiate",
	location: Location,
	expr: AstExpr,
	typeArguments: {AstTypeOrPack}
}

export type AstExprIfElse = { 
	kind: "ExprIfElse", 
	location: Location, 
	condition: AstExpr, 
	hasThen: boolean, 
	trueExpr: AstExpr, 
	hasElse: boolean, 
	falseExpr: AstExpr 
}

export type AstExprInterpString = { 
	kind: "ExprInterpString", 
	location: Location, 
	strings: {string}, 
	expressions: {AstExpr} 
}

export type AstExprError = { 
	kind: "ExprError", 
	location: Location, 
	expressions: {AstExpr}, 
	messageIndex: number 
}

-- Statement Implementations
export type AstStatBlock = { 
	kind: "StatBlock", 
	location: Location, 
	body: {AstStat}, 
	hasEnd: boolean,
	hasSemicolon: boolean?
}

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

export type AstStatWhile = { 
	kind: "StatWhile", 
	location: Location, 
	condition: AstExpr, 
	body: AstStatBlock, 
	hasDo: boolean, 
	doLocation: Location,
	hasSemicolon: boolean?
}

export type AstStatRepeat = { 
	kind: "StatRepeat", 
	location: Location, 
	condition: AstExpr, 
	body: AstStatBlock, 
	hasUntil: boolean,
	hasSemicolon: boolean?
}

export type AstStatBreak = { kind: "StatBreak", location: Location, hasSemicolon: boolean? }
export type AstStatContinue = { kind: "StatContinue", location: Location, hasSemicolon: boolean? }
export type AstStatReturn = { kind: "StatReturn", location: Location, list: {AstExpr}, hasSemicolon: boolean? }
export type AstStatExpr = { kind: "StatExpr", location: Location, expr: AstExpr, hasSemicolon: boolean? }

export type AstStatLocal = { 
	kind: "StatLocal", 
	location: Location, 
	vars: {AstLocal}, 
	values: {AstExpr}, 
	equalsSignLocation: Location?,
	hasSemicolon: boolean?
}

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

export type AstStatAssign = { 
	kind: "StatAssign", 
	location: Location, 
	vars: {AstExpr}, 
	values: {AstExpr},
	hasSemicolon: boolean?
}

export type AstStatCompoundAssign = { 
	kind: "StatCompoundAssign", 
	location: Location, 
	op: number, 
	var: AstExpr, 
	value: AstExpr,
	hasSemicolon: boolean?
}

export type AstStatFunction = { 
	kind: "StatFunction", 
	location: Location, 
	name: AstExpr, 
	func: AstExprFunction,
	hasSemicolon: boolean?
}

export type AstStatLocalFunction = { 
	kind: "StatLocalFunction", 
	location: Location, 
	name: AstLocal, 
	func: AstExprFunction,
	hasSemicolon: boolean?
}

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

export type AstStatDeclareGlobal = { 
	kind: "StatDeclareGlobal", 
	location: Location, 
	name: string, 
	nameLocation: Location, 
	type: AstType,
	hasSemicolon: boolean?
}

-- already removed this becauses it kinda useless for real-world uses
-- this is just a placeholder
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

-- already removed this becauses it kinda useless for real-world uses
-- this is just a placeholder
export type AstStatDeclareExternType = { 
	kind: "StatDeclareExternType", 
	location: Location, 
	name: string, 
	superName: string?, 
	props: {AstDeclaredExternTypeProperty}, 
	indexer: AstTableIndexer?,
	hasSemicolon: boolean?
}

export type AstStatError = { 
	kind: "StatError", 
	location: Location, 
	expressions: {AstExpr}, 
	statements: {AstStat}, 
	messageIndex: number,
	hasSemicolon: boolean?
}

-- Type Annotation Implementations
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

export type AstTypeTable = { 
	kind: "TypeTable", 
	location: Location, 
	props: {AstTableProp}, 
	indexer: AstTableIndexer? 
}

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

export type AstTypeTypeof = { 
	kind: "TypeTypeof", 
	location: Location, 
	expr: AstExpr 
}

export type AstTypeUnion = { 
	kind: "TypeUnion", 
	location: Location, 
	types: {AstType} 
}

export type AstTypeIntersection = { 
	kind: "TypeIntersection", 
	location: Location, 
	types: {AstType} 
}

export type AstTypeSingletonBool = { 
	kind: "TypeSingletonBool", 
	location: Location, 
	value: boolean 
}

export type AstTypeSingletonString = { 
	kind: "TypeSingletonString", 
	location: Location, 
	value: string 
}

export type AstTypeGroup = { 
	kind: "TypeGroup", 
	location: Location, 
	type: AstType 
}

export type AstTypeError = { 
	kind: "TypeError", 
	location: Location, 
	types: {AstType}, 
	isMissing: boolean, 
	messageIndex: number 
}

export type AstTypeOptional = {
	kind: "TypeOptional",
	location: Location
}

export type AstTypePackExplicit = { 
	kind: "TypePackExplicit", 
	location: Location, 
	types: {AstType},
	tailType: AstTypePack?
}

export type AstTypePackVariadic = { 
	kind: "TypePackVariadic", 
	location: Location, 
	variadicType: AstType 
}

export type AstTypePackGeneric = { 
	kind: "TypePackGeneric", 
	location: Location, 
	genericName: string 
}

-- Helper Structs
export type AstAttr = {
	kind: "Attr",
	location: Location,
	type: string, -- Checked, Native, Deprecated
	args: {AstExpr},
	name: string?
}

export type AstGenericType = {
	kind: "GenericType",
	location: Location,
	name: string,
	defaultValue: AstType?
}

export type AstGenericTypePack = {
	kind: "GenericTypePack",
	location: Location,
	name: string,
	defaultValue: AstTypePack?
}

export type AstTypeList = {
	types: {AstType},
	tailType: AstTypePack?
}

export type AstTypeOrPack = {
	type: AstType?,
	typePack: AstTypePack?
}

export type AstArgumentName = {
	name: string,
	location: Location
}

-- Adding missing type used in parseBindingList
export type BindingList = {Binding}

export type AstDeclaredExternTypeProperty = {
	name: string,
	nameLocation: Location,
	ty: AstType,
	isMethod: boolean,
	location: Location
}

export type AstTableProp = {
	kind: "TableProp",
	name: AstName,
	location: Location,
	type: AstType,
	access: string,
	accessLocation: Location?
}

export type AstTableIndexer = {
	kind: "TableIndexer",
	indexType: AstType,
	resultType: AstType,
	location: Location,
	access: string,
	accessLocation: Location?
}

export type Binding = {
	name: AstName,
	location: Location,
	annotation: AstType?,
	colonPosition: Position?
}

-- CST Nodes (Concrete Syntax Tree)

export type CstStatBlock = {
	kind: "CstStatBlock",
	bodyCommaPositions: {Position}
}

export type CstStatRepeat = {
	kind: "CstStatRepeat",
	untilPosition: Position
}

export type CstStatDo = {
	kind: "CstStatDo",
	endPosition: Position
}

export type CstStatFor = {
	kind: "CstStatFor",
	annotationColonPosition: Position?,
	equalsPosition: Position,
	endCommaPosition: Position,
	stepCommaPosition: Position?
}

export type CstStatForIn = {
	kind: "CstStatForIn",
	varsAnnotationColonPositions: {Position?},
	varsCommaPositions: {Position},
	valuesCommaPositions: {Position}
}

export type CstStatFunction = {
	kind: "CstStatFunction",
	functionKeywordPosition: Position
}

export type CstStatLocalFunction = {
	kind: "CstStatLocalFunction",
	localKeywordPosition: Position,
	functionKeywordPosition: Position
}

export type CstStatLocal = {
	kind: "CstStatLocal",
	varsAnnotationColonPositions: {Position?},
	varsCommaPositions: {Position},
	valuesCommaPositions: {Position}
}

export type CstStatAssign = {
	kind: "CstStatAssign",
	varsCommaPositions: {Position},
	equalsPosition: Position,
	valuesCommaPositions: {Position}
}

export type CstStatCompoundAssign = {
	kind: "CstStatCompoundAssign",
	opPosition: Position
}

export type CstStatReturn = {
	kind: "CstStatReturn",
	commaPositions: {Position}
}

export type CstStatTypeAlias = {
	kind: "CstStatTypeAlias",
	typeKeywordPosition: Position,
	genericsOpenPosition: Position?,
	genericsCommaPositions: {Position},
	genericsClosePosition: Position?,
	equalsPosition: Position
}

export type CstStatTypeFunction = {
	kind: "CstStatTypeFunction",
	typeKeywordPosition: Position,
	functionKeywordPosition: Position
}

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

export type CstExprTable = {
	kind: "CstExprTable",
	items: {CstExprTableItem}
}

export type CstExprTableItem = {
	kind: "Record" | "General" | "List",
	equalsPosition: Position?,
	separator: number?,
	separatorPosition: Position,
	indexerOpenPosition: Position?,
	indexerClosePosition: Position?
}

export type CstExprIfElse = {
	kind: "CstExprIfElse",
	thenPosition: Position,
	elsePosition: Position,
	isElseIf: boolean
}

export type CstExprInterpString = {
	kind: "CstExprInterpString",
	sourceStrings: {string},
	stringPositions: {Position}
}

export type CstExprConstantString = {
	kind: "CstExprConstantString",
	sourceString: string?,
	quoteStyle: number,
	blockDepth: number
}

export type CstTypeInstantiation = {
	kind: "CstTypeInstantiation",
	leftArrow1Position: Position,
	leftArrow2Position: Position,

	rightArrow1Position: Position,
	rightArrow2Position: Position,
	commaPositions: {Position}
}

export type CstExprCall = {
	kind: "CstExprCall",
	openParens: Position?,
	closeParens: Position?,
	commaPositions: {Position},
	explicitTypes: CstTypeInstantiation?
}

export type CstExprIndexExpr = {
	kind: "CstExprIndexExpr",
	openBracketPosition: Position,
	closeBracketPosition: Position
}

export type CstExprTypeAssertion = {
	kind: "CstExprTypeAssertion",
	opPosition: Position
}

export type CstExprExplicitTypeInstantiation = {
	kind: "CstExprExplicitTypeInstantiation",
	instantiation: CstTypeInstantiation
}

export type CstExprConstantNumber = {
	kind: "CstExprConstantNumber",
	value: string
}

export type CstExprOp = {
	kind: "CstExprOp",
	opPosition: Position
}

export type CstTypeTypeof = {
	kind: "CstTypeTypeof",
	openPosition: Position,
	closePosition: Position
}

export type CstTypeReference = {
	kind: "CstTypeReference",
	prefixPointPosition: Position?,
	openParametersPosition: Position?,
	parametersCommaPositions: {Position},
	closeParametersPosition: Position?
}

export type CstTypePackGeneric = {
	kind: "CstTypePackGeneric",
	ellipsisPosition: Position
}

export type CstTypePackExplicit = {
	kind: "CstTypePackExplicit",
	openParenthesesPosition: Position?,
	closeParenthesesPosition: Position?,
	commaPositions: {Position}?
}

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

export type CstTypeUnion = {
	kind: "CstTypeUnion",
	leadingPosition: Position?,
	separatorPositions: {Position}
}

export type CstTypeIntersection = {
	kind: "CstTypeIntersection",
	leadingPosition: Position?,
	separatorPositions: {Position}
}

export type CstTypeTable = {
	kind: "CstTypeTable",
	items: {CstTypeTableItem},
	isArray: boolean
}

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

export type CstGenericType = {
	kind: "CstGenericType",
	defaultEqualsPosition: Position?
}

export type CstGenericTypePack = {
	kind: "CstGenericTypePack",
	ellipsisPosition: Position,
	defaultEqualsPosition: Position?,
}

export type CstTypeSingletonString = {
	kind: "CstTypeSingletonString",
	sourceString: {string},
	quoteStyle: number,
	blockDepth: number
}

-- Parser Result
export type ParseError = {
	location: Location,
	message: string
}

export type Options = {
	captureComments: boolean,
	storeCstData: boolean
}

export type Lexeme = {type: number, location: Location}

export type Attrs = {AstAttr}

export type Comment = {
	type: number,
	location: Location
}

export type HotComment = {
	header: boolean,
	content: string,
	location: Location
}

export type FunctionState = {
	vararg: boolean,
	loopDepth: number
}

export type Result = {
	root: AstStatBlock,
	commentLocations: {Comment},
	hotcomments: {HotComment},
	cstNodeMap: {[AstNode]: CstNode},
	errors: {ParseError}
}

return {}
