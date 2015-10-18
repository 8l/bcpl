	.file	"cintsys.c"
	.text
	.p2align 4,,15
	.globl	mcprf
	.type	mcprf, @function
mcprf:
.LFB113:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	36(%esp), %eax
	movl	$1, (%esp)
	movl	%eax, 8(%esp)
	movl	32(%esp), %eax
	movl	%eax, 4(%esp)
	call	__printf_chk
	xorl	%eax, %eax
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
.LFE113:
	.size	mcprf, .-mcprf
	.p2align 4,,15
	.globl	sysGraphics
	.type	sysGraphics, @function
sysGraphics:
.LFB103:
	.cfi_startproc
	xorl	%eax, %eax
	ret
	.cfi_endproc
.LFE103:
	.size	sysGraphics, .-sysGraphics
	.p2align 4,,15
	.globl	badimplementation
	.type	badimplementation, @function
badimplementation:
.LFB104:
	.cfi_startproc
	xorl	%eax, %eax
	ret
	.cfi_endproc
.LFE104:
	.size	badimplementation, .-badimplementation
	.p2align 4,,15
	.globl	initfpvec
	.type	initfpvec, @function
initfpvec:
.LFB105:
	.cfi_startproc
	xorl	%eax, %eax
	ret
	.cfi_endproc
.LFE105:
	.size	initfpvec, .-initfpvec
	.p2align 4,,15
	.globl	newfno
	.type	newfno, @function
newfno:
.LFB106:
	.cfi_startproc
	movl	4(%esp), %eax
	ret
	.cfi_endproc
.LFE106:
	.size	newfno, .-newfno
	.p2align 4,,15
	.globl	freefno
	.type	freefno, @function
freefno:
.LFB107:
	.cfi_startproc
	movl	4(%esp), %eax
	ret
	.cfi_endproc
.LFE107:
	.size	freefno, .-freefno
	.p2align 4,,15
	.globl	findfp
	.type	findfp, @function
findfp:
.LFB108:
	.cfi_startproc
	movl	4(%esp), %eax
	ret
	.cfi_endproc
.LFE108:
	.size	findfp, .-findfp
	.p2align 4,,15
	.globl	inbuf_next
	.type	inbuf_next, @function
inbuf_next:
.LFB111:
	.cfi_startproc
	movl	idx.6086, %edx
	movl	inbuf, %eax
	movsbl	(%eax,%edx), %eax
	testl	%eax, %eax
	je	.L10
	addl	$1, %edx
	movl	%edx, idx.6086
	ret
	.p2align 4,,7
	.p2align 3
.L10:
	movl	$-1, %eax
	ret
	.cfi_endproc
.LFE111:
	.size	inbuf_next, .-inbuf_next
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"malloc"
	.text
	.p2align 4,,15
	.globl	prepend_stdin
	.type	prepend_stdin, @function
prepend_stdin:
.LFB112:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	xorl	%eax, %eax
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$44, %esp
	.cfi_def_cfa_offset 64
	movl	64(%esp), %ecx
	movl	68(%esp), %esi
	movl	76(%esp), %ebx
	movl	72(%esp), %ebp
	testl	%ecx, %ecx
	setne	%al
	addl	%esi, %eax
	subl	%ebx, %eax
	cmpl	$1, %eax
	movl	%eax, 24(%esp)
	je	.L12
	movl	64(%esp), %edx
	xorl	%edi, %edi
	testl	%edx, %edx
	je	.L14
	movl	64(%esp), %eax
	movl	%eax, (%esp)
	call	strlen
	movl	%eax, %edi
.L14:
	addl	$1, %ebx
	cmpl	%ebx, %esi
	movl	%ebx, 28(%esp)
	jle	.L15
	.p2align 4,,7
	.p2align 3
.L16:
	movl	0(%ebp,%ebx,4), %eax
	addl	$1, %ebx
	movl	%eax, (%esp)
	call	strlen
	addl	%eax, %edi
	cmpl	%esi, %ebx
	jne	.L16
.L15:
	addl	24(%esp), %edi
	movl	%edi, (%esp)
	call	malloc
	testl	%eax, %eax
	movl	%eax, %ebx
	movl	%eax, inbuf
	je	.L26
	movb	$0, (%eax)
	movl	%eax, %edi
	movl	64(%esp), %eax
	testl	%eax, %eax
	je	.L19
	movl	64(%esp), %eax
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	strcat
.L19:
	cmpl	28(%esp), %esi
	jle	.L20
	movl	28(%esp), %edi
	jmp	.L23
	.p2align 4,,7
	.p2align 3
.L21:
	movl	0(%ebp,%edi,4), %eax
	addl	$1, %edi
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	strcat
	cmpl	%esi, %edi
	je	.L22
	movl	inbuf, %ebx
.L23:
	cmpb	$0, (%ebx)
	je	.L21
	movl	%ebx, (%esp)
	call	strlen
	movw	$32, (%ebx,%eax)
	movl	inbuf, %ebx
	jmp	.L21
	.p2align 4,,7
	.p2align 3
.L22:
	movl	inbuf, %edi
.L20:
	movl	%edi, (%esp)
	call	strlen
	movw	$10, (%edi,%eax)
.L12:
	addl	$44, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
.L26:
	.cfi_restore_state
	movl	$.LC0, (%esp)
	call	perror
	movl	$-1, (%esp)
	call	exit
	.cfi_endproc
.LFE112:
	.size	prepend_stdin, .-prepend_stdin
	.p2align 4,,15
	.globl	concatsegs
	.type	concatsegs, @function
concatsegs:
.LFB115:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	movl	16(%esp), %esi
	movl	12(%esp), %eax
	testl	%esi, %esi
	je	.L30
	testl	%eax, %eax
	je	.L30
	movl	W, %ebx
	movl	%eax, %edx
	.p2align 4,,7
	.p2align 3
.L29:
	leal	(%ebx,%edx,4), %ecx
	movl	(%ecx), %edx
	testl	%edx, %edx
	jne	.L29
	movl	%esi, (%ecx)
	popl	%ebx
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 4
	.cfi_restore 6
	ret
	.p2align 4,,7
	.p2align 3
.L30:
	.cfi_restore_state
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
.LFE115:
	.size	concatsegs, .-concatsegs
	.p2align 4,,15
	.globl	rdhex
	.type	rdhex, @function
rdhex:
.LFB119:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$28, %esp
	.cfi_def_cfa_offset 48
	movl	48(%esp), %ebx
	.p2align 4,,7
	.p2align 3
.L34:
	movl	%ebx, (%esp)
	call	fgetc
	cmpl	$10, %eax
	je	.L34
	cmpl	$32, %eax
	je	.L34
	cmpl	$13, %eax
	.p2align 4,,2
	je	.L34
	cmpl	$35, %eax
	.p2align 4,,2
	jne	.L50
.L46:
	movl	%ebx, (%esp)
	call	fgetc
	cmpl	$-1, %eax
	je	.L34
	cmpl	$10, %eax
	je	.L34
	.p2align 4,,5
	jmp	.L46
	.p2align 4,,7
	.p2align 3
.L50:
	xorl	%esi, %esi
	movl	$100, %edi
	jmp	.L36
	.p2align 4,,7
	.p2align 3
.L51:
	leal	-87(%eax), %edx
.L42:
	sall	$4, %esi
	orl	%edx, %esi
	movl	%ebx, (%esp)
	call	fgetc
.L36:
	leal	-48(%eax), %edx
	cmpl	$9, %edx
	leal	-65(%eax), %ebp
	cmova	%edi, %edx
	leal	-55(%eax), %ecx
	cmpl	$5, %ebp
	cmovbe	%ecx, %edx
	leal	-97(%eax), %ecx
	cmpl	$5, %ecx
	jbe	.L51
	cmpl	$100, %edx
	jne	.L42
	cmpl	$-1, %eax
	movl	$-1, %eax
	cmove	%eax, %esi
	addl	$28, %esp
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	movl	%esi, %eax
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE119:
	.size	rdhex, .-rdhex
	.p2align 4,,15
	.globl	globin
	.type	globin, @function
globin:
.LFB120:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$4, %esp
	.cfi_def_cfa_offset 24
	movl	W, %edx
	movl	28(%esp), %edi
	movl	24(%esp), %ebx
	movl	(%edx,%edi,4), %eax
	testl	%ebx, %ebx
	movl	%eax, (%esp)
	je	.L53
	movl	24(%esp), %ebp
	movl	%ebp, %esi
	addl	$1, %esi
	movl	(%edx,%esi,4), %ecx
	sall	$2, %esi
	addl	%ebp, %ecx
	cmpl	(%edx,%ecx,4), %eax
	jl	.L59
	.p2align 4,,7
	.p2align 3
.L54:
	leal	-2(%ecx), %eax
	movl	-4(%edx,%ecx,4), %ecx
	testl	%ecx, %ecx
	je	.L55
	.p2align 4,,7
	.p2align 3
.L60:
	movl	(%edx,%eax,4), %ebx
	addl	%esi, %ecx
	subl	$2, %eax
	addl	%edi, %ebx
	movl	%ecx, (%edx,%ebx,4)
	movl	4(%edx,%eax,4), %ecx
	testl	%ecx, %ecx
	jne	.L60
.L55:
	movl	(%edx,%ebp,4), %ebp
	testl	%ebp, %ebp
	je	.L53
	leal	1(%ebp), %eax
	movl	(%edx,%eax,4), %ecx
	leal	0(,%eax,4), %esi
	movl	(%esp), %eax
	addl	%ebp, %ecx
	cmpl	(%edx,%ecx,4), %eax
	jge	.L54
.L59:
	movl	$0, 24(%esp)
.L53:
	movl	24(%esp), %eax
	addl	$4, %esp
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE120:
	.size	globin, .-globin
	.p2align 4,,15
	.globl	getvec
	.type	getvec, @function
getvec:
.LFB121:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	W, %ecx
	xorl	%edx, %edx
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	movl	20(%esp), %edi
	movl	(%ecx), %eax
	addl	$11, %edi
	andl	$-2, %edi
	jmp	.L73
	.p2align 4,,7
	.p2align 3
.L74:
	testl	%eax, %eax
	je	.L70
	addl	%eax, %edx
	movl	(%ecx,%edx,4), %eax
.L73:
	testb	$1, %al
	leal	(%ecx,%edx,4), %esi
	je	.L74
	movl	%edx, %ebx
	.p2align 4,,7
	.p2align 3
.L67:
	leal	-1(%ebx,%eax), %ebx
	movl	(%ecx,%ebx,4), %eax
	testb	$1, %al
	jne	.L67
	movl	%ebx, %ebp
	subl	%edx, %ebp
	cmpl	%ebp, %edi
	jle	.L75
	movl	%ebx, %edx
	jmp	.L73
	.p2align 4,,7
	.p2align 3
.L70:
	popl	%ebx
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	xorl	%eax, %eax
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
.L75:
	.cfi_restore_state
	leal	(%edi,%edx), %eax
	cmpl	%ebx, %eax
	je	.L76
	subl	%edi, %ebp
	leal	1(%ebp), %ebx
	movl	%ebx, (%ecx,%eax,4)
.L69:
	movl	20(%esp), %ebx
	movl	%edi, (%esi)
	movl	$-858993460, -36(%ecx,%eax,4)
	movl	$1431655765, -32(%ecx,%eax,4)
	movl	$-1431655766, -28(%ecx,%eax,4)
	movl	%ebx, -24(%ecx,%eax,4)
	movl	taskname, %ebx
	movl	%ebx, -20(%ecx,%eax,4)
	movl	taskname+4, %ebx
	movl	%ebx, -16(%ecx,%eax,4)
	movl	taskname+8, %ebx
	movl	%ebx, -12(%ecx,%eax,4)
	movl	taskname+12, %ebx
	movl	%edx, -4(%ecx,%eax,4)
	movl	%ebx, -8(%ecx,%eax,4)
	movl	vecstatsvupb, %eax
	cmpl	%eax, 20(%esp)
	cmovle	20(%esp), %eax
	addl	vecstatsvec, %eax
	addl	$1, (%ecx,%eax,4)
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	leal	1(%edx), %eax
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
.L76:
	.cfi_restore_state
	movl	%ebx, %eax
	jmp	.L69
	.cfi_endproc
.LFE121:
	.size	getvec, .-getvec
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align 4
.LC1:
	.string	"\n#### freevec: block at %d already free\n"
	.section	.rodata.str1.1
.LC2:
	.string	"\n#### freevec: block at %d "
.LC3:
	.string	"size %d corrupted"
	.section	.rodata.str1.4
	.align 4
.LC4:
	.string	"\n#### freevec: last 4 words %8X "
	.section	.rodata.str1.1
.LC5:
	.string	"%8X "
.LC6:
	.string	"%6d "
.LC7:
	.string	"%7d\n"
	.section	.rodata.str1.4
	.align 4
.LC8:
	.string	"#### freevec: should be    55555555 AAAAAAAA requpb %7d\n\n"
	.text
	.p2align 4,,15
	.globl	freevec
	.type	freevec, @function
freevec:
.LFB122:
	.cfi_startproc
	subl	$76, %esp
	.cfi_def_cfa_offset 80
	movl	$-1, %eax
	movl	%ebx, 60(%esp)
	movl	80(%esp), %ebx
	.cfi_offset 3, -20
	movl	%esi, 64(%esp)
	movl	%edi, 68(%esp)
	movl	%ebp, 72(%esp)
	testl	%ebx, %ebx
	je	.L78
	.cfi_offset 5, -8
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	movl	W, %edx
	subl	$1, %ebx
	leal	0(,%ebx,4), %ecx
	movl	%ecx, 32(%esp)
	addl	%edx, %ecx
	movl	(%ecx), %esi
	testl	$1, %esi
	jne	.L85
	leal	(%ebx,%esi), %edi
	leal	-1(%edi), %ebp
	cmpl	%ebx, (%edx,%ebp,4)
	movl	%ebp, 36(%esp)
	je	.L80
	leal	-28(,%edi,4), %edx
	leal	-32(,%edi,4), %ecx
	movl	%edx, 40(%esp)
	movl	%ecx, 44(%esp)
.L81:
	movl	%ebx, 8(%esp)
	subl	$6, %edi
	movl	$.LC2, 4(%esp)
	leal	0(,%edi,4), %ebp
	movl	$1, (%esp)
	call	__printf_chk
	movl	%esi, 8(%esp)
	movl	$.LC3, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	44(%esp), %edx
	movl	W, %eax
	movl	(%eax,%edx), %eax
	movl	$.LC4, 4(%esp)
	movl	$1, (%esp)
	movl	%eax, 8(%esp)
	call	__printf_chk
	movl	40(%esp), %ecx
	movl	W, %eax
	movl	(%eax,%ecx), %eax
	movl	$.LC5, 4(%esp)
	movl	$1, (%esp)
	movl	%eax, 8(%esp)
	call	__printf_chk
	movl	W, %eax
	movl	(%eax,%edi,4), %eax
	movl	$.LC6, 4(%esp)
	movl	$1, (%esp)
	movl	%eax, 8(%esp)
	call	__printf_chk
	movl	36(%esp), %edx
	movl	W, %eax
	movl	(%eax,%edx,4), %eax
	movl	$.LC7, 4(%esp)
	movl	$1, (%esp)
	movl	%eax, 8(%esp)
	call	__printf_chk
	movl	%ebx, 8(%esp)
	movl	$.LC8, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	W, %edx
	xorl	%eax, %eax
	movl	32(%esp), %ecx
	addl	%edx, %ecx
	movl	(%ecx), %esi
.L83:
	orl	$1, %esi
	movl	%esi, (%ecx)
	movl	(%edx,%ebp), %ebx
	movl	vecstatsvupb, %ecx
	cmpl	%ecx, %ebx
	cmovle	%ebx, %ecx
	addl	vecstatsvec, %ecx
	subl	$1, (%edx,%ecx,4)
.L78:
	movl	60(%esp), %ebx
	movl	64(%esp), %esi
	movl	68(%esp), %edi
	movl	72(%esp), %ebp
	addl	$76, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	.cfi_restore 7
	.cfi_restore 6
	.cfi_restore 3
	ret
	.p2align 4,,7
	.p2align 3
.L80:
	.cfi_restore_state
	leal	-7(%edi), %ebp
	movl	%ebp, 44(%esp)
	sall	$2, %ebp
	movl	%ebp, 40(%esp)
	movl	44(%esp), %ebp
	cmpl	$-1431655766, (%edx,%ebp,4)
	je	.L82
	leal	-32(,%edi,4), %edx
	movl	%edx, 44(%esp)
	jmp	.L81
	.p2align 4,,7
	.p2align 3
.L85:
	movl	%ebx, 8(%esp)
	movl	$.LC1, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	xorl	%eax, %eax
	jmp	.L78
	.p2align 4,,7
	.p2align 3
.L82:
	leal	-8(%edi), %ebp
	movl	%ebp, 28(%esp)
	sall	$2, %ebp
	movl	%ebp, 44(%esp)
	movl	28(%esp), %ebp
	cmpl	$1431655765, (%edx,%ebp,4)
	jne	.L81
	leal	-24(,%edi,4), %ebp
	jmp	.L83
	.cfi_endproc
.LFE122:
	.size	freevec, .-freevec
	.p2align 4,,15
	.globl	unloadseg
	.type	unloadseg, @function
unloadseg:
.LFB118:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$24, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %eax
	testl	%eax, %eax
	jne	.L90
	jmp	.L86
	.p2align 4,,7
	.p2align 3
.L89:
	movl	%ebx, %eax
.L90:
	movl	W, %edx
	movl	(%edx,%eax,4), %ebx
	movl	%eax, (%esp)
	call	freevec
	testl	%ebx, %ebx
	jne	.L89
.L86:
	addl	$24, %esp
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_def_cfa_offset 4
	.cfi_restore 3
	ret
	.cfi_endproc
.LFE118:
	.size	unloadseg, .-unloadseg
	.p2align 4,,15
	.globl	loadsegfp
	.type	loadsegfp, @function
loadsegfp:
.LFB116:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	xorl	%ebx, %ebx
	subl	$76, %esp
	.cfi_def_cfa_offset 96
	movl	96(%esp), %esi
	movl	$0, 40(%esp)
	movl	%ebx, 32(%esp)
.L118:
	movl	%esi, (%esp)
	call	rdhex
	cmpl	$1000, %eax
	je	.L96
	jg	.L98
	cmpl	$-1, %eax
	movl	32(%esp), %ebx
	je	.L95
.L94:
	testl	%ebx, %ebx
	movl	%ebx, %eax
	jne	.L117
	jmp	.L95
	.p2align 4,,7
	.p2align 3
.L108:
	movl	%ebx, %eax
.L117:
	movl	W, %edx
	leal	(%edx,%ebx,4), %ebx
	movl	(%ebx), %ebx
	movl	%eax, (%esp)
	call	freevec
	testl	%ebx, %ebx
	jne	.L108
.L95:
	addl	$76, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%ebx, %eax
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
	.p2align 4,,7
	.p2align 3
.L98:
	.cfi_restore_state
	cmpl	$1002, %eax
	je	.L118
	cmpl	$3000, %eax
	je	.L125
.L124:
	movl	32(%esp), %ebx
	jmp	.L94
	.p2align 4,,7
	.p2align 3
.L96:
	movl	%esi, (%esp)
	call	rdhex
	movl	%eax, (%esp)
	movl	%eax, 28(%esp)
	call	getvec
	movl	28(%esp), %edx
	testl	%eax, %eax
	movl	%eax, 44(%esp)
	je	.L124
	movl	W, %ebx
	testl	%edx, %edx
	movl	$0, (%ebx,%eax,4)
	jle	.L102
	movl	%esi, 36(%esp)
	leal	4(,%eax,4), %ebp
	movl	$1, %edi
	movl	%edx, %esi
	jmp	.L103
	.p2align 4,,7
	.p2align 3
.L126:
	movl	W, %ebx
.L103:
	movl	36(%esp), %edx
	addl	$1, %edi
	addl	%ebp, %ebx
	addl	$4, %ebp
	movl	%edx, (%esp)
	call	rdhex
	cmpl	%edi, %esi
	movl	%eax, (%ebx)
	jge	.L126
	movl	36(%esp), %esi
.L102:
	movl	32(%esp), %ebp
	testl	%ebp, %ebp
	je	.L109
	movl	44(%esp), %edx
	movl	40(%esp), %ecx
	movl	W, %eax
	movl	%edx, 40(%esp)
	movl	%edx, (%eax,%ecx,4)
	jmp	.L118
	.p2align 4,,7
	.p2align 3
.L125:
	leal	60(%esp), %ecx
	movl	%esi, 12(%esp)
	movl	$1, 8(%esp)
	movl	$4, 4(%esp)
	movl	%ecx, (%esp)
	call	fread
	cmpl	$4, %eax
	jne	.L127
.L114:
	movl	60(%esp), %eax
	movl	%eax, (%esp)
	call	getvec
	testl	%eax, %eax
	movl	%eax, %ebx
	je	.L124
	movl	W, %eax
	movl	$0, (%eax,%ebx,4)
	movl	60(%esp), %edx
	leal	4(%eax,%ebx,4), %eax
	movl	%esi, 12(%esp)
	movl	$4, 4(%esp)
	movl	%eax, (%esp)
	movl	%edx, 8(%esp)
	call	fread
	movl	60(%esp), %edx
	cmpl	%edx, %eax
	je	.L106
	sall	$2, %edx
	cmpl	%eax, %edx
	jne	.L124
.L106:
	movl	32(%esp), %edi
	testl	%edi, %edi
	je	.L113
	movl	40(%esp), %edx
	movl	W, %eax
	movl	%ebx, 40(%esp)
	movl	%ebx, (%eax,%edx,4)
	jmp	.L118
	.p2align 4,,7
	.p2align 3
.L109:
	movl	44(%esp), %eax
	movl	%eax, 40(%esp)
	movl	%eax, 32(%esp)
	jmp	.L118
	.p2align 4,,7
	.p2align 3
.L113:
	movl	%ebx, 40(%esp)
	movl	%ebx, 32(%esp)
	jmp	.L118
.L127:
	cmpl	$1, %eax
	je	.L114
	jmp	.L124
	.cfi_endproc
.LFE116:
	.size	loadsegfp, .-loadsegfp
	.globl	__moddi3
	.globl	__divdi3
	.p2align 4,,15
	.globl	muldiv
	.type	muldiv, @function
muldiv:
.LFB123:
	.cfi_startproc
	subl	$44, %esp
	.cfi_def_cfa_offset 48
	movl	%esi, 36(%esp)
	movl	48(%esp), %eax
	movl	52(%esp), %esi
	.cfi_offset 6, -12
	movl	56(%esp), %ecx
	movl	%edi, 40(%esp)
	xorl	%edi, %edi
	.cfi_offset 7, -8
	imull	%esi
	movl	$1, %esi
	movl	%eax, 24(%esp)
	xorl	%eax, %eax
	testl	%ecx, %ecx
	movl	%edx, 28(%esp)
	je	.L129
	movl	24(%esp), %eax
	movl	%ecx, %edi
	movl	%ecx, %esi
	movl	28(%esp), %edx
	sarl	$31, %edi
	movl	%ecx, 8(%esp)
	movl	%edi, 12(%esp)
	movl	%eax, (%esp)
	movl	%edx, 4(%esp)
	call	__moddi3
.L129:
	movl	28(%esp), %edx
	movl	%eax, result2
	movl	24(%esp), %eax
	movl	%esi, 8(%esp)
	movl	%edi, 12(%esp)
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	call	__divdi3
	movl	36(%esp), %esi
	movl	40(%esp), %edi
	addl	$44, %esp
	.cfi_def_cfa_offset 4
	.cfi_restore 7
	.cfi_restore 6
	ret
	.cfi_endproc
.LFE123:
	.size	muldiv, .-muldiv
	.p2align 4,,15
	.globl	muldiv1
	.type	muldiv1, @function
muldiv1:
.LFB124:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	$1, %eax
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$4, %esp
	.cfi_def_cfa_offset 24
	movl	32(%esp), %ebx
	movl	24(%esp), %ecx
	testl	%ebx, %ebx
	cmove	%eax, %ebx
	testl	%ecx, %ecx
	js	.L148
	movl	28(%esp), %edx
	xorl	%eax, %eax
	movl	$1, %esi
	movl	$0, (%esp)
	testl	%edx, %edx
	js	.L149
.L136:
	testl	%ebx, %ebx
	js	.L150
.L137:
	movl	(%esp), %esi
.L138:
	xorl	%eax, %eax
	xorl	%edi, %edi
	testl	%ecx, %ecx
	je	.L139
	movl	%edx, %eax
	xorl	%edx, %edx
	divl	%ebx
	xorl	%ebp, %ebp
	.p2align 4,,7
	.p2align 3
.L142:
	testb	$1, %cl
	je	.L140
	addl	%edx, %edi
	addl	%eax, %ebp
	cmpl	%edi, %ebx
	ja	.L140
	addl	$1, %ebp
	subl	%ebx, %edi
.L140:
	addl	%edx, %edx
	addl	%eax, %eax
	shrl	%ecx
	cmpl	%edx, %ebx
	ja	.L141
	addl	$1, %eax
	subl	%ebx, %edx
.L141:
	testl	%ecx, %ecx
	jne	.L142
	movl	%ebp, %eax
.L139:
	movl	(%esp), %ecx
	movl	%edi, %edx
	negl	%edx
	testl	%ecx, %ecx
	cmovne	%edx, %edi
	movl	%eax, %edx
	negl	%edx
	testl	%esi, %esi
	movl	%edi, result2
	cmovne	%edx, %eax
	addl	$4, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
	.p2align 4,,7
	.p2align 3
