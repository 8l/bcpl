
@ This will be the machine code library for ARM machines (based on the i386 version)
@ CURRENTLY UNDER DEVELOPMENT.
@ It will be tested on the Raspberry Pi Computer

@ Written by Martin Richards (c) May 2013

	
@ C Linkage:
@   On entry rl   is the return address
@            r0   is the first argument
@            r1   is the second argument
@            etc
@
@   r4 - r13 must be preserved
@
@   result in r0

@ BCPL linkage
@   On entry rl   is the return address
@            r1   is entry address
@            r2   is the new P pointer NP (a m/c address)
@            ra   is the first argument
@            NP!4... are the other arguments
@
@   result in ra

   
.global callstart
.global divrem
.global dosys

ra .req r4
rb .req r5
rc .req r6
rp .req r10
rg .req r11

	
.text
.align 2

callstart:
   stmfd sp!,{r4-r11,lr}
 @ r0 = stackbase (first argument}
 @ r1 = gvec (second argument}

   mov rp, r0    @ rp=r10 is the P pointer
   mov rg, r1    @ rg=r11 is the G pointer

@ Register usage while executing BCPL compiled code

@ r0       Work register
@ r1       Work register, function entry address
@ r2       Work register, new P pointer in call
@ r3       Work register
@ r4    ra Cintcode A
@ r5    rb Cintcode B
@ r6    rc Cintcode C
@ r7-r9    Work registers
@ r10   rp The P pointer -- m/c address
@ r11   rg The G pointer -- m/c address of Global 0
@ r12      Not used
@ r13   sp System Stack pointer
@ r14   lr Link register
@ r15   ip PC

