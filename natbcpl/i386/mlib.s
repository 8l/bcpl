# C Linkage:
#   On entry 0(%esp)   is the return address
#            4(%esp)   is the first argument
#            8(%esp)   is the second argument
#            etc
#
#   %ebp, %ebx, %edi and %esi must be preserved
#
#   result in %eax
#
#   flag DF clear on entry and exit


.globl callstart
.globl _callstart

.text
	.align 16

# callstart(p, g)
   
callstart:
_callstart:
 pushl %ebp
 pushl %ebx
 pushl %edi
 pushl %esi
 subl $40,%esp
 movl 60(%esp),%ebp      #  stackbase (first  argument)
 movl 64(%esp),%esi      #  gvec      (second argument)

# Save caller's FPH contol word -- 16 bits
 fnstcw 36(%esp)

# Set FPH control word rounding to nearest with 24 bits precision
# suitable for 32 bit floating point to integer rounding.

# FPH codeword
#           IC     RC    PC
#    15 14 13 12  11 10 09 08  07 06 05 04  03 02 01 00
#                  0  0     Round to nearest
#                  0  1     Round towards - infinity
#                  1  0     Round towards + infinity
#                  1  1     Round towards zero
#                        0  0     24 bit procision
#                        1  0     53 bit procision
#                        1  1     64 bit procision

 movzwl	36(%esp), %eax
 movb	$0xC0, %ah    
 movw	%ax, 38(%esp)
 fldcw	38(%esp)


# Register usage while executing BCPL compiled code

# %eax  work register
# %ebx  Cintcode A
# %ecx  Cintcode B
# %edx  Cintcode C also used in division and remainder
# %ebp  The P pointer -- m/c address
# %edi  work register
# %esi  The G pointer -- m/c address of Global 0
# %esp  points to main work space
#    64(%esp)   gvec      (second arg of callstart)
#    60(%esp)   stackbase (first  arg of callstart)
#    56(%esp)   return address
#    52(%esp)   caller's %ebp
#    48(%esp)   caller's %ebx
#    44(%esp)   caller's %edi
#    40(%esp)   caller's %esi
#    36(%esp)   caller's FPH contol word
#    32(%esp)   
#    28(%esp)   
#    24(%esp)   
#    20(%esp)   
#    16(%esp)   
#    ...      ) space for args
#      (%esp) )    of external calls

#      (%esp)  is also used as a work location in the compilation
#              of some floating point operations.

   # make sure global 3 (sys) is defined
   movl $sys, 4*3(%esi)
   # make sure global 6 (changeco) is defined
   movl $changeco, 4*6(%esi)
   # make sure global 5 (muldiv) is defined
   # movl $muldiv, 4*5(%esi)

   # BCPL call of clihook(stackupb)
   movl stackupb,%ebx    # A := stackupb
   leal 24(%ebp),%edx    # NP := P + 6
   movl 16(%esi),%eax    # clihook entry address
   call *%eax
   movl %ebx,%eax    # return the clihook result as callstart result

# Restore caller's FPH contol word -- 16 bits
 fldcw 36(%esp)
	
# and then return
 addl $40,%esp
 popl %esi
 popl %edi
 popl %ebx
 popl %ebp
 ret

   	.align 16

   # res = sys(n, x, y, x)  the BCPL callable sys function
sys:
 movl %ebp,0(%edx)   # NP!0 := P
 movl %edx,%ebp      # P    := NP
 popl %edx
 movl %edx,4(%ebp)   # P!1  := return address
 movl %eax,8(%ebp)   # P!2  := entry address
 movl %ebx,12(%ebp)  # P!3  := arg1

 movl %esi,%edx       # second arg (G) in edx
 movl %ebp,%eax       # first  arg (P) in eax
 pushl %edx
 pushl %eax
 call dosys
# call _dosys
 addl $8,%esp
 movl %eax,%ebx       # put result in Cintcode A register

 movl 4(%ebp),%eax
 movl 0(%ebp),%ebp
 jmp *%eax

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

muldiv1:
 movl %ebx,%eax
 movl %edx,%ebx         # new P in ebx
 imull 16(%ebx)         # %eax:%edx := double length product
 idivl 20(%ebx)         # %eax = quotient, %edx = remainder
 movl %ebx,4*10(%esi)   # result2 := remainder
 movl %eax,%ebx         # a := quotient
 ret
   

