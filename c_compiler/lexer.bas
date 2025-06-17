rem TIPE – C compiler
rem A minimal C compiler written in BASIC
rem Aims to compile tinycc

rem Copyright (C) 2025  jd & abito

rem This program is free software: you can redistribute it and/or modify
rem it under the terms of the GNU General Public License as published by
rem the Free Software Foundation, either version 3 of the License, or
rem (at your option) any later version.

rem This program is distributed in the hope that it will be useful,
rem but WITHOUT ANY WARRANTY; without even the implied warranty of
rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
rem GNU General Public License for more details.

rem You should have received a copy of the GNU General Public License
rem along with this program.  If not, see <https://www.gnu.org/licenses/>.

dim C_99_KEYWORDS(0 to 37) as string => { _
    "break", _
    "case", _
    "char", _
    "const", _
    "continue", _
    "default", _
    "do", _
    "double", _
    "else", _
    "enum", _
    "extern", _
    "float", _
    "for", _
    "goto", _
    "if", _
    "inline", _
    "int", _
    "long", _
    "register", _
    "restrict", _
    "return", _
    "short", _
    "signed", _
    "sizeof", _
    "static", _
    "struct", _
    "switch", _
    "typedef", _
    "union", _
    "unsigned", _
    "void", _
    "volatile", _
    "while", _
    "_Bool" _
}
rem Not used in tinycc (not included in the above list):
rem auto
rem _Complex
rem _Imaginary

rem === TOKEN TYPES ===
const TOK_UNDEFINED = 0       rem [undefined]
const TOK_INTEGER = 1         rem integer
const TOK_HEX = 1             rem hex
const TOK_FLOAT = 5           rem float
rem note: the 'f', 'F', 'l' and 'L' suffixes ARE USED by TCC
rem note: there is no hexadecimal-floating-constant in TCC
const TOK_IDENTIFIER = 6      rem identifier
rem   TOK_KEYWORD    = 60     rem defined at the end of the list
const TOK_LSQUARE = 7         rem [
const TOK_RSQUARE = 8         rem ]
const TOK_LPAREN  = 9         rem (
const TOK_RPAREN  = 10        rem )
const TOK_LBRACKET = 11       rem {
const TOK_RBRACKET = 12       rem }
const TOK_DOT = 13            rem .
const TOK_ARROW = 14          rem ->
const TOK_PLUSPLUS = 15       rem ++
const TOK_MINUSMINUS = 16     rem --
const TOK_AMP = 17            rem &
const TOK_MULT = 18           rem *
const TOK_PLUS = 19           rem +
const TOK_MINUS = 20          rem -
const TOK_BITWISENOT = 21     rem ~
const TOK_BANG = 22           rem !
const TOK_SLASH = 23          rem /
const TOK_PERCENT = 24        rem %
const TOK_LSHIFT = 25         rem <<
const TOK_RSHIFT = 26         rem >>
const TOK_LT = 27             rem <
const TOK_GT = 28             rem >
const TOK_LTE = 29            rem <=
const TOK_GTE = 30            rem >=
const TOK_EEQ = 31            rem ==
const TOK_NEQ = 32            rem !=
const TOK_BITWISEXOR = 33     rem ^
const TOK_BITWISEOR = 34      rem |
const TOK_AND = 35            rem &&
const TOK_OR = 36             rem ||
const TOK_INTERROGATION = 37  rem ?
const TOK_COLON = 38          rem :
const TOK_SEMICOLON = 39      rem ;
const TOK_ELLIPSIS = 40       rem ...
const TOK_EQ_ASSIGN = 41      rem =
const TOK_MULTEQ = 42         rem *=
const TOK_DIVEQ = 43          rem /=
const TOK_PERCENTEQ = 44      rem %=
const TOK_PLUSEQ = 45         rem +=
const TOK_MINUSEQ = 46        rem -=
const TOK_LSHIFTEQ = 47       rem <<=
const TOK_RSHIFTEQ = 48       rem >>=
const TOK_AMPEQ = 49          rem &=
const TOK_BITWISEXOREQ = 50   rem ^=
const TOK_BITWISEOREQ = 51    rem |=
const TOK_COMMA = 52          rem ,
const TOK_STRING = 53         rem string -- note: \x and L"" are unused in
                              rem tinycc
const TOK_CHAR = 54           rem char ('X') -- note: u'', U'' and L'' are
                              rem unused in tinycc
