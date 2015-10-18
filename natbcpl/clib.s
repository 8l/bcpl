	.file	"clib.c"
	.data
	.align	2
	.type	parmp, %object
	.size	parmp, 4
parmp:
	.word	1
	.global	trcount
	.align	2
	.type	trcount, %object
	.size	trcount, 4
trcount:
	.word	-1
	.text
	.align	2
	.global	sysGraphics
	.type	sysGraphics, %function
sysGraphics:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	@ lr needed for prologue
	mov	r0, #0
	bx	lr
	.size	sysGraphics, .-sysGraphics
	.global	rootvarstr
	.bss
	.align	2
	.type	rootvarstr, %object
	.size	rootvarstr, 4
rootvarstr:
	.space	4
	.global	pathvarstr
	.align	2
	.type	pathvarstr, %object
	.size	pathvarstr, 4
pathvarstr:
	.space	4
	.global	hdrsvarstr
	.align	2
	.type	hdrsvarstr, %object
	.size	hdrsvarstr, 4
hdrsvarstr:
	.space	4
	.global	scriptsvarstr
	.align	2
	.type	scriptsvarstr, %object
	.size	scriptsvarstr, 4
scriptsvarstr:
	.space	4
	.global	prefixstr
	.align	2
	.type	prefixstr, %object
	.size	prefixstr, 4
prefixstr:
	.space	4
	.section	.rodata.str1.4,"aMS",%progbits,1
	.align	2
.LC0:
	.ascii	"BCPLROOT\000"
	.data
	.align	2
	.type	rootvar, %object
	.size	rootvar, 4
rootvar:
	.word	.LC0
	.section	.rodata.str1.4
	.align	2
.LC1:
	.ascii	"BCPLPATH\000"
	.data
	.align	2
	.type	pathvar, %object
	.size	pathvar, 4
pathvar:
	.word	.LC1
	.section	.rodata.str1.4
	.align	2
.LC2:
	.ascii	"BCPLHDRS\000"
	.data
	.align	2
	.type	hdrsvar, %object
	.size	hdrsvar, 4
hdrsvar:
	.word	.LC2
	.section	.rodata.str1.4
	.align	2
.LC3:
	.ascii	"BCPLSCRIPTS\000"
	.data
	.align	2
	.type	scriptsvar, %object
	.size	scriptsvar, 4
scriptsvar:
	.word	.LC3
	.global	tracing
	.bss
	.align	2
	.type	tracing, %object
	.size	tracing, 4
tracing:
	.space	4
	.global	filetracing
	.align	2
	.type	filetracing, %object
	.size	filetracing, 4
filetracing:
	.space	4
	.text
	.align	2
	.global	badimplementation
	.type	badimplementation, %function
badimplementation:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	@ lr needed for prologue
	mov	r0, #0
	bx	lr
	.size	badimplementation, .-badimplementation
	.align	2
	.global	initfpvec
	.type	initfpvec, %function
initfpvec:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	@ lr needed for prologue
	mov	r0, #0
	bx	lr
	.size	initfpvec, .-initfpvec
	.align	2
	.global	newfno
	.type	newfno, %function
newfno:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	@ lr needed for prologue
	bx	lr
	.size	newfno, .-newfno
	.align	2
	.global	freefno
	.type	freefno, %function
freefno:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	@ lr needed for prologue
	bx	lr
	.size	freefno, .-freefno
	.align	2
	.global	findfp
	.type	findfp, %function
findfp:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	@ lr needed for prologue
	bx	lr
	.size	findfp, .-findfp
	.section	.rodata.str1.4
	.align	2
.LC4:
	.ascii	"SIGINT received\000"
	.text
	.align	2
	.global	handler
	.type	handler, %function
