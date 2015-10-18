	.file	"callstart.c"
	.text
	.align	2
	.global	f
	.type	f, %function
f:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	cmp	r0, #1
	stmfd	sp!, {r4, r5, r6, r7, r8, sl, lr}
	mov	r5, r0
	movle	r0, #1
	ldmlefd	sp!, {r4, r5, r6, r7, r8, sl, pc}
	sub	r3, r5, #1
	cmp	r3, #1
	suble	r7, r5, #2
	movle	sl, #1
	ble	.L7
	sub	r7, r5, #2
	cmp	r7, #1
	suble	r6, r5, #3
	movle	r8, #1
	ble	.L10
	sub	r6, r5, #3
	mov	r0, r6
	bl	f
	mov	r4, r0
	sub	r0, r5, #4
	bl	f
	add	r8, r4, r0
.L10:
	cmp	r6, #1
	movle	r4, #1
	ble	.L13
	sub	r0, r5, #4
	bl	f
	mov	r4, r0
	sub	r0, r5, #5
	bl	f
	add	r4, r4, r0
.L13:
	add	sl, r8, r4
.L7:
	cmp	r7, #1
	movle	r0, #1
	ble	.L16
	sub	r3, r5, #3
	cmp	r3, #1
	suble	r6, r5, #4
	movle	r8, #1
	ble	.L19
	sub	r6, r5, #4
	mov	r0, r6
	bl	f
	mov	r4, r0
	sub	r0, r5, #5
	bl	f
	add	r8, r4, r0
.L19:
	cmp	r6, #1
	movle	r4, #1
	ble	.L22
	sub	r3, r5, #5
	cmp	r3, #1
	suble	r6, r5, #6
	movle	r7, #1
	ble	.L25
	sub	r6, r5, #6
	mov	r0, r6
	bl	f
	mov	r4, r0
	sub	r0, r5, #7
	bl	f
	add	r7, r4, r0
.L25:
	cmp	r6, #1
	movle	r4, #1
	ble	.L28
	sub	r0, r5, #7
	bl	f
	mov	r4, r0
	sub	r0, r5, #8
	bl	f
	add	r4, r4, r0
.L28:
	add	r4, r7, r4
.L22:
	add	r0, r8, r4
.L16:
	add	r0, sl, r0
	ldmfd	sp!, {r4, r5, r6, r7, r8, sl, pc}
	.size	f, .-f
	.align	2
	.global	callstart
	.type	callstart, %function
callstart:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	cmp	r2, #0
	stmfd	sp!, {r4, r5, lr}
	mov	r4, #100
	ble	.L34
	ldr	r5, [r0, #0]
	mov	r4, #1
	cmp	r5, r4
	sub	r0, r5, #1
	ble	.L34
	bl	f
	mov	r4, r0
	sub	r0, r5, #2
	bl	f
	add	r4, r4, r0
.L34:
	mov	r0, r4
	ldmfd	sp!, {r4, r5, pc}
	.size	callstart, .-callstart
	.ident	"GCC: (GNU) 4.0.2"
