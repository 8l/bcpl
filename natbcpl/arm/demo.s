@ This test the ARM assembler
@ Use:   make demo.txt
	
@ Linkage:
@   On entry rl   is the return address
@            r0   is the first argument
@            r1   is the second argument
@            etc
@
@   r4 - r13 must be preserved
@
@   result in r0

.global callstart
.global dosys

ra .req r4
rb .req r5
rc .req r6
rp .req r10
rg .req r11

	
.text
.align 2

demo:
 mov R4,#63
 mov R4,#-63
 mov r4,r5
 mov r4,r5,rrx
 mov r4,r5,lsl #7
 mov r4,r5,lsr #7
 mov r4,r5,asr #7
 mov r4,r5,ror #7
 mov r4,r5,lsl r6
 mov r4,r5,lsr r6
 mov r4,r5,asr r6
 mov r4,r5,ror r6

 add r4,r5,#63
 adc r4,r5,#63
 sub r4,r5,#63
 rsb r4,r5,#63
 rsc r4,r5,#63
 and r4,r5,#63
 eor r4,r5,#63
 orr r4,r5,#63
 bic r4,r5,#63

 cmp r4,#63
 cmn r4,#63
 tst r4,#63
 teq r4,#63

 b demo
 bl demo
 bx r4
	
 ldmia r4,{r0-r2}
 ldmib r4,{r0-r2}
 ldmda r4,{r0-r2}
 ldmdb r4,{r0-r2}

 ldmia r4!,{r0-r2}
 ldmib r4!,{r0-r2}
 ldmda r4!,{r0-r2}
 ldmdb r4!,{r0-r2}

 stmia r4,{r0-r2}
 stmib r4,{r0-r2}
 stmda r4,{r0-r2}
 stmdb r4,{r0-r2}

 stmia r4!,{r0-r2}
 stmib r4!,{r0-r2}
 stmda r4!,{r0-r2}
 stmdb r4!,{r0-r2}

 ldr r4,[r5, #+63]
 ldr r4,[r5, #-63]
 ldr r4,[r5, +r6]
 ldr r4,[r5, -r6]
 ldr r4,[r5, +r6, rrx]
 ldr r4,[r5, -r6, rrx]
 ldr r4,[r5, +r6, lsl #7]
 ldr r4,[r5, -r6, lsl #7]
 ldr r4,[r5, +r6, lsr #7]
 ldr r4,[r5, -r6, lsr #7]
 ldr r4,[r5, +r6, asr #7]
 ldr r4,[r5, -r6, asr #7]
 ldr r4,[r5, +r6, ror #7]
 ldr r4,[r5, -r6, ror #7]

 ldrsh r4,[r5, #+127]
 ldrsh r4,[r5, #-127]
 ldrsh r4,[r5, #+127]!
 ldrsh r4,[r5], #+127
 ldrsh r4,[r5, +r6]
 ldrsh r4,[r5, -r6]
 ldrsh r4,[r5, +r6]!
 ldrsh r4,[r5], +r6
 ldrsh r4,[r5], -r6

 ldrsb r4,[r5, #+127]
 ldrsb r4,[r5, #-127]
 ldrh  r4,[r5, #+127]
 strh  r4,[r5, #+127]

 swp  r4,r5, [r6]
 swpb r4,r5, [r6]

 mul  r4,r5,r6
 mla  r4,r5,r6,r8

 smull  r4,r5,r6,r8
 smlal  r4,r5,r6,r8
 umull  r4,r5,r6,r8
 umlal  r4,r5,r6,r8

 swi    #63
	
