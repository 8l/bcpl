%PAGESIZE 115
 P386
 .MODEL FLAT
code32 SEGMENT PARA USE32 PUBLIC 'CODE'
 PUBLIC _cintasm
 EXTRN _dosys:PROC
; Using optlink linkage (used in OS/2 implementation)
; ebx, edi and esi must be preserved
; eax, edx and ecx hold the first three conforming arguments
; space for the arguments already allocated
; result in eax
; flag DF clear on entry and exit (ie not touched)

; BC4 default calling sequence
;  On entry to _cintasm
;  esp    -> return address
;  esp+4  -> integer subscript of register (first arg)
;  esp+8  -> pointer to base of Cintcode memory (second arg)
;    must preserve EBP, ESP, ESI, EDI
;         EAX EBX ECX EDX may be corrupted
;
;  On return
;   result must be in eax
;   restore ESI EDI
;   restore EBP ESP
;   return not popping the arguments

; The following macro is to allow for experiments
; on the effectivenes of the 486 cache
; It is called at the start of each opcode action routine.

opstart MACRO
 REPT 0
 test eax,0
 ENDM
ENDM

sfetchz MACRO
 jmp fetchz
ENDM

sfetch MACRO
 jmp fetch
ENDM

rfetch MACRO
 mov al,[esi]
 inc esi
 jmp DWORD PTR [runtbl+4*eax]
ENDM

rfetchz MACRO
 movzx eax,BYTE PTR[esi]
 inc esi
 jmp DWORD PTR [runtbl+4*eax]
ENDM

_cintasm PROC
 mov edx,[esp+8]  ; get second argument (mem)  --BC4
 mov eax,[esp+4]  ; get first argument (regs)  --BC4
 push ebp
 push ebx
 push edi
 push esi
 sub esp,40
 mov edi,edx
 mov [esp+64],edi   ; save mem
 mov [esp+60],eax   ; save regs

; code to set the registers

 lea eax,[edx+4*eax] ; get m/c addr of regs
 mov [esp+32],eax    ; save m/c addr of regs vector
 mov ebx,[eax+8]
 mov [esp+28],ebx    ; Cintcode C register
 mov ebp,[eax+12]
 add ebp,edi         ; m/c addr of P0
 mov ebx,[eax+16]
 lea edx,[ebx+edi]
 mov [esp+36],edx    ; save m/c address of G0
 shr ebx,2
 mov [esp+16],ebx    ; save BCPL address of G0
 mov ebx,[eax+20]
 mov [esp+24],ebx    ; cintcode ST
 mov esi,[eax+24]
 add esi,edi         ; PC as m/c address
 mov ebx,[eax+28]
 mov [esp+20],ebx    ; Cintcode Count register(<0)
 mov ebx,[eax]       ; A
 mov ecx,[eax+4]     ; B
 sfetchz


; Register usage at the moment of fetching the next
; Cintcode instruction.

; eax  zero, except for least sig byte (al)
; ebx  Cintcode A
; ecx  Cintcode B
; edx  m/c address of G0
; ebp  m/c address of P0
; edi  m/c addr of cintcode memory
; esi  Cintcode pc as m/c address
; esp  points to cintasm local work space
;    [esp+64]   mem  -- m/c addr of cintcode memory
;    [esp+60]   regs -- bcpl pointer regs vector
;    [esp+56]   return address
;    [esp+52]   caller's ebp
;    [esp+48]   caller's ebx
;    [esp+44]   caller's edi
;    [esp+40]   caller's esi
;    [esp+36]   m/c addr of G0
;    [esp+32]   m/c addr of regs vector
;    [esp+28]   cintcode C reg
;    [esp+24]   cintcode ST
;    [esp+20]   cintcode Count (known to be <0 for cintasm)
;    [esp+16]   BCPL pointer to G0
;    ...      ) space for args
;    [esp+ 0] ) of external calls


; The flag DF is clear, i.e. lodsb etc increment esi

; Begin executing the Cintcode instructions

indjump:
 mov al,[esi]
 lea eax,[esi+2*eax]        ; eax := pc + 2*B[pc]
 and al,254                 ; eax &= #xFFFFFFFE
 movsx esi,WORD PTR[eax]
 add esi,eax                ; esi := eax + SH[eax]

fetchz:
 rfetchz

nojump:
 inc esi                  ; pc++
fetch:
 rfetch

ret1:
; now put registers back into regs
 mov [esp],eax  ; save return code temporarily
 mov eax,[esp+32] ; get m/c addr of regs vector
 mov [eax+0],ebx  ; A
 mov [eax+4],ecx  ; B
 mov ebx,[esp+28]
 mov [eax+8],ebx  ; C
 sub ebp,edi
 mov [eax+12],ebp ; P
                  ; G cannot have changed
                  ; ST cannot have changed
 sub esi,edi
 mov [eax+24],esi ; PC
                  ; Count cannot have changed
 mov eax,[esp]    ; recover result

; and then return
 add esp,40
 pop esi
 pop edi
 pop ebx
 pop ebp
 ret

negpc:
 mov eax,4
 jmp ret1

; frq=nnn  give the frequency of execution of each
;          cintcode operation when the bcpl compiler
;          compiles itself

rl0:   ; Error     frq=0
rl1:   ; Error     frq=0
 opstart
 dec esi
 mov al,1
 jmp ret1

rl2:   ; brk     frq=0
 opstart
 dec esi
 mov al,2
 jmp ret1

