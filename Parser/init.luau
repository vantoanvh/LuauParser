--!optimize 2
--!strict
--!native

-- // Parser Settings

const LuauIntegerType2 = false
const LuauExportValueSyntax = false
const DebugLuauNoInline = false
const DebugLuauUserDefinedClasses = false
const LuauAllowGlobalDeclarationToBeCalledClass = false
const LuauDisallowExternClassInTypeDefinitions = false
const LuauTableEntriesDontNeedToMatchIndent = true
const LuauStoreConstKeywordBegin = true

const LuauRecursionLimit = 1000
const LuauTypeLengthLimit = 1000
const LuauParseErrorLimit = 100

-- // Requires modules

const Confusables = require"@self/Confusables"
const Syntax = require"@self/Syntax"

local hotcommentHeader = true

-- // String types

const BraceType = {
	InterpolatedString = 0,
	Normal = 1,
}

const QuoteStyle = {
	QuotedSimple = 0,
	QuotedSingle = 1,
	QuotedRaw = 2,
	Unquoted = 3,
}

const CstQuotes = {
	QuotedSingle = 0, -- ''
	QuotedDouble = 1, -- ""
	QuotedRaw = 2, -- [[]]
	QuotedInterp = 3, -- ``
}

-- // Lookup for keywords
const ReversedKeywords = {
	[291] = "and",
	[292] = "break",
	[293] = "do",
	[294] = "else",
	[295] = "elseif",
	[296] = "end",
	[297] = "false",
	[298] = "for",
	[299] = "function",
	[300] = "if",
	[301] = "in",
	[302] = "local",
	[303] = "nil",
	[304] = "not",
	[305] = "or",
	[306] = "repeat",
	[307] = "return",
	[308] = "then",
	[309] = "true",
	[310] = "until",
	[311] = "while",
}

const Keywords = {
	["and"] = 291,
	["break"] = 292,
	["do"] = 293,
	["else"] = 294,
	["elseif"] = 295,
	["end"] = 296,
	["false"] = 297,
	["for"] = 298,
	["function"] = 299,
	["if"] = 300,
	["in"] = 301,
	["local"] = 302,
	["nil"] = 303,
	["not"] = 304,
	["or"] = 305,
	["repeat"] = 306,
	["return"] = 307,
	["then"] = 308,
	["true"] = 309,
	["until"] = 310,
	["while"] = 311,
}

-- // Lookup for operators

const BinaryOp = {
	Add = 0,
	Sub = 1,
	Mul = 2,
	Div = 3,
	FloorDiv = 4,
	Mod = 5,
	Pow = 6,
	Concat = 7,
	CompareNe = 8,
	CompareEq = 9,
	CompareLt = 10,
	CompareLe = 11,
	CompareGt = 12,
	CompareGe = 13,
	And = 14,
	Or = 15,
}

const BinaryPriority = {
	[BinaryOp.Add] = { 6, 6 },
	[BinaryOp.Sub] = { 6, 6 },
	[BinaryOp.Mul] = { 7, 7 },
	[BinaryOp.Div] = { 7, 7 },
	[BinaryOp.FloorDiv] = { 7, 7 },
	[BinaryOp.Mod] = { 7, 7 },
	[BinaryOp.Pow] = { 10, 9 },
	[BinaryOp.Concat] = { 5, 4 },
	[BinaryOp.CompareNe] = { 3, 3 },
	[BinaryOp.CompareEq] = { 3, 3 },
	[BinaryOp.CompareLt] = { 3, 3 },
	[BinaryOp.CompareLe] = { 3, 3 },
	[BinaryOp.CompareGt] = { 3, 3 },
	[BinaryOp.CompareGe] = { 3, 3 },
	[BinaryOp.And] = { 2, 2 },
	[BinaryOp.Or] = { 1, 1 },
}

const CompoundLookup = {
	[274] = BinaryOp.FloorDiv, -- FloorDivAssign
	[277] = BinaryOp.Concat, -- ConcatAssign
	[275] = BinaryOp.Mod, -- ModAssign
	[276] = BinaryOp.Pow, -- PowAssign
	[270] = BinaryOp.Add, -- AddAssign
	[271] = BinaryOp.Sub, -- SubAssign
	[272] = BinaryOp.Mul, -- MulAssign
	[273] = BinaryOp.Div, -- DivAssign
}

const BinaryOpLookup = {
	[43] = BinaryOp.Add,
	[45] = BinaryOp.Sub,
	[42] = BinaryOp.Mul,
	[47] = BinaryOp.Div,

	[265] = BinaryOp.FloorDiv, -- FloorDiv

	[37] = BinaryOp.Mod,
	[94] = BinaryOp.Pow,

	[261] = BinaryOp.Concat, -- Dot2
	[260] = BinaryOp.CompareNe, -- NotEqual
	[257] = BinaryOp.CompareEq, -- Equal

	[60] = BinaryOp.CompareLt,

	[258] = BinaryOp.CompareLe, -- LessEqual

	[62] = BinaryOp.CompareGt,

	[259] = BinaryOp.CompareGe, -- GreaterEqual
	[291] = BinaryOp.And, -- ReservedAnd
	[305] = BinaryOp.Or, -- ReservedOr
}

const UnaryOpLookup = {
	[304] = 0, -- ReservedNot
	[45] = 1, -- Minus
	[35] = 2, -- Len
}

const BlockFollow = {
	[295] = true, -- ReservedElseif
	[310] = true, -- ReservedUntil
	[294] = true, -- ReservedElse
	[296] = true, -- ReservedEnd
	[0] = true, -- Eof
}

const ConstantLiteral = {
	ExprConstantNil = true,
	ExprConstantBool = true,
	ExprConstantNumber = true,
	ExprConstantInteger = true,
	ExprConstantString = true,
}

const ExprLValues = {
	ExprLocal = true,
	ExprGlobal = true,
	ExprIndexExpr = true,
	ExprIndexName = true,
}

const AllowedClassMetamethods = {
	__call = true,
	__concat = true,
	__unm = true,
	__add = true,
	__sub = true,
	__mul = true,
	__div = true,
	__mod = true,
	__pow = true,
	__tostring = true,
	__eq = true,
	__lt = true,
	__le = true,
	__iter = true,
	__len = true,
	__idiv = true,
}

const DisallowedClassMetamethods = {
	__index = true,
	__newindex = true,
	__mode = true,
	__metatable = true,
	__type = true,
}

-- // Lookups for Lexer

const HexDigits: { [number]: boolean } = {}
const HexVal: { [number]: number } = {}
const Digits: { [number]: boolean } = {}
const Alpha: { [number]: boolean } = {}

const Spaces = {
	[09] = true, -- \t
	[10] = true, -- \n
	[11] = true, -- \v
	[12] = true, -- \f
	[13] = true, -- \r
	[32] = true, -- space
}

const Escapes = {
	[97] = 7,
	[98] = 8,
	[102] = 12,
	[110] = 10,
	[114] = 13,
	[116] = 9,
	[118] = 11,
}

for i = 48, 57 do -- '0' - '9'
	HexDigits[i] = true
	Digits[i] = true
end

for i = 65, 90 do
	if i <= 70 then
		HexDigits[i] = true
	end -- 'a' - 'f'
	Alpha[i] = true
end

for i = 97, 122 do
	if i <= 102 then
		HexDigits[i] = true
	end -- 'A' - 'F'
	Alpha[i] = true
end

for i = 48, 57 do HexVal[i] = i - 48 end -- '0'-'9'
for i = 65, 70 do HexVal[i] = i - 55 end -- 'A'-'F'
for i = 97, 102 do HexVal[i] = i - 87 end -- 'a'-'f'

-- // Lexer helper

const function fixupQuotedString(data: string): (boolean, string?)
	if #data == 0 or not string.find(data, "\\") then
		return true, data
	end

	const size = #data
	const src = buffer.fromstring(data)
	const buf = buffer.create(size)
	local write = 0
	local i = 0

	while i < size do
		const ch = buffer.readu8(src, i)

		if ch ~= 92 then -- not '\'
			buffer.writeu8(buf, write, ch)
			write += 1
			i += 1
			continue
		end

		if i + 1 == size then
			return false, nil -- Trailing backslash
		end

		const escape = buffer.readu8(src, i + 1)
		i += 2 -- skip \ and the escape char

		if escape == 10 then -- \n
			buffer.writeu8(buf, write, 10)
			write += 1
		elseif escape == 13 then -- \r
			buffer.writeu8(buf, write, 10)
			write += 1
			if i < size and buffer.readu8(src, i) == 10 then
				i += 1
			end
		elseif escape == 0 then
			return false, nil
		elseif escape == 120 then -- 'x'
			if i + 2 > size then
				return false, nil
			end

			local code = 0
			for j = 0, 1 do
				const c = buffer.readu8(src, i + j)
				if not HexDigits[c] then
					return false, nil
				end

				const hexVal = if Digits[c] then c - 48 else bit32.bor(c, 32) - 97 + 10
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
			if i + 3 > size then
				return false, nil
			end
			if buffer.readu8(src, i) ~= 123 then
				return false, nil
			end -- '{'
			i += 1

			if buffer.readu8(src, i) == 125 then
				return false, nil
			end

			local code = 0
			local ended = false

			for j = 0, 15 do
				if i == size then
					return false, nil
				end
				const c = buffer.readu8(src, i)

				if c == 125 then
					ended = true
					break
				end

				if not HexDigits[c] then
					return false, nil
				end

				const hexVal = if Digits[c] then c - 48 else bit32.bor(c, 32) - 97 + 10
				code = 16 * code + hexVal
				i += 1
			end

			if not ended then
				if i == size or buffer.readu8(src, i) ~= 125 then
					return false, nil
				end
			end
			i += 1 -- skip '}'

			if code < 0x80 then
				buffer.writeu8(buf, write, code)
				write += 1
			elseif code < 0x800 then
				buffer.writeu8(buf, write, bit32.bor(0xC0, bit32.rshift(code, 6)))
				buffer.writeu8(buf, write + 1, bit32.bor(0x80, bit32.band(code, 0x3F)))
				write += 2
			elseif code < 0x10000 then
				buffer.writeu8(buf, write, bit32.bor(0xE0, bit32.rshift(code, 12)))
				buffer.writeu8(buf, write + 1, bit32.bor(0x80, bit32.band(bit32.rshift(code, 6), 0x3F)))
				buffer.writeu8(buf, write + 2, bit32.bor(0x80, bit32.band(code, 0x3F)))
				write += 3
			elseif code < 0x110000 then
				buffer.writeu8(buf, write, bit32.bor(0xF0, bit32.rshift(code, 18)))
				buffer.writeu8(buf, write + 1, bit32.bor(0x80, bit32.band(bit32.rshift(code, 12), 0x3F)))
				buffer.writeu8(buf, write + 2, bit32.bor(0x80, bit32.band(bit32.rshift(code, 6), 0x3F)))
				buffer.writeu8(buf, write + 3, bit32.bor(0x80, bit32.band(code, 0x3F)))
				write += 4
			else
				return false, nil
			end
		else
			if Digits[escape] then
				local code = escape - 48

				for j = 0, 1 do
					if i == size then
						break
					end
					const c = buffer.readu8(src, i)
					if not Digits[c] then
						break
					end
					code = 10 * code + (c - 48)
					i += 1
				end

				if code > 255 then
					return false, nil
				end

				buffer.writeu8(buf, write, code)
				write += 1
			else
				buffer.writeu8(buf, write, Escapes[escape] or escape)
				write += 1
			end
		end
	end

	return true, string.sub(buffer.tostring(buf), 1, write)
end

const function fixupMultilineString(data: string): string
	if #data == 0 then
		return data
	end

	data = string.gsub(data, "^\r?\n", "")
	data = string.gsub(data, "\r\n", "\n")

	return data
end

const function ToString(t: number, data: string?, codepoint: number?): string
	if t == 0 then
		return "<eof>"
	elseif t == 257 then
		return "'=='"
	elseif t == 258 then
		return "'<='"
	elseif t == 259 then
		return "'>='"
	elseif t == 260 then
		return "'~='"
	elseif t == 261 then
		return "'..'"
	elseif t == 262 then
		return "'...'"
	elseif t == 263 then
		return "'->'"
	elseif t == 264 then
		return "'::'"
	elseif t == 265 then
		return "'//'"
	elseif t == 270 then
		return "'+='"
	elseif t == 271 then
		return "'-='"
	elseif t == 272 then
		return "'*='"
	elseif t == 273 then
		return "'/='"
	elseif t == 274 then
		return "'//='"
	elseif t == 275 then
		return "'%='"
	elseif t == 276 then
		return "'^='"
	elseif t == 277 then
		return "'..='"
	elseif t == 278 or t == 279 then
		if data then
			return `"{data}"`
		else
			return "string"
		end
	elseif t == 266 then
		if data then
			return `\`{data}\{`
		else
			return "the beginning of an interpolated string"
		end
	elseif t == 267 then
		if data then
			return `\}{data}\{`
		else
			return "the middle of an interpolated string"
		end
	elseif t == 268 then
		if data then
			return `\}{data}\``
		else
			return "the end of an interpolated string"
		end
	elseif t == 269 then
		if data then
			return `\`{data}\``
		else
			return "interpolated string"
		end
	elseif t == 280 then
		if data then
			return `'{data}'`
		else
			return "number"
		end
	elseif t == 281 then
		if data then
			return `'{data}'`
		else
			return "identifier"
		end
	elseif t == 282 then
		return "comment"
	elseif t == 284 then
		if data then
			return `'{data}'`
		else
			return "attribute"
		end
	elseif t == 285 then
		return "'@['"
	elseif t == 286 then
		return "malformed string"
	elseif t == 287 then
		return "unfinished comment"
	elseif t == 289 then
		return "'{{', which is invalid (did you mean '\\{'?)"
	elseif t == 288 then
		if codepoint then
			const confusable = Confusables[codepoint]
			if confusable then
				return `Unicode character {string.format("U+%x", codepoint)} (did you mean '{confusable}'?)`
			end
			return string.format("Unicode character U+%x", codepoint)
		else
			return "invalid UTF-8 sequence"
		end
	else
		if t < 256 then
			return string.format("'%c'", t)
		elseif ReversedKeywords[t] then
			return `'{ReversedKeywords[t]}'`
		else
			return "<unknown>"
		end
	end
end

-- // Parser Helpers

const function isLiteralTable(expr: Syntax.AstExpr): boolean
	if expr.kind ~= "ExprTable" then
		return false
	end

	for _, item in expr.items do
		if item.kind == "General" then
			return false
		elseif item.kind == "Record" or item.kind == "List" then
			if not ConstantLiteral[item.value.kind] and not isLiteralTable(item.value) then
				return false
			end
		end
	end

	return true
end

-- // Attributes

const function deprecatedArgsValidator(attrLoc: Syntax.Location, args: { Syntax.AstExpr }): { Syntax.ParseError }
	const errors: { Syntax.ParseError } = {}
	if #args == 0 then
		return errors
	end
	if #args > 1 then
		table.insert(errors, {
			location = attrLoc,
			message = "@deprecated can be parametrized only by 1 argument",
		})
		return errors
	end

	const arg = args[1]
	if arg.kind ~= "ExprTable" then
		table.insert(errors, {
			location = arg.location,
			message = "Unknown argument type for @deprecated",
		})
		return errors
	end

	for _, item in arg.items do
		if item.key and item.kind == "Record" and item.key.kind == "ExprConstantString" then
			const keyString = item.key.value
			if keyString ~= "use" and keyString ~= "reason" then
				table.insert(errors, {
					location = item.key.location,
					message = `Unknown argument '{keyString}' for @deprecated. Only string constants for 'use' and 'reason' are allowed`,
				})
			elseif item.value.kind ~= "ExprConstantString" then
				table.insert(errors, {
					location = item.value.location,
					message = `Only constant string allowed as value for '{keyString}'`,
				})
			end
		else
			table.insert(errors, {
				location = item.value.location,
				message = "Only constants keys 'use' and 'reason' are allowed for @deprecated attribute",
			})
		end
	end
	return errors
end

const kAttributeEntries = {
	checked = {type = "Checked"},
	native = {type = "Native"},

	deprecated = {
		type = "Deprecated",
		argsValidator = deprecatedArgsValidator,
	},
}

const kDebugAttributeEntries = {
	debugnoinline = {type = "DebugNoinline"},
}

-- // Main

local options = {} :: Syntax.Options
local source = "" :: string

-- // Settings init

local captureComments = options.captureComments
local storeCstData = options.storeCstData

-- // Lexer State & Buffer

local buff_data = buffer.fromstring(source)
local size = #source

-- Current State
local offset = 0
local line = 0
local lineOffset = 0

local braceStack: { number } = {}

-- // Current Token State

local token_type = 0 -- Eof

-- Locations
local token_start_line = 0
local token_start_col = 0
local token_end_line = 0
local token_end_col = 0

-- Previous Token Location (for errors/end mismatch)
local prev_start_line = 0
local prev_start_col = 0
local prev_end_line = 0
local prev_end_col = 0

-- Payload
local token_string: string? = nil
local token_aux: number? = nil
local token_codepoint: number? = nil

-- // Parser init

local recursionCounter = 0

local commentLocations: { Syntax.Comment } = {}
local hotcomments = {} :: { Syntax.HotComment }
local parseErrors: { Syntax.ParseError } = {}
local declaredExportBindings: { [string]: Syntax.Location } = {}
local hasModuleReturn = false
local classesWithinModule: { [string]: boolean } = {}

type TableIndexerResult = {
	node: Syntax.AstTableIndexer,
	indexerOpenPosition: Syntax.Position,
	indexerClosePosition: Syntax.Position,
	colonPosition: Syntax.Position?,
}


-- // Suspect State

local next_type = 0 -- Eof
local next_start_line = 0
local next_end_line = 0

local next_start_col = 0
local next_end_col = 0

local next_codepoint: number? = nil
local next_string: string? = nil
local next_aux: number? = nil

local suspect_type = 0 -- Eof sentinel

local suspect_line = 0

local matchRecovery = table.create(312, 0)
matchRecovery[0] = 1 -- Eof

-- // Stacks

local functionStack: { Syntax.FunctionState } = {{ vararg = true, loopDepth = 0 }}

local localStack: { Syntax.AstLocal? } = {}
local localMap: { [string]: Syntax.AstLocal? } = {}

-- // Lexer // --

