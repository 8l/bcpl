	.file	"tstflt.c"
	.text
	.globl	f
	.type	f, @function
f:
.LFB22:
	.cfi_startproc
	subl	$12, %esp
	.cfi_def_cfa_offset 16
	flds	16(%esp)
	fld	%st(0)
	fmuls	20(%esp)
	fdivs	.LC0
	faddp	%st, %st(1)
	fstps	(%esp)
	movl	(%esp), %eax
	addl	$12, %esp
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
.LFE22:
	.size	f, .-f
	.section	.rodata.cst4,"aM",@progbits,4
	.align 4
.LC0:
	.long	1069547520
	.ident	"GCC: (Ubuntu/Linaro 4.6.3-1ubuntu5) 4.6.3"
	.section	.note.GNU-stack,"",@progbits
