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

mainstart:
    rem === TOKEN TYPES ===
    rem  0 : [undefined]
    rem  1 : integer
    rem  2 : hex
    rem  3 : oct
    rem  4 : bin
    rem  5 : float
    rem  6 : identifier
    rem  7 : (
    rem  8 : )
    rem  9 : {
    rem 10 : }
    rem 11 : [
    rem 12 : ]
    rem 13 : colon (:)
    rem 14 : semicolon (;)
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
    dim temporary_token as token
    redim tokens(0 to 30) as token
    print ubound(tokens)
    dim tok_index = 0

    f = freefile

    open "coucou.cpp" for binary as #f
    if err > 0 then print "Error opening the file. Error code:"; err : end

    index = -1

    gosub lexer
    goto mainend


rem Sub lexer
rem Turns the source file into a list of tokens
lexer:
    print "Lexer"
    lexer_mainloop:
        gosub parseonechar
        if current_char >= &h30 andalso current_char <= &h39 then
            gosub make_num
        else
            print chr(current_char);
        end if
        if current_char > 0 then goto lexer_mainloop
    return


rem Sub newtok
rem Adds the token stored in temporary_token to the tokens array, eventually
rem resizing it
newtok:
    if tok_index = ubound(tokens) then
        redim preserve tokens(0 to ubound(tokens)*2)
    end if
    tokens(tok_index) = temporary_token
    tok_index += 1

    return

rem Sub print_token
rem prints the token stored in temporary_token in a pretty way ; used for
rem debugging
print_token:
    print !"\""; temporary_token.value_str; !"\" ";
    print temporary_token.value_int; " ";
    print temporary_token.value_float; " ";
    print temporary_token.tok_type; " ";
    print temporary_token.pos_start; " ";
    print temporary_token.pos_end

    return

rem Sub parseonechar
rem Updates current_char to the next char of the file and increments index
rem Does not check if EOF is reached - please check if current_char is <> 0
rem before calling
parseonechar:
    get #f, , current_char
    index += 1
    return

rem Sub make_num
rem Parses a number
make_num:
    print chr(current_char)
    print "Detected number"
    temporary_token.value_str = ""
    temporary_token.value_float = 0.0
    temporary_token.value_int = current_char - &h30
    temporary_token.pos_start = index
    temporary_token.pos_end = index
    temporary_token.tok_type = 1
    gosub newtok
    return

rem Label mainend
rem Closes the source file and ends the program.
mainend:
    close #f
    for i as integer = lbound(tokens) to tok_index-1
        temporary_token = tokens(i)
        gosub print_token
    next
    erase tokens
    end

