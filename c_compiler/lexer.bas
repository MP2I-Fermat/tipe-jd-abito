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

option gosub

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
const TOK_RBRACKET = 12       rem {
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
const TOK_BITWISEXOR = 33    rem ^
const TOK_BITWISEOR = 34     rem |
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
const TOK_BITWISEXOREQ = 50  rem ^=
const TOK_BITWISEOREQ = 51    rem |=
const TOK_COMMA = 52          rem ,
const TOK_STRING = 53         rem string -- note: \x and L"" are unused in tinycc
const TOK_CHAR = 54           rem char ('X') -- note: u'', U'' and L'' are unused in tinycc
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

dim f as integer
dim current_char as ubyte
dim index as long
dim start_index as long
dim errmsg as string

dim temporary_token as token
redim tokens(0 to 32) as token
dim tok_index = 0

dim beginning_of_line = true
dim do_not_advance = false

dim encountered_escape_seq_character = false

f = freefile

open "test.c" for binary as #f
if err > 0 then print "Error opening the file. Error code:"; err : end

index = -1

gosub lexer
goto mainend


rem Sub lexer
rem Turns the source file into a list of tokens
lexer:
    print "Lexer"
    do
        if not do_not_advance then
            gosub nextchar
        else
            do_not_advance = false
        endif

        if index = 0 then
            beginning_of_line = true
        endif

        if current_char = 10 then
            rem \n
            print chr(current_char);
            beginning_of_line = true
        elseif current_char >= &h30 andalso current_char <= &h39 then
            rem numbers
            gosub make_num
        elseif  (current_char >= &h41 andalso current_char <= &h5A) _
             or (current_char >= &h61 andalso current_char <= &h7A) _
             or (current_char = &h5F) _
        then
            rem identifiers. We’re doing C99, so no Unicode here
            rem &h5F is underscore
            gosub make_id
        elseif beginning_of_line andalso current_char = 35 then  rem '#'
            rem special preprocessor lines
            gosub skip_preprocessor_output
        elseif (chr(current_char) = "[") then
            gosub init_temp_token
            temporary_token.tok_type = TOK_LSQUARE
            gosub newtok
        elseif (chr(current_char) = "]") then
            gosub init_temp_token
            temporary_token.tok_type = TOK_LSQUARE
            gosub newtok
        elseif (chr(current_char) = "(") then
            gosub init_temp_token
            temporary_token.tok_type = TOK_LPAREN
            gosub newtok
        elseif (chr(current_char) = ")") then
            gosub init_temp_token
            temporary_token.tok_type = TOK_RPAREN
            gosub newtok
        elseif (chr(current_char) = "{") then
            gosub init_temp_token
            temporary_token.tok_type = TOK_LBRACKET
            gosub newtok
        elseif (chr(current_char) = "}") then
            gosub init_temp_token
            temporary_token.tok_type = TOK_RBRACKET
            gosub newtok
        elseif (chr(current_char) = "~") then
            gosub init_temp_token
            temporary_token.tok_type = TOK_BITWISENOT
            gosub newtok
        elseif (chr(current_char) = "?") then
            gosub init_temp_token
            temporary_token.tok_type = TOK_INTERROGATION
            gosub newtok
        elseif (chr(current_char) = ":") then
            gosub init_temp_token
            temporary_token.tok_type = TOK_COLON
            gosub newtok
        elseif (chr(current_char) = ";") then
            gosub init_temp_token
            temporary_token.tok_type = TOK_SEMICOLON
            gosub newtok
        elseif (chr(current_char) = ",") then
            gosub init_temp_token
            temporary_token.tok_type = TOK_COMMA
            gosub newtok
        elseif (chr(current_char) = ".") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = ".") then
                gosub nextchar
                if (chr(current_char) <> ".") then  rem ...
                    errmsg = "Expected '.' after '..'"
                    goto exception
                endif
                temporary_token.tok_type = TOK_ELLIPSIS
            else  rem .
                do_not_advance = true
                temporary_token.tok_type = TOK_DOT
            endif
            gosub newtok
        elseif (chr(current_char) = "-") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = ">") then  rem ->
                temporary_token.tok_type = TOK_ARROW
            elseif (chr(current_char) = "-") then  rem --
                temporary_token.tok_type = TOK_MINUSMINUS
            elseif (chr(current_char) = "=") then  rem -=
                temporary_token.tok_type = TOK_MINUSEQ
            else  rem -
                temporary_token.tok_type = TOK_MINUS
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "+") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "+") then  rem ++
                temporary_token.tok_type = TOK_PLUSPLUS
            elseif (chr(current_char) = "=") then  rem +=
                temporary_token.tok_type = TOK_PLUSEQ
            else  rem +
                temporary_token.tok_type = TOK_PLUS
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "&") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "&") then  rem &&
                temporary_token.tok_type = TOK_AND
            elseif (chr(current_char) = "=") then  rem &=
                temporary_token.tok_type = TOK_AMPEQ
            else  rem &
                temporary_token.tok_type = TOK_AMP
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "*") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "=") then  rem *=
                temporary_token.tok_type = TOK_MULTEQ
            else  rem *
                temporary_token.tok_type = TOK_MULT
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "!") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "=") then  rem !=
                temporary_token.tok_type = TOK_NEQ
            else  rem !
                temporary_token.tok_type = TOK_BANG
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "/") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "=") then  rem /=
                temporary_token.tok_type = TOK_DIVEQ
            else  rem /
                temporary_token.tok_type = TOK_SLASH
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "%") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "=") then  rem %=
                temporary_token.tok_type = TOK_PERCENTEQ
            else  rem %
                temporary_token.tok_type = TOK_PERCENT
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "<") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "<") then  rem <<
                gosub nextchar
                if (chr(current_char) = "=") then  rem <<=
                    temporary_token.tok_type = TOK_LSHIFTEQ
                else  rem <<
                    temporary_token.tok_type = TOK_LSHIFT
                    do_not_advance = true
                endif
            elseif (chr(current_char) = "=") then  rem <=
                temporary_token.tok_type = TOK_LTE
            else  rem <
                temporary_token.tok_type = TOK_LT
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = ">") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = ">") then  rem >>
                gosub nextchar
                if (chr(current_char) = "=") then  rem >>=
                    temporary_token.tok_type = TOK_RSHIFTEQ
                else  rem >>
                    temporary_token.tok_type = TOK_RSHIFT
                    do_not_advance = true
                endif
            elseif (chr(current_char) = "=") then  rem >=
                temporary_token.tok_type = TOK_GTE
            else  rem >
                temporary_token.tok_type = TOK_GT
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "=") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "=") then  rem ==
                temporary_token.tok_type = TOK_EEQ
            else  rem =
                temporary_token.tok_type = TOK_EQ_ASSIGN
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "^") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "=") then  rem ^=
                temporary_token.tok_type = TOK_BITWISEXOREQ
            else  rem ^
                temporary_token.tok_type = TOK_BITWISEXOR
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "|") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "=") then  rem |=
                temporary_token.tok_type = TOK_BITWISEOREQ
            elseif (chr(current_char) = "|") then  rem ||
                temporary_token.tok_type = TOK_OR
            else  rem |
                temporary_token.tok_type = TOK_BITWISEOR
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = !"\"") then  rem strings
            gosub init_temp_token
            gosub nextchar

            dim current_string as string
            current_string = ""
            encountered_escape_seq_character = false

            while (encountered_escape_seq_character or (chr(current_char) <> !"\"" and current_char <> 0))
                if encountered_escape_seq_character then
                    encountered_escape_seq_character = false
                    if chr(current_char) = "\" then
                        current_string = current_string + "\"
                    elseif chr(current_char) = "n" then
                        current_string = current_string + !"\n"
                    elseif chr(current_char) = "t" then
                        current_string = current_string + !"\t"
                    elseif chr(current_char) = "0" then
                        current_string = current_string + chr(0)
                    elseif chr(current_char) = !"\"" then
                        current_string = current_string + !"\""
                    elseif chr(current_char) = "'" then
                        current_string = current_string + "'"
                    endif
                elseif chr(current_char) = "\" then
                    encountered_escape_seq_character = true
                else
                    current_string = current_string + chr(current_char)
                endif
                gosub nextchar
            wend

            temporary_token.value_str = current_string
            temporary_token.tok_type = TOK_STRING
            gosub newtok
        elseif (chr(current_char) = "'") then  rem chars
            gosub init_temp_token
            gosub nextchar

            if chr(current_char) = "\" then
                gosub nextchar

                if chr(current_char) = "\" then
                    temporary_token.value_str = "\"
                elseif chr(current_char) = "n" then
                    temporary_token.value_str = !"\n"
                elseif chr(current_char) = "t" then
                    temporary_token.value_str = !"\t"
                elseif chr(current_char) = "0" then
                    temporary_token.value_str = chr(0)
                elseif chr(current_char) = !"\"" then
                    temporary_token.value_str = !"\""
                elseif chr(current_char) = "'" then
                    temporary_token.value_str = "'"
                endif
            else
                temporary_token.value_str = chr(current_char)
            endif

            gosub nextchar

            if chr(current_char) <> "'" then
                errmsg = !"Expected \"'\" to close the char literal"
                goto exception
            endif

            temporary_token.tok_type = TOK_CHAR
            gosub newtok
        elseif current_char <> 0 then
            rem any other character
            print chr(current_char);
        endif
    loop while current_char <> 0
    return


