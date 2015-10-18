GET "libhdr"

MANIFEST {                          // Parse Tree operators

s_number=1; s_name; s_string; s_true; s_false
s_valof; s_lv; s_rv; s_vecap; s_fnap
s_mult; s_div; s_rem
s_plus; s_minus; s_query; s_neg; s_abs
s_eq; s_ne; s_ls; s_gr; s_le; s_ge
s_byteap; s_mthap
s_not; s_lshift; s_rshift; s_logand; s_logor
s_eqv; s_neqv; s_cond; s_comma; s_table
s_and; s_valdef; s_vecdef; s_constdef
s_fndef; s_rtdef; s_needs; s_section
s_ass; s_rtap; s_goto; s_resultis; s_colon
s_test; s_for; s_if; s_unless
s_while; s_until; s_repeat; s_repeatwhile
s_repeatuntil
s_loop; s_break; s_return; s_finish
s_endcase; s_switchon; s_case; s_default
s_seq; s_let; s_manifest; s_global
s_local; s_label; s_static
 
// Lexical tokens (not in the parse tree)
s_be; s_end; s_lsect; s_rsect; s_get
s_semicolon; s_into
s_to; s_by; s_do; s_else
s_vec; s_lparen; s_rparen

// FLOW Operators
s_llv; s_st; s_ld
s_stind
s_jump; s_jt; s_jf
s_lab; s_entry
s_fnrn; s_rtrn
s_endproc; s_getbyte; s_putbyte
s_globinit; s_arg

s_sys; s_chgco; s_mdiv // Instructions used in SYSLIB

//  Selectors
h1=0; h2; h3; h4; h5; h6; h7
}
 
GLOBAL { // Shared globals
nametable:200; nametablesize
fin_p; fin_l; treep; treevec
errcount; errmax; sourcestream
sysprint; flowout
eqcases; prtree
translate

bigender; naming; debug; bining
}


