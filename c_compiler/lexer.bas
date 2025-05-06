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

mainstart:
    rem === TOKEN TYPES ===
    rem  0 : [undefined]
    rem  1 : integer
    rem  2 : hex  -- todo
    rem  5 : float -- todo
    rem  6 : identifier
    rem 60 : keyword
    rem  7 : [
    rem  8 : ]
    rem  9 : (
    rem 10 : )
    rem 11 : {
    rem 12 : }
    rem 13 : .
    rem 14 : ->
    rem 15 : ++
    rem 16 : --
    rem 17 : &
    rem 18 : *
    rem 19 : +
    rem 20 : -
    rem 21 : ~
    rem 22 : !
    rem 23 : /
    rem 24 : %
    rem 25 : <<
    rem 26 : >>
    rem 27 : <
    rem 28 : >
    rem 29 : <=
    rem 30 : >=
    rem 31 : ==
    rem 32 : !=
    rem 33 : ^
    rem 34 : |
    rem 35 : &&
    rem 36 : ||
    rem 37 : ?
    rem 38 : :
    rem 39 : ;
    rem 40 : ...
    rem 41 : =
    rem 42 : *=
    rem 43 : /=
    rem 44 : %=
    rem 45 : +=
    rem 46 : -=
    rem 47 : <<=
    rem 48 : >>=
    rem 49 : &=
    rem 50 : ^=
    rem 51 : |=
    rem 52 : ,
    rem 53 : string -- note: \x is unused in tinycc -- todo
    rem 54 : char ('X') -- todo
    rem 60 : keyword
    rem The following tokens are not used in tinycc, so they will not be
    rem implemented
    rem  3 : oct (will not be implemented)
    rem  4 : bin (will not be implemented)
    rem  7 : <:  (will not be implemented)
    rem  8 : :>  (will not be implemented)
    rem 11 : <%  (will not be implemented)
    rem 12 : %>  (will not be implemented)
    rem ===================
    type token
        value_str as string
        value_int as long
        value_float as single
        tok_type as integer
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
            temporary_token.tok_type = 7
            gosub newtok
        elseif (chr(current_char) = "]") then
            gosub init_temp_token
            temporary_token.tok_type = 8
            gosub newtok
        elseif (chr(current_char) = "(") then
            gosub init_temp_token
            temporary_token.tok_type = 9
            gosub newtok
        elseif (chr(current_char) = ")") then
            gosub init_temp_token
            temporary_token.tok_type = 10
            gosub newtok
        elseif (chr(current_char) = "{") then
            gosub init_temp_token
            temporary_token.tok_type = 11
            gosub newtok
        elseif (chr(current_char) = "}") then
            gosub init_temp_token
            temporary_token.tok_type = 12
            gosub newtok
        elseif (chr(current_char) = "~") then
            gosub init_temp_token
            temporary_token.tok_type = 21
            gosub newtok
        elseif (chr(current_char) = "?") then
            gosub init_temp_token
            temporary_token.tok_type = 37
            gosub newtok
        elseif (chr(current_char) = ":") then
            gosub init_temp_token
            temporary_token.tok_type = 38
            gosub newtok
        elseif (chr(current_char) = ";") then
            gosub init_temp_token
            temporary_token.tok_type = 39
            gosub newtok
        elseif (chr(current_char) = ",") then
            gosub init_temp_token
            temporary_token.tok_type = 52
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
                temporary_token.tok_type = 40
            else  rem .
                do_not_advance = true
                temporary_token.tok_type = 13
            endif
            gosub newtok
        elseif (chr(current_char) = "-") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = ">") then  rem ->
                temporary_token.tok_type = 14
            elseif (chr(current_char) = "-") then  rem --
                temporary_token.tok_type = 16
            elseif (chr(current_char) = "=") then  rem -=
                temporary_token.tok_type = 46
            else  rem -
                temporary_token.tok_type = 20
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "+") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "+") then  rem ++
                temporary_token.tok_type = 15
            elseif (chr(current_char) = "=") then  rem +=
                temporary_token.tok_type = 45
            else  rem +
                temporary_token.tok_type = 19
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "&") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "&") then  rem &&
                temporary_token.tok_type = 35
            elseif (chr(current_char) = "=") then  rem &=
                temporary_token.tok_type = 49
            else  rem &
                temporary_token.tok_type = 17
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "*") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "=") then  rem *=
                temporary_token.tok_type = 42
            else  rem *
                temporary_token.tok_type = 18
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "!") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "=") then  rem !=
                temporary_token.tok_type = 32
            else  rem !
                temporary_token.tok_type = 22
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "/") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "=") then  rem /=
                temporary_token.tok_type = 43
            else  rem /
                temporary_token.tok_type = 23
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "%") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "=") then  rem %=
                temporary_token.tok_type = 44
            else  rem %
                temporary_token.tok_type = 24
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "<") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "<") then  rem <<
                gosub nextchar
                if (chr(current_char) = "=") then  rem <<=
                    temporary_token.tok_type = 47
                else  rem <<
                    temporary_token.tok_type = 25
                    do_not_advance = true
                endif
            elseif (chr(current_char) = "=") then  rem <=
                temporary_token.tok_type = 29
            else  rem <
                temporary_token.tok_type = 27
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = ">") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = ">") then  rem >>
                gosub nextchar
                if (chr(current_char) = "=") then  rem >>=
                    temporary_token.tok_type = 48
                else  rem >>
                    temporary_token.tok_type = 26
                    do_not_advance = true
                endif
            elseif (chr(current_char) = "=") then  rem >=
                temporary_token.tok_type = 30
            else  rem >
                temporary_token.tok_type = 28
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "=") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "=") then  rem ==
                temporary_token.tok_type = 31
            else  rem =
                temporary_token.tok_type = 41
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "^") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "=") then  rem ^=
                temporary_token.tok_type = 50
            else  rem ^
                temporary_token.tok_type = 33
                do_not_advance = true
            endif
            gosub newtok
        elseif (chr(current_char) = "|") then
            gosub init_temp_token
            gosub nextchar
            if (chr(current_char) = "=") then  rem |=
                temporary_token.tok_type = 51
            elseif (chr(current_char) = "|") then  rem ||
                temporary_token.tok_type = 36
            else  rem |
                temporary_token.tok_type = 34
                do_not_advance = true
            endif
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
    temporary_token.value_float = 0.0
    temporary_token.value_int = 0
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
    print !"\""; temporary_token.value_str; !"\"\t\t";
    print temporary_token.value_int; !"\t";
    print temporary_token.value_float; !"\t";
    print temporary_token.tok_type; !"\t";
    print temporary_token.pos_start; !"\t";
    print temporary_token.pos_end

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
    dim current_num = 0
    start_index = index

    while &h30 <= current_char andalso current_char <= &h39
        current_num *= 10
        current_num += current_char - &h30
        gosub nextchar
    wend

    gosub init_temp_token
    temporary_token.value_int = current_num
    temporary_token.pos_start = start_index
    temporary_token.pos_end = index
    temporary_token.tok_type = 1
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

    temporary_token.tok_type = 6
    for i1 as integer = lbound(C_99_KEYWORDS) to ubound(C_99_KEYWORDS)
        if current_id = C_99_KEYWORDS(i1) then
            temporary_token.tok_type = 60
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
    print !"str\t\t int\t float\t type\t start\t end"
    for i as integer = lbound(tokens) to tok_index-1
        temporary_token = tokens(i)
        gosub print_token
    next
    erase tokens
    end

