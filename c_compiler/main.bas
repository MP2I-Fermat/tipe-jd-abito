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
    Dim f as Integer
    Dim current_char as Ubyte
    Dim index as Long

    f = FreeFile

    Open "coucou.c" For Binary As #f
    If Err > 0 Then Print "Error opening the file. Error code:"; Err : End

    index = -1

    gosub lexer
    goto mainend

rem Sub lexer
rem Turns the source file into a list of tokens
lexer:
    print "Lexer"
    mainloop:
        gosub parseonechar
        if current_char >= &h30 AndAlso current_char <= &h39 Then
            gosub make_num
        Else
            print chr(current_char);
        End If
        if current_char > 0 then goto mainloop
    return

rem Sub parseonechar
rem Updates current_char to the next char of the file and increments index
rem Does not check if EOF is reached - please check if current_char is <> 0
rem before calling
parseonechar:
    Get #f, , current_char
    index += 1
    return

rem Sub make_num
rem Parses a number
make_num:
    print chr(current_char)
    print "Detected number"
    return

rem Label mainend
rem Closes the source file and ends the program.
mainend:
    Close #f
    End

