 // "PALHDR"

MANIFEST {
  ug=200
  co_size=5
  rtn_membase=13
  rtn_memsize
}

GLOBAL {
start:               1
stop:                2
sys:                 3
muldiv:              5
currco:              7
rootnode:            9
result2:            10
level:              15
longjump:           16
rdch:               38
unrdch:             40
wrch:               41
findinput:          48
findoutput:         49
selectinput:        56
selectoutput:       57
input:              58
output:             59
sawritef:           95
rdargs:            102
datstring:         108
datstamp:          109
dat_to_strings:    110
}
 
MANIFEST {
 ug=200
 endstreamch = -1
 bytesperword = 4
 maxint = -1>>1
 signbit = ~maxint
 pagemask = #xFFFFFE00
 pagesize = #x200
 p_addr = #xFFFFFF
 p_tag = #xFF000000
 p_tagp = p_tag-signbit
 ////flten = 10e0                 /// Floating point manifests not allowed
 
 buffl = 128
 numba = 1_000_000_000
 numwi = 9
 
 h0 = 0    // selectors
 h1 = 1
 h2 = 2
 h3 = 3
 
 s_num = 0
 s_string = 1
 s_flt = 2
 s_fpl = 3
 s_numj = 4
 s_ratn = 5
 s_ratl = 6
 s_ratp = 7
 s_poly = 8
 s_polyj = 9
 
 s_loc = 10
 
 s_cdx = 11
 s_cdy = 12
 s_cdz = 13
 s_cd = 14
 
 s_bcplf = 15
 s_bcplr = 16
 s_bcplv = 17
 s_codev = 20
 s_code0 = 21
 s_code1 = 22
 s_code2 = 23
 s_code3 = 24
 s_code4 = 25
 
 s_rds = 26
 s_wrs = 27
 
 s_unset = 29
 s_unset1 = 30
 
 s_gensy = 31
 s_name = 32
 s_glz = 33
 s_glg = 34
 s_glo = 35
 s_qu = 36
 
 s_tuple = 38
 s_xtupl = 39
 
 s_tra = 40
 
 s_e = 41
 s_clos = 42
 s_aclos = 43
 s_clos2 = 44
 s_eclos = 45
 s_fclos = 46
 s_jclos = 47
 s_kclos = 48
 
 s_rec = 49
 s_reca = 50
 s_let = 51
 s_leta = 52
 s_letb = 53
 s_cond = 54
 s_conda = 55
 s_condb = 56
 
 s_seq = 57
 s_seqa = 58
 s_colon = 59
 s_retu = 60
 s_dash = 61
 s_aa = 62
 s_zz = 63
 
 s_apz = 64
 s_apply = 65
 s_apple = 66
 s_aa1 = 67
 s_a1a = 68
 s_ap1 = 69
 s_a1e = 70
 s_apv = 71
 s_ave = 72
 s_aa2 = 73
 s_a2a = 74
 s_ap2 = 75
 s_a2e = 76
 s_aaa = 77
 s_aea = 78
 s_apq = 79
 s_aqe = 80
 
 s_j = 81
 s_z = 82
 
 s_mcc = 83
 s_mcf = 84
 s_mck = 85
 
 s_mal = 86
 s_mar = 87
 s_ms = 88
 s_mt = 89
 s_maa = 90
 s_ma1 = 91
 s_mf1 = 92
 s_mf1a = 93
 s_ma2l = 94
 s_ma2r = 95
 s_mf2l = 96
 s_mf2r = 97
 s_maq = 98
 s_mlet = 99
 s_mcond = 100
 
 s_mz = 101
 s_mmcc = 102
 s_mmcf = 103
 s_mmck = 104
 
 s_mmal = 105
 s_mmar = 106
 s_mms = 107
 s_mmt = 108
 s_mmaa = 109
 s_mma1 = 110
 s_mmf1 = 111
 s_mmf1a = 112
 s_mma2l = 113
 s_mma2r = 114
 s_mmf2l = 115
 s_mmf2r = 116
 s_mmaq = 117
 s_mmlet = 118
 s_mmcond = 119
 
 s_mb = 120
 
 s_if = 121
 s_unless = 122
 s_while = 123
 s_until = 124
 s_repeat = 125
 s_for = 126
 s_do = 127
 s_then = 128
 s_or = 129
 s_else = 130
 s_diadop = 131
 s_relop = 132
 s_lpar = 133
 s_rpar = 134
 s_in = 135
 s_and = 136
 s_within = 137
 s_where = 138
 s_q2 = 139
 s_sh1 = 140
 s_infix = 141
 s_dot = 142
 s_fin = 143
 s_nil = 144
 s_null = 145
 s_pp = 146
 s_dlr = 147
 s_by = 148
 s_qr = 149
 
 str1 = bytesperword*2
 str2 = str1+7
 
 fr_callbcpl = 3
 fr_gc = 12
 fr_s = 64
 
 z = 0
 y0 = -(signbit>>1)
 y1 = y0+1
 y2 = y0+2
 y3 = y0+3
 ym = y0-1
 
 mm3 = s_ratl
 mtypsz = s_mz-1
 typsz = s_mb
 jgap = s_mz-s_z
 
 yloc = signbit>>1
 yfj = signbit>>1
 ysg = signbit>>2
 sva = signbit>>2
 }
 
 
