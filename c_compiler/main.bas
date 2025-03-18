rem print "hello world"
rem dim astring as string
rem dim aninteger as integer
rem astring = "coucou"
rem aninteger = 12
rem print astring
rem print aninteger

rem dim thisisalist(5) as string
rem thisisalist(0) = "test"
rem thisisalist(1) = "test1"
rem thisisalist(2) = "test2"
rem thisisalist(3) = "test3"
rem thisisalist(4) = "test4"

rem dim index as integer
rem input "Indice" ; index

rem print thisisalist(index)

option gosub

mainstart:
    Dim f as Integer, s as String
    Dim fl as long
    Dim current_char as Ubyte
    Dim index as Long

    f = FreeFile

    Open "coucou.c" For Binary As #f
    If Err > 0 Then Print "Error opening the file. Error code:"; Err : End

    index = -1

    gosub lexer
    goto mainend

lexer:
    print "hello"
    mainloop:
        gosub parseonechar
        print chr(current_char)
        if current_char > 0 then goto mainloop
    return

parseonechar:
    Get #f, , current_char
    index += 1
    return

mainend:
    Close #f
    End

