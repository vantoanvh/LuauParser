--!optimize 2
--!native
--!strict

local Lexer = require'@self/Lexer'

local constructLexeme = Lexer.constructLexeme
local constructLexer = Lexer.constructLexer

local fixupMultilineString = Lexer.fixupMultilineString
local fixupQuotedString = Lexer.fixupQuotedString

local ToString = Lexer.ToString

local Lookahead = Lexer.Lookahead
local ReadNext = Lexer.ReadNext
local Next = Lexer.Next

local QuoteStyle = Lexer.QuoteStyle
local BraceType = Lexer.BraceType
local Types = Lexer.Types

local ExplicitTypeExpressionInstantiation = true

local TypeLengthLimit = 1000
local RecursionLimit = 1000
local ErrorLimit = 100

local nameError = "%error-id%"
local nameNumber = "number"
local nameSelf = "self"
local nameNil = "nil"

type Location = Lexer.Location
type Position = Lexer.Position

type Options = {
	allowDeclarationSyntax: boolean,
	captureComments: boolean,
	storeCstData: boolean,
	noErrorLimit: boolean,

	parseFragment: {[string]: any}
}

type Parser = {
	options: Options,

	lexer: Lexer.Lexer,

	recursionCounter: number,

	endMismatchSuspect: {
		type: number,
		location: Location
	},

	localMap: {any},
	localStack: {any},

	cstNodeMap: {
		[any]: {any}
	},

	functionStack: {any},

	matchRecoveryStopOnToken: {[number]: number},

	skipComments: boolean,
	readNames: boolean,

	hotcomments: {any},
	commentLocations: {any},
	parseErrors: {any},

	hotcommentHeader: boolean,
	typeFunctionDepth: any?,
}

export type TypePack = {
	kind: "TypePackExplicit" | "TypePackVariadic" | "TypePackGeneric",
	location: Location,
	types: {any},
	tailType: TypePack?,
	variadicType: any,
	genericName: string?
}

local function deprecatedArgsValidator(attrLoc: any, args: {any})
	local errors = {}
	if #args == 0 then
		return errors
	end
	if #args > 1 then
		table.insert(errors, {
			location = attrLoc,
			message = "@deprecated can be parametrized only by 1 argument"
		})
		return errors
	end

	local arg = args[1]
	if arg.kind ~= "ExprTable" then
		table.insert(errors, {
			location = arg.location,
			message = "Unknown argument type for @deprecated"
		})
		return errors
	end

	for _, item in arg.items do
		if item.kind == "Record" then
			local keyString = item.key.value
			if keyString ~= "use" and keyString ~= "reason" then
				table.insert(errors, {
					location = item.key.location,
					message = `Unknown argument '{keyString}' for @deprecated. Only string constants for 'use' and 'reason' are allowed`
				})
			elseif (item :: any).value.kind ~= "ExprConstantString" then
				table.insert(errors, {
					location = item.value.location,
					message = `Only constant string allowed as value for '{keyString}'`
				})
			end
		else
			table.insert(errors, {
				location = item.value.location,
				message = "Only constants keys 'use' and 'reason' are allowed for @deprecated attribute"
			})
		end
	end
	return errors
end

local AttributeType = {
	Checked = "Checked",
	Native = "Native",
	Deprecated = "Deprecated",
	Unknown = "Unknown"
}

local kAttributeEntries = {
	checked = {
		type = AttributeType.Checked
	},
	native = {
		type = AttributeType.Native
	},
	deprecated = {
		type = AttributeType.Deprecated,
		argsValidator = deprecatedArgsValidator
	}
}

local function nextLexeme(self: Parser): ()
	local lexeme = Next(self.lexer, false, true)

	while lexeme.type == Types.BrokenComment
		or lexeme.type == Types.Comment
		or lexeme.type == Types.BlockComment do

		if self.options.captureComments then
			table.insert(self.commentLocations, {type = lexeme.type, location = lexeme.location})
		end

		if lexeme.type == Types.BrokenComment then
			return
		end

		if lexeme.type == Types.Comment and lexeme.data and string.sub(lexeme.data, 1, 1) == "!" then
			table.insert(self.hotcomments, {
				header = self.hotcommentHeader,
				location = lexeme.location,
				content = lexeme.data
			})
		end

		lexeme = Next(self.lexer, false, false)
	end
end

local function constructParser(source: string, options: Options)

	local startPos = if options.parseFragment then options.parseFragment.resumePosition else nil

	local self = {
		options = options,

		lexer = constructLexer(source, true, startPos),

		recursionCounter = 0,

		endMismatchSuspect = {
			type = Types.Eof,
			location = {
				begin = { line = 0, column = 0},
				end_ = { line = 0, column = 0}
			}
		},

		localMap = {},
		localStack = {},

		cstNodeMap = {},

		functionStack = { { vararg = true, loopDepth = 0 } },

		matchRecoveryStopOnToken = table.create(Types.Reserved_END, 0),

		skipComments = true,
		readNames = true,

		hotcomments = {},
		commentLocations = {},
		parseErrors = {},

		hotcommentHeader = true,
	} :: Parser

	self.matchRecoveryStopOnToken[Types.Eof] = 1

	nextLexeme(self)

	self.hotcommentHeader = false

	if options.parseFragment then
		self.localMap = table.clone(options.parseFragment.localMap)
		self.localStack = table.clone(options.parseFragment.localStack)
	end

	return self
end

local function tableSeparator(self: Parser): number?
	if self.lexer.lexeme.type == 44 then 
		return 0
	elseif self.lexer.lexeme.type == 59 then 
		return 1
	else
		return nil
	end
end

local function blockFollow(l: any): boolean
	local t = l.type

	return t == Types.Eof
		or t == Types.ReservedElse
		or t == Types.ReservedElseif
		or t == Types.ReservedEnd
		or t == Types.ReservedUntil
end

local function saveLocals(self: Parser)
	return #self.localStack
end

local function restoreLocals(self: Parser, offset: number)
	local localstack = self.localStack
	local localMap = self.localMap

	for i = #localstack, offset + 1, -1 do
		local l = localstack[i]
		localMap[l.name] = l.shadow
	end

	for i = #localstack, offset + 1, -1 do
		localstack[i] = nil
	end
end