const TOK_KEYWORD = 60        rem keyword
rem The following tokens are not used in tinycc, so they will not be
rem implemented
rem  1 : oct (will not be implemented)
rem  1 : bin (will not be implemented)
rem  7 : <:  (will not be implemented)
rem  8 : :>  (will not be implemented)
rem 11 : <%  (will not be implemented)
rem 12 : %>  (will not be implemented)
rem ===================

const NO_VALUE = 128

const C_BYTE = 0
const C_SHORT = 1
const C_INT = 2
const C_LONG = 3
const C_LONGLONG = 4

type c_integer_type
    value as longint
    value_type as uinteger
    is_unsigned as boolean
end type

const C_SINGLE = 0
const C_DOUBLE = 1

type c_float_type
    value_type as uinteger
    union
        c_float as single
        c_double as double
    end union
end type

type token
    value_str as string
    value_int as c_integer_type
    value_float as c_float_type
    tok_type as uinteger
    pos_start as integer
    pos_end as integer
end type

type char_and_index
    current_char as ubyte
    index as long
    beginning_of_line as boolean
    do_not_advance as boolean
end type

type ci_and_token
    ci as char_and_index
    tok as token
end type


rem Closes the source file, prints the error message stored in errmsg and ends
rem the program
sub exception(errmsg as string, tokens(any) as token, f as integer)
    close #f
    print "Error: "; errmsg
    erase tokens
    end
end sub


rem Adds the token stored in tok to the tokens array, eventually resizing it.
rem The token array is modified and not returned, tok_index is modified by
rem reference
sub newtok(tok as token, tokens(any) as token, byref tok_index as integer)
    if tok_index = ubound(tokens) then
        redim preserve tokens(0 to ubound(tokens)*2)
    endif
    tokens(tok_index) = tok
    tok_index += 1
end sub


rem Updates (not by reference) ci.current_char to the next char of the file and
rem increments index, then return a copy of ci
rem Does not check if EOF is reached - please check that ci.current_char is <> 0
rem before calling
function nextchar (old_ci as char_and_index, f as integer) as char_and_index
    dim ci as char_and_index
    if old_ci.current_char = 10 then
        ci.beginning_of_line = true
    else
        ci.beginning_of_line = false
    endif
    get #f, , ci.current_char
    ci.index = old_ci.index + 1
    ci.do_not_advance = old_ci.do_not_advance
    return ci
end function


rem Returns an empty token
rem (0s everywhere (except pos_start and pos_end, which are initialised with
rem `index`))
function create_new_token(index as long) as token
    dim tok as token
    tok.value_str = ""
    tok.value_float.value_type = NO_VALUE
    tok.value_int.value_type = NO_VALUE
    tok.pos_start = index
    tok.pos_end = index
    tok.tok_type = 0
    return tok
end function


rem Parses an identifier
function make_id( _
    ci as char_and_index, _
    tokens(any) as token, _
    byref tok_index as integer, _
    f as integer, _
    C_99_KEYWORDS(any) as string _
) as char_and_index
    dim current_id as string
    dim start_index as long
    dim tok as token
    current_id = ""
    start_index = ci.index

    while (ci.current_char >= &h41 andalso ci.current_char <= &h5A) _
       or (ci.current_char >= &h61 andalso ci.current_char <= &h7A) _
       or (ci.current_char >= &h30 andalso ci.current_char <= &h39) _
       or (ci.current_char = &h5F)
        current_id += chr(ci.current_char)
        ci = nextchar(ci, f)
    wend

    tok = create_new_token(start_index)
    tok.value_str = current_id
    tok.pos_start = start_index
    tok.pos_end = ci.index

    tok.tok_type = TOK_IDENTIFIER
    for i1 as integer = lbound(C_99_KEYWORDS) to ubound(C_99_KEYWORDS)
        if current_id = C_99_KEYWORDS(i1) then
            tok.tok_type = TOK_KEYWORD
            exit for
        endif
    next

    newtok(tok, tokens(), tok_index)

    ci.do_not_advance = true
    return ci
end function