@ make sure global 3 (sys) is defined
   adr r0, sys
   str r0, [rg, #4*3]

@ make sure global 6 (changeco) is defined
   adr r0, changeco
   str r0, [rg, #4*6]

@ make sure global 5 (muldiv) is defined
   adr r0, muldiv
   str r0, [rg, #4*5]

@ BCPL call of clihook(stackupb)
   ldr r0,=stackupb
   ldr r4, [r0]          @ First arg = stackupb
   add r2, rp, #4*6      @ New P pointer
   ldr r1, [rg, #4*4]    @ Entry address -- G!4 = clihook
@   ldr r1, [rg, #1*4]    @ Entry address -- G!1 = start
   mov lr, pc            @ Return address
   mov pc, r1            @ Enter clihook
   mov r0, ra            @ return the result of start
   
@ and return
   ldmfd sp!, {r4-r11,pc}    @ return

@ res = sys(n, x, y, x,...)  the BCPL callable sys function
sys:
 stmia r2!, {rp,lr}
 stmia r2, {r1,ra}
 sub rp, r2, #8
@ P = NP -> [<old P>, <return addr>, <entry addr>, <arg1>, ...]

 mov r0, rp        @ first argument  = P
 mov r1, rg        @ second argument = G
 ldr r2, =dosys
 mov lr, pc
 mov pc, r2        @ Call dosys(P, G)
 mov ra, r0        @ put result in Cintcode A register

 ldmia rp, {rp,pc} @ BCPL function return

changeco:          @ changeco(val, cptr)
   @ r1 = entry address
   @ r2 = NP (a m/c address) then new P pointer
   @ ra = val
   @ NP!4 = cptr (a BCPL pointer)
   @ rp = P pointer (a m/c address) -> [<old P>, <ret addr>, <entry addr>, ...]
   @ rg = G pointer (m/c address of global zero)
   @ lr = return address
   @ z  = r0 (to hold zero)

 z  .req r0
 c  .req r1
 np .req r2
 t  .req r3
   
 mov z, #0
 ldr c, [np, #4*4]        @ c := NP!4  (= cptr) -- a BCPL pointer
 ldr t, [rg, #4*7]        @ c := currco)        -- a BCPL pointer
 str rp, [z, t, lsl#2]    @ currco!0 := P       -- save the resumption point
 str c, [rg, #4*7]        @ currco := cptr      -- set current coroutine
 ldr rp, [z, c, lsl#2]    @ P := !cptr          -- get the resumption point
 mov pc, lr

muldiv:
 @movl r4,r0
 @movl r6,r4         @ new P in ebx
 @imull 16(r4)         @ r0:r6 := double length product
 @idivl 20(r4)         @ r0 = quotient, r6 = remainder
 @movl r4,4*10(r11)   @ result2 := remainder
 @movl r0,r4         @ a := quotient
 @ret
 mov r0, #99
 mov r15, r14

    .ltorg

@ --------------------------------------------------------------------------------------------
@ 32-bit DIV and REM from 'ARM System Developer's Guide'
@ Copyright (c) 2003, Andrew N. Sloss, Dominic Symes, Chris Wright
@ All rights reserved.

d       .req r0                         @ input denominator d, output quotient
r       .req r1                         @ input numerator n, output remainder
t       .req r2                         @ scratch register
q       .req r3                         @ current quotient

@ --------------------------------------------------------------------------------------------
udiv:
        mov     q, #0                   @ zero quotient
        rsbs    t, d, r, lsr#3          @ if ((r>>3)>=d) C=1 else C=0
        bcc     div_3bits               @ quotient fits in 3 bits
        rsbs    t, d, r, lsr#8          @ if ((r>>8)>=d) C=1 else C=0
        bcc     div_8bits               @ quotient fits in 8 bits
        mov     d, d, lsl#8             @ d = d*256
        orr     q, q, #0xFF000000       @ make div_loop iterate twice
        rsbs    t, d, r, lsr#4          @ if ((r>>4)>=d) C=1 else C=0
        bcc     div_4bits               @ quotient fits in 12 bits
        rsbs    t, d, r, lsr#8          @ if ((r>>8)>=d) C=1 else C=0
        bcc     div_8bits               @ quotient fits in 16 bits
        mov     d, d, lsl#8             @ d = d*256
        orr     q, q, #0x00FF0000       @ make div_loop iterate 3 times
        rsbs    t, d, r, lsr#8          @ if ((r>>8)>=d)
        movcs   d, d, lsl#8             @ { d = d*256
        orrcs   q, q, #0x0000FF00       @ make div_loop iterate 4 times}
        rsbs    t, d, r, lsr#4          @ if ((r>>4)<d)
        bcc     div_4bits               @   r/d quotient fits in 4 bits
        rsbs    t, d, #0                @ if (0 >= d)
        bcs     div_by_0                @   goto divide by zero trap
                                        @ fall through to the loop with C=0
div_loop:
        movcs   d, d, lsr#8             @ if (next loop) d = d/256
div_8bits:                              @ calculate 8 quotient bits
        rsbs    t, d, r, lsr#7          @ if ((r>>7)>=d) C=1 else C=0
        subcs   r, r, d, lsl#7          @ if (C) r -= d<<7
        adc     q, q, q                 @ q=(q<<1)+C
        rsbs    t, d, r, lsr#6          @ if ((r>>6)>=d) C=1 else C=0
        subcs   r, r, d, lsl#6          @ if (C) r -= d<<6
        adc     q, q, q                 @ q=(q<<1)+C
        rsbs    t, d, r, lsr#5          @ if ((r>>5)>=d) C=1 else C=0
        subcs   r, r, d, lsl#5          @ if (C) r -= d<<5
        adc     q, q, q                 @ q=(q<<1)+C
        rsbs    t, d, r, lsr#4          @ if ((r>>4)>=d) C=1 else C=0
        subcs   r, r, d, lsl#4          @ if (C) r -= d<<4
        adc     q, q, q                 @ q=(q<<1)+C
div_4bits:                              @ calculate 4 quotient bits
        rsbs    t, d, r, lsr#3          @ if ((r>>3)>=d) C=1 else C=0
        subcs   r, r, d, lsl#3          @ if (C) r -= d<<3
        adc     q, q, q                 @ q=(q<<1)+C
div_3bits:                              @ calculate 3 quotient bits
        rsbs    t, d, r, lsr#2          @ if ((r>>2)>=d) C=1 else C=0
        subcs   r, r, d, lsl#2          @ if (C) r -= d<<2
        adc     q, q, q                 @ q=(q<<1)+C
        rsbs    t, d, r, lsr#1          @ if ((r>>1)>=d) C=1 else C=0
        subcs   r, r, d, lsl#1          @ if (C) r -= d<<1
        adc     q, q, q                 @ q=(q<<1)+C
        rsbs    t, d, r                 @ if (r>=d) C=1 else C=0
        subcs   r, r, d                 @ if (C) r -= d
        adcs    q, q, q                 @ q=(q<<1)+C; C=old q bit 31
div_next:
        bcs     div_loop                @ loop if more quotient bits
        mov     r0, q                   @ r0 = quotient; r1=remainder
        mov     pc, lr                  @ return { r0, r1 } structure
div_by_0:
        mov     r0, #-1
        mov     r1, #-1
        mov     pc, lr                  @ return { r0, r1 } structure
                
@ --------------------------------------------------------------------------------------------
divrem:
@ divrem(r0, r1)
@ On return r0 = r0  /  r1
@       and r1 = r0 mod r1
        stmfd   sp!, {ra,lr}
        ands    ra, d, #1<<31           @ ra=(d<0 ? 1<<31 : 0)
        rsbmi   d, d, #0                @ if (d<0) d=-d
        eors    ra, ra, r, asr#32       @ if (r<0) ra=~ra
        rsbcs   r, r, #0                @ if (r<0) r=-r
        bl      udiv                    @ (d,r)=(r/d,r%d)
        movs    ra, ra, lsl#1           @ C=ra[31], N=ra[30]
        rsbcs   d, d, #0                @ if (ra[31]) d=-d
        rsbmi   r, r, #0                @ if (ra[30]) r=-r
        ldmfd   sp!, {ra,pc}            @ return { r0, r1 } structure
       
	


   