rl3:   ; k3     frq=3002
rl4:   ; k4     frq=7738
rl5:   ; k5     frq=4520
rl6:   ; k6     frq=1
rl7:   ; k7     frq=480
rl8:   ; k8     frq=10
rl9:   ; k9     frq=0
rl10:  ; k10    frq=0
rl11:  ; k11    frq=28
 opstart
 lea eax,[ebp+4*eax]
 sub ebp,edi
 mov [eax],ebp        ; p[k] := p
 mov ebp,eax          ; p := p+k
 sub esi,edi
 mov [ebp+4],esi      ; p[1] := pc
 mov [ebp+8],ebx      ; p[2] := a  (the new pc)
 lea esi,[edi+ebx]    ; pc := a (new pc as m/c address)
 mov ebx,ecx          ; a := b
 mov [ebp+12],ebx     ; p[3] := a
 or esi,esi
 js negpc
 rfetchz

rl12:  ; lf      frq=11729
 opstart
 mov ecx,ebx             ; b := a
 movsx ebx,BYTE PTR[esi] ; a := pc + SB[pc]
 add ebx,esi
 sub ebx,edi
 inc esi                 ; pc++
 rfetch

rl13:  ; lf$     frq=4338
 opstart
 mov ecx,ebx             ; b := a
 mov ebx,esi
 and bl,254              ; a := pc & #xFFFFFFFE
 lodsb
 lea ebx,[ebx+2*eax]     ; a := a + 2*B[pc++]
 movsx eax,WORD PTR[ebx]
 add ebx,eax             ; a := a + SH[a]
 sub ebx,edi
 rfetchz

rl14:  ; lm      frq=598248
 opstart
 mov ecx,ebx               ; b := a
 movzx ebx,BYTE PTR[esi]   ; a := - B[pc++]
 inc esi
 neg ebx
 rfetch

rl15:  ; lm1     frq=163150
rl16:  ; l0      frq=244421
rl17:  ; l1      frq=740929
rl18:  ; l2      frq=38430
rl19:  ; l3      frq=49815
rl20:  ; l4      frq=83246
rl21:  ; l5      frq=1224
rl22:  ; l6      frq=54857
rl23:  ; l7      frq=8683
rl24:  ; l8      frq=13745
rl25:  ; l9      frq=96877
rl26:  ; l10     frq=253528
 opstart
 mov ecx,ebx
 lea ebx,[eax-16]
 rfetch

rl27:  ; fhop     frq=2295
 opstart
 xor ebx,ebx       ; a := 0
 inc esi
 rfetch

rl28:  ; jeq     frq=758839
 opstart
 cmp ecx,ebx
 jz SHORT jeq1
 inc esi
 rfetch
jeq1:
 movsx eax,BYTE PTR[esi]
 add esi,eax
 rfetchz

rl29:  ; jeq$     frq=0
 opstart
 cmp ecx,ebx
 jne nojump
 jmp indjump

rl30:  ; jeq0     frq=253477
 opstart
 or ebx,ebx
 jz SHORT jeq1
 inc esi
 rfetch

rl31:  ; jeq0$     frq=2926
 opstart
 or ebx,ebx
 jne nojump
 jmp indjump

rl32:  ; k     frq=35172
 opstart
 lodsb
callk:
 lea eax,[ebp+4*eax]
 sub ebp,edi
 mov [eax],ebp        ; p[k] := p
 mov ebp,eax          ; p := p+k
 sub esi,edi
 mov [ebp+4],esi      ; p[1] := pc
 mov esi,ebx          ; pc := a
 mov [ebp+8],esi      ; p[2] := pc
 mov ebx,ecx          ; a := b
 mov [ebp+12],ebx     ; p[3] := a
 add esi,edi          ; make pc a m/c address
 js  negpc
 rfetchz

rl33:  ; kh     frq=0
 opstart
 lodsw
 jmp callk

rl34:  ; kw     frq=0
 opstart
 lodsd
 jmp callk

rl35:  ; k3g      frq=204783
rl36:  ; k4g      frq=135269
rl37:  ; k5g      frq=263407
rl38:  ; k6g      frq=13337
rl39:  ; k7g      frq=4992
rl40:  ; k8g      frq=4660
rl41:  ; k9g      frq=1689
rl42:  ; k10g     frq=310
rl43:  ; k11g     frq=9
 opstart
 lea eax,[ebp+4*eax-4*32]
 sub ebp,edi
 mov [eax],ebp           ; p[k] := p
 mov ebp,eax             ; p := p+k
 movzx eax,BYTE PTR[esi] ; n := B[pc]
 inc esi                 ; pc++
 sub esi,edi
 mov [ebp+4],esi         ; p[1] := pc
 mov esi,[edx+4*eax]     ; pc := g!n
 mov [ebp+8],esi         ; p[2] := pc
 mov [ebp+12],ebx        ; p[3] := a
 add esi,edi        ; make pc a m/c address
 js negpc
 rfetchz

rl44:  ; s0g     frq=401845
 opstart
 mov al,BYTE PTR[esi] ; n := B[pc]
 inc esi              ; pc++
 mov eax,[edx+4*eax]
 mov [edi+4*eax],ebx  ; g!n!0 := a
 rfetchz

rl45:  ; l0g     frq=411817
 opstart
 mov ecx,ebx
 mov al,BYTE PTR[esi] ; n := B[pc]
 inc esi              ; pc++
 mov ebx,[edx+4*eax]
 mov ebx,[edi+4*ebx]  ; a := g!n!0
 rfetchz

rl46:  ; l1g     frq=409459
 opstart
 mov ecx,ebx
 mov al,BYTE PTR[esi] ; n := B[pc]
 inc esi              ; pc++
 mov ebx,[edx+4*eax]
 mov ebx,[edi+4*ebx+4*1] ; a := g!n!1
 rfetchz

