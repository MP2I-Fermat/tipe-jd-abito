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

    inpf = FreeFile
    Open "coucou.c" For Binary As #inpf
    If Err > 0 Then Print "Error opening the input file. Error code:"; Err : End

    outf = FreeFile
    Open "coucou.preprocessed" For Binary As #outf
    If Err > 0 Then Print "Error opening the output file. Error code:"; Err : End

    index = -1

    gosub preprocessor
    goto mainend


rem Sub preprocessor
rem Copies header libraries, replaces macros and deletes comments
preprocessor:
    print "Preprocessor"
    gosub parseonechar
    mainloop:
        rem 35 is codepoint of #
        if current_char = 35 then
            while current_char <> 10 and current_char <> 0
                gosub parseonechar
            wend
        else
            if current_char = 10 then
                put #outf, , chr(10)
                gosub parseonechar
            else
                while current_char > 0 and current_char <> 10
                    put #outf, , chr(current_char)
                    gosub parseonechar
                wend
            end if
        end if
        if current_char > 0 then goto mainloop
    return

rem Sub parseonechar
rem Updates current_char to the next char of the file and increments index
rem Does not check if EOF is reached - please check if current_char is <> 0
rem before calling
parseonechar:
    Get #inpf, , current_char
    index += 1
    return

rem Label mainend
rem Closes the source file and ends the program.
mainend:
    Close #inpf
    End