.L148:
	.cfi_restore_state
	movl	28(%esp), %edx
	negl	%ecx
	xorl	%esi, %esi
	movl	$1, (%esp)
	testl	%edx, %edx
	jns	.L136
.L149:
	negl	%edx
	testl	%ebx, %ebx
	movl	%esi, (%esp)
	movl	%eax, %esi
	jns	.L137
.L150:
	negl	%ebx
	jmp	.L138
	.cfi_endproc
.LFE124:
	.size	muldiv1, .-muldiv1
	.p2align 4,,15
	.globl	relfilename
	.type	relfilename, @function
relfilename:
.LFB125:
	.cfi_startproc
	movl	4(%esp), %eax
	movzbl	(%eax), %edx
	cmpb	$92, %dl
	je	.L157
	cmpb	$47, %dl
	jne	.L159
.L157:
	xorl	%eax, %eax
	ret
	.p2align 4,,7
	.p2align 3
.L156:
	addl	$1, %eax
	cmpb	$58, %dl
	je	.L158
.L159:
	movzbl	(%eax), %edx
	testb	%dl, %dl
	jne	.L156
	movl	$1, %eax
	ret
	.p2align 4,,7
	.p2align 3
.L158:
	xorl	%eax, %eax
	ret
	.cfi_endproc
.LFE125:
	.size	relfilename, .-relfilename
	.p2align 4,,15
	.globl	msecdelay
	.type	msecdelay, @function
msecdelay:
.LFB128:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$92, %esp
	.cfi_def_cfa_offset 112
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	ftime
	movswl	66(%esp), %eax
	movl	60(%esp), %esi
	movzwl	64(%esp), %ebx
	imull	$60, %eax, %eax
	movl	%esi, %edi
	sarl	$31, %edi
	movl	%eax, %edx
	sarl	$31, %edx
	subl	%eax, %esi
	movl	W, %eax
	sbbl	%edx, %edi
	imull	$60, 532(%eax), %eax
	movl	$86400, 8(%esp)
	movl	$0, 12(%esp)
	movl	%eax, %edx
	sarl	$31, %edx
	addl	%eax, %esi
	adcl	%edx, %edi
	movl	%esi, (%esp)
	movl	%edi, 4(%esp)
	call	__divdi3
	movl	$86400, 8(%esp)
	movl	$0, 12(%esp)
	movl	%esi, (%esp)
	movl	%edi, 4(%esp)
	addl	112(%esp), %ebx
	movl	%eax, %ebp
	call	__moddi3
	imull	$1000, %eax, %eax
	addl	%ebx, %eax
	cmpl	$86399999, %eax
	movl	%eax, 44(%esp)
	jle	.L165
	subl	$86400000, %eax
	addl	$1, %ebp
	movl	%eax, 44(%esp)
	jmp	.L165
	.p2align 4,,7
	.p2align 3
.L166:
	cmpl	$900, %ebx
	movl	$900, %eax
	cmovg	%eax, %ebx
	imull	$1000, %ebx, %ebx
	leal	72(%esp), %eax
	movl	$0, 72(%esp)
	movl	%eax, 16(%esp)
	movl	%ebx, 76(%esp)
	movl	$0, 12(%esp)
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	$1024, (%esp)
	call	select
.L165:
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	ftime
	movswl	66(%esp), %eax
	movl	60(%esp), %esi
	movzwl	64(%esp), %ebx
	imull	$60, %eax, %eax
	movl	%esi, %edi
	sarl	$31, %edi
	movl	%eax, %edx
	sarl	$31, %edx
	subl	%eax, %esi
	movl	W, %eax
	sbbl	%edx, %edi
	imull	$60, 532(%eax), %eax
	movl	$86400, 8(%esp)
	movl	$0, 12(%esp)
	movl	%eax, %edx
	sarl	$31, %edx
	addl	%eax, %esi
	adcl	%edx, %edi
	movl	%esi, (%esp)
	movl	%edi, 4(%esp)
	call	__moddi3
	movl	$86400, 8(%esp)
	movl	$0, 12(%esp)
	movl	%esi, (%esp)
	movl	%edi, 4(%esp)
	imull	$1000, %eax, %eax
	addl	%eax, %ebx
	movl	44(%esp), %eax
	subl	%ebx, %eax
	movl	%eax, %ebx
	call	__divdi3
	movl	%ebp, %edx
	subl	%eax, %edx
	testl	%edx, %edx
	leal	86400000(%ebx), %eax
	cmovg	%eax, %ebx
	testl	%ebx, %ebx
	jg	.L166
	addl	$92, %esp
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE128:
	.size	msecdelay, .-msecdelay
	.section	.rodata.str1.4
	.align 4
.LC9:
	.string	"doflt(%d, %d, %d) not implemented\n"
	.text
	.p2align 4,,15
	.globl	doflt
	.type	doflt, @function
doflt:
.LFB129:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	subl	$88, %esp
	.cfi_def_cfa_offset 96
	movl	96(%esp), %eax
	movl	100(%esp), %ecx
	movl	104(%esp), %edx
	cmpl	$42, %eax
	jbe	.L303
.L168:
	movl	%edx, 16(%esp)
	movl	%ecx, 12(%esp)
	movl	%eax, 8(%esp)
	movl	$.LC9, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L296:
	movl	$-1, %eax
	.p2align 4,,7
	.p2align 3
.L179:
	addl	$88, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_def_cfa_offset 4
	.cfi_restore 3
	ret
	.p2align 4,,7
	.p2align 3
.L303:
	.cfi_restore_state
	jmp	*.L210(,%eax,4)
	.section	.rodata
	.align 4
	.align 4
.L210:
	.long	.L296
	.long	.L170
	.long	.L171
	.long	.L172
	.long	.L173
	.long	.L174
	.long	.L175
	.long	.L176
	.long	.L177
	.long	.L178
	.long	.L293
	.long	.L180
	.long	.L181
	.long	.L182
	.long	.L183
	.long	.L184
	.long	.L185
	.long	.L186
	.long	.L168
	.long	.L168
	.long	.L187
	.long	.L188
	.long	.L189
	.long	.L190
	.long	.L191
	.long	.L192
	.long	.L193
	.long	.L194
	.long	.L195
	.long	.L196
	.long	.L197
	.long	.L198
	.long	.L199
	.long	.L200
	.long	.L201
	.long	.L202
	.long	.L203
	.long	.L204
	.long	.L205
	.long	.L206
	.long	.L207
	.long	.L208
	.long	.L209
	.text
.L306:
	fstp	%st(0)
.L293:
	movl	%ecx, %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L178:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	movl	%edx, 44(%esp)
	flds	44(%esp)
	fsubrp	%st, %st(1)
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L177:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	movl	%edx, 44(%esp)
	flds	44(%esp)
	faddp	%st, %st(1)
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L176:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	movl	%edx, 44(%esp)
	flds	44(%esp)
	fdivrp	%st, %st(1)
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L175:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	movl	%edx, 44(%esp)
	flds	44(%esp)
	fmulp	%st, %st(1)
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L174:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	fldz
	fucomip	%st(1), %st
	jbe	.L306
	fchs
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L173:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	fldz
	fucomip	%st(1), %st
	jbe	.L295
.L301:
	fsubs	.LC17