rl47:  ; l2g     frq=3
 opstart
 mov ecx,ebx
 lodsb
 mov ebx,[edx+4*eax]
 mov ebx,[edi+4*ebx+4*2] ; a := g!n!2
 sfetch

rl48:  ; lg     frq=1365544
 opstart
 mov ecx,ebx          ; b := a
 mov al,[esi]         ; n := B[pc]
 inc esi              ; pc++
 mov ebx,[edx+4*eax]  ; a := g!n
 rfetch

rl49:  ; sg     frq=324122
 opstart
 mov al,[esi]         ; n := B[pc]
 inc esi              ; pc++
 mov [edx+4*eax],ebx  ; g!n := a
 rfetch

rl50:  ; llg     frq=0
 opstart
 mov ecx,ebx
 lodsb
 mov ebx,[esp+16]
 add ebx,eax
 sfetch

rl51:  ; ag     frq=7
 opstart
 lodsb
 add ebx,[edx+4*eax]
 sfetch

rl52:  ; mul     frq=132122
 opstart
 mov eax,ecx
 imul ebx
 mov ebx,eax
 mov edx,[esp+36] ; retore m/c addr of G0
 rfetchz

rl53:  ; div     frq=74675
 opstart
 cmp ebx,0
 je SHORT diverr
 mov eax,ecx
 cdq
 idiv ebx
 mov ebx,eax
 mov edx,[esp+36] ; retore m/c addr of G0
 rfetchz

diverr:
 dec esi
 mov eax,5
 jmp ret1

rl54:  ; rem     frq=92754
 opstart
 cmp ebx,0
 je SHORT diverr
 mov eax,ecx
 cdq
 idiv ebx
 mov ebx,edx
 mov edx,[esp+36] ; retore m/c addr of G0
 rfetchz

rl55:  ; xor     frq=56780
 opstart
 xor ebx,ecx
 rfetch

rl56:  ; sl     frq=0
 opstart
 movsx eax,BYTE PTR[esi]
 mov [esi+eax],ebx
 inc esi
 sfetchz

rl57:  ; sl$     frq=0
 opstart
 lodsb
 lea eax,[esi+2*eax-1]   ; eax := pc + 2*B[pc]; pc++
 and al,254              ; eax &= #xFFFFFFFE
 movsx edx,WORD PTR[eax]
 mov [eax+edx],ebx       ; W[eax+SH[eax]] := a
 mov edx,[esp+36]
 sfetchz

rl58:  ; ll     frq=0
 opstart
 mov ecx,ebx             ; b := a
 movsx ebx,BYTE PTR[esi]
 mov ebx,[esi+ebx]       ; a := pc + SB[pc]
 inc esi                 ; pc++
 sfetch

rl59:  ; ll$     frq=0
 opstart
 mov ecx,ebx             ; b := a
 lodsb
 lea eax,[esi+2*eax-1]   ; eax := pc + 2*B[pc]; pc++
 and al,254              ; eax &= #xFFFFFFFE
 movsx ebx,WORD PTR[eax]
 mov ebx,[eax+ebx]       ; a := W[eax+SH[eax]]
 sfetchz

rl60:  ; jne     frq=412167
 opstart
 cmp ecx,ebx
 jne SHORT jne1
 inc esi
 rfetch
jne1:
 movsx eax,BYTE PTR[esi]
 add esi,eax
 rfetchz

rl61:  ; jne$     frq=17329
 opstart
 cmp ecx,ebx
 jz nojump
 jmp indjump

rl62:  ; jne0     frq=673057
 opstart
 or ebx,ebx
 jne SHORT jne1
 inc esi
 rfetch

rl63:  ; jne0$     frq=8593
 opstart
 or ebx,ebx
 jz nojump
 jmp indjump

rl64:  ; llp     frq=10685
 opstart
 mov ecx,ebx     ; b := a
 mov ebx,ebp     ; a := p + B[pc++]
 sub ebx,edi
 shr ebx,2
 lodsb
 add ebx,eax
 rfetch

rl65:  ; llph     frq=0
 opstart
 mov ecx,ebx     ; b := a
 mov ebx,ebp     ; a := p + H[pc]; pc += 2
 sub ebx,edi
 shr ebx,2
 lodsw
 add ebx,eax
 sfetchz

rl66:  ; llpw     frq=0
 opstart
 mov ecx,ebx     ; b := a
 mov ebx,ebp     ; a := p + W[pc]; pc += 4
 sub ebx,edi
 shr ebx,2
 lodsd
 add ebx,eax
 sfetchz

rl67:  ; k3g1     frq=62815
rl68:  ; k4g1     frq=312332
rl69:  ; k5g1     frq=93172
rl70:  ; k6g1     frq=33086
rl71:  ; k7g1     frq=56780
rl72:  ; k8g1     frq=15758
rl73:  ; k9g1     frq=25517
rl74:  ; k10g1     frq=2673
rl75:  ; k11g1     frq=3440
 opstart
 lea eax,[ebp+4*eax-4*64]
 sub ebp,edi
 mov [eax],ebp        ; p[k] := p
 mov ebp,eax          ; p := p+k
 movzx eax,BYTE PTR[esi] ; n := B[pc]
 inc esi              ; pc++
 sub esi,edi
 mov [ebp+4],esi      ; p[1] := pc
 mov esi,[edx+4*eax+4*256]  ; pc := g!(n+256)
 mov [ebp+8],esi      ; p[2] := pc
 mov [ebp+12],ebx     ; p[3] := a
 add esi,edi     ; make pc a m/c address
 js negpc
 rfetchz

rl76:  ; s0g1     frq=1639
 opstart
 lodsb
 mov eax,[edx+4*eax+4*256]
 mov [edi+4*eax],ebx        ; !(g!(n+256)) := a
 sfetchz