rem Parses a number
function make_num(old_ci as char_and_index, tokens(any) as token, f as integer) as ci_and_token
    dim ci as char_and_index
    ci.index = old_ci.index
    ci.current_char = old_ci.current_char

    dim current_num as longint
    dim current_float as double
    dim is_float as boolean
    dim current_power_of_ten as integer
    dim start_index as long
    dim zero_found as boolean

    current_num = 0
    current_float = 0.0
    is_float = false
    current_power_of_ten = 10
    start_index = ci.index

    if ci.current_char = &h30 then
        ci = nextchar(ci, f)
    endif

    if chr(ci.current_char) = "x" then  rem hexadecimal
        ci = nextchar(ci, f)
        while (&h30 <= ci.current_char andalso ci.current_char <= &h39) or _
              (&h41 <= ci.current_char andalso ci.current_char <= &h46) or _
              (&h61 <= ci.current_char andalso ci.current_char <= &h66)
            current_num *= 16
            if ci.current_char <= &h39 then
                current_num += ci.current_char - &h30
            elseif ci.current_char <= &h46 then
                current_num += 10 + ci.current_char - &h41
            elseif ci.current_char <= &h66 then
                current_num += 10 + ci.current_char - &h61
            endif
            ci = nextchar(ci, f)
        wend
    else
        while (&h30 <= ci.current_char andalso ci.current_char <= &h39) or ci.current_char = &h2E
            if ci.current_char = &h2E then
                if is_float then
                    exception("A float can not have two dots", tokens(), f)
                endif
                is_float = true
                current_float = cdbl(current_num)
            elseif is_float then
                rem TODO improve this
                current_float += cdbl(ci.current_char - &h30) / current_power_of_ten
                current_power_of_ten *= 10
            else
                current_num *= 10
                current_num += ci.current_char - &h30
            endif
            ci = nextchar(ci, f)
        wend
    endif

    dim tok as token
    tok = create_new_token(ci.index)
    tok.pos_start = start_index
    tok.pos_end = ci.index
    if is_float then
        tok.tok_type = TOK_FLOAT
        tok.value_float.value_type = C_DOUBLE
        tok.value_float.c_double = current_float
    else
        tok.tok_type = TOK_INTEGER
        tok.value_int.value_type = C_LONGLONG
        tok.value_int.value = current_num
        tok.value_int.is_unsigned = false
    endif
    ci.do_not_advance = true

    dim cit as ci_and_token
    cit.ci = ci
    cit.tok = tok

    return cit
end function


