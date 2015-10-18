	.arch armv5te
	.fpu softvfp
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 2
	.eabi_attribute 30, 2
	.eabi_attribute 18, 4
	.file	"cinterp.c"
	.global	__aeabi_fmul
	.global	__aeabi_fdiv
	.global	__aeabi_fadd
	.global	__aeabi_fsub
	.global	__aeabi_idiv
	.global	__aeabi_idivmod
	.global	__aeabi_ldivmod
	.text
	.align	2
	.global	interpret
	.type	interpret, %function
interpret:
	.fnstart
	                         @ r0 = regs  r1 = mem
.LFB40:
	@ args = 0, pretend = 0, frame = 152
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, fp, lr}
	.save {r4, r5, r6, r7, r8, r9, sl, fp, lr}
	.pad #156
	sub	sp, sp, #156
	str	r0, [sp, #12]
	add	r2, r0, #4            @ r2 = regs+4
	ldr	ip, [r1, r2, asl #2]
	ldr	sl, [sp, #12]
	mov	r5, r1
	add	r4, sl, #6
	ldr	r1, [sp, #12]
	mov	r0, ip, asr #2
	ldr	r8, [sp, #12]
	ldr	sl, [sp, #12]
	ldr	ip, [sp, #12]
	add	r7, r1, #3
	add	r3, r8, #1
	add	r1, ip, #5
	str	r2, [sp, #40]
	str	r4, [sp, #48]
	add	r2, sl, #2
	ldr	r4, [r5, r4, asl #2]
	str	r0, [sp, #60]
	ldr	r0, [sp, #12]
	str	r7, [sp, #36]
	ldr	r7, [r5, r7, asl #2]
	str	r3, [sp, #28]
	str	r2, [sp, #32]
	ldr	r3, [sp, #12]
	ldr	r2, [sp, #60]
	str	r1, [sp, #44]
	ldr	r1, [sp, #60]
	add	r8, r0, #7
	add	sl, r3, #8
	mov	ip, r2, asl #2
	add	r0, r1, #256
	ldr	r2, [sp, #28]
	ldr	r1, [sp, #28]
	str	r8, [sp, #52]
	ldr	r8, [sp, #12]
	str	sl, [sp, #56]
	ldr	sl, [sp, #12]
	add	r3, r5, r8, asl #2
	str	ip, [sp, #64]
	str	r0, [sp, #76]
	add	ip, r5, r2, asl #2
	ldr	r0, [r5, r1, asl #2]
	str	r3, [sp, #92]
	ldr	sl, [r5, sl, asl #2]
	str	ip, [sp, #96]
	str	r0, [sp, #4]
	ldr	r8, [sp, #32]
	ldr	r2, [sp, #32]
	add	r3, r5, r8, asl #2
	ldr	r1, [sp, #36]
	str	r3, [sp, #100]
	ldr	r3, [sp, #40]
	ldr	ip, [r5, r2, asl #2]
	add	r0, r5, r1, asl #2
	ldr	r1, [sp, #44]
	mov	r8, r7, asr #2
	add	r2, r5, r3, asl #2
	str	ip, [sp, #72]
	ldr	ip, [sp, #44]
	str	r0, [sp, #104]
	str	r8, [sp, #8]
	ldr	r0, [r5, r1, asl #2]
	ldr	r8, [sp, #48]
	ldr	r1, [sp, #56]
	str	r2, [sp, #108]
	ldr	r2, [sp, #52]
	add	r7, r5, ip, asl #2
	add	r3, r5, r8, asl #2
	add	ip, r5, r2, asl #2
	str	r7, [sp, #112]
	str	r0, [sp, #80]
	ldr	r7, [sp, #52]
	add	r0, r5, r1, asl #2
	ldr	r8, [sp, #56]
	ldr	r2, [sp, #64]
	ldr	r1, [sp, #76]
	ldr	r7, [r5, r7, asl #2]
	str	r3, [sp, #116]
	str	ip, [sp, #120]
	ldr	r3, [r5, r8, asl #2]
	str	r0, [sp, #124]
	add	ip, r5, r2
	add	r0, r5, r1, asl #2
	cmp	r4, #0
	str	r3, [sp, #84]
	str	ip, [sp, #68]
	str	r0, [sp, #88]
	blt	.L325
	ldr	r6, [sp, #8]
	ldr	r8, .L364
	mov	r1, r6, asl #2
	ldr	r9, .L364+4
	add	fp, r5, r1
	mov	r6, #0
	str	r1, [sp, #16]
.L347:
	ldr	r0, .L364+4
	ldr	r3, [r0, #0]
	cmp	r3, #0
	beq	.L6
	ldr	r2, [r3, #0]
	ldr	r1, [r9, #4]
	cmp	r2, r1
	bne	.L360
.L6:
	cmp	r7, #0
	blt	.L7
	beq	.L326
	sub	r7, r7, #1
.L7:
	ldr	r2, [r8, #0]
	cmp	r2, #0
	bne	.L361
.L8:
	ldr	r3, .L364+8
	cmp	r4, #0
	ldr	r0, [r3, #0]
	movle	r3, #0
	movgt	r3, #1
	cmp	r4, r0
	movge	r3, #0
	cmp	r3, #0
	ldrne	r3, .L364+12
	sub	r6, r6, #1
	ldrne	r3, [r3, #0]
	ldrne	r0, [r3, r4, asl #2]
	addne	r0, r0, #1
	strne	r0, [r3, r4, asl #2]
	cmp	r6, #0
	ble	.L362
.L11:
	ldrb	ip, [r5, r4]	@ zero_extendqisi2
	add	r3, r4, #1
	sub	r2, ip, #1
	cmp	r2, #254
	ldrls	pc, [pc, r2, asl #2]
	b	.L327
.L264:
	.word	.L12
	.word	.L13
	.word	.L14
	.word	.L15
	.word	.L16
	.word	.L17
	.word	.L18
	.word	.L19
	.word	.L20
	.word	.L21
	.word	.L22
	.word	.L23
	.word	.L24
	.word	.L25
	.word	.L26
	.word	.L27
	.word	.L28
	.word	.L29
	.word	.L30
	.word	.L31
	.word	.L32
	.word	.L33
	.word	.L34
	.word	.L35
	.word	.L36
	.word	.L37
	.word	.L38
	.word	.L39
	.word	.L40
	.word	.L41
	.word	.L42
	.word	.L43
	.word	.L44
	.word	.L45
	.word	.L46
	.word	.L47
	.word	.L48
	.word	.L49
	.word	.L50
	.word	.L51
	.word	.L52
	.word	.L53
	.word	.L54
	.word	.L55
	.word	.L56
	.word	.L57
	.word	.L58
	.word	.L59
	.word	.L60
	.word	.L61
	.word	.L62
	.word	.L63
	.word	.L64
	.word	.L65
	.word	.L66
	.word	.L67
	.word	.L68
	.word	.L69
	.word	.L70
	.word	.L71
	.word	.L72
	.word	.L73
	.word	.L74
	.word	.L75
	.word	.L76
	.word	.L77
	.word	.L78
	.word	.L79
	.word	.L80
	.word	.L81
	.word	.L82
	.word	.L83
	.word	.L84
	.word	.L85
	.word	.L86
	.word	.L87
	.word	.L88
	.word	.L89
	.word	.L90
	.word	.L91
	.word	.L92
	.word	.L93
	.word	.L94
	.word	.L95
	.word	.L96
	.word	.L97
	.word	.L98
	.word	.L99
	.word	.L100
	.word	.L101
	.word	.L102
	.word	.L103
	.word	.L104
	.word	.L105
	.word	.L106
	.word	.L107
	.word	.L108
	.word	.L109
	.word	.L110
	.word	.L111
	.word	.L112
	.word	.L113
	.word	.L114
	.word	.L115
	.word	.L116
	.word	.L117
	.word	.L118
	.word	.L119
	.word	.L120
	.word	.L121
	.word	.L122
	.word	.L123
	.word	.L124
	.word	.L125
	.word	.L126
	.word	.L127
	.word	.L128
	.word	.L129
	.word	.L130
	.word	.L131
	.word	.L132
	.word	.L133
	.word	.L134
	.word	.L135
	.word	.L136
	.word	.L137
	.word	.L138
	.word	.L139
	.word	.L140
	.word	.L141
	.word	.L142
	.word	.L143
	.word	.L144
	.word	.L145
	.word	.L146
	.word	.L147
	.word	.L148
	.word	.L149
	.word	.L150
	.word	.L151
	.word	.L152
	.word	.L153
	.word	.L154
	.word	.L155
	.word	.L156
	.word	.L157
	.word	.L158
	.word	.L159
	.word	.L160
	.word	.L161
	.word	.L162
	.word	.L163
	.word	.L164
	.word	.L165
	.word	.L328
	.word	.L166
	.word	.L167
	.word	.L168
	.word	.L169
	.word	.L170
	.word	.L171
	.word	.L172
	.word	.L173
	.word	.L174
	.word	.L175
	.word	.L176
	.word	.L177
	.word	.L178
	.word	.L179
	.word	.L180
	.word	.L181
	.word	.L182
	.word	.L183
	.word	.L184
	.word	.L185
	.word	.L186
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
	.word	.L197
	.word	.L198
	.word	.L199
	.word	.L200
	.word	.L201
	.word	.L202
	.word	.L203
	.word	.L204
	.word	.L205
	.word	.L206
	.word	.L207
	.word	.L208
	.word	.L209
	.word	.L210
	.word	.L211
	.word	.L212
	.word	.L213
	.word	.L214
	.word	.L215
	.word	.L216
	.word	.L217
	.word	.L4
	.word	.L218
	.word	.L219
	.word	.L220
	.word	.L221
	.word	.L222
	.word	.L223
	.word	.L224
	.word	.L225
	.word	.L226
	.word	.L227
	.word	.L228
	.word	.L229
	.word	.L230
	.word	.L231
	.word	.L327
	.word	.L232
	.word	.L233
	.word	.L234
	.word	.L235
	.word	.L236
	.word	.L237
	.word	.L238
	.word	.L239
	.word	.L240
	.word	.L241
	.word	.L242
	.word	.L243
	.word	.L244
	.word	.L245
	.word	.L246
	.word	.L247
	.word	.L248
	.word	.L249
	.word	.L250
	.word	.L251
	.word	.L252
	.word	.L253
	.word	.L254
	.word	.L255
	.word	.L256
	.word	.L257
	.word	.L258
	.word	.L259
	.word	.L260
	.word	.L261
	.word	.L262
	.word	.L263
.L361:
	mov	r0, r4
	ldr	r1, [sp, #8]
	mov	r2, sl
	ldr	r3, [sp, #4]
	bl	trace
	b	.L8
.L362:
	add	r0, r5, #560
	bl	timestamp
	ldr	r6, .L364+16
	b	.L11
.L138:
	cmp	sl, #0
	addle	r4, r3, #1
	ble	.L347
.L197:
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	add	r0, ip, r3, asr #1
	mov	r3, r0, asl #1
	ldrsh	r2, [r5, r3]
	add	r4, r2, r3
	b	.L347
.L360:
	rsb	r1, r5, r3
	mov	ip, r1, asr #2
	str	r2, [r0, #4]
	str	ip, [r5, #4]
	ldr	r3, [r0, #4]
	mov	r0, #11
	str	r3, [r5, #8]
.L2:
	ldr	r3, [sp, #12]
	ldr	r2, [sp, #28]
	ldr	ip, [sp, #4]
	mov	r1, #0
	str	r1, [r8, #0]
	str	sl, [r5, r3, asl #2]
	str	ip, [r5, r2, asl #2]
	ldr	r3, [sp, #32]
	ldr	r2, [sp, #36]
	ldr	r1, [sp, #72]
	ldr	ip, [sp, #16]
	str	r1, [r5, r3, asl #2]
	str	ip, [r5, r2, asl #2]
	ldr	r3, [sp, #40]
	ldr	r2, [sp, #44]
	ldr	r1, [sp, #64]
	ldr	ip, [sp, #80]
	str	r1, [r5, r3, asl #2]
	str	ip, [r5, r2, asl #2]
	ldr	r1, [sp, #48]
	ldr	r3, [sp, #52]
	ldr	r2, [sp, #56]
	ldr	ip, [sp, #84]
	str	r4, [r5, r1, asl #2]
	str	r7, [r5, r3, asl #2]
	str	ip, [r5, r2, asl #2]
	add	sp, sp, #156
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, fp, pc}
.L326:
	mov	r0, #3
	b	.L2
.L247:
	ldr	lr, [fp, #12]
	ldr	sl, [fp, #16]
	ldr	r3, [fp, #20]
	smull	r0, r1, sl, lr
	cmp	r3, #0
	strd	r0, [sp, #16]
	beq	.L340
	mov	r2, r3
	mov	r3, r2, asr #31
	strd	r2, [sp, #128]
	ldrd	r0, [sp, #16]
	ldrd	r2, [sp, #128]
	bl	__aeabi_ldivmod
.L295:
	ldr	r1, [sp, #68]
	str	r2, [r1, #40]
	ldrd	r0, [sp, #16]
	ldrd	r2, [sp, #128]
	bl	__aeabi_ldivmod
	mov	sl, r0
.L134:
	ldr	r4, [sp, #8]
	ldr	ip, [r5, r4, asl #2]
	ldr	r4, [fp, #4]
	mov	r0, ip, asr #2
	mov	fp, r0, asl #2
	str	fp, [sp, #16]
	str	r0, [sp, #8]
	add	fp, r5, fp
	b	.L347
.L198:
	ldr	r1, [sp, #4]
	cmp	sl, r1
	ldrlesb	r4, [r5, r3]
	addgt	r4, r3, #1
	addle	r4, r4, r3
	b	.L347
.L199:
	ldr	ip, [sp, #4]
	cmp	sl, ip
	addgt	r4, r3, #1
	bgt	.L347
	b	.L197
.L200:
	cmp	sl, #0
	ldrgesb	r4, [r5, r3]
	addlt	r4, r3, #1
	addge	r4, r4, r3
	b	.L347
.L201:
	cmp	sl, #0
	addlt	r4, r3, #1
	bge	.L197
	b	.L347
.L202:
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #1
	ldr	r3, [fp, r0, asl #2]
	add	sl, sl, r3
	b	.L347
.L203:
	add	r1, r5, r3
	ldrb	r1, [r1, #1]	@ zero_extendqisi2
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #2
	orr	r2, r0, r1, asl #8
	ldr	ip, [fp, r2, asl #2]
	add	sl, sl, ip
	b	.L347
.L204:
	add	r2, r5, r3
	ldrb	r4, [r2, #3]	@ zero_extendqisi2
	ldrb	r1, [r2, #2]	@ zero_extendqisi2
	ldrb	ip, [r2, #1]	@ zero_extendqisi2
	orr	r1, r1, r4, asl #8
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	orr	r2, ip, r1, asl #8
	orr	r4, r0, r2, asl #8
	ldr	ip, [fp, r4, asl #2]
	add	r4, r3, #4
	add	sl, sl, ip
	b	.L347
.L205:
	ldr	r2, [fp, #12]
	mov	r4, r3
	add	sl, sl, r2
	b	.L347
.L206:
	ldr	ip, [fp, #16]
	mov	r4, r3
	add	sl, sl, ip
	b	.L347
.L207:
	ldr	r0, [fp, #20]
	mov	r4, r3
	add	sl, sl, r0
	b	.L347
.L208:
	ldr	r2, [fp, #24]
	mov	r4, r3
	add	sl, sl, r2
	b	.L347
.L209:
	ldr	ip, [fp, #28]
	mov	r4, r3
	add	sl, sl, ip
	b	.L347
.L210:
	ldr	r0, [fp, #32]
	mov	r4, r3
	add	sl, sl, r0
	b	.L347
.L211:
	ldr	r2, [fp, #36]
	mov	r4, r3
	add	sl, sl, r2
	b	.L347
.L212:
	ldr	ip, [fp, #40]
	mov	r4, r3
	add	sl, sl, ip
	b	.L347
.L213:
	ldr	r0, [fp, #44]
	mov	r4, r3
	add	sl, sl, r0
	b	.L347
.L214:
	ldr	r2, [fp, #48]
	mov	r4, r3
	add	sl, sl, r2
	b	.L347
.L215:
	ldr	r0, [sp, #4]
	ldr	r4, [sp, #72]
	add	r2, r5, r0
	strb	r4, [r2, sl, asl #2]
	mov	r4, r3
	b	.L347
.L216:
	add	r1, r5, r3
	ldrb	r1, [r1, #1]	@ zero_extendqisi2
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	str	sl, [sp, #4]
	orr	sl, ip, r1, asl #8
	add	r4, r3, #2
	rsb	sl, sl, #0
	b	.L347
.L217:
	ldr	r1, [sp, #4]
	mov	r4, r3
	str	r1, [sp, #72]
	b	.L347
.L4:
	mov	r4, r3
	b	.L347
.L218:
	add	sl, sl, #1
	mov	r4, r3
	b	.L347
.L219:
	add	sl, sl, #2
	mov	r4, r3
	b	.L347
.L220:
	add	sl, sl, #3
	mov	r4, r3
	b	.L347
.L221:
	add	sl, sl, #4
	mov	r4, r3
	b	.L347
.L222:
	add	sl, sl, #5
	mov	r4, r3
	b	.L347
.L223:
	ldr	r0, [fp, #12]
	mov	r4, r3
	add	r3, sl, r0
	ldr	sl, [r5, r3, asl #2]
	b	.L347
.L224:
	ldr	ip, [fp, #16]
	mov	r4, r3
	add	sl, sl, ip
	ldr	sl, [r5, sl, asl #2]
	b	.L347
.L225:
	ldr	r2, [fp, #20]
	mov	r4, r3
	add	r0, sl, r2
	ldr	sl, [r5, r0, asl #2]
	b	.L347
.L226:
	ldr	ip, [fp, #24]
	mov	r4, r3
	add	r3, sl, ip
	ldr	sl, [r5, r3, asl #2]
	b	.L347
.L227:
	ldr	r2, [fp, #28]
	mov	r4, r3
	add	sl, sl, r2
	ldr	sl, [r5, sl, asl #2]
	b	.L347
.L228:
	ldr	r0, [fp, #12]
	mov	r4, r3
	str	sl, [r5, r0, asl #2]
	b	.L347
.L229:
	ldr	ip, [fp, #16]
	mov	r4, r3
	str	sl, [r5, ip, asl #2]
	b	.L347
.L230:
	ldr	r0, [fp, #12]
	mov	r4, r3
	add	ip, r0, #1
	str	sl, [r5, ip, asl #2]
	b	.L347
.L231:
	ldr	r2, [fp, #16]
	mov	r4, r3
	add	r3, r2, #1
	str	sl, [r5, r3, asl #2]
	b	.L347
.L232:
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #1
	add	sl, sl, ip
	b	.L347
.L233:
	add	r4, r5, r3
	ldrb	r1, [r4, #1]	@ zero_extendqisi2
	ldrb	r2, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #2
	orr	r3, r2, r1, asl #8
	add	sl, sl, r3
	b	.L347
.L234:
	add	r2, r5, r3
	ldrb	r0, [r2, #3]	@ zero_extendqisi2
	ldrb	r1, [r2, #2]	@ zero_extendqisi2
	ldrb	r4, [r2, #1]	@ zero_extendqisi2
	orr	r1, r1, r0, asl #8
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	orr	r2, r4, r1, asl #8
	orr	r0, ip, r2, asl #8
	add	sl, sl, r0
	add	r4, r3, #4
	b	.L347
.L235:
	ldr	r2, [fp, #12]
	mov	r4, r3
	str	sl, [sp, #4]
	ldr	sl, [r5, r2, asl #2]
	b	.L347
.L236:
	ldr	r0, [fp, #16]
	mov	r4, r3
	str	sl, [sp, #4]
	ldr	sl, [r5, r0, asl #2]
	b	.L347
.L237:
	ldr	ip, [fp, #20]
	mov	r4, r3
	str	sl, [sp, #4]
	ldr	sl, [r5, ip, asl #2]
	b	.L347
.L238:
	ldr	r2, [fp, #24]
	mov	r4, r3
	str	sl, [sp, #4]
	ldr	sl, [r5, r2, asl #2]
	b	.L347
.L239:
	ldr	r0, [fp, #28]
	mov	r4, r3
	str	sl, [sp, #4]
	ldr	sl, [r5, r0, asl #2]
	b	.L347
.L240:
	ldr	ip, [fp, #32]
	mov	r4, r3
	str	sl, [sp, #4]
	ldr	sl, [r5, ip, asl #2]
	b	.L347
.L241:
	ldr	r2, [fp, #36]
	mov	r4, r3
	str	sl, [sp, #4]
	ldr	sl, [r5, r2, asl #2]
	b	.L347
.L242:
	ldr	r0, [fp, #40]
	mov	r4, r3
	str	sl, [sp, #4]
	ldr	sl, [r5, r0, asl #2]
	b	.L347
.L243:
	ldr	ip, [fp, #44]
	mov	r4, r3
	str	sl, [sp, #4]
	ldr	sl, [r5, ip, asl #2]
	b	.L347
.L244:
	ldr	r2, [fp, #48]
	mov	r4, r3
	str	sl, [sp, #4]
	ldr	sl, [r5, r2, asl #2]
	b	.L347
.L245:
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #1
	rsb	sl, ip, sl
	b	.L347
.L246:
	add	r4, r5, r3
	ldrb	r1, [r4, #1]	@ zero_extendqisi2
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #2
	orr	r3, r0, r1, asl #8
	rsb	sl, r3, sl
	b	.L347
.L248:
	ldr	ip, [sp, #68]
	ldr	r4, [fp, #0]
	ldr	r3, [ip, #28]
	str	r4, [r5, r3, asl #2]
	ldr	r0, [fp, #16]
	ldr	r4, [fp, #4]
	str	r0, [ip, #28]
	ldr	r2, [fp, #16]
	ldr	ip, [r5, r2, asl #2]
	mov	r3, ip, asr #2
	mov	fp, r3, asl #2
	str	fp, [sp, #16]
	str	r3, [sp, #8]
	add	fp, r5, fp
	b	.L347
.L249:
	rsb	sl, sl, #0
	mov	r4, r3
	b	.L347
.L250:
	mvn	sl, sl
	mov	r4, r3
	b	.L347
.L251:
	ldr	ip, [fp, #12]
	str	sl, [sp, #4]
	add	sl, ip, #1
	mov	r4, r3
	ldr	sl, [r5, sl, asl #2]
	b	.L347
.L252:
	ldr	r4, [fp, #16]
	str	sl, [sp, #4]
	add	r2, r4, #1
	ldr	sl, [r5, r2, asl #2]
	mov	r4, r3
	b	.L347
.L253:
	ldr	r0, [fp, #20]
	mov	r4, r3
	add	ip, r0, #1
	str	sl, [sp, #4]
	ldr	sl, [r5, ip, asl #2]
	b	.L347
.L254:
	ldr	r4, [fp, #24]
	str	sl, [sp, #4]
	add	sl, r4, #1
	ldr	sl, [r5, sl, asl #2]
	mov	r4, r3
	b	.L347
.L255:
	ldr	r0, [fp, #12]
	mov	r4, r3
	add	ip, r0, #2
	str	sl, [sp, #4]
	ldr	sl, [r5, ip, asl #2]
	b	.L347
.L256:
	ldr	r4, [fp, #16]
	str	sl, [sp, #4]
	add	sl, r4, #2
	ldr	sl, [r5, sl, asl #2]
	mov	r4, r3
	b	.L347
.L257:
	ldr	r2, [fp, #20]
	mov	r4, r3
	add	r0, r2, #2
	str	sl, [sp, #4]
	ldr	sl, [r5, r0, asl #2]
	b	.L347
.L258:
	ldr	ip, [fp, #12]
	str	sl, [sp, #4]
	add	sl, ip, #3
	mov	r4, r3
	ldr	sl, [r5, sl, asl #2]
	b	.L347
.L259:
	ldr	r4, [fp, #16]
	str	sl, [sp, #4]
	add	r2, r4, #3
	ldr	sl, [r5, r2, asl #2]
	mov	r4, r3
	b	.L347
.L260:
	ldr	r4, [fp, #12]
	str	sl, [sp, #4]
	add	sl, r4, #4
	ldr	sl, [r5, sl, asl #2]
	mov	r4, r3
	b	.L347
.L261:
	ldr	r2, [fp, #16]
	mov	r4, r3
	add	r0, r2, #4
	str	sl, [sp, #4]
	ldr	sl, [r5, r0, asl #2]
	b	.L347
.L262:
	ldrb	r2, [r5, r3]	@ zero_extendqisi2
	mvn	r0, #0
	add	r3, r3, #1
	cmp	r2, #0
	ldrb	r1, [r5, r3]	@ zero_extendqisi2
	mvnne	r0, r0, asl r2
	ldr	sl, [r5, sl, asl #2]
	add	r4, r3, #1
	and	sl, r0, sl, asr r1
	b	.L347
.L263:
	add	r0, r3, #1
	mov	r1, sl, asl #2
	ldrb	r2, [r5, r0]	@ zero_extendqisi2
	add	r4, r3, #2
	str	r1, [sp, #144]
	ldr	r0, [sp, #144]
	ldrb	ip, [r5, r4]	@ zero_extendqisi2
	ldrb	r1, [r5, r3]	@ zero_extendqisi2
	cmp	r2, #0
	mvn	r3, #0
	str	ip, [sp, #128]
	mvnne	r3, r3, asl r2
	moveq	r3, r3, lsr ip
	ldr	r2, [r5, r0]
	ldr	r0, [sp, #128]
	str	r3, [sp, #148]
	add	r4, r4, #1
	str	r2, [sp, #140]
	and	r3, r3, r2, lsr r0
	cmp	r1, #16
	ldrls	pc, [pc, r1, asl #2]
	b	.L332
.L290:
	.word	.L333
	.word	.L274
	.word	.L275
	.word	.L276
	.word	.L277
	.word	.L278
	.word	.L279
	.word	.L280
	.word	.L281
	.word	.L282
	.word	.L283
	.word	.L284
	.word	.L285
	.word	.L286
	.word	.L287
	.word	.L288
	.word	.L289
.L327:
	mov	r0, #1
	b	.L2
.L12:
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	add	r3, r3, #1
	cmp	r0, #17
	ldrls	pc, [pc, r0, asl #2]
	b	.L329
.L268:
	.word	.L330
	.word	.L265
	.word	.L329
	.word	.L266
	.word	.L266
	.word	.L266
	.word	.L267
	.word	.L267
	.word	.L267
	.word	.L267
	.word	.L266
	.word	.L266
	.word	.L267
	.word	.L267
	.word	.L267
	.word	.L267
	.word	.L267
	.word	.L267
.L13:
	mov	r0, #2
	b	.L2
.L14:
	ldr	r1, [sp, #8]
	add	r2, r1, #3
	ldr	r1, [sp, #16]
	str	r2, [sp, #8]
	str	r1, [fp, #12]
.L312:
	mov	r4, r2, asl #2
	add	fp, r5, r4
	str	r4, [sp, #16]
	cmp	sl, #0
	str	r3, [fp, #4]
	ldr	r3, [sp, #4]
	str	sl, [fp, #8]
	str	r3, [fp, #12]
	blt	.L363
	mov	r4, sl
	ldr	sl, [sp, #4]
	b	.L347
.L15:
	ldr	r0, [sp, #16]
	str	r0, [fp, #16]
	ldr	fp, [sp, #8]
	add	ip, fp, #4
	str	ip, [sp, #8]
	mov	r2, ip
	b	.L312
.L16:
	ldr	r2, [sp, #8]
	ldr	r4, [sp, #16]
	add	r1, r2, #5
	str	r4, [fp, #20]
	mov	r2, r1
	str	r1, [sp, #8]
	b	.L312
.L17:
	ldr	r0, [sp, #16]
	str	r0, [fp, #24]
	ldr	fp, [sp, #8]
	add	ip, fp, #6
	str	ip, [sp, #8]
	mov	r2, ip
	b	.L312
.L18:
	ldr	r4, [sp, #8]
	ldr	r1, [sp, #16]
	str	r1, [fp, #28]
	add	r1, r4, #7
	str	r1, [sp, #8]
	mov	r2, r1
	b	.L312
.L19:
	ldr	r0, [sp, #8]
	ldr	r2, [sp, #16]
	str	r2, [fp, #32]
	add	fp, r0, #8
	str	fp, [sp, #8]
	mov	r2, fp
	b	.L312
.L20:
	ldr	r1, [sp, #8]
	ldr	ip, [sp, #16]
	add	r1, r1, #9
	str	ip, [fp, #36]
	mov	r2, r1
	str	r1, [sp, #8]
	b	.L312
.L21:
	ldr	r2, [sp, #8]
	ldr	r4, [sp, #16]
	add	r0, r2, #10
	str	r4, [fp, #40]
	mov	r2, r0
	str	r0, [sp, #8]
	b	.L312
.L22:
	ldr	r4, [sp, #8]
	ldr	ip, [sp, #16]
	add	r1, r4, #11
	str	ip, [fp, #44]
	mov	r2, r1
	str	r1, [sp, #8]
	b	.L312
.L23:
	ldrsb	r0, [r5, r3]
	add	r4, r3, #1
	str	sl, [sp, #4]
	add	sl, r0, r3
	b	.L347
.L24:
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	str	sl, [sp, #4]
	add	r4, ip, r3, asr #1
	mov	r2, r4, asl #1
	ldrsh	r0, [r5, r2]
	add	r4, r3, #1
	add	sl, r0, r2
	b	.L347
.L25:
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #1
	str	sl, [sp, #4]
	rsb	sl, r0, #0
	b	.L347
.L26:				;LM1?
	str	sl, [sp, #4]
	mov	r4, r3
	mvn	sl, #0
	b	.L347
.L27:				;L0
	str	sl, [sp, #4]
	mov	r4, r3
	mov	sl, #0
	b	.L347
.L28:				;L1
	str	sl, [sp, #4]
	mov	r4, r3
	mov	sl, #1
	b	.L347
.L29:				;L2
	str	sl, [sp, #4]
	mov	r4, r3
	mov	sl, #2
	b	.L347
.L30:				;L3
	str	sl, [sp, #4]
	mov	r4, r3
	mov	sl, #3
	b	.L347
.L31:				;L4
	str	sl, [sp, #4]
	mov	r4, r3
	mov	sl, #4
	b	.L347
.L32:				;L5
	str	sl, [sp, #4]
	mov	r4, r3
	mov	sl, #5
	b	.L347
.L33:				;L6
	str	sl, [sp, #4]
	mov	r4, r3
	mov	sl, #6
	b	.L347
.L34:				;L7
	str	sl, [sp, #4]
	mov	r4, r3
	mov	sl, #7
	b	.L347
.L35:				;L8
	str	sl, [sp, #4]
	mov	r4, r3
	mov	sl, #8
	b	.L347
.L36:				;L9
	str	sl, [sp, #4]
	mov	r4, r3
	mov	sl, #9
	b	.L347
.L37:				;L10
	str	sl, [sp, #4]
	mov	r4, r3
	mov	sl, #10
	b	.L347
.L38:
	add	r4, r3, #1
	mov	sl, #0
	b	.L347
.L39:
	ldr	r2, [sp, #4]
	cmp	r2, sl
	ldreqsb	r4, [r5, r3]
	moveq	sl, r2
	addeq	r4, r4, r3
	addne	r4, r3, #1
	b	.L347
.L40:
	ldr	r0, [sp, #4]
	cmp	r0, sl
	addne	r4, r3, #1
	bne	.L347
	b	.L197
.L41:
	cmp	sl, #0
	ldreqsb	r4, [r5, r3]
	addne	r4, r3, #1
	addeq	r4, r4, r3
	b	.L347
.L42:
	cmp	sl, #0
	addne	r4, r3, #1
	bne	.L347
	b	.L197
.L43:
	ldrb	r2, [r5, r3]	@ zero_extendqisi2
	ldr	r1, [sp, #8]
	ldr	r0, [sp, #16]
	add	ip, r1, r2
	mov	r1, ip, asl #2
	str	ip, [sp, #8]
	add	r3, r3, #1
	str	r0, [fp, r2, asl #2]
	cmp	sl, #0
	add	fp, r5, r1
	ldr	r2, [sp, #4]
	str	r1, [sp, #16]
	stmib	fp, {r3, sl}	@ phole stm
	str	r2, [fp, #12]
	blt	.L353
	mov	r4, sl
	ldr	sl, [sp, #4]
	b	.L347
.L365:
	.align	2
.L364:
	.word	tracing
	.word	.LANCHOR0
	.word	tallylim
	.word	tallyv
	.word	10000
.L44:
	add	r4, r5, r3
	ldrb	r1, [r4, #1]	@ zero_extendqisi2
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	ldr	r2, [sp, #8]
	orr	r0, ip, r1, asl #8
	add	r4, r3, #2
	add	r3, r2, r0
	ldr	ip, [sp, #16]
	mov	r1, r3, asl #2
	str	r3, [sp, #8]
	ldr	r2, [sp, #4]
	str	ip, [fp, r0, asl #2]
	cmp	sl, #0
	add	fp, r5, r1
	str	r1, [sp, #16]
	stmib	fp, {r4, sl}	@ phole stm
	str	r2, [fp, #12]
	blt	.L353
	mov	r4, sl
	ldr	sl, [sp, #4]
	b	.L347
.L45:
	add	r4, r5, r3
	ldrb	ip, [r4, #3]	@ zero_extendqisi2
	ldrb	r1, [r4, #2]	@ zero_extendqisi2
	ldrb	r2, [r4, #1]	@ zero_extendqisi2
	orr	r0, r1, ip, asl #8
	ldrb	r4, [r5, r3]	@ zero_extendqisi2
	ldr	r1, [sp, #8]
	orr	ip, r2, r0, asl #8
	orr	r2, r4, ip, asl #8
	add	ip, r1, r2
	ldr	r0, [sp, #16]
	mov	r1, ip, asl #2
	str	ip, [sp, #8]
	add	r3, r3, #4
	str	r0, [fp, r2, asl #2]
	cmp	sl, #0
	add	fp, r5, r1
	ldr	r2, [sp, #4]
	str	r1, [sp, #16]
	stmib	fp, {r3, sl}	@ phole stm
	str	r2, [fp, #12]
	blt	.L353
	mov	r4, sl
	ldr	sl, [sp, #4]
	b	.L347
.L46:				;K0G3
	ldr	r1, [sp, #8]
	add	r0, r1, #3
	mov	r2, r0
	ldr	r1, [sp, #16]
	str	r0, [sp, #8]
	str	r1, [fp, #12]
.L311:
	mov	fp, r2, asl #2
	str	fp, [sp, #16]
	add	r2, r3, #1
	add	fp, r5, fp
	str	r2, [fp, #4]
	ldrb	r3, [r5, r3]	@ zero_extendqisi2
.L356:
	ldr	ip, [sp, #68]
.L358:
	ldr	r4, [ip, r3, asl #2]
	str	r4, [fp, #8]
	cmp	r4, #0
	str	sl, [fp, #12]
	bge	.L347
	mov	r0, #4
	b	.L2
.L47:
	ldr	r4, [sp, #8]
	ldr	ip, [sp, #16]
	str	ip, [fp, #16]
	add	fp, r4, #4
	str	fp, [sp, #8]
	mov	r2, fp
	b	.L311
.L48:
	ldr	r0, [sp, #8]
	ldr	r2, [sp, #16]
	add	r1, r0, #5
	str	r2, [fp, #20]
	str	r1, [sp, #8]
	mov	r2, r1
	b	.L311
.L49:
	ldr	r4, [sp, #8]
	ldr	ip, [sp, #16]
	str	ip, [fp, #24]
	add	fp, r4, #6
	str	fp, [sp, #8]
	mov	r2, fp
	b	.L311
.L50:
	ldr	r2, [sp, #8]
	ldr	r1, [sp, #16]
	str	r1, [fp, #28]
	add	r1, r2, #7
	str	r1, [sp, #8]
	mov	r2, r1
	b	.L311
.L51:
	ldr	ip, [sp, #8]
	ldr	r0, [sp, #16]
	add	r4, ip, #8
	str	r0, [fp, #32]
	mov	r2, r4
	str	r4, [sp, #8]
	b	.L311
.L52:
	ldr	r1, [sp, #16]
	str	r1, [fp, #36]
	ldr	fp, [sp, #8]
	add	r1, fp, #9
	str	r1, [sp, #8]
	mov	r2, r1
	b	.L311
.L53:
	ldr	r0, [sp, #8]
	ldr	r2, [sp, #16]
	add	ip, r0, #10
	str	r2, [fp, #40]
	str	ip, [sp, #8]
	mov	r2, ip
	b	.L311
.L54:
	ldr	r1, [sp, #8]
	ldr	r4, [sp, #16]
	add	r1, r1, #11
	str	r4, [fp, #44]
	mov	r2, r1
	str	r1, [sp, #8]
	b	.L311
.L55:
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	ldr	r1, [sp, #68]
	add	r4, r3, #1
	ldr	ip, [r1, r0, asl #2]
	str	sl, [r5, ip, asl #2]
	b	.L347
.L56:
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	str	sl, [sp, #4]
	ldr	sl, [sp, #68]
	add	r4, r3, #1
	ldr	r2, [sl, r0, asl #2]
	ldr	sl, [r5, r2, asl #2]
	b	.L347
.L57:
	ldrb	r4, [r5, r3]	@ zero_extendqisi2
	ldr	r2, [sp, #68]
	str	sl, [sp, #4]
	ldr	ip, [r2, r4, asl #2]
	add	r4, r3, #1
	add	r3, ip, #1
	ldr	sl, [r5, r3, asl #2]
	b	.L347
.L58:
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	ldr	r1, [sp, #68]
	str	sl, [sp, #4]
	ldr	sl, [r1, ip, asl #2]
	add	r4, r3, #1
	add	r0, sl, #2
	ldr	sl, [r5, r0, asl #2]
	b	.L347
.L59:
	ldrb	r2, [r5, r3]	@ zero_extendqisi2
	ldr	r1, [sp, #68]
	str	sl, [sp, #4]
	add	r4, r3, #1
	ldr	sl, [r1, r2, asl #2]
	b	.L347
.L60:
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #1
	ldr	r3, [sp, #68]
	str	sl, [r3, ip, asl #2]
	b	.L347
.L61:
	ldrb	r2, [r5, r3]	@ zero_extendqisi2
	ldr	ip, [sp, #60]
	str	sl, [sp, #4]
	add	r4, r3, #1
	add	sl, r2, ip
	b	.L347
.L62:
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	ldr	r1, [sp, #68]
	add	r4, r3, #1
	ldr	r2, [r1, r0, asl #2]
	add	sl, sl, r2
	b	.L347
.L63: 				; mul
	ldr	r4, [sp, #4]
	mul	sl, r4, sl
	mov	r4, r3
	b	.L347
.L64:				;div
	cmp	sl, #0
	beq	.L337
	mov	r1, sl
	ldr	r0, [sp, #4]
	str	r3, [sp, #0]
	bl	__aeabi_idiv
	ldr	r2, [sp, #0]
	mov	r4, r2
	mov	sl, r0
	b	.L347
.L65:				;mod
	cmp	sl, #0
	beq	.L337
	mov	r1, sl
	ldr	r0, [sp, #4]
	str	r3, [sp, #0]
	bl	__aeabi_idivmod
	ldr	ip, [sp, #0]
	mov	r4, ip
	mov	sl, r1
	b	.L347
.L66:
	ldr	r1, [sp, #4]
	mov	r4, r3
	eor	sl, sl, r1
	b	.L347
.L67:
	ldrsb	r2, [r5, r3]
	add	r4, r3, #1
	add	r0, r2, r3
	mov	ip, r0, asr #2
	str	sl, [r5, ip, asl #2]
	b	.L347
.L68:
	ldrb	r2, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #1
	add	r3, r2, r3, asr #1
	mov	ip, r3, asl #1
	ldrsh	r0, [r5, ip]
	add	r2, r0, ip
	mov	r3, r2, asr #2
	str	sl, [r5, r3, asl #2]
	b	.L347
.L69:
	ldrsb	r0, [r5, r3]
	str	sl, [sp, #4]
	add	sl, r0, r3
	mov	ip, sl, asr #2
	add	r4, r3, #1
	ldr	sl, [r5, ip, asl #2]
	b	.L347
.L70:
	ldrb	r1, [r5, r3]	@ zero_extendqisi2
	str	sl, [sp, #4]
	add	r4, r1, r3, asr #1
	mov	r2, r4, asl #1
	ldrsh	r1, [r5, r2]
	add	r4, r3, #1
	add	r0, r1, r2
	mov	sl, r0, asr #2
	ldr	sl, [r5, sl, asl #2]
	b	.L347
.L71:
	ldr	r1, [sp, #4]
	cmp	r1, sl
	ldrnesb	r4, [r5, r3]
	moveq	sl, r1
	addne	r4, r4, r3
	addeq	r4, r3, #1
	b	.L347
.L72:
	ldr	ip, [sp, #4]
	cmp	ip, sl
	addeq	r4, r3, #1
	moveq	sl, ip
	bne	.L197
	b	.L347
.L73:
	cmp	sl, #0
	ldrnesb	r4, [r5, r3]
	addeq	r4, r3, #1
	addne	r4, r4, r3
	b	.L347
.L74:
	cmp	sl, #0
	addeq	r4, r3, #1
	beq	.L347
	b	.L197
.L75:
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #1
	ldr	r3, [sp, #8]
	str	sl, [sp, #4]
	add	sl, r0, r3
	b	.L347
.L76:
	add	ip, r5, r3
	ldrb	r1, [ip, #1]	@ zero_extendqisi2
	ldrb	r4, [r5, r3]	@ zero_extendqisi2
	str	sl, [sp, #4]
	orr	sl, r4, r1, asl #8
	ldr	r1, [sp, #8]
	add	r4, r3, #2
	add	sl, sl, r1
	b	.L347
.L77:
	add	r2, r5, r3
	ldrb	r0, [r2, #3]	@ zero_extendqisi2
	ldrb	r1, [r2, #2]	@ zero_extendqisi2
	ldrb	ip, [r2, #1]	@ zero_extendqisi2
	orr	r4, r1, r0, asl #8
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	orr	r1, ip, r4, asl #8
	add	r4, r3, #4
	ldr	r3, [sp, #8]
	orr	r2, r0, r1, asl #8
	str	sl, [sp, #4]
	add	sl, r2, r3
	b	.L347
.L78:
	ldr	r0, [sp, #8]
	ldr	r1, [sp, #16]
	add	ip, r0, #3
	mov	r2, ip
	str	ip, [sp, #8]
	str	r1, [fp, #12]
.L310:
	mov	fp, r2, asl #2
	str	fp, [sp, #16]
	add	r2, r3, #1
	add	fp, r5, fp
	str	r2, [fp, #4]
	ldr	ip, [sp, #88]
	ldrb	r3, [r5, r3]	@ zero_extendqisi2
	b	.L358
.L79:
	ldr	r4, [sp, #16]
	str	r4, [fp, #16]
	ldr	fp, [sp, #8]
	add	r2, fp, #4
	str	r2, [sp, #8]
	b	.L310
.L80:
	ldr	r0, [sp, #8]
	ldr	r1, [sp, #16]
	str	r1, [fp, #20]
	add	r1, r0, #5
	str	r1, [sp, #8]
	mov	r2, r1
	b	.L310
.L81:
	ldr	r4, [sp, #8]
	ldr	ip, [sp, #16]
	str	ip, [fp, #24]
	add	fp, r4, #6
	str	fp, [sp, #8]
	mov	r2, fp
	b	.L310
.L82:
	ldr	r1, [sp, #8]
	ldr	r2, [sp, #16]
	add	r1, r1, #7
	str	r2, [fp, #28]
	str	r1, [sp, #8]
	mov	r2, r1
	b	.L310
.L83:
	ldr	ip, [sp, #8]
	ldr	r0, [sp, #16]
	add	r4, ip, #8
	str	r0, [fp, #32]
	mov	r2, r4
	str	r4, [sp, #8]
	b	.L310
.L84:
	ldr	r2, [sp, #16]
	str	r2, [fp, #36]
	ldr	fp, [sp, #8]
	add	r1, fp, #9
	str	r1, [sp, #8]
	mov	r2, r1
	b	.L310
.L85:
	ldr	ip, [sp, #8]
	ldr	r0, [sp, #16]
	add	r4, ip, #10
	str	r0, [fp, #40]
	mov	r2, r4
	str	r4, [sp, #8]
	b	.L310
.L86:
	ldr	r2, [sp, #8]
	ldr	r1, [sp, #16]
	str	r1, [fp, #44]
	add	r1, r2, #11
	str	r1, [sp, #8]
	mov	r2, r1
	b	.L310
.L87:
	ldrb	r2, [r5, r3]	@ zero_extendqisi2
	ldr	r0, [sp, #88]
	add	r4, r3, #1
	ldr	r3, [r0, r2, asl #2]
	str	sl, [r5, r3, asl #2]
	b	.L347
.L88:
	ldrb	r4, [r5, r3]	@ zero_extendqisi2
	ldr	ip, [sp, #88]
	str	sl, [sp, #4]
	ldr	sl, [ip, r4, asl #2]
	add	r4, r3, #1
	ldr	sl, [r5, sl, asl #2]
	b	.L347
.L89:
	ldrb	r2, [r5, r3]	@ zero_extendqisi2
	str	sl, [sp, #4]
	ldr	sl, [sp, #88]
	add	r4, r3, #1
	ldr	r0, [sl, r2, asl #2]
	add	r3, r0, #1
	ldr	sl, [r5, r3, asl #2]
	b	.L347
.L90:
	ldrb	r4, [r5, r3]	@ zero_extendqisi2
	ldr	r1, [sp, #88]
	str	sl, [sp, #4]
	ldr	r0, [r1, r4, asl #2]
	add	r4, r3, #1
	add	ip, r0, #2
	ldr	sl, [r5, ip, asl #2]
	b	.L347
.L91:
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	ldr	r0, [sp, #88]
	str	sl, [sp, #4]
	add	r4, r3, #1
	ldr	sl, [r0, ip, asl #2]
	b	.L347
.L92:
	ldrb	r2, [r5, r3]	@ zero_extendqisi2
	ldr	r0, [sp, #88]
	add	r4, r3, #1
	str	sl, [r0, r2, asl #2]
	b	.L347
.L93:
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #1
	ldr	r3, [sp, #76]
	str	sl, [sp, #4]
	add	sl, r3, r0
	b	.L347
.L94:
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	ldr	r0, [sp, #88]
	add	r4, r3, #1
	ldr	r3, [r0, ip, asl #2]
	add	sl, sl, r3
	b	.L347
.L95:
	ldr	r0, [sp, #4]
	mov	r4, r3
	add	sl, sl, r0
	b	.L347
.L96:
	ldr	r4, [sp, #4]
	rsb	sl, sl, r4
	mov	r4, r3
	b	.L347
.L97:
	cmp	sl, #31
	ldrle	r1, [sp, #4]
	movgt	sl, #0
	movle	sl, r1, asl sl
	strgt	sl, [sp, #4]
	mov	r4, r3
	b	.L347
.L98:
	cmp	sl, #31
	ldrle	r2, [sp, #4]
	movgt	sl, #0
	movle	sl, r2, lsr sl
	strgt	sl, [sp, #4]
	mov	r4, r3
	b	.L347
.L99:
	ldr	r2, [sp, #4]
	mov	r4, r3
	and	sl, sl, r2
	b	.L347
.L100:
	ldr	ip, [sp, #4]
	mov	r4, r3
	orr	sl, sl, ip
	b	.L347
.L101:
	ldrsb	r2, [r5, r3]
	add	r4, r3, #1
	add	r0, r2, r3
	str	sl, [sp, #4]
	mov	sl, r0, asr #2
	b	.L347
.L102:
	ldrb	r1, [r5, r3]	@ zero_extendqisi2
	str	sl, [sp, #4]
	add	r4, r1, r3, asr #1
	mov	ip, r4, asl #1
	ldrsh	r1, [r5, ip]
	add	r4, r3, #1
	add	sl, r1, ip
	mov	sl, sl, asr #2
	b	.L347
.L103:
	ldr	r2, [sp, #4]
	cmp	sl, r2
	ldrgtsb	r4, [r5, r3]
	addle	r4, r3, #1
	addgt	r4, r4, r3
	b	.L347
.L104:
	ldr	r0, [sp, #4]
	cmp	sl, r0
	addle	r4, r3, #1
	ble	.L347
	b	.L197
.L105:
	cmp	sl, #0
	ldrltsb	r4, [r5, r3]
	addge	r4, r3, #1
	addlt	r4, r4, r3
	b	.L347
.L106:
	cmp	sl, #0
	addge	r4, r3, #1
	bge	.L347
	b	.L197
.L107:
	str	sl, [sp, #4]
	add	r4, r3, #1
	ldrb	sl, [r5, r3]	@ zero_extendqisi2
	b	.L347
.L108:
	add	r4, r5, r3
	ldrb	r1, [r4, #1]	@ zero_extendqisi2
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #2
	str	sl, [sp, #4]
	orr	sl, ip, r1, asl #8
	b	.L347
.L109:
	add	r2, r5, r3
	ldrb	r4, [r2, #2]	@ zero_extendqisi2
	ldrb	ip, [r2, #3]	@ zero_extendqisi2
	ldrb	r1, [r2, #1]	@ zero_extendqisi2
	orr	r0, r4, ip, asl #8
	ldrb	r2, [r5, r3]	@ zero_extendqisi2
	orr	r1, r1, r0, asl #8
	str	sl, [sp, #4]
	add	r4, r3, #4
	orr	sl, r2, r1, asl #8
	b	.L347
.L110:
	ldr	r4, [sp, #8]
	ldr	r1, [sp, #16]
	add	r2, r4, #3
	str	r2, [sp, #8]
	str	r1, [fp, #12]
.L309:
	mov	fp, r2, asl #2
	str	fp, [sp, #16]
	add	r1, r3, #2
	add	r0, r5, r3
	add	fp, r5, fp
	str	r1, [fp, #4]
	ldrb	ip, [r0, #1]	@ zero_extendqisi2
	ldrb	r3, [r5, r3]	@ zero_extendqisi2
	orr	r3, r3, ip, asl #8
	b	.L356
.L111:
	ldr	ip, [sp, #8]
	ldr	r0, [sp, #16]
	add	r4, ip, #4
	str	r0, [fp, #16]
	mov	r2, r4
	str	r4, [sp, #8]
	b	.L309
.L112:
	ldr	r1, [sp, #8]
	ldr	r2, [sp, #16]
	str	r2, [fp, #20]
	add	fp, r1, #5
	str	fp, [sp, #8]
	mov	r2, fp
	b	.L309
.L113:
	ldr	ip, [sp, #8]
	ldr	r0, [sp, #16]
	add	r4, ip, #6
	str	r0, [fp, #24]
	mov	r2, r4
	str	r4, [sp, #8]
	b	.L309
.L114:
	ldr	r1, [sp, #8]
	ldr	r2, [sp, #16]
	str	r2, [fp, #28]
	add	fp, r1, #7
	str	fp, [sp, #8]
	mov	r2, fp
	b	.L309
.L115:
	ldr	ip, [sp, #8]
	ldr	r0, [sp, #16]
	add	r4, ip, #8
	str	r0, [fp, #32]
	mov	r2, r4
	str	r4, [sp, #8]
	b	.L309
.L116:
	ldr	r1, [sp, #8]
	ldr	r2, [sp, #16]
	str	r2, [fp, #36]
	add	fp, r1, #9
	str	fp, [sp, #8]
	mov	r2, fp
	b	.L309
.L117:
	ldr	ip, [sp, #8]
	ldr	r0, [sp, #16]
	add	r4, ip, #10
	str	r0, [fp, #40]
	mov	r2, r4
	str	r4, [sp, #8]
	b	.L309
.L118:
	ldr	r1, [sp, #8]
	ldr	r2, [sp, #16]
	str	r2, [fp, #44]
	add	fp, r1, #11
	str	fp, [sp, #8]
	mov	r2, fp
	b	.L309
.L119:
	add	r1, r5, r3
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	ldrb	r1, [r1, #1]	@ zero_extendqisi2
	ldr	r0, [sp, #68]
	orr	r2, ip, r1, asl #8
	add	r4, r3, #2
	ldr	r3, [r0, r2, asl #2]
	str	sl, [r5, r3, asl #2]
	b	.L347
.L120:
	add	r1, r5, r3
	ldrb	r4, [r5, r3]	@ zero_extendqisi2
	ldrb	r1, [r1, #1]	@ zero_extendqisi2
	ldr	r2, [sp, #68]
	orr	r0, r4, r1, asl #8
	ldr	ip, [r2, r0, asl #2]
	str	sl, [sp, #4]
	add	r4, r3, #2
	ldr	sl, [r5, ip, asl #2]
	b	.L347
.L121:
	add	r4, r5, r3
	ldrb	r1, [r4, #1]	@ zero_extendqisi2
	ldrb	r2, [r5, r3]	@ zero_extendqisi2
	ldr	r0, [sp, #68]
	orr	ip, r2, r1, asl #8
	str	sl, [sp, #4]
	ldr	sl, [r0, ip, asl #2]
	add	r4, r3, #2
	add	r3, sl, #1
	ldr	sl, [r5, r3, asl #2]
	b	.L347
.L122:
	add	r2, r5, r3
	ldrb	r1, [r2, #1]	@ zero_extendqisi2
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	str	sl, [sp, #4]
	orr	ip, r0, r1, asl #8
	ldr	r1, [sp, #68]
	add	r4, r3, #2
	ldr	sl, [r1, ip, asl #2]
	add	r3, sl, #2
	ldr	sl, [r5, r3, asl #2]
	b	.L347
.L123:
	add	r1, r5, r3
	ldrb	r4, [r5, r3]	@ zero_extendqisi2
	ldrb	r1, [r1, #1]	@ zero_extendqisi2
	str	sl, [sp, #4]
	orr	sl, r4, r1, asl #8
	add	r4, r3, #2
	ldr	r3, [sp, #68]
	ldr	sl, [r3, sl, asl #2]
	b	.L347
.L124:
	add	r4, r5, r3
	ldrb	r1, [r4, #1]	@ zero_extendqisi2
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #2
	ldr	r3, [sp, #68]
	orr	r0, ip, r1, asl #8
	str	sl, [r3, r0, asl #2]
	b	.L347
.L125:
	add	r2, r5, r3
	ldrb	r1, [r2, #1]	@ zero_extendqisi2
	ldrb	r4, [r5, r3]	@ zero_extendqisi2
	str	sl, [sp, #4]
	orr	sl, r4, r1, asl #8
	ldr	r1, [sp, #60]
	add	r4, r3, #2
	add	sl, sl, r1
	b	.L347
.L126:
	add	r1, r5, r3
	ldrb	r2, [r5, r3]	@ zero_extendqisi2
	ldrb	r1, [r1, #1]	@ zero_extendqisi2
	ldr	ip, [sp, #68]
	orr	r0, r2, r1, asl #8
	add	r4, r3, #2
	ldr	r3, [ip, r0, asl #2]
	add	sl, sl, r3
	b	.L347
.L127:
	ldr	sl, [r5, sl, asl #2]
	mov	r4, r3
	b	.L347
.L128:
	add	sl, sl, #1
	ldr	sl, [r5, sl, asl #2]
	mov	r4, r3
	b	.L347
.L129:
	add	ip, sl, #2
	ldr	sl, [r5, ip, asl #2]
	mov	r4, r3
	b	.L347
.L130:
	add	r2, sl, #3
	ldr	sl, [r5, r2, asl #2]
	mov	r4, r3
	b	.L347
.L131:
	add	r4, sl, #4
	ldr	sl, [r5, r4, asl #2]
	mov	r4, r3
	b	.L347
.L132:
	add	r0, sl, #5
	ldr	sl, [r5, r0, asl #2]
	mov	r4, r3
	b	.L347
.L165:
	ldr	ip, [fp, #20]
	mov	r4, r3
	add	r2, sl, ip
	ldr	r3, [sp, #4]
	str	r3, [r5, r2, asl #2]
	b	.L347
.L328:
	mov	r4, sl
	b	.L347
.L166:
	ldr	r2, [sp, #4]
	cmp	sl, r2
	ldrgesb	r4, [r5, r3]
	addlt	r4, r3, #1
	addge	r4, r4, r3
	b	.L347
.L167:
	ldr	r0, [sp, #4]
	cmp	sl, r0
	addlt	r4, r3, #1
	blt	.L347
	b	.L197
.L168:
	cmp	sl, #0
	ldrlesb	r4, [r5, r3]
	addgt	r4, r3, #1
	addle	r4, r4, r3
	b	.L347
.L169:
	cmp	sl, #0
	addgt	r4, r3, #1
	bgt	.L347
	b	.L197
.L170:
	ldrb	ip, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #1
	str	sl, [fp, ip, asl #2]
	b	.L347
.L171:
	add	r4, r5, r3
	ldrb	r1, [r4, #1]	@ zero_extendqisi2
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #2
	orr	r3, r0, r1, asl #8
	str	sl, [fp, r3, asl #2]
	b	.L347
.L172:
	add	r2, r5, r3
	ldrb	ip, [r2, #3]	@ zero_extendqisi2
	ldrb	r0, [r2, #2]	@ zero_extendqisi2
	ldrb	r1, [r2, #1]	@ zero_extendqisi2
	ldrb	r4, [r5, r3]	@ zero_extendqisi2
	orr	ip, r0, ip, asl #8
	orr	r1, r1, ip, asl #8
	orr	r2, r4, r1, asl #8
	str	sl, [fp, r2, asl #2]
	add	r4, r3, #4
	b	.L347
.L173:
	str	sl, [fp, #12]
	mov	r4, r3
	b	.L347
.L174:
	str	sl, [fp, #16]
	mov	r4, r3
	b	.L347
.L175:
	str	sl, [fp, #20]
	mov	r4, r3
	b	.L347
.L176:
	str	sl, [fp, #24]
	mov	r4, r3
	b	.L347
.L177:
	str	sl, [fp, #28]
	mov	r4, r3
	b	.L347
.L178:
	str	sl, [fp, #32]
	mov	r4, r3
	b	.L347
.L179:
	str	sl, [fp, #36]
	mov	r4, r3
	b	.L347
.L180:
	str	sl, [fp, #40]
	mov	r4, r3
	b	.L347
.L181:
	str	sl, [fp, #44]
	mov	r4, r3
	b	.L347
.L182:
	str	sl, [fp, #48]
	mov	r4, r3
	b	.L347
.L183:
	str	sl, [fp, #52]
	mov	r4, r3
	b	.L347
.L184:
	str	sl, [fp, #56]
	mov	r4, r3
	b	.L347
.L185:
	str	sl, [fp, #60]
	mov	r4, r3
	b	.L347
.L186:
	str	sl, [fp, #64]
	mov	r4, r3
	b	.L347
.L187:
	sub	sl, sl, #1
	mov	r4, r3
	b	.L347
.L188:
	sub	sl, sl, #2
	mov	r4, r3
	b	.L347
.L189:
	sub	sl, sl, #3
	mov	r4, r3
	b	.L347
.L190:
	sub	sl, sl, #4
	mov	r4, r3
	b	.L347
.L191:
	ldr	r4, [sp, #4]
	eor	sl, r4, sl
	eor	ip, r4, sl
	str	ip, [sp, #4]
	eor	sl, ip, sl
	mov	r4, r3
	b	.L347
.L192:
	ldr	r2, [sp, #4]
	add	sl, r5, sl
	ldrb	sl, [sl, r2, asl #2]	@ zero_extendqisi2
	mov	r4, r3
	b	.L347
.L193:
	ldr	r0, [sp, #4]
	add	ip, r5, sl
	ldr	r1, [sp, #72]
	strb	r1, [ip, r0, asl #2]
	mov	r4, r3
	b	.L347
.L194:
	mov	r4, r3
	str	sl, [sp, #72]
	b	.L347
.L195:
	mov	r4, r3
	str	sl, [sp, #4]
	b	.L347
.L149:
	str	sl, [sp, #4]
	mov	r4, r3
	ldr	sl, [fp, #40]
	b	.L347
.L150:
	str	sl, [sp, #4]
	mov	r4, r3
	ldr	sl, [fp, #44]
	b	.L347
.L151:
	str	sl, [sp, #4]
	mov	r4, r3
	ldr	sl, [fp, #48]
	b	.L347
.L152:
	str	sl, [sp, #4]
	mov	r4, r3
	ldr	sl, [fp, #52]
	b	.L347
.L153:
	str	sl, [sp, #4]
	mov	r4, r3
	ldr	sl, [fp, #56]
	b	.L347
.L154:
	str	sl, [sp, #4]
	mov	r4, r3
	ldr	sl, [fp, #60]
	b	.L347
.L155:
	str	sl, [sp, #4]
	mov	r4, r3
	ldr	sl, [fp, #64]
	b	.L347
.L156:
	cmp	sl, #0
	beq	.L307
	cmp	sl, #5
	beq	.L308
	cmn	sl, #1
	beq	.L306
	add	r0, sp, #92
	ldmia	r0, {r0, ip, lr}	@ phole ldm
	ldr	r4, [sp, #104]
	str	sl, [r0, #0]
	ldr	r1, [sp, #4]
	ldr	sl, [sp, #72]
	ldr	r2, [sp, #16]
	ldr	r0, [sp, #8]
	str	r1, [ip, #0]
	ldr	r1, [sp, #60]
	str	sl, [lr, #0]
	str	r2, [r4, #0]
	ldr	sl, [sp, #108]
	ldr	r2, [sp, #112]
	ldr	ip, [sp, #64]
	ldr	lr, [sp, #80]
	str	ip, [sl, #0]
	ldr	r4, [sp, #116]
	str	lr, [r2, #0]
	ldr	ip, [sp, #120]
	ldr	lr, [sp, #124]
	ldr	sl, [sp, #84]
	str	r3, [r4, #0]
	str	r7, [ip, #0]
	str	sl, [lr, #0]
	str	r3, [sp, #0]
	bl	dosys
	ldr	r1, [sp, #0]
	mov	r4, r1
	mov	sl, r0
	b	.L347
.L157:
	add	r2, r3, #1
	mov	r0, r2, asr #1
	mov	r3, r0, asl #1
	ldrh	ip, [r5, r3]
	mov	r3, #1
.L296:
	cmp	ip, r3
	blt	.L298
	mov	r3, r3, asl #1
	add	r2, r3, r0
	mov	r1, r2, asl #1
	ldrh	r1, [r5, r1]
	cmp	sl, r1
	beq	.L302
.L297:
	blt	.L299
	cmp	ip, r3
	mov	r3, r3, asl #1
	add	r2, r3, r0
	mov	r1, r2, asl #1
	blt	.L298
	ldrh	r1, [r5, r1]
	cmp	sl, r1
	bne	.L297
.L302:
	mov	r0, r2
.L298:
	add	r4, r0, #1
	mov	ip, r4, asl #1
	ldrsh	r0, [r5, ip]
	add	r4, r0, ip
	b	.L347
.L158:
	add	r3, r3, #1
	mov	r4, r3, asr #1
	mov	r2, r4, asl #1
	ldrh	ip, [r5, r2]
	add	r0, r4, #1
	cmp	sl, ip
	movge	ip, #0
	movlt	ip, #1
	cmp	sl, #0
	movlt	ip, #0
	cmp	ip, #0
	addne	ip, sl, #1
	addne	r0, r0, ip
	mov	r3, r0, asl #1
	ldrsh	r2, [r5, r3]
	add	r4, r2, r3
	b	.L347
.L161:
	add	r2, sl, #2
	ldr	ip, [sp, #4]
	str	ip, [r5, r2, asl #2]
	mov	r4, r3
	b	.L347
.L162:
	ldr	r4, [sp, #4]
	add	r0, sl, #3
	str	r4, [r5, r0, asl #2]
	mov	r4, r3
	b	.L347
.L163:
	ldr	r2, [fp, #12]
	mov	r4, r3
	add	r0, sl, r2
	ldr	r3, [sp, #4]
	str	r3, [r5, r0, asl #2]
	b	.L347
.L164:
	ldr	ip, [fp, #16]
	ldr	r2, [sp, #4]
	add	r0, sl, ip
	mov	r4, r3
	str	r2, [r5, r0, asl #2]
	b	.L347
.L159:
	ldr	r4, [sp, #4]
	str	r4, [r5, sl, asl #2]
	mov	r4, r3
	b	.L347
.L160:
	add	r0, sl, #1
	ldr	r1, [sp, #4]
	str	r1, [r5, r0, asl #2]
	mov	r4, r3
	b	.L347
.L141:
	add	r2, r5, r3
	ldrb	ip, [r2, #3]	@ zero_extendqisi2
	ldrb	r1, [r2, #2]	@ zero_extendqisi2
	ldrb	r4, [r2, #1]	@ zero_extendqisi2
	orr	r0, r1, ip, asl #8
	ldrb	r2, [r5, r3]	@ zero_extendqisi2
	orr	r1, r4, r0, asl #8
	orr	ip, r2, r1, asl #8
	str	sl, [sp, #4]
	add	r4, r3, #4
	ldr	sl, [fp, ip, asl #2]
	b	.L347
.L142:
	str	sl, [sp, #4]
	mov	r4, r3
	ldr	sl, [fp, #12]
	b	.L347
.L143:
	str	sl, [sp, #4]
	mov	r4, r3
	ldr	sl, [fp, #16]
	b	.L347
.L144:
	str	sl, [sp, #4]
	mov	r4, r3
	ldr	sl, [fp, #20]
	b	.L347
.L145:
	str	sl, [sp, #4]
	mov	r4, r3
	ldr	sl, [fp, #24]
	b	.L347
.L146:
	str	sl, [sp, #4]
	mov	r4, r3
	ldr	sl, [fp, #28]
	b	.L347
.L147:
	str	sl, [sp, #4]
	mov	r4, r3
	ldr	sl, [fp, #32]
	b	.L347
.L148:
	str	sl, [sp, #4]
	mov	r4, r3
	ldr	sl, [fp, #36]
	b	.L347
.L137:
	cmp	sl, #0
	ldrgtsb	r4, [r5, r3]
	addle	r4, r3, #1
	addgt	r4, r4, r3
	b	.L347
.L139:
	ldrb	r0, [r5, r3]	@ zero_extendqisi2
	add	r4, r3, #1
	str	sl, [sp, #4]
	ldr	sl, [fp, r0, asl #2]
	b	.L347
.L140:
	add	r1, r5, r3
	ldrb	r4, [r5, r3]	@ zero_extendqisi2
	ldrb	r1, [r1, #1]	@ zero_extendqisi2
	str	sl, [sp, #4]
	orr	sl, r4, r1, asl #8
	ldr	sl, [fp, sl, asl #2]
	add	r4, r3, #2
	b	.L347
.L135:
	ldr	r1, [sp, #4]
	cmp	sl, r1
	ldrltsb	r4, [r5, r3]
	addge	r4, r3, #1
	addlt	r4, r4, r3
	b	.L347
.L136:
	ldr	ip, [sp, #4]
	cmp	sl, ip
	addge	r4, r3, #1
	bge	.L347
	b	.L197
.L133:
	add	sl, sl, #6
	ldr	sl, [r5, sl, asl #2]
	mov	r4, r3
	b	.L347
.L196:
	ldrsb	r4, [r5, r3]
	add	r4, r4, r3
	b	.L347
.L325:
	ldr	r1, [sp, #8]
	mov	r0, #4
	mov	r8, r1, asl #2
	str	r8, [sp, #16]
	ldr	r8, .L366
	b	.L2
.L299:
	add	r3, r3, #1
	b	.L296
.L340:
	mov	r0, #1
	mov	r1, #0
	mov	r2, r3
	strd	r0, [sp, #128]
	b	.L295
.L307:
	ldr	r0, [fp, #16]
	mov	r4, r3
	b	.L2
.L266:
	mov	r1, sl
	mov	r2, #0
	str	r3, [sp, #0]
	bl	doflt
	ldr	r4, [sp, #0]
	mov	sl, r0
	b	.L347
.L265:
	ldrb	r2, [r5, r3]	@ zero_extendqisi2
	mov	r1, sl
	cmp	r2, #127
	subgt	r2, r2, #256
	add	r4, r3, #1
	bl	doflt
	mov	sl, r0
	b	.L347
.L330:
	mov	r4, r3
	mvn	sl, #0
	b	.L347
.L329:
	mov	r0, #13
	b	.L2
.L267:
	ldr	r1, [sp, #4]
	mov	r2, sl
	str	r3, [sp, #0]
	bl	doflt
	ldr	r1, [sp, #0]
	mov	r4, r1
	mov	sl, r0
	b	.L347
.L333:
	ldr	r0, [sp, #4]
.L273:
	eor	r0, r0, r3
	ldr	r3, [sp, #148]
	ldr	r1, [sp, #128]
	ldr	ip, [sp, #140]
	and	r2, r0, r3
	eor	r3, ip, r2, asl r1
	ldr	r1, [sp, #144]
	str	r3, [r5, r1]
	b	.L347
.L332:
	mov	sl, #0
	b	.L347
.L289:
	ldr	r0, [sp, #4]
	eor	r0, r3, r0
	b	.L273
.L288:
	ldr	r1, [sp, #4]
	eor	ip, r3, r1
	mvn	r0, ip
	b	.L273
.L287:
	ldr	r2, [sp, #4]
	orr	r0, r3, r2
	b	.L273
.L286:
	ldr	r0, [sp, #4]
	and	r0, r3, r0
	b	.L273
.L285:
	ldr	r1, [sp, #4]
	cmp	r1, #31
	movle	r0, r3
	movgt	r0, #0
	mov	r0, r0, lsr r1
	b	.L273
.L284:
	ldr	ip, [sp, #4]
	cmp	ip, #31
	movle	r0, r3
	movgt	r0, #0
	mov	r0, r0, asl ip
	b	.L273
.L283:
	ldr	r2, [sp, #4]
	rsb	r0, r2, r3
	b	.L273
.L282:
	ldr	r0, [sp, #4]
	add	r0, r3, r0
	b	.L273
.L281:
	mov	r0, r3
	ldr	r1, [sp, #4]
	str	r3, [sp, #0]
	bl	__aeabi_idivmod
	ldr	r3, [sp, #0]
	mov	r0, r1
	b	.L273
.L280:
	mov	r0, r3
	ldr	r1, [sp, #4]
	str	r3, [sp, #0]
	bl	__aeabi_idiv
	ldr	r3, [sp, #0]
	b	.L273
.L279:
	ldr	r1, [sp, #4]
	mul	r0, r1, r3
	b	.L273
.L278:
	mov	r0, r3
	ldr	r1, [sp, #4]	@ float
	str	r3, [sp, #0]
	bl	__aeabi_fsub
	ldr	r3, [sp, #0]
	b	.L273
.L277:
	mov	r0, r3
	ldr	r1, [sp, #4]	@ float
	str	r3, [sp, #0]
	bl	__aeabi_fadd
	ldr	r3, [sp, #0]
	b	.L273
.L276:
	mov	r0, r3
	ldr	r1, [sp, #4]	@ float
	str	r3, [sp, #0]
	bl	__aeabi_fdiv
	ldr	r3, [sp, #0]
	b	.L273
.L275:
	mov	r0, r3
	ldr	r1, [sp, #4]	@ float
	str	r3, [sp, #0]
	bl	__aeabi_fmul
	ldr	r3, [sp, #0]
	b	.L273
.L274:
	ldr	ip, [sp, #4]
	add	r2, r3, ip
	ldr	r0, [r5, r2, asl #2]
	b	.L273
.L306:
	mov	sl, r7
	mov	r4, r3
	ldr	r7, [fp, #16]
	mvn	r0, #0
	b	.L2
.L308:
	ldr	r2, [fp, #16]
	ldr	ip, .L366+4
	ldr	r0, [r5, r2, asl #2]
	mov	r4, r3
	add	r3, r5, r2, asl #2
	str	r3, [ip, #0]
	str	r0, [ip, #4]
	b	.L347
.L363:
	mov	r4, sl
	mov	r0, #4
	mov	sl, r3
	b	.L2
.L353:
	mov	r4, sl
	mov	r0, #4
	mov	sl, r2
	b	.L2
.L337:
	mov	r0, #5
	b	.L2
.L367:
	.align	2
.L366:
	.word	tracing
	.word	.LANCHOR0
	.fnend
	.size	interpret, .-interpret
	.global	watchaddr
	.global	watchval
	.bss
	.align	2
.LANCHOR0 = . + 0
	.type	watchaddr, %object
	.size	watchaddr, 4
watchaddr:
	.space	4
	.type	watchval, %object
	.size	watchval, 4
watchval:
	.space	4
	.ident	"GCC: (Sourcery G++ Lite 2011.03-41) 4.5.2"
	.section	.note.GNU-stack,"",%progbits