rl77:  ; l0g1     frq=724
 opstart
 mov ecx,ebx             ; b := a
 lodsb
 mov ebx,[edx+4*eax+4*256]
 mov ebx,[edi+4*ebx]     ; a := 0!(g!(n+256))
 sfetch

rl78:  ; l1g1     frq=724
 opstart
 mov ecx,ebx             ; b := a
 lodsb
 mov ebx,[edx+4*eax+4*256]
 mov ebx,[edi+4*ebx+4*1] ; a := 1!(g!(n+256))
 sfetch

rl79:  ; l2g1     frq=724
 opstart
 mov ecx,ebx             ; b := a
 lodsb
 mov ebx,[edx+4*eax+4*256]
 mov ebx,[edi+4*ebx+4*2] ; a := 2!(g!(n+256))
 sfetch

rl80:  ; lg1     frq=249497
 opstart
 mov ecx,ebx               ; b := a
 mov al,[esi]              ; n := B[pc++]
 inc esi
 mov ebx,[edx+4*eax+4*256] ; a := g!(n+256)
 rfetch

rl81:  ; sg1     frq=155081
 opstart
 mov al,[esi]                ; n := B[pc++]
 inc esi
 mov [edx+4*eax+4*256],ebx   ; g!(n+256) := b
 rfetch

rl82:  ; llg1     frq=0
 opstart
 mov ecx,ebx               ; b := a
 mov al,[esi]              ; n := B[pc++]
 inc esi
 lea ebx,[eax+256]
 add ebx,[esp+16]          ; a := @ g!(n+256)
 sfetch

rl83:  ; ag1     frq=1290
 opstart
 mov al,[esi]                ; n := B[pc++]
 inc esi
 add ebx,[edx+4*eax+4*256]   ; a += g!(n+256)
 sfetch

rl84:  ; add     frq=51328
 opstart
 add ebx,ecx
 rfetch

rl85:  ; sub     frq=51606
 opstart
 sub ebx,ecx
 neg ebx
 rfetch

rl86:  ; lsh     frq=23772
 opstart
 cmp ebx,01fh
 setg al
 dec eax
 and eax,ecx
 xchg ebx,eax
 xchg ecx,eax
 sal ebx,cl   ; a := b<<a
 mov ecx,eax
 rfetchz

rl87:  ; rsh     frq=65180
 opstart
 cmp ebx,01fh
 setg al
 dec eax
 and eax,ecx
 xchg ebx,eax
 xchg ecx,eax
 shr ebx,cl   ; a := b>>a
 mov ecx,eax
 rfetchz

rl88:  ; and     frq=192985
 opstart
 and ebx,ecx
 rfetch

rl89:  ; or     frq=24123
 opstart
 or ebx,ecx
 rfetch

rl90:  ; lll     frq=57746
 opstart
 mov ecx,ebx
 movsx ebx,BYTE PTR[esi]
 add ebx,esi
 sub ebx,edi
 shr ebx,2
 inc esi
 rfetch

rl91:  ; lll$     frq=189
 opstart
 mov ecx,ebx             ; b := a
 lodsb
 lea eax,[esi+2*eax-1]   ; eax := pc + 2*B[pc]; pc++
 and al,254              ; eax &= #xFFFFFFFE
 movsx ebx,WORD PTR[eax]
 add ebx,eax             ; a := eax+SH[eax]
 sub ebx,edi
 shr ebx,2               ; a >>= 2
 sfetchz

rl92:  ; jls     frq=293452
 opstart
 cmp ecx,ebx
 jl jls1
 inc esi
 rfetch
jls1:
 movsx eax,BYTE PTR[esi]
 add esi,eax
 rfetchz

rl93:  ; jls$     frq=6421
 opstart
 cmp ecx,ebx
 jge nojump
 jmp indjump

rl94:  ; jls0     frq=3102
 opstart
 or ebx,ebx
 jl jls1
 inc esi
 rfetch

rl95:  ; jls0$     frq=0
 opstart
 or ebx,ebx
 jge nojump
 jmp indjump

rl96:  ; l     frq=1098722
 opstart
 mov ecx,ebx             ; b := a
 movzx ebx,BYTE PTR[esi] ; a := B[pc++]
 inc esi
 rfetch

rl97:  ; lh     frq=84529
 opstart
 mov ecx,ebx    ; b := a
 movzx ebx,WORD PTR[esi]
 add esi,2      ; a := H[pc]; pc += 2
 rfetch

rl98:  ; lw     frq=0
 opstart
 mov ecx,ebx    ; b := a
 lodsd
 mov ebx,eax    ; a := W[pc]; pc += 4
 sfetchz

rl99:  ; k3gh     frq=320
rl100: ; k4gh     frq=4633
rl101: ; k5gh     frq=6808
rl102: ; k6gh     frq=8806
rl103: ; k7gh     frq=9358
rl104: ; k8gh     frq=17
rl105: ; k9gh     frq=0
rl106: ; k10gh     frq=169
rl107: ; k11gh     frq=0
 opstart
 lea eax,[ebp+4*eax-4*96]
 sub ebp,edi
 mov [eax],ebp        ; p[k] := p
 mov ebp,eax          ; p := p+k
 movzx eax,WORD PTR[esi] ; n := H[pc]
 add esi,2            ; pc += 2
 sub esi,edi
 mov [ebp+4],esi      ; p[1] := pc
 mov esi,[edx+4*eax]  ; pc := g!n
 mov [ebp+8],esi      ; p[2] := pc
 mov [ebp+12],ebx     ; p[3] := a
 add esi,edi     ; make pc a m/c address
 js negpc
 rfetchz