local function pushLocal(self: Parser, binding: any)

	local localMap = self.localMap
	local funcStack = self.functionStack

	local name = binding.name.value
	local shadow = localMap[name]

	local local_ = {
		name = name,
		location = binding.name.location,
		shadow = shadow,
		functionDepth = #funcStack - 1,
		loopDepth = funcStack[#funcStack].loopDepth,
		annotation = binding.annotation
	}

	localMap[name] = local_
	table.insert(self.localStack, local_)

	return local_
end

local function getTokenString(type_: number): string

	return ToString(constructLexeme({

		begin = { line = 0, column = 0},
		end_ = { line = 0, column = 0}

	}, type_))

end

local function isStatLast(stat: any): boolean
	return stat.kind == "StatBreak" or stat.kind == "StatContinue" or stat.kind == "StatReturn"
end

local function isLiteralTable(expr: any): boolean
	if expr.kind ~= "ExprTable" then return false end
	return true
end

local function isConstantLiteral(expr: any): boolean
	local k = expr.kind
	return k == "ExprConstantNil" or k == "ExprConstantBool" or 
		k == "ExprConstantNumber" or k == "ExprConstantString"
end

local function Report(
	self: Parser,
	location: Location,
	fmt: string,
	...: any
)

	local errors = self.parseErrors

	if #errors > 0 and errors[#errors].location == location then
		return
	end

	local msg = string.format(fmt :: any, ...)
	table.insert(errors,
		{ location = location, message = msg }
	)

	if ErrorLimit == 1 then
		error(msg, 0)
	end

	if not self.options.noErrorLimit and #self.parseErrors >= ErrorLimit then
		error(`Reached error limit ({ErrorLimit})`, 0)
	end
end

local function expectAndConsumeFail(

	self: Parser,
	type: number,
	context: string?

)

	local lexeme = self.lexer.lexeme

	local typeString = getTokenString(type)
	local lexString = ToString(lexeme)

	if context then
		Report(self, lexeme.location, "Expected %s when parsing %s, got %s", typeString, context, lexString)
	else
		Report(self, lexeme.location, "Expected %s, got %s", typeString, lexString)
	end
end

local function expectMatchAndConsumeFail(

	self: Parser,
	type_: number,
	begin: any,
	extra: string?

)

	local lexeme = self.lexer.lexeme

	local typeString = getTokenString(type_)
	local matchString = getTokenString(begin.type)
	local currString = ToString(lexeme)

	local extraMsg = extra or ""

	if lexeme.location.begin.line == begin.location.begin.line then
		Report(self,
			lexeme.location,
			"Expected %s (to close %s at column %d), got %s%s",
			typeString,
			matchString,
			begin.location.begin.column + 1,
			currString,
			extraMsg
		)
	else
		Report(self,
			lexeme.location,
			"Expected %s (to close %s at line %d), got %s%s",
			typeString,
			matchString,
			begin.location.begin.line + 1,
			currString,
			extraMsg
		)
	end
end

local function expectAndConsume(

	self: Parser,
	type_: number,
	context: string?

): boolean

	if self.lexer.lexeme.type ~= type_ then
		expectAndConsumeFail(self, type_, context)

		if Lookahead(self.lexer).type == type_ then
			nextLexeme(self)
			nextLexeme(self)
		end

		return false
	end

	nextLexeme(self)
	return true
end

local function expectMatchAndConsume(

	self: Parser,
	value: number,
	begin: any,
	searchForMissing: boolean?

): boolean

	if self.lexer.lexeme.type ~= value then
		expectMatchAndConsumeFail(self, value, begin)

		if searchForMissing then
			local currentLine = self.lexer.prevLocation.end_.line
			local type_ = self.lexer.lexeme.type

			while currentLine == self.lexer.lexeme.location.begin.line and type_ ~= value and (self.matchRecoveryStopOnToken[type_] or 0) == 0 do
				nextLexeme(self)
				type_ = self.lexer.lexeme.type
			end

			if type_ == value then
				nextLexeme(self)
				return true
			end
		else
			if Lookahead(self.lexer).type == value then
				nextLexeme(self)
				nextLexeme(self)
				return true
			end
		end

		return false
	end

	nextLexeme(self)
	return true
end

local function expectMatchEndAndConsume(

	self: Parser,
	type_: number,
	begin: any

): boolean

	local lexeme = self.lexer.lexeme
	local suspect = self.endMismatchSuspect

	if lexeme.type ~= type_ then

		if suspect.type ~= Types.Eof and suspect.location.begin.line > begin.location.begin.line then
			local suggestion = string.format(
				"; did you forget to close %s at line %d?",
				getTokenString(suspect.type),
				suspect.location.begin.line + 1
			)

			expectMatchAndConsumeFail(self, type_, begin, suggestion)
		else
			expectMatchAndConsumeFail(self, type_, begin)
		end

		if Lookahead(self.lexer).type == type_ then
			nextLexeme(self)
			nextLexeme(self)
			return true
		end

		return false
	end

	if lexeme.location.begin.line ~= begin.location.begin.line and 
		lexeme.location.begin.column ~= begin.location.begin.column and
		suspect.location.begin.line < begin.location.begin.line then

		self.endMismatchSuspect = begin
	end

	nextLexeme(self)
	return true
end

local function reportStatError(

	self: Parser,
	location: Location,
	exprs: {any},
	stats: {any},
	fmt: string,
	...: any

)

	Report(self, location, fmt, ...)

	return {
		kind = "StatError",
		location = location,
		expressions = exprs,
		statements = stats,
		messageIndex = #self.parseErrors
	}
end

local function reportExprError(

	self: Parser,
	location: Location,
	exprs: {any},
	fmt: string,
	...: any

)
	Report(self, location, fmt, ...)

	return {
		kind = "ExprError",
		location = location,
		expressions = exprs,
		messageIndex = #self.parseErrors
	}
end

local function reportTypeError(

	self: Parser,
	location: Location,
	types: {any},
	fmt: string,
	...: any

)
	Report(self, location, fmt, ...)

	return {
		kind = "TypeError",
		location = location,
		types = types,
		isMissing = false,
		messageIndex = #self.parseErrors
	}
end

local function reportNameError(self: Parser, context: string?)
	local currString = ToString(self.lexer.lexeme)
	if context then
		Report(self,
			self.lexer.lexeme.location,
			"Expected identifier when parsing %s, got %s",
			context,
			currString
		)
	else
		Report(self,
			self.lexer.lexeme.location,
			"Expected identifier, got %s",
			currString
		)
	end
end

-- stat ::=
-- varlist `=' explist |
-- functioncall |
-- do block end |
-- while exp do block end |
-- repeat block until exp |
-- if exp then block {elseif exp then block} [else block] end |
-- for binding `=' exp `,' exp [`,' exp] do block end |
-- for namelist in explist do block end |
-- function funcname funcbody |
-- attributes function funcname funcbody |
-- local function Name funcbody |
-- local attributes function Name funcbody |
-- local namelist [`=' explist]
-- laststat ::= return [explist] | break
function parseStat(self: Parser): any
	local type_ = self.lexer.lexeme.type

	if type_ == Types.ReservedIf then
		return parseIf(self)
	elseif type_ == Types.ReservedWhile then
		return parseWhile(self)
	elseif type_ == Types.ReservedDo then
		return parseDo(self)
	elseif type_ == Types.ReservedFor then
		return parseFor(self)
	elseif type_ == Types.ReservedRepeat then
		return parseRepeat(self)
	elseif type_ == Types.ReservedFunction then
		return parseFunctionStat(self, {})
	elseif type_ == Types.ReservedLocal then
		return parseLocal(self, {})
	elseif type_ == Types.ReservedReturn then
		return parseReturn(self)
	elseif type_ == Types.ReservedBreak then
		return parseBreak(self)
	elseif type_ == Types.Attribute or type_ == Types.AttributeOpen then
		return parseAttributeStat(self)
	end

	local start = self.lexer.lexeme.location
	local expr = parsePrimaryExpr(self, true)

	if expr.kind == "ExprCall" then
		return {
			kind = "StatExpr",
			location = expr.location,
			expr = expr
		}
	end

	if self.lexer.lexeme.type == 44 or self.lexer.lexeme.type == 61 then 
		return parseAssignment(self, expr)
	end

	local operator = parseCompoundOp(self.lexer.lexeme)
	if operator then
		return parseCompoundAssignment(self, expr, operator)
	end

	local ident = nil :: string?
	if expr.kind == "ExprLocal" or expr.kind == "ExprGlobal" then
		ident = expr.name or ((expr :: any).local_ and expr.local_.name)
	end

	if ident == "type" then
		return parseTypeAlias(self, expr.location, false, expr.location.begin)
	end

	if ident == "export" and self.lexer.lexeme.type == Types.Name and self.lexer.lexeme.data == "type" then
		local typeKeywordPos = self.lexer.lexeme.location.begin
		nextLexeme(self)
		return parseTypeAlias(self, expr.location, true, typeKeywordPos)
	end

	if ident == "continue" then
		return parseContinue(self, expr.location)
	end

	if self.options.allowDeclarationSyntax then
		if ident == "declare" then
			return parseDeclaration(self, expr.location, {})
		end
	end

	if start.begin.line == self.lexer.lexeme.location.begin.line and start.begin.column == self.lexer.lexeme.location.begin.column then
		nextLexeme(self)
	end

	return reportStatError(
		self,
		expr.location, {expr}, {},
		"Incomplete statement: expected assignment or a function call"
	)
end

local function parseBlockNoScope(self: Parser)
	local body = {}
	local prevPos = self.lexer.prevLocation.end_

	while not blockFollow(self.lexer.lexeme) do
		local oldRecursion = self.recursionCounter
		self.recursionCounter += 1

		local stat = parseStat(self)

		self.recursionCounter = oldRecursion

		if self.lexer.lexeme.type == 59 then 
			nextLexeme(self)
			stat.hasSemicolon = true
			stat.location.end_ = self.lexer.prevLocation.end_
		end

		table.insert(body, stat)

		if stat.kind == "StatBreak" or stat.kind == "StatContinue" or stat.kind == "StatReturn" then
			break
		end
	end
	
	return {
		kind = "StatBlock",
		location = { begin = prevPos, end_ = self.lexer.lexeme.location.begin },
		body = body,
		hasEnd = false
	}
end

-- chunk ::= {stat [`;']} [laststat [`;']]
-- block ::= chunk
local function parseBlock(self: Parser)
	local localsBegin = saveLocals(self)
	local result = parseBlockNoScope(self)
	restoreLocals(self, localsBegin)
	return result
end

local function parseChunk(self: Parser)
	local result = parseBlock(self)

	if self.lexer.lexeme.type ~= Types.Eof then
		expectAndConsumeFail(self, Types.Eof)
	end

	return result
end

-- if exp then block {elseif exp then block} [else block] end
function parseIf(self: Parser)
	local start = self.lexer.lexeme.location

	nextLexeme(self)

	local cond = parseExpr(self)

	local matchThen = self.lexer.lexeme
	local thenLocation = nil
	if expectAndConsume(self, Types.ReservedThen, "if statement") then
		thenLocation = matchThen.location
	end

	local thenbody = parseBlock(self)

	local elsebody = nil
	local end_ = start
	local elseLocation = nil

	if self.lexer.lexeme.type == Types.ReservedElseif then
		thenbody.hasEnd = true
		local oldRecursionCount = self.recursionCounter
		self.recursionCounter += 1

		elseLocation = self.lexer.lexeme.location
		elsebody = parseIf(self)
		end_ = elsebody.location

		self.recursionCounter = oldRecursionCount
	else
		local matchThenElse = matchThen

		if self.lexer.lexeme.type == Types.ReservedElse then
			thenbody.hasEnd = true
			elseLocation = self.lexer.lexeme.location
			matchThenElse = self.lexer.lexeme
			nextLexeme(self)

			elsebody = parseBlock(self)
			elsebody.location.begin = matchThenElse.location.end_
		end

		end_ = self.lexer.lexeme.location

		local hasEnd = expectMatchEndAndConsume(self, Types.ReservedEnd, matchThenElse)

		if elsebody then
			if elsebody.kind == "StatBlock" then
				elsebody.hasEnd = hasEnd
			end
		else
			thenbody.hasEnd = hasEnd
		end
	end

	return { 
		kind = "StatIf", 
		location = {
			begin = start.begin,
			end_ = end_.end_
		}, 
		condition = cond, 
		thenbody = thenbody, 
		elsebody = elsebody, 
		thenLocation = thenLocation, 
		elseLocation = elseLocation 
	}
end

-- while exp do block end
function parseWhile(self: Parser)
	local start = self.lexer.lexeme.location
	nextLexeme(self) 

	local cond = parseExpr(self)

	local matchDo = self.lexer.lexeme
	local hasDo = expectAndConsume(self, Types.ReservedDo, "while loop")

	self.functionStack[#self.functionStack].loopDepth += 1

	local body = parseBlock(self)

	self.functionStack[#self.functionStack].loopDepth -= 1

	local end_ = self.lexer.lexeme.location
	local hasEnd = expectMatchEndAndConsume(self, Types.ReservedEnd, matchDo)
	body.hasEnd = hasEnd

	return {
		kind = "StatWhile",
		location = {
			begin = start.begin,
			end_ = end_.end_
		},
		condition = cond,
		body = body,
		hasDo = hasDo,
		doLocation = matchDo.location
	}
end

-- repeat block until exp
function parseRepeat(self: Parser)
	local start = self.lexer.lexeme.location
	local matchRepeat = self.lexer.lexeme
	nextLexeme(self) -- repeat

	local localsBegin = saveLocals(self)

	self.functionStack[#self.functionStack].loopDepth += 1

	local body = parseBlockNoScope(self)

	self.functionStack[#self.functionStack].loopDepth -= 1

	local untilPosition = self.lexer.lexeme.location.begin
	local hasUntil = expectMatchEndAndConsume(self, Types.ReservedUntil, matchRepeat)

	local cond = parseExpr(self)

	restoreLocals(self, localsBegin)

	local node = {
		kind = "StatRepeat",
		location = {begin=start.begin, end_=cond.location.end_},
		condition = cond,
		body = body,
		hasUntil = hasUntil
	}

	if self.options.storeCstData then
		self.cstNodeMap[node] = {
			kind = "CstStatRepeat",
			untilPosition = untilPosition
		}
	end

	return node
end

-- do block end
function parseDo(self: Parser)
	local start = self.lexer.lexeme.location
	local matchDo = self.lexer.lexeme
	nextLexeme(self) -- do

	local body = parseBlock(self)
	body.location.begin = start.begin

	local endLocation = self.lexer.lexeme.location
	body.hasEnd = expectMatchEndAndConsume(self, Types.ReservedEnd, matchDo)
	if body.hasEnd then
		body.location.end_ = endLocation.end_
	end

	if self.options.storeCstData then
		self.cstNodeMap[body] = {
			kind = "CstStatDo",
			endPosition = endLocation.begin
		}
	end

	return body
end

-- break
function parseBreak(self: Parser): any
	local start = self.lexer.lexeme.location
	nextLexeme(self) -- break

	if self.functionStack[#self.functionStack].loopDepth == 0 then
		return reportStatError(
			self,
			start,
			{}, {{ kind = "StatBreak", location = start }},
			"break statement must be inside a loop"
		)
	end

	return {
		kind = "StatBreak",
		location = start
	}
end

-- continue
function parseContinue(self: Parser, start: any): any
	if self.functionStack[#self.functionStack].loopDepth == 0 then
		return reportStatError(
			self,
			start,
			{}, {{ kind = "StatContinue", location = start } },
			"continue statement must be inside a loop"
		)
	end
	
	-- note: the token is already parsed for us!

	return {
		kind = "StatContinue",
		location = start
	}
end

-- for binding `=' exp `,' exp [`,' exp] do block end |
-- for bindinglist in explist do block end |
function parseFor(self: Parser): any
	local start = self.lexer.lexeme.location
	nextLexeme(self) -- for

	local varname = parseBinding(self)

	if self.lexer.lexeme.type == 61 then 
		local equalsPosition = self.lexer.lexeme.location.begin
		nextLexeme(self)

		local from = parseExpr(self)

		local endCommaPosition = self.lexer.lexeme.location.begin
		expectAndConsume(self, 44, "index range") 

		local to = parseExpr(self)

		local stepCommaPosition = nil
		local step = nil

		if self.lexer.lexeme.type == 44 then 
			stepCommaPosition = self.lexer.lexeme.location.begin
			nextLexeme(self)
			step = parseExpr(self)
		end

		local matchDo = self.lexer.lexeme
		local hasDo = expectAndConsume(self, Types.ReservedDo, "for loop")

		local localsBegin = saveLocals(self)
		self.functionStack[#self.functionStack].loopDepth += 1

		local var = pushLocal(self, varname)

		local body = parseBlock(self)

		self.functionStack[#self.functionStack].loopDepth -= 1
		restoreLocals(self, localsBegin)

		local end_ = self.lexer.lexeme.location
		local hasEnd = expectMatchEndAndConsume(self, Types.ReservedEnd, matchDo)
		body.hasEnd = hasEnd

		local node = {
			kind = "StatFor",
			location = {begin=start.begin, end_=end_.end_},
			var = var,
			from = from,
			to = to,
			step = step,
			body = body,
			hasDo = hasDo,
			doLocation = matchDo.location
		}

		if self.options.storeCstData then
			self.cstNodeMap[node] = {
				kind = "CstStatFor",
				annotationColonPosition = varname.colonPosition,
				equalsPosition = equalsPosition,
				endCommaPosition = endCommaPosition,
				stepCommaPosition = stepCommaPosition
			}
		end

		return node
	else

		local names = { varname }
		local varsCommaPosition = {} 

		if self.lexer.lexeme.type == 44 then 
			local initialCommaPos = self.lexer.lexeme.location.begin
			nextLexeme(self)
			parseBindingList(self, names, false, varsCommaPosition, initialCommaPos)
		end

		local inLocation = self.lexer.lexeme.location
		local hasIn = expectAndConsume(self, Types.ReservedIn, "for loop")

		local values = {}
		local valuesCommaPositions = {}
		parseExprList(self, values, self.options.storeCstData and valuesCommaPositions or nil)

		local matchDo = self.lexer.lexeme
		local hasDo = expectAndConsume(self, Types.ReservedDo, "for loop")

		local localsBegin = saveLocals(self)
		self.functionStack[#self.functionStack].loopDepth += 1

		local vars = {}
		for _, binding in names do
			table.insert(vars, pushLocal(self, binding))
		end

		local body = parseBlock(self)

		self.functionStack[#self.functionStack].loopDepth -= 1
		restoreLocals(self, localsBegin)

		local end_ = self.lexer.lexeme.location
		local hasEnd = expectMatchEndAndConsume(self, Types.ReservedEnd, matchDo)
		body.hasEnd = hasEnd

		local node = {
			kind = "StatForIn",
			location = {begin=start.begin, end_=end_.end_},
			vars = vars,
			values = values,
			body = body,
			hasIn = hasIn,
			inLocation = inLocation,
			hasDo = hasDo,
			doLocation = matchDo.location
		}

		if self.options.storeCstData then
			self.cstNodeMap[node] = {
				kind = "CstStatForIn",
				varsAnnotationColonPositions = extractAnnotationColonPositions(self, names),
				varsCommaPositions = varsCommaPosition,
				valuesCommaPositions = valuesCommaPositions
			}
		end

		return node
	end
end

-- funcname ::= Name {`.' Name} [`:' Name]
function parseFunctionName(self: Parser, hasselfRef: {boolean}, debugnameRef: {string?}): any
	if self.lexer.lexeme.type == Types.Name then
		debugnameRef[1] = self.lexer.lexeme.data
	end

	-- parse funcname into a chain of indexing operators
	local expr = parseNameExpr(self, "function name")

	local oldRecursionCount = self.recursionCounter

	while self.lexer.lexeme.type == 46 do 
		local opPosition = self.lexer.lexeme.location.begin
		nextLexeme(self)

		local name = parseName(self, "field name")
		
		-- while we could concatenate the name chain, for now let's just write the short name
		debugnameRef[1] = name.name.value

		expr = {
			kind = "ExprIndexName",
			location = {
				begin = expr.location.begin,
				end_ = name.location.end_
			},
			expr = expr,
			index = name.name.value,
			indexLocation = name.location,
			opPosition = opPosition,
			op = 46
		}

		-- note: while the parser isn't recursive here, we're generating recursive structures of unbounded depth
		incrementRecursionCounter(self, "function name")
	end

	self.recursionCounter = oldRecursionCount

	-- finish with :
	if self.lexer.lexeme.type == 58 then 
		local opPosition = self.lexer.lexeme.location.begin
		nextLexeme(self)

		local name = parseName(self, "method name")
		
		-- while we could concatenate the name chain, for now let's just write the short name
		debugnameRef[1] = name.name.value
		
		expr = {
			kind = "ExprIndexName",
			location = {
				begin = expr.location.begin,
				end_ = name.location.end_
			},
			expr = expr,
			index = name.name.value,
			indexLocation = name.location,
			opPosition = opPosition,
			op = 58
		}

		hasselfRef[1] = true
	end

	return expr
end

-- function funcname funcbody
function parseFunctionStat(self: Parser, attributes: {any})
	local start = self.lexer.lexeme.location
	if #attributes > 0 then
		start = attributes[1].location
	end

	local matchFunction = self.lexer.lexeme
	nextLexeme(self)

	local hasselfRef = { false }
	local debugnameRef = {}
	local expr = parseFunctionName(self, hasselfRef, debugnameRef)

	self.matchRecoveryStopOnToken[Types.ReservedEnd] = (self.matchRecoveryStopOnToken[Types.ReservedEnd] or 0) + 1

	local bodyData = parseFunctionBody(self, hasselfRef[1], matchFunction, debugnameRef[1], nil, attributes)
	local body = bodyData[1] :: any

	self.matchRecoveryStopOnToken[Types.ReservedEnd] = (self.matchRecoveryStopOnToken[Types.ReservedEnd] or 0) - 1

	local node = {
		kind = "StatFunction",
		location = {
			begin = start.begin,
			end_ = body.location.end_
		},
		name = expr,
		func = body
	}

	if self.options.storeCstData then
		self.cstNodeMap[node] = {
			kind = "CstStatFunction",
			functionKeywordPosition = matchFunction.location.begin
		}
	end

	return node
end

function validateAttribute(

	self: Parser,
	loc: any,
	attributeName: string,
	attributes: {any},
	args: {any}

)
	-- check if the attribute name is valid
	local entry = kAttributeEntries[attributeName]
	local type_ = nil
	local argsValidator = nil

	if entry then
		type_ = entry.type
		argsValidator = entry.argsValidator
	else
		if #attributeName == 0 then
			Report(self, loc, "Attribute name is missing")
		else
			Report(self, loc, "Invalid attribute '@%s'", attributeName)
		end
	end

	if type_ then
		-- check that attribute is not duplicated
		for _, attr in attributes do
			if attr.type == type_ then
				Report(self, loc, "Cannot duplicate attribute '@%s'", attributeName)
			end
		end

		if argsValidator then
			local errors = argsValidator(loc, args)
			for _, err in errors do
				Report(self, err.location, "%s", err.message)
			end
		end
	end

	return type_
end

-- attribute ::= '@' NAME
function parseAttribute(self: Parser, attributes: {any})
	local current = self.lexer.lexeme

	if current.type == Types.Attribute then
		local loc = current.location
		local name = current.data or ""
		local type_ = validateAttribute(self, loc, name, attributes, {})
		nextLexeme(self)
		table.insert(attributes, {
			kind = "Attr",
			location = loc,
			type = type_,
			args = {},
			name = name
		})
	else
		local open = current
		nextLexeme(self)
		if self.lexer.lexeme.type ~= 93 then 
			while true do
				local name = parseName(self, "attribute name")
				local nameLoc = name.location
				local attrName = name.name.value
				local args = {}
				local argsLocation = self.lexer.lexeme.location 

				if self.lexer.lexeme.type == Types.RawString
					or self.lexer.lexeme.type == Types.QuotedString or 
					self.lexer.lexeme.type == 123 or self.lexer.lexeme.type == 40 then 
					local callData = parseCallList(self)
					args = callData[1]
					argsLocation = callData[2] 
					for _, arg in args do
						if not isConstantLiteral(arg) and not isLiteralTable(arg) then
							Report(self, argsLocation, "Only literals can be passed as arguments for attributes")
						end
					end
				end

				validateAttribute(self, nameLoc, attrName, attributes, args)

				table.insert(attributes, {
					kind = "Attr",
					location = nameLoc,
					type = "Unknown",
					args = args,
					name = attrName
				})

				if self.lexer.lexeme.type == 44 then 
					nextLexeme(self)
				else
					break
				end
			end
		else
			Report(self, {
				begin = open.location.begin,
				end_ = self.lexer.lexeme.location.end_
			}, "Attribute list cannot be empty")
		end
		expectMatchAndConsume(self, 93, open) 
	end
end

-- attributes ::= {attribute}
function parseAttributes(self: Parser)
	local attributes = {}

	while self.lexer.lexeme.type == Types.Attribute
		or self.lexer.lexeme.type == Types.AttributeOpen do
		parseAttribute(self, attributes)
	end

	return attributes
end

-- attributes local function Name funcbody
-- attributes function funcname funcbody
-- attributes `declare function' Name`(' [parlist] `)' [`:` Type]
-- declare Name '{' Name ':' attributes `(' [parlist] `)' [`:` Type] '}'
function parseAttributeStat(self): any
	local attributes = parseAttributes(self)
	local type_ = self.lexer.lexeme.type

	if type_ == Types.ReservedFunction then
		return parseFunctionStat(self, attributes)
	elseif type_ == Types.ReservedLocal then
		return parseLocal(self, attributes)
	elseif type_ == Types.Name then
		if self.options.allowDeclarationSyntax and self.lexer.lexeme.data == "declare" then
			local expr = parsePrimaryExpr(self, true)
			return parseDeclaration(self, expr.location, attributes)
		end
	end

	return reportStatError(
		self,
		self.lexer.lexeme.location, {}, {},
		"Expected 'function', 'local function', 'declare function' or a function type declaration after attribute, but got %s instead",
		ToString(self.lexer.lexeme)
	)
end

-- local function Name funcbody |
-- local bindinglist [`=' explist]
function parseLocal(self: Parser, attributes: {any}): any
	local start = self.lexer.lexeme.location
	if #attributes > 0 then
		start = attributes[1].location
	end

	local localKeywordPosition = self.lexer.lexeme.location.begin
	nextLexeme(self) -- local

	if self.lexer.lexeme.type == Types.ReservedFunction then
		local matchFunction = self.lexer.lexeme
		nextLexeme(self)

		local functionKeywordPosition = matchFunction.location.begin
		-- matchFunction is only used for diagnostics; to make it suitable for detecting missed indentation between
		-- `local function` and `end`, we patch the token to begin at the column where `local` starts
		if matchFunction.location.begin.line == start.begin.line then
			matchFunction.location.begin.column = start.begin.column
		end

		local name = parseName(self, "variable name")

		self.matchRecoveryStopOnToken[Types.ReservedEnd] = (self.matchRecoveryStopOnToken[Types.ReservedEnd] or 0) + 1

		local bodyData = parseFunctionBody(self, false, matchFunction, name.name.value, name, attributes)
		local body = bodyData[1] :: any
		local var = bodyData[2]

		self.matchRecoveryStopOnToken[Types.ReservedEnd] = (self.matchRecoveryStopOnToken[Types.ReservedEnd] or 0) - 1

		local node = {
			kind = "StatLocalFunction",
			location = {begin=start.begin, end_=body.location.end_},
			name = var,
			func = body
		}

		if self.options.storeCstData then
			self.cstNodeMap[node] = {
				kind = "CstStatLocalFunction",
				localKeywordPosition = localKeywordPosition,
				functionKeywordPosition = functionKeywordPosition
			}
		end

		return node
	else
		if #attributes ~= 0 then
			return reportStatError(self,
				self.lexer.lexeme.location,
				{}, {},
				"Expected 'function' after local declaration with attribute, but got %s instead",
				ToString(self.lexer.lexeme)
			)
		end

		self.matchRecoveryStopOnToken[61] = (self.matchRecoveryStopOnToken[61] or 0) + 1

		local names = {}
		local varsCommaPositions = {}
		if self.options.storeCstData then
			parseBindingList(self, names, false, varsCommaPositions)
		else
			parseBindingList(self, names, false)
		end

		self.matchRecoveryStopOnToken[61] = (self.matchRecoveryStopOnToken[61] or 0) - 1

		local vars = {}
		local values = {}
		local valuesCommaPositions = {}
		local equalsSignLocation = nil

		if self.lexer.lexeme.type == 61 then 
			equalsSignLocation = self.lexer.lexeme.location
			nextLexeme(self)
			parseExprList(self, values, self.options.storeCstData and valuesCommaPositions or nil)
		end

		for _, binding in names do
			table.insert(vars, pushLocal(self, binding))
		end

		local end_ = start
		if #values > 0 then
			end_ = values[#values].location
		else
			end_ = self.lexer.prevLocation
		end

		local node = {
			kind = "StatLocal",
			location = {begin=start.begin, end_=end_.end_},
			vars = vars,
			values = values,
			equalsSignLocation = equalsSignLocation
		}

		if self.options.storeCstData then
			self.cstNodeMap[node] = {
				kind = "CstStatLocal",
				varsAnnotationColonPositions = extractAnnotationColonPositions(self, names),
				varsCommaPositions = varsCommaPositions,
				valuesCommaPositions = valuesCommaPositions
			}
		end

		return node
	end
end

-- return [explist]
function parseReturn(self: Parser)
	local start = self.lexer.lexeme.location
	nextLexeme(self)

	local list = {}
	local commaPositions = {}

	if not blockFollow(self.lexer.lexeme) and self.lexer.lexeme.type ~= 59 then
		parseExprList(self, list, self.options.storeCstData and commaPositions or nil)
	end

	local end_ = start
	if #list > 0 then
		end_ = list[#list].location
	end

	local node = {
		kind = "StatReturn",
		location = {
			begin = start.begin,
			end_ = end_.end_
		},
		list = list
	}

	if self.options.storeCstData then
		self.cstNodeMap[node] = {
			kind = "CstStatReturn",
			commaPositions = commaPositions
		}
	end

	return node
end

-- type Name [`<' varlist `>'] `=' Type
function parseTypeAlias(

	self: Parser,
	start: any,
	exported: boolean,
	typeKeywordPosition: any

): any

	-- parsing a type function
	if self.lexer.lexeme.type == Types.ReservedFunction then
		return parseTypeFunction(self, start, exported, typeKeywordPosition)
	end

	-- parsing a type alias

	-- note: `type` token is already parsed for us, so we just need to parse the rest

	local nameOpt = parseNameOpt(self, "type name")
	local name = nameOpt

	-- Use error name if the name is missing
	if not name then
		name = {
			name = { value = nameError },
			location = self.lexer.lexeme.location
		}
	end

	local genericsCommaPos = {}

	local genericsClosePos = {
		{line = 0, column = 0}
	}

	local genericsOpenPos = {
		{line = 0, column = 0}
	}

	local genericsData = nil

	if self.options.storeCstData then
		genericsData = parseGenericTypeList(self, true, genericsOpenPos, genericsCommaPos, genericsClosePos)
	else
		genericsData = parseGenericTypeList(self, true)
	end

	local generics, genericPacks = genericsData[1], genericsData[2]

	local equalsPosition = self.lexer.lexeme.location.begin
	expectAndConsume(self, 61, "type alias") 

	local type_ = parseType(self)

	local node = {
		kind = "StatTypeAlias",
		location = { begin = start.begin, end_ = type_.location.end_ },
		name = name.name.value,
		nameLocation = name.location,
		generics = generics,
		genericPacks = genericPacks,
		type = type_,
		exported = exported
	}

	if self.options.storeCstData then
		self.cstNodeMap[node] = {
			kind = "CstStatTypeAlias",
			typeKeywordPosition = typeKeywordPosition,
			genericsOpenPosition = genericsOpenPos[1],
			genericsCommaPositions = genericsCommaPos,
			genericsClosePosition = genericsClosePos[1],
			equalsPosition = equalsPosition
		}
	end

	return node
end

-- type function Name `(' arglist `)' `=' funcbody `end'
function parseTypeFunction(

	self: Parser,
	start: any,
	exported: boolean,
	typeKeywordPosition: any

)

	local matchFn = self.lexer.lexeme
	nextLexeme(self)

	local errorsAtStart = #self.parseErrors

	-- parse the name of the type function

	local fnNameOpt = parseNameOpt(self, "type function name")
	local fnName = fnNameOpt
	if not fnName then
		fnName = {
			name = { value = nameError },
			location = self.lexer.lexeme.location
		}
	end

	self.matchRecoveryStopOnToken[Types.ReservedEnd] = (self.matchRecoveryStopOnToken[Types.ReservedEnd] or 0) + 1

	local oldTypeFunctionDepth = self.typeFunctionDepth or 0
	self.typeFunctionDepth = #self.functionStack

	local bodyData = parseFunctionBody(self, false, matchFn, fnName.name.value, nil, {})
	local body = bodyData[1] :: any

	self.typeFunctionDepth = oldTypeFunctionDepth
	self.matchRecoveryStopOnToken[Types.ReservedEnd] = (self.matchRecoveryStopOnToken[Types.ReservedEnd] or 0) - 1

	local hasErrors = #self.parseErrors > errorsAtStart

	local node = {
		kind = "StatTypeFunction",
		location = {
			begin = start.begin,
			end_ = body.location.end_
		},
		name = fnName.name.value,
		nameLocation = fnName.location,
		body = body,
		exported = exported,
		hasErrors = hasErrors
	}

	if self.options.storeCstData then
		self.cstNodeMap[node] = {
			kind = "CstStatTypeFunction",
			typeKeywordPosition = typeKeywordPosition,
			functionKeywordPosition = matchFn.location.begin
		}
	end

	return node
end

-- Use placeholder if the name is missing
function parseBinding(self: Parser)
	local nameOpt = parseNameOpt(self, "variable name")
	local name = nameOpt

	if not name then
		name = {
			name = {value = nameError },
			location = self.lexer.lexeme.location
		}
	end

	local colonPos = self.lexer.lexeme.location.begin
	local annotation = parseOptionalType(self)

	return {
		name = name.name,
		location = name.location,
		annotation = annotation,
		colonPosition = colonPos
	}
end

-- bindinglist ::= (binding | `...') [`,' bindinglist]
function parseBindingList(

	self: Parser,
	result: {any},
	allowDot3: boolean,
	commaPositions: {any}?,
	initialComma: any?,
	varargAnnotColonPos: any?

): any

	local localCommaPositions = {}

	if commaPositions and initialComma then
		table.insert(localCommaPositions, initialComma)
	end

	while true do
		if self.lexer.lexeme.type == Types.Dot3 and allowDot3 then
			local varargLocation = self.lexer.lexeme.location
			nextLexeme(self)

			local tailAnnotation = nil
			if self.lexer.lexeme.type == 58 then 
				if varargAnnotColonPos then
					varargAnnotColonPos[1] = self.lexer.lexeme.location.begin
				end

				nextLexeme(self)
				tailAnnotation = parseVariadicArgumentTypePack(self)
			end

			if commaPositions then
				for _, v in localCommaPositions do
					table.insert(commaPositions, v)
				end
			end

			return true, varargLocation, tailAnnotation
		end

		table.insert(result, parseBinding(self))

		if self.lexer.lexeme.type ~= 44 then 
			break
		end

		if commaPositions then
			table.insert(localCommaPositions, self.lexer.lexeme.location.begin)
		end
		nextLexeme(self)
	end

	if commaPositions then
		for _, v in localCommaPositions do
			table.insert(commaPositions, v)
		end
	end

	return false, nil, nil
end

function parseNameOpt(self: Parser, context: string?): any
	if self.lexer.lexeme.type ~= Types.Name then
		reportNameError(self, context)
		return nil
	end

	local result = {
		name = { value = self.lexer.lexeme.data },
		location = self.lexer.lexeme.location
	}

	nextLexeme(self)
	return result
end

function parseName(self: Parser, context: string?): any
	local name = parseNameOpt(self, context)
	if name then
		return name
	end

	local loc = self.lexer.lexeme.location
	return {
		name = { value = nameError },
		location = loc
	}
end

-- explist ::= {exp `,'} exp
function parseExprList(self: Parser, result: {any}, commaPositions: any)
	table.insert(result, parseExpr(self))

	while self.lexer.lexeme.type == 44 do
		nextLexeme(self)
		if self.lexer.lexeme.type == 41 then
			Report(
				self,
				self.lexer.lexeme.location,
				"Expected expression after ',' but got ')' instead"
			)

			break
		end

		table.insert(result, parseExpr(self))
	end
end

function incrementRecursionCounter(self: Parser, context: string)
	self.recursionCounter += 1

	if self.recursionCounter > RecursionLimit then
		local msg = `Exceeded allowed recursion depth; simplify your {context} to make the code compile`
		Report(self, self.lexer.lexeme.location, "%s", msg)
		error(msg, 0)
	end
end

function isExprLValue(expr: any)
	return expr.kind == "ExprLocal" or expr.kind == "ExprGlobal" or expr.kind == "ExprIndexExpr" or expr.kind == "ExprIndexName"
end

-- varlist `=' explist
function parseAssignment(self: Parser, initial: any): any
	if not isExprLValue(initial) then
		initial = reportExprError(
			self,
			initial.location,
			{initial},
			"Assigned expression must be a variable or a field"
		)
	end

	local vars = { initial }
	local varsCommaPositions = {}

	while self.lexer.lexeme.type == 44 do 
		if self.options.storeCstData then
			table.insert(varsCommaPositions, self.lexer.lexeme.location.begin)
		end
		nextLexeme(self)

		local expr = parsePrimaryExpr(self, true)
		if not isExprLValue(expr) then
			expr = reportExprError(self, expr.location, {expr}, "Assigned expression must be a variable or a field")
		end
		table.insert(vars, expr)
	end

	local equalsPosition = self.lexer.lexeme.location.begin
	expectAndConsume(self, 61, "assignment") 

	local values = {}
	local valuesCommaPositions = {}
	parseExprList(self, values, self.options.storeCstData and valuesCommaPositions or nil)

	local end_ = values[#values].location

	local node = {
		kind = "StatAssign",
		location = {begin=initial.location.begin, end_=end_.end_},
		vars = vars,
		values = values
	}

	if self.options.storeCstData then
		self.cstNodeMap[node] = {
			kind = "CstStatAssign",
			varsCommaPositions = varsCommaPositions,
			equalsPosition = equalsPosition,
			valuesCommaPositions = valuesCommaPositions
		}
	end

	return node
end

-- var [`+=' | `-=' | `*=' | `/=' | `%=' | `^=' | `..='] exp
function parseCompoundAssignment(

	self: Parser,
	initial: any,
	op: number

): any

	if not isExprLValue(initial) then
		initial = reportExprError(
			self,
			initial.location,
			{initial},
			"Assigned expression must be a variable or a field"
		)
	end

	local opPosition = self.lexer.lexeme.location.begin
	nextLexeme(self)

	local value = parseExpr(self)

	local node = {
		kind = "StatCompoundAssign",
		location = {begin=initial.location.begin, end_=value.location.end_},
		op = op,
		var = initial,
		value = value
	}

	if self.options.storeCstData then
		self.cstNodeMap[node] = {
			kind = "CstStatCompoundAssign",
			opPosition = opPosition
		}
	end

	return node
end

function prepareFunctionArguments(

	self: Parser,
	start: any,
	hasself: boolean,
	args: {any}

)
	local selfLocal = nil
	if hasself then
		selfLocal = pushLocal(self, { 
			name = { value = nameSelf, location = start },
		})
	end

	local vars = {}
	for _, arg in args do
		table.insert(vars, pushLocal(self, arg))
	end

	return selfLocal, vars
end

-- funcbody ::= `(' [parlist] `)' [`:' ReturnType] block end
-- parlist ::= bindinglist [`,' `...'] | `...'
function parseFunctionBody(

	self: Parser,
	hasself: boolean,
	matchFunction: any,
	debugname: any,
	localName: any,
	attributes: {any}

)
	local start = matchFunction.location
	if #attributes > 0 then
		start = attributes[1].location
	end

	local cstNode = nil
	if self.options.storeCstData then
		cstNode = {
			kind = "CstExprFunction",
			functionKeywordPosition = matchFunction.location.begin,
			openGenericsPosition = {line=0, column=0},
			genericsCommaPositions = {},
			closeGenericsPosition = {line=0, column=0},
			argsAnnotationColonPositions = {},
			argsCommaPositions = {},
			varargAnnotationColonPosition = {line=0, column=0},
			returnSpecifierPosition = {line=0, column=0}
		}
	end

	local openGenPosRef = cstNode and {cstNode.openGenericsPosition} or nil
	local genCommaPosRef = cstNode and cstNode.genericsCommaPositions or nil
	local closeGenPosRef = cstNode and {cstNode.closeGenericsPosition} or nil

	local genericsData = parseGenericTypeList(self, false, openGenPosRef, genCommaPosRef, closeGenPosRef)
	local generics, genericPacks = genericsData[1], genericsData[2]

	if cstNode and openGenPosRef then cstNode.openGenericsPosition = openGenPosRef[1] end
	if cstNode and closeGenPosRef then cstNode.closeGenericsPosition = closeGenPosRef[1] end

	local matchParen = self.lexer.lexeme
	expectAndConsume(self, 40, "function") 

	-- NOTE: This was added in conjunction with passing `searchForMissing` to
	-- `expectMatchAndConsume` inside `parseTableType` so that the behavior of
	-- parsing code like below (note the missing `}`):
	
	-- function (t: { a: number  ) end
	
	-- ... will still parse as (roughly):
	
	--  function (t: { a: number }) end
	
	self.matchRecoveryStopOnToken[41] = (self.matchRecoveryStopOnToken[41] or 0) + 1 

	local args = {}
	local vararg = false
	local varargLocation = nil
	local varargAnnotation = nil

	if self.lexer.lexeme.type ~= 41 then 
		local vaAnnotPosRef = cstNode and {cstNode.varargAnnotationColonPosition} or nil

		vararg, varargLocation, varargAnnotation = parseBindingList(
			self,
			args, 
			true, 
			if cstNode then cstNode.argsCommaPositions else nil, 
			nil, 
			vaAnnotPosRef
		)

		if cstNode and vaAnnotPosRef then
			cstNode.varargAnnotationColonPosition = vaAnnotPosRef[1]
		end
	end

	local argLocation = nil
	if matchParen.type == 40 and self.lexer.lexeme.type == 41 then
		argLocation = {
			begin = matchParen.location.begin,
			end_ = self.lexer.lexeme.location.end_
		}
	end

	expectMatchAndConsume(self, 41, matchParen, true) 
	self.matchRecoveryStopOnToken[41] = (self.matchRecoveryStopOnToken[41] or 0) - 1

	local retSpecPosRef = cstNode and {cstNode.returnSpecifierPosition} or nil
	local typelist = parseOptionalReturnType(self, retSpecPosRef)
	if cstNode and retSpecPosRef then cstNode.returnSpecifierPosition = retSpecPosRef[1] end

	local funLocal = nil
	if localName then
		funLocal = pushLocal(self, localName)
	end

	local localsBegin = saveLocals(self)

	local fun = { vararg = vararg, loopDepth = 0 }
	table.insert(self.functionStack, fun)

	local selfLocal, vars = prepareFunctionArguments(self, start, hasself, args)

	local body = parseBlock(self)

	table.remove(self.functionStack)

	restoreLocals(self, localsBegin)

	local end_ = self.lexer.lexeme.location
	local hasEnd = expectMatchEndAndConsume(self, Types.ReservedEnd, matchFunction)
	body.hasEnd = hasEnd

	local node = {
		kind = "ExprFunction",
		location = { begin = start.begin, end_ = end_.end_ },
		attributes = attributes,
		generics = generics,
		genericPacks = genericPacks,
		self = selfLocal,
		args = vars,
		vararg = vararg,
		varargLocation = varargLocation,
		body = body,
		functionDepth = #self.functionStack,
		debugname = debugname,
		returnAnnotation = typelist,
		varargAnnotation = varargAnnotation,
		argLocation = argLocation
	}

	if self.options.storeCstData and cstNode then
		cstNode.argsAnnotationColonPositions = extractAnnotationColonPositions(self, args)
		self.cstNodeMap[node] = cstNode
	end

	return { node, funLocal }
end

function parseGenericTypeList(
	self: Parser,
	withDefaultValues: boolean,
	openPosRef: any, commaPosRef: any,
	closePosRef: any
)
	local names = {}
	local namePacks = {}
	local localCommaPositions = {}

	if self.lexer.lexeme.type == 60 then 
		local begin = self.lexer.lexeme
		if openPosRef then
			openPosRef[1] = begin.location.begin
		end

		nextLexeme(self)

		local seenPack = false
		local seenDefault = false

		while true do
			local nameLoc = self.lexer.lexeme.location
			local name = parseName(self).name

			if self.lexer.lexeme.type == Types.Dot3 or seenPack then
				seenPack = true
				local ellipsisPosition = self.lexer.lexeme.location.begin

				if self.lexer.lexeme.type ~= Types.Dot3 then
					Report(self, self.lexer.lexeme.location, "Generic types come before generic type packs")
				else
					nextLexeme(self)
				end

				if withDefaultValues and self.lexer.lexeme.type == 61 then 
					seenDefault = true
					local equalsPosition = self.lexer.lexeme.location.begin
					nextLexeme(self)

					local typePack = nil
					if shouldParseTypePack(self) then
						typePack = parseTypePack(self)
					else
						local type_, pack_ = parseSimpleTypeOrPack(self)
						if type_ then
							Report(self, type_.location, "Expected type pack after '=', got type")
						end
						typePack = pack_
					end

					local node = {
						kind = "GenericTypePack",
						location = nameLoc,
						name = name,
						defaultValue = typePack
					}

					if self.options.storeCstData then
						self.cstNodeMap[node] = {
							kind = "CstGenericTypePack",
							ellipsisPosition = ellipsisPosition,
							defaultEqualsPosition = equalsPosition
						}
					end

					table.insert(namePacks, node)
				else
					if seenDefault then
						Report(self, self.lexer.lexeme.location, "Expected default type pack after type pack name")
					end

					local node = {
						kind = "GenericTypePack",
						location = nameLoc,
						name = name,
					}

					if self.options.storeCstData then
						self.cstNodeMap[node] = {
							kind = "CstGenericTypePack",
							ellipsisPosition = ellipsisPosition,
						}
					end

					table.insert(namePacks, node)
				end
			else
				if withDefaultValues and self.lexer.lexeme.type == 61 then 
					seenDefault = true
					local equalsPosition = self.lexer.lexeme.location.begin
					nextLexeme(self)

					local defaultType = parseType(self)

					local node = {
						kind = "GenericType",
						location = nameLoc,
						name = name,
						defaultValue = defaultType
					}

					if self.options.storeCstData then
						self.cstNodeMap[node] = {
							kind = "CstGenericType",
							defaultEqualsPosition = equalsPosition
						}
					end
					table.insert(names, node)
				else
					if seenDefault then Report(self, self.lexer.lexeme.location, "Expected default type after type name") end

					local node = {
						kind = "GenericType",
						location = nameLoc,
						name = name,
					}

					if self.options.storeCstData then
						self.cstNodeMap[node] = {
							kind = "CstGenericType"
						}
					end
					table.insert(names, node)
				end
			end

			if self.lexer.lexeme.type == 44 then 
				if commaPosRef then table.insert(localCommaPositions, self.lexer.lexeme.location.begin) end
				nextLexeme(self)

				if self.lexer.lexeme.type == 62 then 
					Report(self, self.lexer.lexeme.location, "Expected type after ',' but got '>' instead")
					break
				end
			else
				break
			end
		end

		if closePosRef then
			closePosRef[1] = self.lexer.lexeme.location.begin
		end

		expectMatchAndConsume(self, 62, begin) 
	end

	if commaPosRef then
		for _, v in localCommaPositions do
			table.insert(commaPosRef, v)
		end
	end

	return { names, namePacks }
end

function shouldParseTypePack(self: Parser)
	local t = self.lexer.lexeme.type

	if t == Types.Dot3 then
		return true
	end

	if t == Types.Name and Lookahead(self.lexer).type == Types.Dot3 then
		return true
	end

	return false
end

function parseOptionalType(self)
	if self.lexer.lexeme.type == 58 then 
		nextLexeme(self)
		return parseType(self, false)
	else
		return nil
	end
end

function extractAnnotationColonPositions(

	self: Parser,
	bindings: {any}

)
	local positions = {}
	for _, binding in bindings do
		if binding.colonPosition then
			table.insert(positions, binding.colonPosition)
		end
	end
	return positions
end

-- TypeList ::= Type [`,' TypeList] | ...Type
function parseTypeList(

	self: Parser,
	result: {any},
	resultNames: {any},
	commaPositions: {any}?,
	nameColonPositions: {any}?

)

	while true do
		if shouldParseTypePack(self) then
			return parseTypePack(self)
		end

		if self.lexer.lexeme.type == Types.Name and Lookahead(self.lexer).type == 58 then
			-- Fill in previous argument names with empty slots
			while #resultNames < #result do
				table.insert(resultNames, nil)
				if nameColonPositions then
					table.insert(nameColonPositions, nil)
				end
			end

			local name = {
				name = { value = self.lexer.lexeme.data },
				location = self.lexer.lexeme.location
			}

			table.insert(resultNames, name)
			nextLexeme(self)

			if nameColonPositions then
				table.insert(nameColonPositions, self.lexer.lexeme.location.begin)
			end

			expectAndConsume(self, 58)
		elseif #resultNames > 0 then
			-- If we have a type with named arguments, provide elements for all types
			table.insert(resultNames, nil)
			if nameColonPositions then
				table.insert(nameColonPositions, nil)
			end
		end

		table.insert(result, parseType(self, false))

		if self.lexer.lexeme.type ~= 44 then
			break
		end

		if commaPositions then
			table.insert(commaPositions, self.lexer.lexeme.location.begin)
		end
		nextLexeme(self)

		if self.lexer.lexeme.type == 41 then
			Report(
				self,
				self.lexer.lexeme.location,
				"Expected type after ',' but got ')' instead"
			)

			break
		end
	end
	return nil
end

function parseOptionalReturnType(

	self: Parser,
	returnSpecifierPosRef: any

): any

	if self.lexer.lexeme.type == 58
		or self.lexer.lexeme.type == Types.SkinnyArrow then 
		if self.lexer.lexeme.type == Types.SkinnyArrow then
			Report(
				self,
				self.lexer.lexeme.location,
				"Function return type annotations are written after ':' instead of '->'"
			)
		end

		if returnSpecifierPosRef then
			returnSpecifierPosRef[1] = self.lexer.lexeme.location.begin
		end

		nextLexeme(self)

		local oldRecursion = self.recursionCounter
		local res = parseReturnType(self)
		self.recursionCounter = oldRecursion

		-- At this point, if we find a , character, it indicates that there are multiple return types
		-- in this type annotation, but the list wasn't wrapped in parentheses.
		if self.lexer.lexeme.type == 44 then 
			Report(
				self,
				self.lexer.lexeme.location,
				"Expected a statement, got ','; did you forget to wrap the list of return types in parentheses?"
			)
			nextLexeme(self)
		end

		return res
	end

	return nil
end

-- ReturnType ::= Type | `(' TypeList `)'
function parseReturnType(self: Parser)
	incrementRecursionCounter(self, "type annotation")

	local begin = self.lexer.lexeme

	if self.lexer.lexeme.type ~= 40 then 
		if shouldParseTypePack(self) then
			return parseTypePack(self)
		else
			local type_ = parseType(self, false)

			local node = {
				kind = "TypePackExplicit",
				location = type_.location,
				types = { type_ },
			}

			if self.options.storeCstData then
				self.cstNodeMap[node] = {
					kind = "CstTypePackExplicit"
				}
			end
			return node
		end
	end

	nextLexeme(self)

	self.matchRecoveryStopOnToken[Types.SkinnyArrow] = (self.matchRecoveryStopOnToken[Types.SkinnyArrow] or 0) + 1

	local result = {}
	local resultNames = {}
	local commaPositions = {}
	local nameColonPositions = {}

	local varargAnnotation = nil

	-- possibly () -> ReturnType
	if self.lexer.lexeme.type ~= 41 then 
		if self.options.storeCstData then
			varargAnnotation = parseTypeList(self, result, resultNames, commaPositions, nameColonPositions)
		else
			varargAnnotation = parseTypeList(self, result, resultNames)
		end
	end

	local endLoc = self.lexer.lexeme.location
	local closeParenPos = self.lexer.lexeme.location.begin

	expectMatchAndConsume(self, 41, begin, true) 

	self.matchRecoveryStopOnToken[Types.SkinnyArrow] = (self.matchRecoveryStopOnToken[Types.SkinnyArrow] or 0) - 1

	if self.lexer.lexeme.type ~= Types.SkinnyArrow and #resultNames == 0 then
		-- If it turns out that it's just '(A)', it's possible that there are unions/intersections to follow, so fold over it.
		if #result == 1 then
			-- TODO(CLI-140667): stop parsing type suffix when varargAnnotation != nullptr - this should be a parse error
			local inner = varargAnnotation == nil
				and { kind = "TypeGroup", location = {begin=begin.location.begin, end_=endLoc.end_}, type = result[1] } 
				or result[1]

			local returnType = parseTypeSuffix(self, inner, begin.location)
			
			-- If parseType parses nothing, then returnType->location.end only points at the last non-type-pack
			-- type to successfully parse.  We need the span of the whole annotation.
			local endPos = (#result == 1) and endLoc.end_ or returnType.location.end_

			local node = {
				kind = "TypePackExplicit",
				location = {
					begin = begin.location.begin,
					end_ = endPos
				},
				types = { returnType },
				tailType = varargAnnotation
			}

			if self.options.storeCstData then
				self.cstNodeMap[node] = {
					kind = "CstTypePackExplicit"
				}
			end
			return node
		end

		local node = {
			kind = "TypePackExplicit",
			location = {
				begin = begin.location.begin,
				end_ = endLoc.end_
			},
			types = result,
			tailType = varargAnnotation
		}

		if self.options.storeCstData then
			self.cstNodeMap[node] = {
				kind = "CstTypePackExplicit",
				openParenthesesPosition = begin.location.begin,
				closeParenthesesPosition = closeParenPos,
				commaPositions = commaPositions
			}
		end
		return node
	end

	local returnArrowPosition = self.lexer.lexeme.location.begin
	local tail = parseFunctionTypeTail(self, begin, {}, {}, {}, result, resultNames, varargAnnotation)

	if self.options.storeCstData and tail.kind == "TypeFunction" then
		self.cstNodeMap[tail] = {
			kind = "CstTypeFunction",
			openGenericsPosition = {line=0, column=0},
			genericsCommaPositions = {},
			closeGenericsPosition = {line=0, column=0},
			openArgsPosition = begin.location.begin,
			argumentNameColonPositions = nameColonPositions,
			argumentsCommaPositions = commaPositions,
			closeArgsPosition = closeParenPos,
			returnArrowPosition = returnArrowPosition
		}
	end

	local node = {
		kind = "TypePackExplicit",
		location = {
			begin = begin.location.begin,
			end_ = tail.location.end_
		},
		types = { tail }
	}

	if self.options.storeCstData then
		self.cstNodeMap[node] = {
			kind = "CstTypePackExplicit"
		}
	end

	return node
end

local function extractStringDetails(self: Parser)
	local style = 0
	local depth = 0

	local lexeme = self.lexer.lexeme

	local t = lexeme.type

	if t == Types.QuotedString then
		style = lexeme.aux == 1 and 1 or 0
	elseif t == Types.InterpStringSimple then
		style = 3 
	elseif t == Types.RawString then
		style = 2 
		depth = lexeme.aux or 0
	end

	return style, depth
end

-- TableIndexer ::= `[' Type `]' `:' Type
function parseTableIndexer(

	self: Parser,
	access: string,
	accessLoc: any,
	begin: any

)

	local index = parseType(self, false)

	local indexerClosePos = self.lexer.lexeme.location.begin
	expectMatchAndConsume(self, 93, begin) 

	local colonPos = self.lexer.lexeme.location.begin
	expectAndConsume(self, 58, "table field") 

	local result = parseType(self, false)

	local node = {
		kind = "TableIndexer",
		location = {
			begin = begin.location.begin,
			end_ = result.location.end_
		},
		indexType = index,
		resultType = result,
		access = access,
		accessLocation = accessLoc
	}

	return {
		node = node,
		indexerOpenPosition = begin.location.begin,
		indexerClosePosition = indexerClosePos,
		colonPosition = colonPos
	}
end

-- TableProp ::= Name `:' Type
-- TablePropOrIndexer ::= TableProp | TableIndexer
-- PropList ::= TablePropOrIndexer {fieldsep TablePropOrIndexer} [fieldsep]
-- TableType ::= `{' PropList `}'
function parseTableType(self: Parser, inDeclarationContext: boolean)
	incrementRecursionCounter(self, "type annotation")

	local props = {}
	local cstItems = {} 
	local indexer = nil

	local start = self.lexer.lexeme.location
	local matchBrace = self.lexer.lexeme
	expectAndConsume(self, 123, "table type") 

	local isArray = false

	while self.lexer.lexeme.type ~= 125 do 
		local access = "ReadWrite"
		local accessLoc = nil


		if self.lexer.lexeme.type == Types.Name and Lookahead(self.lexer).type ~= 58 then 
			if self.lexer.lexeme.data == "read" then
				accessLoc = self.lexer.lexeme.location
				access = "Read"
				nextLexeme(self)
			elseif self.lexer.lexeme.data == "write" then
				accessLoc = self.lexer.lexeme.location
				access = "Write"
				nextLexeme(self)
			end
		end

		if self.lexer.lexeme.type == 91 then 
			local begin = self.lexer.lexeme
			nextLexeme(self)


			if (self.lexer.lexeme.type == Types.RawString or self.lexer.lexeme.type == Types.QuotedString) and Lookahead(self.lexer).type == 93 then
				local style = 0 
				local depth = 0
				if self.options.storeCstData then
					style, depth = extractStringDetails(self)
				end

				local stringPos = self.lexer.lexeme.location.begin
				local sourceString = nil
				if self.options.storeCstData then
					sourceString = self.lexer.lexeme.data
				end

				local chars = parseCharArray(self)

				local indexerClosePos = self.lexer.lexeme.location.begin
				expectMatchAndConsume(self, 93, begin) 

				local colonPos = self.lexer.lexeme.location.begin
				expectAndConsume(self, 58, "table field") 

				local type_ = parseType(self)

				if chars then
					table.insert(props, {
						name = { value = chars }, 
						location = begin.location,
						type = type_,
						access = access,
						accessLocation = accessLoc
					})

					if self.options.storeCstData then
						local cstString = {
							kind = "CstExprConstantString",
							sourceString = sourceString,
							quoteStyle = style,
							blockDepth = depth
						}

						table.insert(cstItems, {
							kind = "StringProperty",
							indexerOpenPosition = begin.location.begin,
							indexerClosePosition = indexerClosePos,
							colonPosition = colonPos,
							separator = tableSeparator(self),
							separatorPosition = self.lexer.lexeme.location.begin,
							stringInfo = cstString,
							stringPosition = stringPos
						})
					end
				else
					Report(self, begin.location, "String literal contains malformed escape sequence or \\0")
				end
			else

				if indexer then

					local badIndexerRes = parseTableIndexer(self, access, accessLoc, begin)
					Report(self, badIndexerRes.node.location, "Cannot have more than one table indexer")
				else
					local idxRes = parseTableIndexer(self, access, accessLoc, begin)
					indexer = idxRes.node

					if self.options.storeCstData then
						table.insert(cstItems, {
							kind = "Indexer",

							indexerOpenPosition = idxRes.indexerOpenPosition,
							indexerClosePosition = idxRes.indexerClosePosition,
							colonPosition = idxRes.colonPosition, 
							separator = tableSeparator(self),
							separatorPosition = self.lexer.lexeme.location.begin
						})
					end
				end
			end
		elseif #props == 0 and not indexer and not (self.lexer.lexeme.type == Types.Name and Lookahead(self.lexer).type == 58) then
			isArray = true
			local type_ = parseType(self)

			local index = {
				kind = "TypeReference",
				location = type_.location,
				name = nameNumber,
				nameLocation = type_.location,
				hasParameterList = false,
				parameters = {}
			}

			indexer = {
				kind = "TableIndexer",
				location = type_.location,
				indexType = index,
				resultType = type_,
				access = access,
				accessLocation = accessLoc
			}
			break
		else
			local nameOpt = parseNameOpt(self, "table field")
			if not nameOpt then break end

			local colonPos = self.lexer.lexeme.location.begin
			expectAndConsume(self, 58, "table field")

			local type_ = parseType(self, inDeclarationContext)

			table.insert(props, {
				name = nameOpt.name,
				location = nameOpt.location,
				type = type_,
				access = access,
				accessLocation = accessLoc
			})

			if self.options.storeCstData then
				table.insert(cstItems, {
					kind = "Property",
					colonPosition = colonPos,
					separator = tableSeparator(self),
					separatorPosition = self.lexer.lexeme.location.begin
				})
			end
		end

		if self.lexer.lexeme.type == 44 or self.lexer.lexeme.type == 59 then 
			nextLexeme(self)
		elseif self.lexer.lexeme.type ~= 125 then 
			break
		end
	end

	local endLoc = self.lexer.lexeme.location
	if not expectMatchAndConsume(self, 125, matchBrace, true) then 
		endLoc = self.lexer.prevLocation
	end

	local node = {
		kind = "TypeTable",
		location = {begin=start.begin, end_=endLoc.end_},
		props = props,
		indexer = indexer
	}

	if self.options.storeCstData then
		self.cstNodeMap[node] = {
			kind = "CstTypeTable",
			items = cstItems,
			isArray = isArray
		}
	end

	return node
end

-- ReturnType ::= Type | `(' TypeList `)'
-- FunctionType ::= [`<' varlist `>'] `(' [TypeList] `)' `->` ReturnType
function parseFunctionType(

	self: Parser,
	allowPack: boolean,
	attributes: {any}

): (any, any) 

	incrementRecursionCounter(self, "type annotation")

	local forceFunctionType = (self.lexer.lexeme.type == 60) 
	local begin = self.lexer.lexeme

	local openGenPos = { { line = 0, column = 0 } }
	local genCommaPos = {}
	local closeGenPos = { { line = 0, column = 0 } }

	local genericsData = nil
	if self.options.storeCstData then
		genericsData = parseGenericTypeList(self, false, openGenPos, genCommaPos, closeGenPos)
	else
		genericsData = parseGenericTypeList(self, false)
	end

	local generics, genericPacks = genericsData[1], genericsData[2]

	local paramStart = self.lexer.lexeme
	expectAndConsume(self, 40, "function parameters") 

	self.matchRecoveryStopOnToken[Types.SkinnyArrow] = (self.matchRecoveryStopOnToken[Types.SkinnyArrow] or 0) + 1

	local params = {}
	local names = {}
	local argCommaPos = {}
	local nameColonPos = {}

	local varargAnnotation = nil

	if self.lexer.lexeme.type ~= 41 then 
		if self.options.storeCstData then
			varargAnnotation = parseTypeList(self, params, names, argCommaPos, nameColonPos)
		else
			varargAnnotation = parseTypeList(self, params, names)
		end
	end

	local closeArgsLoc = self.lexer.lexeme.location
	expectMatchAndConsume(self, 41, paramStart, true) 

	self.matchRecoveryStopOnToken[Types.SkinnyArrow] = (self.matchRecoveryStopOnToken[Types.SkinnyArrow] or 0) - 1

	local paramTypes = params 
	if #names > 0 then
		forceFunctionType = true
	end

	local returnTypeIntroducer = (self.lexer.lexeme.type == Types.SkinnyArrow or self.lexer.lexeme.type == 58)

	-- ot a function at all. Just a parenthesized type. Or maybe a type pack with a single element
	if #params == 1 and not varargAnnotation and not forceFunctionType and not returnTypeIntroducer then
		if allowPack then
			local node = {
				kind = "TypePackExplicit",
				location = begin.location,
				types = paramTypes
			}

			if self.options.storeCstData then
				self.cstNodeMap[node] = {
					kind = "CstTypePackExplicit",
					openParenthesesPosition = paramStart.location.begin,
					closeParenthesesPosition = closeArgsLoc.begin,
					commaPositions = argCommaPos
				}
			end

			return nil, node
		else
			return {
				kind = "TypeGroup",
				location = {
					begin = paramStart.location.begin,
					end_ =closeArgsLoc.end_
				},
				type = params[1]
			}
		end
	end

	if not forceFunctionType and not returnTypeIntroducer and allowPack then
		local node = {
			kind = "TypePackExplicit",
			location = begin.location,
			types = paramTypes,
			tailType = varargAnnotation
		}

		if self.options.storeCstData then
			self.cstNodeMap[node] = {
				kind = "CstTypePackExplicit",
				openParenthesesPosition = paramStart.location.begin,
				closeParenthesesPosition = closeArgsLoc.begin,
				commaPositions = argCommaPos
			}
		end

		return nil, node
	end

	local returnArrowPosition = self.lexer.lexeme.location.begin
	local node = parseFunctionTypeTail(self, begin, attributes, generics, genericPacks, paramTypes, names, varargAnnotation)

	if self.options.storeCstData and node.kind == "TypeFunction" then
		self.cstNodeMap[node] = {
			kind = "CstTypeFunction",
			openGenericsPosition = openGenPos[1],
			genericsCommaPositions = genCommaPos,
			closeGenericsPosition = closeGenPos[1],
			openArgsPosition = paramStart.location.begin,
			argumentNameColonPositions = nameColonPos,
			argumentsCommaPositions = argCommaPos,
			closeArgsPosition = closeArgsLoc.begin,
			returnArrowPosition = returnArrowPosition
		}
	end

	return node, nil
end

function parseFunctionTypeTail(

	self: Parser,
	begin: any,
	attributes: {any},
	generics: {any},
	genericPacks: {any},
	params: {any},
	paramNames: {any},
	varargAnnotation: any

): any

	incrementRecursionCounter(self, "type annotation")

	if self.lexer.lexeme.type == 58 then
		Report(
			self,
			self.lexer.lexeme.location,
			"Return types in function type annotations are written after '->' instead of ':'"
		)

		nextLexeme(self)
		
	-- Users occasionally write '()' as the 'unit' type when they actually want to use 'nil', here we'll try to give a more specific error
	elseif self.lexer.lexeme.type ~= Types.SkinnyArrow and #generics == 0 and #genericPacks == 0 and #params == 0 then
		Report(
			self,
			{
				begin = begin.location.begin,
				end_ = self.lexer.prevLocation.end_
			},
			"Expected '->' after '()' when parsing function type; did you mean 'nil'?"
		)

		return {
			kind = "TypeReference",
			location = begin.location,
			name = nameNil,
			hasParameterList = false,
			parameters = {}
		}
	else
		expectAndConsume(self, Types.SkinnyArrow, "function type")
	end

	local returnType = parseReturnType(self)

	return {
		kind = "TypeFunction",
		location = {
			begin = begin.location.begin,
			end_ = returnType.location.end_
		},
		attributes = attributes,
		generics = generics,
		genericPacks = genericPacks,
		argTypes = {
			types = params,
			tailType = varargAnnotation
		},
		argNames = paramNames,
		returnTypes = returnType
	}
end

-- Type ::=
--      nil |
--      Name[`.' Name] [`<' namelist `>'] |
--      `{' [PropList] `}' |
--      `(' [TypeList] `)' `->` ReturnType
--      `typeof` Type
function parseTypeSuffix(self: Parser, type_: any, begin: any)
	local parts = {} :: {any}
	if type_ then 
		table.insert(parts, type_) 
	end

	incrementRecursionCounter(self, "type annotation")

	local isUnion = false
	local isIntersection = false
	local optionalCount = 0

	local separatorPositions = {}
	local leadingPosition = nil

	while true do
		local t = self.lexer.lexeme.type
		local separatorPosition = self.lexer.lexeme.location.begin

		if t == 124 then 
			nextLexeme(self)

			local oldRecursion = self.recursionCounter

			local typePart, _ = parseSimpleType(self, false, false) 
			table.insert(parts, typePart)

			self.recursionCounter = oldRecursion

			isUnion = true

			if self.options.storeCstData then
				if type_ == nil and not leadingPosition then
					leadingPosition = separatorPosition
				else
					table.insert(separatorPositions, separatorPosition)
				end
			end

		elseif t == 63 then
			local loc = self.lexer.lexeme.location
			nextLexeme(self)

			table.insert(parts, { kind = "TypeOptional", location = loc })

			optionalCount += 1
			isUnion = true
		elseif t == 38 then
			nextLexeme(self)

			local oldRecursion = self.recursionCounter

			local typePart, _ = parseSimpleType(self, false, false)

			table.insert(parts, typePart)

			self.recursionCounter = oldRecursion

			isIntersection = true

			if self.options.storeCstData then
				if type_ == nil and not leadingPosition then
					leadingPosition = separatorPosition
				else
					table.insert(separatorPositions, separatorPosition)
				end
			end

		elseif t == Types.Dot3 then
			Report(self, self.lexer.lexeme.location, "Unexpected '...' after type annotation")
			nextLexeme(self)
		else
			break
		end

		if #parts > TypeLengthLimit + optionalCount then
			Report(self, parts[#parts].location, "Exceeded allowed type length; simplify your type annotation to make the code compile")
		end
	end

	if #parts == 1 and not isUnion and not isIntersection then
		return parts[1]
	end

	if isUnion and isIntersection then
		reportTypeError(self, { begin = begin.begin, end_ = parts[#parts].location.end_ }, parts, "Mixing union and intersection types is not allowed; consider wrapping in parentheses.")
	end

	local loc = { begin = begin.begin, end_ = parts[#parts].location.end_ }

	if isUnion then
		local node = { kind = "TypeUnion", location = loc, types = parts }
		if self.options.storeCstData then
			self.cstNodeMap[node] = {
				kind = "CstTypeUnion",
				leadingPosition = leadingPosition,
				separatorPositions = separatorPositions
			}
		end
		return node
	end

	if isIntersection then
		local node = { kind = "TypeIntersection", location = loc, types = parts }
		if self.options.storeCstData then
			self.cstNodeMap[node] = {
				kind = "CstTypeIntersection",
				leadingPosition = leadingPosition,
				separatorPositions = separatorPositions
			}
		end
		return node
	end

	return parts[1]
end

function parseSimpleTypeOrPack(self: Parser): (any, any)
	local oldRec = self.recursionCounter
	-- recursion counter is incremented in parseSimpleType
	
	local begin = self.lexer.lexeme.location

	local type_, typePack = parseSimpleType(self, true, false)

	if typePack then
		return nil, typePack
	end

	self.recursionCounter = oldRec

	return parseTypeSuffix(self, type_, begin)
end

function parseType(self: Parser, inDeclarationContext: boolean?)
	local oldRec = self.recursionCounter
	-- recursion counter is incremented in parseSimpleType and/or parseTypeSuffix
	
	local begin = self.lexer.lexeme.location

	local type_ = nil

	if self.lexer.lexeme.type ~= 124 and self.lexer.lexeme.type ~= 38 then 
		type_ = parseSimpleType(self, false, inDeclarationContext or false)
		self.recursionCounter = oldRec
	end

	local typeWithSuffix = parseTypeSuffix(self, type_, begin)
	self.recursionCounter = oldRec

	return typeWithSuffix
end

-- Type ::= nil | Name[`.' Name] [ `<' Type [`,' ...] `>' ] | `typeof' `(' expr `)' | `{' [PropList] `}'
--   | [`<' varlist `>'] `(' [TypeList] `)' `->` ReturnType
function parseSimpleType(

	self: Parser,
	allowPack: boolean,
	inDeclarationContext: boolean

): (any, TypePack)

	incrementRecursionCounter(self, "type annotation")

	local start = self.lexer.lexeme.location

	if self.lexer.lexeme.type == Types.Attribute or self.lexer.lexeme.type == Types.AttributeOpen then
		if not inDeclarationContext then
			return reportTypeError(
				self,
				start,
				{},
				"attributes are not allowed in declaration context"
			)
		else
			local attributes = parseAttributes(self)

			return parseFunctionType(
				self,
				allowPack,
				attributes
			)
		end
	elseif self.lexer.lexeme.type == Types.ReservedNil then
		nextLexeme(self)

		return {
			kind = "TypeReference",
			location = start,
			name = nameNil,
			hasParameterList = false,
			parameters = {}
		}
	elseif self.lexer.lexeme.type == Types.ReservedTrue then
		nextLexeme(self)

		return {
			kind = "TypeSingletonBool",
			location = start,
			value = true
		}
	elseif self.lexer.lexeme.type == Types.ReservedFalse then
		nextLexeme(self)

		return {
			kind = "TypeSingletonBool",
			location = start,
			value = false
		}
	elseif self.lexer.lexeme.type == Types.RawString or self.lexer.lexeme.type == Types.QuotedString then
		local chars = parseCharArray(self)
		if chars then
			return {
				kind = "TypeSingletonString",
				location = start,
				value = chars
			}
		else
			return reportTypeError(
				self,
				start, 
				{},
				"String literal contains malformed escape sequence"
			)
		end
	elseif self.lexer.lexeme.type == Types.InterpStringBegin or self.lexer.lexeme.type == Types.InterpStringSimple then
		parseInterpString(self)

		return reportTypeError(
			self,
			start,
			{},
			"Interpolated string literals cannot be used as types"
		)
	elseif self.lexer.lexeme.type == Types.BrokenString then
		nextLexeme(self)
		return reportTypeError(
			self,
			start,
			{},
			"Malformed string; did you forget to finish it?"
		)
	elseif self.lexer.lexeme.type == Types.Name then
		local name = parseName(self, "type name")
		local prefix = nil
		local prefixLoc = nil
		local prefixPointPos = nil

		if self.lexer.lexeme.type == 46 then 
			prefixPointPos = self.lexer.lexeme.location.begin
			nextLexeme(self)
			prefix = name.name.value
			prefixLoc = name.location
			name = parseIndexName(self, "field name", name.location.end_)
		elseif self.lexer.lexeme.type == Types.Dot3 then
			Report(
				self,
				self.lexer.lexeme.location,
				"Unexpected '...' after type name; type pack is not allowed in this context"
			)

			nextLexeme(self)
		elseif name.name.value == "typeof" then
			local typeofBegin = self.lexer.lexeme
			expectAndConsume(self, 40, "typeof type") 
			local expr = parseExpr(self)
			local endLoc = self.lexer.lexeme.location
			expectMatchAndConsume(self, 41, typeofBegin, false) 

			local node = {
				kind = "TypeTypeof",
				location = {
					begin=start.begin,
					end_=endLoc.end_
				},
				expr = expr
			}

			if self.options.storeCstData then
				self.cstNodeMap[node] = {
					kind = "CstTypeTypeof",
					openPosition = typeofBegin.location.begin,
					closePosition = endLoc.begin
				}
			end
			return node
		end

		local hasParams = false
		local params = {}

		local openPosRef = if self.options.storeCstData then { { line = 0, column = 0} } else nil
		local commaPosRef = if self.options.storeCstData then {} else nil
		local closePosRef = if self.options.storeCstData then { { line = 0, column = 0} } else nil

		if self.lexer.lexeme.type == 60 then 
			hasParams = true
			params = parseTypeParams(self, openPosRef, commaPosRef, closePosRef)
		end

		local node = { 
			kind = "TypeReference", 
			location = {
				begin = start.begin,
				end_ = self.lexer.prevLocation.end_
			}, 
			prefix = prefix, 
			name = name.name.value, 
			prefixLocation = prefixLoc, 
			nameLocation = name.location, 
			hasParameterList = hasParams, 
			parameters = params 
		}

		if self.options.storeCstData then
			self.cstNodeMap[node] = {
				kind = "CstTypeReference",
				prefixPointPosition = prefixPointPos,
				openParametersPosition = openPosRef and openPosRef[1] or nil,
				parametersCommaPositions = commaPosRef or {},
				closeParametersPosition = closePosRef and closePosRef[1] or nil
			}
		end

		return node
	elseif self.lexer.lexeme.type == 123 then 
		return parseTableType(self, inDeclarationContext)
	elseif self.lexer.lexeme.type == 40 or self.lexer.lexeme.type == 60 then 
		return parseFunctionType(self, allowPack, {})
	elseif self.lexer.lexeme.type == Types.ReservedFunction then
		nextLexeme(self)

		return reportTypeError(
			self,
			start, {},
			"Using 'function' as a type annotation is not supported..."
		)
	else
		Report(self, start, "Expected type, got %s", ToString(self.lexer.lexeme))

		return {
			kind = "TypeError",
			location = start,
			types = {},
			isMissing = true,
			messageIndex = #self.parseErrors
		}
	end
end

function parseVariadicArgumentTypePack(self: Parser)
	-- Generic: a...
	if self.lexer.lexeme.type == Types.Name and Lookahead(self.lexer).type == Types.Dot3 then
		local name = parseName(self, "generic name")
		local endLoc = self.lexer.lexeme.location
		
		-- This will not fail because of the lookahead guard.
		expectAndConsume(self, Types.Dot3, "generic type pack annotation")

		local node = {
			kind = "TypePackGeneric",
			location = {
				begin = name.location.begin,
				end_ = endLoc.end_
			},
			genericName = name.name.value
		}

		if self.options.storeCstData then
			self.cstNodeMap[node] = {
				kind = "CstTypePackGeneric",
				ellipsisPosition = endLoc.begin
			}
		end

		return node
	else -- Variadic: T
		local varTy = parseType(self, false)

		return {
			kind = "TypePackVariadic",
			location = varTy.location,
			variadicType = varTy
		}
	end
end

function parseTypePack(self: Parser): any
	-- Variadic: ...T
	if self.lexer.lexeme.type == Types.Dot3 then
		local start = self.lexer.lexeme.location
		nextLexeme(self)
		local varTy = parseType(self, false)
		return {
			kind = "TypePackVariadic",
			location = {
				begin = start.begin,
				end_ = varTy.location.end_
			},
			variadicType = varTy
		}
		
	-- Generic: a...
	elseif self.lexer.lexeme.type == Types.Name and Lookahead(self.lexer).type == Types.Dot3 then
		local name = parseName(self, "generic name")
		local endLoc = self.lexer.lexeme.location

		-- This will not fail because of the lookahead guard.
		expectAndConsume(self, Types.Dot3, "generic type pack annotation")

		local node = {
			kind = "TypePackGeneric",
			location = {
				begin = name.location.begin,
				end_ = endLoc.end_
			},
			genericName = name.name.value
		}

		if self.options.storeCstData then
			self.cstNodeMap[node] = {
				kind = "CstTypePackGeneric",
				ellipsisPosition = endLoc.begin
			}
		end

		return node
	end
	
	return nil
end

function parseTypeParams(

	self: Parser,
	openingPosRef: any,
	commaPosRef: any,
	closingPosRef: any

)

	local params = {}
	if self.lexer.lexeme.type == 60 then

		local begin = self.lexer.lexeme
		if openingPosRef then
			openingPosRef[1] = begin.location.begin
		end

		nextLexeme(self)

		while true do
			if shouldParseTypePack(self) then
				local pack = parseTypePack(self)
				table.insert(params, { typePack = pack })
			elseif self.lexer.lexeme.type == 40 then
				local beginParen = self.lexer.lexeme.location
				local type_ = nil
				local typePack = nil
				local t = self.lexer.lexeme.type

				if t ~= 124 and t ~= 38 then
					type_, typePack = parseSimpleType(self, true, false)
				end
				
				--/ Consider the following type:
				
				--  X<(T)>
				
				-- Is this a type pack or a parenthesized type? The
				-- assumption will be a type pack, as that's what allows one
				-- to express either a singular type pack or a potential
				-- complex type.

				if typePack then
					if typePack.kind == "TypePackExplicit"
						and #typePack.types == 1
						and not typePack.tailType
						and (
							self.lexer.lexeme.type == 124
								or self.lexer.lexeme.type == 63
								or self.lexer.lexeme.type == 38
						) then
						
						-- If we parsed an explicit type pack with a single
						-- type in it (something of the form `(T)`), and
						-- the next lexeme is one that follows a type
						-- (&, |, ?), then assume that this was actually a
						-- parenthesized type.

						local parenTy = typePack.types[1]

						local node = {
							kind = "TypeGroup",
							location = parenTy.location,
							type = parenTy
						}

						table.insert(params, {type = parseTypeSuffix(self, node, beginParen)})
					else
						-- Otherwise, it's a type pack.
						table.insert(params, { type = nil, typePack = typePack })
					end
				else
					-- There's two cases in which `typePack` will be null:
					-- - We try to parse a simple type or a type pack, and
					--   we get a simple type: there's no ambiguity and
					--   we attempt to parse a complex type.
					-- - The next lexeme was a `|` or `&` indicating a
					--   union or intersection type with a leading
					--   separator. We just fall right into
					--   `parseTypeSuffix`, which allows its first
					--   argument to be `nullptr`
					table.insert(params, { type = parseTypeSuffix(self, type_, beginParen)})
				end
			elseif self.lexer.lexeme.type == 62 and #params == 0 then
				break
			else
				table.insert(params, { type = parseType(self, false)})
			end

			if self.lexer.lexeme.type == 44 then
				if commaPosRef then table.insert(commaPosRef, self.lexer.lexeme.location.begin) end
				nextLexeme(self)
			else
				break
			end
		end

		if closingPosRef then closingPosRef[1] = self.lexer.lexeme.location.begin end
		expectMatchAndConsume(self, 62, begin, false)
	end
	return params
end

local UnaryOp = {
	Not = 0,
	Minus = 1,
	Len = 2
}

local BinaryOp = {
	Add = 0, Sub = 1, Mul = 2, Div = 3, FloorDiv = 4, Mod = 5, Pow = 6, Concat = 7,
	CompareNe = 8, CompareEq = 9, CompareLt = 10, CompareLe = 11, CompareGt = 12, CompareGe = 13,
	And = 14, Or = 15
}

local BinaryPriority = {
	[BinaryOp.Add] = {6, 6},
	[BinaryOp.Sub] = {6, 6},
	[BinaryOp.Mul] = {7, 7},
	[BinaryOp.Div] = {7, 7},
	[BinaryOp.FloorDiv] = {7, 7},
	[BinaryOp.Mod] = {7, 7},
	[BinaryOp.Pow] = {10, 9},
	[BinaryOp.Concat] = {5, 4},
	[BinaryOp.CompareNe] = {3, 3},
	[BinaryOp.CompareEq] = {3, 3},
	[BinaryOp.CompareLt] = {3, 3},
	[BinaryOp.CompareLe] = {3, 3},
	[BinaryOp.CompareGt] = {3, 3},
	[BinaryOp.CompareGe] = {3, 3},
	[BinaryOp.And] = {2, 2},
	[BinaryOp.Or] = {1, 1}
}

function parseUnaryOp(lexeme: any): number?
	local t = lexeme.type
	if t == Types.ReservedNot then
		return UnaryOp.Not
	elseif t == 45 then
		return UnaryOp.Minus 
	elseif t == 35 then
		return UnaryOp.Len 
	end

	return nil
end

function parseBinaryOp(lexeme: Lexer.Lexeme): number?
	local t = lexeme.type
	if t == 43 then
		return BinaryOp.Add
	elseif t == 45 then
		return BinaryOp.Sub
	elseif t == 42 then
		return BinaryOp.Mul
	elseif t == 47 then
		return BinaryOp.Div
	elseif t == Types.FloorDiv then
		return BinaryOp.FloorDiv
	elseif t == 37 then
		return BinaryOp.Mod
	elseif t == 94 then
		return BinaryOp.Pow
	elseif t == Types.Dot2 then
		return BinaryOp.Concat
	elseif t == Types.NotEqual then
		return BinaryOp.CompareNe
	elseif t == Types.Equal then
		return BinaryOp.CompareEq
	elseif t == 60 then
		return BinaryOp.CompareLt
	elseif t == Types.LessEqual then
		return BinaryOp.CompareLe
	elseif t == 62 then
		return BinaryOp.CompareGt
	elseif t == Types.GreaterEqual then
		return BinaryOp.CompareGe
	elseif t == Types.ReservedAnd then
		return BinaryOp.And
	elseif t == Types.ReservedOr then
		return BinaryOp.Or
	end

	return nil
end

function parseCompoundOp(lexeme: any): number?
	local t = lexeme.type
	if t == Types.AddAssign then
		return BinaryOp.Add
	elseif t == Types.SubAssign then
		return BinaryOp.Sub
	elseif t == Types.MulAssign then
		return BinaryOp.Mul
	elseif t == Types.DivAssign then
		return BinaryOp.Div
	elseif t == Types.FloorDivAssign then
		return BinaryOp.FloorDiv
	elseif t == Types.ModAssign then
		return BinaryOp.Mod
	elseif t == Types.PowAssign then
		return BinaryOp.Pow
	elseif t == Types.ConcatAssign then
		return BinaryOp.Concat
	end
	return nil
end

function checkUnaryConfusables(self: Parser): number?
	local curr = self.lexer.lexeme
	
	-- early-out: need to check if this is a possible confusable quickly
	if curr.type ~= 33 then 
		return nil
	end
	
	Report(
		self,
		curr.location,
		"Unexpected '!'; did you mean 'not'?"
	)

	return UnaryOp.Not
end

function checkBinaryConfusables(self: Parser, limit: number): number?
	local curr = self.lexer.lexeme

	-- arly-out: need to check if this is a possible confusable quickly
	if curr.type ~= 38 and curr.type ~= 124 and curr.type ~= 33 then
		return nil
	end

	-- slow path: possible confusable
	local start = curr.location
	local next_ = Lookahead(self.lexer)

	if curr.type == 38 and next_.type == 38 and curr.location.end_.column == next_.location.begin.column and BinaryPriority[BinaryOp.And][1] > limit then
		nextLexeme(self)

		Report(self,
			{
				begin = start.begin,
				end_ = next_.location.end_
			},
			"Unexpected '&&'; did you mean 'and'?"
		)

		return BinaryOp.And
	elseif curr.type == 124 and next_.type == 124 and curr.location.end_.column == next_.location.begin.column and BinaryPriority[BinaryOp.Or][1] > limit then
		nextLexeme(self)

		Report(self,
			{
				begin = start.begin,
				end_ = next_.location.end_
			},
			"Unexpected '||'; did you mean 'or'?"
		)

		return BinaryOp.Or
	elseif curr.type == 33 and next_.type == 61 and curr.location.end_.column == next_.location.begin.column and BinaryPriority[BinaryOp.CompareNe][1] > limit then
		nextLexeme(self)

		Report(self,
			{
				begin=start.begin,
				end_=next_.location.end_
			},
			"Unexpected '!='; did you mean '~='?"
		)

		return BinaryOp.CompareNe
	end

	return nil
end

-- subexpr -> (asexp | unop subexpr) { binop subexpr }
-- where `binop' is any binary operator with a priority higher than `limit'
function parseExpr(self: Parser, limit: number?): any
	limit = limit or 0
	local oldRecursion = self.recursionCounter
	
	-- this handles recursive calls to parseSubExpr/parseExpr
	incrementRecursionCounter(self, "expression")

	local start = self.lexer.lexeme.location
	local expr = nil

	local uop = parseUnaryOp(self.lexer.lexeme)
	if not uop then uop = checkUnaryConfusables(self) end

	if uop then
		local opPosition = self.lexer.lexeme.location.begin
		nextLexeme(self)

		local subexpr = parseExpr(self, 8)

		expr = {
			kind = "ExprUnary",
			location = {
				begin = start.begin,
				end_ = subexpr.location.end_
			},
			op = uop,
			expr = subexpr
		}

		if self.options.storeCstData then
			self.cstNodeMap[expr] = {
				kind = "CstExprOp",
				opPosition = opPosition
			}
		end
	else
		expr = parseAssertionExpr(self)
	end
	
	-- expand while operators have priorities higher than `limit'
	local op = parseBinaryOp(self.lexer.lexeme)

	if not op then
		op = checkBinaryConfusables(self, limit)
	end
	
	-- expand while operators have priorities higher than `limit'
	while op and BinaryPriority[op][1] > limit do
		local opPosition = self.lexer.lexeme.location.begin
		nextLexeme(self)

		-- read sub-expression with higher priority
		local nextExpr = parseExpr(self, BinaryPriority[op][2])

		expr = {
			kind = "ExprBinary",
			location = {
				begin = start.begin,
				end_ = nextExpr.location.end_
			},
			op = op,
			left = expr,
			right = nextExpr
		}

		if self.options.storeCstData then
			self.cstNodeMap[expr] = {
				kind = "CstExprOp",
				opPosition = opPosition
			}
		end

		op = parseBinaryOp(self.lexer.lexeme)
		if not op then
			op = checkBinaryConfusables(self, limit)
		end
			
		-- note: while the parser isn't recursive here, we're generating recursive structures of unbounded depth
		incrementRecursionCounter(self, "expression")
	end

	self.recursionCounter = oldRecursion
	return expr
end

-- NAME
function parseNameExpr(self: Parser, context: string): any
	local nameOpt = parseNameOpt(self, context)

	if not nameOpt then
		return {
			kind = "ExprError",
			location = self.lexer.lexeme.location,
			expressions = {},
			messageIndex = #self.parseErrors
		}
	end

	local name = nameOpt
	local local_ = self.localMap[name.name.value]

	if local_ then
		if local_.functionDepth < (self.typeFunctionDepth or 0) then
			return reportExprError(
				self,
				self.lexer.lexeme.location,
				{},
				"Type function cannot reference outer local '%s'",
				local_.name
			)
		end

		return {
			kind = "ExprLocal",
			location = name.location,
			local_ = local_,
			upvalue = local_.functionDepth ~= (#self.functionStack - 1)
		}
	end

	return {
		kind = "ExprGlobal",
		location = name.location,
		name = name.name.value
	}
end

-- prefixexp -> NAME | '(' expr ')'
function parsePrefixExpr(self: Parser)
	if self.lexer.lexeme.type == 40 then 
		local start = self.lexer.lexeme.location.begin
		local matchParen = self.lexer.lexeme
		nextLexeme(self)

		local expr = parseExpr(self)

		local end_ = self.lexer.lexeme.location.end_
		if self.lexer.lexeme.type ~= 41 then 
			expectMatchAndConsumeFail(
				self,
				41,
				matchParen,
				self.lexer.lexeme.type == 61 and "; did you mean to use '{' when defining a table?" or nil
			)

			end_ = self.lexer.prevLocation.end_
		else
			nextLexeme(self)
		end

		return {
			kind = "ExprGroup",
			location = {
				begin = start,
				end_ = end_
			},
			expr = expr
		}
	else
		return parseNameExpr(self, "expression")
	end
end

-- primaryexp -> prefixexp { `.' NAME | `[' exp `]' | `:' NAME funcargs | funcargs }
function parsePrimaryExpr(self: Parser, asStatement: boolean): any
	local start = self.lexer.lexeme.location.begin
	local expr = parsePrefixExpr(self)

	local oldRecursion = self.recursionCounter

	while true do
		if self.lexer.lexeme.type == 46 then 
			local opPosition = self.lexer.lexeme.location.begin
			nextLexeme(self)

			local index = parseIndexName(self, nil, opPosition)

			expr = {
				kind = "ExprIndexName",
				location = {begin=start, end_=index.location.end_},
				expr = expr,
				index = index.name.value,
				indexLocation = index.location,
				opPosition = opPosition,
				op = 46 
			}
		elseif self.lexer.lexeme.type == 91 then 
			local matchBracket = self.lexer.lexeme
			nextLexeme(self)

			local index = parseExpr(self)
			local end_ = self.lexer.lexeme.location.end_

			expectMatchAndConsume(self, 93, matchBracket) 

			expr = {
				kind = "ExprIndexExpr",
				location = {begin=start, end_=end_},
				expr = expr,
				index = index
			}
		elseif self.lexer.lexeme.type == 58 then 
			local opPosition = self.lexer.lexeme.location.begin
			nextLexeme(self)

			local index = parseIndexName(self, "method name", opPosition)

			local func = {
				kind = "ExprIndexName",
				location = {begin=start, end_=index.location.end_},
				expr = expr,
				index = index.name.value,
				indexLocation = index.location,
				opPosition = opPosition,
				op = 58 
			}

			if ExplicitTypeExpressionInstantiation then
				local typeArgs = {}

				if self.lexer.lexeme.type == 60 and Lookahead(self.lexer).type == 60 then
					typeArgs = parseTypeInstantiationExpr(self)
				end

				expr = parseFunctionArgs(self, func, true)

				if #typeArgs > 0 then
					expr.typeArguments = typeArgs
				end
			else
				expr = parseFunctionArgs(self, func, true)
			end
		elseif self.lexer.lexeme.type == 40 then 
			-- This error is handled inside 'parseFunctionArgs' as well, but for better error recovery we need to break out the current loop here
			if not asStatement and expr.location.end_.line ~= self.lexer.lexeme.location.begin.line then
				reportAmbiguousCallError(self)
				break
			end
			expr = parseFunctionArgs(self, expr, false)
		elseif self.lexer.lexeme.type == 123 or 
			self.lexer.lexeme.type == Types.RawString or 
			self.lexer.lexeme.type == Types.QuotedString then
			expr = parseFunctionArgs(self, expr, false)
		elseif ExplicitTypeExpressionInstantiation and 
			self.lexer.lexeme.type == 60 and Lookahead(self.lexer).type == 60 then 
			expr = parseExplicitTypeInstantiationExpr(self, start, expr)
		else
			break
		end
		
		-- note: while the parser isn't recursive here, we're generating recursive structures of unbounded depth
		incrementRecursionCounter(self, "expression")
	end

	self.recursionCounter = oldRecursion
	return expr
end

-- asexp -> simpleexp [`::' Type]
function parseAssertionExpr(self: Parser)
	local start = self.lexer.lexeme.location
	local expr = parseSimpleExpr(self)

	if self.lexer.lexeme.type == Types.DoubleColon then
		nextLexeme(self)
		local annotation = parseType(self)
		return {
			kind = "ExprTypeAssertion",
			location = {
				begin = start.begin,
				end_ = annotation.location.end_
			},
			expr = expr,
			annotation = annotation
		}
	else
		return expr
	end
end

-- simpleexp -> NUMBER | STRING | NIL | true | false | ... | constructor | [attributes] FUNCTION body | primaryexp
function parseSimpleExpr(self: Parser): any
	local start = self.lexer.lexeme.location

	local attributes = {}

	if self.lexer.lexeme.type == Types.Attribute or self.lexer.lexeme.type == Types.AttributeOpen then
		attributes = parseAttributes(self)

		if self.lexer.lexeme.type ~= Types.ReservedFunction then
			return reportExprError(
				self,
				start,
				{},
				"Expected 'function' declaration after attribute, but got %s instead",
				ToString(self.lexer.lexeme)
			)
		end
	end

	if self.lexer.lexeme.type == Types.ReservedNil then
		nextLexeme(self)
		return {
			kind = "ExprConstantNil",
			location = start
		}
	elseif self.lexer.lexeme.type == Types.ReservedTrue then
		nextLexeme(self)
		return {
			kind = "ExprConstantBool",
			location = start,
			value = true
		}
	elseif self.lexer.lexeme.type == Types.ReservedFalse then
		nextLexeme(self)
		return {
			kind = "ExprConstantBool",
			location = start,
			value = false
		}
	elseif self.lexer.lexeme.type == Types.ReservedFunction then
		local matchFunction = self.lexer.lexeme
		nextLexeme(self)
		return parseFunctionBody(self, false, matchFunction, nil, nil, attributes)[1]
	elseif self.lexer.lexeme.type == Types.Number then
		return parseNumber(self)
	elseif self.lexer.lexeme.type == Types.RawString or self.lexer.lexeme.type == Types.QuotedString or self.lexer.lexeme.type == Types.InterpStringSimple then
		return parseString(self)
	elseif self.lexer.lexeme.type == Types.InterpStringBegin then
		return parseInterpString(self)
	elseif self.lexer.lexeme.type == Types.BrokenString then
		nextLexeme(self)
		return reportExprError(
			self, start, {}, "Malformed string; did you forget to finish it?"
		)
	elseif self.lexer.lexeme.type == Types.BrokenInterpDoubleBrace then
		nextLexeme(self)
		return reportExprError(
			self,
			start,
			{},
			"Double braces are not permitted within interpolated strings; did you mean '\\{'?"
		)
	elseif self.lexer.lexeme.type == Types.Dot3 then
		if self.functionStack[#self.functionStack].vararg then
			nextLexeme(self)
			return {
				kind = "ExprVarargs",
				location = start
			}
		else
			nextLexeme(self)
			return reportExprError(
				self,
				start,
				{},
				"Cannot use '...' outside of a vararg function"
			)
		end
	elseif self.lexer.lexeme.type == 123 then 
		return parseTableConstructor(self)
	elseif self.lexer.lexeme.type == Types.ReservedIf then
		return parseIfElseExpr(self)
	else
		return parsePrimaryExpr(self, false)
	end
end

-- args ::=  `(' [explist] `)' | tableconstructor | String
function parseFunctionArgs(

	self: Parser,
	func: any,
	selfCall: boolean

): any

	if self.lexer.lexeme.type == 40 then 
		local argStart = self.lexer.lexeme.location.end_
		if func.location.end_.line ~= self.lexer.lexeme.location.begin.line then
			reportAmbiguousCallError(self)
		end

		local matchParen = self.lexer.lexeme
		nextLexeme(self)

		local args = {}
		if self.lexer.lexeme.type ~= 41 then 
			parseExprList(self, args)
		end

		local end_ = self.lexer.lexeme.location
		expectMatchAndConsume(self, 41, matchParen)

		return {
			kind = "ExprCall",
			location = {begin=func.location.begin, end_=end_.end_},
			func = func,
			args = args,
			self = selfCall,
			typeArguments = {},
			argLocation = {begin=argStart, end_=end_.end_}
		}
	elseif self.lexer.lexeme.type == 123 then
		local argStart = self.lexer.lexeme.location.end_
		local expr = parseTableConstructor(self)
		local argEnd = self.lexer.prevLocation.end_

		return {
			kind = "ExprCall",
			location = {
				begin = func.location.begin,
				end_ = expr.location.end_
			},
			func = func,
			args = { expr },
			self = selfCall,
			typeArguments = {},
			argLocation = {
				begin = argStart,
				end_ = argEnd
			}
		}
	elseif self.lexer.lexeme.type == Types.RawString or self.lexer.lexeme.type == Types.QuotedString then
		local argLocation = self.lexer.lexeme.location
		local expr = parseString(self)

		return {
			kind = "ExprCall",
			location = {
				begin = func.location.begin,
				end_ = expr.location.end_
			},
			func = func,
			args = { expr },
			self = selfCall,
			typeArguments = {},
			argLocation = argLocation
		}
	else
		return reportFunctionArgsError(self, func, selfCall)
	end
end

function reportFunctionArgsError(self: Parser, func: any, selfCall: boolean)
	if selfCall and self.lexer.lexeme.location.begin.line ~= func.location.end_.line then
		return reportExprError(
			self,
			func.location :: Location,
			{func},
			"Expected function call arguments after '('"
		)
	else
		return reportExprError(
			self,
			{
				begin = func.location.begin,
				end_ = self.lexer.lexeme.location.begin
			},
			{func},
			"Expected '(', '{' or <string> when parsing function call, got %s",
			ToString(self.lexer.lexeme)
		)
	end
end

function reportAmbiguousCallError(self: Parser)
	Report(
		self,
		self.lexer.lexeme.location,
		"Ambiguous syntax: this looks like an argument list for a function call, but could also be a start of new statement; use ';' to separate statements"
	)
end

function parseIndexName(

	self: Parser,
	context: string?,
	prev: any

)

	local nameOpt = parseNameOpt(self, context)
	if nameOpt then return nameOpt end

	if self.lexer.lexeme.type >= Types.Reserved_BEGIN
		and self.lexer.lexeme.type < Types.Reserved_END and
		prev and self.lexer.lexeme.location.begin.line == prev.line then

		local result = {
			name = { value = self.lexer.lexeme.data },
			location = self.lexer.lexeme.location
		}

		nextLexeme(self)
		return result
	end

	return {
		name = { value = nameError },
		location = self.lexer.lexeme.location
	}
end

function parseCallList(self: Parser, commaPositions: any): any

	if self.lexer.lexeme.type == 40 then 
		local argStart = self.lexer.lexeme.location.end_
		local matchParen = self.lexer.lexeme

		nextLexeme(self)

		local args = {}

		if self.lexer.lexeme.type ~= 41 then
			parseExprList(self, args, commaPositions)
		end

		local end_ = self.lexer.lexeme.location
		expectMatchAndConsume(self, 41, matchParen)

		return {
			args,
			{
				begin = argStart,
				end_ = end_.end_
			},
			{
				begin = matchParen.location.begin,
				end_ = self.lexer.prevLocation.begin
			}
		}
	elseif self.lexer.lexeme.type == 123 then 
		local argStart = self.lexer.lexeme.location.end_
		local expr = parseTableConstructor(self)

		return {
			{expr},
			{
				begin=argStart,
				end_=self.lexer.prevLocation.end_
			},
			expr.location
		}
	else
		local argLoc = self.lexer.lexeme.location
		local expr = parseString(self)
		return { {expr}, argLoc, expr.location }
	end
end

-- tableconstructor ::= `{' [fieldlist] `}'
-- fieldlist ::= field {fieldsep field} [fieldsep]
-- field ::= `[' exp `]' `=' exp | Name `=' exp | exp
-- fieldsep ::= `,' | `;'
function parseTableConstructor(self: Parser): any
	local items = {} :: {any}
	local cstItems = {} 

	local start = self.lexer.lexeme.location

	local matchBrace = self.lexer.lexeme
	expectAndConsume(self, 123, "table literal") 

	local lastElementIndent = 0

	while self.lexer.lexeme.type ~= 125 do 
		lastElementIndent = self.lexer.lexeme.location.begin.column

		local indexerOpenPos = nil
		local indexerClosePos = nil
		local equalsPos = nil

		if self.lexer.lexeme.type == 91 then 
			indexerOpenPos = self.lexer.lexeme.location.begin
			local matchLocationBracket = self.lexer.lexeme
			nextLexeme(self)

			local key = parseExpr(self)

			indexerClosePos = self.lexer.lexeme.location.begin
			expectMatchAndConsume(self, 93, matchLocationBracket) 

			equalsPos = self.lexer.lexeme.location.begin
			expectAndConsume(self, 61, "table field") 

			local value = parseExpr(self)

			table.insert(items, {
				kind = "General",
				key = key,
				value = value
			})

			if self.options.storeCstData then
				table.insert(cstItems, {
					indexerOpenPosition = indexerOpenPos,
					indexerClosePosition = indexerClosePos,
					equalsPosition = equalsPos,
					separator = tableSeparator(self),
					separatorPosition = self.lexer.lexeme.location.begin
				})
			end

		elseif self.lexer.lexeme.type == Types.Name and Lookahead(self.lexer).type == 61 then 
			local name = parseName(self, "table field")

			equalsPos = self.lexer.lexeme.location.begin
			expectAndConsume(self, 61, "table field") 

			local key = {
				kind = "ExprConstantString",
				location = name.location,
				value = name.name.value,
				quoteStyle = 3 
			}

			local value = parseExpr(self)

			if value.kind == "ExprFunction" then
				value.debugname = name.name.value
			end

			table.insert(items, {
				kind = "Record",
				key = key,
				value = value
			})

			if self.options.storeCstData then
				table.insert(cstItems, {
					equalsPosition = equalsPos,
					separator = tableSeparator(self),
					separatorPosition = self.lexer.lexeme.location.begin
				})
			end
		else
			local expr = parseExpr(self)
			table.insert(items, {
				kind = "List",
				value = expr
			})

			if self.options.storeCstData then
				table.insert(cstItems, {
					separator = tableSeparator(self),
					separatorPosition = self.lexer.lexeme.location.begin
				})
			end
		end

		if self.lexer.lexeme.type == 44 or self.lexer.lexeme.type == 59 then 
			nextLexeme(self)
		elseif (self.lexer.lexeme.type == 91 or self.lexer.lexeme.type == Types.Name) and 
			self.lexer.lexeme.location.begin.column == lastElementIndent then
			Report(
				self,
				self.lexer.lexeme.location,
				"Expected ',' after table constructor element"
			)
		elseif self.lexer.lexeme.type ~= 125 then 
			break
		end
	end

	local end_ = self.lexer.lexeme.location
	if not expectMatchAndConsume(self, 125, matchBrace) then 
		end_ = self.lexer.prevLocation
	end

	local node = {
		kind = "ExprTable",
		location = {begin=start.begin, end_=end_.end_},
		items = items
	}

	if self.options.storeCstData then
		self.cstNodeMap[node] = {
			kind = "CstExprTable",
			items = cstItems
		}
	end

	return node
end

function parseIfElseExpr(self: Parser): any
	local hasElse = false
	local start = self.lexer.lexeme.location

	nextLexeme(self) -- skip if / elseif

	local condition = parseExpr(self)

	local thenPosition = self.lexer.lexeme.location.begin
	local hasThen = expectAndConsume(self, Types.ReservedThen, "if then else expression")

	local trueExpr = parseExpr(self)
	local falseExpr = nil

	local elsePosition = self.lexer.lexeme.location.begin
	local isElseIf = false

	if self.lexer.lexeme.type == Types.ReservedElseif then
		local oldRecursion = self.recursionCounter
		incrementRecursionCounter(self, "expression")
		hasElse = true
		falseExpr = parseIfElseExpr(self)
		self.recursionCounter = oldRecursion
		isElseIf = true
	else
		hasElse = expectAndConsume(self, Types.ReservedElse, "if then else expression")
		falseExpr = parseExpr(self)
	end

	local node = {
		kind = "ExprIfElse",
		location = {begin=start.begin, end_=falseExpr.location.end_},
		condition = condition,
		hasThen = hasThen,
		trueExpr = trueExpr,
		hasElse = hasElse,
		falseExpr = falseExpr
	}

	if self.options.storeCstData then
		self.cstNodeMap[node] = {
			kind = "CstExprIfElse",
			thenPosition = thenPosition,
			elsePosition = elsePosition,
			isElseIf = isElseIf
		}
	end

	return node
end

function parseInterpString(self: Parser): any
	local strings = {}
	local sourceStrings = {} 
	local stringPositions = {} 
	local expressions = {}

	local startLocation = self.lexer.lexeme.location
	local endLocation = nil

	while true do
		local currentLexeme = self.lexer.lexeme
		endLocation = currentLexeme.location

		local data = currentLexeme.data or ""

		if self.options.storeCstData then
			table.insert(sourceStrings, data) 
			table.insert(stringPositions, currentLexeme.location.begin)
		end

		local ok, fixedData = fixupQuotedString(data)
		if not ok then
			nextLexeme(self)
			return reportExprError(self, {begin=startLocation.begin, end_=endLocation.end_}, {}, "Interpolated string literal contains malformed escape sequence")
		end

		nextLexeme(self)
		table.insert(strings, fixedData)

		if currentLexeme.type == Types.InterpStringEnd or currentLexeme.type == Types.InterpStringSimple then
			break
		end

		local errorWhileChecking = false
		local t = self.lexer.lexeme.type

		if t == Types.InterpStringMid or t == Types.InterpStringEnd then
			errorWhileChecking = true
			nextLexeme(self)
			table.insert(expressions, reportExprError(self, endLocation, {}, "Malformed interpolated string, expected expression inside '{}'"))
		elseif t == Types.BrokenString then
			errorWhileChecking = true
			nextLexeme(self)
			table.insert(expressions, reportExprError(self, endLocation, {}, "Malformed interpolated string; did you forget to add a '`'?"))
		else
			table.insert(expressions, parseExpr(self))
		end

		if errorWhileChecking then break end

		t = self.lexer.lexeme.type
		if t == Types.InterpStringBegin or t == Types.InterpStringMid or t == Types.InterpStringEnd then

		elseif t == Types.BrokenInterpDoubleBrace then
			nextLexeme(self)
			return reportExprError(self, endLocation, {}, "Double braces are not permitted within interpolated strings; did you mean '\\{'?")
		elseif t == Types.BrokenString or t == Types.Eof then

			if t == Types.BrokenString then
				nextLexeme(self)
			end

			local node = {
				kind = "ExprInterpString",
				location = {begin=startLocation.begin, end_=self.lexer.prevLocation.end_},
				strings = strings,
				expressions = expressions
			}

			if self.options.storeCstData then
				self.cstNodeMap[node] = { kind = "CstExprInterpString", sourceStrings = sourceStrings, stringPositions = stringPositions }
			end

			local stack = self.lexer.braceStack
			local top = (#stack > 0) and stack[#stack] or nil

			if top then
				if top == Lexer.BraceType.InterpolatedString then
					Report(self, self.lexer.prevLocation, "Malformed interpolated string; did you forget to add a '}'?")
				end
			else
				Report(self, self.lexer.prevLocation, "Malformed interpolated string; did you forget to add a '`'?")
			end

			return node
		else
			return reportExprError(self, endLocation, {}, "Malformed interpolated string, got %s", ToString(self.lexer.lexeme))
		end
	end

	local node = {
		kind = "ExprInterpString",
		location = {
			begin = startLocation.begin,
			end_ = (endLocation :: Location).end_
		},
		strings = strings,
		expressions = expressions
	}

	if self.options.storeCstData then
		self.cstNodeMap[node] = { kind = "CstExprInterpString", sourceStrings = sourceStrings, stringPositions = stringPositions }
	end

	return node
end

function parseCharArray(self: Parser): string?
	local t = self.lexer.lexeme.type
	local data = self.lexer.lexeme.data or ""

	if t == Types.QuotedString or t == Types.InterpStringSimple then
		local ok, fixed = fixupQuotedString(data)
		if not ok then
			nextLexeme(self)
			return nil
		end
		data = fixed
	else
		data = fixupMultilineString(data)
	end

	nextLexeme(self)
	return data
end

function parseString(self: Parser): any
	local location = self.lexer.lexeme.location
	local quoteStyle = 0

	local t = self.lexer.lexeme.type
	if t == Types.QuotedString then
		if self.lexer.lexeme.aux == 0 then
			quoteStyle = 1 
		else
			quoteStyle = 0 
		end
	elseif t == Types.InterpStringSimple then
		quoteStyle = 0 
	elseif t == Types.RawString then
		quoteStyle = 2
	end

	local fullStyle = 0
	local blockDepth = 0
	if self.options.storeCstData then
		fullStyle, blockDepth = extractStringDetails(self)
	end

	local originalString = nil
	if self.options.storeCstData then
		originalString = self.lexer.lexeme.data 
	end

	local value = parseCharArray(self)

	if value then
		local node = {
			kind = "ExprConstantString",
			location = location,
			value = value,
			quoteStyle = quoteStyle
		}

		if self.options.storeCstData then
			self.cstNodeMap[node] = { 
				kind = "CstExprConstantString", 
				sourceString = originalString, 
				quoteStyle = fullStyle, 
				blockDepth = blockDepth 
			}
		end

		return node
	else
		return reportExprError(self, location, {}, "String literal contains malformed escape sequence")
	end
end

function parseNumber(self: Parser): any
	local start = self.lexer.lexeme.location
	local data = self.lexer.lexeme.data or ""

	local sourceData = nil
	if self.options.storeCstData then
		sourceData = data
	end

	local cleanData = string.gsub(data, "_", "")

	local value = tonumber(cleanData)
	local parseResult = "Ok"

	if value == nil then
		if string.find(cleanData, "^0[bB][01]+") then
			value = tonumber(string.sub(cleanData, 3), 2)
		end

		if value == nil then
			parseResult = "Malformed"
			value = 0
		end
	end

	nextLexeme(self)

	if value == nil then
		return reportExprError(self, start, {}, "Malformed number")
	end

	if math.abs(value) > 2^53 then
		if string.find(cleanData, "^%d+$") then
			local repr = string.format("%.0f", value)

			if repr ~= cleanData then
				parseResult = "Imprecise"
			end
		end
	end

	local node = {
		kind = "ExprConstantNumber",
		location = start,
		value = value,
		parseResult = parseResult
	}

	if self.options.storeCstData then
		self.cstNodeMap[node] = { kind = "CstExprConstantNumber", value = sourceData }
	end

	return node
end

-- // Explicit Type Instantiation 

function parseExplicitTypeInstantiationExpr(self: Parser, start: any, basedOnExpr: any)
	local typesOrPacks = parseTypeInstantiationExpr(self) 
	local endLocation = self.lexer.prevLocation 

	return {
		kind = "ExprInstantiate",
		location = {begin=start, end_=endLocation.end_},
		expr = basedOnExpr,
		typeArguments = typesOrPacks
	}
end

function parseTypeInstantiationExpr(self: Parser, cstNodeOut: any)
	local begin = self.lexer.lexeme
	nextLexeme(self)

	local typesOrPacks = parseTypeParams(self) 

	expectMatchAndConsume(self, 62, begin)

	return typesOrPacks
end

-- // DECLARATIONS (declare, extern, class, ...) // --

-- Syntax to define types for the analyzer without writing implementation code.

-- Luau only enables this syntax feature when it knows it is
-- parsing a Definition File (internal engine files or .d.luau files).

-- Currently pretty useless for real-world use case

function parseDeclaredExternTypeMethod(self: Parser, attributes: {any}): any
	local start = self.lexer.lexeme.location
	nextLexeme(self) 

	local fnName = parseName(self, "function name")
	
	-- TODO: generic method declarations CLI-39909
	local generics = {}
	local genericPacks = {}

	local matchParen = self.lexer.lexeme
	expectAndConsume(self, 40, "function parameter list start") 

	local args = {}
	local vararg = false
	local varargLocation = nil
	local varargAnnotation = nil

	if self.lexer.lexeme.type ~= 41 then 
		vararg, varargLocation, varargAnnotation = parseBindingList(self, args, true)
	end

	expectMatchAndConsume(self, 41, matchParen) 

	local retTypes = parseOptionalReturnType(self)
	if not retTypes then
		retTypes = {
			kind = "TypePackExplicit",
			location = self.lexer.lexeme.location,
			types = {}
		}
	end

	local end_ = self.lexer.prevLocation
	local vars = {}
	local varNames = {}

	if #args == 0 or args[1].name.value ~= "self" or args[1].annotation ~= nil then
		return {
			name = fnName.name,
			nameLocation = fnName.location,
			ty = reportTypeError(
				self,
				{begin = start.begin, end_ = end_.end_}, {},
				"'self' must be present as the unannotated first parameter"
			),
			isMethod = true,
			location = {
				begin = start.begin,
				end_ = end_.end_
			}
		}
	end

	-- Skip the first index.
	for i = 2, #args do
		table.insert(varNames, { name = args[i].name, location = args[i].name.location }) 
		if args[i].annotation then
			table.insert(vars, args[i].annotation)
		else
			table.insert(vars,
				reportTypeError(
					self,
					{begin=start.begin, end_=end_.end_}, {},
					"All declaration parameters aside from 'self' must be annotated"
				)
			)
		end
	end

	if vararg and not varargAnnotation then
		Report(
			self,
			start,
			"All declaration parameters aside from 'self' must be annotated"
		)
	end

	local fnType = {
		kind = "TypeFunction",
		location = {begin=start.begin, end_=end_.end_},
		attributes = attributes,
		generics = generics,
		genericPacks = genericPacks,
		argTypes = { types = vars, tailType = varargAnnotation },
		argNames = varNames,
		returnTypes = retTypes
	}

	return {
		name = fnName.name,
		nameLocation = fnName.location,
		ty = fnType,
		isMethod = true,
		location = {begin=start.begin, end_=end_.end_}
	}
end

function parseDeclaration(self: Parser, start: any, attributes: {any}): any
	-- `declare` token is already parsed at this point
	
	if #attributes > 0 and self.lexer.lexeme.type ~= Types.ReservedFunction then
		return reportStatError(
			self, 
			self.lexer.lexeme.location,
			{},
			{},
			"Expected a function type declaration after attribute, but got %s instead",
			ToString(self.lexer.lexeme)
		)
	end

	if self.lexer.lexeme.type == Types.ReservedFunction then
		nextLexeme(self)

		local globalName = parseName(self, "global function name")
		local genericsData = parseGenericTypeList(self, false)
		local generics, genericPacks = genericsData[1], genericsData[2]

		local matchParen = self.lexer.lexeme
		expectAndConsume(self, 40, "global function declaration") 

		local args = {}
		local vararg = false
		local varargLocation = nil
		local varargAnnotation = nil

		if self.lexer.lexeme.type ~= 41 then 
			vararg, varargLocation, varargAnnotation = parseBindingList(self, args, true)
		end

		expectMatchAndConsume(self, 41, matchParen) 

		local retTypes = parseOptionalReturnType(self)
		if not retTypes then
			retTypes = { kind = "TypePackExplicit", location = self.lexer.lexeme.location, types = {}}
		end
		local end_ = self.lexer.lexeme.location

		local vars = {}
		local varNames = {} :: {any}

		for i, arg in args do
			if not arg.annotation then
				return reportStatError(
					self,
					{begin = start.begin, end_ = end_.end_},
					{}, {},
					"All declaration parameters must be annotated"
				)
			end

			table.insert(vars, arg.annotation)
			table.insert(varNames, { name = arg.name, location = arg.name.location })
		end

		if vararg and not varargAnnotation then
			return reportStatError(self, {begin=start.begin, end_=end_.end_}, {}, {}, "All declaration parameters must be annotated")
		end

		return {
			kind = "StatDeclareFunction",
			location = {begin=start.begin, end_=end_.end_},
			attributes = attributes,
			name = globalName.name.value,
			nameLocation = globalName.location,
			generics = generics,
			genericPacks = genericPacks,
			params = { types = vars, tailType = varargAnnotation },
			paramNames = varNames,
			vararg = vararg,
			varargLocation = varargLocation,
			retTypes = retTypes
		}

	elseif self.lexer.lexeme.data == "class" or self.lexer.lexeme.data == "extern" then
		local foundExtern = false
		if self.lexer.lexeme.data == "extern" then
			foundExtern = true
			nextLexeme(self)
			if self.lexer.lexeme.data ~= "type" then
				return reportStatError(self, self.lexer.lexeme.location, {}, {}, "Expected `type` keyword after `extern`, but got %s instead", self.lexer.lexeme.data or "")
			end
		end

		nextLexeme(self) 

		local classStart = self.lexer.lexeme.location
		local className = parseName(self, "type name")
		local superName = nil

		if self.lexer.lexeme.data == "extends" then
			nextLexeme(self)
			local sn = parseName(self, "supertype name")
			superName = sn.name
		end

		if foundExtern then
			if self.lexer.lexeme.data ~= "with" then
				Report(
					self,
					self.lexer.lexeme.location,
					"Expected `with` keyword before listing properties of the external type, but got %s instead",
					self.lexer.lexeme.data or ""
				)
			else
				nextLexeme(self)
			end
		end

		local props = {}
		local indexer = nil

		while self.lexer.lexeme.type ~= Types.ReservedEnd do
			local propAttrs = {}

			if self.lexer.lexeme.type == Types.Attribute or self.lexer.lexeme.type == Types.AttributeOpen then
				propAttrs = parseAttributes(self)
				if self.lexer.lexeme.type ~= Types.ReservedFunction then
					return reportStatError(
						self,
						self.lexer.lexeme.location,
						{},
						{},
						"Expected a method type declaration after attribute, but got %s instead",
						ToString(self.lexer.lexeme :: Lexer.Lexeme)
					)
				end
			end
			
			-- There are two possibilities: Either it's a property or a function.
			if self.lexer.lexeme.type == Types.ReservedFunction then
				table.insert(props, parseDeclaredExternTypeMethod(self, propAttrs))
			elseif self.lexer.lexeme.type == 91 then
				local begin = self.lexer.lexeme
				nextLexeme(self)

				if (self.lexer.lexeme.type == Types.RawString or self.lexer.lexeme.type == Types.QuotedString) and Lookahead(self.lexer).type == 93 then
					local nameBegin = self.lexer.lexeme.location
					local chars = parseCharArray(self)
					local nameEnd = self.lexer.prevLocation

					expectMatchAndConsume(self, 93, begin)
					expectAndConsume(self, 58, "property type annotation")
					local type_ = parseType(self)

					if chars then
						table.insert(props, {
							name = { value = chars },
							nameLocation = {begin=nameBegin.begin, end_=nameEnd.end_},
							ty = type_,
							isMethod = false,
							location = {begin=begin.location.begin, end_=self.lexer.prevLocation.end_}
						})
					else
						Report(
							self,
							begin.location,
							"String literal contains malformed escape sequence or \\0"
						)
					end
				elseif indexer then
					-- maybe we don't need to parse the entire badIndexer...
					-- however, we either have { or [ to lint, not the entire table type or the bad indexer.
					local badIndexerRes = parseTableIndexer(self, "ReadWrite", nil, begin)
					-- we lose all additional indexer expressions from the AST after error recovery here
					Report(
						self,
						badIndexerRes.node.location,
						"Cannot have more than one indexer on an extern type"
					)
				else
					indexer = parseTableIndexer(self, "ReadWrite", nil, begin).node
				end
			else
				local propStart = self.lexer.lexeme.location
				local propName = parseNameOpt(self, "property name")

				if not propName then break end

				expectAndConsume(self, 58, "property type annotation")
				local propType = parseType(self)

				table.insert(props, {
					name = propName.name,
					nameLocation = propName.location,
					ty = propType,
					isMethod = false,
					location = {begin=propStart.begin, end_=self.lexer.prevLocation.end_}
				})
			end
		end

		local classEnd = self.lexer.lexeme.location
		nextLexeme(self)

		return {
			kind = "StatDeclareExternType",
			location = {begin=classStart.begin, end_=classEnd.end_},
			name = className.name.value,
			superName = superName and superName.value,
			props = props,
			indexer = indexer
		}

	else
		local globalName = parseNameOpt(self, "global variable name")
		if globalName then
			expectAndConsume(self, 58, "global variable declaration")
			local type_ = parseType(self, true)

			return {
				kind = "StatDeclareGlobal",
				location = {begin=start.begin, end_=type_.location.end_},
				name = globalName.name.value,
				nameLocation = globalName.location,
				type = type_
			}
		else
			return reportStatError(
				self,
				start,
				{},
				{},
				"declare must be followed by an identifier, 'function', or 'extern type'"
			)
		end
	end
end

return {
	parse = function(source: string, options: Options?): any
		local parser = constructParser(source, options or {} :: Options)

		local success, root = pcall(parseChunk, parser)
		local errors = parser.parseErrors

		return success and #errors == 0, {
			root = root,

			commentLocations = parser.commentLocations,
			hotcomments = parser.hotcomments,
			cstNodeMap = parser.cstNodeMap,
			errors = errors,
		}
	end
}
