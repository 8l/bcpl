	.file	"t2.c"
	.text
	.globl	f1
	.type	f1, @function
f1:
.LFB0:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$40, %esp
	flds	8(%ebp)
	fadds	12(%ebp)
	fstps	-16(%ebp)
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
	movl	%eax, -12(%ebp)
	movl	$11, 4(%esp)
	movl	-12(%ebp), %eax
	movl	%eax, (%esp)
	call	f
	flds	8(%ebp)
	flds	12(%ebp)
	fucomip	%st(1), %st
	fstp	%st(0)
	setp	%al
	movzbl	%al, %edx
	movl	$1, %eax
	flds	8(%ebp)
	flds	12(%ebp)
	fucomip	%st(1), %st
	fstp	%st(0)
	cmove	%edx, %eax
	movl	%eax, -12(%ebp)
	movl	$22, 4(%esp)
	movl	-12(%ebp), %eax
	movl	%eax, (%esp)
	call	f
	flds	12(%ebp)
	flds	8(%ebp)
	fxch	%st(1)
	fucomip	%st(1), %st
	fstp	%st(0)
	setae	%al
	movzbl	%al, %eax
	movl	%eax, -12(%ebp)
	movl	$33, 4(%esp)
	movl	-12(%ebp), %eax
	movl	%eax, (%esp)
	call	f
	flds	8(%ebp)
	flds	12(%ebp)
	fxch	%st(1)
	fucomip	%st(1), %st
	fstp	%st(0)
	setae	%al
	movzbl	%al, %eax
	movl	%eax, -12(%ebp)
	movl	$44, 4(%esp)
	movl	-12(%ebp), %eax
	movl	%eax, (%esp)
	call	f
	flds	12(%ebp)
	flds	8(%ebp)
	fxch	%st(1)
	fucomip	%st(1), %st
	fstp	%st(0)
	seta	%al
	movzbl	%al, %eax
	movl	%eax, -12(%ebp)
	movl	$55, 4(%esp)
	movl	-12(%ebp), %eax
	movl	%eax, (%esp)
	call	f
	flds	8(%ebp)
	flds	12(%ebp)
	fxch	%st(1)
	fucomip	%st(1), %st
	fstp	%st(0)
	seta	%al
	movzbl	%al, %eax
	movl	%eax, -12(%ebp)
	movl	$66, 4(%esp)
	movl	-12(%ebp), %eax
	movl	%eax, (%esp)
	call	f
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE0:
	.size	f1, .-f1
	.globl	main
	.type	main, @function
main:
.LFB1:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	andl	$-16, %esp
	subl	$16, %esp
	movl	$0x40c00000, %eax
	movl	%eax, 4(%esp)
	movl	$0x40e00000, %eax
	movl	%eax, (%esp)
	call	f1
	movl	$0x40e00000, %eax
	movl	%eax, 4(%esp)
	movl	$0x40c00000, %eax
	movl	%eax, (%esp)
	call	f1
	movl	$0x40e00000, %eax
	movl	%eax, 4(%esp)
	movl	$0x40e00000, %eax
	movl	%eax, (%esp)
	call	f1
	movl	$0xc0e00000, %eax
	movl	%eax, 4(%esp)
	movl	$0x40e00000, %eax
	movl	%eax, (%esp)
	call	f1
	movl	$0x40e00000, %eax
	movl	%eax, 4(%esp)
	movl	$0xc0e00000, %eax
	movl	%eax, (%esp)
	call	f1
	movl	$0xc0e00000, %eax
	movl	%eax, 4(%esp)
	movl	$0xc0e00000, %eax
	movl	%eax, (%esp)
	call	f1
	movl	$0, %eax
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE1:
	.size	main, .-main
	.ident	"GCC: (Ubuntu/Linaro 4.6.3-1ubuntu5) 4.6.3"
	.section	.note.GNU-stack,"",@progbits