rl108: ; s0gh     frq=15601
 opstart
 lodsw
 mov eax,[edx+4*eax]
 mov [edi+4*eax],ebx        ; 0!(g!(H[pc])) := a; pc += 2
 rfetchz

rl109: ; l0gh     frq=9924
 opstart
 mov ecx,ebx           ; b := a
 lodsw
 mov eax,[edx+4*eax]
 mov ebx,[edi+4*eax]         ; a := 0!(g!(H[pc])); pc += 2
 sfetchz

rl110: ; l1gh     frq=5952
 opstart
 mov ecx,ebx           ; b := a
 lodsw
 mov eax,[edx+4*eax]
 mov ebx,[edi+4*eax+4*1]     ; a := 1!(g!(H[pc])); pc += 2
 sfetchz

rl111: ; l2gh     frq=0
 opstart
 mov ecx,ebx           ; b := a
 lodsw
 mov eax,[edx+4*eax]
 mov ebx,[edi+4*eax+4*2]     ; a := 2!(g!(H[pc])); pc += 2
 sfetchz

rl112: ; lgh     frq=700955
 opstart
 mov ecx,ebx            ; b := a
 movzx ebx,WORD PTR[esi]
 add esi,2
 mov ebx,[edx+4*ebx]    ; a := g!(H[pc]); pc += 2
 rfetch

rl113: ; sgh     frq=297790
 opstart
 mov ax,[esi]
 add esi,2
 mov [edx+4*eax],ebx    ; g!(H[pc]) := a; pc += 2
 rfetchz

rl114: ; llgh     frq=14161
 opstart
 mov ecx,ebx            ; b := a
 lodsw
 add eax,[esp+16]
 mov ebx,eax            ; a := @ g!(H[pc]); pc += 2
 rfetchz

rl115: ; agh     frq=90488
 opstart
 mov ax,[esi]
 add esi,2
 add ebx,[edx+4*eax]    ; a += g!(H[pc]); pc += 2
 rfetchz

rl116: ; rv      frq=81916
rl117: ; rv1     frq=18677
rl118: ; rv2     frq=24044
rl119: ; rv3     frq=942
rl120: ; rv4     frq=0
rl121: ; rv5     frq=303
rl122: ; rv6     frq=392
 opstart
 lea eax,[ebx+eax-116]
 mov ebx,[edi+4*eax]      ; a := a!k
 rfetchz

rl123: ; rtn     frq=1315089
 opstart
 mov esi,[ebp+4]
 add esi,edi   ; make esi a m/c address
 mov ebp,[ebp]
 add ebp,edi   ; make ebp a m/c address
 rfetch

rl124: ; jgr     frq=234567
 opstart
 cmp ecx,ebx
 jg SHORT jgr1
 inc esi
 rfetch
jgr1:
 movsx eax,BYTE PTR[esi]
 add esi,eax
 rfetchz

rl125: ; jgr$     frq=0
 opstart
 cmp ecx,ebx
 jle nojump
 jmp indjump

rl126: ; jgr0     frq=1664
 opstart
 or ebx,ebx
 jg jgr1
 inc esi
 rfetch

rl127: ; jgr0$     frq=0
 opstart
 or ebx,ebx
 jle nojump
 jmp indjump

rl128: ; lp     frq=32473
 opstart
 mov ecx,ebx          ; b := a
 mov al,[esi]
 inc esi
 mov ebx,[ebp+4*eax]  ; a := p!(B[pc++])
 rfetch

rl129: ; lph     frq=0
 opstart
 mov ecx,ebx          ; b := a
 lodsw
 mov ebx,[ebp+4*eax]  ; a := p!(H[pc]); pc += 2
 sfetchz

rl130: ; lpw     frq=0
 opstart
 mov ecx,ebx          ; b := a
 lodsd
 mov ebx,[ebp+4*eax]  ; a := p!(W[pc]); pc += 4
 sfetchz

rl131: ; lp3     frq=1681284
 opstart
 mov ecx,ebx
 mov ebx,[ebp+4*3]
 rfetch

rl132: ; lp4     frq=593132
 opstart
 mov ecx,ebx
 mov ebx,[ebp+4*4]
 rfetch

rl133: ; lp5     frq=355769
 opstart
 mov ecx,ebx
 mov ebx,[ebp+4*5]
 rfetch

rl134: ; lp6     frq=200287
rl135: ; lp7     frq=228093
rl136: ; lp8     frq=126649
rl137: ; lp9     frq=24237
rl138: ; lp10     frq=11740
rl139: ; lp11     frq=8112
rl140: ; lp12     frq=1283
rl141: ; lp13     frq=121
rl142: ; lp14     frq=214
rl143: ; lp15     frq=13779
rl144: ; lp16     frq=45432
 opstart
 mov ecx,ebx
 mov ebx,[ebp+4*eax-4*128]
 rfetch

rl145: ; sys     frq=554
 opstart
 mov eax,[ebp+16]
 cmp ebx,0         ; IF a==0 DO
 je ret1           ;   { res := p!4; GOTO ret }
 mov edx,[esp+16]  ; g as a BCPL pointer
 mov eax,ebp
 sub eax,edi
 shr eax,2         ; p as a BCPL pointer
 push edx          ;  -- BC4
 push eax          ;  -- BC4
 call _dosys
 add esp,8         ;  -- BC4
 mov ebx,eax       ; a := dosys(p, g)
 mov edx,[esp+36]
 sfetchz

rl146: ; swb     frq=48805
 opstart
 inc esi
 and esi,0FFFFFFFEh       ; round pc up to even address
 mov al,1                 ; i := 1