rem Turns the source file into a list of tokens, returns the final length of
rem tokens
function lexer (f as integer, C_99_KEYWORDS(any) as string, tokens(any) as token) as integer
    print "Lexer"

    dim ci as char_and_index
    ci.index = -1
    ci.beginning_of_line = true
    ci.do_not_advance = false

    dim cit as ci_and_token

    dim temporary_token as token
    dim tok_index as integer = 0

    dim encountered_escape_seq_character as boolean
    encountered_escape_seq_character = false

    do
        if not ci.do_not_advance then
            ci = nextchar(ci, f)
        else
            ci.do_not_advance = false
        endif

        if ci.index = 0 then
            ci.beginning_of_line = true
        endif

        if ci.current_char = 10 then
            rem \n, nothing to do
        elseif ci.current_char >= &h30 andalso ci.current_char <= &h39 then
            rem numbers
            cit = make_num(ci, tokens(), f)
            ci = cit.ci
            newtok(cit.tok, tokens(), tok_index)
        elseif  (ci.current_char >= &h41 andalso ci.current_char <= &h5A) _
             or (ci.current_char >= &h61 andalso ci.current_char <= &h7A) _
             or (ci.current_char = &h5F) _
        then
            rem identifiers. We’re doing C99, so no Unicode here
            rem &h5F is underscore
            make_id(ci, tokens(), tok_index, f, C_99_KEYWORDS())
        elseif ci.beginning_of_line andalso ci.current_char = 35 then  rem '#'
            rem skip special preprocessor lines
            while ci.current_char <> 10 andalso ci.current_char <> 0
                ci = nextchar(ci, f)
            wend
        elseif (chr(ci.current_char) = "[") then
            temporary_token = create_new_token(ci.index)
            temporary_token.tok_type = TOK_LSQUARE
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "]") then
            temporary_token = create_new_token(ci.index)
            temporary_token.tok_type = TOK_RSQUARE
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "(") then
            temporary_token = create_new_token(ci.index)
            temporary_token.tok_type = TOK_LPAREN
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = ")") then
            temporary_token = create_new_token(ci.index)
            temporary_token.tok_type = TOK_RPAREN
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "{") then
            temporary_token = create_new_token(ci.index)
            temporary_token.tok_type = TOK_LBRACKET
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "}") then
            temporary_token = create_new_token(ci.index)
            temporary_token.tok_type = TOK_RBRACKET
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "~") then
            temporary_token = create_new_token(ci.index)
            temporary_token.tok_type = TOK_BITWISENOT
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "?") then
            temporary_token = create_new_token(ci.index)
            temporary_token.tok_type = TOK_INTERROGATION
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = ":") then
            temporary_token = create_new_token(ci.index)
            temporary_token.tok_type = TOK_COLON
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = ";") then
            temporary_token = create_new_token(ci.index)
            temporary_token.tok_type = TOK_SEMICOLON
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = ",") then
            temporary_token = create_new_token(ci.index)
            temporary_token.tok_type = TOK_COMMA
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = ".") then
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)
            if (chr(ci.current_char) = ".") then
                ci = nextchar(ci, f)
                if (chr(ci.current_char) <> ".") then  rem ...
                    exception("Expected '.' after '..'", tokens(), f)
                endif
                temporary_token.tok_type = TOK_ELLIPSIS
            else  rem .
                ci.do_not_advance = true
                temporary_token.tok_type = TOK_DOT
            endif
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "-") then
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)
            if (chr(ci.current_char) = ">") then  rem ->
                temporary_token.tok_type = TOK_ARROW
            elseif (chr(ci.current_char) = "-") then  rem --
                temporary_token.tok_type = TOK_MINUSMINUS
            elseif (chr(ci.current_char) = "=") then  rem -=
                temporary_token.tok_type = TOK_MINUSEQ
            else  rem -
                temporary_token.tok_type = TOK_MINUS
                ci.do_not_advance = true
            endif
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "+") then
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)
            if (chr(ci.current_char) = "+") then  rem ++
                temporary_token.tok_type = TOK_PLUSPLUS
            elseif (chr(ci.current_char) = "=") then  rem +=
                temporary_token.tok_type = TOK_PLUSEQ
            else  rem +
                temporary_token.tok_type = TOK_PLUS
                ci.do_not_advance = true
            endif
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "&") then
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)
            if (chr(ci.current_char) = "&") then  rem &&
                temporary_token.tok_type = TOK_AND
            elseif (chr(ci.current_char) = "=") then  rem &=
                temporary_token.tok_type = TOK_AMPEQ
            else  rem &
                temporary_token.tok_type = TOK_AMP
                ci.do_not_advance = true
            endif
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "*") then
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)
            if (chr(ci.current_char) = "=") then  rem *=
                temporary_token.tok_type = TOK_MULTEQ
            else  rem *
                temporary_token.tok_type = TOK_MULT
                ci.do_not_advance = true
            endif
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "!") then
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)
            if (chr(ci.current_char) = "=") then  rem !=
                temporary_token.tok_type = TOK_NEQ
            else  rem !
                temporary_token.tok_type = TOK_BANG
                ci.do_not_advance = true
            endif
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "/") then
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)
            if (chr(ci.current_char) = "=") then  rem /=
                temporary_token.tok_type = TOK_DIVEQ
            else  rem /
                temporary_token.tok_type = TOK_SLASH
                ci.do_not_advance = true
            endif
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "%") then
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)
            if (chr(ci.current_char) = "=") then  rem %=
                temporary_token.tok_type = TOK_PERCENTEQ
            else  rem %
                temporary_token.tok_type = TOK_PERCENT
                ci.do_not_advance = true
            endif
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "<") then
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)
            if (chr(ci.current_char) = "<") then  rem <<
                ci = nextchar(ci, f)
                if (chr(ci.current_char) = "=") then  rem <<=
                    temporary_token.tok_type = TOK_LSHIFTEQ
                else  rem <<
                    temporary_token.tok_type = TOK_LSHIFT
                    ci.do_not_advance = true
                endif
            elseif (chr(ci.current_char) = "=") then  rem <=
                temporary_token.tok_type = TOK_LTE
            else  rem <
                temporary_token.tok_type = TOK_LT
                ci.do_not_advance = true
            endif
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = ">") then
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)
            if (chr(ci.current_char) = ">") then  rem >>
                ci = nextchar(ci, f)
                if (chr(ci.current_char) = "=") then  rem >>=
                    temporary_token.tok_type = TOK_RSHIFTEQ
                else  rem >>
                    temporary_token.tok_type = TOK_RSHIFT
                    ci.do_not_advance = true
                endif
            elseif (chr(ci.current_char) = "=") then  rem >=
                temporary_token.tok_type = TOK_GTE
            else  rem >
                temporary_token.tok_type = TOK_GT
                ci.do_not_advance = true
            endif
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "=") then
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)
            if (chr(ci.current_char) = "=") then  rem ==
                temporary_token.tok_type = TOK_EEQ
            else  rem =
                temporary_token.tok_type = TOK_EQ_ASSIGN
                ci.do_not_advance = true
            endif
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "^") then
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)
            if (chr(ci.current_char) = "=") then  rem ^=
                temporary_token.tok_type = TOK_BITWISEXOREQ
            else  rem ^
                temporary_token.tok_type = TOK_BITWISEXOR
                ci.do_not_advance = true
            endif
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "|") then
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)
            if (chr(ci.current_char) = "=") then  rem |=
                temporary_token.tok_type = TOK_BITWISEOREQ
            elseif (chr(ci.current_char) = "|") then  rem ||
                temporary_token.tok_type = TOK_OR
            else  rem |
                temporary_token.tok_type = TOK_BITWISEOR
                ci.do_not_advance = true
            endif
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = !"\"") then  rem strings
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)

            dim current_string as string
            current_string = ""
            encountered_escape_seq_character = false

            while (encountered_escape_seq_character or (chr(ci.current_char) <> !"\"" andalso ci.current_char <> 0))
                if encountered_escape_seq_character then
                    encountered_escape_seq_character = false
                    if chr(ci.current_char) = "\" then
                        current_string = current_string + "\"
                    elseif chr(ci.current_char) = "n" then
                        current_string = current_string + !"\n"
                    elseif chr(ci.current_char) = "t" then
                        current_string = current_string + !"\t"
                    elseif chr(ci.current_char) = "0" then
                        current_string = current_string + chr(0)
                    elseif chr(ci.current_char) = !"\"" then
                        current_string = current_string + !"\""
                    elseif chr(ci.current_char) = "'" then
                        current_string = current_string + "'"
                    endif
                elseif chr(ci.current_char) = "\" then
                    encountered_escape_seq_character = true
                else
                    current_string = current_string + chr(ci.current_char)
                endif
                ci = nextchar(ci, f)
            wend

            temporary_token.value_str = current_string
            temporary_token.tok_type = TOK_STRING
            newtok(temporary_token, tokens(), tok_index)
        elseif (chr(ci.current_char) = "'") then  rem chars
            temporary_token = create_new_token(ci.index)
            ci = nextchar(ci, f)

            if chr(ci.current_char) = "\" then
                ci = nextchar(ci, f)

                if chr(ci.current_char) = "\" then
                    temporary_token.value_str = "\"
                elseif chr(ci.current_char) = "n" then
                    temporary_token.value_str = !"\n"
                elseif chr(ci.current_char) = "t" then
                    temporary_token.value_str = !"\t"
                elseif chr(ci.current_char) = "0" then
                    temporary_token.value_str = chr(0)
                elseif chr(ci.current_char) = !"\"" then
                    temporary_token.value_str = !"\""
                elseif chr(ci.current_char) = "'" then
                    temporary_token.value_str = "'"
                endif
            else
                temporary_token.value_str = chr(ci.current_char)
            endif

            ci = nextchar(ci, f)

            if chr(ci.current_char) <> "'" then
                exception(!"Expected \"'\" to close the char literal", tokens(), f)
            endif

            temporary_token.tok_type = TOK_CHAR
            newtok(temporary_token, tokens(), tok_index)
        elseif ci.current_char = 9 or ci.current_char = 32 then
            rem tab and space
        elseif ci.current_char <> 0 then
            rem any other character
            print chr(ci.current_char);
        endif
    loop while ci.current_char <> 0

    return tok_index
