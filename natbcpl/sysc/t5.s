	.file	"t5.c"
	.text
	.globl	releq
	.type	releq, @function
releq:
.LFB0:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	flds	8(%ebp)
	flds	12(%ebp)
	fucomip	%st(1), %st
	fstp	%st(0)
	setnp	%al
	movzbl	%al, %edx
	movl	$0, %eax
	flds	8(%ebp)
	flds	12(%ebp)
	fucomip	%st(1), %st
	fstp	%st(0)
	cmove	%edx, %eax
	popl	%ebp
	.cfi_def_cfa 4, 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE0:
	.size	releq, .-releq
	.globl	relne
	.type	relne, @function
relne:
.LFB1:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	flds	8(%ebp)
	flds	12(%ebp)
	fucomip	%st(1), %st
	fstp	%st(0)
	setnp	%al
	movzbl	%al, %edx
	movl	$0, %eax
	flds	8(%ebp)
	flds	12(%ebp)
	fucomip	%st(1), %st
	fstp	%st(0)
	cmove	%edx, %eax
	popl	%ebp
	.cfi_def_cfa 4, 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE1:
	.size	relne, .-relne
	.globl	rells
	.type	rells, @function
rells:
.LFB2:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	flds	8(%ebp)
	flds	12(%ebp)
	fucomip	%st(1), %st
	fstp	%st(0)
	setnp	%al
	movzbl	%al, %edx
	movl	$0, %eax
	flds	8(%ebp)
	flds	12(%ebp)
	fucomip	%st(1), %st
	fstp	%st(0)
	cmove	%edx, %eax
	popl	%ebp
	.cfi_def_cfa 4, 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE2:
	.size	rells, .-rells
	.globl	relgr
	.type	relgr, @function
relgr:
.LFB3:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	flds	8(%ebp)
	flds	12(%ebp)
	fucomip	%st(1), %st
	fstp	%st(0)
	setnp	%al
	movzbl	%al, %edx
	movl	$0, %eax
	flds	8(%ebp)
	flds	12(%ebp)
	fucomip	%st(1), %st
	fstp	%st(0)
	cmove	%edx, %eax
	popl	%ebp
	.cfi_def_cfa 4, 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE3:
	.size	relgr, .-relgr
	.globl	relle
	.type	relle, @function
relle:
.LFB4:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	flds	8(%ebp)
	flds	12(%ebp)
	fucomip	%st(1), %st
	fstp	%st(0)
	setnp	%al
	movzbl	%al, %edx
	movl	$0, %eax
	flds	8(%ebp)
	flds	12(%ebp)
	fucomip	%st(1), %st
	fstp	%st(0)
	cmove	%edx, %eax
	popl	%ebp
	.cfi_def_cfa 4, 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE4:
	.size	relle, .-relle
	.globl	relge
	.type	relge, @function
relge:
.LFB5:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	flds	8(%ebp)
	flds	12(%ebp)
	fucomip	%st(1), %st
	fstp	%st(0)
	setnp	%al
	movzbl	%al, %edx
	movl	$0, %eax
	flds	8(%ebp)
	flds	12(%ebp)
	fucomip	%st(1), %st
	fstp	%st(0)
	cmove	%edx, %eax
	popl	%ebp
	.cfi_def_cfa 4, 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE5:
	.size	relge, .-relge
	.globl	releq0
	.type	releq0, @function
releq0:
.LFB6:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	flds	8(%ebp)
	fldz
	fucomip	%st(1), %st
	fstp	%st(0)
	setnp	%al
	movzbl	%al, %edx
	movl	$0, %eax
	flds	8(%ebp)
	fldz
	fucomip	%st(1), %st
	fstp	%st(0)
	cmove	%edx, %eax
	popl	%ebp
	.cfi_def_cfa 4, 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE6:
	.size	releq0, .-releq0
	.globl	relne0
	.type	relne0, @function
relne0:
.LFB7:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	flds	8(%ebp)
	fldz
	fucomip	%st(1), %st
	fstp	%st(0)
	setnp	%al
	movzbl	%al, %edx
	movl	$0, %eax
	flds	8(%ebp)
	fldz
	fucomip	%st(1), %st
	fstp	%st(0)
	cmove	%edx, %eax
	popl	%ebp
	.cfi_def_cfa 4, 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE7:
	.size	relne0, .-relne0
	.globl	rells0
	.type	rells0, @function
rells0:
.LFB8:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	flds	8(%ebp)
	fldz
	fucomip	%st(1), %st
	fstp	%st(0)
	setnp	%al
	movzbl	%al, %edx
	movl	$0, %eax
	flds	8(%ebp)
	fldz
	fucomip	%st(1), %st
	fstp	%st(0)
	cmove	%edx, %eax
	popl	%ebp
	.cfi_def_cfa 4, 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE8:
	.size	rells0, .-rells0
	.globl	relgr0
	.type	relgr0, @function
relgr0:
.LFB9:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	flds	8(%ebp)
	fldz
	fucomip	%st(1), %st
	fstp	%st(0)
	setnp	%al
	movzbl	%al, %edx
	movl	$0, %eax
	flds	8(%ebp)
	fldz
	fucomip	%st(1), %st
	fstp	%st(0)
	cmove	%edx, %eax
	popl	%ebp
	.cfi_def_cfa 4, 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE9:
	.size	relgr0, .-relgr0
	.globl	relle0
	.type	relle0, @function
relle0:
.LFB10:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	flds	8(%ebp)
	fldz
	fucomip	%st(1), %st
	fstp	%st(0)
	setnp	%al
	movzbl	%al, %edx
	movl	$0, %eax
	flds	8(%ebp)
	fldz
	fucomip	%st(1), %st
	fstp	%st(0)
	cmove	%edx, %eax
	popl	%ebp
	.cfi_def_cfa 4, 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE10:
	.size	relle0, .-relle0
	.globl	relge0
	.type	relge0, @function
relge0:
.LFB11:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	flds	8(%ebp)
	fldz
	fucomip	%st(1), %st
	fstp	%st(0)
	setnp	%al
	movzbl	%al, %edx
	movl	$0, %eax
	flds	8(%ebp)
	fldz
	fucomip	%st(1), %st
	fstp	%st(0)
	cmove	%edx, %eax
	popl	%ebp
	.cfi_def_cfa 4, 4
	.cfi_restore 5
	ret
	.cfi_endproc
.LFE11:
	.size	relge0, .-relge0
	.globl	main
	.type	main, @function
main:
.LFB12:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$16, %esp
	movl	$3, -12(%ebp)
	movl	$33, -8(%ebp)
	fildl	-12(%ebp)
	fldz
	fucomip	%st(1), %st
	fstp	%st(0)
	seta	%al
	movzbl	%al, %eax
	movl	%eax, -4(%ebp)
	movl	$0, %eax
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE12:
	.size	main, .-main
	.ident	"GCC: (Ubuntu/Linaro 4.6.3-1ubuntu5) 4.6.3"
	.section	.note.GNU-stack,"",@progbits
