/*
Header for the MC machine independent dynamic code generation package.

Martin Richards (c) February 2007


MC code is compiled into space pointed to by mc, the currently selected
instance of the MC package.

Initialisation

LET mcb = mcInit(maxfn, isize, dsize) 

mcb is the control block for this instance of the MC package.

mcSelect(mcb) selects mcb as the current MC instance.

*/

MANIFEST {
// MC Machine Registers

  mc_a = 0  // MC register A
  mc_b = 1  // MC register B
  mc_c = 2  // MC register C
  mc_d = 3  // MC register D
  mc_e = 4  // MC register E
  mc_f = 5  // MC register F

// MC op codes and directives.

  mc_add=1     //    RA RV RG RM RL RD RDX RDXs RDXsB
               // RR AR VR GR MR LR DR DXR DXsR DXsBR
               // RK AK VK GK MK LK DK DXK DXsK DXsBK
  mc_addc      //    RA RV RG RM RL RD RDX RDXs RDXsB
               // RR AR VR GR MR LR DR DXR DXsR DXsBR
               // RK AK VK GK MK LK DK DXK DXsK DXsBK
  mc_alignc    // K
  mc_alignd    // K
  mc_and       //    RA RV RG RM RL RD RDX RDXs RDXsB
               // RR AR VR GR MR LR DR DXR DXsR DXsBR
               // RK AK VK GK MK LK DK DXK DXsK DXsBK
  mc_call      // KK
  mc_cdq       // F
  mc_cmp       //    RA RV RG RM RL RD RDX RDXs RDXsB
               // RR AR VR GR MR LR DR DXR DXsR DXsBR
               // RK AK VK GK MK LK DK DXK DXsK DXsBK
  mc_datab     // K
  mc_datak     // K
  mc_datal     // L
  mc_debug     // K
  mc_dec       //    R  A  V  G  M  L  D  DX  DXs  DXsB
  mc_div       // K  R  A  V  G  M  L  D  DX  DXs  DXsB
  mc_dlab      // L
  mc_end       // F
  mc_endfn     // F
  mc_entry     // KKK
  mc_inc       //    R  A  V  G  M  L  D  DX  DXs  DXsB
  mc_jeq       // JS JL JR
  mc_jge       // JS JL JR
  mc_jgt       // JS JL JR
  mc_jle       // JS JL JR
  mc_jlt       // JS JL JR
  mc_jmp       // JS JL JR
  mc_jne       // JS JL JR
  mc_lab       // L
  mc_lea       //    RA RV RG RM RL RD RDX RDXs RDXsB
  mc_lsh       // RK RR
  mc_mul       // K  R  A  V  G  M  L  D  DX  DXs  DXsB
  mc_mv        //    RA RV RG RM RL RD RDX RDXs RDXsB
               // RR AR VR GR MR LR DR DXR DXsR DXsBR
               // RK AK VK GK MK LK DK DXK DXsK DXsBK
  mc_mvsxb     //    RA RV RG RM RL RD RDX RDXs RDXsB
               // RR AR VR GR MR LR DR DXR DXsR DXsBR
  mc_mvsxh     //    RA RV RG RM RL RD RDX RDXs RDXsB
               // RR AR VR GR MR LR DR DXR DXsR DXsBR
  mc_mvb       //    AR VR GR MR LR DR DXR DXsR DXsBR
               //    AK VK GK MK LK DK DXK DXsK DXsBK
  mc_mvh       //    AR VR GR MR LR DR DXR DXsR DXsBR
               //    AK VK GK MK LK DK DXK DXsK DXsBK
  mc_mvzxb     //    RA RV RG RM RL RD RDX RDXs RDXsB
               // RR AR VR GR MR LR DR DXR DXsR DXsBR
  mc_mvzxh     //    RA RV RG RM RL RD RDX RDXs RDXsB
               // RR AR VR GR MR LR DR DXR DXsR DXsBR
  mc_neg       //    R  A  V  G  M  L  D  DX  DXs  DXsB
  mc_nop       //  F
  mc_not       //    R  A  V  G  M  L  D  DX  DXs  DXsB
  mc_or        //    RA RV RG RM RL RD RDX RDXs RDXsB
               // RR AR VR GR MR LR DR DXR DXsR DXsBR
               // RK AK VK GK MK LK DK DXK DXsK DXsBK
  mc_pop       //    R  A  V  G  M  L  D  DX  DXs  DXsB
  mc_push      // K  R  A  V  G  M  L  D  DX  DXs  DXsB
  mc_rsh       // RK  RR
  mc_rtn       // K
  mc_seq       //    R
  mc_sge       //    R
  mc_sge       //    R
  mc_sgt       //    R
  mc_sle       //    R
  mc_slt       //    R
  mc_sne       //    R
  mc_sub       //    RA RV RG RM RL RD RDX RDXs RDXsB
               // RR AR VR GR MR LR DR DXR DXsR DXsBR
               // RK AK VK GK MK LK DK DXK DXsK DXsBK
  mc_subc      //    RA RV RG RM RL RD RDX RDXs RDXsB
               // RR AR VR GR MR LR DR DXR DXsR DXsBR
               // RK AK VK GK MK LK DK DXK DXsK DXsBK
  mc_udiv      // K  R  A  V  G  M  L  D  DX  DXs  DXsB
  mc_ujge      // JS JL JR
  mc_ujgt      // JS JL JR
  mc_ujle      // JS JL JR
  mc_ujlt      // JS JL JR
  mc_umul      // K  R  A  V  G  M  L  D  DX  DXs  DXsB
  mc_usge      // JS JL JR
  mc_usgt      // JS JL JR
  mc_usle      // JS JL JR
  mc_uslt      // JS JL JR
  mc_xchg      // RR RA RV RG RM RL RD RDX RDXs RDXsB
  mc_xor       //    RA RV RG RM RL RD RDX RDXs RDXsB
               // RR AR VR GR MR LR DR DXR DXsR DXsBR
               // RK AK VK GK MK LK DK DXK DXsK DXsBK
}


