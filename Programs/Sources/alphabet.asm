.ORIG x3000
LD R0, START ; Set R0 to 65 ('a')
LD R1, COUNT ; Load count
LOOP BRNZ END ; While loop
OUT ; Print letter
ADD R0, R0, #1 ; Next letter
ADD R1, R1, #-1 ; Decrease count
BR LOOP ; Jump to loop
END AND R0, R0, #0 ; End the program
ADD R0, R0, #10 ; Set R0 to 10 ('\n')
OUT
HALT
START .FILL 65
COUNT .FILL 26
.END