end function


rem prints the token passed in tok in a pretty way ; used for debugging
sub print_token(tok as token)
    print tok.tok_type; !"\t";
    print tok.pos_start; !"\t";
    print tok.pos_end; !"\t";

    if tok.tok_type = TOK_STRING or tok.tok_type = TOK_CHAR then
        print !"\""; tok.value_str; !"\"";

    elseif tok.tok_type = TOK_IDENTIFIER or tok.tok_type = TOK_KEYWORD then
        print tok.value_str;

    elseif tok.value_int.value_type <> NO_VALUE then
        print tok.value_int.value; ", type: ";
        print tok.value_int.value_type; ", is_unsigned: ";
        print tok.value_int.is_unsigned;

    elseif tok.value_float.value_type <> NO_VALUE then
        if tok.value_float.value_type = C_SINGLE then
            print tok.value_float.c_float; !" (single)";
        else
            print tok.value_float.c_double; !" (double)";
        endif
    endif

    print ""
end sub

dim f as integer
f = freefile
open "coucou.cpp" for binary as #f
if err > 0 then print "Error opening the file. Error code:"; err : end

dim len_tokens as integer
redim tokens(0 to 32) as token
len_tokens = lexer(f, C_99_KEYWORDS(), tokens())

close #f
print !"\nTokens :"
print !"type\t start\t end"
for i as integer = lbound(tokens) to len_tokens-1
    print_token(tokens(i))
next
erase tokens