; There are at least 7 cases so unwind the first 3 iterations.

 cmp bx,[esi+4*eax]       ;   compare with case constant
 je SHORT swb3            ;   J if case found
 adc eax,eax              ;   if H[i]>=val then i := 2*i
								  ;                else i := 2*i+1
 cmp bx,[esi+4*eax]       ;   compare with case constant
 je SHORT swb3            ;   J if case found
 adc eax,eax              ;   if H[i]>=val then i := 2*i
								  ;                else i := 2*i+1
swb1:
 cmp bx,[esi+4*eax]       ; { compare with case constant
 je SHORT swb3            ;   J if case found
 adc eax,eax              ;   if H[i]>=val then i := 2*i
								  ;                else i := 2*i+1
 cmp ax,WORD PTR [esi]    ;
 jle swb1                 ; } REPEATWHILE i<=n

swb2:                     ; Set pc to default label
 lea esi,[esi+2]
 movsx eax,WORD PTR[esi]
 add esi,eax              ; set pc
 rfetchz

swb3:                     ; found (provided senior half zero)
 cmp ebx,0FFFFh
 ja  swb2                 ; J if senior half not zero
 lea esi,[esi+4*eax+2]
 movsx eax,WORD PTR[esi]
 add esi,eax              ; set pc to case label
 rfetchz

rl147: ; swl     frq=85714
 opstart
 inc esi
 and esi,0FFFFFFFEh    ; round pc up to even address
 mov ax,[esi]          ; eax := H[esi] (= number of cases)
 add esi,2             ; esi += 2
							  ; esi points to the default lab cell
 or ebx,ebx
 jl SHORT swl1         ; J if value too small
 cmp ebx,eax
 jge SHORT swl1        ; J if too large
 lea esi,[esi+2*ebx+2] ; get pointer to label cell
swl1:
 movsx eax,WORD PTR[esi]
 add esi,eax           ; set pc
 rfetchz

rl148: ; st     frq=53452
 opstart
 mov [edi+4*ebx],ecx ; a!0 := b
 rfetch

rl149: ; st1     frq=36925
 opstart
 mov [edi+4*ebx+4*1],ecx ; a!1 := b
 rfetch

rl150: ; st2     frq=32011
 opstart
 mov [edi+4*ebx+4*2],ecx ; a!2 := b
 rfetch

rl151: ; st3     frq=5530
 opstart
 mov [edi+4*ebx+4*3],ecx ; a!3 := b
 rfetch

rl152: ; stp3     frq=2182
rl153: ; stp4     frq=780
rl154: ; stp5     frq=20
 opstart
 mov eax,[ebp+4*eax-4*149]
 add eax,ebx
 mov [edi+4*eax],ecx ; p!n!a := b
 sfetchz

rl155: ; goto     frq=0
 opstart
 lea esi,[edi+ebx]
 sfetch

rl156: ; jle     frq=575294
 opstart
 cmp ecx,ebx
 jle SHORT jle1
 inc esi
 rfetch
jle1:
 movsx eax,BYTE PTR[esi]
 add esi,eax
 rfetchz

rl157: ; jle$     frq=12919
 opstart
 cmp ecx,ebx
 jg nojump
 jmp indjump

rl158: ; jle0     frq=13814
 opstart
 or ebx,ebx
 jle SHORT jle1
 inc esi
 rfetch

rl159: ; jle0$     frq=0
 opstart
 or ebx,ebx
 jg nojump
 jmp indjump

rl160: ; sp     frq=57497
 opstart
 mov al,[esi]
 inc esi
 mov [ebp+4*eax],ebx
 rfetch

rl161: ; sph     frq=0
 opstart
 lodsw
 mov [ebp+4*eax],ebx
 sfetchz

rl162: ; spw     frq=0
 opstart
 lodsw
 mov [ebp+4*eax],ebx
 sfetchz

rl163: ; sp3     frq=448052
 opstart
 mov [ebp+4*3],ebx
 rfetch

rl164: ; sp4     frq=988190
 opstart
 mov [ebp+4*4],ebx
 rfetch

rl165: ; sp5     frq=344005
 opstart
 mov [ebp+4*5],ebx
 rfetch

rl166: ; sp6     frq=163718
 opstart
 mov [ebp+4*6],ebx
 rfetch

rl167: ; sp7     frq=233850
 opstart
 mov [ebp+4*7],ebx
 rfetch

rl168: ; sp8     frq=109584
 opstart
 mov [ebp+4*8],ebx
 rfetch

rl169: ; sp9     frq=110121
 opstart
 mov [ebp+4*9],ebx
 rfetch

rl170: ; sp10     frq=56154
rl171: ; sp11     frq=50794
rl172: ; sp12     frq=20524
rl173: ; sp13     frq=15806
rl174: ; sp14     frq=4839
rl175: ; sp15     frq=16120
rl176: ; sp16     frq=33499
 opstart
 mov [ebp+4*eax-4*160],ebx
 rfetch

rl177: ; s1     frq=34291
 opstart
 dec ebx        ; A := A-1
 rfetch

rl178: ; s2     frq=4205
 opstart
 sub ebx,2      ; A := A-2
 rfetch

rl179: ; s3     frq=26048
 opstart
 sub ebx,3      ; A := A-3
 rfetch

rl180: ; s4     frq=3
 opstart
 sub ebx,4      ; A := A-4
 rfetch

rl181: ; xch     frq=1761584
 opstart
 xchg ebx,ecx
 rfetch

rl182: ; gbyt     frq=504790
 opstart
 add ebx,edi
 movzx ebx,BYTE PTR[ebx+4*ecx]         ; a := b%a
 rfetch

rl183: ; pbyt     frq=395227
 opstart
 add ebx,edi
 mov al,BYTE PTR[esp+28]
 mov [ebx+4*ecx],al                    ; b%a := c
 sub ebx,edi
 rfetch