handler:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	ldr	r0, .L15
	bl	puts
	ldr	r4, .L15+4
	mov	r0, #2
	ldr	r1, [r4, #0]
	bl	signal
	str	r0, [r4, #0]
	bl	close_keyb
	mov	r0, #20
	bl	exit
.L16:
	.align	2
.L15:
	.word	.LC4
	.word	old_handler
	.size	handler, .-handler
	.section	.rodata.str1.4
	.align	2
.LC5:
	.ascii	"This implementation of C is not suitable\000"
	.align	2
.LC6:
	.ascii	"Environment variable %s\000"
	.align	2
.LC7:
	.ascii	" = %s\012\000"
	.align	2
.LC8:
	.ascii	"unable to allocate space for globbase\000"
	.align	2
.LC9:
	.ascii	"unable to allocate space for stackbase\000"
	.align	2
.LC10:
	.ascii	"globbase[Gn_rootnode]=%d\012\000"
	.align	2
.LC11:
	.ascii	"clib: calling callstart(%d, %d)\012\000"
	.align	2
.LC12:
	.ascii	"\012G%3i:\000"
	.align	2
.LC13:
	.ascii	" %9d\000"
	.align	2
.LC14:
	.ascii	"\012Execution finished, return code %ld\012\000"
	.text
	.align	2
	.global	main
	.type	main, %function
main:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, fp, lr}
	mov	r6, r0
	mov	r7, r1
	ldr	r3, .L81
	mov	r1, #0
	ldr	r2, .L81+4
.L18:
	str	r1, [r3], #4
	cmp	r2, r3
	bne	.L18
	bl	badimplementation
	cmp	r0, #0
	beq	.L20
	ldr	r0, .L81+8
	bl	puts
	mov	r5, #20
	b	.L22
.L20:
	mov	r0, #1024
	bl	malloc
	ldr	r3, .L81+12
	str	r0, [r3, #0]
	mov	r3, #0
	strb	r3, [r0, #0]
	cmp	r6, #1
	movle	r5, r3
	ble	.L25
	mov	r8, #1
	mov	r5, #0
.L26:
	ldr	r4, [r7, r8, asl #2]
	mov	r0, r4
	bl	strlen
	subs	ip, r0, #0
	movle	r0, #0
	ble	.L29
	mov	r0, #0
	mov	r2, r0
.L30:
	ldrb	r3, [r4, r2]	@ zero_extendqisi2
	cmp	r3, #32
	cmpne	r3, #34
	beq	.L31
	cmp	r3, #10
	bne	.L33
.L31:
	mov	r0, #1
.L33:
	add	r2, r2, #1
	cmp	ip, r2
	bne	.L30
.L29:
	add	r1, r5, #1
	ldr	lr, .L81+12
	ldr	r2, [lr, #0]
	mov	r3, #32
	strb	r3, [r1, r2]
	cmp	r0, #0
	beq	.L34
	add	r0, r5, #2
	ldr	r2, [lr, #0]
	add	r3, r3, #2
	strb	r3, [r0, r2]
	cmp	ip, #0
	ble	.L36
	mov	lr, #0
	ldr	r5, .L81+12
	mov	sl, #42
.L38:
	ldrb	r1, [r4, lr]	@ zero_extendqisi2
	cmp	r1, #10
	bne	.L39
	ldr	r3, [r5, #0]
	strb	sl, [r0, r3]
	add	r0, r0, #2
	ldr	r2, [r5, #0]
	mov	r3, #110
	strb	r3, [r0, r2]
	b	.L41
.L39:
	cmp	r1, #34
	bne	.L41
	ldr	r3, [r5, #0]
	strb	sl, [r0, r3]
	add	r0, r0, #2
	ldr	r3, [r5, #0]
	strb	r1, [r0, r3]
	b	.L43
.L41:
	add	r0, r0, #1
	ldr	r3, [r5, #0]
	strb	r1, [r0, r3]
.L43:
	add	lr, lr, #1
	cmp	ip, lr
	bne	.L38
.L36:
	add	r5, r0, #1
	ldr	r3, .L81+12
	ldr	r2, [r3, #0]
	mov	r3, #34
	strb	r3, [r5, r2]
	b	.L44
.L45:
	mov	r5, r1
	mov	r1, #0
	ldr	r0, .L81+12
.L46:
	add	r5, r5, #1
	ldr	r2, [r0, #0]
	ldrb	r3, [r4, r1]	@ zero_extendqisi2
	strb	r3, [r2, r5]
	add	r1, r1, #1
	cmp	ip, r1
	bne	.L46
.L44:
	add	r8, r8, #1
	cmp	r6, r8
	bne	.L26
.L25:
	add	r0, r5, #1
	ldr	r1, .L81+12
	ldr	r2, [r1, #0]
	mov	r3, #10
	strb	r3, [r0, r2]
	ldr	r3, [r1, #0]
	strb	r0, [r3, #0]
	mov	r2, #1
	ldr	r3, .L81+16
	str	r2, [r3, #0]
	mov	r0, #2
	ldr	r1, .L81+20
	bl	signal
	ldr	r3, .L81+24
	str	r0, [r3, #0]
	mov	r0, #320
	bl	malloc
	mov	r0, r0, asr #2
	ldr	r3, .L81+28
	str	r0, [r3, #0]
	add	r2, r0, #16
	ldr	r3, .L81+32
	str	r2, [r3, #0]
	add	r2, r0, #32
	ldr	r3, .L81+36
	str	r2, [r3, #0]
	add	r2, r0, #48
	ldr	r3, .L81+40
	str	r2, [r3, #0]
	add	r0, r0, #64
	ldr	r3, .L81+44
	str	r0, [r3, #0]
	mov	r0, r0, asl #2
	ldr	r3, .L81+48
	str	r0, [r3, #0]
	mov	r2, #0
	ldr	r7, .L81+28
	mov	r1, r2
.L47:
	ldr	r3, [r7, #0]
	mov	r3, r3, asl #2
	str	r1, [r3, r2]
	add	r2, r2, #4
	cmp	r2, #324
	bne	.L47
	ldr	r8, .L81+52
	ldr	r0, [r8, #0]
	ldr	r1, [r7, #0]
	bl	c2b_str
	ldr	sl, .L81+56
	ldr	r6, .L81+32
	ldr	r0, [sl, #0]
	ldr	r1, [r6, #0]
	bl	c2b_str
	ldr	r9, .L81+60
	ldr	r4, .L81+36
	ldr	r0, [r9, #0]
	ldr	r1, [r4, #0]
	bl	c2b_str
	ldr	fp, .L81+64
	ldr	r5, .L81+40
	ldr	r0, [fp, #0]
	ldr	r1, [r5, #0]
	bl	c2b_str
	ldr	r2, .L81
	ldr	r3, [r7, #0]
	str	r3, [r2, #140]
	ldr	r3, [r6, #0]
	str	r3, [r2, #144]
	ldr	r3, [r4, #0]
	str	r3, [r2, #148]
	ldr	r3, [r5, #0]
	str	r3, [r2, #152]
	ldr	r3, .L81+68
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L49
	ldr	r0, [r8, #0]
	bl	getenv
	mov	r4, r0
	ldr	r5, .L81+72
	mov	r0, r5
	ldr	r1, [r8, #0]
	bl	printf
	ldr	r6, .L81+76
	mov	r0, r6
	mov	r1, r4
	bl	printf
	ldr	r0, [sl, #0]
	bl	getenv
	mov	r4, r0
	mov	r0, r5
	ldr	r1, [sl, #0]
	bl	printf
	mov	r0, r6
	mov	r1, r4
	bl	printf
	ldr	r0, [r9, #0]
	bl	getenv
	mov	r4, r0
	mov	r0, r5
	ldr	r1, [r9, #0]
	bl	printf
	mov	r0, r6
	mov	r1, r4
	bl	printf
	ldr	r0, [fp, #0]
	bl	getenv
	mov	r4, r0
	mov	r0, r5
	ldr	r1, [fp, #0]
	bl	printf
	mov	r0, r6
	mov	r1, r4
	bl	printf
.L49:
	ldr	r3, .L81+80
	ldr	r0, [r3, #0]
	add	r0, r0, #1
	mov	r1, #4
	bl	calloc
	ldr	r3, .L81+84
	str	r0, [r3, #0]
	cmp	r0, #0
	bne	.L51
	ldr	r0, .L81+88
	bl	puts
	mov	r0, #20
	bl	exit
.L51:
	ldr	r3, .L81+92
	ldr	r0, [r3, #0]
	add	r0, r0, #1
	mov	r1, #4
	bl	calloc
	ldr	r3, .L81+96
	str	r0, [r3, #0]
	cmp	r0, #0
	bne	.L53
	ldr	r0, .L81+100
	bl	puts
	mov	r0, #20
	bl	exit
.L53:
	ldr	r3, .L81+84
	ldr	r1, [r3, #0]
	ldr	r2, .L81+80
	ldr	r3, [r2, #0]
	str	r3, [r1, #0]
	ldr	r3, [r2, #0]
	cmp	r3, #0
	ble	.L55
	mov	r1, #1
	ldr	r0, .L81+84
	ldr	ip, .L81+104
	mov	lr, r2
.L57:
	ldr	r3, [r0, #0]
	add	r2, r1, ip
	str	r2, [r3, r1, asl #2]
	add	r1, r1, #1
	ldr	r3, [lr, #0]
	cmp	r1, r3
	ble	.L57
.L55:
	ldr	r3, .L81+84
	ldr	r2, [r3, #0]
	ldr	r3, .L81
	mov	r3, r3, asr #2
	str	r3, [r2, #36]
	ldr	r3, .L81+92
	ldr	r3, [r3, #0]
	cmp	r3, #0
	blt	.L58
	mov	r2, #0
	ldr	r1, .L81+96
	mov	r0, r2
	ldr	ip, .L81+92
.L60:
	ldr	r3, [r1, #0]
	str	r0, [r3, r2, asl #2]
	add	r2, r2, #1
	ldr	r3, [ip, #0]
	cmp	r2, r3
	ble	.L60
.L58:
	ldr	r4, .L81+84
	ldr	r0, [r4, #0]
	bl	initsections
	bl	init_keyb
	ldr	r3, .L81+108
	str	r0, [r3, #0]
	ldr	r3, [r4, #0]
	ldr	r0, .L81+112
	ldr	r1, [r3, #36]
	bl	printf
	ldr	r5, .L81+96
	ldr	r0, .L81+116
	ldr	r1, [r5, #0]
	ldr	r2, [r4, #0]
	bl	printf
	ldr	r0, [r5, #0]
	ldr	r1, [r4, #0]
	bl	callstart
	mov	r5, r0
	bl	close_keyb
	mov	r4, #0
	ldr	r6, .L81+84
.L61:
	ldr	r3, .L81+120
	smull	r1, r2, r3, r4
	mov	r3, r4, asr #31
	rsb	r3, r3, r2, asr #1
	add	r3, r3, r3, asl #2
	cmp	r4, r3
	bne	.L62
	ldr	r3, [r6, #0]
	ldr	r0, .L81+124
	mov	r1, r4
	ldr	r2, [r3, r4, asl #2]
	bl	printf
.L62:
	ldr	r3, [r6, #0]
	ldr	r0, .L81+128
	ldr	r1, [r3, r4, asl #2]
	bl	printf
	add	r4, r4, #1
	cmp	r4, #20
	bne	.L61
	mov	r0, #10
	bl	putchar
	cmp	r5, #0
	ldrne	r0, .L81+132
	movne	r1, r5
	blne	printf
.L65:
	ldr	r3, .L81+84
	ldr	r0, [r3, #0]
	bl	free
	ldr	r3, .L81+96
	ldr	r0, [r3, #0]
	bl	free
	ldr	r3, .L81+12
	ldr	r0, [r3, #0]
	bl	free
	b	.L22
.L34:
	cmp	ip, #0
	movle	r5, r1
	ble	.L44
	b	.L45
.L22:
	mov	r0, r5
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, fp, pc}
.L82:
	.align	2
.L81:
	.word	rootnode
	.word	rootnode+204
	.word	.LC5
	.word	parms
	.word	parmp
	.word	handler
	.word	old_handler
	.word	rootvarstr
	.word	pathvarstr
	.word	hdrsvarstr
	.word	scriptsvarstr
	.word	prefixstr
	.word	prefixbp
	.word	rootvar
	.word	pathvar
	.word	hdrsvar
	.word	scriptsvar
	.word	filetracing
	.word	.LC6
	.word	.LC7
	.word	gvecupb
	.word	globbase
	.word	.LC8
	.word	stackupb
	.word	stackbase
	.word	.LC9
	.word	-1886453760
	.word	ttyinp
	.word	.LC10
	.word	.LC11
	.word	1717986919
	.word	.LC12
	.word	.LC13
	.word	.LC14
	.size	main, .-main
	.global	__moddi3
	.global	__divdi3
	.align	2
	.type	muldiv, %function
muldiv:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, lr}
	smull	r4, r5, r0, r1
	cmp	r2, #0
	movne	r6, r2
	moveq	r6, #1
	mov	r7, r6, asr #31
	mov	r0, r4
	mov	r1, r5
	mov	r2, r6
	mov	r3, r7
	bl	__moddi3
	ldr	r3, .L87
	str	r0, [r3, #0]
	mov	r0, r4
	mov	r1, r5
	mov	r2, r6
	mov	r3, r7
	bl	__divdi3
	ldmfd	sp!, {r4, r5, r6, r7, pc}
.L88:
	.align	2
.L87:
	.word	result2
	.size	muldiv, .-muldiv
	.global	__udivsi3
	.global	__umodsi3
	.align	2
	.global	muldiv1
	.type	muldiv1, %function
muldiv1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, sl, lr}
	cmp	r2, #0
	movne	r3, r2
	moveq	r3, #1
	cmp	r0, #0
	rsblt	r5, r0, #0
	movlt	r8, #1
	movlt	sl, r8
	movge	r5, r0
	movge	r8, #0
	movge	sl, r8
	cmp	r1, #0
	eorlt	r8, r8, #1
	eorlt	sl, sl, #1
	rsblt	r7, r1, #0
	movge	r7, r1
	cmp	r3, #0
	eorlt	r8, r8, #1
	rsblt	r4, r3, #0
	movge	r4, r3
	mov	r0, r7
	mov	r1, r4
	bl	__udivsi3
	mov	r6, r0
	mov	r0, r7
	mov	r1, r4
	bl	__umodsi3
	cmp	r5, #0
	moveq	r1, r5
	moveq	r3, r1
	beq	.L103
	mov	r1, #0
	mov	r3, r1
.L104:
	tst	r5, #1
	beq	.L105
	add	r1, r1, r6
	add	r3, r3, r0
	cmp	r4, r3
	addls	r1, r1, #1
	rsbls	r3, r4, r3
.L105:
	mov	r5, r5, lsr #1
	mov	r6, r6, asl #1
	mov	r0, r0, asl #1
	cmp	r4, r0
	addls	r6, r6, #1
	rsbls	r0, r4, r0
	cmp	r5, #0
	bne	.L104
.L103:
	cmp	sl, #0
	rsbne	r2, r3, #0
	moveq	r2, r3
	ldr	r3, .L118
	str	r2, [r3, #0]
	cmp	r8, #0
	rsbne	r0, r1, #0
	moveq	r0, r1
	ldmfd	sp!, {r4, r5, r6, r7, r8, sl, pc}
.L119:
	.align	2
.L118:
	.word	result2
	.size	muldiv1, .-muldiv1
	.align	2
	.global	relfilename
	.type	relfilename, %function
relfilename:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	@ lr needed for prologue
	ldrb	r3, [r0, #0]	@ zero_extendqisi2
	cmp	r3, #92
	cmpne	r3, #47
	bne	.L127
	b	.L121
.L123:
	add	r0, r0, #1
	cmp	r3, #58
	beq	.L121
.L127:
	ldrb	r3, [r0, #0]	@ zero_extendqisi2
	cmp	r3, #0
	bne	.L123
	mov	r0, #1
	bx	lr
.L121:
	mov	r0, #0
	bx	lr
	.size	relfilename, .-relfilename
	.section	.rodata.str1.4
	.align	2
.LC15:
	.ascii	"rb\000"
	.align	2
.LC16:
	.ascii	"Trying: %s in the current directory - \000"
	.align	2
.LC17:
	.ascii	"found\000"
	.align	2
.LC18:
	.ascii	"not found\000"
	.align	2
.LC19:
	.ascii	"pathinput: attempting to open %s\000"
	.align	2
.LC20:
	.ascii	" using\012  %s\000"
	.align	2
.LC21:
	.ascii	"Trying: %s - \000"
	.text
	.align	2
	.global	pathinput
	.type	pathinput, %function
pathinput:
	@ args = 0, pretend = 0, frame = 256
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, lr}
	sub	sp, sp, #256
	mov	r7, r0
	subs	r5, r1, #0
	beq	.L129
	bl	relfilename
	cmp	r0, #0
	bne	.L131
.L129:
	mov	r0, r7
	ldr	r1, .L182
	bl	osfname
	ldr	r1, .L182+4
	bl	fopen
	mov	r5, r0
	ldr	r3, .L182+8
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L132
	ldr	r0, .L182+12
	mov	r1, r7
	bl	printf
	cmp	r5, #0
	beq	.L134
	ldr	r0, .L182+16
	bl	puts
	b	.L132
.L134:
	ldr	r0, .L182+20
	bl	puts
	b	.L132
.L171:
	ldr	r0, .L182+16
	bl	puts
	b	.L132
.L172:
	ldr	r0, .L182+16
	bl	puts
	b	.L132
.L131:
	mov	r0, r5
	bl	getenv
	mov	r4, r0
	ldr	r3, .L182+8
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L136
	ldr	r0, .L182+24
	mov	r1, r7
	bl	printf
	ldr	r0, .L182+28
	mov	r1, r5
	bl	printf
	ldr	r0, .L182+32
	mov	r1, r4
	bl	printf
.L136:
	cmp	r4, #0
	beq	.L138
.L181:
	ldrb	r3, [r4, #0]	@ zero_extendqisi2
	cmp	r3, #59
	addeq	r4, r4, #1
	beq	.L181
	cmp	r3, #58
	addeq	r4, r4, #1
	beq	.L181
	cmp	r3, #0
	bne	.L178
	b	.L138
.L145:
	add	r4, r4, #1
	cmp	r3, #59
	beq	.L146
	add	r2, r2, #1
	cmp	r3, #58
	beq	.L146
	mov	r0, r3
.L149:
	mov	r1, r2
	strb	r0, [r2, #-1]
	ldrb	r3, [r4, #0]	@ zero_extendqisi2
	cmp	r3, #0
	bne	.L145
.L146:
	mov	r3, r0
.L150:
	cmp	r3, #47
	cmpne	r3, #92
	movne	r3, #47
	strneb	r3, [r1], #1
	mov	r2, r7
.L153:
	ldrb	r3, [r2], #1	@ zero_extendqisi2
	strb	r3, [r1], #1
	cmp	r3, #0
	bne	.L153
	mov	r6, sp
	mov	r0, sp
	ldr	r1, .L182
	bl	osfname
	ldr	r1, .L182+4
	bl	fopen
	mov	r5, r0
	ldr	r3, .L182+8
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L155
	ldr	r0, .L182+36
	mov	r1, sp
	bl	printf
	cmp	r5, #0
	bne	.L171
	ldr	r0, .L182+20
	bl	puts
	b	.L159
.L155:
	cmp	r0, #0
	bne	.L132
.L159:
	cmp	r4, #0
	bne	.L181
.L138:
	mov	r0, r7
	ldr	r1, .L182
	bl	osfname
	ldr	r1, .L182+4
	bl	fopen
	mov	r5, r0
	ldr	r3, .L182+8
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L132
	ldr	r0, .L182+12
	mov	r1, r7
	bl	printf
	cmp	r5, #0
	bne	.L172
	ldr	r0, .L182+20
	bl	puts
	b	.L132
.L178:
	ldrb	r0, [r4, #0]	@ zero_extendqisi2
	cmp	r0, #0
	moveq	r1, sp
	moveq	r3, r0
	beq	.L150
	add	r4, r4, #1
	cmp	r0, #59
	moveq	r1, sp
	moveq	r3, #0
	beq	.L150
	cmp	r0, #58
	moveq	r1, sp
	moveq	r3, #0
	addne	r2, sp, #1
	bne	.L149
	b	.L150
.L132:
	mov	r0, r5
	add	sp, sp, #256
	ldmfd	sp!, {r4, r5, r6, r7, pc}
.L183:
	.align	2
.L182:
	.word	chbuf4
	.word	.LC15
	.word	filetracing
	.word	.LC16
	.word	.LC17
	.word	.LC18
	.word	.LC19
	.word	.LC20
	.word	.LC7
	.word	.LC21
	.size	pathinput, .-pathinput
	.section	.rodata.str1.4
	.align	2
.LC22:
	.ascii	"\012Bad sys %ld\012\000"
	.align	2
.LC23:
	.ascii	"wb\000"
	.align	2
.LC24:
	.ascii	"ab\000"
	.align	2
.LC25:
	.ascii	"rb+\000"
	.align	2
.LC26:
	.ascii	"wb+\000"
	.align	2
.LC27:
	.ascii	"\012Cintpos memory not dumped to DUMP.mem\000"
	.text
	.align	2
	.global	dosys
	.type	dosys, %function
dosys:
	@ args = 0, pretend = 0, frame = 260
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, lr}
	sub	sp, sp, #260
	mov	r6, r0
	add	r5, r0, #12
	ldr	r1, [r0, #12]
	sub	r3, r1, #4
	cmp	r3, #133
	ldrls	pc, [pc, r3, asl #2]
	b	.L185
	.p2align 2
.L222:
	.word	.L186
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L187
	.word	.L188
	.word	.L189
	.word	.L190
	.word	.L191
	.word	.L192
	.word	.L193
	.word	.L194
	.word	.L195
	.word	.L196
	.word	.L185
	.word	.L197
	.word	.L198
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L199
	.word	.L185
	.word	.L200
	.word	.L185
	.word	.L201
	.word	.L202
	.word	.L203
	.word	.L204
	.word	.L205
	.word	.L206
	.word	.L207
	.word	.L207
	.word	.L208
	.word	.L209
	.word	.L207
	.word	.L207
	.word	.L207
	.word	.L207
	.word	.L210
	.word	.L185
	.word	.L211
	.word	.L212
	.word	.L213
	.word	.L214
	.word	.L215
	.word	.L216
	.word	.L217
	.word	.L218
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L185
	.word	.L219
	.word	.L220
	.word	.L221
.L185:
	ldr	r0, .L252
	bl	printf
	ldr	r5, [r5, #0]
	b	.L223
.L186:
	ldr	r2, [r0, #16]
	ldr	r3, .L252+4
	str	r2, [r3, #0]
	mov	r5, #0
	b	.L223
.L187:
	ldr	r3, .L252+8
	ldr	r0, [r3, #0]
	ldr	r2, .L252+12
	ldr	r1, [r2, #0]
	ldrb	r3, [r0, #0]	@ zero_extendqisi2
	cmp	r3, r1
	ldrgeb	r5, [r0, r1]	@ zero_extendqisi2
	addge	r3, r1, #1
	strge	r3, [r2, #0]
	bge	.L223
.L224:
	bl	Readch
	mov	r5, r0
	ldr	r3, .L252+16
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L223
	cmp	r0, #0
	andge	r0, r0, #255
	ldrge	r3, .L252+20
	ldrge	r1, [r3, #0]
	blge	_IO_putc
.L227:
	cmp	r5, #13
	bne	.L229
	mov	r0, #10
	ldr	r3, .L252+20
	ldr	r1, [r3, #0]
	bl	_IO_putc
	sub	r5, r5, #3
.L229:
	ldr	r3, .L252+20
	ldr	r0, [r3, #0]
	bl	fflush
	b	.L223
.L188:
	add	r5, r0, #16
	ldr	r3, [r0, #16]
	cmp	r3, #10
	moveq	r0, #13
	ldreq	r3, .L252+20
	ldreq	r1, [r3, #0]
	bleq	_IO_putc
.L231:
	ldr	r4, .L252+20
	ldrb	r0, [r5, #0]	@ zero_extendqisi2
	ldr	r1, [r4, #0]
	bl	_IO_putc
	ldr	r0, [r4, #0]
	bl	fflush
	mov	r5, #0
	b	.L223
.L189:
	ldr	r4, [r0, #20]
	mov	r4, r4, asl #2
	ldr	r5, [r0, #24]
	ldr	r0, [r0, #16]
	bl	findfp
	mov	r3, r0
	mov	r0, r4
	mov	r1, #1
	mov	r2, r5
	bl	fread
	mov	r5, r0
	b	.L223
.L190:
	ldr	r0, [r0, #16]
	bl	findfp
	mov	r4, r0
	ldr	r0, [r6, #20]
	mov	r0, r0, asl #2
	mov	r1, #1
	ldr	r2, [r6, #24]
	mov	r3, r4
	bl	fwrite
	mov	r5, r0
	mov	r0, r4
	bl	fflush
	b	.L223
.L191:
	ldr	r0, [r0, #16]
	ldr	r1, .L252+24
	bl	b2c_str
	mov	r4, r0
	ldr	r0, [r6, #20]
	ldr	r1, .L252+28
	bl	b2c_str
	mov	r1, r0
	mov	r0, r4
	bl	pathinput
	cmp	r0, #0
	beq	.L207
	bl	newfno
	mov	r5, r0
	b	.L223
.L192:
	ldr	r0, [r0, #16]
	ldr	r1, .L252+24
	bl	b2c_str
	ldr	r1, .L252+32
	bl	osfname
	ldr	r1, .L252+36
	bl	fopen
	cmp	r0, #0
	beq	.L207
	bl	newfno
	mov	r5, r0
	b	.L223
.L196:
	ldr	r0, [r0, #16]
	ldr	r1, .L252+24
	bl	b2c_str
	ldr	r1, .L252+32
	bl	osfname
	ldr	r1, .L252+40
	bl	fopen
	cmp	r0, #0
	beq	.L207
	bl	newfno
	mov	r5, r0
	b	.L223
.L212:
	ldr	r0, [r0, #16]
	ldr	r1, .L252+24
	bl	b2c_str
	mov	r4, r0
	ldr	r1, .L252+32
	bl	osfname
	ldr	r1, .L252+44
	bl	fopen
	cmp	r0, #0
	bne	.L236
	mov	r0, r4
	ldr	r1, .L252+48
	bl	fopen
	cmp	r0, #0
	beq	.L207
.L236:
	bl	newfno
	mov	r5, r0
	b	.L223
.L193:
	ldr	r0, [r0, #16]
	bl	findfp
	bl	fclose
	cmp	r0, #0
	bne	.L207
	b	.L206
.L194:
	ldr	r0, [r0, #16]
	ldr	r1, .L252+24
	bl	b2c_str
	ldr	r1, .L252+32
	bl	osfname
	bl	unlink
	rsbs	r5, r0, #1
	movcc	r5, #0
	b	.L223
.L195:
	ldr	r0, [r0, #16]
	ldr	r1, .L252+24
	bl	b2c_str
	mov	r4, r0
	ldr	r0, [r6, #20]
	ldr	r1, .L252+28
	bl	b2c_str
	mov	r5, r0
	mov	r0, r4
	ldr	r1, .L252+52
	bl	osfname
	mov	r6, r0
	mov	r0, r5
	ldr	r1, .L252+32
	bl	osfname
	mov	r4, r0
	bl	unlink
	mov	r0, r6
	mov	r1, r4
	bl	rename
	rsbs	r5, r0, #1
	movcc	r5, #0
	b	.L223
.L197:
	ldr	r0, [r0, #16]
	add	r0, r0, #1
	mov	r0, r0, asl #2
	bl	malloc
	mov	r5, r0, asr #2
	b	.L223
.L198:
	ldr	r0, [r0, #16]
	mov	r0, r0, asl #2
	bl	free
	mvn	r5, #0
	b	.L223
.L199:
	ldr	r0, [r0, #16]
	ldr	r1, [r6, #20]
	ldr	r2, [r6, #24]
	bl	muldiv
	ldr	r3, .L252+56
	ldr	r2, [r3, #0]
	ldr	r3, .L252+60
	ldr	r3, [r3, #0]
	str	r3, [r2, #40]
	mov	r5, r0
	b	.L223
.L200:
	bl	intflag
	cmp	r0, #0
	beq	.L207
	b	.L206
.L201:
	bl	clock
	mov	r1, #1000
	ldr	r2, .L252+64
	bl	muldiv
	mov	r5, r0
	b	.L223
.L202:
	ldr	r0, [r0, #16]
	ldr	r1, .L252+24
	bl	b2c_str
	ldr	r3, [r6, #20]
	mov	r4, r3, asl #2
	ldr	r1, .L252+32
	bl	osfname
	mov	r1, r0
	mov	r0, #3
	mov	r2, sp
	bl	__xstat
	cmp	r0, #0
	beq	.L238
	mov	r2, #0
	str	r2, [r4, #0]
	str	r2, [r4, #4]
	mvn	r3, #0
	str	r3, [r4, #8]
	mov	r5, r2
	b	.L223
.L238:
	ldr	r2, [sp, #64]
	ldr	r3, .L252+68
	smull	r0, r1, r3, r2
	add	r1, r1, r2
	mov	r3, r2, asr #31
	rsb	r3, r3, r1, asr #16
	str	r3, [r4, #0]
	add	r3, r3, r3, asl #1
	rsb	r3, r3, r3, asl #4
	rsb	r3, r3, r3, asl #4
	sub	r2, r2, r3, asl #7
	rsb	r3, r2, r2, asl #5
	add	r2, r2, r3, asl #2
	mov	r2, r2, asl #3
	str	r2, [r4, #4]
	mvn	r3, #0
	str	r3, [r4, #8]
	mov	r5, r3
	b	.L223
.L203:
	ldr	r3, [r0, #16]
	mov	r0, r3, asl #2
	ldr	r3, .L252+72
	ldr	r1, [r3, #0]
	ldrb	r3, [r0, #0]	@ zero_extendqisi2
	cmp	r3, #63
	bgt	.L207
	mov	r2, #0
	add	ip, r3, #1
.L242:
	ldrb	r3, [r0], #1	@ zero_extendqisi2
	strb	r3, [r1], #1
	add	r2, r2, #1
	cmp	ip, r2
	bne	.L242
	ldr	r3, .L252+76
	ldr	r5, [r3, #0]
	b	.L223
.L204:
	ldr	r3, .L252+76
	ldr	r5, [r3, #0]
	b	.L223
.L205:
	bl	sysGraphics
	mov	r5, r0
	b	.L223
.L208:
	ldr	r0, [r0, #16]
	bl	findfp
	ldr	r1, [r6, #20]
	mov	r2, #0
	bl	fseek
	cmp	r0, #0
	bne	.L207
	b	.L206
.L209:
	ldr	r0, [r0, #16]
	bl	findfp
	bl	ftell
	mov	r5, r0
	b	.L223
.L210:
	ldr	r0, [r0, #16]
	bl	timestamp
	mov	r5, r0
	b	.L223
.L211:
	ldr	r0, [r0, #16]
	bl	findfp
	mov	r4, r0
	bl	ftell
	mov	r5, r0
	mov	r0, r4
	mov	r1, #0
	mov	r2, #2
	bl	fseek
	mov	r0, r4
	bl	ftell
	mov	r6, r0
	mov	r0, r4
	mov	r1, r5
	mov	r2, #0
	bl	fseek
	cmp	r0, #0
	moveq	r5, r6
	beq	.L223
	b	.L206
.L213:
	ldr	r3, [r0, #16]
	ldr	r5, [r3, #0]
	b	.L223
.L214:
	ldr	r2, [r0, #16]
	ldr	r3, [r0, #20]
	str	r3, [r2, #0]
	mov	r5, #0
	b	.L223
.L215:
	ldr	r3, [r0, #16]
	mov	r4, r3, asl #2
	mov	r0, r4
	bl	strlen
	cmp	r0, #0
	ble	.L245
	mov	r2, #0
	mov	r1, #1
	mov	ip, sp
.L247:
	ldrb	r3, [r1, r4]	@ zero_extendqisi2
	strb	r3, [r2, ip]
	add	r2, r2, #1
	add	r1, r1, #1
	cmp	r0, r2
	bne	.L247
.L245:
	add	r3, sp, #260
	add	r2, r3, r0
	mov	r3, #0
	strb	r3, [r2, #-260]
	mov	r0, sp
	bl	system
	mov	r5, r0
	b	.L223
.L216:
	bl	getpid
	mov	r5, r0
	b	.L223
.L217:
	ldr	r0, .L252+80
	bl	puts
	mov	r5, #0
	b	.L223
.L218:
	add	r3, r0, #16
	mov	lr, pc
	bx	r3
	mov	r5, r0
	b	.L223
.L219:
	mov	r0, #0
	bl	time
	add	r3, sp, #260
	str	r0, [r3, #-4]!
	mov	r0, r3
	bl	gmtime
	ldr	r2, [r6, #16]
	mov	r2, r2, asl #2
	ldr	r3, [r0, #20]
	add	r3, r3, #1888
	add	r3, r3, #12
	str	r3, [r2, #0]
	ldr	r3, [r0, #16]
	add	r3, r3, #1
	str	r3, [r2, #4]
	ldr	r3, [r0, #12]
	str	r3, [r2, #8]
	ldr	r3, [r0, #8]
	str	r3, [r2, #12]
	ldr	r3, [r0, #4]
	str	r3, [r2, #16]
	ldr	r3, [r0, #0]
	str	r3, [r2, #20]
	mov	r5, #0
	b	.L223
.L220:
	ldr	r4, .L252+24
	mov	r0, r4
	mov	r1, #256
	bl	getcwd
	mov	r0, r4
	ldr	r1, [r6, #16]
	bl	c2b_str
	mov	r5, #0
	b	.L223
.L221:
	ldr	r3, .L252+8
	ldr	r3, [r3, #0]
	mov	r5, r3, asr #2
	b	.L223
.L207:
	mov	r5, #0
	b	.L223
.L206:
	mvn	r5, #0
.L223:
	mov	r0, r5
	add	sp, sp, #260
	ldmfd	sp!, {r4, r5, r6, pc}
.L253:
	.align	2
.L252:
	.word	.LC22
	.word	tracing
	.word	parms
	.word	parmp
	.word	ttyinp
	.word	stdout
	.word	chbuf1
	.word	chbuf2
	.word	chbuf4
	.word	.LC23
	.word	.LC24
	.word	.LC25
	.word	.LC26
	.word	chbuf3
	.word	globbase
	.word	result2
	.word	1000000
	.word	-1037155065
	.word	prefixbp
	.word	prefixstr
	.word	.LC27
	.size	dosys, .-dosys
	.align	2
	.global	msecdelay
	.type	msecdelay, %function
msecdelay:
	@ args = 0, pretend = 0, frame = 20
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, lr}
	sub	sp, sp, #24
	mov	r4, r0
	add	r0, sp, #4
	bl	timestamp
	ldr	r5, [sp, #4]
	ldr	r3, [sp, #8]
	add	r4, r4, r3
	ldr	r3, .L265
	cmp	r4, r3
	addgt	r5, r5, #1
	addgt	r4, r4, #-100663296
	addgt	r4, r4, #14221312
	addgt	r4, r4, #41984
.L264:
	add	r0, sp, #4
	bl	timestamp
	ldr	r3, [sp, #8]
	rsb	r1, r3, r4
	ldr	r3, [sp, #4]
	rsb	r3, r3, r5
	cmp	r3, #0
	addgt	r1, r1, #85983232
	addgt	r1, r1, #413696
	addgt	r1, r1, #3072
	cmp	r1, #0
	ble	.L263
	cmp	r1, #900
	movge	r1, #900
	mov	r3, #0
	str	r3, [sp, #16]
	rsb	r2, r1, r1, asl #5
	add	r2, r1, r2, asl #2
	mov	r2, r2, asl #3
	str	r2, [sp, #20]
	add	r2, sp, #16
	str	r2, [sp, #0]
	mov	r0, #1024
	mov	r1, r3
	mov	r2, r3
	bl	select
	b	.L264
.L263:
	add	sp, sp, #24
	ldmfd	sp!, {r4, r5, pc}
.L266:
	.align	2
.L265:
	.word	86399999
	.size	msecdelay, .-msecdelay
	.align	2
	.global	doflt
	.type	doflt, %function
doflt:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	@ lr needed for prologue
	mov	r0, #0
	bx	lr
	.size	doflt, .-doflt
	.align	2
	.global	timestamp
	.type	timestamp, %function
timestamp:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, lr}
	sub	sp, sp, #8
	mov	sl, r0
	mov	r0, sp
	mov	r1, #0
	bl	gettimeofday
	ldr	r3, [sp, #0]
	mov	r4, r3, asr #31
	mov	r1, #3600
	mov	r2, #0
	adds	r1, r1, r3
	adc	r2, r2, r4
	ldr	r3, .L271
	ldr	r3, [r3, #132]
	rsb	r3, r3, r3, asl #4
	mov	r3, r3, asl #2
	mov	r4, r3, asr #31
	adds	r6, r1, r3
	adc	r7, r2, r4
	ldr	r8, .L271+4
	mov	r9, #0
	mov	r0, r6
	mov	r1, r7
	mov	r2, r8
	mov	r3, r9
	bl	__moddi3
	mov	r2, #1000
	umull	r3, r4, r0, r2
	mla	r4, r1, r2, r4
	ldr	r5, [sp, #4]
	ldr	r2, .L271+8
	smull	r1, r2, r5, r2
	mov	r5, r5, asr #31
	rsb	r5, r5, r2, asr #6
	add	r5, r5, r3
	mov	r0, r6
	mov	r1, r7
	mov	r2, r8
	mov	r3, r9
	bl	__divdi3
	stmia	sl, {r0, r5}	@ phole stm
	mvn	r0, #0
	str	r0, [sl, #8]
	add	sp, sp, #8
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, pc}
.L272:
	.align	2
.L271:
	.word	rootnode
	.word	86400
	.word	274877907
	.size	timestamp, .-timestamp
	.align	2
	.type	vmsfname, %function
vmsfname:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	ldrb	r3, [r0, #0]	@ zero_extendqisi2
	cmp	r3, #0
	bne	.L274
.L275:
	mov	lr, #0
	mov	ip, lr
.L276:
	ldrb	r2, [r0, ip]	@ zero_extendqisi2
	cmp	r2, #0
	mvneq	r4, #0
	beq	.L279
	b	.L277
.L319:
	cmp	r3, #58
	bne	.L281
	cmp	r2, #0
	blt	.L275
	mov	lr, #0
.L313:
	ldrb	r3, [r0, lr]	@ zero_extendqisi2
	strb	r3, [lr, r1]
	add	lr, lr, #1
	cmp	lr, r2
	ble	.L313
	mov	ip, lr
	b	.L276
.L286:
	mov	r2, #0
.L281:
	add	r2, r2, #1
	ldrb	r3, [r0, r2]	@ zero_extendqisi2
	cmp	r3, #0
	bne	.L319
	b	.L275
.L277:
	add	r3, r0, ip
	mvn	r4, #0
.L287:
	cmp	r2, #47
	moveq	r4, ip
	add	ip, ip, #1
	ldrb	r2, [r3, #1]	@ zero_extendqisi2
	add	r3, r3, #1
	cmp	r2, #0
	bne	.L287
.L279:
	mov	r2, lr
	add	ip, r0, lr
	ldrb	r3, [r0, lr]	@ zero_extendqisi2
	cmp	r3, #47
	bne	.L290
	cmp	lr, r4
	movne	r3, #91
	strneb	r3, [lr, r1]
	addne	r2, lr, #1
	add	ip, lr, #1
	b	.L295
.L290:
	cmp	r4, #0
	movlt	ip, lr
	movlt	r2, lr
	blt	.L295
	mov	r3, #91
	strb	r3, [r2, r1]
	add	r2, lr, #1
	ldrb	r3, [ip, #0]	@ zero_extendqisi2
	cmp	r3, #46
	bne	.L298
	add	r3, r0, lr
	ldrb	r3, [r3, #1]	@ zero_extendqisi2
	cmp	r3, #46
	moveq	ip, lr
	beq	.L295
.L298:
	mov	r3, #46
	strb	r3, [r1, r2]
	add	r2, lr, #2
	mov	ip, lr
.L295:
	add	lr, r2, r1
.L301:
	ldrb	r2, [r0, ip]	@ zero_extendqisi2
	cmp	r2, #46
	bne	.L302
	add	r3, r0, ip
	ldrb	r3, [r3, #1]	@ zero_extendqisi2
	cmp	r3, #46
	addeq	ip, ip, #1
	subeq	r2, r2, #1
	b	.L304
.L302:
	cmp	r2, #47
	bne	.L304
	cmp	ip, r4
	movne	r2, #46
	moveq	r2, #93
.L304:
	strb	r2, [lr], #1
	cmp	r2, #0
	beq	.L309
	add	ip, ip, #1
	b	.L301
.L274:
	cmp	r3, #58
	moveq	r2, #0
	moveq	lr, r2
	beq	.L313
	b	.L286
.L309:
	mov	r0, r1
	ldmfd	sp!, {r4, pc}
	.size	vmsfname, .-vmsfname
	.align	2
	.type	winfname, %function
winfname:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	@ lr needed for prologue
	mov	r2, r1
.L321:
	ldrb	r3, [r0], #1	@ zero_extendqisi2
	cmp	r3, #47
	moveq	r3, #92
	strb	r3, [r2], #1
	cmp	r3, #0
	bne	.L321
	mov	r0, r1
	bx	lr
	.size	winfname, .-winfname
	.align	2
	.type	unixfname, %function
unixfname:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	@ lr needed for prologue
	mov	r2, r1
.L329:
	ldrb	r3, [r0], #1	@ zero_extendqisi2
	cmp	r3, #92
	moveq	r3, #47
	strb	r3, [r2], #1
	cmp	r3, #0
	bne	.L329
	mov	r0, r1
	bx	lr
	.size	unixfname, .-unixfname
	.section	.rodata.str1.4
	.align	2
.LC28:
	.ascii	"Configuration error: \000"
	.align	2
.LC29:
	.ascii	"One of UNIXNAMES, WINNAMES or VMSNAMES must be set\000"
	.align	2
.LC30:
	.ascii	"osfname: %s => %s\012\000"
	.text
	.align	2
	.type	osfname, %function
osfname:
	@ args = 0, pretend = 0, frame = 256
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, lr}
	sub	sp, sp, #256
	mov	r5, r0
	mov	r4, r1
	mov	r1, sp
	bl	prepend_prefix
	mov	r1, r4
	bl	unixfname
	subs	r4, r0, #0
	bne	.L337
	ldr	r0, .L342
	bl	printf
	ldr	r0, .L342+4
	bl	puts
	b	.L339
.L337:
	ldr	r3, .L342+8
	ldr	r3, [r3, #0]
	cmp	r3, #0
	ldrne	r0, .L342+12
	movne	r1, r5
	movne	r2, r4
	blne	printf
.L339:
	mov	r0, r4
	add	sp, sp, #256
	ldmfd	sp!, {r4, r5, pc}
.L343:
	.align	2
.L342:
	.word	.LC28
	.word	.LC29
	.word	filetracing
	.word	.LC30
	.size	osfname, .-osfname
	.align	2
	.type	prepend_prefix, %function
prepend_prefix:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, lr}
	mov	r4, r0
	mov	r6, r1
	ldr	r3, .L359
	ldr	r3, [r3, #0]
	ldrb	r5, [r3], #1	@ zero_extendqisi2
	mov	r7, r3
	cmp	r5, #0
	beq	.L345
	bl	relfilename
	cmp	r0, #0
	bne	.L357
	b	.L345
.L348:
	mov	r2, #0
	add	r1, r3, #1
.L349:
	ldrb	r3, [r7, r2]	@ zero_extendqisi2
	strb	r3, [r6, r2]
	add	r2, r2, #1
	cmp	r2, r1
	bne	.L349
.L350:
	mov	r3, #47
	strb	r3, [r2, r6]
	add	r3, r2, #1
	add	r2, r6, r3
.L351:
	ldrb	r3, [r4], #1	@ zero_extendqisi2
	strb	r3, [r2], #1
	cmp	r3, #0
	bne	.L351
	mov	r4, r6
	b	.L345
.L357:
	sub	r3, r5, #1
	cmn	r3, #1
	moveq	r2, #0
	beq	.L350
	b	.L348
.L345:
	mov	r0, r4
	ldmfd	sp!, {r4, r5, r6, r7, pc}
.L360:
	.align	2
.L359:
	.word	prefixbp
	.size	prepend_prefix, .-prepend_prefix
	.align	2
	.type	c2b_str, %function
c2b_str:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	@ lr needed for prologue
	mov	ip, r1, asl #2
	ldrb	r3, [r0, #0]	@ zero_extendqisi2
	cmp	r3, #0
	beq	.L364
	mov	r2, #1
.L365:
	strb	r3, [ip, r2]
	ldrb	r3, [r0, r2]	@ zero_extendqisi2
	add	r2, r2, #1
	cmp	r3, #0
	bne	.L365
	sub	r3, r2, #1
.L364:
	strb	r3, [ip, #0]
	mov	r0, r1
	bx	lr
	.size	c2b_str, .-c2b_str
	.align	2
	.type	b2c_str, %function
b2c_str:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	mov	r3, r0, asl #2
	cmp	r0, #0
	moveq	r1, r0
	beq	.L373
	ldrb	lr, [r3], #1	@ zero_extendqisi2
	mov	r0, r3
	cmp	lr, #0
	beq	.L374
	mov	r2, #0
	mov	ip, r2
.L376:
	ldrb	r3, [r0], #1	@ zero_extendqisi2
	strb	r3, [r1, ip]
	add	r3, r2, #1
	and	r2, r3, #255
	add	ip, ip, #1
	cmp	lr, r2
	bne	.L376
.L374:
	mov	r3, #0
	strb	r3, [lr, r1]
.L373:
	mov	r0, r1
	ldr	pc, [sp], #4
	.size	b2c_str, .-b2c_str
	.local	parms
	.comm	parms,4,4
	.local	ttyinp
	.comm	ttyinp,4,4
	.local	chbuf1
	.comm	chbuf1,256,1
	.local	chbuf2
	.comm	chbuf2,256,1
	.local	chbuf3
	.comm	chbuf3,256,1
	.local	chbuf4
	.comm	chbuf4,256,1
	.comm	rootnode,204,4
	.comm	trvec,16384,4
	.comm	prefixbp,4,4
	.comm	stackbase,4,4
	.comm	globbase,4,4
	.comm	result2,4,4
	.comm	old_handler,4,4
	.ident	"GCC: (GNU) 4.0.2"
