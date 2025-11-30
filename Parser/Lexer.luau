--!strict
--!optimize 2
--!native

local findConfusable = require('./findConfusable')

local BraceType = {
	InterpolatedString = 0,
	Normal = 1
}

local QuoteStyle = {
	Single = 0,
	Double = 1,
}

local ReadNext = nil

type AstName = string?

local kReserved = {
	"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in",
	"local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"
}

export type Position = {
	line: number,
	column: number,
}

export type Location = {
	begin: Position,
	end_: Position,
}

export type Lexeme = {
	type: number,
	location: Location,
	length: number,
	data: string?, 
	codepoint: number?,
	aux: number?,
}

type NameTable = {
	[string]: { value: string, type: number, length: number }
}

export type Lexer = {
	buffer: buffer,
	bufferSize: number,
	offset: number,
	line: number,
	lineOffset: number,
	lexeme: Lexeme,
	prevLocation: Location,
	names: NameTable,
	skipComments: boolean,
	readNames: boolean,
	braceStack: {number},
}

local Types = {
	Eof = 0,
	Char_END = 256,
	Equal = 257,
	LessEqual = 258,
	GreaterEqual = 259,
	NotEqual = 260,
	Dot2 = 261,
	Dot3 = 262,
	SkinnyArrow = 263,
	DoubleColon = 264,
	FloorDiv = 265,
	InterpStringBegin = 266,
	InterpStringMid = 267,
	InterpStringEnd = 268,
	InterpStringSimple = 269,
	AddAssign = 270,
	SubAssign = 271,
	MulAssign = 272,
	DivAssign = 273,
	FloorDivAssign = 274,
	ModAssign = 275,
	PowAssign = 276,
	ConcatAssign = 277,
	RawString = 278,
	QuotedString = 279,
	Number = 280,
	Name = 281,
	Comment = 282,
	BlockComment = 283,
	Attribute = 284,
	AttributeOpen = 285,
	BrokenString = 286,
	BrokenComment = 287,
	BrokenUnicode = 288,
	BrokenInterpDoubleBrace = 289,
	Error = 290,
	Reserved_BEGIN = 291,
	ReservedAnd = 291,
	ReservedBreak = 292,
	ReservedDo = 293,
	ReservedElse = 294,
	ReservedElseif = 295,
	ReservedEnd = 296,
	ReservedFalse = 297,
	ReservedFor = 298,
	ReservedFunction = 299,
	ReservedIf = 300,
	ReservedIn = 301,
	ReservedLocal = 302,
	ReservedNil = 303,
	ReservedNot = 304,
	ReservedOr = 305,
	ReservedRepeat = 306,
	ReservedReturn = 307,
	ReservedThen = 308,
	ReservedTrue = 309,
	ReservedUntil = 310,
	ReservedWhile = 311,
	Reserved_END = 312
}

local function PositionNew(line: number, column: number): Position
	return {line = line, column = column}
end

local function newFromPositions(beginPos: Position, endPos: Position): Location
	return {
		begin = {line = beginPos.line, column = beginPos.column},
		end_ = {line = endPos.line, column = endPos.column}
	}
end

local function newFromLength(beginPos: Position, length: number): Location
	return {
		begin = {line = beginPos.line, column = beginPos.column},
		end_ = {line = beginPos.line, column = beginPos.column + length}
	}
end

-- We do it the most performant way

local HexDigits = {}
local Digits = {}
local Alpha = {}

local Spaces = {
	[9] = true,
	[10] = true,
	[11] = true,
	[12] = true,
	[13] = true,
	[32] = true,
}

for i = 48, 57 do
	HexDigits[i] = true
	Digits[i] = true
end

for i = 65, 90 do
	if i <= 70 then HexDigits[i] = true end
	
	Alpha[i] = true
end

for i = 97, 122 do
	if i <= 102 then HexDigits[i] = true end
	
	Alpha[i] = true
end

local function constructLexeme(location: Location, type: number): Lexeme
	return {
		location = location,
		length = 0,
		type = type,
	}