GLOBAL {
  mc:800       // The currently selected mc control block

  mcInit       // mcb := mcInit(maxfno, csize, dsize)

  mcSelect     // Select and instance of the MC package

  mcCall       // Call an assembled function

  mcClose      // Close the current MC instant
  mcPRF        // Print a formatted message

  mcNextlab    // Returns next available label
  mcComment    // Write a comment, if mcDebug>=1

  mcDatap      // Returns the value of datap
  mcCodep      // Returns the value of codep

// Generator functions for the abstract machine
// directives and instructions.

  mcF     // cdq end endfn nop rtn

  mcK     // alignc alignd datab datak debug push
  mcR     // div jmp mul neg not pop push udiv umul
          // seq sne slt sle sgt sge uslt usle usgt usge
  mcA     // div jmp mul neg not pop push udiv umul
          // seq sne slt sle sgt sge uslt usle usgt usge
  mcV     // div jmp mul neg not pop push udiv umul
          // seq sne slt sle sgt sge uslt usle usgt usge
  mcG     // div jmp mul neg not pop push udiv umul
          // seq sne slt sle sgt sge uslt usle usgt usge
  mcM     // div jmp mul neg not pop push udiv umul
          // seq sne slt sle sgt sge uslt usle usgt usge
  mcL     // datal dlab lab
          // div jmp mul neg not pop push udiv umul
          // seq sne slt sle sgt sge uslt usle usgt usge
  mcD     // div jmp mul neg not pop push udiv umul
          // seq sne slt sle sgt sge uslt usle usgt usge
  mcDX   // div jmp mul neg not pop push udiv umul
          // seq sne slt sle sgt sge uslt usle usgt usge
  mcDXs   // div jmp mul neg not pop push udiv umul
          // seq sne slt sle sgt sge uslt usle usgt usge
  mcDXsB  // div jmp mul neg not pop push udiv umul
          // seq sne slt sle sgt sge uslt usle usgt usge

  mcJS    // Jump with 8-bit relative address as default
          // jmp jeq jne jlt jle jgt jge ujlt ujle ujgt ujge
  mcJL    // Jump with 32-bit relative address as default
          // jmp jeq jne jlt jle jgt jge ujlt ujle ujgt ujge
  mcJR    // Jump with target in a register
          // jmp jeq jne jlt jle jgt jge ujlt ujle ujgt ujge

  mcRA    // add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
  mcRV    // add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
  mcRG    // add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
  mcRM    // add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
  mcRL    // add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
  mcRD    // add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
  mcRDX   // add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
  mcRDXs  // add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
  mcRDXsB // add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor

  mcRR    // add and cmp lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
  mcAR    // add and cmp lsh mv rsh or sub xor
  mcVR    // add and cmp lsh mv rsh or sub xor
  mcGR    // add and cmp lsh mv rsh or sub xor
  mcMR    // add and cmp lsh mv rsh or sub xor
  mcLR    // add and cmp lsh mv rsh or sub xor
  mcDR    // add and cmp lsh mv rsh or sub xor
  mcDXR   // add and cmp lsh mv rsh or sub xor
  mcDXsR  // add and cmp lsh mv rsh or sub xor
  mcDXsBR // add and cmp lsh mv rsh or sub xor

  mcRK    // add and cmp lsh mv rsh or sub xor
  mcAK    // add and cmp lsh mv rsh or sub xor
  mcVK    // add and cmp lsh mv rsh or sub xor
  mcGK    // add and cmp lsh mv rsh or sub xor
  mcMK    // add and cmp lsh mv rsh or sub xor
  mcLK    // add and cmp lsh mv rsh or sub xor
  mcDK    // add and cmp lsh mv rsh or sub xor
  mcDXK   // add and cmp lsh mv rsh or sub xor
  mcDXsK  // add and cmp lsh mv rsh or sub xor
  mcDXsBK // add and cmp lsh mv rsh or sub xor

  mcKK    // call   -- fno and number of args pushed
  mcKKK   // entry  -- fno, number of args, number of locals
}
