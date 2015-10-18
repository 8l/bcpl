# This will be the machine code library for ARM based on the i386 version
# CURRENTLY UNDER DEVELOPMENT.
	
# Linkage:
#   On entry rl   is the return address
#            r0   is the first argument
#            r1   is the second argument
#            etc
#
#   r4 - r13 must be preserved
#
#   result in r0

.globl callstart
.globl _callstart

.text
	.align 2

callstart:
_callstart:
 stmia r4!,{fp,lr,pc}
 stmia r4,{r0,r1,r2,r3}
 sub fp,r4,#12
 @ r0 = stackbase (first argument}
 @ r1 = gvec (second argument}
 pushl %ebp
 pushl %ebx
 pushl %edi
 pushl %esi
 subl $40,%esp
 movl 60(%esp),%ebp      #  stackbase (first  argument)
 movl 64(%esp),%esi      #  gvec      (second argument)

# Register usage while executing BCPL compiled code

# %eax r0  work register
# %ebx r1 Cintcode A
# %ecx r2 Cintcode B
# %edx r3 Cintcode C also used in division and remainder
# %ebp r10  The P pointer -- m/c address
# %edi  work register
# %esi r11  The G pointer -- m/c address of Global 0
# %esp  points to main work space
@ r13   link register
@ r14   stack pointer
@ r15   PC
#    64(%esp)   gvec      (second arg of callstart)
#    60(%esp)   stackbase (first  arg of callstart)
#    56(%esp)   return address
#    52(%esp)   caller's %ebp
#    48(%esp)   caller's %ebx
#    44(%esp)   caller's %edi
#    40(%esp)   caller's %esi
#    36(%esp)   
#    32(%esp)   
#    28(%esp)   
#    24(%esp)   
#    20(%esp)   
#    16(%esp)   
#    ...      ) space for args
#      (%esp) )    of external calls

   # make sure global 3 (sys) is defined
   movl $sys, 4*3(%esi)
   # make sure global 6 (changeco) is defined
   movl $changeco, 4*6(%esi)
   # make sure global 5 (muldiv) is defined
   movl $muldiv, 4*5(%esi)

   # BCPL call of clihook(stackupb)
   movl stackupb,%ebx
#   movl _stackupb,%ebx
   leal 24(%ebp),%edx
   movl 16(%esi),%eax
   call *%eax
   movl %ebx,%eax    # return the result of start
   
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

muldiv:
 movl %ebx,%eax
 movl %edx,%ebx         # new P in ebx
 imull 16(%ebx)         # %eax:%edx := double length product
 idivl 20(%ebx)         # %eax = quotient, %edx = remainder
 movl %ebx,4*10(%esi)   # result2 := remainder
 movl %eax,%ebx         # a := quotient
 ret
   