end

local function newFromChar(location: Location, char: number): Lexeme
	return {
		location = location,
		length = 0,
		type = char,
	}
end

local function newFromData(location: Location, type: number, data: string, size: number): Lexeme
	return {
		location = location,
		length = size,
		type = type,
		data = data,
	}
end

local function newFromName(location: Location, type: number, name: string?): Lexeme
	return {
		location = location,
		length = 0,
		type = type,
		data = name,
	}
end

local function ToString(self: Lexeme): string
	local t = self.type
	if t == Types.Eof then
		return "<eof>"
	elseif t == Types.Equal then
		return "'=='"
	elseif t == Types.LessEqual then
		return "'<='"
	elseif t == Types.GreaterEqual then
		return "'>='"
	elseif t == Types.NotEqual then
		return "'~='"
	elseif t == Types.Dot2 then
		return "'..'"
	elseif t == Types.Dot3 then
		return "'...'"
	elseif t == Types.SkinnyArrow then
		return "'->'"
	elseif t == Types.DoubleColon then
		return "'::'"
	elseif t == Types.FloorDiv then
		return "'//'"
	elseif t == Types.AddAssign then
		return "'+='"
	elseif t == Types.SubAssign then
		return "'-='"
	elseif t == Types.MulAssign then
		return "'*='"
	elseif t == Types.DivAssign then
		return "'/='"
	elseif t == Types.FloorDivAssign then
		return "'//='"
	elseif t == Types.ModAssign then
		return "'%='"
	elseif t == Types.PowAssign then
		return "'^='"
	elseif t == Types.ConcatAssign then
		return "'..='"
	elseif t == Types.RawString or t == Types.QuotedString then
		if self.data then
			return `"{self.data}"`
		else
			return "string"
		end
	elseif t == Types.InterpStringBegin then
		if self.data then
			return `\`{self.data}\{`
		else
			return "the beginning of an interpolated string"
		end
	elseif t == Types.InterpStringMid then
		if self.data then
			return `\}{self.data}\{`
		else
			return "the middle of an interpolated string"
		end
	elseif t == Types.InterpStringEnd then
		if self.data then
			return `\}{self.data}\``
		else
			return "the end of an interpolated string"
		end
	elseif t == Types.InterpStringSimple then
		if self.data then
			return `\`{self.data}\``
		else
			return "interpolated string"
		end
	elseif t == Types.Number then
		if self.data then
			return `'{self.data}'`
		else
			return "number"
		end
	elseif t == Types.Name then
		if self.data then
			return `'{self.data}'`
		else
			return "identifier"
		end
	elseif t == Types.Comment then
		return "comment"
	elseif t == Types.Attribute then
		if self.data then
			return `'{self.data}'`
		else
			return "attribute"
		end
	elseif t == Types.AttributeOpen then
		return "'@['"
	elseif t == Types.BrokenString then
		return "malformed string"
	elseif t == Types.BrokenComment then
		return "unfinished comment"
	elseif t == Types.BrokenInterpDoubleBrace then
		return "'{{', which is invalid (did you mean '\\{'?)"
	elseif t == Types.BrokenUnicode then
		if self.codepoint then
			local confusable = findConfusable(self.codepoint)
			if confusable then
				return string.format("Unicode character U+%x (did you mean '%s'?)", self.codepoint, confusable)
			end
			return string.format("Unicode character U+%x", self.codepoint)
		else
			return "invalid UTF-8 sequence"
		end
	else
		if t < Types.Char_END then
			return string.format("'%c'", t)
		elseif t >= Types.Reserved_BEGIN and t < Types.Reserved_END then
			return `'{kReserved[t - Types.Reserved_BEGIN + 1]}'`
		else
			return "<unknown>"
		end
	end
end

