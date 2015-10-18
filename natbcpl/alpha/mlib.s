 # It uses the following linkage conventions:
 #
 # $0       v0       The returned value
 # $1-$8    t0 - t7  Temporary registers
 # $9-$15   s0 - s6  Must be preserved
 # $16-$21  a0 - a5  The first six conforming arguments
 # $22-$25  t8 - t11 Temporary registers
 # $26      ra       The return address
 # $27      t12      Temporary registers (or procedure value)
 # $28      at       May be used by the assembler
 # $29      gp       Global pointer
 # $30      sp       Points to stack location of first argument on entry
 # $31      zero     Always has value zero

#include <regdef.h>

        .ugen

        .text
        .align  4
        .globl  callstart

        .ent    callstart 2
callstart:
        ldgp    gp, 0(pv)
        lda     sp, -128(sp)
        stq     ra, 120(sp)
        stq     s0, 112(sp)
        stq     s1, 104(sp)
        stq     s2, 96(sp)
        stq     s3, 88(sp)
        stq     s4, 80(sp)
        stq     s5, 72(sp)
        stq     s6, 64(sp)

        mov     a0,s3            # P pointer (first arg)
        mov     a1,s4            # G pointer (second arg)
   
 # Register usage while executing BCPL compiled code

 # s0   A
 # s1   B
 # s2   C
 # s3   m/c addr P
 # s4   m/c addr G
 # s5   
 # s6   
 # t0   NP on call
 # t1   Entry address on call

   
 # $0       v0       The returned value
 # $1-$8    t0 - t7  Temporary registers
 # $9-$15   s0 - s6  Preserved on function calls
 # $16-$21  a0 - a5  The first six conforming arguments
 # $22-$25  t8 - t11 Temporary registers
 # $26      ra       The return address
 # $27      t12      Temporary registers (or procedure value)
 # $28      at       May be used by the assembler
 # $29      gp       Global pointer
 # $30      sp       Points to stack location of first argument on entry
 # $31      zero     Always has value zero

      
 # make sure global 3 (sys) is defined
    lda t0,sys
    stq t0,8*3(s4)
 # make sure global 6 (changeco) is defined
    lda t0,changeco
    stq t0,8*6(s4)
 # make sure global 19 (muldiv) is defined
    lda t0,muldiv
    stq t0,8*19(s4)

 # BCPL call of clihook(stackupb)
    ldq    s0,stackupb
    addq   s3,8*6,t0
    ldq    t1,8*4(s4)  # clihook

    jsr    ra,(t1),1
    
    mov    s0,v0                 # return the result of start

   ret:                          # Result in v0
      ldq     s6,64(sp)          # restore registers
      ldq     s5,72(sp)
      ldq     s4,80(sp)
      ldq     s3,88(sp)
      ldq     s2,96(sp)
      ldq     s1,104(sp)
      ldq     s0,112(sp)
      ldq     ra,120(sp)

      lda     sp,128(sp)
      ret     zero,(ra),1


 # res = sys(n, x, y, x)  the BCPL callable sys function

sys:
         stq     s3,0(t0)        # NP!0 := P
         mov     t0,s3           # P := NP
         stq     ra,8*1(s3)      # P!1 := L
         stq     t1,8*2(s3)      # P!2 := F
         stq     s0,8*3(s3)      # P!3 := first argument

sys1:
         mov     s4,a1           # g as a BCPL pointer
         mov     s3,a0           # p as a BCPL pointer
         jsr     ra,dosys
         ldgp    gp,0(ra)

         mov     v0,s0           # a := dosys(p, g)

         ldq     ra,8*1(s3)      # L := P!1
         ldq     s3,0(s3)        # P := P!0
         ret     zero,(ra),1     # goto L
   

changeco:                  # changeco(val, cptr)

         ldq     v0,8*7(s4)
         s8addq  v0,zero,v0
         stq     s3,0(v0)        # !currco := p

         ldq     v0,8*4(t0)      #           (NP!4)
         stq     v0,8*7(s4)      # currco := cptr

         s8addq  v0,zero,v0
         ldq     s3,0(v0)        # p := !cptr
   
         jmp     zero,(ra)       # jump L


 .end
   