.L298:
	fnstcw	58(%esp)
	movzwl	58(%esp), %eax
	movb	$12, %ah
	movw	%ax, 56(%esp)
	fldcw	56(%esp)
	fistpl	52(%esp)
	fldcw	58(%esp)
	movl	52(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L172:
	movl	%ecx, 52(%esp)
	fildl	52(%esp)
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L171:
	movl	%ecx, 44(%esp)
	xorl	%ebx, %ebx
	flds	44(%esp)
	fldz
	fucomip	%st(1), %st
	jbe	.L220
	fchs
	movl	$1, %ebx
.L220:
	flds	.LC10
	xorl	%edx, %edx
	fld	%st(0)
	fxch	%st(2)
	fucomi	%st(2), %st
	fstp	%st(2)
	jae	.L281
	jmp	.L307
	.p2align 4,,7
	.p2align 3
.L308:
	fxch	%st(1)
.L281:
	fdivr	%st, %st(1)
	fxch	%st(1)
	addl	$5, %edx
	fucomi	%st(1), %st
	jae	.L308
	fstp	%st(1)
	jmp	.L222
.L307:
	fstp	%st(0)
	.p2align 4,,7
	.p2align 3
.L222:
	fld1
	fxch	%st(1)
	fucomi	%st(1), %st
	fstp	%st(1)
	jb	.L225
	flds	.LC11
	.p2align 4,,7
	.p2align 3
.L280:
	fdivr	%st, %st(1)
	addl	$1, %edx
	fld1
	fxch	%st(2)
	fucomi	%st(2), %st
	fstp	%st(2)
	jae	.L280
	fstp	%st(0)
.L225:
	fldl	.LC14
	movl	$1, %eax
	fucomip	%st(1), %st
	jb	.L228
	flds	.LC10
	jmp	.L279
	.p2align 4,,7
	.p2align 3
.L304:
	fldl	.LC14
	fucomip	%st(2), %st
	jb	.L309
.L279:
	subl	$5, %edx
	cmpl	$-400, %edx
	fmul	%st, %st(1)
	setge	%al
	jge	.L304
	fstp	%st(0)
	jmp	.L228
	.p2align 4,,7
	.p2align 3
.L309:
	fstp	%st(0)
.L228:
	fldl	.LC15
	fucomip	%st(1), %st
	jbe	.L231
	testb	%al, %al
	je	.L231
	flds	.LC11
	jmp	.L278
	.p2align 4,,7
	.p2align 3
.L305:
	fldl	.LC15
	fucomip	%st(2), %st
	jbe	.L310
.L278:
	subl	$1, %edx
	cmpl	$-400, %edx
	fmul	%st, %st(1)
	jge	.L305
	fstp	%st(0)
	jmp	.L231
	.p2align 4,,7
	.p2align 3
.L310:
	fstp	%st(0)
.L231:
	xorl	%ecx, %ecx
	xorl	%eax, %eax
	cmpl	$-400, %edx
	jl	.L311
	fmuls	.LC16
	fnstcw	58(%esp)
	leal	-9(%edx), %ecx
	movzwl	58(%esp), %eax
	fadds	.LC17
	movb	$12, %ah
	movw	%ax, 56(%esp)
	fldcw	56(%esp)
	fistpl	52(%esp)
	fldcw	58(%esp)
	movl	52(%esp), %eax
	jmp	.L234
	.p2align 4,,7
	.p2align 3
.L311:
	fstp	%st(0)
.L234:
	movl	%eax, %edx
	negl	%edx
	testl	%ebx, %ebx
	movl	%ecx, result2
	cmovne	%edx, %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L170:
	movl	%ecx, 52(%esp)
	cmpl	$5, %edx
	fildl	52(%esp)
	jle	.L211
	flds	.LC10
	.p2align 4,,7
	.p2align 3
.L277:
	subl	$5, %edx
	cmpl	$5, %edx
	fmul	%st, %st(1)
	jg	.L277
	fstp	%st(0)
.L211:
	testl	%edx, %edx
	jle	.L213
	flds	.LC11
	.p2align 4,,7
	.p2align 3
.L274:
	subl	$1, %edx
	fmul	%st, %st(1)
	jne	.L274
	fstp	%st(0)
.L299:
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L209:
	movl	%ecx, 52(%esp)
	fildl	52(%esp)
	movl	%edx, 44(%esp)
	flds	44(%esp)
	fmulp	%st, %st(1)
	fldz
	fucomip	%st(1), %st
	ja	.L301
.L295:
	fadds	.LC17
	jmp	.L298
	.p2align 4,,7
	.p2align 3
.L208:
	movl	%edx, 52(%esp)
	fildl	52(%esp)
	movl	%ecx, 52(%esp)
	fildl	52(%esp)
	fdivrp	%st, %st(1)
	fstps	48(%esp)
	jmp	.L300
	.p2align 4,,7
	.p2align 3
.L312:
	fstp	%st(0)
.L300:
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L207:
	movl	%edx, 44(%esp)
	flds	44(%esp)
	movl	%ecx, 44(%esp)
	flds	44(%esp)
.L246:
	fprem
	fnstsw	%ax
	sahf
	jp	.L246
	fstp	%st(1)
	fucomi	%st(0), %st
	jnp	.L299
	fstp	%st(0)
	movl	%edx, 44(%esp)
	flds	44(%esp)
	fstpl	8(%esp)
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	fstpl	(%esp)
	call	fmod
	jmp	.L299
	.p2align 4,,7
	.p2align 3
.L206:
	movl	%ecx, (%esp)
	call	floorf
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L205:
	movl	%ecx, (%esp)
	call	ceilf
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L204:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	fld	%st(0)
	fsqrt
	fsts	48(%esp)
	fucomip	%st(0), %st
	jnp	.L312
	fstps	(%esp)
	call	sqrtf
	fstps	48(%esp)
	jmp	.L300
	.p2align 4,,7
	.p2align 3
.L203:
	movl	%edx, 44(%esp)
	flds	44(%esp)
	fstpl	8(%esp)
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	fstpl	(%esp)
	call	pow
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L202:
	movl	%ecx, 44(%esp)
	leal	64(%esp), %eax
	flds	44(%esp)
	fstpl	(%esp)
	movl	%eax, 8(%esp)
	call	modf
	fnstcw	58(%esp)
	fstps	48(%esp)
	movl	48(%esp), %eax
	fldl	64(%esp)
	movzwl	58(%esp), %edx
	movb	$12, %dh
	movw	%dx, 56(%esp)
	fldcw	56(%esp)
	fistpl	result2
	fldcw	58(%esp)
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L201:
	movl	%ecx, (%esp)
	call	log10f
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L200:
	movl	%ecx, (%esp)
	call	logf
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L199:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	fstpl	(%esp)
	movl	%edx, 8(%esp)
	call	ldexp
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L198:
	movl	%ecx, 44(%esp)
	leal	76(%esp), %eax
	flds	44(%esp)
	fstpl	(%esp)
	movl	%eax, 8(%esp)
	call	frexp
	movl	76(%esp), %edx
	movl	%edx, result2
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L197:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	fstpl	(%esp)
	call	exp
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L196:
	movl	%ecx, (%esp)
	call	tanhf
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L195:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	fstpl	(%esp)
	call	sinh
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L194:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	fstpl	(%esp)
	call	cosh
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L193:
	movl	%ecx, (%esp)
	call	tanf
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L192:
	movl	%ecx, (%esp)
	call	sinf
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L191:
	movl	%ecx, (%esp)
	call	cosf
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L190:
	movl	%edx, 44(%esp)
	flds	44(%esp)
	fstpl	8(%esp)
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	fstpl	(%esp)
	call	atan2
	jmp	.L299
	.p2align 4,,7
	.p2align 3
.L189:
	movl	%ecx, (%esp)
	call	atanf
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L188:
	movl	%ecx, (%esp)
	call	asinf
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L187:
	movl	%ecx, (%esp)
	call	acosf
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L186:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	movl	%edx, 44(%esp)
	flds	44(%esp)
	fxch	%st(1)
	fucomip	%st(1), %st
	fstp	%st(0)
	sbbl	%eax, %eax
	notl	%eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L185:
	movl	%edx, 44(%esp)
	flds	44(%esp)
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	fxch	%st(1)
	fucomip	%st(1), %st
	fstp	%st(0)
	sbbl	%eax, %eax
	notl	%eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L184:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	movl	%edx, 44(%esp)
.L297:
	flds	44(%esp)
	fxch	%st(1)
	xorl	%eax, %eax
	fucomip	%st(1), %st
	fstp	%st(0)
	setbe	%al
	subl	$1, %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L183:
	movl	%edx, 44(%esp)
	flds	44(%esp)
	movl	%ecx, 44(%esp)
	jmp	.L297
	.p2align 4,,7
	.p2align 3
.L182:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	movl	%edx, 44(%esp)
	flds	44(%esp)
	fxch	%st(1)
	fucomip	%st(1), %st
	fstp	%st(0)
	jp	.L296
	jne	.L296
.L294:
	xorl	%eax, %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L181:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	movl	%edx, 44(%esp)
	flds	44(%esp)
	fxch	%st(1)
	fucomip	%st(1), %st
	fstp	%st(0)
	jp	.L294
	movl	$-1, %eax
	je	.L179
	xorl	%eax, %eax
	jmp	.L179
	.p2align 4,,7
	.p2align 3
.L180:
	movl	%ecx, 44(%esp)
	flds	44(%esp)
	fchs
	fstps	48(%esp)
	movl	48(%esp), %eax
	jmp	.L179
.L213:
	cmpl	$-5, %edx
	jge	.L216
	flds	.LC10
	.p2align 4,,7
	.p2align 3
.L276:
	addl	$5, %edx
	cmpl	$-5, %edx
	fdivr	%st, %st(1)
	jl	.L276
	fstp	%st(0)
.L216:
	testl	%edx, %edx
	je	.L299
	flds	.LC11
	.p2align 4,,7
	.p2align 3
.L275:
	addl	$1, %edx
	fdivr	%st, %st(1)
	jne	.L275
	fstp	%st(0)
	jmp	.L299
	.cfi_endproc
.LFE129:
	.size	doflt, .-doflt
	.p2align 4,,15
	.globl	timestamp
	.type	timestamp, @function
timestamp:
.LFB130:
	.cfi_startproc
	subl	$76, %esp
	.cfi_def_cfa_offset 80
	leal	36(%esp), %eax
	movl	%ebx, 60(%esp)
	movl	%esi, 64(%esp)
	movl	%edi, 68(%esp)
	movl	%ebp, 72(%esp)
	movl	80(%esp), %ebp
	.cfi_offset 5, -8
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	%eax, (%esp)
	call	ftime
	movswl	42(%esp), %eax
	movl	36(%esp), %ecx
	imull	$60, %eax, %eax
	movl	%ecx, %ebx
	sarl	$31, %ebx
	movl	%eax, %edx
	sarl	$31, %edx
	subl	%eax, %ecx
	movzwl	40(%esp), %eax
	sbbl	%edx, %ebx
	movl	%eax, 28(%esp)
	movl	W, %eax
	imull	$60, 532(%eax), %esi
	movl	$86400, 8(%esp)
	movl	$0, 12(%esp)
	movl	%esi, %edi
	sarl	$31, %edi
	addl	%ecx, %esi
	adcl	%ebx, %edi
	movl	%esi, (%esp)
	movl	%edi, 4(%esp)
	call	__divdi3
	movl	%eax, 0(%ebp)
	movl	%esi, (%esp)
	movl	%edi, 4(%esp)
	movl	$86400, 8(%esp)
	movl	$0, 12(%esp)
	call	__moddi3
	movl	60(%esp), %ebx
	movl	$-1, 8(%ebp)
	movl	64(%esp), %esi
	movl	68(%esp), %edi
	imull	$1000, %eax, %eax
	addl	28(%esp), %eax
	movl	%eax, 4(%ebp)
	movl	$-1, %eax
	movl	72(%esp), %ebp
	addl	$76, %esp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	.cfi_restore 7
	.cfi_restore 6
	.cfi_restore 3
	ret
	.cfi_endproc
.LFE130:
	.size	timestamp, .-timestamp
	.p2align 4,,15
	.globl	vmsfname
	.type	vmsfname, @function
vmsfname:
.LFB131:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$16, %esp
	.cfi_def_cfa_offset 36
	movl	36(%esp), %edx
	movl	40(%esp), %eax
	movzbl	(%edx), %ebp
	movl	%ebp, %ecx
	movsbl	%cl, %esi
	testl	%esi, %esi
	je	.L338
	xorl	%ecx, %ecx
	cmpl	$58, %esi
	jne	.L317
	jmp	.L316
	.p2align 4,,7
	.p2align 3
.L354:
	cmpl	$58, %ebx
	je	.L316
.L317:
	addl	$1, %ecx
	movsbl	(%edx,%ecx), %ebx
	testl	%ebx, %ebx
	jne	.L354
	movl	%edx, 8(%esp)
	xorl	%ecx, %ecx
	movl	$0, 4(%esp)
.L322:
	movl	%ecx, %ebx
	movl	$-1, %edi
	.p2align 4,,7
	.p2align 3
.L325:
	cmpl	$47, %esi
	cmove	%ebx, %edi
	addl	$1, %ebx
	movsbl	(%edx,%ebx), %esi
	testl	%esi, %esi
	jne	.L325
	leal	1(%ecx), %ebx
	movl	%ebx, 12(%esp)
.L315:
	movl	%ebp, %ebx
	cmpb	$47, %bl
	je	.L356
	cmpl	$-1, %edi
	movl	%ecx, %esi
	je	.L328
	movl	4(%esp), %ebx
	movb	$91, (%eax,%ebx)
	movl	8(%esp), %ebx
	cmpb	$46, (%ebx)
	je	.L357
.L329:
	movl	12(%esp), %ebx
	leal	2(%ecx), %esi
	movb	$46, (%eax,%ebx)
.L328:
	addl	$1, %esi
	movl	$46, %ebp
	jmp	.L335
	.p2align 4,,7
	.p2align 3
.L330:
	cmpl	$47, %ebx
	je	.L358
	testl	%ebx, %ebx
	movb	%bl, -1(%eax,%esi)
	je	.L334
.L337:
	addl	$1, %ecx
	addl	$1, %esi
.L335:
	movsbl	(%edx,%ecx), %ebx
	cmpl	$46, %ebx
	jne	.L330
	cmpb	$46, 1(%edx,%ecx)
	je	.L359
.L331:
	movb	%bl, -1(%eax,%esi)
	jmp	.L337
	.p2align 4,,7
	.p2align 3
.L358:
	cmpl	%edi, %ecx
	movb	$93, %bl
	cmovne	%ebp, %ebx
	movb	%bl, -1(%eax,%esi)
	jmp	.L337
	.p2align 4,,7
	.p2align 3
.L334:
	addl	$16, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
	.p2align 4,,7
	.p2align 3
.L359:
	.cfi_restore_state
	addl	$1, %ecx
	movl	$45, %ebx
	jmp	.L331
	.p2align 4,,7
	.p2align 3
.L316:
	testl	%ecx, %ecx
	movl	$0, %ebx
	cmovns	%ecx, %ebx
	movl	%ebx, %ebp
	addl	$1, %ebp
	movl	%ebp, %edi
	shrl	$2, %edi
	movl	%ebx, 12(%esp)
	leal	0(,%edi,4), %ebx
	testl	%ebx, %ebx
	movl	%ebx, 4(%esp)
	je	.L340
	leal	4(%eax), %ebx
	cmpl	%ebx, %edx
	seta	%bl
	movl	%ebx, %esi
	leal	4(%edx), %ebx
	cmpl	%ebx, %eax
	seta	%bl
	orl	%ebx, %esi
	movl	%eax, %ebx
	orl	%edx, %ebx
	andl	$3, %ebx
	sete	3(%esp)
	cmpl	$9, %ebp
	seta	%bl
	andb	%bl, 3(%esp)
	movl	%esi, %ebx
	testb	%bl, 3(%esp)
	je	.L340
	xorl	%ebx, %ebx
	.p2align 4,,7
	.p2align 3
.L319:
	movl	(%edx,%ebx,4), %esi
	movl	%esi, (%eax,%ebx,4)
	addl	$1, %ebx
	cmpl	%ebx, %edi
	ja	.L319
	movl	4(%esp), %ebx
	cmpl	%ebx, %ebp
	je	.L320
	movl	%ecx, %esi
	.p2align 4,,7
	.p2align 3
.L349:
	movzbl	(%edx,%ebx), %ecx
	movb	%cl, (%eax,%ebx)
	addl	$1, %ebx
	cmpl	%ebx, %esi
	jge	.L349
.L320:
	movl	%ebp, %ecx
	addl	%edx, %ecx
	movl	%ebp, 4(%esp)
	movzbl	(%ecx), %ebp
	movl	%ecx, 8(%esp)
	movl	4(%esp), %ecx
	movl	%ebp, %ebx
	movsbl	%bl, %esi
	testl	%esi, %esi
	jne	.L322
	movl	12(%esp), %ecx
	movl	$-1, %edi
	addl	$2, %ecx
	movl	%ecx, 12(%esp)
	movl	4(%esp), %ecx
	jmp	.L315
	.p2align 4,,7
	.p2align 3
.L356:
	cmpl	%ecx, %edi
	movl	%edi, %esi
	je	.L327
	movl	4(%esp), %ecx
	movl	12(%esp), %esi
	movb	$91, (%eax,%ecx)
.L327:
	movl	12(%esp), %ecx
	jmp	.L328
	.p2align 4,,7
	.p2align 3
.L357:
	movl	4(%esp), %ebx
	movl	12(%esp), %esi
	cmpb	$46, 1(%edx,%ebx)
	jne	.L329
	jmp	.L328
.L338:
	movl	%edx, 8(%esp)
	xorl	%ecx, %ecx
	movl	$-1, %edi
	movl	$1, 12(%esp)
	movl	$0, 4(%esp)
	jmp	.L315
.L340:
	xorl	%ebx, %ebx
	movl	%ecx, %esi
	jmp	.L349
	.cfi_endproc
.LFE131:
	.size	vmsfname, .-vmsfname
	.p2align 4,,15
	.globl	winfname
	.type	winfname, @function
winfname:
.LFB132:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	movl	16(%esp), %esi
	movl	12(%esp), %edx
	leal	1(%esi), %ecx
	jmp	.L361
	.p2align 4,,7
	.p2align 3
.L365:
	testl	%ebx, %ebx
	movb	%al, -1(%ecx)
	je	.L364
.L363:
	addl	$1, %ecx
.L361:
	movzbl	(%edx), %eax
	addl	$1, %edx
	movsbl	%al, %ebx
	cmpl	$47, %ebx
	jne	.L365
	movb	$92, -1(%ecx)
	jmp	.L363
	.p2align 4,,7
	.p2align 3
.L364:
	movl	%esi, %eax
	popl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 4
	.cfi_restore 6
	ret
	.cfi_endproc
.LFE132:
	.size	winfname, .-winfname
	.p2align 4,,15
	.globl	unixfname
	.type	unixfname, @function
unixfname:
.LFB133:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	movl	16(%esp), %esi
	movl	12(%esp), %edx
	leal	1(%esi), %ecx
	jmp	.L367
	.p2align 4,,7
	.p2align 3
.L371:
	testl	%ebx, %ebx
	movb	%al, -1(%ecx)
	je	.L370
.L369:
	addl	$1, %ecx
.L367:
	movzbl	(%edx), %eax
	addl	$1, %edx
	movsbl	%al, %ebx
	cmpl	$92, %ebx
	jne	.L371
	movb	$47, -1(%ecx)
	jmp	.L369
	.p2align 4,,7
	.p2align 3
.L370:
	movl	%esi, %eax
	popl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 4
	.cfi_restore 6
	ret
	.cfi_endproc
.LFE133:
	.size	unixfname, .-unixfname
	.p2align 4,,15
	.globl	prepend_prefix
	.type	prepend_prefix, @function
prepend_prefix:
.LFB135:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$20, %esp
	.cfi_def_cfa_offset 40
	movl	prefixbp, %esi
	movl	40(%esp), %eax
	movl	44(%esp), %ebx
	movsbl	(%esi), %ebp
	testl	%ebp, %ebp
	jne	.L387
.L373:
	addl	$20, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
	.p2align 4,,7
	.p2align 3
.L387:
	.cfi_restore_state
	movzbl	(%eax), %edx
	cmpb	$92, %dl
	je	.L373
	cmpb	$47, %dl
	je	.L373
	movl	%eax, %edx
	jmp	.L375
	.p2align 4,,7
	.p2align 3
.L376:
	addl	$1, %edx
	cmpb	$58, %cl
	je	.L373
.L375:
	movzbl	(%edx), %ecx
	testb	%cl, %cl
	jne	.L376
	movl	%ebp, %edi
	shrl	$2, %edi
	movl	%edi, 8(%esp)
	sall	$2, %edi
	leal	1(%esi), %edx
	testl	%edi, %edi
	movl	%edx, 4(%esp)
	leal	-1(%ebp), %ecx
	movl	%edi, 16(%esp)
	je	.L382
	cmpl	$9, %ebp
	seta	3(%esp)
	orl	%ebx, %edx
	andl	$3, %edx
	sete	%dl
	andb	%dl, 3(%esp)
	leal	5(%esi), %edx
	cmpl	%edx, %ebx
	seta	2(%esp)
	leal	4(%ebx), %edx
	cmpl	%edx, 4(%esp)
	seta	%dl
	orb	%dl, 2(%esp)
	movzbl	2(%esp), %edx
	testb	%dl, 3(%esp)
	je	.L382
	movl	8(%esp), %edi
	xorl	%edx, %edx
	movl	%ecx, 8(%esp)
	.p2align 4,,7
	.p2align 3
.L378:
	movl	1(%esi,%edx,4), %ecx
	movl	%ecx, (%ebx,%edx,4)
	addl	$1, %edx
	cmpl	%edx, %edi
	ja	.L378
	movl	16(%esp), %edi
	movl	8(%esp), %ecx
	addl	%edi, 4(%esp)
	movl	%edi, %edx
	subl	%edi, %ecx
	cmpl	%edi, %ebp
	je	.L379
.L377:
	movl	4(%esp), %edi
	movl	%eax, %esi
	subl	%edx, %edi
	.p2align 4,,7
	.p2align 3
.L380:
	movzbl	(%edi,%edx), %eax
	subl	$1, %ecx
	movb	%al, (%ebx,%edx)
	addl	$1, %edx
	cmpl	$-1, %ecx
	jne	.L380
	movl	%esi, %eax
.L379:
	movb	$47, (%ebx,%ebp)
	xorl	%edx, %edx
	leal	(%ebx,%ebp), %esi
	.p2align 4,,7
	.p2align 3
.L381:
	movzbl	(%eax,%edx), %ecx
	movb	%cl, 1(%esi,%edx)
	addl	$1, %edx
	testb	%cl, %cl
	jne	.L381
	addl	$20, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	%ebx, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
.L382:
	.cfi_restore_state
	xorl	%edx, %edx
	jmp	.L377
	.cfi_endproc
.LFE135:
	.size	prepend_prefix, .-prepend_prefix
	.section	.rodata.str1.1
.LC19:
	.string	"Configuration error: "
	.section	.rodata.str1.4
	.align 4
.LC20:
	.string	"One of UNIXNAMES, WINNAMES or VMSNAMES must be set"
	.section	.rodata.str1.1
.LC21:
	.string	"osfname: %s => %s\n"
	.text
	.p2align 4,,15
	.globl	osfname
	.type	osfname, @function
osfname:
.LFB134:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$300, %esp
	.cfi_def_cfa_offset 320
	movl	320(%esp), %esi
	movl	324(%esp), %ebp
	movl	%gs:20, %eax
	movl	%eax, 284(%esp)
	xorl	%eax, %eax
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	movl	%esi, (%esp)
	call	prepend_prefix
	leal	1(%ebp), %edx
	jmp	.L389
	.p2align 4,,7
	.p2align 3
.L398:
	testl	%ecx, %ecx
	movb	%bl, -1(%edx)
	je	.L397
.L391:
	addl	$1, %edx
.L389:
	movzbl	(%eax), %edi
	addl	$1, %eax
	movl	%edi, %ebx
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	jne	.L398
	movb	$47, -1(%edx)
	jmp	.L391
	.p2align 4,,7
	.p2align 3
.L397:
	testl	%ebp, %ebp
	je	.L399
	movl	filetracing, %edi
	movl	%ebp, %ebx
	testl	%edi, %edi
	je	.L393
	movl	%ebp, 12(%esp)
	movl	%esi, 8(%esp)
	movl	$.LC21, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L393:
	movl	284(%esp), %edx
	xorl	%gs:20, %edx
	movl	%ebx, %eax
	jne	.L400
	addl	$300, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
.L399:
	.cfi_restore_state
	movl	$.LC19, 4(%esp)
	xorl	%ebx, %ebx
	movl	$1, (%esp)
	call	__printf_chk
	movl	$.LC20, (%esp)
	call	puts
	jmp	.L393
.L400:
	call	__stack_chk_fail
	.cfi_endproc
.LFE134:
	.size	osfname, .-osfname
	.section	.rodata.str1.4
	.align 4
.LC22:
	.string	"pathinput: attempting to open %s"
	.section	.rodata.str1.1
.LC23:
	.string	" using\n  %s"
.LC24:
	.string	" = %s\n"
.LC25:
	.string	"rb"
.LC26:
	.string	"Trying: %s - "
.LC27:
	.string	"found"
.LC28:
	.string	"not found"
	.section	.rodata.str1.4
	.align 4
.LC29:
	.string	"Trying: %s in the current directory - "
	.text
	.p2align 4,,15
	.type	pathinput.part.3, @function
pathinput.part.3:
.LFB153:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	movl	%edx, %edi
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	movl	%eax, %ebx
	subl	$556, %esp
	.cfi_def_cfa_offset 576
	movl	%gs:20, %eax
	movl	%eax, 540(%esp)
	xorl	%eax, %eax
	movl	%edx, (%esp)
	call	getenv
	movl	%eax, %esi
	movl	filetracing, %eax
	testl	%eax, %eax
	jne	.L440
.L402:
	testl	%esi, %esi
	leal	28(%esp), %edi
	je	.L404
	.p2align 4,,7
	.p2align 3
.L403:
	addl	$1, %esi
	movzbl	-1(%esi), %ecx
	cmpb	$59, %cl
	je	.L403
	cmpb	$58, %cl
	je	.L403
	testb	%cl, %cl
	je	.L404
	movl	%edi, %edx
	.p2align 4,,4
	jmp	.L405
	.p2align 4,,7
	.p2align 3
.L407:
	addl	$1, %esi
	cmpb	$59, %al
	.p2align 4,,2
	je	.L406
	cmpb	$58, %al
	.p2align 4,,2
	je	.L406
	movl	%eax, %ecx
.L405:
	movb	%cl, (%edx)
	movzbl	(%esi), %eax
	addl	$1, %edx
	testb	%al, %al
	jne	.L407
.L406:
	cmpb	$92, %cl
	jne	.L441
.L408:
	xorl	%eax, %eax
	.p2align 4,,7
	.p2align 3
.L409:
	movzbl	(%ebx,%eax), %ecx
	movb	%cl, (%edx,%eax)
	addl	$1, %eax
	testb	%cl, %cl
	jne	.L409
	leal	284(%esp), %edx
	movl	%edx, 4(%esp)
	movl	%edi, (%esp)
	call	prepend_prefix
	movl	$chbuf4, %edx
	movl	%edx, %ebp
.L433:
	movzbl	(%eax), %edx
	addl	$1, %eax
	movsbl	%dl, %ecx
	cmpl	$92, %ecx
	je	.L411
.L443:
	testl	%ecx, %ecx
	movb	%dl, 0(%ebp)
	je	.L442
	movzbl	(%eax), %edx
	addl	$1, %ebp
	addl	$1, %eax
	movsbl	%dl, %ecx
	cmpl	$92, %ecx
	jne	.L443
.L411:
	movb	$47, 0(%ebp)
	addl	$1, %ebp
	jmp	.L433
	.p2align 4,,7
	.p2align 3
.L441:
	cmpb	$47, %cl
	je	.L408
	movb	$47, (%edx)
	addl	$1, %edx
	jmp	.L408
	.p2align 4,,7
	.p2align 3
.L442:
	movl	filetracing, %eax
	testl	%eax, %eax
	je	.L413
	movl	$chbuf4, 12(%esp)
	movl	%edi, 8(%esp)
	movl	$.LC21, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L413:
	movl	$.LC25, 4(%esp)
	movl	$chbuf4, (%esp)
	call	fopen
	movl	%eax, %ebp
	movl	filetracing, %eax
	testl	%eax, %eax
	jne	.L444
	testl	%ebp, %ebp
	jne	.L416
.L417:
	testl	%esi, %esi
	jne	.L403
.L404:
	leal	284(%esp), %eax
	movl	%eax, 4(%esp)
	movl	%ebx, (%esp)
	call	prepend_prefix
	movl	$chbuf4, %edx
	movl	%edx, %esi
.L434:
	movzbl	(%eax), %edx
	addl	$1, %eax
	movsbl	%dl, %ecx
	cmpl	$92, %ecx
	je	.L422
.L446:
	testl	%ecx, %ecx
	movb	%dl, (%esi)
	je	.L445
	movzbl	(%eax), %edx
	addl	$1, %esi
	addl	$1, %eax
	movsbl	%dl, %ecx
	cmpl	$92, %ecx
	jne	.L446
.L422:
	movb	$47, (%esi)
	addl	$1, %esi
	jmp	.L434
	.p2align 4,,7
	.p2align 3
.L444:
	movl	%edi, 8(%esp)
	movl	$.LC26, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	testl	%ebp, %ebp
	je	.L415
.L439:
	movl	$.LC27, (%esp)
	call	puts
.L416:
	movl	540(%esp), %edx
	xorl	%gs:20, %edx
	movl	%ebp, %eax
	jne	.L447
	addl	$556, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
.L445:
	.cfi_restore_state
	movl	filetracing, %eax
	testl	%eax, %eax
	jne	.L448
.L424:
	movl	$.LC25, 4(%esp)
	movl	$chbuf4, (%esp)
	call	fopen
	movl	%eax, %ebp
	movl	filetracing, %eax
	testl	%eax, %eax
	je	.L416
	movl	%ebx, 8(%esp)
	movl	$.LC29, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	testl	%ebp, %ebp
	jne	.L439
	movl	$.LC28, (%esp)
	call	puts
	jmp	.L416
	.p2align 4,,7
	.p2align 3
.L440:
	movl	%ebx, 8(%esp)
	movl	$.LC22, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	%edi, 8(%esp)
	movl	$.LC23, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	%esi, 8(%esp)
	movl	$.LC24, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	jmp	.L402
.L415:
	movl	$.LC28, (%esp)
	call	puts
	jmp	.L417
.L448:
	movl	$chbuf4, 12(%esp)
	movl	%ebx, 8(%esp)
	movl	$.LC21, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	jmp	.L424
.L447:
	call	__stack_chk_fail
	.cfi_endproc
.LFE153:
	.size	pathinput.part.3, .-pathinput.part.3
	.p2align 4,,15
	.globl	pathinput
	.type	pathinput, @function
pathinput:
.LFB126:
	.cfi_startproc
	pushl	%edi
	.cfi_def_cfa_offset 8
	.cfi_offset 7, -8
	pushl	%esi
	.cfi_def_cfa_offset 12
	.cfi_offset 6, -12
	pushl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	subl	$288, %esp
	.cfi_def_cfa_offset 304
	movl	308(%esp), %edx
	movl	%gs:20, %eax
	movl	%eax, 284(%esp)
	xorl	%eax, %eax
	movl	304(%esp), %edi
	testl	%edx, %edx
	je	.L450
	movzbl	(%edi), %eax
	cmpb	$92, %al
	je	.L450
	cmpb	$47, %al
	je	.L450
	movl	%edi, %eax
	.p2align 4,,2
	jmp	.L452
	.p2align 4,,7
	.p2align 3
.L453:
	addl	$1, %eax
	cmpb	$58, %cl
	je	.L450
.L452:
	movzbl	(%eax), %ecx
	testb	%cl, %cl
	jne	.L453
	movl	%edi, %eax
	call	pathinput.part.3
	movl	%eax, %esi
.L459:
	movl	284(%esp), %edx
	xorl	%gs:20, %edx
	movl	%esi, %eax
	jne	.L466
	addl	$288, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 16
	popl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 8
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 4
	.cfi_restore 7
	ret
	.p2align 4,,7
	.p2align 3
.L450:
	.cfi_restore_state
	leal	28(%esp), %eax
	movl	%eax, 4(%esp)
	movl	%edi, (%esp)
	call	prepend_prefix
	movl	$chbuf4, %edx
.L464:
	movzbl	(%eax), %esi
	addl	$1, %eax
	movl	%esi, %ebx
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	je	.L456
.L468:
	testl	%ecx, %ecx
	movb	%bl, (%edx)
	je	.L467
	movzbl	(%eax), %esi
	addl	$1, %edx
	addl	$1, %eax
	movl	%esi, %ebx
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	jne	.L468
.L456:
	movb	$47, (%edx)
	addl	$1, %edx
	jmp	.L464
	.p2align 4,,7
	.p2align 3
.L467:
	movl	filetracing, %edx
	testl	%edx, %edx
	jne	.L469
.L458:
	movl	$.LC25, 4(%esp)
	movl	$chbuf4, (%esp)
	call	fopen
	movl	%eax, %esi
	movl	filetracing, %eax
	testl	%eax, %eax
	je	.L459
	movl	%edi, 8(%esp)
	movl	$.LC29, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	testl	%esi, %esi
	je	.L460
	movl	$.LC27, (%esp)
	call	puts
	jmp	.L459
	.p2align 4,,7
	.p2align 3
.L469:
	movl	$chbuf4, 12(%esp)
	movl	%edi, 8(%esp)
	movl	$.LC21, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	jmp	.L458
.L460:
	movl	$.LC28, (%esp)
	call	puts
	jmp	.L459
.L466:
	call	__stack_chk_fail
	.cfi_endproc
.LFE126:
	.size	pathinput, .-pathinput
	.p2align 4,,15
	.globl	loadseg
	.type	loadseg, @function
loadseg:
.LFB117:
	.cfi_startproc
	subl	$348, %esp
	.cfi_def_cfa_offset 352
	movl	%ebx, 332(%esp)
	movl	352(%esp), %ebx
	.cfi_offset 3, -20
	movl	%esi, 336(%esp)
	movl	%gs:20, %eax
	movl	%eax, 316(%esp)
	xorl	%eax, %eax
	movl	%edi, 340(%esp)
	movl	%ebp, 344(%esp)
	movl	$0, 4(%esp)
	movl	%ebx, (%esp)
	.cfi_offset 5, -8
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	call	pathinput
	testl	%eax, %eax
	movl	%eax, %esi
	je	.L471
	movl	%eax, (%esp)
	call	loadsegfp
	movl	%esi, (%esp)
	movl	%eax, %edi
	call	fclose
	testl	%edi, %edi
	jne	.L472
.L471:
	movl	W, %eax
	xorl	%ebp, %ebp
	movl	544(%eax), %edi
	leal	0(,%edi,4), %esi
	testl	%edi, %edi
	leal	(%eax,%esi), %ecx
	movzbl	(%ecx), %edx
	je	.L473
	movzbl	%dl, %edi
	movl	%edi, 32(%esp)
	leal	60(%esp), %ebp
	cmpl	$0, 32(%esp)
	movl	%ebp, %edi
	je	.L474
	leal	1(%ecx), %edi
	addl	$1, %esi
	movl	%edi, 28(%esp)
	movl	32(%esp), %edi
	movl	%esi, 40(%esp)
	movl	32(%esp), %esi
	shrl	$2, %edi
	movl	%edi, 44(%esp)
	sall	$2, %edi
	subl	$1, %esi
	testl	%edi, %edi
	movl	%edi, 36(%esp)
	je	.L482
	cmpb	$6, %dl
	seta	23(%esp)
	testb	$3, 28(%esp)
	sete	%dl
	andb	%dl, 23(%esp)
	leal	5(%ecx), %edx
	cmpl	%edx, %ebp
	seta	22(%esp)
	leal	64(%esp), %edx
	cmpl	%edx, 28(%esp)
	seta	%dl
	orb	%dl, 22(%esp)
	movzbl	22(%esp), %edx
	testb	%dl, 23(%esp)
	je	.L482
	movl	44(%esp), %edi
	xorl	%edx, %edx
	movl	%eax, 28(%esp)
	.p2align 4,,7
	.p2align 3
.L476:
	movl	1(%ecx,%edx,4), %eax
	movl	%eax, 0(%ebp,%edx,4)
	addl	$1, %edx
	cmpl	%edx, %edi
	ja	.L476
	movl	36(%esp), %edi
	movl	36(%esp), %edx
	addl	%edi, 40(%esp)
	subl	36(%esp), %esi
	addl	%ebp, %edi
	movl	28(%esp), %eax
	cmpl	%edx, 32(%esp)
	je	.L477
.L475:
	movl	40(%esp), %edx
	subl	%edx, %edi
	.p2align 4,,7
	.p2align 3
.L478:
	movzbl	(%eax,%edx), %ecx
	subl	$1, %esi
	movb	%cl, (%edi,%edx)
	addl	$1, %edx
	cmpl	$-1, %esi
	jne	.L478
.L477:
	movl	32(%esp), %edi
	addl	%ebp, %edi
.L474:
	movb	$0, (%edi)
.L473:
	movl	%ebx, (%esp)
	xorl	%edi, %edi
	movl	%ebp, 4(%esp)
	call	pathinput
	testl	%eax, %eax
	movl	%eax, %ebx
	je	.L472
	movl	%eax, (%esp)
	call	loadsegfp
	movl	%ebx, (%esp)
	movl	%eax, %edi
	call	fclose
.L472:
	movl	%edi, %eax
	movl	316(%esp), %edi
	xorl	%gs:20, %edi
	jne	.L487
	movl	332(%esp), %ebx
	movl	336(%esp), %esi
	movl	340(%esp), %edi
	movl	344(%esp), %ebp
	addl	$348, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	.cfi_restore 7
	.cfi_restore 6
	.cfi_restore 3
	ret
.L487:
	.cfi_restore_state
	call	__stack_chk_fail
.L482:
	movl	%ebp, %edi
	jmp	.L475
	.cfi_endproc
.LFE117:
	.size	loadseg, .-loadseg
	.p2align 4,,15
	.globl	c2b_str
	.type	c2b_str, @function
c2b_str:
.LFB136:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	movl	8(%esp), %ebx
	movl	W, %eax
	movl	12(%esp), %ecx
	movzbl	(%ebx), %edx
	leal	(%eax,%ecx,4), %ecx
	xorl	%eax, %eax
	testb	%dl, %dl
	je	.L489
	xorl	%eax, %eax
	jmp	.L490
	.p2align 4,,7
	.p2align 3
.L495:
	cmpl	$63, %eax
	jg	.L489
.L490:
	addl	$1, %eax
	movb	%dl, (%ecx,%eax)
	movzbl	(%ebx,%eax), %edx
	testb	%dl, %dl
	jne	.L495
.L489:
	movb	%al, (%ecx)
	popl	%ebx
	.cfi_def_cfa_offset 4
	.cfi_restore 3
	ret
	.cfi_endproc
.LFE136:
	.size	c2b_str, .-c2b_str
	.p2align 4,,15
	.globl	b2c_str
	.type	b2c_str, @function
b2c_str:
.LFB137:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$4, %esp
	.cfi_def_cfa_offset 24
	movl	24(%esp), %edx
	movl	28(%esp), %eax
	leal	0(,%edx,4), %ecx
	testl	%edx, %edx
	movl	%ecx, (%esp)
	movl	W, %ecx
	movzbl	(%ecx,%edx,4), %esi
	je	.L501
	movl	%esi, %ebx
	movl	%eax, %edi
	testb	%bl, %bl
	je	.L498
	movl	(%esp), %edx
	movzbl	%bl, %edi
	movl	%eax, %ebx
	subl	(%esp), %ebx
	addl	$1, %edx
	leal	(%edx,%edi), %esi
	jmp	.L500
	.p2align 4,,7
	.p2align 3
.L503:
	movl	W, %ecx
.L500:
	movzbl	(%ecx,%edx), %ecx
	movb	%cl, -1(%ebx,%edx)
	addl	$1, %edx
	cmpl	%esi, %edx
	jne	.L503
	addl	%eax, %edi
.L498:
	movb	$0, (%edi)
	addl	$4, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
	.p2align 4,,7
	.p2align 3
.L501:
	.cfi_restore_state
	addl	$4, %esp
	.cfi_def_cfa_offset 20
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
.LFE137:
	.size	b2c_str, .-b2c_str
	.section	.rodata.str1.1
.LC30:
	.string	"syscin/"
	.text
	.p2align 4,,15
	.globl	syscin2b_str
	.type	syscin2b_str, @function
syscin2b_str:
.LFB138:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	movl	$115, %ecx
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	movl	16(%esp), %eax
	xorl	%edx, %edx
	movl	12(%esp), %esi
	leal	0(,%eax,4), %ebx
	addl	W, %ebx
	.p2align 4,,7
	.p2align 3
.L505:
	addl	$1, %edx
	movb	%cl, (%ebx,%edx)
	movzbl	.LC30(%edx), %ecx
	testb	%cl, %cl
	jne	.L505
	movzbl	(%esi), %ecx
	testb	%cl, %cl
	je	.L506
	subl	%edx, %esi
	.p2align 4,,7
	.p2align 3
.L508:
	addl	$1, %edx
	movb	%cl, (%ebx,%edx)
	movzbl	(%esi,%edx), %ecx
	testb	%cl, %cl
	jne	.L508
.L506:
	movb	%dl, (%ebx)
	popl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 4
	.cfi_restore 6
	ret
	.cfi_endproc
.LFE138:
	.size	syscin2b_str, .-syscin2b_str
	.p2align 4,,15
	.globl	catstr2c_str
	.type	catstr2c_str, @function
catstr2c_str:
.LFB139:
	.cfi_startproc
	pushl	%esi
	.cfi_def_cfa_offset 8
	.cfi_offset 6, -8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_offset 3, -12
	movl	12(%esp), %ecx
	movl	20(%esp), %eax
	movl	16(%esp), %esi
	testl	%ecx, %ecx
	movl	%eax, %edx
	je	.L512
	movzbl	(%ecx), %ebx
	testb	%bl, %bl
	je	.L517
	.p2align 4,,7
	.p2align 3
.L514:
	addl	$1, %ecx
	movb	%bl, (%edx)
	movzbl	(%ecx), %ebx
	addl	$1, %edx
	testb	%bl, %bl
	jne	.L514
	testl	%ecx, %ecx
	je	.L512
.L513:
	movzbl	(%esi), %ecx
	testb	%cl, %cl
	je	.L512
	movl	%esi, %ebx
	.p2align 4,,7
	.p2align 3
.L515:
	addl	$1, %ebx
	movb	%cl, (%edx)
	movzbl	(%ebx), %ecx
	addl	$1, %edx
	testb	%cl, %cl
	jne	.L515
.L512:
	movb	$0, (%edx)
	popl	%ebx
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 4
	.cfi_restore 6
	ret
.L517:
	.cfi_restore_state
	movl	%eax, %edx
	jmp	.L513
	.cfi_endproc
.LFE139:
	.size	catstr2c_str, .-catstr2c_str
	.section	.rodata.str1.4
	.align 4
.LC31:
	.string	"     -     K   LLP     L    LP    SP    AP     A"
	.section	.rodata.str1.1
.LC32:
	.string	"  "
	.text
	.p2align 4,,15
	.globl	wrcode
	.type	wrcode, @function
wrcode:
.LFB140:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movl	$.LC31, %esi
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$44, %esp
	.cfi_def_cfa_offset 64
	movl	68(%esp), %edx
	movl	72(%esp), %eax
	movl	64(%esp), %ebp
	movl	%eax, 28(%esp)
	movl	%edx, %eax
	andl	$31, %edx
	sarl	$5, %eax
	subl	$1, %edx
	andl	$7, %eax
	cmpl	$30, %edx
	ja	.L521
	movl	CSWTCH.261(,%edx,4), %esi
.L521:
	leal	(%eax,%eax,2), %ebx
	addl	%ebx, %ebx
	leal	5(%ebx), %edi
	.p2align 4,,7
	.p2align 3
.L522:
	movl	stdout, %eax
	movl	%eax, 4(%esp)
	movsbl	(%esi,%ebx), %eax
	addl	$1, %ebx
	movl	%eax, (%esp)
	call	_IO_putc
	cmpl	%edi, %ebx
	jle	.L522
	movl	$.LC32, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	28(%esp), %eax
	movl	%ebp, 4(%esp)
	movl	$1, (%esp)
	movl	%eax, 8(%esp)
	call	__printf_chk
	movl	$10, 64(%esp)
	addl	$44, %esp
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	jmp	putchar
	.cfi_endproc
.LFE140:
	.size	wrcode, .-wrcode
	.p2align 4,,15
	.globl	wrfcode
	.type	wrfcode, @function
wrfcode:
.LFB141:
	.cfi_startproc
	pushl	%edi
	.cfi_def_cfa_offset 8
	.cfi_offset 7, -8
	pushl	%esi
	.cfi_def_cfa_offset 12
	.cfi_offset 6, -12
	movl	$.LC31, %esi
	pushl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	subl	$16, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %edx
	movl	%edx, %eax
	andl	$31, %edx
	sarl	$5, %eax
	subl	$1, %edx
	andl	$7, %eax
	cmpl	$30, %edx
	ja	.L526
	movl	CSWTCH.261(,%edx,4), %esi
.L526:
	leal	(%eax,%eax,2), %ebx
	addl	%ebx, %ebx
	leal	5(%ebx), %edi
	.p2align 4,,7
	.p2align 3
.L527:
	movl	stdout, %eax
	movl	%eax, 4(%esp)
	movsbl	(%esi,%ebx), %eax
	addl	$1, %ebx
	movl	%eax, (%esp)
	call	_IO_putc
	cmpl	%edi, %ebx
	jle	.L527
	addl	$16, %esp
	.cfi_def_cfa_offset 16
	popl	%ebx
	.cfi_def_cfa_offset 12
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 8
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 4
	.cfi_restore 7
	ret
	.cfi_endproc
.LFE141:
	.size	wrfcode, .-wrfcode
	.section	.rodata.str1.1
.LC33:
	.string	"     #G%03d# "
.LC34:
	.string	" %10d "
.LC35:
	.string	" #x%8X "
	.text
	.p2align 4,,15
	.globl	trval
	.type	trval, @function
trval:
.LFB142:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	32(%esp), %eax
	movzwl	%ax, %edx
	cmpl	$1000, %edx
	jle	.L534
.L531:
	leal	10000000(%eax), %edx
	cmpl	$20000000, %edx
	movl	%eax, 8(%esp)
	jbe	.L535
	movl	$.LC35, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
	.p2align 3
.L535:
	.cfi_restore_state
	movl	$.LC34, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
	.p2align 3
.L534:
	.cfi_restore_state
	movl	%eax, %ecx
	xorw	%cx, %cx
	cmpl	$-1886453760, %ecx
	jne	.L531
	movl	%edx, 8(%esp)
	movl	$.LC33, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	addl	$28, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
.LFE142:
	.size	trval, .-trval
	.section	.rodata.str1.1
.LC36:
	.string	"A="
.LC37:
	.string	"B="
.LC38:
	.string	"P=%5d "
.LC39:
	.string	"%9d: "
.LC40:
	.string	"(%3d)"
	.text
	.p2align 4,,15
	.globl	trace
	.type	trace, @function
trace:
.LFB143:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$28, %esp
	.cfi_def_cfa_offset 48
	movl	56(%esp), %edi
	movl	48(%esp), %ebx
	movl	52(%esp), %ebp
	movl	60(%esp), %esi
	movl	$.LC36, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	%edi, %eax
	andl	$65535, %eax
	cmpl	$1000, %eax
	jle	.L547
.L537:
	leal	10000000(%edi), %eax
	cmpl	$20000000, %eax
	movl	%edi, 8(%esp)
	jbe	.L548
	movl	$.LC35, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L538:
	movl	$.LC37, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	%esi, %eax
	andl	$65535, %eax
	cmpl	$1000, %eax
	jle	.L549
.L540:
	leal	10000000(%esi), %eax
	cmpl	$20000000, %eax
	movl	%esi, 8(%esp)
	jbe	.L550
	movl	$.LC35, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L541:
	movl	%ebp, 8(%esp)
	movl	$.LC31, %esi
	movl	$.LC38, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	%ebx, 8(%esp)
	movl	$.LC39, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	W, %eax
	movzbl	(%eax,%ebx), %edx
	movzbl	1(%eax,%ebx), %ebp
	movl	%edx, %eax
	andl	$31, %edx
	subl	$1, %edx
	sarl	$5, %eax
	cmpl	$30, %edx
	ja	.L543
	movl	CSWTCH.261(,%edx,4), %esi
.L543:
	leal	(%eax,%eax,2), %ebx
	addl	%ebx, %ebx
	leal	5(%ebx), %edi
	.p2align 4,,7
	.p2align 3
.L544:
	movl	stdout, %eax
	movl	%eax, 4(%esp)
	movsbl	(%esi,%ebx), %eax
	addl	$1, %ebx
	movl	%eax, (%esp)
	call	_IO_putc
	cmpl	%ebx, %edi
	jge	.L544
	movl	$.LC32, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	%ebp, 8(%esp)
	movl	$.LC40, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	$10, (%esp)
	call	putchar
	movl	stdout, %eax
	movl	$13, 48(%esp)
	movl	%eax, 52(%esp)
	addl	$28, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	jmp	_IO_putc
	.p2align 4,,7
	.p2align 3
.L548:
	.cfi_restore_state
	movl	$.LC34, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	jmp	.L538
	.p2align 4,,7
	.p2align 3
.L550:
	movl	$.LC34, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	jmp	.L541
	.p2align 4,,7
	.p2align 3
.L547:
	movl	%edi, %edx
	xorw	%dx, %dx
	cmpl	$-1886453760, %edx
	jne	.L537
	movl	%eax, 8(%esp)
	movl	$.LC33, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	jmp	.L538
	.p2align 4,,7
	.p2align 3
.L549:
	movl	%esi, %edx
	xorw	%dx, %dx
	cmpl	$-1886453760, %edx
	jne	.L540
	movl	%eax, 8(%esp)
	movl	$.LC33, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	jmp	.L541
	.cfi_endproc
.LFE143:
	.size	trace, .-trace
	.section	.rodata.str1.1
.LC41:
	.string	"wb"
.LC42:
	.string	"DUMP.mem"
	.text
	.p2align 4,,15
	.globl	dumpmem
	.type	dumpmem, @function
dumpmem:
.LFB144:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$76, %esp
	.cfi_def_cfa_offset 96
	movl	100(%esp), %esi
	movl	96(%esp), %ebx
	movl	$.LC41, 4(%esp)
	movl	$.LC42, (%esp)
	movl	%esi, 56(%esp)
	call	fopen
	testl	%eax, %eax
	movl	%eax, 24(%esp)
	je	.L551
	movl	W, %edx
	movl	lastWp, %eax
	subl	%edx, %eax
	sarl	$2, %eax
	movl	%eax, 516(%ebx)
	movl	lastWg, %eax
	subl	%edx, %eax
	sarl	$2, %eax
	movl	%eax, 520(%ebx)
	movl	lastst, %eax
	movl	%eax, 524(%ebx)
	movl	104(%esp), %eax
	movl	%eax, 512(%ebx)
	leal	44(%esp), %eax
	movl	%eax, (%esp)
	call	ftime
	movswl	50(%esp), %eax
	movl	44(%esp), %edi
	imull	$60, %eax, %eax
	movl	%edi, %ebp
	sarl	$31, %ebp
	movl	%eax, %edx
	sarl	$31, %edx
	subl	%eax, %edi
	movzwl	48(%esp), %eax
	sbbl	%edx, %ebp
	movl	%eax, 28(%esp)
	movl	W, %eax
	imull	$60, 532(%eax), %eax
	movl	$86400, 8(%esp)
	movl	$0, 12(%esp)
	movl	%eax, %edx
	sarl	$31, %edx
	addl	%eax, %edi
	adcl	%edx, %ebp
	movl	%edi, (%esp)
	movl	%ebp, 4(%esp)
	call	__divdi3
	movl	%eax, 560(%ebx)
	movl	$86400, 8(%esp)
	movl	$0, 12(%esp)
	movl	%edi, (%esp)
	movl	%ebp, 4(%esp)
	call	__moddi3
	movl	$-1, 568(%ebx)
	imull	$1000, %eax, %eax
	addl	28(%esp), %eax
	movl	%eax, 564(%ebx)
	movl	24(%esp), %eax
	movl	$1, 8(%esp)
	movl	$4, 4(%esp)
	movl	%eax, 12(%esp)
	leal	56(%esp), %eax
	movl	%eax, (%esp)
	call	fwrite
	cmpl	$1, %eax
	je	.L568
.L553:
	movl	24(%esp), %eax
	movl	%eax, (%esp)
	call	fclose
.L552:
.L551:
	addl	$76, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
	.p2align 4,,7
	.p2align 3
.L568:
	.cfi_restore_state
	testl	%esi, %esi
	js	.L553
	xorl	%ebp, %ebp
	xorl	%edx, %edx
	.p2align 4,,7
	.p2align 3
.L554:
	movl	(%ebx,%ebp,4), %eax
	movl	%ebp, %edi
	movl	%eax, 60(%esp)
.L555:
	addl	$1, %edi
	cmpl	(%ebx,%edi,4), %eax
	je	.L557
	cmpl	%edi, %esi
	jl	.L556
	movl	%edi, %eax
	subl	%ebp, %eax
	cmpl	$199, %eax
	jle	.L558
.L556:
	movl	%ebp, %eax
	subl	%edx, %eax
	testl	%eax, %eax
	movl	%eax, 56(%esp)
	jne	.L569
.L559:
	subl	%edi, %ebp
	testl	%ebp, %ebp
	movl	%ebp, 56(%esp)
	jne	.L570
.L560:
	cmpl	%edi, %esi
	jl	.L553
	movl	%edi, %edx
.L558:
	movl	%edi, %ebp
	jmp	.L554
	.p2align 4,,7
	.p2align 3
.L557:
	cmpl	%edi, %esi
	jge	.L555
	movl	%ebp, %eax
	subl	%edx, %eax
	testl	%eax, %eax
	movl	%eax, 56(%esp)
	je	.L559
	.p2align 4,,7
	.p2align 3
.L569:
	movl	24(%esp), %eax
	movl	%edx, 20(%esp)
	movl	$1, 8(%esp)
	movl	$4, 4(%esp)
	movl	%eax, 12(%esp)
	leal	56(%esp), %eax
	movl	%eax, (%esp)
	call	fwrite
	movl	20(%esp), %edx
	cmpl	$1, %eax
	jne	.L553
	movl	24(%esp), %eax
	movl	$4, 4(%esp)
	movl	%eax, 12(%esp)
	movl	56(%esp), %eax
	movl	%eax, 8(%esp)
	leal	(%ebx,%edx,4), %eax
	movl	%eax, (%esp)
	call	fwrite
	cmpl	56(%esp), %eax
	jne	.L553
	subl	%edi, %ebp
	testl	%ebp, %ebp
	movl	%ebp, 56(%esp)
	je	.L560
.L570:
	movl	24(%esp), %eax
	movl	$1, 8(%esp)
	movl	$4, 4(%esp)
	movl	%eax, 12(%esp)
	leal	56(%esp), %eax
	movl	%eax, (%esp)
	call	fwrite
	cmpl	$1, %eax
	jne	.L553
	movl	24(%esp), %eax
	movl	$1, 8(%esp)
	movl	$4, 4(%esp)
	movl	%eax, 12(%esp)
	leal	60(%esp), %eax
	movl	%eax, (%esp)
	call	fwrite
	cmpl	$1, %eax
	je	.L560
	jmp	.L553
	.cfi_endproc
.LFE144:
	.size	dumpmem, .-dumpmem
	.section	.rodata.str1.1
.LC43:
	.string	"-cin"
.LC44:
	.string	"-slow"
.LC45:
	.string	"missing parameter for -s\n"
.LC46:
	.string	"c"
.LC47:
	.string	"Unknown command option: %s\n"
.LC48:
	.string	"\nValid arguments:\n"
	.section	.rodata.str1.4
	.align 4
.LC49:
	.string	"-h            Output this help information"
	.align 4
.LC50:
	.string	"-m n          Set Cintcode memory size to n words"
	.align 4
.LC51:
	.string	"-t n          Set Tally vector size to n words"
	.align 4
.LC52:
	.string	"-c args       Pass args to interpreter as standard input (executable bytecode)"
	.align 4
.LC53:
	.string	"-- args       Pass args to interpreter standard input, then re-attach stdin"
	.align 4
.LC54:
	.string	"-s file args  Invoke command interpreter on file with args (executable scripts)"
	.align 4
.LC55:
	.string	"-cin name     Set the pathvar environment variable name"
	.align 4
.LC56:
	.string	"-f            Trace the use of environment variables in pathinput"
	.align 4
.LC57:
	.string	"-v            Trace the bootstrapping process"
	.align 4
.LC58:
	.string	"-v -v         As -v, but also include some Cincode level tracing"
	.align 4
.LC59:
	.string	"-d            Cause a dump of the Cintcode memory to DUMP.mem"
	.align 4
.LC60:
	.string	"              if a fault/error is encountered"
	.align 4
.LC61:
	.string	"-slow         Force the slow interpreter to always be selected"
	.align 4
.LC62:
	.string	"Boot tracing level is set to %d\n"
	.section	.rodata.str1.1
.LC63:
	.string	"Bad -m or -t size"
.LC64:
	.string	"\ncintsys 25 Jan 2012  11:08\n"
.LC65:
	.string	"ABCD1234"
.LC66:
	.string	"bytestr=%s word 0 = %8X\n"
.LC67:
	.string	"BIGENDER is not defined"
.LC68:
	.string	"sizeof(int)        = %d\n"
.LC69:
	.string	"sizeof(long)       = %d\n"
.LC70:
	.string	"sizeof(BCPLWORD)   = %d\n"
.LC71:
	.string	"sizeof(BCPLWORD *) = %d\n"
.LC72:
	.string	"d"
.LC73:
	.string	"FormD is \"%s\"\n"
.LC74:
	.string	"X"
.LC75:
	.string	"FormX is \"%s\"\n"
.LC76:
	.string	"W=%d %8x\n"
	.section	.rodata.str1.4
	.align 4
.LC77:
	.string	"Insufficient memory for memvec"
	.align 4
.LC78:
	.string	"Cintcode memory (upb=%d) allocated\n"
	.align 4
.LC79:
	.string	"The root node was at %d not at %d\n"
	.section	.rodata.str1.1
.LC80:
	.string	"BCPLROOT"
.LC81:
	.string	"BCPLHDRS"
.LC82:
	.string	"BCPLSCRIPTS"
.LC83:
	.string	"Environment variable %s"
.LC84:
	.string	"Boot's stack allocated at %d\n"
	.section	.rodata.str1.4
	.align 4
.LC85:
	.string	"Boot's global vector allocated at %d\n"
	.section	.rodata.str1.1
.LC86:
	.string	"Rootnode allocated at %d\n"
	.section	.rodata.str1.4
	.align 4
.LC87:
	.string	"Loading all resident programs and libraries"
	.section	.rodata.str1.1
.LC88:
	.string	"syscin/boot"
.LC89:
	.string	"\nUnable to find syscin/boot"
	.section	.rodata.str1.4
	.align 4
.LC90:
	.string	"This is probably caused by incorrect settings of"
	.align 4
.LC91:
	.string	"environment variables such as BCPLROOT and BCPLPATH"
	.align 4
.LC92:
	.string	"Try entering cintsys using the command"
	.section	.rodata.str1.1
.LC93:
	.string	"\ncintsys -f -v\n"
.LC94:
	.string	"to see what is happening"
.LC95:
	.string	"Can't globin boot"
	.section	.rodata.str1.4
	.align 4
.LC96:
	.string	"syscin/boot loaded successfully"
	.section	.rodata.str1.1
.LC97:
	.string	"syscin/blib"
.LC98:
	.string	"Can't load syscin/blib"
	.section	.rodata.str1.4
	.align 4
.LC99:
	.string	"syscin/blib loaded successfully"
	.section	.rodata.str1.1
.LC100:
	.string	"syscin/syslib"
.LC101:
	.string	"Can't load syscin/syslib"
	.section	.rodata.str1.4
	.align 4
.LC102:
	.string	"syscin/syslib loaded successfully"
	.section	.rodata.str1.1
.LC103:
	.string	"syscin/dlib"
.LC104:
	.string	"Can't load syscin/dlib"
	.section	.rodata.str1.4
	.align 4
.LC105:
	.string	"syscin/dlib loaded successfully"
	.align 4
.LC106:
	.string	"Can't globin {blib,syslib,dlib}"
	.section	.rodata.str1.1
.LC107:
	.string	"Calling the interpreter"
	.section	.rodata.str1.4
	.align 4
.LC108:
	.string	"Cintsys: Turning instruction tracing on"
	.align 4
.LC109:
	.string	"interpreter returned control to cintsys, res=%d\n"
	.align 4
.LC110:
	.string	"\nExecution finished, return code %d\n"
	.align 4
.LC111:
	.string	"\nCintpos memory dumped to DUMP.mem, context=3"
	.align 4
.LC112:
	.string	" but the host machine is a big ender"
	.section	.text.startup,"ax",@progbits
	.p2align 4,,15
	.globl	main
	.type	main, @function
main:
.LFB114:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	andl	$-16, %esp
	subl	$48, %esp
	movl	12(%ebp), %edx
	movl	$0, taskname
	movl	$0, taskname+4
	movl	$0, taskname+8
	movl	%edx, 40(%esp)
	movl	$0, taskname+12
	movl	$4000000, memupb
	movl	$1000000, tallyupb
	movl	$20000, vecstatsvupb
	.cfi_offset 3, -20
	.cfi_offset 6, -16
	.cfi_offset 7, -12
	call	getpid
	movl	40(%esp), %edx
	cmpl	$1, 8(%ebp)
	movl	%eax, mainpid
	jle	.L572
	movl	$1, %ebx
	movl	%edx, 36(%esp)
	jmp	.L593
	.p2align 4,,7
	.p2align 3
.L649:
	cmpb	$109, 1(%eax)
	jne	.L574
	cmpb	$0, 2(%eax)
	jne	.L574
	addl	$1, %ebx
	movl	$10, 8(%esp)
	movl	$0, 4(%esp)
	movl	(%edx,%ebx,4), %eax
	movl	%eax, (%esp)
	call	strtol
	movl	%eax, memupb
.L575:
	addl	$1, %ebx
	cmpl	%ebx, 8(%ebp)
	jle	.L572
.L593:
	movl	36(%esp), %edx
	movl	(%edx,%ebx,4), %eax
	movzbl	(%eax), %ecx
	subl	$45, %ecx
	movl	%ecx, 44(%esp)
	je	.L649
.L573:
	movl	$.LC43, %edi
	movl	%eax, %esi
	movl	$5, %ecx
	repz cmpsb
	jne	.L576
	movl	36(%esp), %edx
	addl	$1, %ebx
	movl	(%edx,%ebx,4), %eax
	addl	$1, %ebx
	cmpl	%ebx, 8(%ebp)
	movl	%eax, pathvar
	jg	.L593
.L572:
	movl	boottrace, %eax
	testl	%eax, %eax
	jle	.L594
	movl	%eax, 8(%esp)
	movl	$.LC62, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L594:
	cmpl	$49999, memupb
	jle	.L595
	cmpl	$0, tallyupb
	js	.L595
	cmpl	$0, boottrace
	jne	.L650
.L597:
	movl	memupb, %eax
	addl	tallyupb, %eax
	addl	vecstatsvupb, %eax
	movl	$30, (%esp)
	leal	28(,%eax,4), %ebx
	call	sysconf
	movl	$0, 20(%esp)
	movl	$0, 16(%esp)
	movl	$34, 12(%esp)
	movl	$7, 8(%esp)
	movl	%ebx, 4(%esp)
	movl	$0, (%esp)
	call	mmap
	movl	$.LC76, 4(%esp)
	movl	$1, (%esp)
	movl	%eax, W
	movl	%eax, 12(%esp)
	movl	%eax, 8(%esp)
	call	__printf_chk
	movl	W, %ecx
	testl	%ecx, %ecx
	je	.L651
	movl	memupb, %edx
	addl	$7, %ecx
	andl	$-8, %ecx
	movl	%ecx, W
	movl	%ecx, lastWp
	testl	%edx, %edx
	movl	%ecx, lastWg
	movl	$3, lastst
	jle	.L600
	xorl	%eax, %eax
	.p2align 4,,7
	.p2align 3
.L601:
	movl	$-559038242, (%ecx,%eax,4)
	movl	memupb, %edx
	addl	$1, %eax
	cmpl	%eax, %edx
	jg	.L601
.L600:
	cmpl	$0, boottrace
	jle	.L602
	movl	%edx, 8(%esp)
	movl	$.LC78, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	memupb, %edx
.L602:
	movl	W, %ebx
	addl	$1, %edx
	movl	%edx, (%ebx)
	movl	memupb, %eax
	movl	$0, (%ebx,%eax,4)
	movl	memupb, %eax
	movl	$0, tallylim
	addl	$1, %eax
	leal	(%ebx,%eax,4), %ecx
	movl	%eax, tallyvec
	movl	tallyupb, %eax
	movl	%ecx, tallyv
	movl	%eax, (%ecx)
	movl	tallyupb, %edx
	testl	%edx, %edx
	jle	.L603
	movl	$1, %eax
	.p2align 4,,7
	.p2align 3
.L604:
	movl	$0, (%ecx,%eax,4)
	movl	tallyupb, %edx
	addl	$1, %eax
	cmpl	%eax, %edx
	jge	.L604
.L603:
	movl	tallyvec, %eax
	addl	%edx, %eax
	addl	$1, %eax
	cmpl	$0, vecstatsvupb
	leal	(%ebx,%eax,4), %edx
	movl	%eax, vecstatsvec
	movl	%edx, vecstatsv
	js	.L605
	xorl	%eax, %eax
	.p2align 4,,7
	.p2align 3
.L606:
	movl	$0, (%edx,%eax,4)
	addl	$1, %eax
	cmpl	%eax, vecstatsvupb
	jge	.L606
.L605:
	movl	$88, (%esp)
	call	getvec
	movl	$100, (%esp)
	call	getvec
	addl	$1, %eax
	cmpl	$100, %eax
	je	.L607
	movl	$100, 12(%esp)
	movl	%eax, 8(%esp)
	movl	$.LC79, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L607:
	movl	$80, (%esp)
	call	getvec
	movl	W, %ecx
	leal	16(%eax), %edx
	movl	%edx, pathvarstr
	leal	32(%eax), %edx
	movl	%eax, rootvarstr
	movl	%edx, hdrsvarstr
	leal	48(%eax), %edx
	addl	$64, %eax
	movl	%eax, prefixstr
	leal	(%ecx,%eax,4), %eax
	movl	%eax, prefixbp
	xorl	%eax, %eax
	movl	%edx, scriptsvarstr
	.p2align 4,,7
	.p2align 3
.L608:
	movl	rootvarstr, %edx
	addl	%eax, %edx
	addl	$1, %eax
	cmpl	$81, %eax
	movl	$0, (%ecx,%edx,4)
	jne	.L608
	movl	rootvarstr, %eax
	movl	$.LC80, (%esp)
	movl	%eax, 4(%esp)
	call	c2b_str
	movl	pathvarstr, %eax
	movl	%eax, 4(%esp)
	movl	pathvar, %eax
	movl	%eax, (%esp)
	call	c2b_str
	movl	hdrsvarstr, %eax
	movl	$.LC81, (%esp)
	movl	%eax, 4(%esp)
	call	c2b_str
	movl	scriptsvarstr, %eax
	movl	$.LC82, (%esp)
	movl	%eax, 4(%esp)
	call	c2b_str
	movl	$511, (%esp)
	call	getvec
	movl	W, %ecx
	movl	%eax, dcountv
	movl	$511, (%ecx,%eax,4)
	movl	$1, %eax
	.p2align 4,,7
	.p2align 3
.L609:
	movl	dcountv, %edx
	addl	%eax, %edx
	addl	$1, %eax
	cmpl	$512, %eax
	movl	$0, (%ecx,%edx,4)
	jne	.L609
	cmpl	$0, filetracing
	jne	.L652
.L610:
	movl	$506, (%esp)
	call	getvec
	movl	$1000, (%esp)
	movl	%eax, stackbase
	call	getvec
	cmpl	$0, boottrace
	movl	$0, result2
	movl	%eax, globbase
	jle	.L611
	movl	stackbase, %eax
	movl	$.LC84, 4(%esp)
	movl	$1, (%esp)
	movl	%eax, 8(%esp)
	call	__printf_chk
.L611:
	movl	stackbase, %eax
	movl	W, %edx
	movl	$500, (%edx,%eax,4)
	movl	$1, %eax
	.p2align 4,,7
	.p2align 3
.L612:
	movl	stackbase, %ecx
	addl	%eax, %ecx
	addl	$1, %eax
	cmpl	$507, %eax
	movl	$-1412623820, (%edx,%ecx,4)
	jne	.L612
	cmpl	$0, boottrace
	jle	.L613
	movl	globbase, %eax
	movl	$.LC85, 4(%esp)
	movl	$1, (%esp)
	movl	%eax, 8(%esp)
	call	__printf_chk
	movl	W, %edx
.L613:
	xorl	%eax, %eax
	.p2align 4,,7
	.p2align 3
.L614:
	movl	globbase, %ecx
	leal	-1886453760(%eax), %ebx
	addl	%eax, %ecx
	addl	$1, %eax
	cmpl	$1001, %eax
	movl	%ebx, (%edx,%ecx,4)
	jne	.L614
	movl	globbase, %eax
	movl	$1000, (%edx,%eax,4)
	movl	globbase, %eax
	movl	$100, 36(%edx,%eax,4)
	xorl	%eax, %eax
	.p2align 4,,7
	.p2align 3
.L615:
	movl	$0, 400(%edx,%eax,4)
	addl	$1, %eax
	cmpl	$51, %eax
	jne	.L615
	movl	dumpflag, %ecx
	movl	memupb, %eax
	movl	$0, 452(%edx)
	movl	$0, 416(%edx)
	movl	%ecx, 500(%edx)
	movl	rootvarstr, %ecx
	movl	%eax, 456(%edx)
	movl	tallyvec, %eax
	movl	%edx, 572(%edx)
	movl	$0, 576(%edx)
	movl	%ecx, 540(%edx)
	movl	pathvarstr, %ecx
	movl	%eax, 420(%edx)
	movl	vecstatsvec, %eax
	movl	$mcprf, 580(%edx)
	movl	$0, 584(%edx)
	movl	%ecx, 544(%edx)
	movl	hdrsvarstr, %ecx
	movl	%eax, 488(%edx)
	movl	vecstatsvupb, %eax
	movl	%ecx, 548(%edx)
	movl	scriptsvarstr, %ecx
	movl	%eax, 492(%edx)
	movl	boottrace, %eax
	movl	%ecx, 552(%edx)
	movl	dcountv, %ecx
	testl	%eax, %eax
	movl	%eax, 556(%edx)
	movl	%ecx, 536(%edx)
	jle	.L616
	movl	$100, 8(%esp)
	movl	$.LC86, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L616:
	cmpl	$0, boottrace
	jle	.L617
	movl	$.LC87, (%esp)
	call	puts
.L617:
	movl	$.LC88, (%esp)
	call	loadseg
	testl	%eax, %eax
	jne	.L618
	movl	$.LC89, (%esp)
	call	puts
	movl	$.LC90, (%esp)
	call	puts
	movl	$.LC91, (%esp)
	call	puts
	movl	$.LC92, (%esp)
	call	puts
	movl	$.LC93, (%esp)
	call	puts
	movl	$.LC94, (%esp)
	call	puts
	movl	$20, %eax
	jmp	.L592
	.p2align 4,,7
	.p2align 3
.L574:
	cmpb	$116, 1(%eax)
	jne	.L573
	cmpb	$0, 2(%eax)
	jne	.L573
	movl	36(%esp), %edx
	addl	$1, %ebx
	movl	$10, 8(%esp)
	movl	$0, 4(%esp)
	movl	(%edx,%ebx,4), %eax
	movl	%eax, (%esp)
	call	strtol
	movl	%eax, tallyupb
	jmp	.L575
	.p2align 4,,7
	.p2align 3
.L576:
	movl	44(%esp), %ecx
	testl	%ecx, %ecx
	je	.L653
.L577:
	movl	$.LC44, %edi
	movl	%eax, %esi
	movl	$6, %ecx
	repz cmpsb
	jne	.L579
	movl	$1, slowflag
	jmp	.L575
	.p2align 4,,7
	.p2align 3
.L653:
	cmpb	$102, 1(%eax)
	jne	.L578
	cmpb	$0, 2(%eax)
	jne	.L578
	movl	$1, filetracing
	jmp	.L575
	.p2align 4,,7
	.p2align 3
.L578:
	cmpb	$100, 1(%eax)
	jne	.L577
	cmpb	$0, 2(%eax)
	jne	.L577
	movl	$1, dumpflag
	jmp	.L575
	.p2align 4,,7
	.p2align 3
.L579:
	movl	44(%esp), %edx
	testl	%edx, %edx
	jne	.L580
	cmpb	$115, 1(%eax)
	jne	.L581
	cmpb	$0, 2(%eax)
	je	.L654
.L581:
	cmpb	$45, 1(%eax)
	jne	.L583
	cmpb	$0, 2(%eax)
	jne	.L583
	movl	$1, reattach_stdin
.L583:
	cmpb	$45, (%eax)
	jne	.L590
	cmpb	$99, 1(%eax)
	jne	.L585
	cmpb	$0, 2(%eax)
	je	.L655
.L587:
	cmpb	$118, 1(%eax)
	jne	.L588
	cmpb	$0, 2(%eax)
	jne	.L589
	movl	$1, boottrace
	jmp	.L575
.L595:
	movl	$.LC63, (%esp)
	call	puts
	movl	$10, %eax
.L592:
	leal	-12(%ebp), %esp
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%edi
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa 4, 4
	.cfi_restore 5
	ret
.L580:
	.cfi_restore_state
	cmpb	$45, (%eax)
	je	.L588
.L590:
	movl	%eax, 8(%esp)
	movl	$.LC47, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L591:
	movl	$.LC48, (%esp)
	call	puts
	movl	$.LC49, (%esp)
	call	puts
	movl	$.LC50, (%esp)
	call	puts
	movl	$.LC51, (%esp)
	call	puts
	movl	$.LC52, (%esp)
	call	puts
	movl	$.LC53, (%esp)
	call	puts
	movl	$.LC54, (%esp)
	call	puts
	movl	$.LC55, (%esp)
	call	puts
	movl	$.LC56, (%esp)
	call	puts
	movl	$.LC57, (%esp)
	call	puts
	movl	$.LC58, (%esp)
	call	puts
	movl	$.LC59, (%esp)
	call	puts
	movl	$.LC60, (%esp)
	call	puts
	movl	$.LC61, (%esp)
	call	puts
	xorl	%eax, %eax
	jmp	.L592
.L585:
	cmpb	$45, 1(%eax)
	jne	.L587
	cmpb	$0, 2(%eax)
	movl	36(%esp), %edx
	je	.L586
.L588:
	cmpb	$104, 1(%eax)
	jne	.L590
	cmpb	$0, 2(%eax)
	je	.L591
	.p2align 4,,3
	jmp	.L590
.L618:
	movl	globbase, %edx
	movl	W, %ebx
	movl	%eax, (%esp)
	movl	%edx, 4(%esp)
	call	globin
	movl	%eax, 468(%ebx)
	movl	W, %eax
	cmpl	$0, 468(%eax)
	je	.L656
	cmpl	$0, boottrace
	jle	.L620
	movl	$.LC96, (%esp)
	call	puts
.L620:
	movl	$.LC97, (%esp)
	call	loadseg
	testl	%eax, %eax
	movl	%eax, %ebx
	je	.L657
	cmpl	$0, boottrace
	jle	.L622
	movl	$.LC99, (%esp)
	call	puts
.L622:
	movl	$.LC100, (%esp)
	call	loadseg
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	concatsegs
	testl	%eax, %eax
	movl	%eax, %ebx
	je	.L658
	cmpl	$0, boottrace
	jle	.L624
	movl	$.LC102, (%esp)
	call	puts
.L624:
	movl	$.LC103, (%esp)
	call	loadseg
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	concatsegs
	testl	%eax, %eax
	movl	%eax, %ebx
	je	.L659
	cmpl	$0, boottrace
	jle	.L626
	movl	$.LC105, (%esp)
	call	puts
.L626:
	movl	globbase, %eax
	movl	W, %esi
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	globin
	movl	%eax, 476(%esi)
	movl	W, %eax
	cmpl	$0, 476(%eax)
	jne	.L627
	movl	$.LC106, (%esp)
	call	puts
	movl	$20, %eax
	jmp	.L592
.L650:
	movl	$.LC64, (%esp)
	call	puts
	movl	.LC65, %ebx
	movl	$.LC65, 8(%esp)
	movl	$.LC66, 4(%esp)
	movl	$1, (%esp)
	movl	%ebx, 12(%esp)
	call	__printf_chk
	cmpb	$65, %bl
	movl	$.LC67, 4(%esp)
	movl	$1, (%esp)
	je	.L598
	call	__printf_chk
.L632:
	movl	$10, (%esp)
	call	putchar
	movl	$4, 8(%esp)
	movl	$.LC68, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	$4, 8(%esp)
	movl	$.LC69, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	$4, 8(%esp)
	movl	$.LC70, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	$4, 8(%esp)
	movl	$.LC71, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	$.LC72, 8(%esp)
	movl	$.LC73, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	$.LC74, 8(%esp)
	movl	$.LC75, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	jmp	.L597
.L652:
	movl	$.LC80, (%esp)
	call	getenv
	movl	$.LC80, 8(%esp)
	movl	$.LC83, 4(%esp)
	movl	$1, (%esp)
	movl	%eax, %ebx
	call	__printf_chk
	movl	%ebx, 8(%esp)
	movl	$.LC24, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	pathvar, %ebx
	movl	%ebx, (%esp)
	call	getenv
	movl	%ebx, 8(%esp)
	movl	$.LC83, 4(%esp)
	movl	$1, (%esp)
	movl	%eax, %esi
	call	__printf_chk
	movl	%esi, 8(%esp)
	movl	$.LC24, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	$.LC81, (%esp)
	call	getenv
	movl	$.LC81, 8(%esp)
	movl	$.LC83, 4(%esp)
	movl	$1, (%esp)
	movl	%eax, %ebx
	call	__printf_chk
	movl	%ebx, 8(%esp)
	movl	$.LC24, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	$.LC82, (%esp)
	call	getenv
	movl	$.LC82, 8(%esp)
	movl	$.LC83, 4(%esp)
	movl	$1, (%esp)
	movl	%eax, %ebx
	call	__printf_chk
	movl	%ebx, 8(%esp)
	movl	$.LC24, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	jmp	.L610
.L656:
	movl	$.LC95, (%esp)
	call	puts
	movl	$20, %eax
	jmp	.L592
.L654:
	movl	36(%esp), %edx
	cmpl	$0, 4(%edx,%ebx,4)
	je	.L660
	movl	%edx, 8(%esp)
	movl	8(%ebp), %edx
	movl	%ebx, 12(%esp)
	movl	$.LC46, (%esp)
	movl	%edx, 4(%esp)
	call	prepend_stdin
	jmp	.L572
.L655:
	movl	36(%esp), %edx
.L586:
	movl	%edx, 8(%esp)
	movl	8(%ebp), %edx
	movl	%ebx, 12(%esp)
	movl	$0, (%esp)
	movl	%edx, 4(%esp)
	call	prepend_stdin
	jmp	.L572
.L598:
	call	__printf_chk
	movl	$.LC112, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	jmp	.L632
.L657:
	movl	$.LC98, (%esp)
	call	puts
	movl	$20, %eax
	jmp	.L592
.L658:
	movl	$.LC101, (%esp)
	call	puts
	movl	$20, %eax
	jmp	.L592
.L651:
	movl	$.LC77, (%esp)
	call	puts
	xorl	%eax, %eax
	jmp	.L592
.L659:
	movl	$.LC104, (%esp)
	call	puts
	movl	$20, %eax
	jmp	.L592
.L627:
	movl	$inthandler, 4(%esp)
	movl	$2, (%esp)
	call	signal
	movl	$segvhandler, 4(%esp)
	movl	$11, (%esp)
	movl	%eax, old_inthandler
	call	signal
	movl	globbase, %edx
	movl	%eax, old_segvhandler
	movl	W, %eax
	movl	12(%eax,%edx,4), %ecx
	movl	%ecx, 464(%eax)
	movl	$0, 28(%eax,%edx,4)
	movl	globbase, %edx
	movl	$0, 32(%eax,%edx,4)
	movl	stackbase, %edx
	movl	$0, 44(%eax)
	movl	$0, 48(%eax)
	movl	$0, 52(%eax)
	sall	$2, %edx
	movl	%edx, 56(%eax)
	movl	globbase, %edx
	movl	$2, 64(%eax)
	leal	0(,%edx,4), %ecx
	movl	%ecx, 60(%eax)
	movl	4(%eax,%edx,4), %edx
	movl	$-1, 72(%eax)
	movl	$0, 76(%eax)
	movl	%edx, 68(%eax)
	call	init_keyb
	cmpl	$0, boottrace
	jle	.L628
	movl	$.LC107, (%esp)
	call	puts
.L628:
	cmpl	$1, boottrace
	jle	.L629
	movl	$.LC108, (%esp)
	call	puts
	movl	$1, tracing
.L629:
	movl	W, %eax
	movl	$11, (%esp)
	movl	%eax, 4(%esp)
	call	interpret
	cmpl	$0, boottrace
	movl	%eax, %ebx
	jle	.L630
	movl	%eax, 8(%esp)
	movl	$.LC109, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L630:
	call	close_keyb
	testl	%ebx, %ebx
	jne	.L661
.L631:
	movl	$10, (%esp)
	call	putchar
	movl	W, %eax
	movl	globbase, %edx
	movl	548(%eax,%edx,4), %eax
	jmp	.L592
.L589:
	cmpb	$118, 2(%eax)
	jne	.L588
	cmpb	$0, 3(%eax)
	jne	.L588
	movl	$2, boottrace
	jmp	.L575
.L660:
	movl	stderr, %eax
	movl	$25, 8(%esp)
	movl	$1, 4(%esp)
	movl	$.LC45, (%esp)
	movl	%eax, 12(%esp)
	call	fwrite
	movl	$-1, (%esp)
	call	exit
.L661:
	movl	%ebx, 8(%esp)
	movl	$.LC110, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	W, %eax
	cmpl	$0, 500(%eax)
	je	.L631
	movl	memupb, %edx
	movl	$3, 8(%esp)
	movl	%eax, (%esp)
	movl	%edx, 4(%esp)
	call	dumpmem
	movl	$.LC111, (%esp)
	call	puts
	jmp	.L631
	.cfi_endproc
.LFE114:
	.size	main, .-main
	.section	.rodata.str1.1
.LC113:
	.string	"\nSIGSEGV received"
.LC114:
	.string	"\nLeaving Cintsys"
	.section	.rodata.str1.4
	.align 4
.LC115:
	.string	"\nMemory dumped to DUMP.mem, context=2"
	.text
	.p2align 4,,15
	.globl	segvhandler
	.type	segvhandler, @function
segvhandler:
.LFB110:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	$.LC113, (%esp)
	call	puts
	movl	old_segvhandler, %eax
	movl	$11, (%esp)
	movl	%eax, 4(%esp)
	call	signal
	movl	%eax, old_segvhandler
	call	close_keyb
	movl	$.LC114, (%esp)
	call	puts
	movl	W, %eax
	movl	500(%eax), %edx
	testl	%edx, %edx
	jne	.L664
.L663:
	movl	$0, (%esp)
	call	exit
.L664:
	movl	lastWp, %edx
	subl	%eax, %edx
	sarl	$2, %edx
	movl	%edx, 516(%eax)
	movl	lastWg, %edx
	subl	%eax, %edx
	sarl	$2, %edx
	movl	%edx, 520(%eax)
	movl	memupb, %edx
	movl	$2, 8(%esp)
	movl	%eax, (%esp)
	movl	%edx, 4(%esp)
	call	dumpmem
	movl	$.LC115, (%esp)
	call	puts
	jmp	.L663
	.cfi_endproc
.LFE110:
	.size	segvhandler, .-segvhandler
	.section	.rodata.str1.1
.LC116:
	.string	"\nSIGINT received"
	.section	.rodata.str1.4
	.align 4
.LC117:
	.string	"\nMemory dumped to DUMP.mem, context=1"
	.text
	.p2align 4,,15
	.globl	inthandler
	.type	inthandler, @function
inthandler:
.LFB109:
	.cfi_startproc
	subl	$28, %esp
	.cfi_def_cfa_offset 32
	movl	$.LC116, (%esp)
	call	puts
	movl	old_inthandler, %eax
	movl	$2, (%esp)
	movl	%eax, 4(%esp)
	call	signal
	movl	%eax, old_inthandler
	call	close_keyb
	movl	$.LC114, (%esp)
	call	puts
	movl	W, %eax
	movl	500(%eax), %ecx
	testl	%ecx, %ecx
	jne	.L667
.L666:
	movl	$0, (%esp)
	call	exit
.L667:
	movl	lastWp, %edx
	subl	%eax, %edx
	sarl	$2, %edx
	movl	%edx, 516(%eax)
	movl	lastWg, %edx
	subl	%eax, %edx
	sarl	$2, %edx
	movl	%edx, 520(%eax)
	movl	memupb, %edx
	movl	$1, 8(%esp)
	movl	%eax, (%esp)
	movl	%edx, 4(%esp)
	call	dumpmem
	movl	$.LC117, (%esp)
	call	puts
	jmp	.L666
	.cfi_endproc
.LFE109:
	.size	inthandler, .-inthandler
	.p2align 4,,15
	.globl	trpush
	.type	trpush, @function
trpush:
.LFB145:
	.cfi_startproc
	subl	$76, %esp
	.cfi_def_cfa_offset 80
	movl	%ebx, 60(%esp)
	movl	trcount, %ebx
	.cfi_offset 3, -20
	movl	%esi, 64(%esp)
	movl	%edi, 68(%esp)
	movl	%ebp, 72(%esp)
	testl	%ebx, %ebx
	js	.L668
	.cfi_offset 5, -8
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	leal	36(%esp), %eax
	movl	%eax, (%esp)
	call	ftime
	movswl	42(%esp), %eax
	movl	36(%esp), %esi
	movl	trcount, %ebx
	imull	$60, %eax, %eax
	movl	%esi, %edi
	sarl	$31, %edi
	movl	%ebx, %ebp
	movl	%eax, %edx
	sarl	$31, %edx
	subl	%eax, %esi
	movzwl	40(%esp), %eax
	sbbl	%edx, %edi
	movl	%eax, 28(%esp)
	movl	W, %eax
	imull	$60, 532(%eax), %eax
	movl	$86400, 8(%esp)
	movl	$0, 12(%esp)
	movl	%eax, %edx
	sarl	$31, %edx
	addl	%eax, %esi
	adcl	%edx, %edi
	andl	$4095, %ebp
	movl	%esi, (%esp)
	movl	%edi, 4(%esp)
	call	__moddi3
	movl	$1172812403, %edx
	imull	$1000, %eax, %ecx
	addl	28(%esp), %ecx
	movl	%ecx, %eax
	imull	%edx
	movl	%ecx, %eax
	sarl	$31, %eax
	sarl	$14, %edx
	subl	%eax, %edx
	imull	$60000, %edx, %edx
	leal	1(%ebx), %eax
	addl	$2, %ebx
	andl	$4095, %eax
	movl	%ebx, trcount
	subl	%edx, %ecx
	movl	80(%esp), %edx
	addl	$1711276032, %ecx
	movl	%ecx, trvec(,%ebp,4)
	movl	%edx, trvec(,%eax,4)
.L668:
	movl	60(%esp), %ebx
	movl	64(%esp), %esi
	movl	68(%esp), %edi
	movl	72(%esp), %ebp
	addl	$76, %esp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	.cfi_restore 7
	.cfi_restore 6
	.cfi_restore 3
	ret
	.cfi_endproc
.LFE145:
	.size	trpush, .-trpush
	.p2align 4,,15
	.globl	settrcount
	.type	settrcount, @function
settrcount:
.LFB146:
	.cfi_startproc
	movl	4(%esp), %edx
	movl	trcount, %eax
	movl	%edx, trcount
	ret
	.cfi_endproc
.LFE146:
	.size	settrcount, .-settrcount
	.p2align 4,,15
	.globl	gettrval
	.type	gettrval, @function
gettrval:
.LFB147:
	.cfi_startproc
	movl	4(%esp), %eax
	andl	$4095, %eax
	movl	trvec(,%eax,4), %eax
	ret
	.cfi_endproc
.LFE147:
	.size	gettrval, .-gettrval
	.p2align 4,,15
	.globl	incdcount
	.type	incdcount, @function
incdcount:
.LFB148:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	movl	8(%esp), %ecx
	movl	$-1, %eax
	movl	W, %edx
	testl	%ecx, %ecx
	movl	536(%edx), %ebx
	jle	.L673
	cmpl	(%edx,%ebx,4), %ecx
	jg	.L673
	addl	%ebx, %ecx
	leal	(%edx,%ecx,4), %edx
	movl	(%edx), %eax
	addl	$1, %eax
	movl	%eax, (%edx)
.L673:
	popl	%ebx
	.cfi_def_cfa_offset 4
	.cfi_restore 3
	ret
	.cfi_endproc
.LFE148:
	.size	incdcount, .-incdcount
	.p2align 4,,15
	.globl	soundfn
	.type	soundfn, @function
soundfn:
.LFB149:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$92, %esp
	.cfi_def_cfa_offset 112
	movl	112(%esp), %ebx
	movl	%gs:20, %eax
	movl	%eax, 76(%esp)
	xorl	%eax, %eax
	cmpl	$17, (%ebx)
	jbe	.L746
.L720:
	movl	$-1, %esi
	.p2align 4,,7
	.p2align 3
.L677:
	movl	76(%esp), %edx
	xorl	%gs:20, %edx
	movl	%esi, %eax
	jne	.L747
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
	.p2align 4,,7
	.p2align 3
.L746:
	.cfi_restore_state
	movl	(%ebx), %eax
	jmp	*.L693(,%eax,4)
	.section	.rodata
	.align 4
	.align 4
.L693:
	.long	.L720
	.long	.L678
	.long	.L720
	.long	.L720
	.long	.L685
	.long	.L692
	.long	.L681
	.long	.L691
	.long	.L692
	.long	.L684
	.long	.L685
	.long	.L692
	.long	.L687
	.long	.L688
	.long	.L689
	.long	.L690
	.long	.L691
	.long	.L692
	.text
	.p2align 4,,7
	.p2align 3
.L692:
	movl	4(%ebx), %eax
	movl	%eax, (%esp)
	call	close
	movl	%eax, %esi
	jmp	.L677
	.p2align 4,,7
	.p2align 3
.L685:
	movl	12(%ebx), %eax
	movl	W, %edi
	movl	%eax, 8(%esp)
	movl	8(%ebx), %eax
	leal	(%edi,%eax,4), %eax
	movl	%eax, 4(%esp)
	movl	4(%ebx), %eax
	movl	%eax, (%esp)
	call	read
	movl	%eax, %esi
	jmp	.L677
	.p2align 4,,7
	.p2align 3
.L691:
	movl	12(%ebx), %eax
	movl	W, %esi
	movl	%eax, 8(%esp)
	movl	8(%ebx), %eax
	leal	(%esi,%eax,4), %eax
	movl	%eax, 4(%esp)
	movl	4(%ebx), %eax
	movl	%eax, (%esp)
	call	write
	movl	%eax, %esi
	jmp	.L677
	.p2align 4,,7
	.p2align 3
.L678:
	movl	4(%ebx), %eax
	movl	W, %edi
	leal	0(,%eax,4), %edx
	leal	(%edi,%edx), %esi
	movzbl	(%esi), %ecx
	movb	%cl, 36(%esp)
	xorl	%ecx, %ecx
	testl	%eax, %eax
	je	.L694
	movzbl	36(%esp), %eax
	movl	%eax, 24(%esp)
	movl	24(%esp), %ebp
	movl	$chbuf1, %eax
	testl	%ebp, %ebp
	je	.L695
	movl	24(%esp), %ebp
	addl	$1, %edx
	movl	%edx, 32(%esp)
	movl	24(%esp), %edx
	leal	1(%esi), %ecx
	movl	%ecx, 44(%esp)
	shrl	$2, %ebp
	leal	0(,%ebp,4), %eax
	subl	$1, %edx
	testl	%eax, %eax
	movl	%eax, 28(%esp)
	je	.L723
	cmpl	$chbuf1+4, %ecx
	leal	5(%esi), %ecx
	seta	%al
	cmpl	$chbuf1, %ecx
	setb	%cl
	orl	%ecx, %eax
	testb	$3, 44(%esp)
	sete	%cl
	cmpb	$6, 36(%esp)
	seta	36(%esp)
	andb	36(%esp), %cl
	testb	%cl, %al
	je	.L723
	xorl	%eax, %eax
	.p2align 4,,7
	.p2align 3
.L697:
	movl	1(%esi,%eax,4), %ecx
	movl	%ecx, chbuf1(,%eax,4)
	addl	$1, %eax
	cmpl	%eax, %ebp
	ja	.L697
	movl	28(%esp), %eax
	movl	28(%esp), %ecx
	addl	%eax, 32(%esp)
	subl	28(%esp), %edx
	addl	$chbuf1, %eax
	cmpl	%ecx, 24(%esp)
	je	.L698
.L696:
	movl	32(%esp), %ecx
	movl	%eax, %esi
	subl	%ecx, %esi
	.p2align 4,,7
	.p2align 3
.L699:
	movzbl	(%edi,%ecx), %eax
	subl	$1, %edx
	movb	%al, (%esi,%ecx)
	addl	$1, %ecx
	cmpl	$-1, %edx
	jne	.L699
.L698:
	movl	24(%esp), %eax
	addl	$chbuf1, %eax
.L695:
	movb	$0, (%eax)
	movl	$chbuf1, %ecx
.L694:
	movl	8(%ebx), %eax
	movl	%eax, 60(%esp)
	movl	12(%ebx), %eax
	movl	%eax, 64(%esp)
	movl	16(%ebx), %eax
	movl	%ecx, (%esp)
	movl	$chbuf2, 4(%esp)
	movl	%eax, 68(%esp)
	call	osfname
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	open
	movl	$-1073459195, 4(%esp)
	movl	%eax, %esi
	leal	60(%esp), %eax
	movl	%eax, 8(%esp)
	movl	%esi, (%esp)
	call	ioctl
	cmpl	$-1, %eax
	je	.L700
	movl	60(%esp), %eax
	cmpl	%eax, 8(%ebx)
	jne	.L700
	leal	64(%esp), %eax
	movl	%eax, 8(%esp)
	movl	$-1073459194, 4(%esp)
	movl	%esi, (%esp)
	call	ioctl
	cmpl	$-1, %eax
	je	.L700
	movl	64(%esp), %edx
	cmpl	%edx, 12(%ebx)
	jne	.L700
	leal	68(%esp), %eax
	movl	%eax, 8(%esp)
	movl	$-1073459198, 4(%esp)
	movl	%esi, (%esp)
	call	ioctl
	cmpl	$-1, %eax
	jne	.L677
	.p2align 4,,7
	.p2align 3
.L700:
	movl	%esi, (%esp)
	movl	$-1, %esi
	call	close
	jmp	.L677
	.p2align 4,,7
	.p2align 3
.L690:
	movl	8(%ebx), %edx
	movl	4(%ebx), %eax
	movb	%dl, 72(%esp)
	movl	12(%ebx), %edx
	movb	%dl, 73(%esp)
	movl	16(%ebx), %edx
	movl	$3, 8(%esp)
	movb	%dl, 74(%esp)
.L745:
	leal	72(%esp), %edx
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	call	write
	movl	%eax, %esi
	jmp	.L677
	.p2align 4,,7
	.p2align 3
.L689:
	movl	8(%ebx), %edx
	movl	4(%ebx), %eax
	movb	%dl, 72(%esp)
	movl	12(%ebx), %edx
	movl	$2, 8(%esp)
	movb	%dl, 73(%esp)
	jmp	.L745
	.p2align 4,,7
	.p2align 3
.L681:
	movl	4(%ebx), %edx
	movl	W, %ebp
	leal	0(,%edx,4), %eax
	leal	0(%ebp,%eax), %edi
	movzbl	(%edi), %ecx
	movb	%cl, 36(%esp)
	xorl	%ecx, %ecx
	testl	%edx, %edx
	je	.L701
	movzbl	36(%esp), %edx
	movl	%edx, 24(%esp)
	movl	24(%esp), %ecx
	movl	$chbuf1, %edx
	testl	%ecx, %ecx
	je	.L702
	addl	$1, %eax
	movl	24(%esp), %edx
	movl	%eax, 32(%esp)
	movl	24(%esp), %eax
	leal	1(%edi), %ecx
	movl	%ecx, 40(%esp)
	subl	$1, %edx
	shrl	$2, %eax
	movl	%eax, 44(%esp)
	sall	$2, %eax
	testl	%eax, %eax
	movl	%eax, 28(%esp)
	je	.L726
	cmpb	$6, 36(%esp)
	seta	%cl
	testb	$3, 40(%esp)
	sete	%al
	andl	%eax, %ecx
	leal	5(%edi), %eax
	cmpl	$chbuf1, %eax
	setb	%al
	cmpl	$chbuf1+4, 40(%esp)
	seta	36(%esp)
	orb	36(%esp), %al
	testb	%al, %cl
	je	.L726
	movl	%esi, 36(%esp)
	movl	44(%esp), %esi
	xorl	%eax, %eax
	.p2align 4,,7
	.p2align 3
.L704:
	movl	1(%edi,%eax,4), %ecx
	movl	%ecx, chbuf1(,%eax,4)
	addl	$1, %eax
	cmpl	%eax, %esi
	ja	.L704
	movl	28(%esp), %ecx
	addl	%ecx, 32(%esp)
	movl	36(%esp), %esi
	movl	%ecx, %edi
	subl	%ecx, %edx
	addl	$chbuf1, %edi
	cmpl	%ecx, 24(%esp)
	je	.L705
.L703:
	movl	32(%esp), %eax
	subl	%eax, %edi
	.p2align 4,,7
	.p2align 3
.L706:
	movzbl	0(%ebp,%eax), %ecx
	subl	$1, %edx
	movb	%cl, (%edi,%eax)
	addl	$1, %eax
	cmpl	$-1, %edx
	jne	.L706
.L705:
	movl	24(%esp), %edx
	addl	$chbuf1, %edx
.L702:
	movb	$0, (%edx)
	movl	$chbuf1, %ecx
.L701:
	movl	8(%ebx), %eax
	movl	%eax, 68(%esp)
	movl	12(%ebx), %eax
	movl	%eax, 64(%esp)
	movl	16(%ebx), %eax
	movl	%ecx, (%esp)
	movl	$chbuf2, 4(%esp)
	movl	%eax, 60(%esp)
	call	osfname
	movl	$0, 8(%esp)
	movl	$1, 4(%esp)
	movl	%eax, (%esp)
	call	open
	movl	$-1073459195, 4(%esp)
	movl	%eax, %edi
	leal	68(%esp), %eax
	movl	%eax, 8(%esp)
	movl	%edi, (%esp)
	call	ioctl
	cmpl	$-1, %eax
	je	.L700
	movl	68(%esp), %eax
	cmpl	%eax, 8(%ebx)
	jne	.L700
	leal	64(%esp), %eax
	movl	%eax, 8(%esp)
	movl	$-1073459194, 4(%esp)
	movl	%edi, (%esp)
	call	ioctl
	cmpl	$-1, %eax
	je	.L700
	movl	64(%esp), %edx
	cmpl	%edx, 12(%ebx)
	jne	.L700
	leal	60(%esp), %eax
	movl	%eax, 8(%esp)
	movl	$-1073459198, 4(%esp)
	movl	%edi, (%esp)
	call	ioctl
	cmpl	$-1, %eax
	je	.L700
	movl	%edi, %esi
	jmp	.L677
	.p2align 4,,7
	.p2align 3
.L688:
	movl	8(%ebx), %edx
	movl	4(%ebx), %eax
	movl	$1, 8(%esp)
	movb	%dl, 72(%esp)
	jmp	.L745
	.p2align 4,,7
	.p2align 3
.L687:
	movl	4(%ebx), %edx
	xorl	%ecx, %ecx
	movl	W, %esi
	leal	0(,%edx,4), %edi
	testl	%edx, %edx
	leal	(%esi,%edi), %ebx
	movzbl	(%ebx), %eax
	je	.L713
	movzbl	%al, %ebp
	movl	$chbuf1, %edx
	testl	%ebp, %ebp
	je	.L714
	addl	$1, %edi
	movl	%edi, 28(%esp)
	movl	%ebp, %edi
	leal	1(%ebx), %ecx
	shrl	$2, %edi
	movl	%ecx, 32(%esp)
	leal	0(,%edi,4), %ecx
	testl	%ecx, %ecx
	leal	-1(%ebp), %edx
	movl	%ecx, 24(%esp)
	je	.L732
	cmpb	$6, %al
	seta	%cl
	testb	$3, 32(%esp)
	sete	%al
	andl	%eax, %ecx
	leal	5(%ebx), %eax
	cmpl	$chbuf1, %eax
	setb	%al
	cmpl	$chbuf1+4, 32(%esp)
	seta	32(%esp)
	orb	32(%esp), %al
	testb	%al, %cl
	je	.L732
	xorl	%eax, %eax
	.p2align 4,,7
	.p2align 3
.L716:
	movl	1(%ebx,%eax,4), %ecx
	movl	%ecx, chbuf1(,%eax,4)
	addl	$1, %eax
	cmpl	%eax, %edi
	ja	.L716
	movl	24(%esp), %eax
	addl	%eax, 28(%esp)
	movl	%eax, %ebx
	subl	%eax, %edx
	addl	$chbuf1, %ebx
	cmpl	%eax, %ebp
	je	.L717
.L715:
	movl	28(%esp), %eax
	subl	%eax, %ebx
	.p2align 4,,7
	.p2align 3
.L718:
	movzbl	(%esi,%eax), %ecx
	subl	$1, %edx
	movb	%cl, (%ebx,%eax)
	addl	$1, %eax
	cmpl	$-1, %edx
	jne	.L718
.L717:
	leal	chbuf1(%ebp), %edx
.L714:
	movb	$0, (%edx)
	movl	$chbuf1, %ecx
.L713:
	movl	%ecx, (%esp)
	movl	$chbuf2, 4(%esp)
	call	osfname
	movl	$0, 8(%esp)
	movl	$1, 4(%esp)
	movl	%eax, (%esp)
	call	open
	movl	%eax, %esi
	jmp	.L677
	.p2align 4,,7
	.p2align 3
.L684:
	movl	4(%ebx), %edx
	xorl	%ecx, %ecx
	movl	W, %esi
	leal	0(,%edx,4), %edi
	testl	%edx, %edx
	leal	(%esi,%edi), %ebx
	movzbl	(%ebx), %eax
	je	.L707
	movzbl	%al, %ebp
	movl	$chbuf1, %edx
	testl	%ebp, %ebp
	je	.L708
	addl	$1, %edi
	movl	%edi, 28(%esp)
	movl	%ebp, %edi
	leal	1(%ebx), %ecx
	shrl	$2, %edi
	movl	%ecx, 32(%esp)
	leal	0(,%edi,4), %ecx
	testl	%ecx, %ecx
	leal	-1(%ebp), %edx
	movl	%ecx, 24(%esp)
	je	.L729
	cmpb	$6, %al
	seta	%cl
	testb	$3, 32(%esp)
	sete	%al
	andl	%eax, %ecx
	leal	5(%ebx), %eax
	cmpl	$chbuf1, %eax
	setb	%al
	cmpl	$chbuf1+4, 32(%esp)
	seta	32(%esp)
	orb	32(%esp), %al
	testb	%al, %cl
	je	.L729
	xorl	%eax, %eax
	.p2align 4,,7
	.p2align 3
.L710:
	movl	1(%ebx,%eax,4), %ecx
	movl	%ecx, chbuf1(,%eax,4)
	addl	$1, %eax
	cmpl	%eax, %edi
	ja	.L710
	movl	24(%esp), %eax
	addl	%eax, 28(%esp)
	movl	%eax, %ebx
	subl	%eax, %edx
	addl	$chbuf1, %ebx
	cmpl	%eax, %ebp
	je	.L711
.L709:
	movl	28(%esp), %eax
	subl	%eax, %ebx
	.p2align 4,,7
	.p2align 3
.L712:
	movzbl	(%esi,%eax), %ecx
	subl	$1, %edx
	movb	%cl, (%ebx,%eax)
	addl	$1, %eax
	cmpl	$-1, %edx
	jne	.L712
.L711:
	leal	chbuf1(%ebp), %edx
.L708:
	movb	$0, (%edx)
	movl	$chbuf1, %ecx
.L707:
	movl	%ecx, (%esp)
	movl	$chbuf2, 4(%esp)
	call	osfname
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	open
	movl	%eax, %esi
	jmp	.L677
.L747:
	call	__stack_chk_fail
.L726:
	movl	$chbuf1, %edi
	jmp	.L703
.L723:
	movl	$chbuf1, %eax
	jmp	.L696
.L729:
	movl	$chbuf1, %ebx
	jmp	.L709
.L732:
	movl	$chbuf1, %ebx
	jmp	.L715
	.cfi_endproc
.LFE149:
	.size	soundfn, .-soundfn
	.section	.rodata.str1.1
.LC118:
	.string	"\nBad sys number: %d\n"
.LC119:
	.string	"sys_read"
.LC120:
	.string	"ab"
.LC121:
	.string	"rb+"
.LC122:
	.string	"wb+"
	.section	.rodata.str1.4
	.align 4
.LC123:
	.string	"\nMemory dumped to DUMP.mem, context=%d\n"
	.text
	.p2align 4,,15
	.globl	dosys
	.type	dosys, @function
dosys:
.LFB127:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$428, %esp
	.cfi_def_cfa_offset 448
	movl	448(%esp), %esi
	movl	%gs:20, %eax
	movl	%eax, 412(%esp)
	xorl	%eax, %eax
	movl	W, %eax
	movl	452(%esp), %edi
	leal	3(%esi), %ebx
	movl	(%eax,%ebx,4), %ecx
	leal	-4(%ecx), %edx
	cmpl	$131, %edx
	jbe	.L1029
.L749:
	movl	%ecx, 8(%esp)
	movl	$.LC118, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
	movl	W, %eax
	movl	(%eax,%ebx,4), %ebx
	.p2align 4,,7
	.p2align 3
.L776:
	movl	412(%esp), %edx
	xorl	%gs:20, %edx
	movl	%ebx, %eax
	jne	.L1030
	addl	$428, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_def_cfa_offset 16
	.cfi_restore 3
	popl	%esi
	.cfi_def_cfa_offset 12
	.cfi_restore 6
	popl	%edi
	.cfi_def_cfa_offset 8
	.cfi_restore 7
	popl	%ebp
	.cfi_def_cfa_offset 4
	.cfi_restore 5
	ret
	.p2align 4,,7
	.p2align 3
.L1029:
	.cfi_restore_state
	jmp	*.L804(,%edx,4)
	.section	.rodata
	.align 4
	.align 4
.L804:
	.long	.L750
	.long	.L749
	.long	.L751
	.long	.L752
	.long	.L749
	.long	.L749
	.long	.L753
	.long	.L754
	.long	.L755
	.long	.L756
	.long	.L757
	.long	.L758
	.long	.L759
	.long	.L760
	.long	.L761
	.long	.L762
	.long	.L749
	.long	.L763
	.long	.L764
	.long	.L765
	.long	.L766
	.long	.L767
	.long	.L768
	.long	.L749
	.long	.L769
	.long	.L770
	.long	.L771
	.long	.L772
	.long	.L773
	.long	.L774
	.long	.L969
	.long	.L928
	.long	.L969
	.long	.L969
	.long	.L777
	.long	.L778
	.long	.L969
	.long	.L969
	.long	.L969
	.long	.L969
	.long	.L779
	.long	.L749
	.long	.L780
	.long	.L781
	.long	.L782
	.long	.L783
	.long	.L784
	.long	.L785
	.long	.L786
	.long	.L787
	.long	.L788
	.long	.L789
	.long	.L790
	.long	.L791
	.long	.L792
	.long	.L793
	.long	.L794
	.long	.L795
	.long	.L796
	.long	.L797
	.long	.L798
	.long	.L799
	.long	.L800
	.long	.L801
	.long	.L802
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L749
	.long	.L803
	.text
.L1046:
	movl	filetracing, %eax
	testl	%eax, %eax
	je	.L855
	movl	$chbuf4, 12(%esp)
	movl	%edi, 8(%esp)
	movl	$.LC21, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L855:
	movl	$.LC121, 4(%esp)
	movl	$chbuf4, (%esp)
	call	fopen
	testl	%eax, %eax
	jne	.L1027
	movl	$.LC122, 4(%esp)
	movl	%edi, (%esp)
	call	fopen
	testl	%eax, %eax
	jne	.L1027
.L969:
	xorl	%ebx, %ebx
	jmp	.L776
.L773:
	movl	16(%eax,%esi,4), %edx
	movl	prefixstr, %ebx
	leal	(%eax,%edx,4), %ecx
	movsbl	(%ecx), %esi
	cmpl	$63, %esi
	jg	.L969
	testl	%esi, %esi
	js	.L776
	leal	(%eax,%ebx,4), %ebx
	leal	1(%esi), %eax
	movl	%eax, 24(%esp)
	shrl	$2, %eax
	movl	%eax, %ebp
	sall	$2, %ebp
	testl	%ebp, %ebp
	movl	%eax, 36(%esp)
	je	.L970
	cmpl	$9, 24(%esp)
	movl	%ecx, %eax
	leal	4(%ebx), %edx
	seta	40(%esp)
	orl	%ebx, %eax
	testb	$3, %al
	sete	%al
	andb	%al, 40(%esp)
	leal	4(%ecx), %eax
	cmpl	%eax, %ebx
	seta	%al
	cmpl	%edx, %ecx
	seta	%dl
	movl	%edx, %edi
	orl	%edi, %eax
	testb	%al, 40(%esp)
	je	.L970
	movl	36(%esp), %edi
	xorl	%eax, %eax
	.p2align 4,,7
	.p2align 3
.L909:
	movl	(%ecx,%eax,4), %edx
	movl	%edx, (%ebx,%eax,4)
	addl	$1, %eax
	cmpl	%eax, %edi
	ja	.L909
	addl	%ebp, %ecx
	addl	%ebp, %ebx
	cmpl	%ebp, 24(%esp)
	je	.L774
.L908:
	movl	%ebp, %eax
	negl	%eax
	addl	%eax, %ecx
	addl	%eax, %ebx
	.p2align 4,,7
	.p2align 3
.L911:
	movzbl	(%ecx,%ebp), %eax
	movb	%al, (%ebx,%ebp)
	addl	$1, %ebp
	cmpl	%ebp, %esi
	jge	.L911
.L774:
	movl	prefixstr, %ebx
	jmp	.L776
.L758:
	movl	16(%eax,%esi,4), %ecx
	xorl	%ebx, %ebx
	leal	0(,%ecx,4), %edi
	testl	%ecx, %ecx
	leal	(%eax,%edi), %esi
	movzbl	(%esi), %edx
	je	.L826
	movzbl	%dl, %ebp
	movl	$chbuf1, %ecx
	testl	%ebp, %ebp
	je	.L827
	addl	$1, %edi
	movl	%edi, 32(%esp)
	movl	%ebp, %edi
	leal	1(%esi), %ebx
	shrl	$2, %edi
	movl	%ebx, 36(%esp)
	leal	0(,%edi,4), %ebx
	testl	%ebx, %ebx
	leal	-1(%ebp), %ecx
	movl	%ebx, 24(%esp)
	je	.L940
	cmpb	$6, %dl
	seta	%bl
	testb	$3, 36(%esp)
	sete	%dl
	andl	%edx, %ebx
	leal	5(%esi), %edx
	cmpl	$chbuf1, %edx
	setb	%dl
	cmpl	$chbuf1+4, 36(%esp)
	seta	36(%esp)
	orb	36(%esp), %dl
	testb	%dl, %bl
	je	.L940
	xorl	%edx, %edx
	.p2align 4,,7
	.p2align 3
.L829:
	movl	1(%esi,%edx,4), %ebx
	movl	%ebx, chbuf1(,%edx,4)
	addl	$1, %edx
	cmpl	%edx, %edi
	ja	.L829
	movl	24(%esp), %edi
	addl	%edi, 32(%esp)
	movl	%edi, %esi
	subl	%edi, %ecx
	addl	$chbuf1, %esi
	cmpl	%edi, %ebp
	je	.L830
.L828:
	movl	32(%esp), %edx
	subl	%edx, %esi
	.p2align 4,,7
	.p2align 3
.L831:
	movzbl	(%eax,%edx), %ebx
	subl	$1, %ecx
	movb	%bl, (%esi,%edx)
	addl	$1, %edx
	cmpl	$-1, %ecx
	jne	.L831
.L830:
	leal	chbuf1(%ebp), %ecx
.L827:
	movb	$0, (%ecx)
	movl	$chbuf1, %ebx
.L826:
	leal	156(%esp), %eax
	movl	%ebx, %esi
	movl	%eax, 4(%esp)
	movl	%ebx, (%esp)
	call	prepend_prefix
	movl	$chbuf4, %edx
.L1015:
	movzbl	(%eax), %ebx
	addl	$1, %eax
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	je	.L833
.L1032:
	testl	%ecx, %ecx
	movb	%bl, (%edx)
	je	.L1031
	movzbl	(%eax), %ebx
	addl	$1, %edx
	addl	$1, %eax
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	jne	.L1032
.L833:
	movb	$47, (%edx)
	addl	$1, %edx
	jmp	.L1015
.L757:
	movl	16(%eax,%esi,4), %ecx
	movl	$0, 36(%esp)
	leal	0(,%ecx,4), %edx
	testl	%ecx, %ecx
	leal	(%eax,%edx), %edi
	movzbl	(%edi), %ebx
	movb	%bl, 40(%esp)
	je	.L814
	movzbl	%bl, %ecx
	movl	%ecx, 24(%esp)
	movl	24(%esp), %ebx
	movl	$chbuf1, %ecx
	testl	%ebx, %ebx
	je	.L815
	movl	24(%esp), %ebp
	addl	$1, %edx
	movl	24(%esp), %ecx
	leal	1(%edi), %ebx
	movl	%edx, 36(%esp)
	movl	%ebx, 20(%esp)
	shrl	$2, %ebp
	leal	0(,%ebp,4), %edx
	subl	$1, %ecx
	testl	%edx, %edx
	movl	%edx, 32(%esp)
	je	.L933
	cmpl	$chbuf1+4, %ebx
	leal	5(%edi), %ebx
	seta	%dl
	cmpl	$chbuf1, %ebx
	setb	%bl
	orl	%ebx, %edx
	testb	$3, 20(%esp)
	sete	%bl
	cmpb	$6, 40(%esp)
	seta	40(%esp)
	andb	40(%esp), %bl
	testb	%bl, %dl
	je	.L933
	xorl	%edx, %edx
	.p2align 4,,7
	.p2align 3
.L817:
	movl	1(%edi,%edx,4), %ebx
	movl	%ebx, chbuf1(,%edx,4)
	addl	$1, %edx
	cmpl	%edx, %ebp
	ja	.L817
	movl	32(%esp), %edi
	addl	%edi, 36(%esp)
	movl	%edi, %edx
	subl	%edi, %ecx
	addl	$chbuf1, %edx
	cmpl	%edi, 24(%esp)
	je	.L818
.L816:
	movl	36(%esp), %ebx
	movl	%edx, %edi
	subl	%ebx, %edi
	.p2align 4,,7
	.p2align 3
.L819:
	movzbl	(%eax,%ebx), %edx
	subl	$1, %ecx
	movb	%dl, (%edi,%ebx)
	addl	$1, %ebx
	cmpl	$-1, %ecx
	jne	.L819
.L818:
	movl	24(%esp), %ecx
	addl	$chbuf1, %ecx
.L815:
	movb	$0, (%ecx)
	movl	$chbuf1, 36(%esp)
.L814:
	movl	20(%eax,%esi,4), %edx
	leal	0(,%edx,4), %ecx
	leal	(%eax,%ecx), %esi
	movzbl	(%esi), %ebx
	movb	%bl, 40(%esp)
	xorl	%ebx, %ebx
	testl	%edx, %edx
	je	.L820
	movzbl	40(%esp), %ebp
	movl	$chbuf2, %edx
	testl	%ebp, %ebp
	je	.L821
	movl	%ebp, %edi
	addl	$1, %ecx
	shrl	$2, %edi
	leal	0(,%edi,4), %edx
	movl	%edx, 24(%esp)
	leal	5(%esi), %edx
	leal	1(%esi), %ebx
	cmpl	$chbuf2, %edx
	setb	%dl
	cmpl	$chbuf2+4, %ebx
	seta	44(%esp)
	orb	44(%esp), %dl
	andl	$3, %ebx
	sete	%bl
	cmpb	$6, 40(%esp)
	movl	%ecx, 32(%esp)
	leal	-1(%ebp), %ecx
	seta	40(%esp)
	andb	40(%esp), %bl
	testb	%bl, %dl
	je	.L936
	movl	24(%esp), %edx
	testl	%edx, %edx
	je	.L936
	xorl	%edx, %edx
	.p2align 4,,7
	.p2align 3
.L823:
	movl	1(%esi,%edx,4), %ebx
	movl	%ebx, chbuf2(,%edx,4)
	addl	$1, %edx
	cmpl	%edx, %edi
	ja	.L823
	movl	24(%esp), %ebx
	addl	%ebx, 32(%esp)
	movl	%ebx, %edx
	subl	%ebx, %ecx
	addl	$chbuf2, %edx
	cmpl	%ebp, %ebx
	je	.L824
.L822:
	movl	32(%esp), %ebx
	movl	%edx, %esi
	subl	%ebx, %esi
	.p2align 4,,7
	.p2align 3
.L825:
	movzbl	(%eax,%ebx), %edx
	subl	$1, %ecx
	movb	%dl, (%esi,%ebx)
	addl	$1, %ebx
	cmpl	$-1, %ecx
	jne	.L825
.L824:
	leal	chbuf2(%ebp), %edx
.L821:
	movb	$0, (%edx)
	movl	$chbuf2, %ebx
.L820:
	movl	36(%esp), %edi
	movl	%ebx, 4(%esp)
	movl	%edi, (%esp)
	call	pathinput
	movl	%eax, %ebx
	jmp	.L776
.L756:
	movl	16(%eax,%esi,4), %edi
	movl	%edi, 12(%esp)
	movl	24(%eax,%esi,4), %edx
	movl	$1, 4(%esp)
	movl	%edx, 8(%esp)
	movl	20(%eax,%esi,4), %edx
	leal	(%eax,%edx,4), %eax
	movl	%eax, (%esp)
	call	fwrite
	movl	%edi, (%esp)
	movl	%eax, %ebx
	call	fflush
	jmp	.L776
.L755:
	movl	16(%eax,%esi,4), %edi
	movl	20(%eax,%esi,4), %ebx
	movl	24(%eax,%esi,4), %esi
	movl	%edi, (%esp)
	call	clearerr
	movl	W, %eax
	sall	$2, %ebx
	movl	%edi, 12(%esp)
	movl	%esi, 8(%esp)
	movl	$1, 4(%esp)
	addl	%ebx, %eax
	movl	%eax, (%esp)
	call	fread
	movl	%edi, (%esp)
	movl	%eax, %ebx
	call	ferror
	testl	%eax, %eax
	je	.L776
	movl	$.LC119, (%esp)
	orl	$-1, %ebx
	call	perror
	jmp	.L776
	.p2align 4,,7
	.p2align 3
.L754:
	movl	stdout, %edx
	xorl	%ebx, %ebx
	movl	%edx, 4(%esp)
	movsbl	16(%eax,%esi,4), %eax
	movl	%eax, (%esp)
	call	_IO_putc
	movl	stdout, %eax
	movl	%eax, (%esp)
	call	fflush
	jmp	.L776
.L753:
	movl	inbuf, %eax
	testl	%eax, %eax
	je	.L809
	movl	idx.6086, %edx
	movsbl	(%eax,%edx), %ebx
	testl	%ebx, %ebx
	jne	.L1033
.L810:
	movl	reattach_stdin, %esi
	movl	$-1, %ebx
	testl	%esi, %esi
	je	.L776
	movl	%eax, (%esp)
	call	free
	movl	$0, inbuf
.L809:
	call	Readch
	cmpl	$127, %eax
	movl	%eax, %ebx
	je	.L811
	testl	%eax, %eax
	jns	.L1034
.L812:
	movl	stdout, %eax
	movl	%eax, (%esp)
	call	fflush
	jmp	.L776
.L752:
	movl	16(%eax,%esi,4), %edx
	movl	28(%eax,%edx,4), %ebp
	testl	%ebp, %ebp
	jns	.L807
	movl	slowflag, %edi
	testl	%edi, %edi
	je	.L808
.L807:
	movl	%eax, 4(%esp)
	movl	%edx, (%esp)
	call	interpret
	movl	%eax, %ebx
	jmp	.L776
.L751:
	movl	16(%eax,%esi,4), %eax
	testl	%eax, %eax
	je	.L805
	movl	tallyupb, %eax
	xorl	%ebx, %ebx
	testl	%eax, %eax
	movl	%eax, tallylim
	jle	.L776
	movl	tallyv, %edx
	movl	$1, %eax
	.p2align 4,,7
	.p2align 3
.L806:
	movl	$0, (%edx,%eax,4)
	addl	$1, %eax
	cmpl	%eax, tallylim
	jge	.L806
	xorl	%ebx, %ebx
	jmp	.L776
.L750:
	movl	16(%eax,%esi,4), %eax
	xorl	%ebx, %ebx
	movl	%eax, tracing
	jmp	.L776
.L794:
	movl	16(%eax,%esi,4), %esi
	xorl	%ebx, %ebx
	movl	trcount, %eax
	movl	%esi, 24(%esp)
	testl	%eax, %eax
	js	.L776
	leal	140(%esp), %eax
	movl	%eax, (%esp)
	call	ftime
	movswl	146(%esp), %eax
	movl	140(%esp), %edi
	movl	trcount, %esi
	movzwl	144(%esp), %ecx
	imull	$60, %eax, %eax
	movl	%edi, %ebp
	sarl	$31, %ebp
	movl	%ecx, 32(%esp)
	movl	%esi, %ecx
	movl	%eax, %edx
	sarl	$31, %edx
	subl	%eax, %edi
	movl	W, %eax
	sbbl	%edx, %ebp
	imull	$60, 532(%eax), %eax
	movl	$86400, 8(%esp)
	movl	$0, 12(%esp)
	movl	%eax, %edx
	sarl	$31, %edx
	addl	%eax, %edi
	adcl	%edx, %ebp
	andl	$4095, %ecx
	movl	%edi, (%esp)
	movl	%ebp, 4(%esp)
	movl	%ecx, 36(%esp)
	call	__moddi3
	movl	$1172812403, %edx
	movl	24(%esp), %edi
	imull	$1000, %eax, %ecx
	addl	32(%esp), %ecx
	movl	%ecx, %eax
	imull	%edx
	movl	%ecx, %eax
	sarl	$31, %eax
	sarl	$14, %edx
	subl	%eax, %edx
	imull	$60000, %edx, %edx
	subl	%edx, %ecx
	leal	1711276032(%ecx), %eax
	movl	36(%esp), %ecx
	movl	%eax, trvec(,%ecx,4)
	leal	1(%esi), %eax
	addl	$2, %esi
	andl	$4095, %eax
	movl	%edi, trvec(,%eax,4)
	movl	%esi, trcount
	jmp	.L776
.L793:
	leal	(%eax,%edi,4), %edx
	leal	16(%eax,%esi,4), %eax
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	call	callc
	movl	%eax, %ebx
	jmp	.L776
.L792:
	leal	(%eax,%edi,4), %edx
	leal	16(%eax,%esi,4), %eax
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	call	soundfn
	movl	%eax, %ebx
	jmp	.L776
.L791:
	movl	16(%eax,%esi,4), %eax
	xorl	%ebx, %ebx
	movl	%eax, (%esp)
	call	msecdelay
	jmp	.L776
.L766:
	movl	%edi, 4(%esp)
	movl	16(%eax,%esi,4), %eax
	movl	%eax, (%esp)
	call	globin
	movl	%eax, %ebx
	jmp	.L776
.L765:
	movl	16(%eax,%esi,4), %ecx
	xorl	%edi, %edi
	movl	412(%eax), %ebx
	testl	%ecx, %ecx
	movl	%ebx, 36(%esp)
	leal	0(,%ecx,4), %ebx
	leal	(%eax,%ebx), %esi
	movzbl	(%esi), %edx
	je	.L888
	movzbl	%dl, %ebp
	movl	$chbuf2, %ecx
	testl	%ebp, %ebp
	je	.L889
	leal	1(%esi), %edi
	addl	$1, %ebx
	movl	%edi, 40(%esp)
	movl	%ebp, %edi
	shrl	$2, %edi
	movl	%ebx, 32(%esp)
	leal	0(,%edi,4), %ebx
	testl	%ebx, %ebx
	leal	-1(%ebp), %ecx
	movl	%ebx, 24(%esp)
	je	.L962
	cmpb	$6, %dl
	seta	%bl
	testb	$3, 40(%esp)
	sete	%dl
	andl	%edx, %ebx
	leal	5(%esi), %edx
	cmpl	$chbuf2, %edx
	setb	%dl
	cmpl	$chbuf2+4, 40(%esp)
	seta	40(%esp)
	orb	40(%esp), %dl
	testb	%dl, %bl
	je	.L962
	xorl	%edx, %edx
	.p2align 4,,7
	.p2align 3
.L891:
	movl	1(%esi,%edx,4), %ebx
	movl	%ebx, chbuf2(,%edx,4)
	addl	$1, %edx
	cmpl	%edx, %edi
	ja	.L891
	movl	24(%esp), %edi
	addl	%edi, 32(%esp)
	movl	%edi, %edx
	subl	%edi, %ecx
	addl	$chbuf2, %edx
	cmpl	%edi, %ebp
	je	.L892
.L890:
	movl	32(%esp), %ebx
	movl	%edx, %esi
	subl	%ebx, %esi
	.p2align 4,,7
	.p2align 3
.L893:
	movzbl	(%eax,%ebx), %edx
	subl	$1, %ecx
	movb	%dl, (%esi,%ebx)
	addl	$1, %ebx
	cmpl	$-1, %ecx
	jne	.L893
.L892:
	leal	chbuf2(%ebp), %ecx
.L889:
	movb	$0, (%ecx)
	movl	$chbuf2, %edi
.L888:
	movl	36(%esp), %edx
	testl	%edx, %edx
	je	.L894
	movl	36(%esp), %edx
	leal	76(%eax,%edx,4), %eax
	movl	(%eax), %edx
	movl	%edx, taskname
	movl	4(%eax), %edx
	movl	%edx, taskname+4
	movl	8(%eax), %edx
	movl	%edx, taskname+8
	movl	12(%eax), %eax
.L925:
	movl	%eax, taskname+12
	movl	%edi, (%esp)
	call	loadseg
	movl	%eax, %ebx
	jmp	.L776
.L764:
	movl	16(%eax,%esi,4), %eax
	movl	%eax, (%esp)
	call	freevec
	movl	%eax, %ebx
	jmp	.L776
.L763:
	movl	412(%eax), %edx
	testl	%edx, %edx
	je	.L887
	leal	76(%eax,%edx,4), %edx
	movl	(%edx), %ecx
	movl	%ecx, taskname
	movl	4(%edx), %ecx
	movl	%ecx, taskname+4
	movl	8(%edx), %ecx
	movl	%ecx, taskname+8
	movl	12(%edx), %edx
.L924:
	movl	%edx, taskname+12
	movl	16(%eax,%esi,4), %eax
	movl	%eax, (%esp)
	call	getvec
	movl	%eax, %ebx
	jmp	.L776
.L796:
	movl	16(%eax,%esi,4), %eax
	andl	$4095, %eax
	movl	trvec(,%eax,4), %ebx
	jmp	.L776
.L797:
	movl	24(%eax,%esi,4), %edx
	movl	%edx, 8(%esp)
	movl	20(%eax,%esi,4), %edx
	movl	%edx, 4(%esp)
	movl	16(%eax,%esi,4), %eax
	movl	%eax, (%esp)
	call	doflt
	movl	W, %edx
	movl	result2, %ecx
	movl	%ecx, 40(%edx,%edi,4)
	movl	%eax, %ebx
	jmp	.L776
.L795:
	movl	16(%eax,%esi,4), %eax
	movl	trcount, %ebx
	movl	%eax, trcount
	jmp	.L776
.L762:
	movl	16(%eax,%esi,4), %ecx
	xorl	%ebx, %ebx
	leal	0(,%ecx,4), %edi
	testl	%ecx, %ecx
	leal	(%eax,%edi), %esi
	movzbl	(%esi), %edx
	je	.L836
	movzbl	%dl, %ebp
	movl	$chbuf1, %ecx
	testl	%ebp, %ebp
	je	.L837
	addl	$1, %edi
	movl	%edi, 32(%esp)
	movl	%ebp, %edi
	leal	1(%esi), %ebx
	shrl	$2, %edi
	movl	%ebx, 36(%esp)
	leal	0(,%edi,4), %ebx
	testl	%ebx, %ebx
	leal	-1(%ebp), %ecx
	movl	%ebx, 24(%esp)
	je	.L944
	cmpb	$6, %dl
	seta	%bl
	testb	$3, 36(%esp)
	sete	%dl
	andl	%edx, %ebx
	leal	5(%esi), %edx
	cmpl	$chbuf1, %edx
	setb	%dl
	cmpl	$chbuf1+4, 36(%esp)
	seta	36(%esp)
	orb	36(%esp), %dl
	testb	%dl, %bl
	je	.L944
	xorl	%edx, %edx
	.p2align 4,,7
	.p2align 3
.L839:
	movl	1(%esi,%edx,4), %ebx
	movl	%ebx, chbuf1(,%edx,4)
	addl	$1, %edx
	cmpl	%edx, %edi
	ja	.L839
	movl	24(%esp), %edi
	addl	%edi, 32(%esp)
	movl	%edi, %esi
	subl	%edi, %ecx
	addl	$chbuf1, %esi
	cmpl	%edi, %ebp
	je	.L840
.L838:
	movl	32(%esp), %edx
	subl	%edx, %esi
	.p2align 4,,7
	.p2align 3
.L841:
	movzbl	(%eax,%edx), %ebx
	subl	$1, %ecx
	movb	%bl, (%esi,%edx)
	addl	$1, %edx
	cmpl	$-1, %ecx
	jne	.L841
.L840:
	leal	chbuf1(%ebp), %ecx
.L837:
	movb	$0, (%ecx)
	movl	$chbuf1, %ebx
.L836:
	leal	156(%esp), %eax
	movl	%ebx, %esi
	movl	%eax, 4(%esp)
	movl	%ebx, (%esp)
	call	prepend_prefix
	movl	$chbuf4, %edx
.L1016:
	movzbl	(%eax), %ebx
	addl	$1, %eax
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	je	.L843
.L1036:
	testl	%ecx, %ecx
	movb	%bl, (%edx)
	je	.L1035
	movzbl	(%eax), %ebx
	addl	$1, %edx
	addl	$1, %eax
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	jne	.L1036
.L843:
	movb	$47, (%edx)
	addl	$1, %edx
	jmp	.L1016
.L761:
	movl	16(%eax,%esi,4), %ebx
	movl	$0, 32(%esp)
	leal	0(,%ebx,4), %ecx
	testl	%ebx, %ebx
	leal	(%eax,%ecx), %edi
	movzbl	(%edi), %edx
	je	.L867
	movzbl	%dl, %ebx
	movl	%ebx, 24(%esp)
	movl	24(%esp), %ebp
	movl	$chbuf1, %ebx
	testl	%ebp, %ebp
	je	.L868
	movl	24(%esp), %ebp
	addl	$1, %ecx
	movl	%ecx, 36(%esp)
	movl	24(%esp), %ecx
	leal	1(%edi), %ebx
	movl	%ebx, 40(%esp)
	shrl	$2, %ebp
	leal	0(,%ebp,4), %ebx
	subl	$1, %ecx
	testl	%ebx, %ebx
	movl	%ebx, 32(%esp)
	je	.L956
	cmpb	$6, %dl
	seta	%bl
	testb	$3, 40(%esp)
	sete	%dl
	andl	%edx, %ebx
	leal	5(%edi), %edx
	cmpl	$chbuf1, %edx
	setb	%dl
	cmpl	$chbuf1+4, 40(%esp)
	seta	40(%esp)
	orb	40(%esp), %dl
	testb	%dl, %bl
	je	.L956
	xorl	%edx, %edx
	.p2align 4,,7
	.p2align 3
.L870:
	movl	1(%edi,%edx,4), %ebx
	movl	%ebx, chbuf1(,%edx,4)
	addl	$1, %edx
	cmpl	%edx, %ebp
	ja	.L870
	movl	32(%esp), %edi
	addl	%edi, 36(%esp)
	movl	%edi, %edx
	subl	%edi, %ecx
	addl	$chbuf1, %edx
	cmpl	%edi, 24(%esp)
	je	.L871
.L869:
	movl	36(%esp), %ebx
	movl	%edx, %edi
	subl	%ebx, %edi
	.p2align 4,,7
	.p2align 3
.L872:
	movzbl	(%eax,%ebx), %edx
	subl	$1, %ecx
	movb	%dl, (%edi,%ebx)
	addl	$1, %ebx
	cmpl	$-1, %ecx
	jne	.L872
.L871:
	movl	24(%esp), %ebx
	addl	$chbuf1, %ebx
.L868:
	movb	$0, (%ebx)
	movl	$chbuf1, 32(%esp)
.L867:
	movl	20(%eax,%esi,4), %ebx
	xorl	%edi, %edi
	leal	0(,%ebx,4), %ecx
	testl	%ebx, %ebx
	leal	(%eax,%ecx), %esi
	movzbl	(%esi), %edx
	je	.L873
	movzbl	%dl, %ebp
	movl	$chbuf2, %ebx
	testl	%ebp, %ebp
	je	.L874
	movl	%ebp, %edi
	addl	$1, %ecx
	leal	1(%esi), %ebx
	shrl	$2, %edi
	movl	%ebx, 40(%esp)
	leal	0(,%edi,4), %ebx
	testl	%ebx, %ebx
	movl	%ecx, 36(%esp)
	leal	-1(%ebp), %ecx
	movl	%ebx, 24(%esp)
	je	.L959
	cmpb	$6, %dl
	seta	%bl
	testb	$3, 40(%esp)
	sete	%dl
	andl	%edx, %ebx
	leal	5(%esi), %edx
	cmpl	$chbuf2, %edx
	setb	%dl
	cmpl	$chbuf2+4, 40(%esp)
	seta	40(%esp)
	orb	40(%esp), %dl
	testb	%dl, %bl
	je	.L959
	xorl	%edx, %edx
	.p2align 4,,7
	.p2align 3
.L876:
	movl	1(%esi,%edx,4), %ebx
	movl	%ebx, chbuf2(,%edx,4)
	addl	$1, %edx
	cmpl	%edx, %edi
	ja	.L876
	movl	24(%esp), %edi
	addl	%edi, 36(%esp)
	movl	%edi, %edx
	subl	%edi, %ecx
	addl	$chbuf2, %edx
	cmpl	%edi, %ebp
	je	.L877
.L875:
	movl	36(%esp), %ebx
	movl	%edx, %esi
	subl	%ebx, %esi
	.p2align 4,,7
	.p2align 3
.L878:
	movzbl	(%eax,%ebx), %edx
	subl	$1, %ecx
	movb	%dl, (%esi,%ebx)
	addl	$1, %ebx
	cmpl	$-1, %ecx
	jne	.L878
.L877:
	leal	chbuf2(%ebp), %ebx
.L874:
	movb	$0, (%ebx)
	movl	$chbuf2, %edi
.L873:
	movl	32(%esp), %edx
	leal	156(%esp), %ebx
	movl	%ebx, 4(%esp)
	movl	%ebx, %esi
	movl	%edx, (%esp)
	call	prepend_prefix
	movl	$chbuf3, %edx
.L1019:
	movzbl	(%eax), %ebx
	addl	$1, %eax
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	je	.L880
.L1038:
	testl	%ecx, %ecx
	movb	%bl, (%edx)
	je	.L1037
	movzbl	(%eax), %ebx
	addl	$1, %edx
	addl	$1, %eax
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	jne	.L1038
.L880:
	movb	$47, (%edx)
	addl	$1, %edx
	jmp	.L1019
.L760:
	movl	16(%eax,%esi,4), %ecx
	xorl	%ebx, %ebx
	leal	0(,%ecx,4), %edi
	testl	%ecx, %ecx
	leal	(%eax,%edi), %esi
	movzbl	(%esi), %edx
	je	.L857
	movzbl	%dl, %ebp
	movl	$chbuf1, %ecx
	testl	%ebp, %ebp
	je	.L858
	addl	$1, %edi
	movl	%edi, 32(%esp)
	movl	%ebp, %edi
	leal	1(%esi), %ebx
	shrl	$2, %edi
	movl	%ebx, 36(%esp)
	leal	0(,%edi,4), %ebx
	testl	%ebx, %ebx
	leal	-1(%ebp), %ecx
	movl	%ebx, 24(%esp)
	je	.L953
	cmpb	$6, %dl
	seta	%bl
	testb	$3, 36(%esp)
	sete	%dl
	andl	%edx, %ebx
	leal	5(%esi), %edx
	cmpl	$chbuf1, %edx
	setb	%dl
	cmpl	$chbuf1+4, 36(%esp)
	seta	36(%esp)
	orb	36(%esp), %dl
	testb	%dl, %bl
	je	.L953
	xorl	%edx, %edx
	.p2align 4,,7
	.p2align 3
.L860:
	movl	1(%esi,%edx,4), %ebx
	movl	%ebx, chbuf1(,%edx,4)
	addl	$1, %edx
	cmpl	%edx, %edi
	ja	.L860
	movl	24(%esp), %edi
	addl	%edi, 32(%esp)
	movl	%edi, %esi
	subl	%edi, %ecx
	addl	$chbuf1, %esi
	cmpl	%edi, %ebp
	je	.L861
.L859:
	movl	32(%esp), %edx
	subl	%edx, %esi
	.p2align 4,,7
	.p2align 3
.L862:
	movzbl	(%eax,%edx), %ebx
	subl	$1, %ecx
	movb	%bl, (%esi,%edx)
	addl	$1, %edx
	cmpl	$-1, %ecx
	jne	.L862
.L861:
	leal	chbuf1(%ebp), %ecx
.L858:
	movb	$0, (%ecx)
	movl	$chbuf1, %ebx
.L857:
	leal	156(%esp), %eax
	movl	%ebx, %esi
	movl	%eax, 4(%esp)
	movl	%ebx, (%esp)
	call	prepend_prefix
	movl	$chbuf4, %edx
.L1018:
	movzbl	(%eax), %ebx
	addl	$1, %eax
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	je	.L864
.L1040:
	testl	%ecx, %ecx
	movb	%bl, (%edx)
	je	.L1039
	movzbl	(%eax), %ebx
	addl	$1, %edx
	addl	$1, %eax
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	jne	.L1040
.L864:
	movb	$47, (%edx)
	addl	$1, %edx
	jmp	.L1018
.L759:
	movl	16(%eax,%esi,4), %eax
	movl	%eax, (%esp)
	call	fclose
	cmpl	$1, %eax
	sbbl	%ebx, %ebx
	jmp	.L776
.L770:
	movl	20(%eax,%esi,4), %edx
	movl	%edx, 4(%esp)
	movl	16(%eax,%esi,4), %eax
	movl	%eax, (%esp)
	call	setraster
	movl	%eax, %ebx
	jmp	.L776
.L769:
	call	intflag
	cmpl	$1, %eax
	sbbl	%ebx, %ebx
	notl	%ebx
	jmp	.L776
.L768:
	movl	24(%eax,%esi,4), %edx
	movl	%edx, 8(%esp)
	movl	20(%eax,%esi,4), %edx
	movl	%edx, 4(%esp)
	movl	16(%eax,%esi,4), %eax
	movl	%eax, (%esp)
	call	muldiv1
	movl	W, %edx
	movl	result2, %ecx
	movl	%ecx, 40(%edx,%edi,4)
	movl	%eax, %ebx
	jmp	.L776
.L767:
	movl	16(%eax,%esi,4), %edx
	xorl	%ebx, %ebx
	testl	%edx, %edx
	jne	.L1021
	jmp	.L776
	.p2align 4,,7
	.p2align 3
.L1041:
	movl	W, %eax
	movl	%ebx, %edx
.L1021:
	movl	(%eax,%edx,4), %ebx
	movl	%edx, (%esp)
	call	freevec
	testl	%ebx, %ebx
	jne	.L1041
	xorl	%ebx, %ebx
	jmp	.L776
.L772:
	movl	16(%eax,%esi,4), %ebp
	xorl	%ebx, %ebx
	leal	0(,%ebp,4), %ecx
	testl	%ebp, %ebp
	leal	(%eax,%ecx), %edi
	movzbl	(%edi), %edx
	je	.L896
	movzbl	%dl, %ebx
	movl	%ebx, 24(%esp)
	movl	24(%esp), %ebp
	movl	$chbuf1, %ebx
	testl	%ebp, %ebp
	je	.L897
	movl	24(%esp), %ebp
	addl	$1, %ecx
	movl	%ecx, 36(%esp)
	movl	24(%esp), %ecx
	leal	1(%edi), %ebx
	movl	%ebx, 40(%esp)
	shrl	$2, %ebp
	leal	0(,%ebp,4), %ebx
	subl	$1, %ecx
	testl	%ebx, %ebx
	movl	%ebx, 32(%esp)
	je	.L968
	cmpb	$6, %dl
	seta	%bl
	testb	$3, 40(%esp)
	sete	%dl
	andl	%edx, %ebx
	leal	5(%edi), %edx
	cmpl	$chbuf1, %edx
	setb	%dl
	cmpl	$chbuf1+4, 40(%esp)
	seta	40(%esp)
	orb	40(%esp), %dl
	testb	%dl, %bl
	je	.L968
	xorl	%edx, %edx
	.p2align 4,,7
	.p2align 3
.L899:
	movl	1(%edi,%edx,4), %ebx
	movl	%ebx, chbuf1(,%edx,4)
	addl	$1, %edx
	cmpl	%edx, %ebp
	ja	.L899
	movl	32(%esp), %edi
	addl	%edi, 36(%esp)
	movl	%edi, %edx
	subl	%edi, %ecx
	addl	$chbuf1, %edx
	cmpl	%edi, 24(%esp)
	je	.L900
.L898:
	movl	36(%esp), %ebx
	movl	%edx, %edi
	subl	%ebx, %edi
	.p2align 4,,7
	.p2align 3
.L901:
	movzbl	(%eax,%ebx), %edx
	subl	$1, %ecx
	movb	%dl, (%edi,%ebx)
	addl	$1, %ebx
	cmpl	$-1, %ecx
	jne	.L901
.L900:
	movl	24(%esp), %ebx
	addl	$chbuf1, %ebx
.L897:
	movb	$0, (%ebx)
	movl	$chbuf1, %ebx
.L896:
	movl	20(%eax,%esi,4), %esi
	leal	156(%esp), %eax
	movl	%ebx, %edi
	movl	%eax, 4(%esp)
	movl	%ebx, (%esp)
	call	prepend_prefix
	movl	$chbuf4, %edx
.L1022:
	movzbl	(%eax), %ebx
	addl	$1, %eax
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	je	.L903
.L1043:
	testl	%ecx, %ecx
	movb	%bl, (%edx)
	je	.L1042
	movzbl	(%eax), %ebx
	addl	$1, %edx
	addl	$1, %eax
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	jne	.L1043
.L903:
	movb	$47, (%edx)
	addl	$1, %edx
	jmp	.L1022
.L771:
	call	clock
	movl	$1000, %ebx
	movl	$1000000, 8(%esp)
	movl	$0, 12(%esp)
	imull	%ebx
	movl	%eax, (%esp)
	movl	%edx, 4(%esp)
	movl	%eax, 24(%esp)
	movl	%edx, 28(%esp)
	call	__moddi3
	movl	24(%esp), %ecx
	movl	28(%esp), %ebx
	movl	$1000000, 8(%esp)
	movl	$0, 12(%esp)
	movl	%ecx, (%esp)
	movl	%ebx, 4(%esp)
	movl	%eax, result2
	call	__divdi3
	movl	%eax, %ebx
	jmp	.L776
.L928:
	movl	$-1, %ebx
	jmp	.L776
.L790:
	movl	$-3, %ebx
	jmp	.L776
.L789:
	movl	16(%eax,%esi,4), %edx
	leal	(%eax,%edx,4), %edx
	movl	(%edx), %ebx
	addl	20(%eax,%esi,4), %ebx
	movl	%ebx, (%edx)
	jmp	.L776
.L788:
	movl	$5, %ebx
	jmp	.L776
.L787:
	movl	28(%eax,%esi,4), %ecx
	movl	16(%eax,%esi,4), %edx
	movl	%ecx, 8(%esp)
	movl	24(%eax,%esi,4), %ecx
	leal	(%eax,%edx,4), %edx
	movl	%ecx, 4(%esp)
	movl	20(%eax,%esi,4), %eax
	movl	%eax, (%esp)
	call	*%edx
	movl	%eax, %ebx
	jmp	.L776
.L786:
	addl	$4, %esi
	xorl	%ebx, %ebx
	movl	(%eax,%esi,4), %edx
	movl	%eax, (%esp)
	movl	%edx, 8(%esp)
	movl	memupb, %edx
	movl	%edx, 4(%esp)
	call	dumpmem
	movl	W, %eax
	movl	(%eax,%esi,4), %eax
	movl	$.LC123, 4(%esp)
	movl	$1, (%esp)
	movl	%eax, 8(%esp)
	call	__printf_chk
	jmp	.L776
.L785:
	call	getpid
	movl	%eax, %ebx
	.p2align 4,,6
	jmp	.L776
.L784:
	movl	16(%eax,%esi,4), %edx
	leal	(%eax,%edx,4), %edx
	movl	%edx, 36(%esp)
	movsbl	(%edx), %edx
	testl	%edx, %edx
	jle	.L1044
	movl	36(%esp), %eax
	movl	%edx, %ecx
	shrl	$2, %ecx
	movl	%ecx, %ebp
	sall	$2, %ebp
	addl	$1, %eax
	testl	%ebp, %ebp
	movl	%ecx, 40(%esp)
	je	.L1045
	movl	36(%esp), %esi
	cmpl	$8, %edx
	seta	%bl
	testb	$3, %al
	movl	%ebx, %edi
	sete	%bl
	andl	%ebx, %edi
	addl	$5, %esi
	leal	156(%esp), %ebx
	cmpl	%esi, %ebx
	seta	%cl
	movl	%ecx, %esi
	leal	160(%esp), %ecx
	cmpl	%ecx, %eax
	seta	%al
	orl	%eax, %esi
	movl	%edi, %eax
	movl	%esi, %ecx
	testb	%cl, %al
	je	.L973
	movl	36(%esp), %eax
	xorl	%esi, %esi
	movl	40(%esp), %ecx
	.p2align 4,,7
	.p2align 3
.L914:
	movl	1(%eax,%esi,4), %edi
	movl	%edi, (%ebx,%esi,4)
	addl	$1, %esi
	cmpl	%esi, %ecx
	ja	.L914
	cmpl	%ebp, %edx
	movl	%eax, 36(%esp)
	je	.L912
	.p2align 4,,7
	.p2align 3
.L989:
	movzbl	1(%eax,%ebp), %ecx
	movb	%cl, (%ebx,%ebp)
	addl	$1, %ebp
	cmpl	%ebp, %edx
	jg	.L989
.L912:
	movb	$0, 156(%esp,%edx)
	movl	%ebx, (%esp)
	call	system
	movl	%eax, %ebx
	jmp	.L776
.L783:
	movl	20(%eax,%esi,4), %ecx
	xorl	%ebx, %ebx
	movl	16(%eax,%esi,4), %edx
	movl	%ecx, (%eax,%edx,4)
	jmp	.L776
.L782:
	movl	16(%eax,%esi,4), %edx
	movl	(%eax,%edx,4), %ebx
	jmp	.L776
.L781:
	movl	16(%eax,%esi,4), %ecx
	xorl	%edi, %edi
	leal	0(,%ecx,4), %ebx
	testl	%ecx, %ecx
	leal	(%eax,%ebx), %esi
	movzbl	(%esi), %edx
	je	.L846
	movzbl	%dl, %ebp
	movl	$chbuf1, %ecx
	testl	%ebp, %ebp
	je	.L847
	addl	$1, %ebx
	movl	%ebp, %edi
	shrl	$2, %edi
	movl	%ebx, 32(%esp)
	leal	1(%esi), %ebx
	movl	%ebx, 36(%esp)
	leal	0(,%edi,4), %ebx
	testl	%ebx, %ebx
	leal	-1(%ebp), %ecx
	movl	%ebx, 24(%esp)
	je	.L948
	cmpb	$6, %dl
	seta	%bl
	testb	$3, 36(%esp)
	sete	%dl
	andl	%edx, %ebx
	leal	5(%esi), %edx
	cmpl	$chbuf1, %edx
	setb	%dl
	cmpl	$chbuf1+4, 36(%esp)
	seta	36(%esp)
	orb	36(%esp), %dl
	testb	%dl, %bl
	je	.L948
	xorl	%edx, %edx
	.p2align 4,,7
	.p2align 3
.L849:
	movl	1(%esi,%edx,4), %ebx
	movl	%ebx, chbuf1(,%edx,4)
	addl	$1, %edx
	cmpl	%edx, %edi
	ja	.L849
	movl	24(%esp), %edi
	addl	%edi, 32(%esp)
	movl	%edi, %esi
	subl	%edi, %ecx
	addl	$chbuf1, %esi
	cmpl	%edi, %ebp
	je	.L850
.L848:
	movl	32(%esp), %edx
	subl	%edx, %esi
	.p2align 4,,7
	.p2align 3
.L851:
	movzbl	(%eax,%edx), %ebx
	subl	$1, %ecx
	movb	%bl, (%esi,%edx)
	addl	$1, %edx
	cmpl	$-1, %ecx
	jne	.L851
.L850:
	leal	chbuf1(%ebp), %ecx
.L847:
	movb	$0, (%ecx)
	movl	$chbuf1, %edi
.L846:
	leal	156(%esp), %eax
	movl	%eax, 4(%esp)
	movl	%edi, (%esp)
	call	prepend_prefix
	movl	$chbuf4, %edx
.L1017:
	movzbl	(%eax), %ebx
	addl	$1, %eax
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	je	.L853
.L1047:
	testl	%ecx, %ecx
	movb	%bl, (%edx)
	je	.L1046
	movzbl	(%eax), %ebx
	addl	$1, %edx
	addl	$1, %eax
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	jne	.L1047
.L853:
	movb	$47, (%edx)
	addl	$1, %edx
	jmp	.L1017
.L780:
	movl	16(%eax,%esi,4), %ebx
	movl	%ebx, (%esp)
	call	ftell
	movl	%ebx, (%esp)
	movl	$2, 8(%esp)
	movl	$0, 4(%esp)
	movl	%eax, %edi
	call	fseek
	movl	%ebx, (%esp)
	call	ftell
	movl	%ebx, (%esp)
	movl	$-1, %ebx
	movl	$0, 8(%esp)
	movl	%edi, 4(%esp)
	movl	%eax, %esi
	call	fseek
	testl	%eax, %eax
	cmove	%esi, %ebx
	jmp	.L776
.L779:
	movl	16(%eax,%esi,4), %edx
	leal	(%eax,%edx,4), %ebx
	leal	140(%esp), %eax
	movl	%eax, (%esp)
	call	ftime
	movswl	146(%esp), %eax
	movl	140(%esp), %esi
	movzwl	144(%esp), %ebp
	imull	$60, %eax, %eax
	movl	%esi, %edi
	sarl	$31, %edi
	movl	%eax, %edx
	sarl	$31, %edx
	subl	%eax, %esi
	movl	W, %eax
	sbbl	%edx, %edi
	imull	$60, 532(%eax), %eax
	movl	$86400, 8(%esp)
	movl	$0, 12(%esp)
	movl	%eax, %edx
	sarl	$31, %edx
	addl	%eax, %esi
	adcl	%edx, %edi
	movl	%esi, (%esp)
	movl	%edi, 4(%esp)
	call	__divdi3
	movl	%eax, (%ebx)
	movl	$86400, 8(%esp)
	movl	$0, 12(%esp)
	movl	%esi, (%esp)
	movl	%edi, 4(%esp)
	call	__moddi3
	movl	$-1, 8(%ebx)
	imull	$1000, %eax, %eax
	addl	%eax, %ebp
	movl	%ebp, 4(%ebx)
	movl	$-1, %ebx
	jmp	.L776
.L798:
	call	pollReadch
.L1027:
	movl	%eax, %ebx
	jmp	.L776
.L799:
	movl	16(%eax,%esi,4), %edx
	movl	$-1, %ebx
	movl	536(%eax), %ecx
	testl	%edx, %edx
	jle	.L776
	cmpl	(%eax,%ecx,4), %edx
	jg	.L776
	addl	%ecx, %edx
	leal	(%eax,%edx,4), %eax
	movl	(%eax), %ebx
	addl	$1, %ebx
	movl	%ebx, (%eax)
	jmp	.L776
.L800:
	leal	(%eax,%edi,4), %edx
	movl	%eax, 8(%esp)
	leal	16(%eax,%esi,4), %eax
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	call	sdlfn
	movl	%eax, %ebx
	jmp	.L776
.L801:
	leal	(%eax,%edi,4), %edx
	movl	%eax, 8(%esp)
	leal	16(%eax,%esi,4), %eax
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	call	glfn
	movl	%eax, %ebx
	jmp	.L776
.L778:
	movl	16(%eax,%esi,4), %eax
	leal	40(,%edi,4), %esi
	movl	%eax, (%esp)
	call	ftell
	addl	W, %esi
	movl	%eax, %ebx
	call	__errno_location
	movl	(%eax), %eax
	movl	%eax, (%esi)
	jmp	.L776
.L777:
	movl	$0, 8(%esp)
	movl	20(%eax,%esi,4), %edx
	leal	40(,%edi,4), %ebx
	movl	%edx, 4(%esp)
	movl	16(%eax,%esi,4), %eax
	movl	%eax, (%esp)
	call	fseek
	addl	W, %ebx
	movl	%eax, %esi
	call	__errno_location
	cmpl	$1, %esi
	movl	(%eax), %eax
	movl	%eax, (%ebx)
	sbbl	%ebx, %ebx
	jmp	.L776
.L802:
	leal	(%eax,%edi,4), %edx
	movl	%eax, 8(%esp)
	leal	16(%eax,%esi,4), %eax
	movl	%edx, 4(%esp)
	movl	%eax, (%esp)
	call	extfn
	movl	%eax, %ebx
	jmp	.L776
.L803:
	movl	$0, (%esp)
	xorl	%ebx, %ebx
	call	time
	movl	%eax, 152(%esp)
	leal	152(%esp), %eax
	movl	%eax, (%esp)
	call	gmtime
	movl	W, %edx
	movl	16(%edx,%esi,4), %ecx
	leal	(%edx,%ecx,4), %edx
	movl	20(%eax), %ecx
	addl	$1900, %ecx
	movl	%ecx, (%edx)
	movl	16(%eax), %ecx
	addl	$1, %ecx
	movl	%ecx, 4(%edx)
	movl	12(%eax), %ecx
	movl	%ecx, 8(%edx)
	movl	8(%eax), %ecx
	movl	%ecx, 12(%edx)
	movl	4(%eax), %ecx
	movl	%ecx, 16(%edx)
	movl	(%eax), %eax
	movl	%eax, 20(%edx)
	jmp	.L776
.L1039:
	movl	filetracing, %eax
	testl	%eax, %eax
	je	.L866
	movl	$chbuf4, 12(%esp)
	movl	%esi, 8(%esp)
	movl	$.LC21, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L866:
	movl	$chbuf4, (%esp)
	xorl	%ebx, %ebx
	call	unlink
	testl	%eax, %eax
	sete	%bl
	jmp	.L776
.L1035:
	movl	filetracing, %eax
	testl	%eax, %eax
	je	.L845
	movl	$chbuf4, 12(%esp)
	movl	%esi, 8(%esp)
	movl	$.LC21, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L845:
	movl	$.LC120, 4(%esp)
	movl	$chbuf4, (%esp)
	call	fopen
	movl	%eax, %ebx
	jmp	.L776
.L1042:
	movl	filetracing, %eax
	testl	%eax, %eax
	je	.L905
	movl	$chbuf4, 12(%esp)
	movl	%edi, 8(%esp)
	movl	$.LC21, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L905:
	leal	52(%esp), %eax
	movl	%eax, 8(%esp)
	movl	$chbuf4, 4(%esp)
	movl	$3, (%esp)
	call	__xstat
	testl	%eax, %eax
	je	.L906
	movl	W, %eax
	xorl	%ebx, %ebx
	movl	$0, (%eax,%esi,4)
	movl	$0, 4(%eax,%esi,4)
	movl	$-1, 8(%eax,%esi,4)
	jmp	.L776
.L1031:
	movl	filetracing, %eax
	testl	%eax, %eax
	je	.L835
	movl	$chbuf4, 12(%esp)
	movl	%esi, 8(%esp)
	movl	$.LC21, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L835:
	movl	$.LC41, 4(%esp)
	movl	$chbuf4, (%esp)
	call	fopen
	movl	%eax, %ebx
	jmp	.L776
.L1037:
	movl	%esi, %ebx
	movl	filetracing, %esi
	testl	%esi, %esi
	je	.L882
	movl	32(%esp), %ecx
	movl	$chbuf3, 12(%esp)
	movl	$.LC21, 4(%esp)
	movl	$1, (%esp)
	movl	%ecx, 8(%esp)
	call	__printf_chk
.L882:
	movl	%ebx, 4(%esp)
	movl	%edi, (%esp)
	call	prepend_prefix
	movl	$chbuf4, %edx
.L1020:
	movzbl	(%eax), %ebx
	addl	$1, %eax
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	je	.L884
.L1049:
	testl	%ecx, %ecx
	movb	%bl, (%edx)
	je	.L1048
	movzbl	(%eax), %ebx
	addl	$1, %edx
	addl	$1, %eax
	movsbl	%bl, %ecx
	cmpl	$92, %ecx
	jne	.L1049
.L884:
	movb	$47, (%edx)
	addl	$1, %edx
	jmp	.L1020
.L1048:
	movl	filetracing, %ecx
	testl	%ecx, %ecx
	je	.L886
	movl	$chbuf4, 12(%esp)
	movl	%edi, 8(%esp)
	movl	$.LC21, 4(%esp)
	movl	$1, (%esp)
	call	__printf_chk
.L886:
	movl	$chbuf4, (%esp)
	xorl	%ebx, %ebx
	call	unlink
	movl	$chbuf4, 4(%esp)
	movl	$chbuf3, (%esp)
	call	rename
	testl	%eax, %eax
	sete	%bl
	jmp	.L776
.L887:
	movl	$0, taskname
	xorl	%edx, %edx
	movl	$0, taskname+4
	movl	$0, taskname+8
	jmp	.L924
.L894:
	movl	$0, taskname
	xorl	%eax, %eax
	movl	$0, taskname+4
	movl	$0, taskname+8
	jmp	.L925
.L1033:
	addl	$1, %edx
	cmpl	$-1, %ebx
	movl	%edx, idx.6086
	jne	.L776
	jmp	.L810
	.p2align 4,,7
	.p2align 3
.L805:
	movl	$0, tallylim
	xorl	%ebx, %ebx
	jmp	.L776
.L808:
	movl	%eax, 4(%esp)
	movl	%edx, (%esp)
	call	cintasm
	movl	%eax, %ebx
	jmp	.L776
.L811:
	movl	stdout, %eax
	movl	$8, %ebx
	movl	$8, (%esp)
	movl	%eax, 4(%esp)
	call	_IO_putc
	jmp	.L812
.L1034:
	movl	stdout, %eax
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	_IO_putc
	cmpl	$13, %ebx
	jne	.L812
	movl	stdout, %eax
	movb	$10, %bl
	movl	$10, (%esp)
	movl	%eax, 4(%esp)
	call	_IO_putc
	jmp	.L812
.L1030:
	call	__stack_chk_fail
.L906:
	movl	116(%esp), %eax
	movl	$86400, %ebx
	movl	W, %ecx
	movl	%eax, %edx
	sarl	$31, %edx
	idivl	%ebx
	orl	$-1, %ebx
	movl	$-1, 8(%ecx,%esi,4)
	imull	$1000, %edx, %edx
	movl	%eax, (%ecx,%esi,4)
	movl	%edx, 4(%ecx,%esi,4)
	jmp	.L776
.L1044:
	leal	156(%esp), %ebx
	jmp	.L912
.L1045:
	leal	156(%esp), %ebx
.L973:
	xorl	%ebp, %ebp
	movl	36(%esp), %eax
	jmp	.L989
.L936:
	movl	$chbuf2, %edx
	jmp	.L822
.L962:
	movl	$chbuf2, %edx
	jmp	.L890
.L959:
	movl	$chbuf2, %edx
	jmp	.L875
.L956:
	movl	$chbuf1, %edx
	jmp	.L869
.L933:
	movl	$chbuf1, %edx
	jmp	.L816
.L940:
	movl	$chbuf1, %esi
	jmp	.L828
.L970:
	xorl	%ebp, %ebp
	jmp	.L908
.L944:
	movl	$chbuf1, %esi
	jmp	.L838
.L968:
	movl	$chbuf1, %edx
	jmp	.L898
.L948:
	movl	$chbuf1, %esi
	jmp	.L848
.L953:
	movl	$chbuf1, %esi
	jmp	.L859
	.cfi_endproc
.LFE127:
	.size	dosys, .-dosys
	.globl	reattach_stdin
	.bss
	.align 4
	.type	reattach_stdin, @object
	.size	reattach_stdin, 4
reattach_stdin:
	.zero	4
	.globl	inbuf
	.align 4
	.type	inbuf, @object
	.size	inbuf, 4
inbuf:
	.zero	4
	.comm	old_segvhandler,4,4
	.comm	old_inthandler,4,4
	.globl	mainpid
	.align 4
	.type	mainpid, @object
	.size	mainpid, 4
mainpid:
	.zero	4
	.comm	taskname,16,4
	.comm	dcountv,4,4
	.comm	vecstatsv,4,4
	.comm	vecstatsvec,4,4
	.comm	vecstatsvupb,4,4
	.globl	tallylim
	.align 4
	.type	tallylim, @object
	.size	tallylim, 4
tallylim:
	.zero	4
	.comm	tallyv,4,4
	.comm	tallyvec,4,4
	.comm	tallyupb,4,4
	.comm	memupb,4,4
	.globl	boottrace
	.align 4
	.type	boottrace, @object
	.size	boottrace, 4
boottrace:
	.zero	4
	.globl	slowflag
	.align 4
	.type	slowflag, @object
	.size	slowflag, 4
slowflag:
	.zero	4
	.globl	dumpflag
	.align 4
	.type	dumpflag, @object
	.size	dumpflag, 4
dumpflag:
	.zero	4
	.globl	filetracing
	.align 4
	.type	filetracing, @object
	.size	filetracing, 4
filetracing:
	.zero	4
	.globl	tracing
	.align 4
	.type	tracing, @object
	.size	tracing, 4
tracing:
	.zero	4
	.comm	result2,4,4
	.comm	globbase,4,4
	.comm	stackbase,4,4
	.comm	prefixbp,4,4
	.globl	prefixstr
	.align 4
	.type	prefixstr, @object
	.size	prefixstr, 4
prefixstr:
	.zero	4
	.globl	scriptsvarstr
	.align 4
	.type	scriptsvarstr, @object
	.size	scriptsvarstr, 4
scriptsvarstr:
	.zero	4
	.globl	hdrsvarstr
	.align 4
	.type	hdrsvarstr, @object
	.size	hdrsvarstr, 4
hdrsvarstr:
	.zero	4
	.globl	pathvarstr
	.align 4
	.type	pathvarstr, @object
	.size	pathvarstr, 4
pathvarstr:
	.zero	4
	.globl	rootvarstr
	.align 4
	.type	rootvarstr, @object
	.size	rootvarstr, 4
rootvarstr:
	.zero	4
	.comm	lastst,4,4
	.comm	lastWg,4,4
	.comm	lastWp,4,4
	.comm	W,4,4
	.comm	trvec,16384,32
	.globl	trcount
	.data
	.align 4
	.type	trcount, @object
	.size	trcount, 4
trcount:
	.long	-1
	.local	idx.6086
	.comm	idx.6086,4,4
	.section	.rodata.str1.1
.LC124:
	.string	"BCPLPATH"
	.data
	.align 4
	.type	pathvar, @object
	.size	pathvar, 4
pathvar:
	.long	.LC124
	.local	chbuf4
	.comm	chbuf4,256,32
	.local	chbuf1
	.comm	chbuf1,256,32
	.local	chbuf2
	.comm	chbuf2,256,32
	.local	chbuf3
	.comm	chbuf3,256,32
	.section	.rodata.str1.4
	.align 4
.LC125:
	.string	" FLTOP    KH  LLPH    LH   LPH   SPH   APH    AH"
	.align 4
.LC126:
	.string	"   BRK    KW  LLPW    LW   LPW   SPW   APW    AW"
	.align 4
.LC127:
	.string	"    K3   K3G  K3G1  K3GH   LP3   SP3   AP3  L0P3"
	.align 4
.LC128:
	.string	"    K4   K4G  K4G1  K4GH   LP4   SP4   AP4  L0P4"
	.align 4
.LC129:
	.string	"    K5   K5G  K5G1  K5GH   LP5   SP5   AP5  L0P5"
	.align 4
.LC130:
	.string	"    K6   K6G  K6G1  K6GH   LP6   SP6   AP6  L0P6"
	.align 4
.LC131:
	.string	"    K7   K7G  K7G1  K7GH   LP7   SP7   AP7  L0P7"
	.align 4
.LC132:
	.string	"    K8   K8G  K8G1  K8GH   LP8   SP8   AP8  L0P8"
	.align 4
.LC133:
	.string	"    K9   K9G  K9G1  K9GH   LP9   SP9   AP9  L0P9"
	.align 4
.LC134:
	.string	"   K10  K10G K10G1 K10GH  LP10  SP10  AP10 L0P10"
	.align 4
.LC135:
	.string	"   K11  K11G K11G1 K11GH  LP11  SP11  AP11 L0P11"
	.align 4
.LC136:
	.string	"    LF   S0G  S0G1  S0GH  LP12  SP12  AP12 L0P12"
	.align 4
.LC137:
	.string	"   LF$   L0G  L0G1  L0GH  LP13  SP13 XPBYT     S"
	.align 4
.LC138:
	.string	"    LM   L1G  L1G1  L1GH  LP14  SP14   LMH    SH"
	.align 4
.LC139:
	.string	"   LM1   L2G  L2G1  L2GH  LP15  SP15   BTC  MDIV"
	.align 4
.LC140:
	.string	"    L0    LG   LG1   LGH  LP16  SP16   NOP CHGCO"
	.align 4
.LC141:
	.string	"    L1    SG   SG1   SGH   SYS    S1    A1   NEG"
	.align 4
.LC142:
	.string	"    L2   LLG  LLG1  LLGH   SWB    S2    A2   NOT"
	.align 4
.LC143:
	.string	"    L3    AG   AG1   AGH   SWL    S3    A3  L1P3"
	.align 4
.LC144:
	.string	"    L4   MUL   ADD    RV    ST    S4    A4  L1P4"
	.align 4
.LC145:
	.string	"    L5   DIV   SUB   RV1   ST1   XCH    A5  L1P5"
	.align 4
.LC146:
	.string	"    L6   REM   LSH   RV2   ST2  GBYT  RVP3  L1P6"
	.align 4
.LC147:
	.string	"    L7   XOR   RSH   RV3   ST3  PBYT  RVP4  L2P3"
	.align 4
.LC148:
	.string	"    L8    SL   AND   RV4  STP3   ATC  RVP5  L2P4"
	.align 4
.LC149:
	.string	"    L9   SL$    OR   RV5  STP4   ATB  RVP6  L2P5"
	.align 4
.LC150:
	.string	"   L10    LL   LLL   RV6  STP5     J  RVP7  L3P3"
	.align 4
.LC151:
	.string	"  FHOP   LL$  LLL$   RTN  GOTO    J$ ST0P3  L3P4"
	.align 4
.LC152:
	.string	"   JEQ   JNE   JLS   JGR   JLE   JGE ST0P4  L4P3"
	.align 4
.LC153:
	.string	"  JEQ$  JNE$  JLS$  JGR$  JLE$  JGE$ ST1P3  L4P4"
	.align 4
.LC154:
	.string	"  JEQ0  JNE0  JLS0  JGR0  JLE0  JGE0 ST1P4 SELLD"
	.align 4
.LC155:
	.string	" JEQ0$ JNE0$ JLS0$ JGR0$ JLE0$ JGE0$    MW SELST"
	.section	.rodata
	.align 32
	.type	CSWTCH.261, @object
	.size	CSWTCH.261, 124
CSWTCH.261:
	.long	.LC125
	.long	.LC126
	.long	.LC127
	.long	.LC128
	.long	.LC129
	.long	.LC130
	.long	.LC131
	.long	.LC132
	.long	.LC133
	.long	.LC134
	.long	.LC135
	.long	.LC136
	.long	.LC137
	.long	.LC138
	.long	.LC139
	.long	.LC140
	.long	.LC141
	.long	.LC142
	.long	.LC143
	.long	.LC144
	.long	.LC145
	.long	.LC146
	.long	.LC147
	.long	.LC148
	.long	.LC149
	.long	.LC150
	.long	.LC151
	.long	.LC152
	.long	.LC153
	.long	.LC154
	.long	.LC155
	.section	.rodata.cst4,"aM",@progbits,4
	.align 4
.LC10:
	.long	1203982336
	.align 4
.LC11:
	.long	1092616192
	.section	.rodata.cst8,"aM",@progbits,8
	.align 8
.LC14:
	.long	-1998362383
	.long	1055193269
	.align 8
.LC15:
	.long	-1717986918
	.long	1069128089
	.section	.rodata.cst4
	.align 4
.LC16:
	.long	1315859240
	.align 4
.LC17:
	.long	1056964608
	.ident	"GCC: (Ubuntu/Linaro 4.6.3-1ubuntu5) 4.6.3"
	.section	.note.GNU-stack,"",@progbits