local function getOrAddWithType(data: NameTable, name: string, length: number): (AstName, number)
	local actualName = name
	if #name ~= length then
		actualName = string.sub(name, 1, length)
	end

	local entry = data[actualName]
	if entry and entry.type ~= Types.Eof then
		return entry.value, entry.type
	end

	local type_ = Types.Name
	if string.byte(actualName, 1) == 64 then -- '@'
		type_ = Types.Attribute
	end

	entry = { value = actualName, length = length, type = type_ }
	data[actualName] = entry

	return entry.value, entry.type
end

local function getWithType(data: NameTable, name: string, length: number): (AstName, number)
	local actualName = name
	if #name ~= length then
		actualName = string.sub(name, 1, length)
	end

	local entry = data[actualName]
	if entry then
		return entry.value, entry.type
	end
	return nil, Types.Name
end

local function constructLexer(buf: buffer | string, skipComments: boolean?, startPosition: Position?): Lexer
	local self = {}
	
	local s = buf :: string
	local b = buffer.fromstring(s)
	
	self.buffer = b
	self.bufferSize = #s
	
	local data = {}
	
	for i = 0, Types.Reserved_END - Types.Reserved_BEGIN - 1 do
		local typeVal = Types.Reserved_BEGIN + i
		local name = kReserved[i + 1]
		
		data[name] = { value = name, length = #name, type = typeVal }
	end

	self.names = data
	self.offset = 0

	local startLine = 0
	local startCol = 0
	if startPosition then
		startLine = startPosition.line
		startCol = startPosition.column
	end

	self.line = startLine
	self.lineOffset = 0 - startCol 

	self.lexeme = constructLexeme(newFromPositions(PositionNew(startLine, startCol), PositionNew(startLine, startCol)), Types.Eof)

	self.prevLocation = {
		begin = {line = 0, column = 0},
		end_ = {line = 0, column = 0}
	}

	self.skipComments = if skipComments ~= nil then skipComments else false
	self.readNames = true
	self.braceStack = {}

	return self :: Lexer
end

local function Peekch(self: Lexer, lookahead: number?): number
	local la = lookahead or 0
	if self.offset + la < self.bufferSize then
		return buffer.readu8(self.buffer, self.offset + la)
	end
	return 0
end

local function consumeAny(self: Lexer)
	if buffer.readu8(self.buffer, self.offset) == 10 then
		self.line += 1
		self.lineOffset = self.offset + 1
	end
	self.offset += 1
end

local function Next(self: Lexer, skipComments: boolean?, updatePrevLocation: boolean?): Lexeme
	local sc = if skipComments ~= nil then skipComments else self.skipComments
	local upl = if updatePrevLocation ~= nil then updatePrevLocation else true
	
	while true do
		while Spaces[Peekch(self)] do
			consumeAny(self)
		end

		if upl then
			self.prevLocation = self.lexeme.location
		end
		
		self.lexeme = ReadNext(self)
		upl = false

		local lextype = self.lexeme.type
		if not (sc and (lextype == Types.Comment or lextype == Types.BlockComment)) then
			break
		end
	end

	return self.lexeme
end

local function Lookahead(self: Lexer): Lexeme
	local currentOffset = self.offset
	local currentLine = self.line
	local currentLineOffset = self.lineOffset
	local currentLexeme = self.lexeme
	local currentPrevLocation = self.prevLocation
	local currentBraceStackSize = #self.braceStack
	local currentBraceType = BraceType.Normal
	if #self.braceStack > 0 then currentBraceType = self.braceStack[#self.braceStack] end

	local result = Next(self)

	self.offset = currentOffset
	self.line = currentLine
	self.lineOffset = currentLineOffset
	self.lexeme = currentLexeme
	self.prevLocation = currentPrevLocation

	while #self.braceStack > currentBraceStackSize do
		table.remove(self.braceStack)
	end
	while #self.braceStack < currentBraceStackSize do
		table.insert(self.braceStack, currentBraceType)
	end

	return result
end

local function Pos(self: Lexer): Position
	return PositionNew(self.line, self.offset - self.lineOffset)
end

local function skipLongSeparator(self: Lexer): number
	local start = Peekch(self)
	assert(start == 91 or start == 93) 
	self.offset += 1

	local count = 0
	while Peekch(self) == 61 do 
		self.offset += 1
		count += 1
	end

	if start == Peekch(self) then
		return count
	else
		return -count - 1
	end
end

local function readLongString(self: Lexer, start: Position, sep: number, ok: number, broken: number): Lexeme
	assert(Peekch(self) == 91) 
	self.offset += 1 

	local startOffset = self.offset

	while Peekch(self) ~= 0 do
		if Peekch(self) == 93 then 
			if skipLongSeparator(self) == sep then
				assert(Peekch(self) == 93)
				self.offset += 1

				local endOffset = self.offset - sep - 2
				assert(endOffset >= startOffset)

				local l = newFromData(newFromPositions(start, Pos(self)), ok, buffer.readstring(self.buffer, startOffset, endOffset - startOffset), endOffset - startOffset)
				l.aux = sep 
				return l
			end
		else
			consumeAny(self)
		end
	end

	return constructLexeme(newFromPositions(start, Pos(self)), broken)
end

local function readCommentBody(self: Lexer): Lexeme
	local start = Pos(self)

	assert(Peekch(self, 0) == 45 and Peekch(self, 1) == 45) 
	self.offset += 2

	local startOffset = self.offset

	if Peekch(self) == 91 then -- '['
		local sep = skipLongSeparator(self)
		if sep >= 0 then
			return readLongString(self, start, sep, Types.BlockComment, Types.BrokenComment)
		end
	end

	while true do
		local ch = Peekch(self)
		if ch == 0 or ch == 13 or ch == 10 then break end
		self.offset += 1
	end

	return newFromData(newFromPositions(start, Pos(self)), Types.Comment, buffer.readstring(self.buffer, startOffset, self.offset - startOffset), self.offset - startOffset)
end

local function readBackslashInString(self: Lexer)
	assert(Peekch(self) == 92) 
	self.offset += 1
	local ch = Peekch(self)

	if ch == 13 then 
		self.offset += 1
		if Peekch(self) == 10 then consumeAny(self) end
	elseif ch == 122 then 
		self.offset += 1
		while Spaces[Peekch(self)] do
			consumeAny(self)
		end
	else
		consumeAny(self)
	end
end

local function readQuotedString(self: Lexer): Lexeme
	local start = Pos(self)
	local delimiter = Peekch(self)
	assert(delimiter == 39 or delimiter == 34) 
	self.offset += 1

	local startOffset = self.offset

	while Peekch(self) ~= delimiter do
		local ch = Peekch(self)
		if ch == 0 or ch == 13 or ch == 10 then
			return constructLexeme(newFromPositions(start, Pos(self)), Types.BrokenString)
		elseif ch == 92 then 
			readBackslashInString(self)
		else
			self.offset += 1
		end
	end

	self.offset += 1

	local l = newFromData(newFromPositions(start, Pos(self)), Types.QuotedString, buffer.readstring(self.buffer, startOffset, self.offset - startOffset - 1), self.offset - startOffset - 1)
	l.aux = if delimiter == 39 then QuoteStyle.Single else QuoteStyle.Double

	return l
end

local function readInterpolatedStringSection(self: Lexer, start: Position, formatType: number, endType: number): Lexeme
	local startOffset = self.offset

	while Peekch(self) ~= 96 do 
		local ch = Peekch(self)
		if ch == 0 or ch == 13 or ch == 10 then
			return constructLexeme(newFromPositions(start, Pos(self)), Types.BrokenString)
		elseif ch == 92 then 
			if Peekch(self, 1) == 117 and Peekch(self, 2) == 123 then 
				self.offset += 3
			else
				readBackslashInString(self)
			end
		elseif ch == 123 then 
			table.insert(self.braceStack, BraceType.InterpolatedString)

			if Peekch(self, 1) == 123 then 
				local brokenDoubleBrace = newFromData(newFromPositions(start, Pos(self)), Types.BrokenInterpDoubleBrace, buffer.readstring(self.buffer, startOffset, self.offset - startOffset), self.offset - startOffset)
				self.offset += 2
				return brokenDoubleBrace
			end

			self.offset += 1
			return newFromData(newFromPositions(start, Pos(self)), formatType, buffer.readstring(self.buffer, startOffset, self.offset - startOffset - 1), self.offset - startOffset - 1)
		else
			self.offset += 1
		end
	end

	self.offset += 1
	return newFromData(newFromPositions(start, Pos(self)), endType, buffer.readstring(self.buffer, startOffset, self.offset - startOffset - 1), self.offset - startOffset - 1)
end

local function readInterpolatedStringBegin(self: Lexer): Lexeme
	assert(Peekch(self) == 96) 
	local start = Pos(self)
	self.offset += 1
	return readInterpolatedStringSection(self, start, Types.InterpStringBegin, Types.InterpStringSimple)
end

local function readNumber(self: Lexer, start: Position, startOffset: number): Lexeme
	assert(Digits[Peekch(self)])

	repeat
		self.offset += 1
		local ch = Peekch(self)
	until not (Digits[ch] or ch == 46 or ch == 95)

	local ch = Peekch(self)
	if ch == 101 or ch == 69 then 
		self.offset += 1
		local nextCh = Peekch(self)
		if nextCh == 43 or nextCh == 45 then 
			self.offset += 1
		end
	end

	while true do
		local c = Peekch(self)
		if not (Alpha[c] or Digits[c] or c == 95) then break end
		self.offset += 1
	end

	return newFromData(newFromPositions(start, Pos(self)), Types.Number, buffer.readstring(self.buffer, startOffset, self.offset - startOffset), self.offset - startOffset)
end

local function readName(self: Lexer): (AstName, number)
	local ch = Peekch(self)
	assert(Alpha[ch] or ch == 95 or ch == 64)

	local startOffset = self.offset
	repeat
		self.offset += 1
		ch = Peekch(self)
	until not (Alpha[ch] or Digits[ch] or ch == 95)

	local name = buffer.readstring(self.buffer, startOffset, self.offset - startOffset)
	
	local names = self.names
	if self.readNames then
		return getOrAddWithType(names, name, #name)
	else
		return getWithType(names, name, #name)
	end
end

function ReadNext(self: Lexer): Lexeme
	local start = Pos(self)
	local ch = Peekch(self)

	if ch == 0 then
		return constructLexeme(newFromLength(start, 0), Types.Eof)
	elseif ch == 45 then 
		if Peekch(self, 1) == 62 then 
			self.offset += 2
			return constructLexeme(newFromLength(start, 2), Types.SkinnyArrow)
		elseif Peekch(self, 1) == 61 then 
			self.offset += 2
			return constructLexeme(newFromLength(start, 2), Types.SubAssign)
		elseif Peekch(self, 1) == 45 then 
			return readCommentBody(self)
		else
			self.offset += 1
			return newFromChar(newFromLength(start, 1), 45)
		end
	elseif ch == 91 then 
		local sep = skipLongSeparator(self)
		if sep >= 0 then
			return readLongString(self, start, sep, Types.RawString, Types.BrokenString)
		elseif sep == -1 then
			return newFromChar(newFromLength(start, 1), 91)
		else
			return constructLexeme(newFromPositions(start, Pos(self)), Types.BrokenString)
		end
	elseif ch == 123 then 
		self.offset += 1
		if #self.braceStack > 0 then
			table.insert(self.braceStack, BraceType.Normal)
		end
		return newFromChar(newFromLength(start, 1), 123)
	elseif ch == 125 then 
		self.offset += 1
		if #self.braceStack == 0 then
			return newFromChar(newFromLength(start, 1), 125)
		end
		local braceStackTop = self.braceStack[#self.braceStack]
		table.remove(self.braceStack)
		if braceStackTop ~= BraceType.InterpolatedString then
			return newFromChar(newFromLength(start, 1), 125)
		end
		return readInterpolatedStringSection(self, start, Types.InterpStringMid, Types.InterpStringEnd)
	elseif ch == 61 then 
		self.offset += 1
		if Peekch(self) == 61 then
			self.offset += 1
			return constructLexeme(newFromLength(start, 2), Types.Equal)
		else
			return newFromChar(newFromLength(start, 1), 61)
		end
	elseif ch == 60 then 
		self.offset += 1
		if Peekch(self) == 61 then
			self.offset += 1
			return constructLexeme(newFromLength(start, 2), Types.LessEqual)
		else
			return newFromChar(newFromLength(start, 1), 60)
		end
	elseif ch == 62 then 
		self.offset += 1
		if Peekch(self) == 61 then
			self.offset += 1
			return constructLexeme(newFromLength(start, 2), Types.GreaterEqual)
		else
			return newFromChar(newFromLength(start, 1), 62)
		end
	elseif ch == 126 then 
		self.offset += 1
		if Peekch(self) == 61 then
			self.offset += 1
			return constructLexeme(newFromLength(start, 2), Types.NotEqual)
		else
			return newFromChar(newFromLength(start, 1), 126)
		end
	elseif ch == 34 or ch == 39 then 
		return readQuotedString(self)
	elseif ch == 96 then 
		return readInterpolatedStringBegin(self)
	elseif ch == 46 then 
		self.offset += 1
		if Peekch(self) == 46 then
			self.offset += 1
			if Peekch(self) == 46 then
				self.offset += 1
				return constructLexeme(newFromLength(start, 3), Types.Dot3)
			elseif Peekch(self) == 61 then
				self.offset += 1
				return constructLexeme(newFromLength(start, 3), Types.ConcatAssign)
			else
				return constructLexeme(newFromLength(start, 2), Types.Dot2)
			end
		else
			if Digits[Peekch(self)] then
				return readNumber(self, start, self.offset - 1)
			else
				return newFromChar(newFromLength(start, 1), 46)
			end
		end
	elseif ch == 43 then 
		self.offset += 1
		if Peekch(self) == 61 then
			self.offset += 1
			return constructLexeme(newFromLength(start, 2), Types.AddAssign)
		else
			return newFromChar(newFromLength(start, 1), 43)
		end
	elseif ch == 47 then 
		self.offset += 1
		local c = Peekch(self)
		if c == 61 then
			self.offset += 1
			return constructLexeme(newFromLength(start, 2), Types.DivAssign)
		elseif c == 47 then
			self.offset += 1
			if Peekch(self) == 61 then
				self.offset += 1
				return constructLexeme(newFromLength(start, 3), Types.FloorDivAssign)
			else
				return constructLexeme(newFromLength(start, 2), Types.FloorDiv)
			end
		else
			return newFromChar(newFromLength(start, 1), 47)
		end
	elseif ch == 42 then 
		self.offset += 1
		if Peekch(self) == 61 then
			self.offset += 1
			return constructLexeme(newFromLength(start, 2), Types.MulAssign)
		else
			return newFromChar(newFromLength(start, 1), 42)
		end
	elseif ch == 37 then 
		self.offset += 1
		if Peekch(self) == 61 then
			self.offset += 1
			return constructLexeme(newFromLength(start, 2), Types.ModAssign)
		else
			return newFromChar(newFromLength(start, 1), 37)
		end
	elseif ch == 94 then 
		self.offset += 1
		if Peekch(self) == 61 then
			self.offset += 1
			return constructLexeme(newFromLength(start, 2), Types.PowAssign)
		else
			return newFromChar(newFromLength(start, 1), 94)
		end
	elseif ch == 58 then 
		self.offset += 1
		if Peekch(self) == 58 then
			self.offset += 1
			return constructLexeme(newFromLength(start, 2), Types.DoubleColon)
		else
			return newFromChar(newFromLength(start, 1), 58)
		end
	elseif ch == 40 or ch == 41 or ch == 93 or ch == 59 or ch == 44 or ch == 35 or ch == 63 or ch == 38 or ch == 124 then
		self.offset += 1
		return newFromChar(newFromLength(start, 1), ch)
	elseif ch == 64 then 
		if Peekch(self, 1) == 91 then 
			self.offset += 2
			return constructLexeme(newFromLength(start, 2), Types.AttributeOpen)
		else
			self.offset += 1
			local nextCh = Peekch(self)
			if Alpha[nextCh] or nextCh == 95 then
				local name, type_ = readName(self)
				return newFromName(newFromPositions(start, Pos(self)), Types.Attribute, name)
			else
				return newFromName(newFromPositions(start, Pos(self)), Types.Attribute, "")
			end
		end
	else
		if Digits[ch] then
			return readNumber(self, start, self.offset)
		elseif Alpha[ch] or ch == 95 then
			local name, type_ = readName(self)
			return newFromName(newFromPositions(start, Pos(self)), type_, name)
		elseif bit32.band(ch, 0x80) ~= 0 then
			local start = Pos(self)
			local codepoint = 0
			local size = 0
			local ch = Peekch(self)

			if bit32.band(ch, 0x80) == 0x00 then
				size = 1
				codepoint = bit32.band(ch, 0x7F)
			elseif bit32.band(ch, 0xE0) == 0xC0 then
				size = 2
				codepoint = bit32.band(ch, 0x1F)
			elseif bit32.band(ch, 0xF0) == 0xE0 then
				size = 3
				codepoint = bit32.band(ch, 0x0F)
			elseif bit32.band(ch, 0xF8) == 0xF0 then
				size = 4
				codepoint = bit32.band(ch, 0x07)
			else
				self.offset += 1
				return constructLexeme(newFromPositions(start, Pos(self)), Types.BrokenUnicode)
			end

			self.offset += 1

			for i = 2, size do
				ch = Peekch(self)
				if bit32.band(ch, 0xC0) ~= 0x80 then
					return constructLexeme(newFromPositions(start, Pos(self)), Types.BrokenUnicode)
				end

				codepoint = bit32.lshift(codepoint, 6)
				codepoint = bit32.bor(codepoint, bit32.band(ch, 0x3F))
				self.offset += 1
			end

			local l = constructLexeme(newFromPositions(start, Pos(self)), Types.BrokenUnicode)
			l.codepoint = codepoint
			return l
		else
			self.offset += 1
			return newFromChar(newFromLength(start, 1), ch)
		end
	end
end

local function fixupQuotedString(data: string): (boolean, string?)
	if #data == 0 or not string.find(data, "\\") then
		return true, data
	end

	local size = #data
	local src = buffer.fromstring(data)
	local buf = buffer.create(size) -- Result is always <= size of source
	local write = 0
	local i = 0

	while i < size do
		local ch = buffer.readu8(src, i)

		if ch ~= 92 then -- not '\'
			buffer.writeu8(buf, write, ch)
			write += 1
			i += 1
			continue
		end

		if i + 1 == size then
			return false, nil -- Trailing backslash
		end

		local escape = buffer.readu8(src, i + 1)
		i += 2 -- skip \ and the escape char

		if escape == 10 then -- \n
			buffer.writeu8(buf, write, 10)
			write += 1
		elseif escape == 13 then -- \r
			buffer.writeu8(buf, write, 10) -- normalize to \n
			write += 1
			if i < size and buffer.readu8(src, i) == 10 then
				i += 1
			end
		elseif escape == 0 then
			return false, nil
		elseif escape == 120 then -- 'x'
			-- hex escape codes are exactly 2 hex digits long
			if i + 2 > size then
				return false, nil
			end

			local code = 0
			for j = 0, 1 do
				local c = buffer.readu8(src, i + j)
				if not HexDigits[c] then
					return false, nil
				end
				-- (ch | ' ') - 'a' + 10 trick
				local hexVal = if Digits[c] then c - 48 else bit32.bor(c, 32) - 97 + 10
				code = 16 * code + hexVal
			end

			buffer.writeu8(buf, write, code)
			write += 1
			i += 2
		elseif escape == 122 then -- 'z'
			while i < size and Spaces[buffer.readu8(src, i)] do
				i += 1
			end
		elseif escape == 117 then -- 'u'
			-- unicode escape codes \u{...}
			if i + 3 > size then return false, nil end
			if buffer.readu8(src, i) ~= 123 then return false, nil end -- '{'
			i += 1

			if buffer.readu8(src, i) == 125 then return false, nil end -- Empty \u{}? C++ implies failure if immediate '}'

			local code = 0
			local ended = false

			for j = 0, 15 do
				if i == size then return false, nil end
				local c = buffer.readu8(src, i)

				if c == 125 then -- '}'
					ended = true
					break
				end

				if not HexDigits[c] then
					return false, nil
				end

				local hexVal = if Digits[c] then c - 48 else bit32.bor(c, 32) - 97 + 10
				code = 16 * code + hexVal
				i += 1
			end

			if not ended then
				-- Check if we finished loop but didn't find '}'
				if i == size or buffer.readu8(src, i) ~= 125 then
					return false, nil
				end
			end
			i += 1 -- skip '}'

			-- Convert code to UTF8
			if code < 0x80 then
				buffer.writeu8(buf, write, code)
				write += 1
			elseif code < 0x800 then
				buffer.writeu8(buf, write, bit32.bor(0xC0, bit32.rshift(code, 6)))
				buffer.writeu8(buf, write + 1, bit32.bor(0x80, bit32.band(code, 0x3F)))
				write += 2
			elseif code < 0x10000 then
				-- Basic Multilingual Plane
				buffer.writeu8(buf, write, bit32.bor(0xE0, bit32.rshift(code, 12)))
				buffer.writeu8(buf, write + 1, bit32.bor(0x80, bit32.band(bit32.rshift(code, 6), 0x3F)))
				buffer.writeu8(buf, write + 2, bit32.bor(0x80, bit32.band(code, 0x3F)))
				write += 3
			elseif code < 0x110000 then
				-- Supplementary Planes
				buffer.writeu8(buf, write, bit32.bor(0xF0, bit32.rshift(code, 18)))
				buffer.writeu8(buf, write + 1, bit32.bor(0x80, bit32.band(bit32.rshift(code, 12), 0x3F)))
				buffer.writeu8(buf, write + 2, bit32.bor(0x80, bit32.band(bit32.rshift(code, 6), 0x3F)))
				buffer.writeu8(buf, write + 3, bit32.bor(0x80, bit32.band(code, 0x3F)))
				write += 4
			else
				return false, nil -- Invalid unicode codepoint
			end
		else
			if Digits[escape] then
				local code = escape - 48

				-- Read up to 2 more digits
				for j = 0, 1 do
					if i == size then break end
					local c = buffer.readu8(src, i)
					if not Digits[c] then break end
					code = 10 * code + (c - 48)
					i += 1
				end

				if code > 255 then
					return false, nil
				end

				buffer.writeu8(buf, write, code)
				write += 1
			else
				local escaped =
					
					if escape == 97 then 7
					elseif escape == 98 then 8
					elseif escape == 102 then 12
					elseif escape == 110 then 10
					elseif escape == 114 then 13
					elseif escape == 116 then 9
					elseif escape == 118 then 11
					else escape
				
				buffer.writeu8(buf, write, escaped)
				write += 1
			end
		end
	end

	return true, buffer.readstring(buf, 0, write)
end

local function fixupMultilineString(data: string): string
	if #data == 0 then
		return data
	end
	
	data = string.gsub(data, "^\r?\n", "")
	data = string.gsub(data, "\r\n", "\n")
	
	return data
end

return {
	constructLexeme = constructLexeme,
	constructLexer = constructLexer,
	
	ToString = ToString,
	
	fixupQuotedString = fixupQuotedString,
	fixupMultilineString = fixupMultilineString,
	
	Lookahead = Lookahead,
	ReadNext = ReadNext,
	Next = Next,
	
	QuoteStyle = QuoteStyle,
	BraceType = BraceType,
	Types = Types,
}