rl184: ; atc     frq=395227
 opstart
 mov [esp+28],ebx              ; c := a
 rfetch

rl185: ; atb     frq=0
 opstart
 mov ecx,ebx                   ; b := a
 sfetch

rl186: ; j     frq=302744
 opstart
 movsx eax,BYTE PTR[esi]   ; pc += SB[pc]
 add esi,eax
 rfetchz

rl187: ; j$     frq=150058
 opstart
 mov al,[esi]
 lea eax,[esi+2*eax]        ; eax := pc + 2*B[pc]
 and al,254                 ; eax &= #xFFFFFFFE
 movsx esi,WORD PTR[eax]
 add esi,eax                ; esi := eax + SH[eax]
 rfetchz

rl188: ; jge     frq=301004
 opstart
 cmp ecx,ebx
 jge SHORT jge1
 inc esi
 rfetch
jge1:
 movsx eax,BYTE PTR[esi]
 add esi,eax
 rfetchz

rl189: ; jge$     frq=0
 opstart
 cmp ecx,ebx
 jl nojump
 jmp indjump

rl190: ; jge0     frq=47832
 opstart
 or ebx,ebx
 jge SHORT jge1
 inc esi
 rfetch

rl191: ; jge0$     frq=0
 opstart
 or ebx,ebx
 jl nojump
 jmp indjump

rl192: ; ap     frq=6416
 opstart
 lodsb
 add ebx,[ebp+4*eax]
 sfetch

rl193: ; aph     frq=0
 opstart
 lodsw
 add ebx,[ebp+4*eax]
 sfetchz

rl194: ; apw     frq=0
 opstart
 lodsd
 add ebx,[ebp+4*eax]
 sfetchz

rl195: ; ap3     frq=283379
 opstart
 add ebx,[ebp+4*3]
 rfetch

rl196: ; ap4     frq=832703
 opstart
 add ebx,[ebp+4*4]
 rfetch

rl197: ; ap5     frq=65255
rl198: ; ap6     frq=11097
rl199: ; ap7     frq=106439
rl200: ; ap8     frq=3583
rl201: ; ap9     frq=47609
rl202: ; ap10     frq=1439
rl203: ; ap11     frq=0
rl204: ; ap12     frq=21
 opstart
 add ebx,[ebp+4*eax-4*192]
 rfetch

rl205: ; xpbyt     frq=326298
 opstart
 add ecx,edi
 mov al,[esp+28]
 mov [ecx+4*ebx],al            ; a%b := c
 sub ecx,edi
 rfetch

rl206: ; lmh     frq=1269
 opstart
 mov ecx,ebx     ; b := a
 lodsw
 neg eax
 mov ebx,eax     ; a := -H[pc]; pc += 2
 sfetchz

rl207: ; btc     frq=184802
 opstart
 mov [esp+28],ecx ; c := b
 rfetch

rl208: ; nop     frq=0
 opstart
 sfetch

rl209: ; a1     frq=319289
 opstart
 inc ebx
 rfetch

rl210: ; a2     frq=69342
 opstart
 add ebx,2
 rfetch

rl211: ; a3     frq=44520
rl212: ; a4     frq=5224
rl213: ; a5     frq=0
 opstart
 lea ebx,[ebx+eax-208]
 rfetch

rl214: ; rvp3     frq=1108
rl215: ; rvp4     frq=1582
rl216: ; rvp5     frq=30
rl217: ; rvp6     frq=12697
rl218: ; rvp7     frq=1449
 opstart
 add ebx,[ebp+4*eax-4*211]
 mov ebx,[edi+4*ebx]      ; a := p!n!a
 rfetch

rl219: ; st0p3     frq=10619
rl220: ; st0p4     frq=7637
 opstart
 mov eax,[ebp+4*eax-4*216]
 mov [edi+4*eax],ebx       ; p!n!0 := a
 rfetchz

rl221: ; st1p3     frq=1455
rl222: ; st1p4     frq=0
 opstart
 mov eax,[ebp+4*eax-4*218]
 mov [edi+4*eax+4*1],ebx     ; p!n!1 := a
 sfetchz

rl223: ; Error     frq=0
 opstart
 dec esi
 mov al,1
 jmp ret1

rl224: ; a     frq=74587
 opstart
 mov al,[esi]
 inc esi
 add ebx,eax            ; a += B[pc++]
 rfetch

rl225: ; ah     frq=6
 opstart
 lodsw
 add ebx,eax            ; a += H[pc]; pc += 2
 sfetchz

rl226: ; aw        frq=0
 opstart
 lodsd
 add ebx,eax            ; a += W[pc]; pc += 4
 sfetchz

rl227: ; l0p3      frq=65102
rl228: ; l0p4      frq=612068
rl229: ; l0p5      frq=17186
rl230: ; l0p6      frq=8430
rl231: ; l0p7      frq=30505
rl232: ; l0p8      frq=14744
rl233: ; l0p9      frq=0
rl234: ; l0p10     frq=0
rl235: ; l0p11     frq=0
rl236: ; l0p12     frq=0
 opstart
 mov ecx,ebx               ; b := a
 mov ebx,[ebp+4*eax-4*224]
 mov ebx,[edi+4*ebx]       ; a := p!n!0
 rfetch

rl237: ; s      frq=130833
 opstart
 mov al,[esi]
 inc esi
 sub ebx,eax            ; a -= B[pc++]
 rfetch

rl238: ; sh     frq=0
 opstart
 mov ax,[esi]
 add esi,2
 sub ebx,eax            ; a -= H[pc]; pc += 2
 rfetchz