rem Sub skip_preprocessor_output
rem Skips lines starting with '#' generated by the preprocessor
skip_preprocessor_output:
    while current_char <> 10 andalso current_char <> 0
        gosub nextchar
    wend
    return


rem Sub init_temp_token
rem Reinitialises the global temporary_token variable to default values
rem (0s everywhere (except pos_start and pos_end, which are initialised with
rem `index`))
init_temp_token:
    temporary_token.value_str = ""
    temporary_token.value_float.value_type = NO_VALUE
    temporary_token.value_int.value_type = NO_VALUE
    temporary_token.pos_start = index
    temporary_token.pos_end = index
    temporary_token.tok_type = 0
    return

rem Sub newtok
rem Adds the token stored in temporary_token to the tokens array, eventually
rem resizing it
newtok:
    if tok_index = ubound(tokens) then
        redim preserve tokens(0 to ubound(tokens)*2)
    endif
    tokens(tok_index) = temporary_token
    tok_index += 1

    return

rem Sub print_token
rem prints the token stored in temporary_token in a pretty way ; used for
rem debugging
print_token:
    print temporary_token.tok_type; !"\t";
    print temporary_token.pos_start; !"\t";
    print temporary_token.pos_end; !"\t";

    if temporary_token.tok_type = TOK_STRING or _
       temporary_token.tok_type = TOK_CHAR then
        print !"\""; temporary_token.value_str; !"\"";

    elseif temporary_token.tok_type = TOK_IDENTIFIER or _
           temporary_token.tok_type = TOK_KEYWORD then
        print temporary_token.value_str;

    elseif temporary_token.value_int.value_type <> NO_VALUE then
        print temporary_token.value_int.value; ", type: ";
        print temporary_token.value_int.value_type; ", is_unsigned: ";
        print temporary_token.value_int.is_unsigned;

    elseif temporary_token.value_float.value_type <> NO_VALUE then
        if temporary_token.value_float.value_type = C_SINGLE then
            print temporary_token.value_float.c_float; !"(single)";
        else
            print temporary_token.value_float.c_double; !"(double)";
        endif
    endif

    print ""

    return

