# mlib.s - machine-code library for Native BCPL on LINUX
# $Log: mlib.s,v $
# Revision 1.3  2004/03/31 20:06:57  colin
# Comments reorganised and much extended
#
# Revision 1.2  2004/03/30 20:21:43  colin
# Calls to sys(0,n) now abort the run, returning n.
#

# callstart called from C in clib.c as
# res = callstart(stackbase, globbase)
#	
# Linkage:
#   On entry 0(%esp)   is the return address
#            4(%esp)   is the first argument
#            8(%esp)   is the second argument
#            etc
#
#   %ebp, %ebx, %edi and %esi must be preserved
#
# On return,   result in %eax
#
# Flag DF clear on entry and exit

.globl callstart
.text
	.align 16

callstart:
	pushl %ebp
	pushl %ebx
	pushl %edi
	pushl %esi
	movl %esp, savesp	# save stack-pointer for unwinding
	subl $40,%esp		# reserve workspace
	movl 60(%esp),%ebp	#  stackbase (first  argument)
	movl 64(%esp),%esi	#  globbase  (second argument)

# Register usage while executing BCPL compiled code

# %eax  work register
# %ebx  Cintcode A
# %ecx  Cintcode B
# %edx  Cintcode C also used in division and remainder
# %ebp  The P pointer -- m/c address of BCPL stack frame
# %edi  work register
# %esi  The G pointer -- m/c address of Global 0
# %esp  points to main work space:
#    64(%esp)   gvec      (second arg of callstart)
#    60(%esp)   stackbase (first  arg of callstart)
#    56(%esp)   return address
#    52(%esp)   caller's %ebp
#    48(%esp)   caller's %ebx
#    44(%esp)   caller's %edi
#    40(%esp)   caller's %esi
#    36(%esp)   
#    ...      ) space for args
#    00(%esp) )    of external calls

# Set BCPL globals for functions defined in this module
	movl $sys, 4*3(%esi)		# Global 3
	movl $changeco, 4*6(%esi)	# Global 6
	movl $muldiv, 4*19(%esi)	# Global 19

# BCPL call of clihook(stackupb)
	movl stackupb,%ebx	# argument 1
	leal 24(%ebp),%edx	# new value for P
	movl 16(%esi),%eax	# Entry-point in Global 4
	call *%eax		# call clihook
	movl %ebx,%eax		# return the result of BCPL start()
	   
# and then return to C caller
	addl $40,%esp		# recover workspace
finish:	
	popl %esi
	popl %edi
	popl %ebx
	popl %ebp
	ret

.data
savesp:	.int 0

.text
	
# BCPL call res := sys(n, x, y, x)
# For n > 0, calls the C function dosys(p, g) in clib.c
# with arguments P and G. Args x, y ... are at p[3], p[4]....
# For n = 0, aborts the program with result x.
sys:
	movl %ebp,0(%edx)	# NP!0 := P
	movl %edx,%ebp		# P    := NP
	popl %edx		# pop return address	
	movl %edx,4(%ebp)	# P!1  := return address
	movl %eax,8(%ebp)	# P!2  := entry address
	movl %ebx,12(%ebp)	# P!3  := arg1
	# test for sys(0....
	or %ebx, %ebx
	jnz cont
	
	# sys(0, x) called, so we shall abort
	movl 16(%ebp), %eax	# second arg (x) to eax
	movl savesp, %esp	# unwind stack
	jmp finish
	
cont:	# other calls to sys(.. passed to dosys(p, g)	
	movl %esi,%edx		# second arg in edx
	movl %ebp,%eax		# first  arg in eax
	pushl %edx		# ... pushed onto stack
	pushl %eax
	call dosys		# call the C function
	addl $8,%esp		# restore esp to before the 2 x pushl
	# return to the BCPL caller 
	movl %eax,%ebx		# put result of dosys() in Cintcode A register
	movl 4(%ebp),%eax	# return address
	movl 0(%ebp),%ebp	# restore caller's P
	jmp *%eax		# return
#
changeco:
	movl %ebp,0(%edx)   # NP!0 := P
	movl %edx,%ebp      # P    := NP
	popl %edx
	movl %edx,4(%ebp)   # P!1  := return address
	movl %eax,8(%ebp)   # P!2  := entry address
	movl %ebx,12(%ebp)  # P!3  := arg1

	movl (%ebp),%edx
	movl 4*7(%esi),%eax
	movl %edx,(,%eax,4)        # !currco := !p
	movl 4(%ebp),%eax          # pc := p!1
	movl 16(%ebp),%edx
	movl %edx,4*7(%esi)        # currco := cptr
	movl 0(,%edx,4),%ebp       # p := !cptr
	jmp *%eax

muldiv:
	movl %ebx,%eax
	movl %edx,%ebx         # new P in ebx
	imull 16(%ebx)         # %eax:%edx := double length product
	idivl 20(%ebx)         # %eax = quotient, %edx = remainder
	movl %ebx,4*10(%esi)   # result2 := remainder
	movl %eax,%ebx         # a := quotient
	ret
