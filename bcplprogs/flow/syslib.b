SECTION "SYSLIB"

GLOBAL { sys:3; changeco:6; muldiv:19 }

LET sys(n, a, b, c, d) = 0   // SYS Vr Va Vb Vc Vd; FNRN Vr

LET changeco(val, cptr) = 0  // CHGCO Vval Vcptr; FNRN Vval

LET muldiv(a, b, c) = 0      // MDIV Vr Va Vb Vc; FNRN Vr