rem Sub nextchar
rem Updates current_char to the next char of the file and increments index
rem Does not check if EOF is reached - please check that current_char is <> 0
rem before calling
nextchar:
    if current_char = 10 then
        beginning_of_line = true
    else
        beginning_of_line = false
    endif
    get #f, , current_char
    index += 1
    return

rem Sub make_num
rem Parses a number
make_num:
    dim current_num as longint
    dim current_float as double
    current_num = 0
    current_float = 0.0
    dim is_float = false
    dim current_power_of_ten = 10
    start_index = index

    if current_char = &h30 then
        gosub nextchar
    endif
    if chr(current_char) = "x" then  rem hexadecimal
        gosub nextchar
        while (&h30 <= current_char andalso current_char <= &h39) or _
              (&h41 <= current_char andalso current_char <= &h46) or _
              (&h61 <= current_char andalso current_char <= &h66)
            current_num *= 16
            if current_char <= &h39 then
                current_num += current_char - &h30
            elseif current_char <= &h46 then
                current_num += 10 + current_char - &h41
            elseif current_char <= &h66 then
                current_num += 10 + current_char - &h61
            endif
            gosub nextchar
        wend
    else
        while (&h30 <= current_char andalso current_char <= &h39) or current_char = &h2E
            if current_char = &h2E then
                if is_float then
                    errmsg = "A float can not have two dots"
                    gosub exception
                endif
                is_float = true
                current_float = cdbl(current_num)
            elseif is_float then
                rem TODO improve this
                current_float += cdbl(current_char - &h30) / current_power_of_ten
                print current_float
                current_power_of_ten *= 10
            else
                current_num *= 10
                current_num += current_char - &h30
            endif
            gosub nextchar
        wend
    endif

    gosub init_temp_token
    temporary_token.pos_start = start_index
    temporary_token.pos_end = index
    if is_float then
        temporary_token.tok_type = TOK_FLOAT
        temporary_token.value_float.value_type = C_DOUBLE
        temporary_token.value_float.c_double = current_float
    else
        temporary_token.tok_type = TOK_INTEGER
        temporary_token.value_int.value_type = C_LONGLONG
        temporary_token.value_int.value = current_num
        temporary_token.value_int.is_unsigned = false
    endif
    gosub newtok
    do_not_advance = true
    return


rem Sub make_id
rem Parses an identifier
make_id:
    dim current_id as string
    current_id = ""
    start_index = index

    while (current_char >= &h41 andalso current_char <= &h5A) _
       or (current_char >= &h61 andalso current_char <= &h7A) _
       or (current_char >= &h30 andalso current_char <= &h39) _
       or (current_char = &h5F)
        current_id += chr(current_char)
        gosub nextchar
    wend

    gosub init_temp_token
    temporary_token.value_str = current_id
    temporary_token.pos_start = start_index
    temporary_token.pos_end = index

    temporary_token.tok_type = TOK_IDENTIFIER
    for i1 as integer = lbound(C_99_KEYWORDS) to ubound(C_99_KEYWORDS)
        if current_id = C_99_KEYWORDS(i1) then
            temporary_token.tok_type = TOK_KEYWORD
            exit for
        endif
    next

    gosub newtok

    do_not_advance = true

    return


rem Label exception
rem Closes the source file, prints the error message in errmsg and ends the
rem program
exception:
    close #f
    print "Error: "; errmsg
    erase tokens
    end


rem Label mainend
rem Closes the source file, prints tokens and ends the program.
mainend:
    close #f
    print !"\nTokens :"
    print !"type\t start\t end"
    for i as integer = lbound(tokens) to tok_index-1
        temporary_token = tokens(i)
        gosub print_token
    next
    erase tokens
    end

