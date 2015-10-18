	.file	"ct1.c"
	.text
.globl f
	.type	f, @function
f:
	pushl	%ebp
	movl	%esp, %ebp
	movl	12(%ebp), %eax
	addl	8(%ebp), %eax
	addl	16(%ebp), %eax
	popl	%ebp
	ret
	.size	f, .-f
.globl main
	.type	main, @function
main:
	leal	4(%esp), %ecx
	andl	$-16, %esp
	pushl	-4(%ecx)
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%ecx
	subl	$28, %esp
	movl	$333, 8(%esp)
	movl	$222, 4(%esp)
	movl	$111, (%esp)
	call	f
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	movl	%eax, -12(%ebp)
	movl	-12(%ebp), %eax
	addl	$1, %eax
	movl	%eax, -8(%ebp)
	movl	-12(%ebp), %eax
	cmpl	-8(%ebp), %eax
	ja	.L4
	movl	$1, -16(%ebp)
.L4:
	movl	-12(%ebp), %eax
	cmpl	-8(%ebp), %eax
	jae	.L6
	movl	$1, -16(%ebp)
.L6:
	movl	-12(%ebp), %eax
	cmpl	-8(%ebp), %eax
	jb	.L8
	movl	$1, -16(%ebp)
.L8:
	movl	-12(%ebp), %eax
	cmpl	-8(%ebp), %eax
	jbe	.L10
	movl	$1, -16(%ebp)
.L10:
	cmpl	$10, -12(%ebp)
	ja	.L12
	movl	$1, -16(%ebp)
.L12:
	cmpl	$9, -12(%ebp)
	ja	.L14
	movl	$1, -16(%ebp)
.L14:
	cmpl	$9, -12(%ebp)
	jbe	.L16
	movl	$1, -16(%ebp)
.L16:
	cmpl	$10, -12(%ebp)
	jbe	.L18
	movl	$1, -16(%ebp)
.L18:
	movl	$0, %eax
	addl	$28, %esp
	popl	%ecx
	popl	%ebp
	leal	-4(%ecx), %esp
	ret
	.size	main, .-main
	.ident	"GCC: (GNU) 4.1.2 20070626 (Red Hat 4.1.2-13)"
	.section	.note.GNU-stack,"",@progbits