const function lex(skip_comments: boolean)
	local ptr = offset
	local cur_line = line

	const buff = buff_data
	const sourceSize = size

	while true do
		if ptr >= sourceSize then
			-- EOF Logic
			offset = ptr
			line = cur_line

			next_type = 0 -- Eof
			next_end_line = cur_line
			next_end_col = ptr - lineOffset

			next_start_line = cur_line
			next_start_col = ptr - lineOffset
			return
		end

		const c = buffer.readu8(buff, ptr)

		if c == 32 or c == 9 then -- space or tab
			ptr += 1
		elseif c == 10 then -- \n
			cur_line += 1
			ptr += 1
			lineOffset = ptr
		elseif c == 13 then -- \r
			if ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 10 then
				ptr += 2
				cur_line += 1
				lineOffset = ptr
			else
				ptr += 1
			end
		elseif c == 11 or c == 12 then -- \v, \f
			ptr += 1
		else
			break -- not whitespace
		end
	end

	next_start_line = cur_line
	next_start_col = ptr - lineOffset
	next_string = nil
	next_aux = nil
	next_codepoint = nil

	const ch = buffer.readu8(buff, ptr)
	const start_ptr = ptr
	ptr += 1 -- Consume current char

	const alphaLookup = Alpha
	const digitLookup = Digits
	const keywordLookup = Keywords

	-- Identifiers / Keywords
	if alphaLookup[ch] or ch == 95 then
		while ptr < sourceSize do
			const c = buffer.readu8(buff, ptr)
			if alphaLookup[c] or digitLookup[c] or c == 95 then
				ptr += 1
			else
				break
			end
		end

		const text = string.sub(source, start_ptr + 1, ptr)

		next_type = keywordLookup[text] or 281 -- Name fallback when `text` is not a keyword
		next_string = text
		-- Numbers (0-9)
	elseif digitLookup[ch] then
		while ptr < size do
			const numberChar = buffer.readu8(buff, ptr)

			if Digits[numberChar] or numberChar == 46 or numberChar == 95 then
				ptr += 1
			elseif numberChar == 101 or numberChar == 69 then -- e / E
				ptr += 1

				if ptr < size then
					const exp_ch = buffer.readu8(buff, ptr)
					if exp_ch == 43 or exp_ch == 45 then -- + / -
						ptr += 1
					end
				end
			else
				break
			end
		end

		while ptr < size do
			const suffixChar = buffer.readu8(buff, ptr)

			if Alpha[suffixChar] or Digits[suffixChar] or suffixChar == 95 then
				ptr += 1
			else
				break
			end
		end
		
		next_type = 280 -- Number
		next_string = string.sub(source, start_ptr + 1, ptr)

		-- Strings (" or ')
	elseif ch == 34 or ch == 39 then -- " or '
		const delim = ch
		const content_start = ptr

		while ptr < sourceSize do
			const c = buffer.readu8(buff, ptr)
			if c == delim then
				break
			elseif c == 92 then -- \
				ptr += 1
				if ptr < sourceSize then
					const esc = buffer.readu8(buff, ptr)
					if esc == 10 then -- \n
						cur_line += 1
						lineOffset = ptr + 1
					elseif esc == 13 then -- \r
						if ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 10 then
							cur_line += 1
							ptr += 1
							lineOffset = ptr + 1
						end
					elseif esc == 122 then -- z
						ptr += 1
						while ptr < sourceSize do
							const wc = buffer.readu8(buff, ptr)
							if wc == 32 or wc == 9 or wc == 10 or wc == 13 or wc == 11 or wc == 12 then
								if wc == 10 then
									cur_line += 1
									lineOffset = ptr + 1
								elseif wc == 13 then
									if ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 10 then
										ptr += 1
										cur_line += 1
										lineOffset = ptr + 1
									end
								end
								ptr += 1
							else
								ptr -= 1
								break
							end
						end
					end
				end
			elseif c == 10 or c == 13 then -- \n / \r
				next_type = 286 -- BrokenString
				break
			end
			ptr += 1
		end

		if next_type == 286 then -- BrokenString
			-- handled
		elseif ptr >= sourceSize then
			next_type = 286 -- BrokenString
		else
			next_type = 279 -- QuotedString
			next_string = string.sub(source, content_start + 1, ptr)
			next_aux = if delim == 39 then 0 else 1
			ptr += 1 -- consume closing delim
		end

		-- Operators & Punctuation
	elseif ch == 45 then -- '-'
		const next_ch = if ptr < sourceSize then buffer.readu8(buff, ptr) else 0
		if next_ch == 62 then -- ->
			ptr += 1
			next_type = 263 -- SkinnyArrow
		elseif next_ch == 61 then -- -=
			ptr += 1
			next_type = 271 -- SubAssign
		elseif next_ch == 45 then -- -- Comment
			ptr += 1
			const comment_start = ptr

			-- Block Comment --[
			local is_block = false
			if ptr < sourceSize and buffer.readu8(buff, ptr) == 91 then
				const sep_start = ptr
				ptr += 1
				local count = 0
				while ptr < sourceSize and buffer.readu8(buff, ptr) == 61 do
					ptr += 1
					count += 1
				end

				if ptr < sourceSize and buffer.readu8(buff, ptr) == 91 then
					-- Found long comment
					is_block = true
					ptr += 1
					local found_end = false

					while ptr < sourceSize do
						const c = buffer.readu8(buff, ptr)
						if c == 93 then -- ]
							local c2_idx = ptr + 1
							local close_count = 0
							while c2_idx < sourceSize and buffer.readu8(buff, c2_idx) == 61 do
								c2_idx += 1
								close_count += 1
							end
							if close_count == count and c2_idx < sourceSize and buffer.readu8(buff, c2_idx) == 93 then
								ptr = c2_idx + 1
								found_end = true
								break
							end
						elseif c == 10 then -- \n
							cur_line += 1
							lineOffset = ptr + 1
						end
						ptr += 1
					end

					if not found_end then
						next_type = 287 -- BrokenComment
					else
						next_type = 283 -- BlockComment
					end
				else
					-- Not a block comment
					ptr = sep_start -- Backtrack
				end
			end

			if not is_block then
				-- Line Comment
				while ptr < sourceSize do
					const c = buffer.readu8(buff, ptr)
					if c == 10 or c == 13 then
						break
					end -- \n or \r
					ptr += 1
				end
				next_type = 282 -- Comment
			end

			if not skip_comments then
				next_string = string.sub(source, comment_start + 1, ptr)
			end
		else
			next_type = 45 -- '-'
		end
	elseif ch == 46 then -- '.'
		const next_ch = if ptr < sourceSize then buffer.readu8(buff, ptr) else 0
		if next_ch == 46 then -- ..
			ptr += 1
			const third_ch = if ptr < sourceSize then buffer.readu8(buff, ptr) else 0
			if third_ch == 46 then -- ...
				ptr += 1
				next_type = 262 -- Dot3
			elseif third_ch == 61 then -- ..=
				ptr += 1
				next_type = 277 -- ConcatAssign
			else
				next_type = 261 -- Dot2
			end
		else
			if digitLookup[next_ch] then
				ptr -= 1 -- Backtrack
				const n_start = ptr
				while ptr < size do
					const numberChar = buffer.readu8(buff, ptr)

					if Digits[numberChar] or numberChar == 46 or numberChar == 95 then
						ptr += 1
					elseif numberChar == 101 or numberChar == 69 then -- e / E
						ptr += 1

						if ptr < size then
							const exp_ch = buffer.readu8(buff, ptr)
							if exp_ch == 43 or exp_ch == 45 then -- + / -
								ptr += 1
							end
						end
					else
						break
					end
				end

				while ptr < size do
					const suffixChar = buffer.readu8(buff, ptr)

					if Alpha[suffixChar] or Digits[suffixChar] or suffixChar == 95 then
						ptr += 1
					else
						break
					end
				end
				
				next_type = 280 -- Number
				next_string = string.sub(source, n_start + 1, ptr)
			else
				next_type = 46 -- '.'
			end
		end
	elseif ch == 61 then -- '='
		if ptr < sourceSize and buffer.readu8(buff, ptr) == 61 then
			ptr += 1
			next_type = 257 -- Equal
		else
			next_type = 61
		end
	elseif ch == 60 then -- '<'
		if ptr < sourceSize and buffer.readu8(buff, ptr) == 61 then
			ptr += 1
			next_type = 258 -- LessEqual
		else
			next_type = 60
		end
	elseif ch == 62 then -- '>'
		if ptr < sourceSize and buffer.readu8(buff, ptr) == 61 then
			ptr += 1
			next_type = 259 -- GreaterEqual
		else
			next_type = 62
		end
	elseif ch == 126 then -- '~'
		if ptr < sourceSize and buffer.readu8(buff, ptr) == 61 then
			ptr += 1
			next_type = 260 -- NotEqual
		else
			next_type = 126
		end
	elseif ch == 43 then -- '+'
		if ptr < sourceSize and buffer.readu8(buff, ptr) == 61 then
			ptr += 1
			next_type = 270 -- AddAssign
		else
			next_type = 43
		end
	elseif ch == 42 then -- '*'
		if ptr < sourceSize and buffer.readu8(buff, ptr) == 61 then
			ptr += 1
			next_type = 272 -- MulAssign
		else
			next_type = 42
		end
	elseif ch == 37 then -- '%'
		if ptr < sourceSize and buffer.readu8(buff, ptr) == 61 then
			ptr += 1
			next_type = 275 -- ModAssign
		else
			next_type = 37
		end
	elseif ch == 94 then -- '^'
		if ptr < sourceSize and buffer.readu8(buff, ptr) == 61 then
			ptr += 1
			next_type = 276 -- PowAssign
		else
			next_type = 94
		end
	elseif ch == 47 then -- '/'
		const next_ch = if ptr < sourceSize then buffer.readu8(buff, ptr) else 0
		if next_ch == 61 then
			ptr += 1
			next_type = 273 -- DivAssign
		elseif next_ch == 47 then
			ptr += 1
			if ptr < sourceSize and buffer.readu8(buff, ptr) == 61 then
				ptr += 1
				next_type = 274 -- FloorDivAssign
			else
				next_type = 265 -- FloorDiv
			end
		else
			next_type = 47
		end
	elseif ch == 58 then -- ':'
		if ptr < sourceSize and buffer.readu8(buff, ptr) == 58 then
			ptr += 1
			next_type = 264 -- DoubleColon
		else
			next_type = 58
		end

		-- Single Char / Interp
	elseif
		ch == 40
		or ch == 41
		or ch == 93
		or ch == 59
		or ch == 44
		or ch == 35
		or ch == 63
		or ch == 38
		or ch == 124
		or ch == 123
		or ch == 125
	then
		if ch == 123 then
			if #braceStack > 0 then
				table.insert(braceStack, BraceType.Normal)
			end
			next_type = ch
		elseif ch == 125 then
			if #braceStack == 0 then
				next_type = ch
			else
				const top = table.remove(braceStack)
				if top ~= BraceType.InterpolatedString then
					next_type = ch
				else
					const sectionStart = ptr
					local sectionDone = false

					while ptr < sourceSize do
						const c = buffer.readu8(buff, ptr)

						if c == 96 then -- `
							next_type = 268 -- InterpStringEnd
							next_string = string.sub(source, sectionStart + 1, ptr)
							ptr += 1
							sectionDone = true
							break
						elseif c == 13 or c == 10 then -- \r / \n
							next_type = 286 -- BrokenString
							sectionDone = true
							break
						elseif c == 92 then -- \
							-- Allow \u{...} without treating '{' as interpolation start.
							if
								ptr + 2 < sourceSize
								and buffer.readu8(buff, ptr + 1) == 117
								and buffer.readu8(buff, ptr + 2) == 123
							then
								ptr += 3
							else
								ptr += 1 -- consume '\'

								if ptr < sourceSize then
									const esc = buffer.readu8(buff, ptr)

									if esc == 13 then -- \r
										if ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 10 then
											cur_line += 1
											ptr += 1
											lineOffset = ptr + 1
										end
									elseif esc == 122 then -- z
										ptr += 1
										while ptr < sourceSize do
											const wc = buffer.readu8(buff, ptr)
											if
												wc ~= 32
												and wc ~= 9
												and wc ~= 13
												and wc ~= 10
												and wc ~= 11
												and wc ~= 12
											then
												break
											end

											if wc == 10 then
												cur_line += 1
												lineOffset = ptr + 1
											elseif
												wc == 13
												and ptr + 1 < sourceSize
												and buffer.readu8(buff, ptr + 1) == 10
											then
												ptr += 1
												cur_line += 1
												lineOffset = ptr + 1
											end

											ptr += 1
										end
									elseif esc == 10 then -- \n
										cur_line += 1
										lineOffset = ptr + 1
										ptr += 1
									else
										ptr += 1
									end
								end
							end
						elseif c == 123 then -- {
							table.insert(braceStack, BraceType.InterpolatedString)

							if ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 123 then
								next_type = 289 -- BrokenInterpDoubleBrace
								next_string = string.sub(source, sectionStart + 1, ptr)
								ptr += 2
								sectionDone = true
								break
							end

							next_type = 267 -- InterpStringMid
							next_string = string.sub(source, sectionStart + 1, ptr)
							ptr += 1
							sectionDone = true
							break
						else
							ptr += 1
						end
					end

					if not sectionDone then
						next_type = 286 -- BrokenString
					end
				end
			end
		else
			next_type = ch
		end
	elseif ch == 96 then -- `
		const sectionStart = ptr
		local sectionDone = false

		while ptr < sourceSize do
			const c = buffer.readu8(buff, ptr)

			if c == 96 then -- `
				next_type = 269 -- InterpStringSimple
				next_string = string.sub(source, sectionStart + 1, ptr)
				ptr += 1
				sectionDone = true
				break
			elseif c == 13 or c == 10 then -- \r / \n
				next_type = 286 -- BrokenString
				sectionDone = true
				break
			elseif c == 92 then -- \
				-- Allow \u{...} without treating '{' as interpolation start.
				if ptr + 2 < sourceSize and buffer.readu8(buff, ptr + 1) == 117 and buffer.readu8(buff, ptr + 2) == 123 then
					ptr += 3
				else
					ptr += 1 -- consume '\'
					if ptr < sourceSize then
						const esc = buffer.readu8(buff, ptr)

						if esc == 13 then -- \r
							if ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 10 then
								cur_line += 1
								ptr += 1
								lineOffset = ptr + 1
							end
						elseif esc == 122 then -- z
							ptr += 1
							while ptr < sourceSize do
								const wc = buffer.readu8(buff, ptr)
								if wc ~= 32 and wc ~= 9 and wc ~= 13 and wc ~= 10 and wc ~= 11 and wc ~= 12 then
									break
								end

								if wc == 10 then
									cur_line += 1
									lineOffset = ptr + 1
								elseif wc == 13 and ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 10 then
									ptr += 1
									cur_line += 1
									lineOffset = ptr + 1
								end

								ptr += 1
							end
						elseif esc == 10 then -- \n
							cur_line += 1
							lineOffset = ptr + 1
							ptr += 1
						else
							ptr += 1
						end
					end
				end
			elseif c == 123 then -- {
				table.insert(braceStack, BraceType.InterpolatedString)

				if ptr + 1 < sourceSize and buffer.readu8(buff, ptr + 1) == 123 then
					next_type = 289 -- BrokenInterpDoubleBrace
					next_string = string.sub(source, sectionStart + 1, ptr)
					ptr += 2
					sectionDone = true
					break
				end

				next_type = 266 -- InterpStringBegin
				next_string = string.sub(source, sectionStart + 1, ptr)
				ptr += 1
				sectionDone = true
				break
			else
				ptr += 1
			end
		end

		if not sectionDone then
			next_type = 286 -- BrokenString
		end
	elseif ch == 91 then -- [
		local count = 0
		while ptr < sourceSize and buffer.readu8(buff, ptr) == 61 do
			ptr += 1
			count += 1
		end

		if ptr < sourceSize and buffer.readu8(buff, ptr) == 91 then
			ptr += 1
			-- Long String
			const ls_start = ptr
			local found = false

			while ptr < sourceSize do
				if buffer.readu8(buff, ptr) == 93 then
					local c2 = ptr + 1
					local cc = 0

					while c2 < sourceSize and buffer.readu8(buff, c2) == 61 do
						c2 += 1
						cc += 1
					end

					if cc == count and c2 < sourceSize and buffer.readu8(buff, c2) == 93 then
						next_type = 278 -- RawString
						next_string = string.sub(source, ls_start + 1, ptr)
						ptr = c2 + 1
						next_aux = count
						found = true
						break
					end
				elseif buffer.readu8(buff, ptr) == 10 then
					cur_line += 1
					lineOffset = ptr + 1
				end
				ptr += 1
			end
			if not found then
				next_type = 286 -- BrokenString
			end
		elseif count == 0 then
			next_type = 91 -- [
		else
			next_type = 286 -- BrokenString
		end
	elseif ch == 64 then -- @
		if ptr < sourceSize and buffer.readu8(buff, ptr) == 91 then
			ptr += 1
			next_type = 285 -- AttributeOpen
		else
			next_type = 284 -- Attribute
			if ptr < sourceSize then
				const first = buffer.readu8(buff, ptr)
				if alphaLookup[first] or first == 95 then
					const name_start = ptr
					ptr += 1
					while ptr < sourceSize do
						const c = buffer.readu8(buff, ptr)
						if alphaLookup[c] or digitLookup[c] or c == 95 then
							ptr += 1
						else
							break
						end
					end
					next_string = string.sub(source, name_start + 1, ptr)
				else
					next_string = ""
				end
			else
				next_string = ""
			end
		end
	else
		if bit32.btest(ch, 0x80) then
			local cp = 0
			local seq_len = 0
			if bit32.band(ch, 0xE0) == 0xC0 then
				seq_len = 1
				cp = bit32.band(ch, 0x1F)
			elseif bit32.band(ch, 0xF0) == 0xE0 then
				seq_len = 2
				cp = bit32.band(ch, 0x0F)
			elseif bit32.band(ch, 0xF8) == 0xF0 then
				seq_len = 3
				cp = bit32.band(ch, 0x07)
			else
				next_type = 288 -- BrokenUnicode
				seq_len = -1 -- signal fail
			end

			if seq_len ~= -1 then
				local ok = true
				for i = 1, seq_len do
					if ptr >= sourceSize then
						ok = false
						break
					end

					const c = buffer.readu8(buff, ptr)
					if bit32.band(c, 0xC0) ~= 0x80 then
						ok = false
						break
					end

					cp = bit32.lshift(cp, 6) + bit32.band(c, 0x3F)
					ptr += 1
				end

				if ok then
					next_type = 288 -- BrokenUnicode
					next_codepoint = cp
				else
					next_type = 288 -- BrokenUnicode
				end
			end
		else
			next_type = ch
		end
	end

	-- Sync State
	offset = ptr
	line = cur_line
	next_end_line = cur_line
	next_end_col = ptr - lineOffset
end

-- // Parser Interface
const function fillNext()
	while true do
		lex(false) -- writes to next_*

		if next_type == 282 or next_type == 283 or next_type == 287 then -- Comment / BlockComment / BrokenComment
			if captureComments then
				table.insert(commentLocations, {
					type = next_type,
					location = {
						begin = { line = next_start_line, column = next_start_col },
						end_ = { line = next_end_line, column = next_end_col },
					},
				})
			end

			if next_type == 282 and next_string and string.byte(next_string :: string, 1) == 33 then -- Comment and '!'
				const text = next_string :: string
				local ending = #text

				while ending > 0 do
					const byte = string.byte(text, ending)
					if byte and Spaces[byte] then
						ending -= 1
					else
						break
					end
				end

				table.insert(
					hotcomments,
					{
						header = hotcommentHeader,
						location = {
							begin = { line = next_start_line, column = next_start_col },
							end_ = { line = next_end_line, column = next_end_col },
						},
						content = string.sub(text, 2, ending),
					} :: Syntax.HotComment
				)
			end

			if next_type == 287 then return end -- BrokenComment
			continue
		end

		break
	end
end

const function nextLexeme()
	-- Save previous current to prev
	prev_start_line = token_start_line
	prev_start_col = token_start_col
	prev_end_line = token_end_line
	prev_end_col = token_end_col

	-- Move NEXT to CURRENT
	token_type = next_type
	token_start_line = next_start_line
	token_start_col = next_start_col
	token_end_line = next_end_line
	token_end_col = next_end_col
	token_string = next_string
	token_aux = next_aux
	token_codepoint = next_codepoint

	-- Refill NEXT
	fillNext()
end

-- // Parser Commons

const function snapshot(): Syntax.Location
	return {
		begin = { line = token_start_line, column = token_start_col },
		end_ = { line = token_end_line, column = token_end_col },
	}
end

const function get_lexeme(): Syntax.Lexeme
	return {
		type = token_type,
		location = {
			begin = { line = token_start_line, column = token_start_col },
			end_ = { line = token_end_line, column = token_end_col },
		},
	}
end

const function getprev(): Syntax.Location
	return {
		begin = { line = prev_start_line, column = prev_start_col },
		end_ = { line = prev_end_line, column = prev_end_col },
	}
end

-- // Error reports

const function positionsEqual(a: Syntax.Position, b: Syntax.Position): boolean
	return a.line == b.line and a.column == b.column
end

const function locationsEqual(a: Syntax.Location, b: Syntax.Location): boolean
	return positionsEqual(a.begin, b.begin) and positionsEqual(a.end_, b.end_)
end

const function report(loc: Syntax.Location, fmt: string, ...: unknown)
	if #parseErrors > 0 and locationsEqual(parseErrors[#parseErrors].location, loc) then
		return
	end

	const msg = string.format(fmt, ...)
	table.insert(parseErrors, { location = loc, message = msg })

	if LuauParseErrorLimit == 1 then
		error(msg, 0)
	end

	if #parseErrors >= LuauParseErrorLimit and not options.noErrorLimit then
		error(`Reached error limit ({LuauParseErrorLimit})`, 0)
	end
end

const function expectAndConsumeFail(type_: number, context: string?)
	const typeString = ToString(type_)
	const lexString = ToString(token_type, token_string, token_codepoint)

	if context then
		report(snapshot(), "Expected %s when parsing %s, got %s", typeString, context, lexString)
	else
		report(snapshot(), "Expected %s, got %s", typeString, lexString)
	end
end

const function expectMatchAndConsumeFail(
	type_: number,
	begin_type: number,
	line: number,
	column: number,
	extra: string?
)
	const typeString = ToString(type_)
	const matchString = ToString(begin_type)
	const currString = ToString(token_type, token_string, token_codepoint)

	if token_start_line == line then
		report(
			snapshot(),
			"Expected %s (to close %s at column %d), got %s%s",
			typeString,
			matchString,
			column + 1,
			currString,
			extra or ""
		)
	else
		report(
			snapshot(),
			"Expected %s (to close %s at line %d), got %s%s",
			typeString,
			matchString,
			line + 1,
			currString,
			extra or ""
		)
	end
end

const function expectAndConsume(type_: number, context: string?): boolean
	if token_type ~= type_ then
		expectAndConsumeFail(type_, context)

		if next_type == type_ then
			nextLexeme()
			nextLexeme()
		end

		return false
	end

	nextLexeme()
	return true
end

const function expectMatchAndConsume(
	value: number,
	begin_type: number,
	line: number,
	column: number,
	searchForMissing: boolean?
): boolean
	if token_type ~= value then
		expectMatchAndConsumeFail(value, begin_type, line, column)

		if searchForMissing then
			const currentLine = prev_end_line
			local type_ = token_type

			while currentLine == token_start_line and type_ ~= value and matchRecovery[type_] == 0 do
				nextLexeme()
				type_ = token_type
			end

			if type_ == value then
				nextLexeme()
				return true
			end
		else
			if next_type == value then
				nextLexeme()
				nextLexeme()
				return true
			end
		end

		return false
	end

	nextLexeme()
	return true
end

const function expectMatchEndAndConsume(type_: number, begin_type: number, line: number, column: number): boolean
	if token_type ~= type_ then
		if suspect_type ~= 0 and suspect_line > line then
			expectMatchAndConsumeFail(type_, begin_type, line, column,
				string.format(
				"; did you forget to close %s at line %d?",
				ToString(suspect_type, token_string, token_codepoint),
				suspect_line + 1
				)
			)
		else
			expectMatchAndConsumeFail(type_, begin_type, line, column)
		end

		if next_type == type_ then
			nextLexeme()
			nextLexeme()
			return true
		end

		return false
	end

	if token_start_line ~= line and token_start_col ~= column and suspect_line < line then
		suspect_line = line
		suspect_type = begin_type
	end

	nextLexeme()
	return true
end

-- // Ast reports

const function reportStatError(
	location: Syntax.Location,
	exprs: { Syntax.AstExpr },
	stats: { Syntax.AstStat },
	fmt: string,
	...: unknown
): Syntax.AstStatError
	report(location, fmt, ...)

	return {
		kind = "StatError",
		location = location,
		expressions = exprs,
		statements = stats,
		messageIndex = #parseErrors,
	}
end

const function reportExprError(
	location: Syntax.Location,
	exprs: { Syntax.AstExpr },
	fmt: string,
	...: unknown
): Syntax.AstExprError
	report(location, fmt, ...)

	return {
		kind = "ExprError",
		location = location,
		expressions = exprs,
		messageIndex = #parseErrors,
	}
end

const function reportTypeError(
	location: Syntax.Location,
	types: { Syntax.AstType },
	fmt: string,
	...: unknown
): Syntax.AstTypeError
	report(location, fmt, ...)

	return {
		kind = "TypeError",
		location = location,
		types = types,
		isMissing = false,
		messageIndex = #parseErrors,
	}
end

const function reportMissingTypeError(
	parseErrorLocation: Syntax.Location,
	astErrorLocation: Syntax.Location,
	fmt: string,
	...: unknown
): Syntax.AstTypeError
	report(parseErrorLocation, fmt, ...)

	return {
		kind = "TypeError",
		location = astErrorLocation,
		types = {},
		isMissing = true,
		messageIndex = #parseErrors,
	}
end

const function reportNameError(context: string?)
	const currString = ToString(token_type, token_string, token_codepoint)
	if context then
		report(snapshot(), "Expected identifier when parsing %s, got %s", context, currString)
	else
		report(snapshot(), "Expected identifier, got %s", currString)
	end
end

-- // Locals Helpers

const function restoreLocals(offset: number)
	for i = #localStack, offset + 1, -1 do
		const l = localStack[i] :: Syntax.AstLocal
		localMap[l.name] = l.shadow
	end

	for i = #localStack, offset + 1, -1 do
		localStack[i] = nil
	end
end

const function pushLocal(binding: Syntax.Binding): Syntax.AstLocal
	const name = binding.name.value
	const shadow = localMap[name]

	const local_ = {
		name = name,
		location = binding.location,
		shadow = shadow,
		functionDepth = #functionStack - 1,
		loopDepth = functionStack[#functionStack].loopDepth,
		annotation = binding.annotation,
		isConst = binding.isConst == true,
		isExported = false,
	} :: Syntax.AstLocal

	localMap[name] = local_
	table.insert(localStack, local_)

	return local_
end

const function incrementRecursionCounter(context: string)
	recursionCounter += 1

	if recursionCounter > LuauRecursionLimit then
		const msg = `Exceeded allowed recursion depth; simplify your {context} to make the code compile`
		report(snapshot(), "%s", msg)
		error(msg, 0)
	end
end

const function isExprLValue(expr: Syntax.AstExpr): boolean
	if expr.kind == "ExprLocal" then
		const local_ = expr["local"]
		return local_.isConst ~= true
	end

	return ExprLValues[expr.kind] == true
end

const function reportLValueError(expr: Syntax.AstExpr): Syntax.AstExprError
	if expr.kind == "ExprLocal" and expr["local"].isConst == true then
		return reportExprError(
			expr.location,
			{ expr },
			"Variable '%s' is constant and may not be reassigned",
			expr["local"].name
		)
	end

	return reportExprError(expr.location, { expr }, "Assigned expression must be a variable or a field")
end

-- // The core of the code

local typeFunctionDepth = 0

type ParserFunctionTable = {
	parseStat: () -> Syntax.AstStat,
	parseReturnType: () -> Syntax.AstTypePack,
	parseSimpleType: (boolean, boolean) -> (Syntax.AstType?, Syntax.AstTypePack?),
	parseExpr: (number?) -> Syntax.AstExpr,
}

const ParserFunctions = {} :: ParserFunctionTable

const function parseNameOptImpl(context: string?): Syntax.Binding?
	if token_type ~= 281 then
		reportNameError(context)
		return nil
	end

	const result = {
		name = { value = token_string :: string },
		location = snapshot(),
	} :: Syntax.Binding

	nextLexeme()
	return result
end

-- Type ::=
--      nil |
--      Name[`.' Name] [`<' namelist `>'] |
--      `{' [PropList] `}' |
--      `(' [TypeList] `)' `->` ReturnType
--      `typeof` Type
const function parseTypeSuffixImpl(type_: Syntax.AstType?, begin: Syntax.Location): Syntax.AstType
	const parts = {} :: { Syntax.AstType }
	if type_ then
		table.insert(parts, type_)
	end

	incrementRecursionCounter("type annotation")

	local isUnion = false
	local isIntersection = false
	local optionalCount = 0

	const separatorPositions: { Syntax.Position } = {}
	local leadingPosition: Syntax.Position? = nil

	while true do
		const t = token_type
		const separatorPosition = { line = token_start_line, column = token_start_col }

		if t == 124 then
			nextLexeme()

			const oldRecursion = recursionCounter

			const typePart, _ = ParserFunctions.parseSimpleType(false, false)
			if typePart then
				table.insert(parts, typePart)
			end

			recursionCounter = oldRecursion

			isUnion = true

			if storeCstData then
				if type_ == nil and not leadingPosition then
					leadingPosition = separatorPosition
				else
					table.insert(separatorPositions, separatorPosition)
				end
			end
		elseif t == 63 then
			const loc = snapshot()
			nextLexeme()

			table.insert(parts, { kind = "TypeOptional", location = loc } :: Syntax.AstTypeOptional)

			optionalCount += 1
			isUnion = true
		elseif t == 38 then
			nextLexeme()

			const oldRecursion = recursionCounter

			const typePart, _ = ParserFunctions.parseSimpleType(false, false)
			if typePart then
				table.insert(parts, typePart)
			end

			recursionCounter = oldRecursion

			isIntersection = true

			if storeCstData then
				if type_ == nil and not leadingPosition then
					leadingPosition = separatorPosition
				else
					table.insert(separatorPositions, separatorPosition)
				end
			end
		elseif t == 262 then
			report(snapshot(), "Unexpected '...' after type annotation")
			nextLexeme()
		else
			break
		end

		if #parts > LuauTypeLengthLimit + optionalCount then
			const msg = "Exceeded allowed type length; simplify your type annotation to make the code compile"
			report(parts[#parts].location, "%s", msg)
			error(msg, 0)
		end
	end

	if #parts == 1 and not isUnion and not isIntersection then
		return parts[1]
	end

	if isUnion and isIntersection then
		return reportTypeError(
			{ begin = begin.begin, end_ = parts[#parts].location.end_ },
			parts,
			"Mixing union and intersection types is not allowed; consider wrapping in parentheses."
		)
	end

	const loc = { begin = begin.begin, end_ = parts[#parts].location.end_ }

	if isUnion then
		const node = { kind = "TypeUnion", location = loc, types = parts } :: Syntax.AstTypeUnion
		if storeCstData then
			node.cstNode = {
				kind = "CstTypeUnion",
				leadingPosition = leadingPosition,
				separatorPositions = separatorPositions,
			}
		end
		return node
	end

	if isIntersection then
		const node = { kind = "TypeIntersection", location = loc, types = parts } :: Syntax.AstTypeIntersection
		if storeCstData then
			node.cstNode = {
				kind = "CstTypeIntersection",
				leadingPosition = leadingPosition,
				separatorPositions = separatorPositions,
			}
		end
		return node
	end

	return parts[1]
end

const function parseTypeImpl(inDeclarationContext: boolean?): Syntax.AstType
	const oldRec = recursionCounter
	-- recursion counter is incremented in parseSimpleType and/or parseTypeSuffix

	const begin = snapshot()

	local type_: Syntax.AstType? = nil

	if token_type ~= 124 and token_type ~= 38 then
		type_ = ParserFunctions.parseSimpleType(false, inDeclarationContext or false)
		recursionCounter = oldRec
	end

	const typeWithSuffix = parseTypeSuffixImpl(type_, begin)
	recursionCounter = oldRec

	return typeWithSuffix
end

const function parseOptionalTypeImpl(): Syntax.AstType?
	if token_type == 58 then
		nextLexeme()
		return parseTypeImpl(false)
	else
		return nil
	end
end
const function parseBinding(isConst: boolean?): Syntax.Binding
	const nameOpt = parseNameOptImpl("variable name")

	local bindingName = nameOpt :: Syntax.Binding
	if not bindingName then
		bindingName = {
			name = { value = "%error-id%" },
			location = snapshot(),
		} :: Syntax.Binding
	end

	const colonPos = if storeCstData and token_type == 58 then { line = token_start_line, column = token_start_col } else nil
	const annotation = parseOptionalTypeImpl()

	return {
		name = bindingName.name,
		location = bindingName.location,
		annotation = annotation,
		colonPosition = colonPos,
		isConst = isConst == true,
	} :: Syntax.Binding
end

const function parseNameImpl(context: string?): Syntax.Binding
	const name = parseNameOptImpl(context)
	if name then
		return name
	end

	return {
		name = { value = "%error-id%" },
		location = snapshot(),
	}
end

const function parseVariadicArgumentTypePackImpl(): Syntax.AstTypePackVariadic | Syntax.AstTypePackGeneric
	-- Generic: a...
	if token_type == 281 and next_type == 262 then
		const name = parseNameImpl("generic name")
		const endLoc = snapshot()

		-- This will not fail because of the lookahead guard.
		expectAndConsume(262, "generic type pack annotation")

		const node = {
			kind = "TypePackGeneric",
			location = {
				begin = name.location.begin,
				end_ = endLoc.end_,
			},
			genericName = name.name.value,
		} :: Syntax.AstTypePackGeneric

		if storeCstData then
			node.cstNode = {
				kind = "CstTypePackGeneric",
				ellipsisPosition = endLoc.begin,
			}
		end

		return node
	else -- Variadic: T
		const varTy = parseTypeImpl(false)

		return {
			kind = "TypePackVariadic",
			location = varTy.location,
			variadicType = varTy,
		}
	end
end

-- bindinglist ::= (binding | `...') [`,' bindinglist]
const function parseBindingList(
	result: { Syntax.Binding },
	allowDot3: boolean,
	commaPositions: { Syntax.Position }?,
	initialComma: Syntax.Position?,
	varargAnnotColonPos: { Syntax.Position? }?,
	isConst: boolean?
): (boolean, Syntax.Location?, Syntax.AstTypePack?)
	const localCommaPositions: { Syntax.Position } = {}

	if commaPositions and initialComma then
		table.insert(localCommaPositions, initialComma)
	end

	while true do
		if token_type == 262 and allowDot3 then
			const varargLocation = snapshot()
			nextLexeme()

			local tailAnnotation: Syntax.AstTypePack? = nil
			if token_type == 58 then
				if varargAnnotColonPos then
					varargAnnotColonPos[1] = { line = token_start_line, column = token_start_col }
				end

				nextLexeme()
				tailAnnotation = parseVariadicArgumentTypePackImpl()
			end

			if commaPositions then
				for _, v in localCommaPositions do
					table.insert(commaPositions, v)
				end
			end

			return true, varargLocation, tailAnnotation
		end

		table.insert(result, parseBinding(isConst))

		if token_type ~= 44 then
			break
		end

		if commaPositions then
			table.insert(localCommaPositions, { line = token_start_line, column = token_start_col })
		end

		nextLexeme()
	end

	if commaPositions then
		for _, v in localCommaPositions do
			table.insert(commaPositions, v)
		end
	end

	return false, nil, nil
end

const function parseBlockNoScope(): Syntax.AstStatBlock
	const body: { Syntax.AstStat } = {}

	const prevPos = {
		line = prev_end_line,
		column = prev_end_col,
	}

	while not BlockFollow[token_type] do
		const oldRecursion = recursionCounter
		incrementRecursionCounter("block")

		const stat = ParserFunctions.parseStat()

		recursionCounter = oldRecursion

		if token_type == 59 then
			nextLexeme()
			stat.hasSemicolon = true

			stat.location.end_.line = prev_end_line
			stat.location.end_.column = prev_end_col
		end

		table.insert(body, stat)

		if stat.kind == "StatBreak" or stat.kind == "StatContinue" or stat.kind == "StatReturn" then
			break
		end
	end

	return {
		kind = "StatBlock",
		location = {
			begin = prevPos,
			end_ = {
				line = token_start_line,
				column = token_start_col,
			},
		},
		body = body,
		hasEnd = false,
	} :: Syntax.AstStatBlock
end

-- chunk ::= {stat [`;']} [laststat [`;']]
-- block ::= chunk
const function parseBlock(): Syntax.AstStatBlock
	const localsBegin = #localStack
	const result = parseBlockNoScope()
	restoreLocals(localsBegin)
	return result
end

-- if exp then block {elseif exp then block} [else block] end
const function parseIfImpl(): Syntax.AstStatIf
	const start = snapshot()

	nextLexeme()

	const cond = ParserFunctions.parseExpr()

	const Then_start_line, Then_start_col = token_start_line, token_start_col
	const Then_end_line, Then_end_col = token_end_line, token_end_col

	local thenLocation: Syntax.Location? = nil
	if expectAndConsume(308, "if statement") then
		thenLocation = {
			begin = { line = Then_start_line, column = Then_start_col },
			end_ = { line = Then_end_line, column = Then_end_col },
		}
	end

	const thenbody = parseBlock()

	local elsebody: Syntax.AstStat? = nil
	local end_ = start
	local elseLocation: Syntax.Location? = nil

	if token_type == 295 then
		thenbody.hasEnd = true
		const oldRecursionCount = recursionCounter
		incrementRecursionCounter("elseif")

		elseLocation = snapshot()
		elsebody = parseIfImpl()
		end_ = elsebody.location

		recursionCounter = oldRecursionCount
	else
		local ThenElse_type = token_type

		local ThenElse_start_line, ThenElse_start_col = token_start_line, token_start_col
		local ThenElse_end_line, ThenElse_end_col = token_end_line, token_end_col

		if token_type == 294 then
			thenbody.hasEnd = true
			elseLocation = snapshot()

			ThenElse_type = token_type

			ThenElse_start_line, ThenElse_start_col = token_start_line, token_start_col
			ThenElse_end_line, ThenElse_end_col = token_end_line, token_end_col

			nextLexeme()

			const body = parseBlock()
			body.location.begin = { line = ThenElse_end_line, column = ThenElse_end_col }
			elsebody = body
		end

		end_ = snapshot()

		const hasEnd = expectMatchEndAndConsume(296, ThenElse_type, ThenElse_start_line, ThenElse_start_col)

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
			end_ = end_.end_,
		},
		condition = cond,
		thenbody = thenbody,
		elsebody = elsebody,
		thenLocation = thenLocation,
		elseLocation = elseLocation,
	} :: Syntax.AstStatIf
end

-- while exp do block end
const function parseWhileImpl(): Syntax.AstStatWhile
	const start = snapshot()
	nextLexeme()

	const cond = ParserFunctions.parseExpr()

	const Do_type = token_type

	const Do_start_line, Do_start_col = token_start_line, token_start_col
	const Do_end_line, Do_end_col = token_end_line, token_end_col

	const hasDo = expectAndConsume(293, "while loop")

	functionStack[#functionStack].loopDepth += 1

	const body = parseBlock()

	functionStack[#functionStack].loopDepth -= 1

	const end_ = snapshot()
	const hasEnd = expectMatchEndAndConsume(296, Do_type, Do_start_line, Do_start_col)

	body.hasEnd = hasEnd

	return {
		kind = "StatWhile",
		location = {
			begin = start.begin,
			end_ = end_.end_,
		},
		condition = cond,
		body = body,
		hasDo = hasDo,
		doLocation = {
			begin = { line = Do_start_line, column = Do_start_col },
			end_ = { line = Do_end_line, column = Do_end_col },
		},
	} :: Syntax.AstStatWhile
end

-- repeat block until exp
const function parseRepeatImpl(): Syntax.AstStatRepeat
	const start = snapshot()

	const Repeat_type = token_type
	const Repeat_start_line, Repeat_start_col = token_start_line, token_start_col

	nextLexeme() -- repeat

	const localsBegin = #localStack

	functionStack[#functionStack].loopDepth += 1

	const body = parseBlockNoScope()

	functionStack[#functionStack].loopDepth -= 1

	local untilPosition = { line = 0, column = 0 }
	const hasUntil = expectMatchEndAndConsume(310, Repeat_type, Repeat_start_line, Repeat_start_col)
	body.hasEnd = hasUntil
	if hasUntil then
		untilPosition = { line = prev_start_line, column = prev_start_col }
	end

	const cond = ParserFunctions.parseExpr()

	restoreLocals(localsBegin)

	const node = {
		kind = "StatRepeat",
		location = { begin = start.begin, end_ = cond.location.end_ },
		condition = cond,
		body = body,
		hasUntil = hasUntil,
	} :: Syntax.AstStatRepeat

	if storeCstData then
		node.cstNode = {
			kind = "CstStatRepeat",
			untilPosition = untilPosition,
		}
	end

	return node
end

-- do block end
const function parseDoImpl(): Syntax.AstStatBlock
	const start = snapshot()

	const Do_type = token_type
	const Do_start_line, Do_start_col = token_start_line, token_start_col

	nextLexeme() -- do

	const statsStart = if storeCstData then snapshot() else nil

	const body = parseBlock()
	body.location.begin = start.begin

	const endLocation = snapshot()
	body.hasEnd = expectMatchEndAndConsume(296, Do_type, Do_start_line, Do_start_col)

	if body.hasEnd then
		body.location.end_ = endLocation.end_
	end

	if storeCstData and statsStart then
		body.cstNode = {
			kind = "CstStatDo",
			statsStart = statsStart.begin,
			endPosition = if body.hasEnd then endLocation.begin else { line = 0, column = 0 },
		} :: Syntax.CstStatDo
	end

	return body
end

-- break
const function parseBreakImpl(): Syntax.AstStatBreak | Syntax.AstStatError
	const start = snapshot()
	nextLexeme() -- break

	if functionStack[#functionStack].loopDepth == 0 then
		return reportStatError(
			start,
			{},
			{ { kind = "StatBreak", location = start } },
			"break statement must be inside a loop"
		)
	end

	return {
		kind = "StatBreak",
		location = start,
	}
end

-- continue
const function parseContinueImpl(start: Syntax.Location): Syntax.AstStatContinue | Syntax.AstStatError
	if functionStack[#functionStack].loopDepth == 0 then
		return reportStatError(
			start,
			{},
			{ { kind = "StatContinue", location = start } },
			"continue statement must be inside a loop"
		)
	end

	-- note: the token is already parsed for us!

	return {
		kind = "StatContinue",
		location = start,
	}
end

const function extractAnnotationColonPositions(bindings: { Syntax.Binding }): { Syntax.Position? }
	const positions: { Syntax.Position? } = {}
	for i, binding in bindings do
		positions[i] = binding.colonPosition
	end
	return positions
end

-- explist ::= {exp `,'} exp
const function parseExprListImpl(result: { Syntax.AstExpr }, commaPositions: { Syntax.Position }?)
	table.insert(result, ParserFunctions.parseExpr())

	while token_type == 44 do
		if commaPositions then
			table.insert(commaPositions, { line = token_start_line, column = token_start_col })
		end

		nextLexeme()
		if token_type == 41 then
			report(snapshot(), "Expected expression after ',' but got ')' instead")

			break
		end

		table.insert(result, ParserFunctions.parseExpr())
	end
end

-- for binding `=' exp `,' exp [`,' exp] do block end |
-- for bindinglist in explist do block end |
const function parseForImpl(): Syntax.AstStatFor | Syntax.AstStatForIn
	const start = snapshot()
	nextLexeme() -- for

	const varname = parseBinding()

	if token_type == 61 then
		const equalsPosition = { line = token_start_line, column = token_start_col }
		nextLexeme()

		const from = ParserFunctions.parseExpr()

		local endCommaPosition = { line = 0, column = 0 }
		if expectAndConsume(44, "index range") then
			endCommaPosition = { line = prev_start_line, column = prev_start_col }
		end

		const to = ParserFunctions.parseExpr()

		local stepCommaPosition: Syntax.Position? = nil
		local step: Syntax.AstExpr? = nil

		if token_type == 44 then
			stepCommaPosition = { line = token_start_line, column = token_start_col }
			nextLexeme()
			step = ParserFunctions.parseExpr()
		end

		const Do_type = token_type

		const Do_start_line, Do_start_col = token_start_line, token_start_col
		const Do_end_line, Do_end_col = token_end_line, token_end_col

		const hasDo = expectAndConsume(293, "for loop")

		const localsBegin = #localStack
		functionStack[#functionStack].loopDepth += 1

		const var = pushLocal(varname)

		const body = parseBlock()

		functionStack[#functionStack].loopDepth -= 1
		restoreLocals(localsBegin)

		const end_ = { line = token_end_line, column = token_end_col }
		const hasEnd = expectMatchEndAndConsume(296, Do_type, Do_start_line, Do_start_col)
		body.hasEnd = hasEnd

		const node = {
			kind = "StatFor",
			location = { begin = start.begin, end_ = end_ },
			var = var,
			from = from,
			to = to,
			step = step,
			body = body,
			hasDo = hasDo,
			doLocation = {
				begin = { line = Do_start_line, column = Do_start_col },
				end_ = { line = Do_end_line, column = Do_end_col },
			},
		} :: Syntax.AstStatFor

		if storeCstData then
			node.cstNode = {
				kind = "CstStatFor",
				annotationColonPosition = varname.colonPosition,
				equalsPosition = equalsPosition,
				endCommaPosition = endCommaPosition,
				stepCommaPosition = stepCommaPosition,
			}
		end

		return node
	else
		const names = { varname }
		const varsCommaPosition: { Syntax.Position } = {}

		if token_type == 44 then
			const initialCommaPos = { line = token_start_line, column = token_start_col }
			nextLexeme()
			parseBindingList(names, false, varsCommaPosition, initialCommaPos)
		end

		const inLocation = snapshot()
		const hasIn = expectAndConsume(301, "for loop")

		const values: { Syntax.AstExpr } = {}

		const valuesCommaPositions: { Syntax.Position } = {}
		parseExprListImpl(values, storeCstData and valuesCommaPositions or nil)

		const Do_type = token_type

		const Do_start_line, Do_start_col = token_start_line, token_start_col
		const Do_end_line, Do_end_col = token_end_line, token_end_col

		const hasDo = expectAndConsume(293, "for loop")

		const localsBegin = #localStack
		functionStack[#functionStack].loopDepth += 1

		const vars = {} :: { Syntax.AstLocal }
		for _, binding in names do
			table.insert(vars, pushLocal(binding))
		end

		const body = parseBlock()

		functionStack[#functionStack].loopDepth -= 1
		restoreLocals(localsBegin)

		const end_ = { line = token_end_line, column = token_end_col }

		const hasEnd = expectMatchEndAndConsume(296, Do_type, Do_start_line, Do_start_col)
		body.hasEnd = hasEnd

		const node = {
			kind = "StatForIn",
			location = { begin = start.begin, end_ = end_ },
			vars = vars,
			values = values,
			body = body,
			hasIn = hasIn,
			inLocation = inLocation,
			hasDo = hasDo,
			doLocation = {
				begin = { line = Do_start_line, column = Do_start_col },
				end_ = { line = Do_end_line, column = Do_end_col },
			},
		} :: Syntax.AstStatForIn

		if storeCstData then
			node.cstNode = {
				kind = "CstStatForIn",
				varsAnnotationColonPositions = extractAnnotationColonPositions(names),
				varsCommaPositions = varsCommaPosition,
				valuesCommaPositions = valuesCommaPositions,
			}
		end

		return node
	end
end

-- NAME
const function parseNameExprImpl(context: string): Syntax.AstExprLocal | Syntax.AstExprGlobal | Syntax.AstExprError
	const nameOpt = parseNameOptImpl(context)

	if not nameOpt then
		return {
			kind = "ExprError",
			location = snapshot(),
			expressions = {},
			messageIndex = #parseErrors,
		}
	end

	const name = nameOpt
	const local_ = localMap[name.name.value]

	if local_ then
		if local_.functionDepth < (typeFunctionDepth or 0) then
			return reportExprError(snapshot(), {}, "Type function cannot reference outer local '%s'", local_.name)
		end

		return {
			kind = "ExprLocal",
			location = name.location,
			["local"] = local_,
			upvalue = local_.functionDepth ~= (#functionStack - 1),
		}
	end

	return {
		kind = "ExprGlobal",
		location = name.location,
		name = name.name.value,
	}
end

-- funcname ::= Name {`.' Name} [`:' Name]
const function parseFunctionName(hasRef: { boolean }, debugnameRef: { string? }): Syntax.AstExprIndexName
	if token_type == 281 then
		debugnameRef[1] = token_string
	end

	-- parse funcname into a chain of indexing operators
	local expr = parseNameExprImpl("function name")

	const oldRecursionCount = recursionCounter

	while token_type == 46 do
		const opPosition = { line = token_start_line, column = token_start_col }
		nextLexeme()

		const name = parseNameImpl("field name")

		-- while we could concatenate the name chain, for now let's just write the short name
		debugnameRef[1] = name.name.value

		expr = {
			kind = "ExprIndexName",
			location = {
				begin = expr.location.begin,
				end_ = name.location.end_,
			},
			expr = expr,
			index = name.name.value,
			indexLocation = name.location,
			opPosition = opPosition,
			op = 46,
		}

		-- note: while the parser isn't recursive here, we're generating recursive structures of unbounded depth
		incrementRecursionCounter("function name")
	end

	recursionCounter = oldRecursionCount

	-- finish with :
	if token_type == 58 then
		const opPosition = { line = token_start_line, column = token_start_col }
		nextLexeme()

		const name = parseNameImpl("method name")

		-- while we could concatenate the name chain, for now let's just write the short name
		debugnameRef[1] = name.name.value

		expr = {
			kind = "ExprIndexName",
			location = {
				begin = expr.location.begin,
				end_ = name.location.end_,
			},
			expr = expr,
			index = name.name.value,
			indexLocation = name.location,
			opPosition = opPosition,
			op = 58,
		}

		hasRef[1] = true
	end

	return expr :: Syntax.AstExprIndexName
end

const function shouldParseTypePack()
	const t = token_type

	if t == 262 then
		return true
	end

	if t == 281 and next_type == 262 then
		return true
	end

	return false
end

const function parseTypePackImpl(): Syntax.AstTypePackVariadic | Syntax.AstTypePackGeneric
	-- Variadic: ...T
	if token_type == 262 then
		const start = snapshot()
		nextLexeme()
		const varTy = parseTypeImpl(false)
		return {
			kind = "TypePackVariadic",
			location = {
				begin = start.begin,
				end_ = varTy.location.end_,
			},
			variadicType = varTy,
		}

		-- Generic: a...
	elseif token_type == 281 and next_type == 262 then
		const name = parseNameImpl("generic name")
		const endLoc = snapshot()

		-- This will not fail because of the lookahead guard.
		expectAndConsume(262, "generic type pack annotation")

		const node = {
			kind = "TypePackGeneric",
			location = {
				begin = name.location.begin,
				end_ = endLoc.end_,
			},
			genericName = name.name.value,
		}

		if storeCstData then
			node.cstNode = {
				kind = "CstTypePackGeneric",
				ellipsisPosition = endLoc.begin,
			}
		end

		return node :: Syntax.AstTypePackGeneric
	end

	-- TODO: shouldParseTypePack can be removed and parseTypePack can be called unconditionally instead
	error("parseTypePack can't be called if shouldParseTypePack() returned false")
end

const function parseSimpleTypeOrPackImpl(): (Syntax.AstType?, Syntax.AstTypePack?)
	const oldRec = recursionCounter
	-- recursion counter is incremented in parseSimpleType

	const begin = snapshot()

	const type_, typePack = ParserFunctions.parseSimpleType(true, false)

	if typePack then
		return nil, typePack
	end

	recursionCounter = oldRec

	return parseTypeSuffixImpl(type_, begin), nil
end

const function parseGenericTypeListImpl(
	withDefaultValues: boolean,
	openPosRef: { Syntax.Position }?,
	commaPosRef: { Syntax.Position }?,
	closePosRef: { Syntax.Position }?
): ({ Syntax.AstGenericType }, { Syntax.AstGenericTypePack })
	const names: { Syntax.AstGenericType } = {}
	const namePacks: { Syntax.AstGenericTypePack } = {}
	const localCommaPositions: { Syntax.Position } = {}

	if token_type == 60 then
		const begin_type = token_type
		const begin_start_line, begin_start_col = token_start_line, token_start_col

		if openPosRef then
			openPosRef[1] = { line = begin_start_line, column = begin_start_col }
		end

		nextLexeme()

		local seenPack = false
		local seenDefault = false

		while true do
			const nameLoc = snapshot()
			const nameBinding = parseNameImpl()
			const name = nameBinding.name.value

			if token_type == 262 or seenPack then
				seenPack = true
				local ellipsisPosition = { line = 0, column = 0 }

				if token_type ~= 262 then
					report(snapshot(), "Generic types come before generic type packs")
				else
					ellipsisPosition = { line = token_start_line, column = token_start_col }
					nextLexeme()
				end

				if withDefaultValues and token_type == 61 then
					seenDefault = true
					const equalsPosition = { line = token_start_line, column = token_start_col }
					nextLexeme()

					local typePack: Syntax.AstTypePack? = nil
					if shouldParseTypePack() then
						typePack = parseTypePackImpl()
					else
						const type_, pack_ = parseSimpleTypeOrPackImpl()
						if type_ then
							report(type_.location, "Expected type pack after '=', got type")
						end
						typePack = pack_
					end

					const node = {
						kind = "GenericTypePack",
						location = nameLoc,
						name = name,
						defaultValue = typePack,
					} :: Syntax.AstGenericTypePack

					if storeCstData then
						node.cstNode = {
							kind = "CstGenericTypePack",
							ellipsisPosition = ellipsisPosition,
							defaultEqualsPosition = equalsPosition,
						} :: Syntax.CstGenericTypePack
					end

					table.insert(namePacks, node)
				else
					if seenDefault then
						report(snapshot(), "Expected default type pack after type pack name")
					end

					const node = {
						kind = "GenericTypePack",
						location = nameLoc,
						name = name,
						defaultValue = nil,
					} :: Syntax.AstGenericTypePack

					if storeCstData then
						node.cstNode = {
							kind = "CstGenericTypePack",
							ellipsisPosition = ellipsisPosition,
							defaultEqualsPosition = nil,
						} :: Syntax.CstGenericTypePack
					end

					table.insert(namePacks, node)
				end
			else
				if withDefaultValues and token_type == 61 then
					seenDefault = true
					const equalsPosition = { line = token_start_line, column = token_start_col }
					nextLexeme()

					const defaultType = parseTypeImpl()

					const node = {
						kind = "GenericType",
						location = nameLoc,
						name = name,
						defaultValue = defaultType,
					} :: Syntax.AstGenericType

					if storeCstData then
						node.cstNode = {
							kind = "CstGenericType",
							defaultEqualsPosition = equalsPosition,
						} :: Syntax.CstGenericType
					end
					table.insert(names, node)
				else
					if seenDefault then
						report(snapshot(), "Expected default type after type name")
					end

					const node = {
						kind = "GenericType",
						location = nameLoc,
						name = name,
						defaultValue = nil,
					} :: Syntax.AstGenericType

					if storeCstData then
						node.cstNode = {
							kind = "CstGenericType",
							defaultEqualsPosition = nil,
						} :: Syntax.CstGenericType
					end
					table.insert(names, node)
				end
			end

			if token_type == 44 then
				if commaPosRef then
					table.insert(localCommaPositions, { line = token_start_line, column = token_start_col })
				end
				nextLexeme()

				if token_type == 62 then
					report(snapshot(), "Expected type after ',' but got '>' instead")
					break
				end
			else
				break
			end
		end

		if expectMatchAndConsume(62, begin_type, begin_start_line, begin_start_col) and closePosRef then
			closePosRef[1] = { line = prev_start_line, column = prev_start_col }
		end
	end

	if commaPosRef then
		for _, v in localCommaPositions do
			table.insert(commaPosRef, v)
		end
	end

	return names, namePacks
end

const function parseOptionalReturnTypeImpl(returnSpecifierPosRef: { Syntax.Position }?): Syntax.AstTypePack?
	if token_type == 58 or token_type == 263 then
		if token_type == 263 then
			report(snapshot(), "Function return type annotations are written after ':' instead of '->'")
		end

		if returnSpecifierPosRef then
			returnSpecifierPosRef[1] = { line = token_start_line, column = token_start_col }
		end

		nextLexeme()

		const oldRecursion = recursionCounter
		const res = ParserFunctions.parseReturnType()
		recursionCounter = oldRecursion

		-- At this point, if we find a , character, it indicates that there are multiple return types
		-- in this type annotation, but the list wasn't wrapped in parentheses.
		if token_type == 44 then
			report(
				snapshot(),
				"Expected a statement, got ','; did you forget to wrap the list of return types in parentheses?"
			)
			nextLexeme()
		end

		return res
	end

	return nil
end

const function prepareFunctionArgumentsImpl(start: Syntax.Location, hasself: boolean, args: { Syntax.Binding }): (Syntax.AstLocal?, { Syntax.AstLocal })
	local selfLocal: Syntax.AstLocal? = nil
	if hasself then
		selfLocal = pushLocal({
			name = { value = "self" },
			location = start,
			annotation = nil,
			colonPosition = nil,
		})
	end

	const vars: { Syntax.AstLocal } = {}
	for _, arg in args do
		table.insert(vars, pushLocal(arg))
	end

	return selfLocal, vars
end

-- funcbody ::= `(' [parlist] `)' [`:' ReturnType] block end
-- parlist ::= bindinglist [`,' `...'] | `...'
const function parseFunctionBodyImpl(
	hasself: boolean,
	matchFunction: Syntax.Lexeme,
	debugname: string?,
	localName: string?,
	localNameLocation: Syntax.Location?,
	attributes: Syntax.Attrs,
	cstAttrLists: { Syntax.CstAttrList }?,
	isConst: boolean?
): (Syntax.AstExprFunction, Syntax.AstLocal?)
	local start = matchFunction.location
	if #attributes > 0 then
		start = attributes[1].location
	end

	local cstNode: Syntax.CstExprFunction? = nil
	if storeCstData then
		cstNode = {
			kind = "CstExprFunction",
			attrLists = cstAttrLists or {},
			functionKeywordPosition = matchFunction.location.begin,
			openGenericsPosition = { line = 0, column = 0 },
			genericsCommaPositions = {},
			closeGenericsPosition = { line = 0, column = 0 },
			argsAnnotationColonPositions = {},
			argsCommaPositions = {},
			varargAnnotationColonPosition = { line = 0, column = 0 },
			returnSpecifierPosition = { line = 0, column = 0 },
		} :: Syntax.CstExprFunction
	end

	const openGenPosRef = cstNode and { cstNode.openGenericsPosition } or nil
	const genCommaPosRef = cstNode and cstNode.genericsCommaPositions or nil
	const closeGenPosRef = cstNode and { cstNode.closeGenericsPosition } or nil

	const generics, genericPacks = parseGenericTypeListImpl(false, openGenPosRef, genCommaPosRef, closeGenPosRef)

	if cstNode and openGenPosRef then
		cstNode.openGenericsPosition = openGenPosRef[1]
	end
	if cstNode and closeGenPosRef then
		cstNode.closeGenericsPosition = closeGenPosRef[1]
	end

	const Paren_type = token_type
	const Paren_line = token_start_line
	const Paren_col = token_start_col

	expectAndConsume(40, "function")

	-- NOTE: This was added in conjunction with passing `searchForMissing` to
	-- `expectMatchAndConsume` inside `parseTableType` so that the behavior of
	-- parsing code like below (note the missing `}`):

	-- function (t: { a: number  ) end

	-- ... will still parse as (roughly):

	-- function (t: { a: number }) end

	matchRecovery[41] += 1

	const args = {} :: { Syntax.Binding }
	local vararg = false
	local varargLocation: Syntax.Location? = nil
	local varargAnnotation: Syntax.AstTypePack? = nil

	if token_type ~= 41 then
		const vaAnnotPosRef = cstNode and { cstNode.varargAnnotationColonPosition :: Syntax.Position? } or nil

		vararg, varargLocation, varargAnnotation =
			parseBindingList(args, true, if cstNode then cstNode.argsCommaPositions else nil, nil, vaAnnotPosRef, false)

		if cstNode and vaAnnotPosRef then
			cstNode.varargAnnotationColonPosition = vaAnnotPosRef[1]
		end
	end

	local argLocation: Syntax.Location? = nil
	if Paren_type == 40 and token_type == 41 then
		argLocation = {
			begin = { line = Paren_line, column = Paren_col },
			end_ = { line = token_end_line, column = token_end_col },
		}
	end

	expectMatchAndConsume(41, Paren_type, Paren_line, Paren_col, true)
	matchRecovery[41] -= 1

	const retSpecPosRef = cstNode and { cstNode.returnSpecifierPosition } or nil
	const typelist = parseOptionalReturnTypeImpl(retSpecPosRef)
	if cstNode and retSpecPosRef then
		cstNode.returnSpecifierPosition = retSpecPosRef[1]
	end

	local funLocal: Syntax.AstLocal? = nil
	if localName then
		const bindingLocation = localNameLocation or start
		funLocal = pushLocal({
			name = { value = localName },
			location = bindingLocation,
			annotation = nil,
			colonPosition = nil,
			isConst = isConst == true,
		} :: Syntax.Binding)
	end

	const localsBegin = #localStack

	const fun = { vararg = vararg, loopDepth = 0 } :: Syntax.FunctionState
	table.insert(functionStack, fun)

	const selfLocal, vars = prepareFunctionArgumentsImpl(start, hasself, args)

	const body = parseBlock()

	table.remove(functionStack)

	restoreLocals(localsBegin)

	const end_ = snapshot()
	const hasEnd = expectMatchEndAndConsume(
		296,
		matchFunction.type,
		matchFunction.location.begin.line,
		matchFunction.location.begin.column
	)
	body.hasEnd = hasEnd

	const node = {
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
		functionDepth = #functionStack,
		debugname = debugname,
		returnAnnotation = typelist,
		varargAnnotation = varargAnnotation,
		argLocation = argLocation,
	} :: Syntax.AstExprFunction

	if storeCstData and cstNode then
		cstNode.argsAnnotationColonPositions = extractAnnotationColonPositions(args)
		node.cstNode = cstNode
	end

	return node, funLocal
end

-- function funcname funcbody
const function parseFunctionStatImpl(
	attributes: Syntax.Attrs,
	attributeStartLocation: Syntax.Location?,
	cstAttrLists: { Syntax.CstAttrList }?
): Syntax.AstStatFunction
	local start = snapshot()
	if attributeStartLocation ~= nil then
		start = attributeStartLocation
	elseif #attributes > 0 then
		start = attributes[1].location
	end

	const matchFunction = get_lexeme()
	nextLexeme()

	const hasRef = { false }
	const debugnameRef: { string? } = {}
	local expr: Syntax.AstExpr = parseFunctionName(hasRef, debugnameRef)

	if not isExprLValue(expr) then
		expr = if LuauExportValueSyntax
			then reportLValueError(expr)
			else reportExprError(expr.location, { expr }, "Assigned expression must be a variable or a field")
	end

	matchRecovery[296] += 1

	const body = parseFunctionBodyImpl(hasRef[1], matchFunction, debugnameRef[1], nil, nil, attributes, nil, false)

	matchRecovery[296] -= 1

	const node = {
		kind = "StatFunction",
		location = {
			begin = start.begin,
			end_ = body.location.end_,
		},
		name = expr,
		func = body,
	} :: Syntax.AstStatFunction

	if storeCstData then
		node.cstNode = {
			kind = "CstStatFunction",
			attrLists = cstAttrLists or {},
			functionKeywordPosition = matchFunction.location.begin,
		}
	end

	return node
end

const function validateAttribute(
	loc: Syntax.Location,
	attributeName: string,
	attributes: Syntax.Attrs,
	args: { Syntax.AstExpr }
)
	-- check if the attribute name is valid
	const entry = kAttributeEntries[attributeName]
	local type_: string? = nil
	local argsValidator: ((Syntax.Location, { Syntax.AstExpr }) -> { Syntax.ParseError })? = nil

	if entry then
		type_ = entry.type
		argsValidator = entry.argsValidator
	elseif DebugLuauNoInline and kDebugAttributeEntries[attributeName] then
		type_ = kDebugAttributeEntries[attributeName].type
	else
		if #attributeName == 0 then
			report(loc, "Attribute name is missing")
		else
			report(loc, "Invalid attribute '@%s'", attributeName)
		end
	end

	if type_ then
		-- check that attribute is not duplicated
		for _, attr in attributes do
			if attr.type == type_ then
				report(loc, "Cannot duplicate attribute '@%s'", attributeName)
			end
		end

		if argsValidator then
			const validator = argsValidator :: (Syntax.Location, { Syntax.AstExpr }) -> { Syntax.ParseError }
			const errors = validator(loc, args)
			for _, err in errors do
				report(err.location, "%s", err.message)
			end
		end
	end

	return type_
end

const function tableSeparator(): number?
	if token_type == 44 then
		return 0
	elseif token_type == 59 then
		return 1
	else
		return nil
	end
end

const function cstSeparatorPosition(separator: number?): Syntax.Position
	return if separator == nil then { line = 0, column = 0 } else { line = token_start_line, column = token_start_col }
end

-- tableconstructor ::= `{' [fieldlist] `}'
-- fieldlist ::= field {fieldsep field} [fieldsep]
-- field ::= `[' exp `]' `=' exp | Name `=' exp | exp
-- fieldsep ::= `,' | `;'
const function parseTableConstructorImpl(): Syntax.AstExprTable
	const items = {} :: { Syntax.AstExprTableItem }
	const cstItems: { Syntax.CstExprTableItem } = {}

	const start = snapshot()

	const brace_type, brace_line, brace_col = token_type, token_start_line, token_start_col
	expectAndConsume(123, "table literal")

	local lastElementIndent = 0

	while token_type ~= 125 do
		if not LuauTableEntriesDontNeedToMatchIndent then
			lastElementIndent = token_start_col
		end

		local indexerOpenPos: Syntax.Position? = nil
		local indexerClosePos: Syntax.Position? = nil
		local equalsPos: Syntax.Position? = nil

		if token_type == 91 then
			indexerOpenPos = { line = token_start_line, column = token_start_col }
			const bracket_type, bracket_line, bracket_col = token_type, token_start_line, token_start_col
			nextLexeme()

			const key = ParserFunctions.parseExpr()

			if expectMatchAndConsume(93, bracket_type, bracket_line, bracket_col) then
				indexerClosePos = { line = prev_start_line, column = prev_start_col }
			end

			if expectAndConsume(61, "table field") then
				equalsPos = { line = prev_start_line, column = prev_start_col }
			end

			const value = ParserFunctions.parseExpr()

			table.insert(
				items,
				{
					kind = "General",
					key = key,
					value = value,
				} :: Syntax.AstExprTableItem
			)

			if storeCstData then
				const separator = tableSeparator()
				table.insert(
					cstItems,
					{
						kind = "General",
						indexerOpenPosition = indexerOpenPos,
						indexerClosePosition = indexerClosePos,
						equalsPosition = equalsPos,
						separator = separator,
						separatorPosition = cstSeparatorPosition(separator),
					} :: Syntax.CstExprTableItem
				)
			end
		elseif token_type == 281 and next_type == 61 then
			const name = parseNameImpl("table field")

			if expectAndConsume(61, "table field") then
				equalsPos = { line = prev_start_line, column = prev_start_col }
			end

			const key = {
				kind = "ExprConstantString",
				location = name.location,
				value = name.name.value,
				quoteStyle = QuoteStyle.Unquoted,
			}

			const value = ParserFunctions.parseExpr()

			if value.kind == "ExprFunction" then
				value.debugname = name.name.value
			end

			table.insert(
				items,
				{
					kind = "Record",
					key = key,
					value = value,
				} :: Syntax.AstExprTableItem
			)

			if storeCstData then
				const separator = tableSeparator()
				table.insert(
					cstItems,
					{
						kind = "Record",
						equalsPosition = equalsPos,
						separator = separator,
						separatorPosition = cstSeparatorPosition(separator),
					} :: Syntax.CstExprTableItem
				)
			end
		else
			const expr = ParserFunctions.parseExpr()
			table.insert(
				items,
				{
					kind = "List",
					value = expr,
				} :: Syntax.AstExprTableItem
			)

			if storeCstData then
				const separator = tableSeparator()
				table.insert(
					cstItems,
					{
						kind = "List",
						separator = separator,
						separatorPosition = cstSeparatorPosition(separator),
					} :: Syntax.CstExprTableItem
				)
			end
		end

		if token_type == 44 or token_type == 59 then
			nextLexeme()
		elseif
			(token_type == 91 or token_type == 281)
			and (LuauTableEntriesDontNeedToMatchIndent or token_start_col == lastElementIndent)
		then
			report(snapshot(), "Expected ',' after table constructor element")
		elseif token_type ~= 125 then
			break
		end
	end

	local end_ = snapshot()
	if not expectMatchAndConsume(125, brace_type, brace_line, brace_col) then
		end_ = getprev()
	end

	const node = {
		kind = "ExprTable",
		location = { begin = start.begin, end_ = end_.end_ },
		items = items,
	} :: Syntax.AstExprTable

	if storeCstData then
		node.cstNode = {
			kind = "CstExprTable",
			items = cstItems,
		} :: Syntax.CstExprTable
	end

	return node
end

const function extractStringDetails()
	local style = 0
	local depth = 0

	if token_type == 279 then
		style = token_aux == 0 and CstQuotes.QuotedSingle or CstQuotes.QuotedDouble
	elseif token_type == 269 then
		style = CstQuotes.QuotedInterp
	elseif token_type == 278 then
		style = CstQuotes.QuotedRaw
		depth = token_aux or 0
	end

	return style, depth
end

const function parseCharArrayImpl(): string?
	const t = token_type
	local data = token_string or ""

	if t == 279 or t == 269 then
		const ok, fixed = fixupQuotedString(data)
		if not ok then
			nextLexeme()
			return nil
		end
		data = fixed :: string
	else
		data = fixupMultilineString(data)
	end

	nextLexeme()
	return data
end

const function parseStringImpl(): Syntax.AstExprConstantString | Syntax.AstExprError
	const location = snapshot()
	local quoteStyle = QuoteStyle.QuotedSimple

	if token_type == 279 then
		if token_aux == 0 then
			quoteStyle = QuoteStyle.QuotedSingle
		else
			quoteStyle = QuoteStyle.QuotedSimple
		end
	elseif token_type == 269 then
		quoteStyle = QuoteStyle.QuotedSimple
	elseif token_type == 278 then
		quoteStyle = QuoteStyle.QuotedRaw
	end

	local fullStyle = 0
	local blockDepth = 0
	if storeCstData then
		fullStyle, blockDepth = extractStringDetails()
	end

	local originalString: string? = nil
	if storeCstData then
		originalString = token_string
	end

	const value = parseCharArrayImpl()

	if value then
		const node = {
			kind = "ExprConstantString",
			location = location,
			value = value,
			quoteStyle = quoteStyle,
		} :: Syntax.AstExprConstantString

		if storeCstData then
			node.cstNode = {
				kind = "CstExprConstantString",
				sourceString = originalString,
				quoteStyle = fullStyle,
				blockDepth = blockDepth,
			}
		end

		return node :: Syntax.AstExprConstantString
	else
		return reportExprError(location, {}, "String literal contains malformed escape sequence")
	end
end

const function parseCallListImpl(commaPositions: { Syntax.Position }?): (
	{ Syntax.AstExpr },
	Syntax.Location,
	Syntax.Location,
	Syntax.Position?
)
	if token_type == 40 then
		const argStart = { line = token_end_line, column = token_end_col }
		const paren_type, paren_line, paren_col = token_type, token_start_line, token_start_col

		nextLexeme()

		const args: { Syntax.AstExpr } = {}

		if token_type ~= 41 then
			parseExprListImpl(args, commaPositions)
		end

		const end_ = snapshot()
		local closeParenPosition: Syntax.Position? = nil
		if expectMatchAndConsume(41, paren_type, paren_line, paren_col) then
			closeParenPosition = end_.begin
		end

		return args,
			{
				begin = argStart,
				end_ = end_.end_,
			},
			{
				begin = { line = paren_line, column = paren_col },
				end_ = { line = prev_start_line, column = prev_start_col },
			},
			closeParenPosition
	elseif token_type == 123 then
		const argStart = { line = token_end_line, column = token_end_col }
		const expr = parseTableConstructorImpl()

		return { expr } :: { Syntax.AstExpr },
			{
				begin = argStart,
				end_ = { line = prev_end_line, column = prev_end_col },
			},
			expr.location,
			nil
	else
		const argLoc = snapshot()
		const expr = parseStringImpl()
		return { expr } :: { Syntax.AstExpr }, argLoc, expr.location, nil
	end
end

-- attribute ::= '@' NAME
const function parseAttribute(attributes: Syntax.Attrs): (Syntax.Location, Syntax.CstAttrList?)
	if token_type == 284 then
		const loc = snapshot()
		const name = token_string or ""
		const type_ = validateAttribute(loc, name, attributes, {})
		nextLexeme()
		const attr = {
			kind = "Attr",
			location = loc,
			type = type_ or "Unknown",
			args = {},
			name = name,
		} :: Syntax.AstAttr

		if storeCstData then
			attr.cstNode = {
				kind = "CstAttr",
				hasAt = true,
			}
		end

		table.insert(attributes, attr)

		return loc, nil
	else
		const open_type = token_type
		const open_start_line, open_start_col = token_start_line, token_start_col
		const openLocation = {
			begin = { line = open_start_line, column = open_start_col },
			end_ = { line = open_start_line, column = open_start_col },
		}
		const commaPositions: { Syntax.Position } = {}

		nextLexeme()
		if token_type ~= 93 then
			while true do
				const name = parseNameImpl("attribute name")
				const nameLoc = name.location
				const attrName = name.name.value
				local args: { Syntax.AstExpr } = {}
				local argsLocation = snapshot()
				local hasArgs = false
				local openParenPosition = { line = 0, column = 0 }
				local closeParenPosition = { line = 0, column = 0 }
				const argsCommaPositions: { Syntax.Position } = {}

				if token_type == 278 or token_type == 279 or token_type == 123 or token_type == 40 then
					const argOpenType = token_type
					if argOpenType == 40 then
						openParenPosition = { line = token_start_line, column = token_start_col }
					end

					const args_, argsLoc_, _, parsedCloseParenPosition =
						parseCallListImpl(storeCstData and argsCommaPositions or nil)
					args = args_
					argsLocation = argsLoc_
					hasArgs = true
					if argOpenType == 40 and parsedCloseParenPosition then
						closeParenPosition = parsedCloseParenPosition
					end

					for _, arg in args do
						if not ConstantLiteral[arg.kind] and not isLiteralTable(arg) then
							report(argsLocation, "Only literals can be passed as arguments for attributes")
						end
					end
				end

				const type_ = validateAttribute(nameLoc, attrName, attributes, args)
				local attrLocation = nameLoc
				if hasArgs then
					attrLocation = {
						begin = nameLoc.begin,
						end_ = argsLocation.end_,
					}
				end

				const attr = {
					kind = "Attr",
					location = attrLocation,
					type = type_ or "Unknown",
					args = args,
					name = attrName,
				} :: Syntax.AstAttr

				if storeCstData then
					attr.cstNode = if hasArgs
						then {
							kind = "CstParametrizedAttr",
							openParenPosition = openParenPosition,
							closeParenPosition = closeParenPosition,
							argsCommaPositions = argsCommaPositions,
						}
						else {
							kind = "CstAttr",
							hasAt = false,
						}
				end

				table.insert(attributes, attr)

				if token_type == 44 then
					if storeCstData then
						table.insert(commaPositions, { line = token_start_line, column = token_start_col })
					end
					nextLexeme()
				else
					break
				end
			end
		else
			const errorLocation = {
				begin = { line = open_start_line, column = open_start_col },
				end_ = { line = token_end_line, column = token_end_col },
			}

			report(errorLocation, "Attribute list cannot be empty")

			const attr = {
				kind = "Attr",
				location = errorLocation,
				type = "Unknown",
				args = {},
				name = "%error-id%",
			} :: Syntax.AstAttr

			if storeCstData then
				attr.cstNode = {
					kind = "CstAttr",
					hasAt = false,
				}
			end

			table.insert(attributes, attr)
		end

		const closeBracketPosition = if token_type == 93
			then { line = token_start_line, column = token_start_col }
			else { line = 0, column = 0 }
		expectMatchAndConsume(93, open_type, open_start_line, open_start_col)

		return openLocation,
			{
				kind = "CstAttrList",
				atBracketPosition = openLocation.begin,
				closeBracketPosition = closeBracketPosition,
				commaPositions = commaPositions,
			}
	end
end

-- attributes ::= {attribute}
const function parseAttributes(): (Syntax.Attrs, Syntax.Location?, { Syntax.CstAttrList })
	const attributes: Syntax.Attrs = {}
	local startLocation: Syntax.Location? = nil
	const cstAttrLists: { Syntax.CstAttrList } = {}

	while token_type == 284 or token_type == 285 do
		const attributeStart, cstAttrList = parseAttribute(attributes)
		if startLocation == nil then
			startLocation = attributeStart
		end
		if storeCstData and cstAttrList then
			table.insert(cstAttrLists, cstAttrList)
		end
	end

	return attributes, startLocation, cstAttrLists
end

const function isEnoughValues(values: { Syntax.AstExpr }, expected: number): boolean
	if #values > 0 then
		const last = values[#values]
		if last.kind == "ExprCall" or last.kind == "ExprVarargs" then
			return true
		end
	end

	return #values == expected
end

const function parseLocalImpl(
	start: Syntax.Location,
	keywordPosition: Syntax.Position,
	attributes: Syntax.Attrs,
	cstAttrLists: { Syntax.CstAttrList }?,
	isConst: boolean
): Syntax.AstStatLocal | Syntax.AstStatLocalFunction | Syntax.AstStatError
	if not isConst then
		nextLexeme() -- local
	end

	if token_type == 299 then
		const matchFunction = get_lexeme()
		nextLexeme()

		const functionKeywordPosition = matchFunction.location.begin
		-- matchFunction is only used for diagnostics; to make it suitable for detecting missed indentation between
		-- `local function` and `end`, we patch the token to begin at the column where `local` starts
		if matchFunction.location.begin.line == start.begin.line then
			matchFunction.location.begin.column = start.begin.column
		end

		const name = parseNameImpl("variable name")

		matchRecovery[296] += 1

		const body, var = parseFunctionBodyImpl(
			false,
			matchFunction,
			name.name.value,
			name.name.value,
			name.location,
			attributes,
			nil,
			isConst
		)

		matchRecovery[296] -= 1

		const node = {
			kind = "StatLocalFunction",
			location = { begin = start.begin, end_ = body.location.end_ },
			name = var,
			func = body,
			isConst = isConst,
			constKeywordBegin = if isConst and LuauStoreConstKeywordBegin then keywordPosition else nil,
		} :: Syntax.AstStatLocalFunction

		if storeCstData then
			node.cstNode = {
				kind = "CstStatLocalFunction",
				attrLists = cstAttrLists or {},
				localKeywordPosition = keywordPosition,
				functionKeywordPosition = functionKeywordPosition,
			}
		end

		return node
	else
		if #attributes ~= 0 then
			return reportStatError(
				snapshot(),
				{},
				{},
				"Expected 'function' after local declaration with attribute, but got %s instead",
				ToString(token_type, token_string, token_codepoint)
			)
		end

		matchRecovery[61] += 1

		const names: { Syntax.Binding } = {}
		const varsCommaPositions: { Syntax.Position } = {}
		if storeCstData then
			parseBindingList(names, false, varsCommaPositions, nil, nil, isConst)
		else
			parseBindingList(names, false, nil, nil, nil, isConst)
		end

		matchRecovery[61] -= 1

		const vars: { Syntax.AstLocal } = {}
		const values: { Syntax.AstExpr } = {}
		const valuesCommaPositions: { Syntax.Position } = {}
		local equalsSignLocation: Syntax.Location? = nil

		if token_type == 61 then
			equalsSignLocation = snapshot()
			nextLexeme()
			parseExprListImpl(values, storeCstData and valuesCommaPositions or nil)
		end

		for _, binding in names do
			table.insert(vars, pushLocal(binding))
		end

		local end_
		if #values == 0 then
			end_ = { line = prev_end_line, column = prev_end_col }
		else
			end_ = values[#values].location.end_
		end

		if isConst and not isEnoughValues(values, #vars) then
			report({ begin = start.begin, end_ = end_ }, "Missing initializer in const declaration")
		end

		const node = {
			kind = "StatLocal",
			location = { begin = start.begin, end_ = end_ },
			vars = vars,
			values = values,
			equalsSignLocation = equalsSignLocation,
			isConst = isConst,
			isExported = false,
		} :: Syntax.AstStatLocal

		if storeCstData then
			node.cstNode = {
				kind = "CstStatLocal",
				varsAnnotationColonPositions = extractAnnotationColonPositions(names),
				varsCommaPositions = varsCommaPositions,
				valuesCommaPositions = valuesCommaPositions,
			}
		end

		return node
	end
end

const function checkDuplicateExport(name: string, location: Syntax.Location): boolean
	if declaredExportBindings[name] then
		return false
	end

	declaredExportBindings[name] = location
	return true
end

const function exportLocalStat(stat: Syntax.AstStat, keywordLocation: Syntax.Location): Syntax.AstStat
	if stat.kind == "StatLocal" then
		stat.isExported = true

		for _, local_ in stat.vars do
			if not checkDuplicateExport(local_.name, local_.location) then
				report(local_.location, "Duplicate exported identifier '%s'", local_.name)
			else
				local_.isExported = true
			end
		end

		stat.keywordLocation = keywordLocation
	end

	return stat
end

const function parseClassStatImpl(start: Syntax.Location, exported: boolean): Syntax.AstStatClass | Syntax.AstStatError
	local name = parseNameOptImpl("type name")

	if not name then
		name = {
			name = { value = "%error-id%" },
			location = snapshot(),
		} :: Syntax.Binding
	end
	const className = name :: Syntax.Binding

	const savedLocals = #localStack
	const nameLocal = pushLocal({
		name = className.name,
		location = className.location,
		annotation = nil,
		colonPosition = nil,
		isConst = true,
	} :: Syntax.Binding)

	const members = {} :: { Syntax.AstClassMember }
	const memberNames: { [string]: boolean } = {}

	while token_type ~= 296 and token_type ~= 0 do
		local qualifierLocation = nil :: Syntax.Location?
		if token_type == 281 and token_string == "public" then
			qualifierLocation = snapshot()
			nextLexeme()
		end

		if qualifierLocation and token_type ~= 299 then
			const propName = parseNameOptImpl("class property name")
			if not propName then
				continue
			end

			local propType = nil :: Syntax.AstType?
			local typeColonLocation = nil :: Syntax.Location?

			if token_type == 58 then
				typeColonLocation = snapshot()
				nextLexeme()
				propType = parseTypeImpl()
			end

			if string.sub(propName.name.value, 1, 2) == "__" then
				report(propName.location, "Class properties cannot start with '__'")
			end

			if memberNames[propName.name.value] then
				report(propName.location, "Duplicate class member '%s'", propName.name.value)
			else
				memberNames[propName.name.value] = true
				table.insert(
					members,
					{
						kind = "ClassProperty",
						qualifierLocation = qualifierLocation,
						name = propName.name,
						nameLocation = propName.location,
						typeColonLocation = typeColonLocation,
						type = propType,
					} :: Syntax.AstClassProperty
				)
			end
		elseif token_type == 299 then
			const matchFunction = get_lexeme()
			nextLexeme()

			const methodName = parseNameImpl("method name")

			matchRecovery[296] += 1
			const body = parseFunctionBodyImpl(false, matchFunction, methodName.name.value, nil, nil, {}, nil, false)
			matchRecovery[296] -= 1

			const selfAnnotation = if #body.args > 0 and body.args[1].name == "self" then body.args[1].annotation else nil
			if selfAnnotation then
				report(selfAnnotation.location, "The 'self' parameter cannot have a type annotation")
			end

			if string.sub(methodName.name.value, 1, 2) == "__" then
				if DisallowedClassMetamethods[methodName.name.value] then
					report(methodName.location, "Classes cannot define '%s' as a metamethod", methodName.name.value)
				elseif not AllowedClassMetamethods[methodName.name.value] then
					report(
						methodName.location,
						"Cannot use '%s' as a method name: names starting with '__' are reserved",
						methodName.name.value
					)
				end
			end

			if memberNames[methodName.name.value] then
				report(methodName.location, "Duplicate class member '%s'", methodName.name.value)
			else
				memberNames[methodName.name.value] = true
				table.insert(
					members,
					{
						kind = "ClassMethod",
						qualifierLocation = qualifierLocation,
						keywordLocation = matchFunction.location,
						functionName = methodName.name,
						nameLocation = methodName.location,
						func = body,
					} :: Syntax.AstClassMethod
				)
			end
		else
			report(snapshot(), "Only class properties and functions can be declared within a class")
			nextLexeme()
		end
	end

	const endLocation = snapshot()
	expectAndConsume(296, "class")

	const node = {
		kind = "StatClass",
		location = { begin = start.begin, end_ = endLocation.end_ },
		name = nameLocal,
		members = members,
		exported = exported,
	} :: Syntax.AstStatClass

	if recursionCounter > 1 then
		report(nameLocal.location, "Cannot declare class '%s' inside another statement or expression", nameLocal.name)
	end

	if classesWithinModule[nameLocal.name] then
		restoreLocals(savedLocals)
		return reportStatError(
			nameLocal.location,
			{},
			{ node },
			"A class named '%s' has already been declared in this module",
			nameLocal.name
		)
	end

	classesWithinModule[nameLocal.name] = true
	return node
end

const function parseExportValueImpl(
	start: Syntax.Location,
	keywordPosition: Syntax.Position,
	attributes: Syntax.Attrs,
	cstAttrLists: { Syntax.CstAttrList }?
): Syntax.AstStat
	if #functionStack ~= 1 or recursionCounter ~= 1 then
		report(start, "'export' may only be applied to top-level statements")
	end

	if hasModuleReturn then
		report(start, "Exporting values is not compatible with top-level return (export/return conflict)")
	end

	if #attributes ~= 0 and token_type ~= 299 then
		report(
			snapshot(),
			"Expected 'function' after export declaration with attribute, but got %s instead",
			ToString(token_type, token_string, token_codepoint)
		)
	end

	if token_type == 302 then
		const localKeywordLocation = snapshot()

		if next_type == 299 then
			report(start, "'export' must be followed by an identifier or 'function'; try removing 'local'")
			return parseLocalImpl(start, localKeywordLocation.begin, {}, nil, true)
		end

		return exportLocalStat(parseLocalImpl(start, keywordPosition, {}, nil, false), localKeywordLocation)
	elseif token_type == 299 then
		const stat = parseLocalImpl(start, keywordPosition, attributes, cstAttrLists, true)

		if stat.kind == "StatLocalFunction" and stat.name then
			if not checkDuplicateExport(stat.name.name, stat.name.location) then
				report(stat.name.location, "Duplicate exported identifier '%s'", stat.name.name)
			end

			stat.name.isExported = true
			stat.name.isConst = true
		end

		return stat
	elseif token_type == 281 and token_string == "const" then
		const constKeywordLocation = snapshot()
		nextLexeme()

		if token_type == 299 then
			report(start, "'export' must be followed by an identifier or 'function'")
			return parseLocalImpl(start, constKeywordLocation.begin, {}, nil, true)
		end

		return exportLocalStat(parseLocalImpl(start, constKeywordLocation.begin, {}, nil, true), constKeywordLocation)
	elseif DebugLuauUserDefinedClasses and token_type == 281 and token_string == "class" then
		nextLexeme()
		const stat = parseClassStatImpl(start, true)

		if stat.kind == "StatClass" then
			if not checkDuplicateExport(stat.name.name, stat.name.location) then
				report(stat.name.location, "Duplicate exported class '%s'", stat.name.name)
			end

			stat.name.isExported = true
		end

		return stat
	end

	return reportStatError(start, {}, {}, "'export' must be followed by an identifier or 'function'")
end

-- prefixexp -> NAME | '(' expr ')'
const function parsePrefixExprImpl(): Syntax.AstExpr
	if token_type == 40 then
		const start = { line = token_start_line, column = token_start_col }
		const Paren_type = token_type
		const Paren_line = token_start_line
		const Paren_col = token_start_col
		nextLexeme()

		const expr = ParserFunctions.parseExpr()

		local end_ = { line = token_end_line, column = token_end_col }
		local closePosition = { line = 0, column = 0 }
		if token_type ~= 41 then
			expectMatchAndConsumeFail(

				41,
				Paren_type,
				Paren_line,
				Paren_col,
				token_type == 61 and "; did you mean to use '{' when defining a table?" or nil
			)

			end_ = { line = prev_end_line, column = prev_end_col }
		else
			closePosition = { line = token_start_line, column = token_start_col }
			nextLexeme()
		end

		const node = {
			kind = "ExprGroup",
			location = {
				begin = start,
				end_ = end_,
			},
			expr = expr,
		} :: Syntax.AstExprGroup

		if storeCstData then
			node.cstNode = {
				kind = "CstExprGroup",
				closePosition = closePosition,
			}
		end

		return node
	else
		return parseNameExprImpl("expression")
	end
end

const function parseIndexNameImpl(context: string?, prev: Syntax.Position): Syntax.Binding
	const nameOpt = parseNameOptImpl(context)
	if nameOpt then
		return nameOpt
	end

	if token_type >= 291 and token_type < 312 and prev and token_start_line == prev.line then
		const result = {
			name = { value = token_string },
			location = snapshot(),
		} :: Syntax.Binding

		nextLexeme()
		return result
	end

	return {
		name = { value = "%error-id%" },
		location = snapshot(),
	}
end

const function parseTypeParamsImpl(
	openingPosRef: { Syntax.Position }?,
	commaPosRef: { Syntax.Position }?,
	closingPosRef: { Syntax.Position }?
): { Syntax.AstTypeOrPack }
	const params = {} :: { Syntax.AstTypeOrPack }

	if token_type == 60 then
		const begin = get_lexeme()
		if openingPosRef then
			openingPosRef[1] = begin.location.begin
		end

		nextLexeme()

		while true do
			if shouldParseTypePack() then
				const pack = parseTypePackImpl()
				table.insert(params, { typePack = pack, type = nil })
			elseif token_type == 40 then
				const beginParen = snapshot()
				local type_: Syntax.AstType? = nil
				local typePack: Syntax.AstTypePack? = nil
				const t = token_type

				if t ~= 124 and t ~= 38 then
					type_, typePack = ParserFunctions.parseSimpleType(true, false)
				end

				--/ Consider the following type:

				--  X<(T)>

				-- Is this a type pack or a parenthesized type? The
				-- assumption will be a type pack, as that's what allows one
				-- to express either a singular type pack or a potential
				-- complex type.

				if typePack then
					if
						typePack.kind == "TypePackExplicit"
						and #typePack.types == 1
						and not typePack.tailType
						and (token_type == 124 or token_type == 63 or token_type == 38)
					then
						-- If we parsed an explicit type pack with a single
						-- type in it (something of the form `(T)`), and
						-- the next lexeme is one that follows a type
						-- (&, |, ?), then assume that this was actually a
						-- parenthesized type.

						const parenTy = typePack.types[1]

						const node = {
							kind = "TypeGroup",
							location = parenTy.location,
							type = parenTy,
						} :: Syntax.AstTypeGroup

						if storeCstData then
							local closePosition = parenTy.location.end_
							if typePack.cstNode and typePack.cstNode.closeParenthesesPosition then
								closePosition = typePack.cstNode.closeParenthesesPosition
							end

							node.cstNode = {
								kind = "CstTypeGroup",
								closePosition = closePosition,
							}
						end

						table.insert(params, { type = parseTypeSuffixImpl(node, beginParen), typePack = nil })
					else
						-- Otherwise, it's a type pack.
						table.insert(params, { type = nil, typePack = typePack })
					end
				else
					table.insert(params, { type = parseTypeSuffixImpl(type_, beginParen), typePack = nil })
				end
			elseif token_type == 62 and #params == 0 then
				break
			else
				table.insert(params, { type = parseTypeImpl(false), typePack = nil })
			end

			if token_type == 44 then
				if commaPosRef then
					table.insert(commaPosRef, { line = token_start_line, column = token_start_col })
				end
				nextLexeme()
			else
				break
			end
		end

		if expectMatchAndConsume(62, begin.type, begin.location.begin.line, begin.location.begin.column, false) and closingPosRef then
			closingPosRef[1] = { line = prev_start_line, column = prev_start_col }
		end
	end
	return params
end

-- // Explicit Type Instantiation

const function parseTypeInstantiationExpr(): ({ Syntax.AstTypeOrPack }, Syntax.CstTypeInstantiation, Syntax.Location)
	const begin_type, begin_line, begin_col = token_type, token_start_line, token_start_col
	const leftArrow1 = { line = token_start_line, column = token_start_col }
	nextLexeme()

	const leftArrow2Ref: { Syntax.Position } = {}
	const commaPositions: { Syntax.Position } = {}
	const rightArrow1Ref: { Syntax.Position } = {}

	const typesOrPacks = parseTypeParamsImpl(leftArrow2Ref, commaPositions, rightArrow1Ref)

	const endLocation = snapshot()
	const rightArrow2 = if token_type == 62 then endLocation.begin else { line = 0, column = 0 }
	expectMatchAndConsume(62, begin_type, begin_line, begin_col)

	const cstData = {
		kind = "CstTypeInstantiation",
		leftArrow1Position = leftArrow1,
		leftArrow2Position = leftArrow2Ref[1],
		commaPositions = commaPositions,
		rightArrow1Position = rightArrow1Ref[1],
		rightArrow2Position = rightArrow2,
	} :: Syntax.CstTypeInstantiation

	return typesOrPacks, cstData, endLocation
end

const function reportAmbiguousCallError()
	report(
		snapshot(),
		"Ambiguous syntax: this looks like an argument list for a function call, but could also be a start of new statement; use ';' to separate statements"
	)
end

const function reportFunctionArgsErrorImpl(func: Syntax.AstExpr, selfCall: boolean): Syntax.AstExpr
	if selfCall and token_start_line ~= func.location.end_.line then
		return reportExprError(func.location :: Syntax.Location, { func }, "Expected function call arguments after '('")
	else
		return reportExprError(
			{
				begin = func.location.begin,
				end_ = { line = token_start_line, column = token_start_col },
			},
			{ func },
			"Expected '(', '{' or <string> when parsing function call, got %s",
			ToString(token_type, token_string, token_codepoint)
		)
	end
end

-- args ::=  `(' [explist] `)' | tableconstructor | String
const function parseFunctionArgsImpl(func: Syntax.AstExpr, selfCall: boolean): Syntax.AstExpr
	if token_type == 40 then
		const argStart = { line = token_end_line, column = token_end_col }
		if func.location.end_.line ~= token_start_line then
			reportAmbiguousCallError()
		end

		const paren_type, paren_line, paren_col = token_type, token_start_line, token_start_col
		nextLexeme()

		const args: { Syntax.AstExpr } = {}
		const commaPositions: { Syntax.Position } = {}
		if token_type ~= 41 then
			parseExprListImpl(args, commaPositions)
		end

		const end_ = snapshot()
		local closeParen = { line = 0, column = 0 }
		if expectMatchAndConsume(41, paren_type, paren_line, paren_col) then
			closeParen = { line = prev_start_line, column = prev_start_col }
		end

		const result = {
			kind = "ExprCall",
			location = { begin = func.location.begin, end_ = end_.end_ },
			func = func,
			args = args,
			self = selfCall,
			typeArguments = {} :: { Syntax.AstTypeOrPack },
			argLocation = { begin = argStart, end_ = end_.end_ },
		} :: Syntax.AstExprCall

		if storeCstData then
			result.cstNode = {
				kind = "CstExprCall",
				openParens = { line = paren_line, column = paren_col },
				closeParens = closeParen,
				commaPositions = commaPositions,
				explicitTypes = nil,
			}
		end

		return result
	elseif token_type == 123 then
		const argStart = { line = token_end_line, column = token_end_col }
		const expr = parseTableConstructorImpl()
		const argEnd = { line = prev_end_line, column = prev_end_col }

		const result = {
			kind = "ExprCall",
			location = {
				begin = func.location.begin,
				end_ = expr.location.end_,
			},
			func = func,
			args = { expr },
			self = selfCall,
			typeArguments = {},
			argLocation = {
				begin = argStart,
				end_ = argEnd,
			},
		} :: Syntax.AstExprCall

		if storeCstData then
			result.cstNode = {
				kind = "CstExprCall",
				commaPositions = {},
				explicitTypes = nil,
			}
		end

		return result
	elseif token_type == 278 or token_type == 279 then
		const argLocation = snapshot()
		const expr = parseStringImpl()

		const result = {
			kind = "ExprCall",
			location = {
				begin = func.location.begin,
				end_ = expr.location.end_,
			},
			func = func,
			args = { expr },
			self = selfCall,
			typeArguments = {},
			argLocation = argLocation,
		} :: Syntax.AstExprCall

		if storeCstData then
			result.cstNode = {
				kind = "CstExprCall",
				commaPositions = {},
				explicitTypes = nil,
			}
		end

		return result
	else
		return reportFunctionArgsErrorImpl(func, selfCall)
	end
end

const function parseExplicitTypeInstantiationExpr(
	start: Syntax.Position,
	basedOnExpr: Syntax.AstExpr
): Syntax.AstExprInstantiate
	const typesOrPacks, cstInstantiation, endLocation = parseTypeInstantiationExpr()

	const expr = {
		kind = "ExprInstantiate",
		location = { begin = start, end_ = endLocation.end_ },
		expr = basedOnExpr,
		typeArguments = typesOrPacks,
	} :: Syntax.AstExprInstantiate

	if storeCstData then
		expr.cstNode = {
			kind = "CstExprExplicitTypeInstantiation",
			instantiation = cstInstantiation,
		}
	end

	return expr
end

-- primaryexp -> prefixexp { `.' NAME | `[' exp `]' | `:' NAME funcargs | funcargs }
const function parsePrimaryExprImpl(asStatement: boolean): Syntax.AstExpr
	const start = { line = token_start_line, column = token_start_col }
	local expr: Syntax.AstExpr = parsePrefixExprImpl()

	const oldRecursion = recursionCounter

	while true do
		if token_type == 46 then
			const opPosition = { line = token_start_line, column = token_start_col }
			nextLexeme()

			const index = parseIndexNameImpl(nil, opPosition)

			expr = {
				kind = "ExprIndexName",
				location = { begin = start, end_ = index.location.end_ },
				expr = expr,
				index = index.name.value,
				indexLocation = index.location,
				opPosition = opPosition,
				op = 46,
			} :: Syntax.AstExprIndexName
		elseif token_type == 91 then
			const bracket_type, bracket_line, bracket_col = token_type, token_start_line, token_start_col
			const openBracket = { line = token_start_line, column = token_start_col }
			nextLexeme()

			const index = ParserFunctions.parseExpr()
			const end_ = { line = token_end_line, column = token_end_col }
			local closeBracket = { line = 0, column = 0 }

			if expectMatchAndConsume(93, bracket_type, bracket_line, bracket_col) then
				closeBracket = { line = prev_start_line, column = prev_start_col }
			end

			expr = {
				kind = "ExprIndexExpr",
				location = { begin = start, end_ = end_ },
				expr = expr,
				index = index,
			} :: Syntax.AstExprIndexExpr

			if storeCstData then
				expr.cstNode = {
					kind = "CstExprIndexExpr",
					openBracketPosition = openBracket,
					closeBracketPosition = closeBracket,
				}
			end
		elseif token_type == 58 then
			const opPosition = { line = token_start_line, column = token_start_col }
			nextLexeme()

			const index = parseIndexNameImpl("method name", opPosition)

			const func = {
				kind = "ExprIndexName",
				location = { begin = start, end_ = index.location.end_ },
				expr = expr,
				index = index.name.value,
				indexLocation = index.location,
				opPosition = opPosition,
				op = 58,
			} :: Syntax.AstExprIndexName

			local typeArgs: { Syntax.AstTypeOrPack } = {}
			local cstInstantiation: Syntax.CstTypeInstantiation? = nil

			if token_type == 60 and next_type == 60 then
				typeArgs, cstInstantiation = parseTypeInstantiationExpr()
			end

			const callExpr = parseFunctionArgsImpl(func, true)
			expr = callExpr

			if #typeArgs > 0 and callExpr.kind == "ExprCall" then
				callExpr.typeArguments = typeArgs
			end

			if storeCstData and cstInstantiation and (callExpr :: Syntax.AstExprCall).cstNode then
				(callExpr.cstNode :: Syntax.CstExprCall).explicitTypes = cstInstantiation
			end
		elseif token_type == 40 then
			-- This error is handled inside 'parseFunctionArgs' as well, but for better error recovery we need to break out the current loop here
			if not asStatement and expr.location.end_.line ~= token_start_line then
				reportAmbiguousCallError()
				break
			end
			expr = parseFunctionArgsImpl(expr, false)
		elseif token_type == 123 or token_type == 278 or token_type == 279 then
			expr = parseFunctionArgsImpl(expr, false)
		elseif token_type == 60 and next_type == 60 then
			expr = parseExplicitTypeInstantiationExpr(start, expr)
		else
			break
		end

		-- note: while the parser isn't recursive here, we're generating recursive structures of unbounded depth
		incrementRecursionCounter("expression")
	end

	recursionCounter = oldRecursion
	return expr
end

const function emptyReturnTypePack(location: Syntax.Location): Syntax.AstTypePackExplicit
	return {
		kind = "TypePackExplicit",
		location = location,
		types = {},
		tailType = nil,
	} :: Syntax.AstTypePackExplicit
end

const function parseDeclaredExternTypeMethodImpl(attributes: Syntax.Attrs): Syntax.AstDeclaredExternTypeProperty
	const start = snapshot()
	local matchParen = get_lexeme()
	nextLexeme()

	const fnName = parseNameImpl("function name")

	matchParen = get_lexeme()
	expectAndConsume(40, "function parameter list start")

	const args = {} :: { Syntax.Binding }
	local vararg = false
	local varargAnnotation = nil :: Syntax.AstTypePack?

	if token_type ~= 41 then
		vararg, _, varargAnnotation = parseBindingList(args, true)
	end

	expectMatchAndConsume(41, matchParen.type, matchParen.location.begin.line, matchParen.location.begin.column)

	local retTypes = parseOptionalReturnTypeImpl(nil)
	if not retTypes then
		retTypes = emptyReturnTypePack(snapshot())
	end

	const endLocation = getprev()
	const methodLocation = { begin = start.begin, end_ = endLocation.end_ }

	if #args == 0 or args[1].name.value ~= "self" or args[1].annotation ~= nil then
		return {
			kind = "DeclaredExternTypeProperty",
			name = fnName.name,
			nameLocation = fnName.location,
			type = reportTypeError(methodLocation, {}, "'self' must be present as the unannotated first parameter"),
			isMethod = true,
			location = methodLocation,
			access = "ReadWrite",
		} :: Syntax.AstDeclaredExternTypeProperty
	end

	const params = {} :: { Syntax.AstType }
	const paramNames = {} :: { Syntax.AstArgumentName | boolean }

	for i = 2, #args do
		const arg = args[i]
		table.insert(paramNames, { name = arg.name.value, location = arg.location })

		if arg.annotation then
			table.insert(params, arg.annotation)
		else
			table.insert(
				params,
				reportTypeError(methodLocation, {}, "All declaration parameters aside from 'self' must be annotated")
			)
		end
	end

	if vararg and not varargAnnotation then
		report(start, "All declaration parameters aside from 'self' must be annotated")
	end

	const fnType = {
		kind = "TypeFunction",
		location = methodLocation,
		attributes = attributes,
		generics = {} :: { Syntax.AstGenericType },
		genericPacks = {} :: { Syntax.AstGenericTypePack },
		argTypes = {
			types = params,
			tailType = varargAnnotation,
		},
		argNames = paramNames,
		returnTypes = retTypes,
	} :: Syntax.AstTypeFunction

	return {
		kind = "DeclaredExternTypeProperty",
		name = fnName.name,
		nameLocation = fnName.location,
		type = fnType,
		isMethod = true,
		location = methodLocation,
		access = "ReadWrite",
	} :: Syntax.AstDeclaredExternTypeProperty
end

-- TableIndexer ::= `[' Type `]' `:' Type
const function parseTableIndexerImpl(
	access: Syntax.AstTableAccess,
	accessLoc: Syntax.Location?,
	begin: Syntax.Lexeme
): {
	node: Syntax.AstTableIndexer,
	indexerOpenPosition: Syntax.Position,
	indexerClosePosition: Syntax.Position,
	colonPosition: Syntax.Position,
}
	const index = parseTypeImpl(false)

	local indexerClosePos = { line = 0, column = 0 }
	if expectMatchAndConsume(93, begin.type, begin.location.begin.line, begin.location.begin.column) then
		indexerClosePos = { line = prev_start_line, column = prev_start_col }
	end

	local colonPos = { line = 0, column = 0 }
	if expectAndConsume(58, "table field") then
		colonPos = { line = prev_start_line, column = prev_start_col }
	end

	const result = parseTypeImpl(false)

	const node = {
		kind = "TableIndexer",
		location = {
			begin = begin.location.begin,
			end_ = result.location.end_,
		},
		indexType = index,
		resultType = result,
		access = access,
		accessLocation = accessLoc,
	} :: Syntax.AstTableIndexer

	return {
		node = node,
		indexerOpenPosition = begin.location.begin,
		indexerClosePosition = indexerClosePos,
		colonPosition = colonPos,
	}
end

const function parseDeclarationImpl(start: Syntax.Location, attributes: Syntax.Attrs): Syntax.AstStat
	if #attributes ~= 0 and token_type ~= 299 then
		return reportStatError(
			snapshot(),
			{},
			{},
			"Expected a function type declaration after attribute, but got %s instead",
			ToString(token_type, token_string, token_codepoint)
		)
	end

	if token_type == 299 then
		nextLexeme()

		const globalName = parseNameImpl("global function name")
		const generics, genericPacks = parseGenericTypeListImpl(false)

		const matchParen = get_lexeme()
		expectAndConsume(40, "global function declaration")

		const args = {} :: { Syntax.Binding }
		local vararg = false
		local varargLocation = nil :: Syntax.Location?
		local varargAnnotation = nil :: Syntax.AstTypePack?

		if token_type ~= 41 then
			vararg, varargLocation, varargAnnotation = parseBindingList(args, true)
		end

		expectMatchAndConsume(41, matchParen.type, matchParen.location.begin.line, matchParen.location.begin.column)

		local retTypes = parseOptionalReturnTypeImpl(nil)
		const endLocation = snapshot()
		if not retTypes then
			retTypes = emptyReturnTypePack(snapshot())
		end

		const params = {} :: { Syntax.AstType }
		const paramNames = {} :: { Syntax.AstArgumentName }
		const declLocation = { begin = start.begin, end_ = endLocation.end_ }

		for _, arg in args do
			if not arg.annotation then
				return reportStatError(declLocation, {}, {}, "All declaration parameters must be annotated")
			end

			table.insert(params, arg.annotation)
			table.insert(paramNames, { name = arg.name.value, location = arg.location })
		end

		if vararg and not varargAnnotation then
			return reportStatError(declLocation, {}, {}, "All declaration parameters must be annotated")
		end

		return {
			kind = "StatDeclareFunction",
			location = declLocation,
			attributes = attributes,
			name = globalName.name.value,
			nameLocation = globalName.location,
			generics = generics,
			genericPacks = genericPacks,
			params = {
				types = params,
				tailType = varargAnnotation,
			},
			paramNames = paramNames,
			vararg = vararg,
			varargLocation = varargLocation,
			retTypes = retTypes,
		} :: Syntax.AstStatDeclareFunction
	elseif
		token_type == 281
		and (
			if LuauDisallowExternClassInTypeDefinitions
				then token_string == "extern"
				else (
					token_string == "extern"
					or (
						token_string == "class"
						and (if LuauAllowGlobalDeclarationToBeCalledClass then next_type ~= 58 else true)
					)
				)
		)
	then
		local foundExtern = false

		if token_string == "extern" then
			if not LuauDisallowExternClassInTypeDefinitions then
				foundExtern = true
			end

			nextLexeme()

			if token_type ~= 281 or token_string ~= "type" then
				return reportStatError(
					snapshot(),
					{},
					{},
					"Expected `type` keyword after `extern`, but got %s instead",
					ToString(token_type, token_string, token_codepoint)
				)
			end
		end

		nextLexeme()

		const typeStart = snapshot()
		const typeName = parseNameImpl("type name")
		local superName = nil :: string?

		if token_type == 281 and token_string == "extends" then
			nextLexeme()
			superName = parseNameImpl("supertype name").name.value
		end

		if LuauDisallowExternClassInTypeDefinitions or foundExtern then
			if token_type == 281 and token_string == "with" then
				nextLexeme()
			else
				report(
					snapshot(),
					"Expected `with` keyword before listing properties of the external type, but got %s instead",
					ToString(token_type, token_string, token_codepoint)
				)
			end
		end

		const props = {} :: { Syntax.AstDeclaredExternTypeProperty }
		local indexer = nil :: Syntax.AstTableIndexer?

		while token_type ~= 296 and token_type ~= 0 do
			local methodAttributes = {} :: Syntax.Attrs

			if token_type == 284 or token_type == 285 then
				methodAttributes = parseAttributes()

				if token_type ~= 299 then
					return reportStatError(
						snapshot(),
						{},
						{},
						"Expected a method type declaration after attribute, but got %s instead",
						ToString(token_type, token_string, token_codepoint)
					)
				end
			end

			if token_type == 299 then
				table.insert(props, parseDeclaredExternTypeMethodImpl(methodAttributes))
			elseif token_type == 91 then
				const begin = get_lexeme()
				nextLexeme()

				if (token_type == 278 or token_type == 279) and next_type == 93 then
					const nameLocation = snapshot()
					const chars = parseCharArrayImpl()
					const nameEnd = getprev()

					expectMatchAndConsume(93, begin.type, begin.location.begin.line, begin.location.begin.column)
					expectAndConsume(58, "property type annotation")
					const propType = parseTypeImpl(true)

					if chars and string.find(chars, "\0", 1, true) == nil then
						table.insert(
							props,
							{
								kind = "DeclaredExternTypeProperty",
								name = { value = chars },
								nameLocation = { begin = nameLocation.begin, end_ = nameEnd.end_ },
								type = propType,
								isMethod = false,
								location = { begin = begin.location.begin, end_ = propType.location.end_ },
								access = "ReadWrite",
							} :: Syntax.AstDeclaredExternTypeProperty
						)
					else
						report(begin.location, "String literal contains malformed escape sequence or \\0")
					end
				elseif indexer then
					const badIndexer = parseTableIndexerImpl("ReadWrite", nil, begin)
					report(badIndexer.node.location, "Cannot have more than one indexer on an extern type")
				else
					indexer = parseTableIndexerImpl("ReadWrite", nil, begin).node
				end
			else
				local access: Syntax.AstTableAccess = "ReadWrite"
				local accessLocation = nil :: Syntax.Location?

				if token_type == 281 and next_type ~= 58 then
					if token_string == "read" then
						access = "Read"
						accessLocation = snapshot()
						nextLexeme()
					elseif token_string == "write" then
						access = "Write"
						accessLocation = snapshot()
						nextLexeme()
					else
						report(snapshot(), "Expected blank or 'read' or 'write' attribute, got '%s'", token_string or "")
						nextLexeme()
					end
				end

				const propStart = snapshot()
				const propName = parseNameOptImpl("property name")
				if not propName then
					break
				end

				expectAndConsume(58, "property type annotation")
				const propType = parseTypeImpl(true)

				table.insert(
					props,
					{
						kind = "DeclaredExternTypeProperty",
						name = propName.name,
						nameLocation = propName.location,
						type = propType,
						isMethod = false,
						location = { begin = propStart.begin, end_ = propType.location.end_ },
						access = access,
					} :: Syntax.AstDeclaredExternTypeProperty
				)

				if accessLocation then
					props[#props].location.begin = accessLocation.begin
				end
			end

			if token_type == 44 or token_type == 59 then
				nextLexeme()
			end
		end

		const typeEnd = snapshot()
		expectAndConsume(296, "extern type")

		return {
			kind = "StatDeclareExternType",
			location = { begin = typeStart.begin, end_ = typeEnd.end_ },
			name = typeName.name.value,
			superName = superName,
			props = props,
			indexer = indexer,
		} :: Syntax.AstStatDeclareExternType
	end

	const globalName = parseNameOptImpl("global variable name")
	if globalName then
		expectAndConsume(58, "global variable declaration")
		const type_ = parseTypeImpl(true)

		return {
			kind = "StatDeclareGlobal",
			location = { begin = start.begin, end_ = type_.location.end_ },
			name = globalName.name.value,
			nameLocation = globalName.location,
			type = type_,
		} :: Syntax.AstStatDeclareGlobal
	end

	return reportStatError(start, {}, {}, "declare must be followed by an identifier, 'function', or 'extern type'")
end

-- attributes local function Name funcbody
-- attributes function funcname funcbody
-- attributes `declare function' Name`(' [parlist] `)' [`:` Type]
-- declare Name '{' Name ':' attributes `(' [parlist] `)' [`:` Type] '}'
const function parseAttributeStatImpl(): Syntax.AstStat
	const attributes, attributeStartLocation, cstAttrLists = parseAttributes()
	const type_ = token_type

	if type_ == 299 then
		return parseFunctionStatImpl(attributes, attributeStartLocation, cstAttrLists)
	elseif type_ == 302 then
		const keywordLocation = snapshot()
		return parseLocalImpl(
			attributeStartLocation or keywordLocation,
			keywordLocation.begin,
			attributes,
			cstAttrLists,
			false
		)
	elseif type_ == 281 and token_string == "const" then
		const keywordLocation = snapshot()
		nextLexeme()
		return parseLocalImpl(
			attributeStartLocation or keywordLocation,
			keywordLocation.begin,
			attributes,
			cstAttrLists,
			true
		)
	elseif LuauExportValueSyntax and type_ == 281 and token_string == "export" then
		const keywordLocation = snapshot()
		nextLexeme()
		return parseExportValueImpl(
			attributeStartLocation or keywordLocation,
			keywordLocation.begin,
			attributes,
			cstAttrLists
		)
	elseif options.allowDeclarationSyntax and type_ == 281 and token_string == "declare" then
		const expr = parsePrimaryExprImpl(true)
		return parseDeclarationImpl(expr.location, attributes)
	end

	return reportStatError(
		snapshot(),
		{},
		{},
		"Expected 'function', 'local function', 'const function', 'declare function' or a function type declaration after attribute, but got %s instead",
		ToString(token_type, token_string, token_codepoint)
	)
end

-- return [explist]
const function parseReturnImpl(): Syntax.AstStatReturn
	const start = snapshot()
	nextLexeme()

	if LuauExportValueSyntax and #functionStack == 1 then
		for _, exportLocation in declaredExportBindings do
			report(
				exportLocation,
				"Exporting values is not compatible with top-level return (export/return conflict)"
			)
			break
		end

		hasModuleReturn = true
	end

	const list: { Syntax.AstExpr } = {}
	const commaPositions: { Syntax.Position } = {}

	if not BlockFollow[token_type] and token_type ~= 59 then
		parseExprListImpl(list, storeCstData and commaPositions or nil)
	end

	local end_ = start.end_
	if #list > 0 then
		end_ = list[#list].location.end_
	end

	const node = {
		kind = "StatReturn",
		location = {
			begin = start.begin,
			end_ = end_,
		},
		list = list,
	} :: Syntax.AstStatReturn

	if storeCstData then
		node.cstNode = {
			kind = "CstStatReturn",
			commaPositions = commaPositions,
		}
	end

	return node
end

-- type function Name `(' arglist `)' `=' funcbody `end'
const function parseTypeFunctionImpl(
	start: Syntax.Location,
	exported: boolean,
	typeKeywordPosition: Syntax.Position
): Syntax.AstStatTypeFunction
	const matchFn = get_lexeme()
	nextLexeme()

	const errorsAtStart = #parseErrors

	-- parse the name of the type function
	const fnNameOpt = parseNameOptImpl("type function name")
	local fnName = fnNameOpt :: Syntax.Binding

	if fnName == nil then
		fnName = {
			name = { value = "%error-id%" },
			location = snapshot(),
		} :: Syntax.Binding
	end

	matchRecovery[296] += 1

	const oldTypeFunctionDepth = typeFunctionDepth
	typeFunctionDepth = #functionStack

	const body = parseFunctionBodyImpl(false, matchFn, fnName.name.value, nil, nil, {}, nil, false)

	typeFunctionDepth = oldTypeFunctionDepth
	matchRecovery[296] -= 1

	const hasErrors = #parseErrors > errorsAtStart

	const node = {
		kind = "StatTypeFunction",
		location = {
			begin = start.begin,
			end_ = body.location.end_,
		},
		name = fnName.name.value,
		nameLocation = fnName.location,
		body = body,
		exported = exported,
		hasErrors = hasErrors,
	} :: Syntax.AstStatTypeFunction

	if storeCstData then
		node.cstNode = {
			kind = "CstStatTypeFunction",
			typeKeywordPosition = typeKeywordPosition,
			functionKeywordPosition = matchFn.location.begin,
		}
	end

	return node
end

-- type Name [`<' varlist `>'] `=' Type
const function parseTypeAliasImpl(
	start: Syntax.Location,
	exported: boolean,
	typeKeywordPosition: Syntax.Position
): Syntax.AstStatTypeAlias | Syntax.AstStatTypeFunction
	-- parsing a type function
	if token_type == 299 then
		return parseTypeFunctionImpl(start, exported, typeKeywordPosition)
	end

	-- parsing a type alias

	-- note: `type` token is already parsed for us, so we just need to parse the rest

	const nameOpt = parseNameOptImpl("type name")
	local name = nameOpt :: Syntax.Binding

	-- Use error name if the name is missing
	if not name then
		name = {
			name = { value = "%error-id%" },
			location = snapshot(),
		} :: Syntax.Binding
	end

	const genericsCommaPos: { Syntax.Position } = {}

	const genericsClosePos = {
		{ line = 0, column = 0 },
	}

	const genericsOpenPos = {
		{ line = 0, column = 0 },
	}

	local generics: { Syntax.AstGenericType }, genericPacks: { Syntax.AstGenericTypePack }
	if storeCstData then
		generics, genericPacks = parseGenericTypeListImpl(true, genericsOpenPos, genericsCommaPos, genericsClosePos)
	else
		generics, genericPacks = parseGenericTypeListImpl(true)
	end

	local equalsPosition = { line = 0, column = 0 }
	if expectAndConsume(61, "type alias") then
		equalsPosition = { line = prev_start_line, column = prev_start_col }
	end

	const type_ = parseTypeImpl()

	const node = {
		kind = "StatTypeAlias",
		location = { begin = start.begin, end_ = type_.location.end_ },
		name = name.name.value,
		nameLocation = name.location,
		generics = generics,
		genericPacks = genericPacks,
		type = type_,
		exported = exported,
	} :: Syntax.AstStatTypeAlias

	if storeCstData then
		node.cstNode = {
			kind = "CstStatTypeAlias",
			typeKeywordPosition = typeKeywordPosition,
			genericsOpenPosition = genericsOpenPos[1],
			genericsCommaPositions = genericsCommaPos,
			genericsClosePosition = genericsClosePos[1],
			equalsPosition = equalsPosition,
		}
	end

	return node
end

-- varlist `=' explist
const function parseAssignmentImpl(initial: Syntax.AstExpr): Syntax.AstStatAssign
	if not isExprLValue(initial) then
		initial = if LuauExportValueSyntax
			then reportLValueError(initial)
			else reportExprError(initial.location, { initial }, "Assigned expression must be a variable or a field")
	end

	const vars: { Syntax.AstExpr } = { initial }
	const varsCommaPositions: { Syntax.Position } = {}

	while token_type == 44 do
		if storeCstData then
			table.insert(varsCommaPositions, { line = token_start_line, column = token_start_col })
		end
		nextLexeme()

		local expr = parsePrimaryExprImpl(true)
		if not isExprLValue(expr) then
			expr = if LuauExportValueSyntax
				then reportLValueError(expr)
				else reportExprError(expr.location, { expr }, "Assigned expression must be a variable or a field")
		end
		table.insert(vars, expr)
	end

	local equalsPosition = { line = 0, column = 0 }
	if expectAndConsume(61, "assignment") then
		equalsPosition = { line = prev_start_line, column = prev_start_col }
	end

	const values: { Syntax.AstExpr } = {}
	const valuesCommaPositions: { Syntax.Position } = {}
	parseExprListImpl(values, storeCstData and valuesCommaPositions or nil)

	const end_ = values[#values].location

	const node = {
		kind = "StatAssign",
		location = { begin = initial.location.begin, end_ = end_.end_ },
		vars = vars,
		values = values,
	} :: Syntax.AstStatAssign

	if storeCstData then
		node.cstNode = {
			kind = "CstStatAssign",
			varsCommaPositions = varsCommaPositions,
			equalsPosition = equalsPosition,
			valuesCommaPositions = valuesCommaPositions,
		}
	end

	return node
end

-- var [`+=' | `-=' | `*=' | `/=' | `%=' | `^=' | `..='] exp
const function parseCompoundAssignmentImpl(initial: Syntax.AstExpr, op: number): Syntax.AstStatCompoundAssign
	if not isExprLValue(initial) then
		initial = if LuauExportValueSyntax
			then reportLValueError(initial)
			else reportExprError(initial.location, { initial }, "Assigned expression must be a variable or a field")
	end

	const opPosition = { line = token_start_line, column = token_start_col }
	nextLexeme()

	const value = ParserFunctions.parseExpr()

	const node = {
		kind = "StatCompoundAssign",
		location = { begin = initial.location.begin, end_ = value.location.end_ },
		op = op,
		var = initial,
		value = value,
	} :: Syntax.AstStatCompoundAssign

	if storeCstData then
		node.cstNode = {
			kind = "CstStatCompoundAssign",
			opPosition = opPosition,
		}
	end

	return node
end

-- TypeList ::= Type [`,' TypeList] | ...Type
const function parseTypeListImpl(
	result: { Syntax.AstType },
	resultNames: { Syntax.AstArgumentName | boolean },
	commaPositions: { Syntax.Position }?,
	nameColonPositions: { Syntax.Position | boolean }?
): Syntax.AstTypePack?
	while true do
		if shouldParseTypePack() then
			return parseTypePackImpl()
		end

		if token_type == 281 and next_type == 58 then
			-- Fill in previous argument names with empty slots
			while #resultNames < #result do
				table.insert(resultNames, false)
				if nameColonPositions then
					table.insert(nameColonPositions, false)
				end
			end

			const name = {
				name = token_string :: string,
				location = snapshot(),
			}

			table.insert(resultNames, name)
			nextLexeme()

			if nameColonPositions then
				table.insert(nameColonPositions, { line = token_start_line, column = token_start_col })
			end

			expectAndConsume(58)
		elseif #resultNames > 0 then
			-- If we have a type with named arguments, provide elements for all types
			table.insert(resultNames, false)
			if nameColonPositions then
				table.insert(nameColonPositions, false)
			end
		end

		table.insert(result, parseTypeImpl(false))

		if token_type ~= 44 then
			break
		end

		if commaPositions then
			table.insert(commaPositions, { line = token_start_line, column = token_start_col })
		end
		nextLexeme()

		if token_type == 41 then
			report(snapshot(), "Expected type after ',' but got ')' instead")

			break
		end
	end
	return nil
end

-- TableProp ::= Name `:' Type
-- TablePropOrIndexer ::= TableProp | TableIndexer
-- PropList ::= TablePropOrIndexer {fieldsep TablePropOrIndexer} [fieldsep]
-- TableType ::= `{' PropList `}'
const function parseTableTypeImpl(inDeclarationContext: boolean): Syntax.AstTypeTable
	incrementRecursionCounter("type annotation")

	const props: { Syntax.AstTableProp } = {}
	const cstItems: { Syntax.CstTypeTableItem } = {}
	local indexer: Syntax.AstTableIndexer? = nil

	const start = snapshot()
	const matchBrace = get_lexeme()
	expectAndConsume(123, "table type")

	local isArray = false

	while token_type ~= 125 do
		local access: Syntax.AstTableAccess = "ReadWrite"
		local accessLoc: Syntax.Location? = nil

		if token_type == 281 and next_type ~= 58 then
			if token_string == "read" then
				accessLoc = snapshot()
				access = "Read"
				nextLexeme()
			elseif token_string == "write" then
				accessLoc = snapshot()
				access = "Write"
				nextLexeme()
			end
		end

		if token_type == 91 then
			const begin = get_lexeme()
			nextLexeme()

			if (token_type == 278 or token_type == 279) and next_type == 93 then
				local style = 0
				local depth = 0
				if storeCstData then
					style, depth = extractStringDetails()
				end

				const stringPos = { line = token_start_line, column = token_start_col }
				local sourceString: string? = nil
				if storeCstData then
					sourceString = token_string
				end

				const chars = parseCharArrayImpl()

				local indexerClosePos = { line = 0, column = 0 }
				if expectMatchAndConsume(93, begin.type, begin.location.begin.line, begin.location.begin.column) then
					indexerClosePos = { line = prev_start_line, column = prev_start_col }
				end

				local colonPos = { line = 0, column = 0 }
				if expectAndConsume(58, "table field") then
					colonPos = { line = prev_start_line, column = prev_start_col }
				end

				const type_ = parseTypeImpl()

				if chars and string.find(chars, "\0", 1, true) == nil then
					table.insert(
						props,
						{
							kind = "TableProp",
							name = { value = chars },
							location = begin.location,
							type = type_,
							access = access,
							accessLocation = accessLoc,
						} :: Syntax.AstTableProp
					)

					if storeCstData then
						const separator = tableSeparator()
						const cstString = {
							kind = "CstExprConstantString",
							sourceString = sourceString,
							quoteStyle = style,
							blockDepth = depth,
						}

						table.insert(
							cstItems,
							{
								kind = "StringProperty",
								indexerOpenPosition = begin.location.begin,
								indexerClosePosition = indexerClosePos,
								colonPosition = colonPos,
								separator = separator,
								separatorPosition = cstSeparatorPosition(separator),
								stringInfo = cstString,
								stringPosition = stringPos,
							} :: Syntax.CstTypeTableItem
						)
					end
				else
					report(begin.location, "String literal contains malformed escape sequence or \\0")
				end
			else
				if indexer then
					const badIndexerRes = parseTableIndexerImpl(access, accessLoc, begin)
					report(badIndexerRes.node.location, "Cannot have more than one table indexer")
				else
					const idxRes = parseTableIndexerImpl(access, accessLoc, begin)
					indexer = idxRes.node

					if storeCstData then
						const separator = tableSeparator()
						table.insert(
							cstItems,
							{
								kind = "Indexer",

								indexerOpenPosition = idxRes.indexerOpenPosition,
								indexerClosePosition = idxRes.indexerClosePosition,
								colonPosition = idxRes.colonPosition,
								separator = separator,
								separatorPosition = cstSeparatorPosition(separator),
							} :: Syntax.CstTypeTableItem
						)
					end
				end
			end
		elseif #props == 0 and not indexer and not (token_type == 281 and next_type == 58) then
			const type_ = parseTypeImpl()
			isArray = true

			-- array-like table type: {T} desugars into {[number]: T}
			const index = {
				kind = "TypeReference",
				location = type_.location,
				name = "number",
				nameLocation = type_.location,
				hasParameterList = false,
				parameters = {},
			} :: Syntax.AstTypeReference

			indexer = {
				kind = "TableIndexer",
				location = type_.location,
				indexType = index,
				resultType = type_,
				access = access,
				accessLocation = accessLoc,
			} :: Syntax.AstTableIndexer
			break
		else
			const nameOpt = parseNameOptImpl("table field")
			if not nameOpt then
				break
			end

			local colonPos = { line = 0, column = 0 }
			if expectAndConsume(58, "table field") then
				colonPos = { line = prev_start_line, column = prev_start_col }
			end

			const type_ = parseTypeImpl(inDeclarationContext)

			table.insert(
				props,
				{
					kind = "TableProp",
					name = nameOpt.name,
					location = nameOpt.location,
					type = type_,
					access = access,
					accessLocation = accessLoc,
				} :: Syntax.AstTableProp
			)

			if storeCstData then
				const separator = tableSeparator()
				table.insert(
					cstItems,
					{
						kind = "Property",
						colonPosition = colonPos,
						separator = separator,
						separatorPosition = cstSeparatorPosition(separator),
					} :: Syntax.CstTypeTableItem
				)
			end
		end

		if token_type == 44 or token_type == 59 then
			nextLexeme()
		elseif token_type ~= 125 then
			break
		end
	end

	local endLoc = snapshot()
	if
		not expectMatchAndConsume(
			125,
			matchBrace.type,
			matchBrace.location.begin.line,
			matchBrace.location.begin.column,
			true
		)
	then
		endLoc = getprev()
	end

	const node = {
		kind = "TypeTable",
		location = { begin = start.begin, end_ = endLoc.end_ },
		props = props,
		indexer = indexer,
	} :: Syntax.AstTypeTable

	if storeCstData then
		node.cstNode = {
			kind = "CstTypeTable",
			items = cstItems,
			isArray = isArray,
		}
	end

	return node
end

const function parseFunctionTypeTailImpl(
	begin: Syntax.Lexeme,
	attributes: Syntax.Attrs,
	generics: { Syntax.AstGenericType },
	genericPacks: { Syntax.AstGenericTypePack },
	params: { Syntax.AstType },
	paramNames: { Syntax.AstArgumentName | boolean },
	varargAnnotation: Syntax.AstTypePack?
): Syntax.AstType
	incrementRecursionCounter("type annotation")

	if token_type == 58 then
		report(snapshot(), "Return types in function type annotations are written after '->' instead of ':'")

		nextLexeme()

		-- Users occasionally write '()' as the 'unit' type when they actually want to use 'nil', here we'll try to give a more specific error
	elseif token_type ~= 263 and #generics == 0 and #genericPacks == 0 and #params == 0 then
		report({
			begin = begin.location.begin,
			end_ = { line = prev_end_line, column = prev_end_col },
		}, "Expected '->' after '()' when parsing function type; did you mean 'nil'?")

		return {
			kind = "TypeReference",
			location = begin.location,
			name = "nil",
			nameLocation = begin.location,
			hasParameterList = false,
			parameters = {},
		} :: Syntax.AstTypeReference
	else
		expectAndConsume(263, "function type")
	end

	const returnType = ParserFunctions.parseReturnType()

	return {
		kind = "TypeFunction",
		location = {
			begin = begin.location.begin,
			end_ = returnType.location.end_,
		},
		attributes = attributes,
		generics = generics,
		genericPacks = genericPacks,
		argTypes = {
			types = params,
			tailType = varargAnnotation,
		},
		argNames = paramNames,
		returnTypes = returnType,
	}
end

-- ReturnType ::= Type | `(' TypeList `)'
-- FunctionType ::= [`<' varlist `>'] `(' [TypeList] `)' `->` ReturnType
const function parseFunctionTypeImpl(
allowPack: boolean, attributes: Syntax.Attrs
): (Syntax.AstType?, Syntax.AstTypePack?)
	incrementRecursionCounter("type annotation")

	local forceFunctionType = (token_type == 60)
	const begin = get_lexeme()

	const openGenPos: { Syntax.Position } = { { line = 0, column = 0 } }
	const genCommaPos: { Syntax.Position } = {}
	const closeGenPos: { Syntax.Position } = { { line = 0, column = 0 } }

	local generics: { Syntax.AstGenericType }, genericPacks: { Syntax.AstGenericTypePack }
	if storeCstData then
		generics, genericPacks = parseGenericTypeListImpl(false, openGenPos, genCommaPos, closeGenPos)
	else
		generics, genericPacks = parseGenericTypeListImpl(false)
	end

	const paramStart = get_lexeme()
	const openArgsFound = expectAndConsume(40, "function parameters")
	const openArgsPosition = if openArgsFound then paramStart.location.begin else { line = 0, column = 0 }

	matchRecovery[263] += 1

	const params: { Syntax.AstType } = {}
	const names: { Syntax.AstArgumentName | boolean } = {}
	const argCommaPos: { Syntax.Position } = {}
	const nameColonPos: { Syntax.Position | boolean } = {}

	local varargAnnotation: Syntax.AstTypePack? = nil

	if token_type ~= 41 then
		if storeCstData then
			varargAnnotation = parseTypeListImpl(params, names, argCommaPos, nameColonPos)
		else
			varargAnnotation = parseTypeListImpl(params, names)
		end
	end

	const closeArgsLoc = snapshot()
	local closeArgsPosition = { line = 0, column = 0 }
	if expectMatchAndConsume(41, paramStart.type, paramStart.location.begin.line, paramStart.location.begin.column, true) then
		closeArgsPosition = closeArgsLoc.begin
	end

	matchRecovery[263] -= 1

	const paramTypes = params
	if #names > 0 then
		forceFunctionType = true
	end

	const returnTypeIntroducer = (token_type == 263 or token_type == 58)

	-- ot a function at all. Just a parenthesized type. Or maybe a type pack with a single element
	if #params == 1 and not varargAnnotation and not forceFunctionType and not returnTypeIntroducer then
		if allowPack then
			const node = {
				kind = "TypePackExplicit",
				location = begin.location,
				types = paramTypes,
			} :: Syntax.AstTypePackExplicit

			if storeCstData then
				node.cstNode = {
					kind = "CstTypePackExplicit",
					openParenthesesPosition = openArgsPosition,
					closeParenthesesPosition = closeArgsPosition,
					commaPositions = argCommaPos,
				}
			end

			return nil, node
		else
			const node = {
				kind = "TypeGroup",
				location = {
					begin = paramStart.location.begin,
					end_ = closeArgsLoc.end_,
				},
				type = params[1],
			} :: Syntax.AstTypeGroup

			if storeCstData then
				node.cstNode = {
					kind = "CstTypeGroup",
					closePosition = closeArgsPosition,
				}
			end

			return node, nil
		end
	end

	if not forceFunctionType and not returnTypeIntroducer and allowPack then
		const node = {
			kind = "TypePackExplicit",
			location = begin.location,
			types = paramTypes,
			tailType = varargAnnotation,
		} :: Syntax.AstTypePackExplicit

		if storeCstData then
			node.cstNode = {
				kind = "CstTypePackExplicit",
				openParenthesesPosition = openArgsPosition,
				closeParenthesesPosition = closeArgsPosition,
				commaPositions = argCommaPos,
			}
		end

		return nil, node
	end

	const returnArrowPosition = { line = token_start_line, column = token_start_col }
	const node = parseFunctionTypeTailImpl(begin, attributes, generics, genericPacks, paramTypes, names, varargAnnotation)

	if storeCstData and node.kind == "TypeFunction" then
		node.cstNode = {
			kind = "CstTypeFunction",
			openGenericsPosition = openGenPos[1],
			genericsCommaPositions = genCommaPos,
			closeGenericsPosition = closeGenPos[1],
			openArgsPosition = openArgsPosition,
			argumentNameColonPositions = nameColonPos,
			argumentsCommaPositions = argCommaPos,
			closeArgsPosition = closeArgsPosition,
			returnArrowPosition = returnArrowPosition,
		}
	end

	return node, nil
end

const function checkUnaryConfusables(): number?
	-- early-out: need to check if this is a possible confusable quickly
	if token_type ~= 33 then
		return nil
	end

	report(snapshot(), "Unexpected '!'; did you mean 'not'?")

	return 0 -- UnaryOp.Not
end

const function checkBinaryConfusables(limit: number): number?
	const curr = get_lexeme()

	-- arly-out: need to check if this is a possible confusable quickly
	if curr.type ~= 38 and curr.type ~= 124 and curr.type ~= 33 then
		return nil
	end

	-- slow path: possible confusable
	const start = curr.location

	if
		curr.type == 38
		and next_type == 38
		and curr.location.end_.line == next_start_line
		and curr.location.end_.column == next_start_col
		and BinaryPriority[BinaryOp.And][1] > limit
	then
		nextLexeme()

		report({
			begin = start.begin,
			end_ = { line = token_end_line, column = token_end_col },
		}, "Unexpected '&&'; did you mean 'and'?")

		return BinaryOp.And
	elseif
		curr.type == 124
		and next_type == 124
		and curr.location.end_.line == next_start_line
		and curr.location.end_.column == next_start_col
		and BinaryPriority[BinaryOp.Or][1] > limit
	then
		nextLexeme()

		report({
			begin = start.begin,
			end_ = { line = token_end_line, column = token_end_col },
		}, "Unexpected '||'; did you mean 'or'?")

		return BinaryOp.Or
	elseif
		curr.type == 33
		and next_type == 61
		and curr.location.end_.line == next_start_line
		and curr.location.end_.column == next_start_col
		and BinaryPriority[BinaryOp.CompareNe][1] > limit
	then
		nextLexeme()

		report({
			begin = start.begin,
			end_ = { line = token_end_line, column = token_end_col },
		}, "Unexpected '!='; did you mean '~='?")

		return BinaryOp.CompareNe
	end

	return nil
end

const function digitValue(ch: number): number?
	if ch >= 48 and ch <= 57 then
		return ch - 48
	elseif ch >= 65 and ch <= 70 then
		return ch - 55
	elseif ch >= 97 and ch <= 102 then
		return ch - 87
	end

	return nil
end

type NumberParseResult = "Ok" | "Imprecise" | "HexOverflow" | "BinOverflow" | "IntOverflow" | "Malformed"

const ParseResultOk: NumberParseResult = "Ok"
const ParseResultImprecise: NumberParseResult = "Imprecise"
const ParseResultHexOverflow: NumberParseResult = "HexOverflow"
const ParseResultBinOverflow: NumberParseResult = "BinOverflow"
const ParseResultIntOverflow: NumberParseResult = "IntOverflow"
const ParseResultMalformed: NumberParseResult = "Malformed"

const function parseInteger64Words(data: string, base: number, allowFullUint64: boolean): (number, number, NumberParseResult)
	local low = 0
	local high = 0

	if #data == 0 then
		return 0, 0, ParseResultMalformed
	end

	for i = 1, #data do
		const ch = string.byte(data, i)
		const digit = digitValue(ch)
		if digit == nil or digit >= base then
			return 0, 0, ParseResultMalformed
		end

		if base == 2 then
			const lowCarry = bit32.rshift(low, 31)
			low = bit32.band(low * 2 + digit, 0xFFFFFFFF)

			if bit32.rshift(high, 31) ~= 0 then
				return 0, 0, ParseResultBinOverflow
			end

			high = bit32.band(high * 2 + lowCarry, 0xFFFFFFFF)
		else
			const lowCarry = bit32.rshift(low, 28)
			low = bit32.band(low * 16 + digit, 0xFFFFFFFF)

			if bit32.rshift(high, 28) ~= 0 then
				return 0, 0, ParseResultHexOverflow
			end

			high = bit32.band(high * 16 + lowCarry, 0xFFFFFFFF)
		end
	end

	if not allowFullUint64 and (high > 2147483647 or (high == 2147483647 and low > 4294967295)) then
		return 0, 0, ParseResultIntOverflow
	end

	return low, high, ParseResultOk
end

const function makeNumberNode(
	location: Syntax.Location,
	value: number,
	parseResult: NumberParseResult,
	sourceData: string?
): Syntax.AstExprConstantNumber
	const node: Syntax.AstExprConstantNumber = {
		kind = "ExprConstantNumber",
		location = location,
		value = value,
		parseResult = parseResult,
	}

	if storeCstData then
		node.cstNode = { kind = "CstExprConstantNumber", value = sourceData }
	end

	return node
end

const function parseNumberImpl(): Syntax.AstExprConstantNumber | Syntax.AstExprConstantInteger | Syntax.AstExprError
	const start = snapshot()
	const data = token_string or ""

	local sourceData: string? = nil
	if storeCstData then
		sourceData = data
	end

	-- Remove internal '_'
	const cleanData = string.gsub(data, "_", "")

	if LuauIntegerType2 and string.sub(cleanData, -1) == "i" then
		const integerData = string.sub(cleanData, 1, -2)
		local low = 0
		local high = 0
		local parseResult: NumberParseResult = ParseResultOk

		if string.find(integerData, "^0[xX]") then
			low, high, parseResult = parseInteger64Words(string.sub(integerData, 3), 16, true)
		elseif string.find(integerData, "^0[bB]") then
			low, high, parseResult = parseInteger64Words(string.sub(integerData, 3), 2, true)
		else
			low, high, parseResult = parseInteger64Words(integerData, 10, false)
		end

		nextLexeme()

		if parseResult == ParseResultMalformed then
			return reportExprError(start, {}, "Malformed integer")
		end

		if parseResult ~= ParseResultOk then
			return reportExprError(start, {}, "Integer overflow")
		end

		const node = {
			kind = "ExprConstantInteger",
			location = start,
			low = low,
			high = high,
			parseResult = parseResult,
		} :: Syntax.AstExprConstantInteger

		if storeCstData then
			node.cstNode = { kind = "CstExprConstantInteger", value = sourceData }
		end

		return node
	end

	local value = 0
	local parseResult: NumberParseResult = ParseResultOk

	-- Hexadecimal check (0x...)
	if string.find(cleanData, "^0[xX]") then
		const content = string.sub(cleanData, 3)
		const significant = string.match(content, "^0*(.+)") or "0"

		-- 16 Hex digits * 4 bits = 64 bits. Anything more is overflow for uint64.
		if #significant > 16 then
			parseResult = ParseResultHexOverflow
			value = 0
		else
			const v = tonumber(cleanData)
			if v then
				value = v
				if significant ~= "0" then
					const firstNibble = HexVal[string.byte(significant, 1)]
					if firstNibble then
						const headBits = if firstNibble >= 8
							then 4
							elseif firstNibble >= 4 then 3
							elseif firstNibble >= 2 then 2
							else 1
						const bitLength = (#significant - 1) * 4 + headBits

						if bitLength > 53 then
							const requiredTrailingZeros = bitLength - 53
							local trailingZeros = 0

							for i = #significant, 1, -1 do
								const nibble = HexVal[string.byte(significant, i)]
								if nibble == nil then
									trailingZeros = -1
									break
								end

								if nibble == 0 then
									trailingZeros += 4
								else
									trailingZeros += nibble == 0 and 32 or 31 - bit32.countlz(
										bit32.band(nibble, -nibble)
									)
									break
								end
							end

							if trailingZeros < requiredTrailingZeros then
								parseResult = ParseResultImprecise
							end
						end
					else
						parseResult = ParseResultImprecise
					end
				end
			else
				parseResult = ParseResultMalformed
				value = 0
			end
		end
	elseif string.find(cleanData, "^0[bB][01]+") then
		const content = string.sub(cleanData, 3)
		const significant = string.match(content, "^0*(.+)") or "0"

		-- 64 bits max for uint64
		if #significant > 64 then
			parseResult = ParseResultBinOverflow
			value = 0
		else
			const v = tonumber(content, 2)
			if v then
				value = v
				const bitLength = #significant

				if bitLength > 53 then
					const requiredTrailingZeros = bitLength - 53
					local precise = true

					for i = bitLength, bitLength - requiredTrailingZeros + 1, -1 do
						if string.byte(significant, i) ~= 48 then -- '0'
							precise = false
							break
						end
					end

					if not precise then
						parseResult = ParseResultImprecise
					end
				end
			else
				parseResult = ParseResultMalformed
				value = 0
			end
		end
	else
		const v = tonumber(cleanData)
		value = v or 0

		if v then
			if value >= 9007199254740992 and string.find(cleanData, "^%d+$") then
				const repr = string.format("%.0f", value)
				if repr ~= cleanData then
					parseResult = ParseResultImprecise
				end
			end
		else
			parseResult = ParseResultMalformed
			value = 0
		end
	end

	nextLexeme()

	if parseResult == ParseResultMalformed then
		return reportExprError(start, {}, "Malformed number")
	end

	return makeNumberNode(start, value, parseResult, sourceData)
end

const function parseInterpStringImpl(): Syntax.AstExprInterpString | Syntax.AstExprError
	const strings: { string } = {}
	const sourceStrings: { string } = {}
	const stringPositions: { Syntax.Position } = {}
	const expressions: { Syntax.AstExpr } = {}

	const startLocation = snapshot()
	local endLocation: Syntax.Location? = nil

	while true do
		const currentLexeme = get_lexeme()
		endLocation = currentLexeme.location

		const data = token_string or ""

		if storeCstData then
			table.insert(sourceStrings, data)
			table.insert(stringPositions, currentLexeme.location.begin)
		end

		const ok, fixedData = fixupQuotedString(data)
		if not ok then
			nextLexeme()
			return reportExprError({
				begin = startLocation.begin,
				end_ = endLocation.end_,
			}, {}, "Interpolated string literal contains malformed escape sequence")
		end

		nextLexeme()
		table.insert(strings, fixedData :: string)

		if currentLexeme.type == 268 or currentLexeme.type == 269 then
			break
		end

		local errorWhileChecking = false
		local t = token_type

		if t == 267 or t == 268 then
			errorWhileChecking = true
			nextLexeme()
			table.insert(
				expressions,
				reportExprError(endLocation, {}, "Malformed interpolated string, expected expression inside '{}'")
			)
		elseif t == 286 then
			errorWhileChecking = true
			nextLexeme()
			table.insert(
				expressions,
				reportExprError(endLocation, {}, "Malformed interpolated string; did you forget to add a '`'?")
			)
		else
			table.insert(expressions, ParserFunctions.parseExpr())
		end

		if errorWhileChecking then
			break
		end

		t = token_type

		if t == 266 or t == 267 or t == 268 then
		elseif token_type == 289 then
			nextLexeme()
			return reportExprError(
				endLocation,
				{},
				"Double braces are not permitted within interpolated strings; did you mean '\\{'?"
			)
		elseif token_type == 286 or token_type == 0 then
			if token_type == 286 then
				nextLexeme()
			end

			const node = {
				kind = "ExprInterpString",
				location = {
					begin = startLocation.begin,
					end_ = {
						line = prev_end_line,
						column = prev_end_col,
					},
				},
				strings = strings,
				expressions = expressions,
			} :: Syntax.AstExprInterpString

			if storeCstData then
				node.cstNode =
					{ kind = "CstExprInterpString", sourceStrings = sourceStrings, stringPositions = stringPositions }
			end

			const stack = braceStack
			const top = (#stack > 0) and stack[#stack] or nil

			if top then
				if top == BraceType.InterpolatedString then
					report(getprev(), "Malformed interpolated string; did you forget to add a '}'?")
				end
			else
				report(getprev(), "Malformed interpolated string; did you forget to add a '`'?")
			end

			return node :: Syntax.AstExprInterpString
		else
			return reportExprError(
				endLocation,
				{},
				"Malformed interpolated string, got %s",
				ToString(token_type, token_string, token_codepoint)
			)
		end
	end

	const node = {
		kind = "ExprInterpString",
		location = {
			begin = startLocation.begin,
			end_ = (endLocation :: Syntax.Location).end_,
		},
		strings = strings,
		expressions = expressions,
	} :: Syntax.AstExprInterpString

	if storeCstData then
		node.cstNode =
			{ kind = "CstExprInterpString", sourceStrings = sourceStrings, stringPositions = stringPositions }
	end

	return node :: Syntax.AstExprInterpString
end

const function parseIfElseExprImpl(): Syntax.AstExprIfElse
	local hasElse = false
	const start = snapshot()

	nextLexeme() -- skip if / elseif

	const condition = ParserFunctions.parseExpr()

	local thenPosition = { line = 0, column = 0 }
	const hasThen = expectAndConsume(308, "if then else expression")
	if hasThen then
		thenPosition = { line = prev_start_line, column = prev_start_col }
	end

	const trueExpr = ParserFunctions.parseExpr()
	local falseExpr: Syntax.AstExpr? = nil

	const elsePosition = { line = token_start_line, column = token_start_col }
	local isElseIf = false

	if token_type == 295 then
		const oldRecursion = recursionCounter
		incrementRecursionCounter("expression")
		hasElse = true
		falseExpr = parseIfElseExprImpl()
		recursionCounter = oldRecursion
		isElseIf = true
	else
		hasElse = expectAndConsume(294, "if then else expression")
		falseExpr = ParserFunctions.parseExpr()
	end

	const resolvedFalseExpr = falseExpr :: Syntax.AstExpr

	const node = {
		kind = "ExprIfElse",
		location = { begin = start.begin, end_ = resolvedFalseExpr.location.end_ },
		condition = condition,
		hasThen = hasThen,
		trueExpr = trueExpr,
		hasElse = hasElse,
		falseExpr = resolvedFalseExpr,
	} :: Syntax.AstExprIfElse

	if storeCstData then
		node.cstNode = {
			kind = "CstExprIfElse",
			thenPosition = thenPosition,
			elsePosition = elsePosition,
			isElseIf = isElseIf,
		}
	end

	return node
end

-- simpleexp -> NUMBER | STRING | NIL | true | boolean | ... | constructor | [attributes] FUNCTION body | primaryexp
const function parseSimpleExprImpl(): Syntax.AstExpr
	const start = snapshot()

	local attributes: Syntax.Attrs = {}
	local cstAttrLists: { Syntax.CstAttrList }? = nil

	if token_type == 284 or token_type == 285 then
		attributes, _, cstAttrLists = parseAttributes()

		if token_type ~= 299 then
			return reportExprError(

				start,
				{},
				"Expected 'function' declaration after attribute, but got %s instead",
				ToString(token_type, token_string, token_codepoint)
			)
		end
	end

	if token_type == 303 then
		nextLexeme()
		return {
			kind = "ExprConstantNil",
			location = start,
		}
	elseif token_type == 309 then
		nextLexeme()
		return {
			kind = "ExprConstantBool",
			location = start,
			value = true,
		}
	elseif token_type == 297 then
		nextLexeme()
		return {
			kind = "ExprConstantBool",
			location = start,
			value = false,
		}
	elseif token_type == 299 then
		const matchFunction = get_lexeme()
		nextLexeme()
		const node = parseFunctionBodyImpl(false, matchFunction, nil, nil, nil, attributes, cstAttrLists, false)
		return node
	elseif token_type == 280 then
		return parseNumberImpl()
	elseif token_type == 278 or token_type == 279 or token_type == 269 then
		return parseStringImpl()
	elseif token_type == 266 then
		return parseInterpStringImpl()
	elseif token_type == 286 then
		nextLexeme()
		return reportExprError(start, {}, "Malformed string; did you forget to finish it?")
	elseif token_type == 289 then
		nextLexeme()
		return reportExprError(start, {}, "Double braces are not permitted within interpolated strings; did you mean '\\{'?")
	elseif token_type == 262 then
		if functionStack[#functionStack].vararg then
			nextLexeme()
			return {
				kind = "ExprVarargs",
				location = start,
			}
		else
			nextLexeme()
			return reportExprError(start, {}, "Cannot use '...' outside of a vararg function")
		end
	elseif token_type == 123 then
		return parseTableConstructorImpl()
	elseif token_type == 300 then
		return parseIfElseExprImpl()
	else
		return parsePrimaryExprImpl(false)
	end
end

-- asexp -> simpleexp [`::' Type]
const function parseAssertionExprImpl(): Syntax.AstExpr
	const start = snapshot()
	const expr = parseSimpleExprImpl()

	if token_type == 264 then
		const opPos = { line = token_start_line, column = token_start_col }
		nextLexeme()
		const annotation = parseTypeImpl()
		const node = {
			kind = "ExprTypeAssertion",
			location = {
				begin = start.begin,
				end_ = annotation.location.end_,
			},
			expr = expr,
			annotation = annotation,
		} :: Syntax.AstExprTypeAssertion

		if storeCstData then
			node.cstNode = {
				kind = "CstExprTypeAssertion",
				opPosition = opPos,
			}
		end

		return node
	else
		return expr
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
const function parseStat(): Syntax.AstStat
	const type_ = token_type

	if type_ == 300 then
		return parseIfImpl()
	elseif type_ == 311 then
		return parseWhileImpl()
	elseif type_ == 293 then
		return parseDoImpl()
	elseif type_ == 298 then
		return parseForImpl()
	elseif type_ == 306 then
		return parseRepeatImpl()
	elseif type_ == 299 then
		return parseFunctionStatImpl({}, nil, nil)
	elseif type_ == 302 then
		const start = snapshot()
		return parseLocalImpl(start, start.begin, {}, nil, false)
	elseif type_ == 307 then
		return parseReturnImpl()
	elseif type_ == 292 then
		return parseBreakImpl()
	elseif type_ == 284 or type_ == 285 then
		return parseAttributeStatImpl()
	end

	const start_line, start_column = token_start_line, token_start_col
	const start_end_line, start_end_column = token_end_line, token_end_col
	const expr = parsePrimaryExprImpl(true)

	if expr.kind == "ExprCall" then
		return {
			kind = "StatExpr",
			location = expr.location,
			expr = expr,
		}
	end

	if token_type == 44 or token_type == 61 then
		return parseAssignmentImpl(expr)
	end

	const operator = CompoundLookup[token_type]
	if operator then
		return parseCompoundAssignmentImpl(expr, operator)
	end

	local ident = nil :: string?
	if expr.kind == "ExprGlobal" then
		ident = expr.name
	elseif expr.kind == "ExprLocal" then
		ident = expr["local"] and expr["local"].name
	end

	if ident == "type" then
		return parseTypeAliasImpl(expr.location, false, expr.location.begin)
	end

	if DebugLuauUserDefinedClasses and ident == "class" then
		return parseClassStatImpl(expr.location, false)
	end

	if ident == "export" then
		if
			LuauExportValueSyntax
			and (
				token_type == 302
				or token_type == 299
				or (
					token_type == 281
					and (token_string == "const" or (DebugLuauUserDefinedClasses and token_string == "class"))
				)
			)
		then
			return parseExportValueImpl(expr.location, expr.location.begin, {}, nil)
		elseif token_type == 281 and token_string == "type" then
			const typeKeywordPos = { line = token_start_line, column = token_start_col }
			nextLexeme()
			return parseTypeAliasImpl(expr.location, true, typeKeywordPos)
		elseif not LuauExportValueSyntax and DebugLuauUserDefinedClasses and token_type == 281 and token_string == "class" then
			nextLexeme()
			return parseClassStatImpl(expr.location, true)
		end
	end

	if ident == "continue" then
		return parseContinueImpl(expr.location)
	end

	if ident == "const" then
		return parseLocalImpl(expr.location, expr.location.begin, {}, nil, true)
	end

	if options.allowDeclarationSyntax and ident == "declare" then
		return parseDeclarationImpl(expr.location, {})
	end

	if
		start_line == token_start_line
		and start_column == token_start_col
		and start_end_line == token_end_line
		and start_end_column == token_end_col
	then
		nextLexeme()
	end

	return reportStatError(expr.location, { expr }, {}, "Incomplete statement: expected assignment or a function call")
end

-- ReturnType ::= Type | `(' TypeList `)'
const function parseReturnTypeImpl(): Syntax.AstTypePack
	incrementRecursionCounter("type annotation")

	const begin = get_lexeme()

	const begin_type, begin_line, begin_col = token_type, token_start_line, token_start_col

	if token_type ~= 40 then
		if shouldParseTypePack() then
			return parseTypePackImpl()
		else
			const type_ = parseTypeImpl(false)

			const node = {
				kind = "TypePackExplicit",
				location = type_.location,
				types = { type_ },
			} :: Syntax.AstTypePackExplicit

			if storeCstData then
				node.cstNode = {
					kind = "CstTypePackExplicit",
				}
			end
			return node
		end
	end

	nextLexeme()

	matchRecovery[263] += 1

	const result: { Syntax.AstType } = {}
	const resultNames: { Syntax.AstArgumentName | boolean } = {}
	const commaPositions: { Syntax.Position } = {}
	const nameColonPositions: { Syntax.Position | boolean } = {}

	local varargAnnotation: Syntax.AstTypePack? = nil

	-- possibly () -> ReturnType
	if token_type ~= 41 then
		if storeCstData then
			varargAnnotation = parseTypeListImpl(result, resultNames, commaPositions, nameColonPositions)
		else
			varargAnnotation = parseTypeListImpl(result, resultNames)
		end
	end

	const endLoc = snapshot()
	local closeParenPos = { line = 0, column = 0 }

	if expectMatchAndConsume(41, begin_type, begin_line, begin_col, true) then
		closeParenPos = { line = prev_start_line, column = prev_start_col }
	end

	matchRecovery[263] -= 1

	if token_type ~= 263 and #resultNames == 0 then
		-- If it turns out that it's just '(A)', it's possible that there are unions/intersections to follow, so fold over it.
		if #result == 1 then
			-- TODO(CLI-140667): stop parsing type suffix when varargAnnotation != nullptr - this should be a parse error
			local inner: Syntax.AstType
			if varargAnnotation == nil then
				const typeGroup = {
					kind = "TypeGroup",
					location = { begin = begin.location.begin, end_ = endLoc.end_ },
					type = result[1],
				} :: Syntax.AstTypeGroup

				if storeCstData then
					typeGroup.cstNode = {
						kind = "CstTypeGroup",
						closePosition = closeParenPos,
					}
				end

				inner = typeGroup
			else
				inner = result[1]
			end

			const returnType = parseTypeSuffixImpl(inner, begin.location)

			-- If parseType parses nothing, then returnType->location.end only points at the last non-type-pack
			-- type to successfully parse.  We need the span of the whole annotation.
			const endPos = (#result == 1) and endLoc.end_ or returnType.location.end_

			const node = {
				kind = "TypePackExplicit",
				location = {
					begin = begin.location.begin,
					end_ = endPos,
				},
				types = { returnType },
				tailType = varargAnnotation,
			} :: Syntax.AstTypePackExplicit

			if storeCstData then
				node.cstNode = {
					kind = "CstTypePackExplicit",
				}
			end
			return node
		end

		const node = {
			kind = "TypePackExplicit",
			location = {
				begin = begin.location.begin,
				end_ = endLoc.end_,
			},
			types = result,
			tailType = varargAnnotation,
		} :: Syntax.AstTypePackExplicit

		if storeCstData then
			node.cstNode = {
				kind = "CstTypePackExplicit",
				openParenthesesPosition = begin.location.begin,
				closeParenthesesPosition = closeParenPos,
				commaPositions = commaPositions,
			}
		end
		return node
	end

	const returnArrowPosition = { line = token_start_line, column = token_start_col }
	const tail = parseFunctionTypeTailImpl(begin, {}, {}, {}, result, resultNames, varargAnnotation)

	if storeCstData and tail.kind == "TypeFunction" then
		tail.cstNode = {
			kind = "CstTypeFunction",
			openGenericsPosition = { line = 0, column = 0 },
			genericsCommaPositions = {},
			closeGenericsPosition = { line = 0, column = 0 },
			openArgsPosition = begin.location.begin,
			argumentNameColonPositions = nameColonPositions,
			argumentsCommaPositions = commaPositions,
			closeArgsPosition = closeParenPos,
			returnArrowPosition = returnArrowPosition,
		}
	end

	const node = {
		kind = "TypePackExplicit",
		location = {
			begin = begin.location.begin,
			end_ = tail.location.end_,
		},
		types = { tail },
	} :: Syntax.AstTypePackExplicit

	if storeCstData then
		node.cstNode = {
			kind = "CstTypePackExplicit",
		}
	end

	return node
end

-- Type ::= nil | Name[`.' Name] [ `<' Type [`,' ...] `>' ] | `typeof' `(' expr `)' | `{' [PropList] `}'
--   | [`<' varlist `>'] `(' [TypeList] `)' `->` ReturnType
const function parseSimpleTypeImpl(allowPack: boolean, inDeclarationContext: boolean): (Syntax.AstType?, Syntax.AstTypePack?)
	incrementRecursionCounter("type annotation")

	const start = snapshot()

	if token_type == 284 or token_type == 285 then
		if not inDeclarationContext then
			return reportTypeError(start, {}, "attributes are not allowed in declaration context"), nil
		else
			const attributes = parseAttributes()

			return parseFunctionTypeImpl(allowPack, attributes), nil
		end
	elseif token_type == 303 then
		nextLexeme()

		return {
			kind = "TypeReference",
			location = start,
			name = "nil",
			nameLocation = start,
			hasParameterList = false,
			parameters = {},
		} :: Syntax.AstTypeReference,
			nil
	elseif token_type == 309 then
		nextLexeme()

		return {
			kind = "TypeSingletonBool",
			location = start,
			value = true,
		} :: Syntax.AstTypeSingletonBool,
			nil
	elseif token_type == 297 then
		nextLexeme()

		return {
			kind = "TypeSingletonBool",
			location = start,
			value = false,
		} :: Syntax.AstTypeSingletonBool,
			nil
	elseif token_type == 278 or token_type == 279 then
		local style = 0
		local depth = 0
		local sourceString = nil :: string?
		if storeCstData then
			style, depth = extractStringDetails()
			sourceString = token_string
		end

		const chars = parseCharArrayImpl()
		if chars then
			const node = {
				kind = "TypeSingletonString",
				location = start,
				value = chars,
			} :: Syntax.AstTypeSingletonString

			if storeCstData then
				node.cstNode = {
					kind = "CstTypeSingletonString",
					sourceString = sourceString,
					quoteStyle = style,
					blockDepth = depth,
				}
			end

			return node, nil
		else
			return reportTypeError(start, {}, "String literal contains malformed escape sequence"), nil
		end
	elseif token_type == 266 or token_type == 269 then
		parseInterpStringImpl()

		return reportTypeError(start, {}, "Interpolated string literals cannot be used as types"), nil
	elseif token_type == 286 then
		nextLexeme()
		return reportTypeError(start, {}, "Malformed string; did you forget to finish it?"), nil
	elseif token_type == 281 then
		local name = parseNameImpl("type name")
		local prefix: string? = nil
		local prefixLoc: Syntax.Location? = nil
		local prefixPointPos: Syntax.Position? = nil

		if token_type == 46 then
			prefixPointPos = { line = token_start_line, column = token_start_col }
			nextLexeme()
			prefix = name.name.value
			prefixLoc = name.location
			name = parseIndexNameImpl("field name", name.location.end_)
		elseif token_type == 262 then
			report(snapshot(), "Unexpected '...' after type name; type pack is not allowed in this context")

			nextLexeme()
		elseif name.name.value == "typeof" then
			const typeofBegin = get_lexeme()
			const openParenFound = expectAndConsume(40, "typeof type")
			const expr = ParserFunctions.parseExpr()
			const endLoc = snapshot()
			local closePosition = { line = 0, column = 0 }
			if expectMatchAndConsume(
				41,
				typeofBegin.type,
				typeofBegin.location.begin.line,
				typeofBegin.location.begin.column,
				false
			) then
				closePosition = endLoc.begin
			end

			const node = {
				kind = "TypeTypeof",
				location = {
					begin = start.begin,
					end_ = endLoc.end_,
				},
				expr = expr,
			} :: Syntax.AstTypeTypeof

			if storeCstData then
				node.cstNode = {
					kind = "CstTypeTypeof",
					openPosition = if openParenFound then typeofBegin.location.begin else { line = 0, column = 0 },
					closePosition = closePosition,
				}
			end
			return node, nil
		end

		local hasParams = false
		local params: { Syntax.AstTypeOrPack } = {}

		const openPosRef = if storeCstData then { { line = 0, column = 0 } } else nil
		const commaPosRef = if storeCstData then {} else nil
		const closePosRef = if storeCstData then { { line = 0, column = 0 } } else nil

		if token_type == 60 then
			hasParams = true
			params = parseTypeParamsImpl(openPosRef, commaPosRef, closePosRef)
		end

		const node = {
			kind = "TypeReference",
			location = {
				begin = start.begin,
				end_ = { line = prev_end_line, column = prev_end_col },
			},
			prefix = prefix,
			name = name.name.value,
			prefixLocation = prefixLoc,
			nameLocation = name.location,
			hasParameterList = hasParams,
			parameters = params,
		} :: Syntax.AstTypeReference

		if storeCstData then
			node.cstNode = {
				kind = "CstTypeReference",
				prefixPointPosition = prefixPointPos,
				openParametersPosition = openPosRef and openPosRef[1] or nil,
				parametersCommaPositions = commaPosRef or {},
				closeParametersPosition = closePosRef and closePosRef[1] or nil,
			}
		end

		return node, nil
	elseif token_type == 123 then
		return parseTableTypeImpl(inDeclarationContext), nil
	elseif token_type == 40 or token_type == 60 then
		return parseFunctionTypeImpl(allowPack, {})
	elseif token_type == 299 then
		nextLexeme()

		return reportTypeError(start, {}, "Using 'function' as a type annotation is not supported..."), nil
	else
		const astErrorLocation = {
			begin = { line = prev_end_line, column = prev_end_col },
			end_ = start.begin,
		}
		const parseErrorLocation = {
			begin = { line = prev_end_line, column = prev_end_col },
			end_ = start.end_,
		}

		return reportMissingTypeError(
			parseErrorLocation,
			astErrorLocation,
			"Expected type, got %s",
			ToString(token_type, token_string, token_codepoint)
		),
			nil
	end
end

-- subexpr -> (asexp | unop subexpr) { binop subexpr }
-- where `binop' is any binary operator with a priority higher than `limit'
const function parseExprImpl(limit_val: number?): Syntax.AstExpr
	const limit: number = limit_val or 0
	const oldRecursion = recursionCounter

	-- this handles recursive calls to parseSubExpr/parseExpr
	incrementRecursionCounter("expression")

	const start = snapshot()
	local expr: Syntax.AstExpr? = nil

	local uop: number? = UnaryOpLookup[token_type] -- Fix: Lookup based on token type
	if not uop then
		uop = checkUnaryConfusables()
	end

	if uop then
		const opPosition = { line = token_start_line, column = token_start_col }
		nextLexeme()

		const subexpr = ParserFunctions.parseExpr(8)

		expr = {
			kind = "ExprUnary",
			location = {
				begin = start.begin,
				end_ = subexpr.location.end_,
			},
			op = uop :: number,
			expr = subexpr,
		} :: Syntax.AstExprUnary

		if storeCstData then
			expr.cstNode = {
				kind = "CstExprOp",
				opPosition = opPosition,
			}
		end
	else
		expr = parseAssertionExprImpl()
	end

	-- expand while operators have priorities higher than `limit'
	local op: number? = BinaryOpLookup[token_type] or checkBinaryConfusables(limit)

	-- expand while operators have priorities higher than `limit'
	while op and BinaryPriority[op][1] > limit do
		const opPosition = { line = token_start_line, column = token_start_col }
		nextLexeme()

		-- read sub-expression with higher priority
		const nextExpr = ParserFunctions.parseExpr(BinaryPriority[op][2])

		expr = {
			kind = "ExprBinary",
			location = {
				begin = start.begin,
				end_ = nextExpr.location.end_,
			},
			op = op :: number,
			left = expr :: Syntax.AstExpr,
			right = nextExpr,
		} :: Syntax.AstExprBinary

		if storeCstData then
			expr.cstNode = {
				kind = "CstExprOp",
				opPosition = opPosition,
			}
		end

		op = BinaryOpLookup[token_type] or checkBinaryConfusables(limit) -- Fix: Lookup based on token type

		-- note: while the parser isn't recursive here, we're generating recursive structures of unbounded depth
		incrementRecursionCounter("expression")
	end

	recursionCounter = oldRecursion
	return expr
end

ParserFunctions.parseStat = parseStat
ParserFunctions.parseReturnType = parseReturnTypeImpl
ParserFunctions.parseSimpleType = parseSimpleTypeImpl
ParserFunctions.parseExpr = parseExprImpl

const function parseChunk(sourceText: string, parseOptions: Syntax.Options): Syntax.AstStatBlock
	options = parseOptions
	captureComments = parseOptions.captureComments == true
	storeCstData = parseOptions.storeCstData == true

	source = sourceText
	buff_data = buffer.fromstring(sourceText)
	size = #sourceText

	offset = 0

	if parseOptions.parseFragment and parseOptions.parseFragment.resumePosition then
		line = parseOptions.parseFragment.resumePosition.line
		lineOffset = 0 - parseOptions.parseFragment.resumePosition.column
	else
		line = 0
		lineOffset = 0
	end

	const startColumn = 0 - lineOffset

	braceStack = {}

	token_type = 0

	token_start_line = line
	token_start_col = startColumn
	token_end_line = line
	token_end_col = startColumn

	prev_start_line = line
	prev_start_col = startColumn
	prev_end_line = line
	prev_end_col = startColumn

	token_string = nil
	token_aux = nil
	token_codepoint = nil

	recursionCounter = 0

	commentLocations = {}
	hotcomments = {}
	parseErrors = {}
	declaredExportBindings = {}
	hasModuleReturn = false
	classesWithinModule = {}

	hotcommentHeader = true

	suspect_type = 0
	suspect_line = 0

	matchRecovery = table.create(312, 0)
	matchRecovery[0] = 1

	functionStack = {
		{ vararg = true, loopDepth = 0 },
	}

	if parseOptions.parseFragment then
		localStack = table.clone(parseOptions.parseFragment.localStack)
		localMap = table.clone(parseOptions.parseFragment.localMap)
	else
		localStack = {}
		localMap = {}
	end

	fillNext()
	nextLexeme()
	hotcommentHeader = false

	const localsBegin = #localStack
	const result = parseBlockNoScope()
	restoreLocals(localsBegin)

	if token_type ~= 0 then
		expectAndConsumeFail(0)
	end

	return result
end

return {
	parse = function(source: string, options: Syntax.Options?): (boolean, Syntax.Result)
		const parseOptions = options or {} :: Syntax.Options
		const success, result = pcall(parseChunk, source, parseOptions)
		const root = if success then result else nil
		const lines = if success then token_end_line + if size > 0 and buffer.readu8(buff_data, size - 1) ~= 10 then 1 else 0 else 0

		return success and #parseErrors == 0,
			{
				root = if success then root else nil,
				lines = lines,
				commentLocations = commentLocations,
				hotcomments = hotcomments,
				errors = parseErrors,
			}
	end,

	BraceType = BraceType,
	QuoteStyle = QuoteStyle,
	
	UnaryOp = {
		Not = 0,
		Minus = 1,
		Len = 2,
	},
	
	BinaryOp = BinaryOp,
	CstQuotes = CstQuotes,
}