GLOBAL{
 g0:0
 
 dummy:ug
 cinabort   /// Uses interface to call Cintsys abort

 ///start:1
 abort///:3
 backtrace///:4
 errormessage///:5
 savearea///:6
 unloadall///:7
 loadfort///:8
 unload///:9
 load///:10
 ///selectinput///:11
 ///selectoutput///:12
 ///rdch///:13
 ///wrch///:14
 ///unrdch///:15
 ///input///:16
 ///output///:17
 incontrol///:18
 outcontrol///:19
 triminput///:20
 setwindow///:21
 binaryinput///:22
 readrec///:23
 writerec///:24
 writeseg///:25
 skiprec///:26
 timeofday///:27
 time///:28
 date///:29
 ///stop///:30
 ///level///:31
 ///longjump///:32
 binwrch///:34
 rewind///:35
 findlog///:36
 writetolog///:37
 findtput///:38
 findparm///:39
 aptovec///:40
 ///findoutput///:41
 ///findinput///:42
 findlibrary///:43
 inputmember///:44
 parms///:45
 endread///:46
 endwrite///:47
 closelibrary///:48
 outputmember///:49
 endtoinput///:51
 loadpoint///:52
 endpoint///:53
 stackbase///:54
 stackend///:55
 stackhwm///:56
// G57 IS 'OS' OR 'CMS'
 writes///:60
 writen///:62
 newline///:63
 newpage///:64
 writeo///:65
 packstring///:66
 unpackstring///:67
 writed///:68
 writearg///:69
 readn///:70
 terminator///:71
 ch///:71
 loadpage///:72
 turnpage///:73
 writex///:74
 writehex///:75
 writef///:76
 writeoct///:77
 mapstore///:78
 userpostmortem///:79
 callifort///:80
 callrfort///:81
 setbreak///:82
 isbreak///:83
 errorreset///:84
 getbyte///:85
 putbyte///:86
 ///getvec:87
 ///freevec:88
 random///:89
 ///muldiv:90
 ///result2:91
 blocksize///:92
 createblockfile///:93
 openblockfile///:94
 closeblockfile///:95
 readblock///:96
 writeblock///:97
 wrnextblock///:98
 moveblock///:99
 zero///:101
 wrc///:102
 wch///:103
 wch1///:104
 chc///:105
 chz///:106
 writep///:107
 writel///:108
 wrflt///:109
 tab///:110
 xtab///:111
 ytab///:112
 ztab///:113
 q_input///:114
 q_output///:115
 q_selinput///:116
 q_seloutput///:117
 q_endread///:118
 q_endwrite///:119
 sysin///:120
 sysout///:121
 rch///:122
 rch0///:123
 rch1///:124
 peepch///:125
 rbase///:126
 readsn///:127
 setio///:128
 softerror///:129
 mapgvec///:130
 mapseg///:131
 mapload///:132
 validcode///:133
 validentry///:134
 erlev///:135
 erlab///:136
 stackb///:137
 stackl///:138
 backtr///:139
 nargs///:140
 wframe///:141
 
 stackp///:150
 st1///:152
 st2///:153
 svu///:154
 svv///:155
 ssz///:156
 region///:157
 
 stack///:161
 scanp///:162
 scanst///:163
 marka///:164
 stkover///:165
 gpfn///:166
 squash///:167
 
 eql///:170
 
 sadd///:171
 smul///:172
 sdiv///:173
 
 okpal///:174
 rec0///:175
 rec1///:176
 throw///:177
 
 ksq///:179
 kwords///:180
 kstack///:181
 
 lastditch///:184
 writeargp///:185
 errorp///:186
 pframe///:187
 pmap///:188
 flevel///:189
 mapheap///:190
 verify///:191
 paldd///:192
 
 setup///:193
 initff///:194
 setglob///:195
 valglob///:196
 stov///:197
 ttov///:198
 ///fixbcpl1///:199
 
 parama///:200
 paramb///:201
 paramc///:202
 paramd///:203
 parami///:204
 paramj///:205
 paramk///:206
 paramm///:207
 paramn///:208
 paramq///:209
 paramv///:210
 paramy///:211
 paramz///:212
 param///:213
 
 gw0///:214
 gw1///:215
 gw2///:216
 gw3///:217
 gw4///:218
 
 msg0///:220
 msg1///:221
 msg2///:222
 msg3///:223
 
 code///:225
 bcplf///:226
 bcplr///:227
 bcplv///:228
 getv///:229
 getmv///:230
 stream///:231
 
 g_load///:232
 g_unload///:233
 
 sel1///:235
 sel2///:236
 g_posint///:237
 g_np///:238
 g_nt///:239
 
 callbcpl///:240
 transpal///:241
 
 buffp///:242
 rtime///:243
 tempus///:244
 tempusp///:245
 clock///:246
 
 cons///:249
 cycles///:250
 gensymn///:251
 algn///:252
 lcoef///:253
 ldeg///:254
 frag///:255
 mfn///:256
 numarg///:257
 worse///:258
 worse1///:259
 gseq///:260
 gseqf///:261
 
 ocm///:262
 typ///:263
 fff///:264
 evsy///:265
 keep1///:266
 keep2///:267
 
 patch0///:268
 patch1///:269
 patch2///:270
 patch3///:271
 patch4///:272
 patch5///:273
 
 m///:275
 zc///:276
 ze///:277
 zj///:278
 zs///:279
 zsy///:280
 zsc///:281
 zsq///:282
 zu///:283
 
 e///:294
 j///:295
 arg1///:296
 root///:297
 trz///:298
 erz///:299
 
 a_num///:300
 a_qu///:301
 a_fclos///:302
 a_eq///:303
 a_gt///:304
 a_plus///:305
 a_minu///:306
 a_mul///:307
 a_div///:308
 a_null///:309
 
 error///:320
 errorset///:321
 erroreval///:322
 
 ll_sy///:330
 ll_rx///:331
 rp///:334
 readx///:335
 rexq///:336
 rexp///:337
 rdef///:338
 rfndef///:339
 rbv///:340
 rbvlist///:341
 rsym///:342
 rs///:343
 getex///:346
 
 rds///:351
 wrs///:352
 rea///:355
 prin///:357
 prch///:358
 prinl///:360
 print///:361
 printa///:362
 prink///:363
 prine///:365
 prinj///:366
 prind///:367
 
 trap///:430
 dotrap///:431
 dotrap1///:432
 trace///:435
 untrace///:436
 dotrace///:437
 dotrace1///:438
 
 show///:440
 show1///:445
 
 fixv///:470
 floatv///:471
 absv///:472
 ratapprox///:480
 shlv///:486
 shrv///:487
 
 lvv///:490
 rvv///:491
 tyv///:492
 hdv///:493
 miv///:494
 tlv///:495
 null///:496
 iv///:497
 order///:498

 lmap///:500
 lmapl///:501
 lmapt///:502
 
 dofor///:509
 aug///:511
 isv///:512
 assg///:513
 genglo///:514
 gensym///:515
 asym///:516
 rev///:517
 revd///:518
 xtuple///:520
 find///:521
 put///:522
 
 arithv///:529
 coerce///:530
 arithfn///:531
 eqlv///:532
 gtv///:533
 add///:538
 minu///:539
 mul///:540
 div///:541
 modv///:542
 pow///:543
 neg///:544
 positive///:545
 recip///:546
 gcda///:547
 
 mainvar///:550
 num///:551
 atom///:552
 tuple///:553
 rat///:555
 syn///:556
 function///:557
 
 apply///:560
 eval///:561
 get4///:562
 getx///:563
 
 linkword///:572
 findword///:573
 putword///:574
 compl///:575
 
 pol///:576
 eqpoly///:577
 evalpoly///:578
 alg///:579
 algatom///:580
 addpoly///:581
 addp1///:582
 polymapf///:583
 mulpoly///:584
 divpoly///:585
 pseudorempoly///:586
 copyu///:587
 copyv///:588
 uncopy///:589
 monicpoly///:590
 polygcd///:591
 
 matchbv///:599
 simname///:600
 simtup///:601
 fn///:602
 rec///:603
 mlet///:604
 mlet1///:605
 colon///:606
 mcolon///:607
 seq///:608
 mseq///:609
 cond///:610
 mcond///:611
 linseq///:612
 retu///:613
 mqu///:614
 ap1///:615
 ap2///:616
 mdol///:617
 mk_aa///:618
 mk_zz///:619
 mdash///:620
 mnull///:621
 mclos1///:622
 ma2///:623
 
 mk_aug///:624
 mk_logor///:625
 mk_logand///:626
 mk_ne///:627
 mk_ge///:628
 mk_lt///:629
 mk_le///:630
 mk_plus///:632
 mk_minu///:633
 mk_mul///:634
 mk_div///:635
 mk_pow///:636
 mfor///:637
 mwhi///:638
 mdolv///:639
 
 fixap///:640
 
 number///:671
 string///:673
 name///:674
 globa///:675
 
 dump///:695
 undump///:696
 
 longadd///:701
 longsub///:702
 longas1///:703
 longmul///:704
 longmul1///:705
 longcmp///:706
 longdiv1///:707
 longdiv///:708
 
 lookup///:710
 bind///:711
 bind1///:712
 binda///:713
 bindr///:714
 dorec///:716
 doreca///:717
 
 difr///:720
 difr1///:721
 
 igcd///:725
 gcd1///:726
 lgcd///:727
 
 l_flatten///:734
 flatten///:735
 flat1///:736
 fixapf///:737
 flatbv///:738
 simenv///:739
 loadn///:740
 
 ff_clos///:755
 ff_reca///:756
 ff_tuple///:757
 ff_condb///:758
 ff_seqa///:759
 ff_dash///:760
 ff_e///:761
 ff_a1e///:763
 ff_ave///:764
 ff_a2e///:765
 
 ll_zc///:780
 la_entx///:781
 la_enty///:782
 la_entz///:783
 la_aploc///:784
 la_aptup///:785
 la_apcode2///:786
 la_apclos2///:787
 la_apeclos///:788
 la_apfclos///:789
 
 ll_entx///:790
 ll_enty///:791
 ll_entz///:792
 ll_apeclos///:793
 ll_apfclos///:794
 la_a1///:795
 la_ae///:796
 
 ll_ev///:797
 ll_ex///:798
 ll_ap///:800
 ll_glz///:801
 ll_rsc///:802
 ll_rsf///:803
 ll_svc///:804
 ll_svf///:805
 ll_svf1///:806
 
 ll_bind///:811
 ll_binde///:816
 ll_unbind///:817
 ll_cy///:820
 ll_cyf///:821
 ll_na///:822
 ll_na1///:823
 ll_na2///:824
 ll_naf///:825
 ll_na1f///:826
 ll_na2f///:827
 ll_st///:830
 ll_us///:831
 
 ll_rec0///:833
 ll_rec1///:834
 ll_dash///:835
 ll_e///:836
 ll_j///:837
 ll_cond///:838
 
 ll_tup///:840
 ll_tupa///:841
 ll_tupz///:842
 ll_1tup///:843
 ll_closl///:845
 ll_closx///:847
 ll_apv///:850
 ll_ap1///:851
 ll_hdv///:852
 ll_miv///:853
 ll_tlv///:854
 ll_null///:855
 ll_atom///:856
 ll_ap2///:857
 ll_ap2f///:858
 ll_ap2s///:859
 ll_ap2sf///:860
 ll_cons///:861
 ll_consf///:862
 ll_xcons///:863
 ll_xconsf///:864
 
 ll_lv///:869
 ll_rv///:870
 ll_bvf///:872
 ll_bvfe///:873
 ll_bvfa///:874
 ll_bvf1///:875
 ll_bvfz///:876
 ll_bve///:877
 ll_bvez///:878
 ll_ent2///:879
 
 ll_apcf///:880
 ll_apcf1///:881
 ll_apck///:882
 ll_apcc///:883
 ll_apbf///:884
 ll_apbf1///:885
 ll_apbk///:886
 ll_apbc///:887
 ll_apkf///:888
 ll_apkk///:889
 ll_apkc///:890
 ll_apkj///:891
 ll_apnf///:892
 ll_apnf1///:893
 ll_apnk///:894
 ll_apnc///:895
 ll_apnj///:896

 psetio /// Must be updateable
 ddadd
 ddminu
 ddmul
 dddiv
 ddaddpoly
 ddmulpoly
 dddivpoly
 ddpseu
 ddequp


}
 
 
MANIFEST {
  ocmsz = 120
  maxglob = 896
}