rl239: ; mdiv     frq=0
 opstart
 mov eax,ebx
 mov ebx,edx
 imul DWORD PTR [ebp+16] ; eax:edx := double length product
 idiv DWORD PTR [ebp+20] ; eax = quotient, edx = remainder
 xchg edx,ebx
 mov [edx+4*10],ebx      ; result2 := remainder
 mov ebx,eax             ; a := quotient
 mov esi,[ebp+4]
 add esi,edi             ; make esi a m/c address
 mov ebp,[ebp]
 add ebp,edi             ; make ebp a m/c address
 rfetchz

rl240: ; chgco     frq=2
 opstart
 mov esi,[ebp]
 mov eax,[edx+4*7]
 mov [edi+4*eax],esi     ; !currco := !p
 mov esi,[ebp+4]
 add esi,edi             ; pc := p!1
 mov eax,[ebp+16]
 mov [edx+4*7],eax       ; currco := cptr
 mov ebp,[edi+4*eax]
 add ebp,edi             ; p := !cptr
 sfetchz

rl241: ; neg     frq=297
 opstart
 neg ebx
 sfetch

rl242: ; not     frq=196
 opstart
 not ebx
 sfetch

rl243: ; l1p3     frq=35547
rl244: ; l1p4     frq=3525
rl245: ; l1p5     frq=20773
rl246: ; l1p6     frq=414
 opstart
 mov ecx,ebx               ; b := a
 mov ebx,[ebp+4*eax-4*240]
 mov ebx,[edi+4*ebx+4*1]   ; a := p!k!1
 rfetch

rl247: ; l2p3     frq=22841
rl248: ; l2p4     frq=5310
rl249: ; l2p5     frq=32256
 opstart
 mov ecx,ebx               ; b := a
 mov ebx,[ebp+4*eax-4*244]
 mov ebx,[edi+4*ebx+4*2]   ; a := p!k!2
 rfetch

rl250: ; l3p3     frq=4185
rl251: ; l3p4     frq=1
 opstart
 mov ecx,ebx               ; b := a
 mov ebx,[ebp+4*eax-4*247]
 mov ebx,[edi+4*ebx+4*3]   ; a := p!k!3
 sfetch

rl252: ; l4p3     frq=449
rl253: ; l4p4     frq=1
 opstart
 mov ecx,ebx               ; b := a
 mov ebx,[ebp+4*eax-4*249]
 mov ebx,[edi+4*ebx+4*4]   ; a := p!k!4
 sfetch

rl254: ; Error     frq=0
rl255: ; Error     frq=0
 opstart
 dec esi
 mov al,1
 jmp ret1

 ALIGN 16

runtbl:
 dd   rl0,   rl1,   rl2,   rl3,   rl4,   rl5,   rl6,   rl7
 dd   rl8,   rl9,  rl10,  rl11,  rl12,  rl13,  rl14,  rl15
 dd  rl16,  rl17,  rl18,  rl19,  rl20,  rl21,  rl22,  rl23
 dd  rl24,  rl25,  rl26,  rl27,  rl28,  rl29,  rl30,  rl31
 dd  rl32,  rl33,  rl34,  rl35,  rl36,  rl37,  rl38,  rl39
 dd  rl40,  rl41,  rl42,  rl43,  rl44,  rl45,  rl46,  rl47
 dd  rl48,  rl49,  rl50,  rl51,  rl52,  rl53,  rl54,  rl55
 dd  rl56,  rl57,  rl58,  rl59,  rl60,  rl61,  rl62,  rl63
 dd  rl64,  rl65,  rl66,  rl67,  rl68,  rl69,  rl70,  rl71
 dd  rl72,  rl73,  rl74,  rl75,  rl76,  rl77,  rl78,  rl79
 dd  rl80,  rl81,  rl82,  rl83,  rl84,  rl85,  rl86,  rl87
 dd  rl88,  rl89,  rl90,  rl91,  rl92,  rl93,  rl94,  rl95
 dd  rl96,  rl97,  rl98,  rl99, rl100, rl101, rl102, rl103
 dd rl104, rl105, rl106, rl107, rl108, rl109, rl110, rl111
 dd rl112, rl113, rl114, rl115, rl116, rl117, rl118, rl119
 dd rl120, rl121, rl122, rl123, rl124, rl125, rl126, rl127
 dd rl128, rl129, rl130, rl131, rl132, rl133, rl134, rl135
 dd rl136, rl137, rl138, rl139, rl140, rl141, rl142, rl143
 dd rl144, rl145, rl146, rl147, rl148, rl149, rl150, rl151
 dd rl152, rl153, rl154, rl155, rl156, rl157, rl158, rl159
 dd rl160, rl161, rl162, rl163, rl164, rl165, rl166, rl167
 dd rl168, rl169, rl170, rl171, rl172, rl173, rl174, rl175
 dd rl176, rl177, rl178, rl179, rl180, rl181, rl182, rl183
 dd rl184, rl185, rl186, rl187, rl188, rl189, rl190, rl191
 dd rl192, rl193, rl194, rl195, rl196, rl197, rl198, rl199
 dd rl200, rl201, rl202, rl203, rl204, rl205, rl206, rl207
 dd rl208, rl209, rl210, rl211, rl212, rl213, rl214, rl215
 dd rl216, rl217, rl218, rl219, rl220, rl221, rl222, rl223
 dd rl224, rl225, rl226, rl227, rl228, rl229, rl230, rl231
 dd rl232, rl233, rl234, rl235, rl236, rl237, rl238, rl239
 dd rl240, rl241, rl242, rl243, rl244, rl245, rl246, rl247
 dd rl248, rl249, rl250, rl251, rl252, rl253, rl254, rl255

_cintasm endp

code32 ENDS
 END

