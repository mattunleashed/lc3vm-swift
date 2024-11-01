.ORIG x3000 ; program starts at address x3000
LEA R0, TEXT
AND R1, R1, #0
ADD R1, R1, #5
LOOP ADD R1, R1, #-1
PUTS
BRp LOOP
HALT
TEXT .STRINGZ "Hello, World!\n"
.END
