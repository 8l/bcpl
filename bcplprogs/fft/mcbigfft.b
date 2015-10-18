/*

This is a version of bigfft.b that uses scaled fixed point complex
arithmetic rather than modulo arithmetic and generates dynamic native
code using the MC package.

Implemented by Martin Richards (c) January 2008

*/

GET "libhdr"
GET "mc.h"

MANIFEST {
 A=mc_a
 B=mc_b
 C=mc_c
 D=mc_d
 E=mc_e
 F=mc_f
}


MANIFEST {
Scale = 10000    // All scaled values are of the form: dddd.dddd

//K = 16
//K = 12
//K = 10
//K = 2
K = 3
//K = 2

N       = 1<<K    // N = 2^K
upb     = N-1     // UPB of data vectors
}

STATIC {
 rdata=0      // real components
 idata=0      // imaginary components
 prupb = upb  // Upper bound for printing
 rw           // Table of re(w^k)
 iw           // Table of im(w^k)
}

// sin(a) returns sine((pi/2)*(a/1024)) a=0..1024 as unsigned fractions in 
// the range [0,1). The results are rounded, except for sin(1024) which
// returns #xFFFFFFFF

LET sin(a) = a!TABLE
#x00000000,#x006486EB,#xFFD8FFD5,#x011E9782,#x01921000,#x0105B651,#x024C1E61,
#x01BFC406,#x03242B31,#x0387BFFD,#x02EE451E,#x0450D8D3,#x03C63DAF,#x050ADFF0,
#x05705348,#x04F2E3E7,#x0648556E,#x05ACE51D,#x071152E3,#x0774E163,#x06DB3DCD,
#x082ED800,#x07B341EE,#x0906BC86,#x095D31BB,#x08DFB86C,#xFB350CC7,#xFB998061,
#xFAFF0069,#xFC625FBF,#xFBD5DE52,#xFD1C4915,#xFD7FC209,#xFD040AEC,#xFE587FDF,
#xFDBCF3D3,#xFF214689,#xFF84B621,#xFEEB036D,#x003F4F7B,#xFFC1C72D,#x1016FE83,
#x106C613F,#x0FDFC27F,#x11440134,#x10B83E31,#x11FD9674,#x126FDCF0,#x11E52092,
#x1339613F,#x138E9012,#x1400E8E0,#x14661179,#x13CB44FD,#x151F773B,#x1591B554,
#x1505DFFC,#x164B074E,#x15C00C2F,#x17232C8E,#x1787585B,#x16EC7196,#x18408712,
#x17C397D0,#x1916B5BD,#x196BBFCB,#x18DFC5EC,#x0B42C8FF,#x0AB6C724,#x0BFBC10F,
#x0C5FB5ED,#x0BE39870,#x0D3784D8,#x0D8C5EC6,#x0D00532C,#x0E633348,#x0DD6FECC,
#x0F1AF4C8,#x0F7EC6FE,#x0F02857E,#x10563F56,#x0FBB123C,#x200DE14B,#x20817C76,
#x1FF54080,#x21480095,#x20AD8C79,#x2210411C,#x2272F18E,#x21E76CC0,#x232C1281,
#x238EB1E4,#x24021DB9,#x2464C201,#x23D9328C,#x251CAD8B,#x25901FDE,#x25038054,
#x26560703,#x25BB4AB7,#x270DC762,#x2780FF14,#x26F44EB0,#x2846B924,#x27AAEE62,
#x28FF1C4C,#x297161FF,#x28E4942F,#x1B36BFFC,#x1B8AF354,#x1AFF00FD,#x1C611823,
#x1BD42889,#x1D273220,#x1D7B3506,#x1CEE2FFF,#x1E502609,#x1DC31418,#x1F14FC0B,
#x1F77DC00,#x1EDBC2BD,#x202F852F,#x1FB14077,#x30041258,#x3065CDE1,#x2FD980E3,
#x311D1F41,#x317EE336,#x31017078,#x32540608,#x31C692E3,#x331918CE,#x336C96F5,
#x32DEFEFE,#x34406D36,#x33B1F240,#x3505403C,#x35679619,#x34D8F2AC,#x361D2803,
#x367F64DF,#x36008B60,#x3751D669,#x36C3F8EC,#x381703E4,#x38791719,#x37DC1FB6,
#x392E2170,#x39901966,#x2B010879,#x2B61EF8B,#x2AD3CBBB,#x2C268FCC,#x2C885ABC,
#x2BEB1D6F,#x2D3BF503,#x2CAE942D,#x2E002B1A,#x2E6FE67D,#x2DE26985,#x2F330206,
#x2F9571D0,#x2F05F901,#x3058556E,#x2FC8C835,#x400C1119,#x406D600B,#x3FDDB51B,
#x412EF038,#x40B01137,#x42013817,#x426253D9,#x41D36730,#x43246069,#x43855E38,
#x42F6608E,#x4447497B,#x43B82700,#x4507FBC0,#x4568D3F8,#x44CB834E,#x461C3700,
#x467BDFF0,#x45ED6DEF,#x473E0FFE,#x46AE98FE,#x47FF1600,#x485F8704,#x47CEEEB0,
#x49203B1F,#x49808B65,#x48EFE043,#x3B5017BC,#x3AC045BE,#x3C10692B,#x3C708024,
#x3BE07C5C,#x3D307C02,#x3D906EE8,#x3D0065F0,#x3E5042FD,#x3DC01349,#x3EFFE77E,
#x3F607FD6,#x3ED02BF8,#x401EDBF1,#x407F5FB5,#x3FEE0724,#x503E7250,#x4FACF119,
#x50FD4372,#x515C993B,#x50CAF295,#x521B1042,#x52894044,#x51F8727C,#x53478909,
#x52B691C0,#x54058070,#x5464702C,#x53D36202,#x552236C7,#x5581003C,#x54DFBBC0,
#x562F68E6,#x568DFAC0,#x55FC8F1F,#x574B2442,#x56C88CDF,#x58170703,#x58756572,
#x57E2C53D,#x59310774,#x59901BDC,#x58EF5272,#x4B3D5C1C,#x4AAB7507,#x4C0871D8,
#x4C66617F,#x4BD4422D,#x4D2213D3,#x4D6FE916,#x4CDE8025,#x4E2C35F0,#x4E97E02E,
#x4E064C29,#x4F52E798,#x4EC1456D,#x4FFEB3D4,#x505C0564,#x4FD9373E,#x60265B71,
#x60837ED1,#x5FEFB41F,#x612DAAAC,#x618AB229,#x61077B8B,#x625462F0,#x61C11F0C,
#x62FDF8FF,#x635B93BC,#x62D73112,#x6422BF07,#x64802C7C,#x63DCB97F,#x65390804,
#x659555DF,#x650195FF,#x663DD585,#x65B8F535,#x67050510,#x67610508,#x66BDF4FF,
#x6818D516,#x687594FF,#x67E153ED,#x691E0490,#x6987B40C,#x68F43340,#x5B2FC220,
#x5B8C1FAE,#x5B066EBB,#x5C50CD49,#x5BAE093C,#x5D0834C1,#x5D635160,#x5CBF4D76,
#x5E1955C8,#x5E744028,#x5DD017C5,#x5F28F053,#x5F849606,#x5EE02D7D,#x6038E10A,
#x60945450,#x5FEED681,#x70492760,#x6FB375EE,#x6FFDC50E,#x7156F0DF,#x70C0FE26,
#x71FD05F5,#x7264FFFF,#x71BFF593,#x7318BB64,#x73736E77,#x72CE1EBD,#x7425CF24,
#x74804BB3,#x73E8E71C,#x75333FAF,#x757D980F,#x74F4DE5F,#x76301080,#x76983173,
#x76013FFF,#x773B2D52,#x76B32620,#x76FBFE8B,#x7853D285,#x77AE73F0,#x79061490,
#x794EB0C4,#x78C70D12,#x6B0082AC,#x6B66E872,#x6AD00B57,#x6C184941,#x6C70653C,
#x6BD85F2F,#x6D20640B,#x6D7845E2,#x6CE01658,#x6E26E290,#x6E706C99,#x6DE71139,
#x6F1F9360,#x6F860231,#x6EDE4E71,#x7033B510,#x707BE921,#x6FF20994,#x802B0641,
#x80900027,#x7FF6F42B,#x812EC55D,#x819571B0,#x80ED0C06,#x8241C135,#x8299324E,
#x81F09062,#x83450835,#x838D2CD9,#x83025E11,#x84488902,#x848F907B,#x840482B0,
#x853B6235,#x84B01D2D,#x8504F0B7,#x863C825B,#x85B0FF78,#x860684D2,#x873BF82D,
#x86B134E9,#x87065F7C,#x883C9247,#x87AFAFFE,#x88058AB0,#x893B7026,#x89903F70,
#x89040891,#x7B47AE7A,#x7B8E2E00,#x7B00C726,#x7C460BF0,#x7C8B5C0F,#x7BEEB3E7,
#x7D41D809,#x7D95E76C,#x7CEAE041,#x7E2EC368,#x7E927FC9,#x7DF63834,#x7F38E8CE,
#x7F7E6578,#x7EEFDC26,#x80342ACE,#x8087844E,#x7FDAC6CD,#x901DE4FC,#x907FDD00,
#x8FE2CCDA,#x9125B71F,#x91795C31,#x90CD17D4,#x920EAFDD,#x9271305C,#x91D38B65,
#x9314EDBE,#x93681B66,#x92BB5054,#x93FD506B,#x944F56CC,#x93C0392C,#x950202BD,
#x9552C743,#x94B552D3,#x9505E920,#x9648476D,#x96998F8B,#x95EADF70,#x972D0710,
#x977E185D,#x96DF124B,#x981F03DE,#x986FBFF7,#x97E0735E,#x99210062,#x997192BB,
#x98D20068,#x8B125560,#x8B629296,#x8AC1C6FD,#x8C01D588,#x8C51BC1D,#x8BB297DD,
#x8C024F7C,#x8D41FD1F,#x8D90B0C9,#x8CF1100F,#x8E308452,#x8E6FE149,#x8DD00506,
#x8F0F223D,#x8F5E2640,#x8EBD10D6,#x8FFAF3E1,#x90599055,#x8FB84148,#x9005CB8B,
#xB0452C41,#xB0939331,#xAFF0E24F,#xB12007BD,#xB16F0630,#xB0CBFAE9,#xB218E681,
#xB2679928,#xB1C541D5,#xB301E349,#xB3503AAB,#xB38DB7DD,#xB2EAEDE3,#xB4381983,
#xB4851BE0,#xB3E223DD,#xB5100460,#xB55BCB7C,#xB4C87724,#xB604FB20,#xB65182B0,
#xB68DF35B,#xB5EB2983,#xB73654E0,#xB7826871,#xB6CF611F,#xB80B3FFB,#xB86603FB,
#xB7C0B002,#xB7FE3FF6,#xB947C6CC,#xB9941495,#xB8E05738,#xAB1B6FB8,#xAB757DDC,
#xAAD080D4,#xABFC4C59,#xAC560B7D,#xABAFC054,#xABEC48B4,#xAD34C971,#xAD7FFEB0,
#xACCB4954,#xAE146952,#xAE4F5EB0,#xADB85932,#xAE0227FD,#xAF2BDE03,#xAF8577FC,
#xAECF0739,#xB0184C73,#xB060B3AD,#xAFAAE1E9,#xB002F4F0,#xC02CDDF2,#xC084BAB8,
#xBFCF6D36,#xC1172270,#xC14FAE79,#xC0B80E18,#xC1007152,#xC237AB0C,#xC27FD769,
#xC1D7D921,#xC30FB063,#xC35878FC,#xC2B027F9,#xC2F6BD25,#xC42032B1,#xC4768055,
#xC3BDD034,#xC5040333,#xC53BFC49,#xC591F769,#xC4E8C789,#xC6205C8F,#xC667038D,
#xC5AE706B,#xC602E01D,#xC72B21B7,#xC78048F0,#xC6D653CF,#xC7FD4364,#xC8521598,
#xC896CC60,#xC7DE63C0,#xC921F16F,#xC96840C0,#xC8AE8569,#xC901AD70,#xBB36C5CC,
#xBB6CB45E,#xBAD1753E,#xBC062962,#xBC3AD08E,#xBC802B08,#xBBE39865,#xBD16E7DE,
#xBD4BFD52,#xBCB001BB,#xBCF2ECFD,#xBE26C82E,#xBE5C6743,#xBDAF0913,#xBE025DB3,
#xBF34D3F7,#xBF77FEE6,#xBEBD0C66,#xBF000B7C,#xC040FD2F,#xC083D071,#xBFD7670B,
#xD0090031,#xD03D4BAC,#xD07EB96E,#xCFDFE98E,#xD111ED01,#xD153F090,#xD195C75E,
#xD0E87050,#xD20AFC5F,#xD24C887E,#xD28CF6C3,#xD1DF27E7,#xD3103BEF,#xD3604FED,
#xD2B136CB,#xD2F2006E,#xD421AAFD,#xD463372B,#xD3B2B520,#xD3F303E2,#xD5242618,
#xD5643806,#xD4B41E65,#xD4F40358,#xD622BAD7,#xD66352B8,#xD5B1CE01,#xD5F22998,
#xD7216694,#xD76083DB,#xD7908461,#xD6DF6510,#xD80E26FC,#xD84BCB0B,#xD88B3F44,
#xD7E7C36F,#xD91608C0,#xD9551FFF,#xD9932930,#xD8E1123E,#xCAFEDD49,#xCB3D870E,
#xCB7B11BF,#xCAD77024,#xCC03CD45,#xCC40FB15,#xCC70087F,#xCBBC06B6,#xCC07D752,
#xCD35777B,#xCD720844,#xCCAF7976,#xCCEACC18,#xCE25FE21,#xCE630086,#xCE900231,
#xCDDAE542,#xCF168888,#xCF520D04,#xCF7E7FB0,#xCED7F380,#xD004175E,#xD0301C5F,
#xD06B1079,#xCFC40385,#xCFEFB78A,#xE01B2C6D,#xE063B055,#xE09002FC,#xDFE93696,
#xE11348EC,#xE13E2E02,#xE186FFE2,#xE0CFD252,#xE0FB546B,#xE232D641,#xE25E178D,
#xE1B64885,#xE1E05800,#xE31847E8,#xE3511831,#xE388D604,#xE2D25518,#xE2FAD294,
#xE4330060,#xE45C2C72,#xE3B345D2,#xE3DC3148,#xE511FAFB,#xE53AB2E1,#xE5821BD4,
#xE4C991D8,#xE4FFE7E8,#xE626FDF9,#xE6500105,#xE694F401,#xE5CCB5E6,#xE703478B,
#xE738D736,#xE77024B1,#xE6B661E4,#xE6DD6ED4,#xE812795C,#xE84851D0,#xE86EFABB,
#xE7C2B152,#xE7F9166F,#xE90F5B38,#xE9538D75,#xE987AE21,#xE8BE8D4E,#xE9026907,
#xDB271505,#xDB4BB03F,#xDB9007FD,#xDAD44005,#xDB087531,#xDC1D77B7,#xDC604B52,
#xDC940B28,#xDBD6C822,#xDBFC3437,#xDD1F7F50,#xDD60D693,#xDD93DCCC,#xDCD6DFFF,
#xDCFAB326,#xDE1E5339,#xDE4FF131,#xDE923E05,#xDDD495AF,#xDE05BF25,#xDF27D350,
#xDF4AB658,#xDF7D6706,#xDEBF0563,#xDEF08167,#xE01FDC09,#xE0521241,#xE08326FC,
#xDFC4194D,#xDFF3F91E,#xF0159678,#xF0462134,#xF076895A,#xEFB5CEF2,#xEFE600D5,
#xF10600FE,#xF135D080,#xF1667B4A,#xF1962240,#xF0D5977D,#xF103F907,#xF224197B,
#xF253262E,#xF2821009,#xF1BFE5F7,#xF1E06AD0,#xF2FDFBBC,#xF32D58B4,#xF35B9481,
#xF397AD3D,#xF2D5B000,#xF3047291,#xF4221FFC,#xF43FAD38,#xF46E1430,#xF3AB5909,
#xF3E76B90,#xF50477CE,#xF53152C9,#xF54EFC3E,#xF57B9081,#xF4C71050,#xF4F34DC1,
#xF6008790,#xF62C7F14,#xF6677106,#xF6933071,#xF5BECD3D,#xF5EB4492,#xF715992D,
#xF73FCB44,#xF75BE6B1,#xF795D141,#xF6D18746,#xF6ED2970,#xF815B706,#xF84101B0,
#xF85C396B,#xF8953D6E,#xF7C02BB1,#xF7F905F2,#xF911AF37,#xF92D318B,#xF9659107,
#xF97ECD74,#xF8C6F2DF,#xF8EFE72D,#xEB08B67B,#xEB3250D0,#xEB4AE7E8,#xEB832BCE,
#xEAAC6B97,#xEAE39531,#xEAFC7C94,#xEC234DBB,#xEC3BFC8F,#xEC729538,#xEC98FB84,
#xEBD12C6B,#xEBF85815,#xED005041,#xED362422,#xED4CE387,#xED834F7A,#xECB8D403,
#xECE005ED,#xED062461,#xEE0D0E3C,#xEE4100B4,#xEE66B167,#xEE7E1D7F,#xEDC29311,
#xEDE6E3EF,#xEDFD020D,#xEF20EB97,#xEF45BF4B,#xEF5C5E4E,#xEF80078D,#xEEC44E11,
#xEEE88DC6,#xEEFCC986,#xF01FC06C,#xF0448290,#xF0681FBF,#xF07BC802,#xEFB00C54,
#xEFE258C1,#xF0057311,#x00186770,#x002C35D9,#x004DF115,#x00806651,#xFFB1D676,
#xFFD5016F,#xFFF71767,#x01090827,#x011AE2BE,#x013D6B21,#x015DFC50,#x01805744,
#x00C07E06,#x00E19063,#x01027C86,#x02135259,#x023302E8,#x02545FFD,#x0273D5D1,
#x02940824,#x01C5040D,#x01E3EAB8,#x0203ABD0,#x03144762,#x0332BE87,#x0352FF1B,
#x03723949,#x03912EDC,#x02C00EDF,#x02CEE93E,#x02EE5F22,#x03FBDE4B,#x041B25F1,
#x04483ADE,#x04664910,#x048420C0,#x03B0E47E,#x03C060C0,#x03DCD915,#x03FAFAC6,
#x05172691,#x05340D90,#x054FECDF,#x055E9747,#x057B0BE7,#x04B66B7B,#x04D1C34D,
#x04DED646,#x04FAC347,#x06166B58,#x06320C77,#x063E968F,#x0667EBD9,#x06840B04,
#x0690240D,#x05BB072C,#x05E3D43E,#x05F04C50,#x0708CD2E,#x07241712,#x072F2BCC,
#x07582B63,#x077211E5,#x077BD510,#x06B5512D,#x06BEC728,#x06E705F0,#x07011060,
#x07FB02B4,#x0821DFB6,#x082C7765,#x085306DE,#x085D5208,#x088484F4,#x088D935E,
#x07C46B90,#x07CD2C78,#x07F2E501,#x07FC3B09,#x091296BC,#x0928C005,#x093FBFF2,
#x09578B40,#x095F3F48,#x0983DBCB,#x098C41E1,#x08C1834C,#x08D78E63,#x08DE8FF6,
#x09034DF0,#xFB090440,#xFB0F8420,#xFB32DE6E,#xFB491035,#xFB4F0D55,#xFB7300E8,
#xFB86CFBD,#xFB8D57FE,#xFABFCB99,#xFAD5157C,#xFAE938E2,#xFAEE375B,#xFC00FF41,
#xFC13BF70,#xFC284707,#xFC2BAAC4,#xFC3EF5C3,#xFC60FBF0,#xFC73EB69,#xFC86C20B,
#xFC8B5302,#xFBACCE0E,#xFBC02068,#xFBE13CF0,#xFBF35284,#xFC053140,#xFD05F930,
#xFD186B52,#xFD28F484,#xFD2C26E4,#xFD3D442E,#xFD4E38BF,#xFD5F0854,#xFD6EAFFE,
#xFD802FC6,#xFD907B6D,#xFCAFBE3E,#xFCBFD926,#xFCCFAF05,#xFCE05BF7,#xFCF001CC,
#xFCFF71AE,#xFDFDBC7C,#xFE0CDE63,#xFE1BE833,#xFE2AAC08,#xFE4957C0,#xFE56DF58,
#xFE662CF0,#xFE747472,#xFE8283E0,#xFE905F34,#xFE8F3060,#xFDABCC7D,#xFDC9307D,
#xFDD67D5C,#xFDE2C228,#xFDEFBFC0,#xFDEE8830,#xFDFB3878,#xFF05D195,#xFF132387,
#xFF104F49,#xFF1C70DC,#xFF374F2C,#xFF432367,#xFF3ED14F,#xFF4B380E,#xFF6586B2,
#xFF6FAFEC,#xFF6BC008,#xFF867AD6,#xFF912E54,#xFF8BD7B1,#xFEB61CB9,#xFEC0695E,
#xFEBB6EEB,#xFED45E10,#xFECF3409,#xFEE6E2B8,#xFEF13BFC,#xFEEB8D01,#xFF02D5C4,
#xFEFCD917,#x0004B428,#xFFFF56F5,#x0015F43E,#x00104950,#x00278718,#x00208E79,
#x00377D70,#x0030541B,#x00460478,#x003F5E68,#x0054BF08,#x004CF92A,#x0062EC08,
#x005AD765,#x00716C60,#x00780814,#x006F5E54,#x0083AC1D,#x007AD18E,#x008FBFB7,
#x00967846,#x008D186D,#xFFB19146,#xFFB5F1B6,#xFFACFD97,#xFFC1000C,#xFFC4EB31,
#xFFBB8DE8,#xFFC01B10,#xFFD37EE6,#xFFD6CD1D,#xFFCBF210,#xFFCFE081,#xFFE39770,
#xFFE736FB,#xFFDAB021,#xFFDDFFD2,#xFFF127F1,#xFFF41AB6,#xFFF703F7,#xFFF8C6C1,
#xFFED4304,#xFFEEB5E0,#xFFFFF344,#x00020820,#x0003F4B2,#x0005AC8D,#x00083B0F,
#x0008D126,#xFFFC0FC4,#xFFFD37D9,#xFFFE3964,#xFFFF1285,#xFFFED41D,#x00003F58,
#xFFFFC0FC,#xFFFFED42,#xFFFFFFFF

LET rwki(k,i) = VALOF
// Returns the real part of the (2^i)th power (i = 0..k)
// of the (2^k)th root of unity using scaled arithmetic
// with 9 digits after the decimal point.
{ LET t = TABLE
  1_000000000,                                  
  0_999999995, // cos(2Pi/65536) = re(w^1)      (2**16)th root of unity
  0_999999982, // cos(2Pi/32768) = re(w^2)      (2**15)th root of unity
  0_999999926, // cos(2Pi/16384) = re(w^4)      (2**14)th root of unity
  0_999999706, // cos(2Pi/ 8192) = re(w^8)      (2**13)th root of unity
  0_999998823, // cos(2Pi/ 4096) = re(w^16)     (2**12)th root of unity
  0_999995294, // cos(2Pi/ 2048) = re(w^32)     (2**11)th root of unity
  0_999981175, // cos(2Pi/ 1024) = re(w^64)     (2**10)th root of unity
  0_999924702, // cos(2Pi/  512) = re(w^128)    (2** 9)th root of unity
  0_999698819, // cos(2Pi/  256) = re(w^256)    (2** 8)th root of unity
  0_998795456, // cos(2Pi/  128) = re(w^512)    (2** 7)th root of unity
  0_995184727, // cos(2Pi/   64) = re(w^1024)   (2** 6)th root of unity
  0_980785280, // cos(2Pi/   32) = re(w^2048)   (2** 5)th root of unity
  0_923879533, // cos(2Pi/   16) = re(w^4096)   (2** 4)th root of unity
  0_707106782, // cos(2Pi/    8) = re(w^8192)   (2** 3)th root of unity
  0_000000000, // cos(2Pi/    4) = re(w^16384)  (2** 2)th root of unity
 -1_000000000, // cos(2Pi/    2) = re(w^32768)  (2** 1)th root of unity
  1_000000000  // cos(2Pi/    1) = re(w^65536)  (2** 0)th root of unity
  LET base = 17-k // k=16 => 0, k=15=>1, k=14=>2, etc 
  RESULTIS t!(base+i)
}

LET iwki(k, i) = VALOF
// Returns the imaginary part of the (2^i)th power
// of the (2^k)th root of unity using scaled arithmetic
// with 9 digits after the decimal point.
{ LET t = TABLE
  0_000000000,
  0_000095874, // sin(2Pi/65536) = im(w^1)      (2**16)th root of unity
  0_000191748, // sin(2Pi/32768) = im(w^2)      (2**15)th root of unity
  0_000383495, // sin(2Pi/16384) = im(w^4)      (2**14)th root of unity
  0_000766990, // sin(2Pi/ 8192) = im(w^8)      (2**13)th root of unity
  0_001533980, // sin(2Pi/ 4096) = im(w^16)     (2**12)th root of unity
  0_003067957, // sin(2Pi/ 2048) = im(w^32)     (2**11)th root of unity
  0_006135885, // sin(2Pi/ 1024) = im(w^64)     (2**10)th root of unity
  0_012271538, // sin(2Pi/  512) = im(w^128)    (2** 9)th root of unity
  0_024541228, // sin(2Pi/  256) = im(w^256)    (2** 8)th root of unity
  0_049067674, // sin(2Pi/  128) = im(w^512)    (2** 7)th root of unity
  0_098017140, // sin(2Pi/   64) = im(w^1024)   (2** 6)th root of unity
  0_195090322, // sin(2Pi/   32) = im(w^2048)   (2** 5)th root of unity
  0_382683432, // sin(2Pi/   16) = im(w^4096)   (2** 4)th root of unity
  0_707106782, // sin(2Pi/    8) = im(w^8192)   (2** 3)th root of unity
  1_000000000, // sin(2Pi/    4) = im(w^16384)  (2** 2)th root of unity
  0_000000000, // sin(2Pi/    2) = im(w^32768)  (2** 1)th root of unity
  0_000000000  // sin(2Pi/    1) = im(w^65536)  (2** 0)th root of unity
  LET base = 17-k // k=16 => 0, k=15=>1, k=14=>2, etc 
  RESULTIS t!(base+i)
}

AND wpower(k, n) = VALOF
// Returns re(w**n), result2=im(w**n) where w is the (2**k)th root of unity
// using scaled arithmetic with 9 digits after the decimal point.
{ LET res, res2 = 1_000000000, 0
  LET i = 0
  LET nn = n

  WHILE n DO
  { UNLESS (n&1)=0 DO
    { // Multiply by w^(2**i) where w = (2^k)th root of unity
      LET rwk, iwk = rwki(k,i), iwki(k,i) 
      LET rt, it = res, res2
      res  := muldiv(rt, rwk, 1_000000000) - muldiv(it, iwk, 1_000000000)
      res2 := muldiv(rt, iwk, 1_000000000) + muldiv(it, rwk, 1_000000000)
    }
    i, n := i+1, n>>1
  }

  result2 := res2
  RESULTIS res
}

LET start() = VALOF
{ // Load the dynamic code generation package
  LET mcseg = globin(loadseg("mci386"))
  LET mcb = 0

  UNLESS mcseg DO
  { writef("Trouble with MC package: mci386*n")
    GOTO fin
  }

  // Create an MC instance for 10 functions with a data space
  // of 3,000 words and code space of 100,000
  mcb := mcInit(20, 3_000, 100_000)

  UNLESS mcb DO
  { writef("Unable to create an mci386 instance*n")
    GOTO fin
  } 

  mc := 0          // Currently no selected MC instance
  mcSelect(mcb)

   prupb := upb
   rdata := getvec(upb)
   idata := getvec(upb)

   rw := getvec(N)  // For a table of w^i, i=0..N
   iw := getvec(N)

   // Build a table of powers of the Nth root of unity where N=2^K.
   FOR i = 0 TO N DO
   { rw!i := wpower(K, i)
     iw!i := result2
   }

   mcK(mc_debug, #b0011)

   genfft(1, FALSE) // Create F1 = FFT function
   genfft(2, TRUE)  // Create F2 = Inverse FFT function

   FOR i = 0 TO upb DO rdata!i, idata!i := i*1000, 0

   pr(rdata, idata, prupb)
// prints  -- Original data

//(  0.0000,  0.0000) (  1.0000,  0.0000) (  2.0000,  0.0000) (  3.0000,  0.0000) 
//(  4.0000,  0.0000) (  5.0000,  0.0000) (  6.0000,  0.0000) (  7.0000,  0.0000) 
//(  8.0000,  0.0000) (  9.0000,  0.0000) ( 10.0000,  0.0000) ( 11.0000,  0.0000) 
//( 12.0000,  0.0000) ( 13.0000,  0.0000) ( 14.0000,  0.0000) ( 15.0000,  0.0000) 

   mcCall(1) // Call the FFT function

   pr(rdata, idata, prupb)
// prints   -- Transformed data

//(120.0000,  0.0000) ( -8.0001,-40.2184) ( -8.0000,-19.3136) ( -8.0001,-11.9726) 
//( -8.0000, -8.0000) ( -7.9999, -5.3454) ( -8.0000, -3.3136) ( -7.9999, -1.5912) 
//( -8.0000,  0.0000) ( -7.9999,  1.5912) ( -8.0000,  3.3136) ( -7.9999,  5.3454) 
//( -8.0000,  8.0000) ( -8.0001, 11.9726) ( -8.0000, 19.3136) ( -8.0001, 40.2184) 

   mcCall(2) // Call the Inverse FFT function

   pr(rdata, idata, prupb)
// prints  -- Restored data

//(  0.0000,  0.0000) (  1.0000,  0.0000) (  2.0000,  0.0000) (  3.0000,  0.0000) 
//(  4.0000,  0.0000) (  5.0000,  0.0000) (  6.0000,  0.0000) (  7.0000,  0.0000) 
//(  8.0000,  0.0000) (  8.9999,  0.0000) (  9.9999,  0.0000) ( 10.9999,  0.0000) 
//( 12.0000,  0.0000) ( 12.9999,  0.0000) ( 13.9999,  0.0000) ( 14.9998,  0.0000) 

fin:
  IF mcseg DO unloadseg(mcseg)  
  RESULTIS 0
}

AND genfft(fno, inverse) BE
{ LET n2  = N>>1

  mcKKK(mc_entry, fno, 3, 0)

  // First do the perfect shuffle
  genreorder(rdata, idata, N)

  // Then do all the butterfly operations
  FOR s = 1 TO K DO
  { LET m  = 1<<s
    LET m2 = m>>1
    LET k = 0
    FOR j = 0 TO m2-1 DO
    { LET p = j
      WHILE p<N DO
      { LET rwk = rw!k
        LET iwk = inverse -> -iw!k, iw!k
        butterfly(p, p+m2, rwk, iwk, k)
        p := p+m
      }
      k := k + (1<<(K-s))
    }
  }

  IF inverse FOR i = 0 TO upb DO
  { 
    writef("// div:  %i4 by %n*n", i, N)
  }

  mcF(mc_rtn)
  mcF(mc_endfn)
}

AND butterfly(p, q, rwk, iwk, k) BE
{ LET a = k MOD (N/4) // The angle in the first quadrant
  LET q = k / (N/4)   // the quadrant number
  LET rneg = q=1 | q=2
  LET ineg = q>=2
  LET i = a * 1024 * K / N
  // i is a power of 2 with
  // i=0    meaning and angle of 0 degrees and
  // i=1024 meaning and angle of 90 degrees.
  // re and im are the cosine and sine of this angle.
  LET re = sin(1024-i)
  LET im = sin(i)

writef("// bfly: %i4 %i4 w^%n = (%12.9d + %12.9di)*n",
        p, q, k, rwk, iwk)

  // Set B+iC = !q * wk
  // Then add to !p and subtract from !q

  // Optimise the cases wk = 1, i, -1 and -i
  TEST rwk=1_000000000 & iwk=0 & FALSE
  THEN { // wk = 1
         mcRM(mc_mv,  B, @rdata!q)
         mcRM(mc_mv,  C, @idata!q)
         mcMR(mc_add, @rdata!p, B)  // !p +:= !q*wk
         mcMR(mc_add, @idata!p, C)
         mcMR(mc_sub, @rdata!q, B)  // !p -:= !q*wk
         mcMR(mc_sub, @idata!q, C)
       }
  ELSE TEST rwk=0 & iwk=1_000000000  & FALSE
  THEN { // wk = i
         mcRM(mc_mv,  B, @idata!q)
         mcRM(mc_mv,  C, @rdata!q)
         mcR (mc_neg, B)
         mcMR(mc_add, @rdata!p, B)  // !p +:= !q*wk
         mcMR(mc_add, @idata!p, C)
         mcMR(mc_sub, @rdata!q, B)  // !p -:= !q*wk
         mcMR(mc_sub, @idata!q, C)
       }
  ELSE TEST rwk=-1_000000000 & iwk=0
  THEN { // wk = -1
         mcRM(mc_mv,  B, @rdata!q)
         mcR (mc_neg, B)
         mcRM(mc_mv,  C, @idata!q)
         mcR (mc_neg, C)
         mcMR(mc_add, @rdata!p, B)  // !p +:= !q*wk
         mcMR(mc_add, @idata!p, C)
         mcMR(mc_sub, @rdata!q, B)  // !p -:= !q*wk
         mcMR(mc_sub, @idata!q, C)
       }
  ELSE TEST rwk=0 & iwk=-1_000000000 & FALSE
  THEN { // wk = -i
         mcRM(mc_mv,  B, @idata!q)
         mcRM(mc_mv,  C, @rdata!q)
         mcR (mc_neg, C)
         mcRM(mc_add, @rdata!p, B)  // !p +:= !q*wk
         mcRM(mc_add, @idata!p, C)
         mcRM(mc_sub, @rdata!q, B)  // !p -:= !q*wk
         mcRM(mc_sub, @idata!q, C)
       }
  ELSE { mcRM(mc_mv, D, @rdata!q)
         mcK (mc_mul, rwk)          // A:D := D * rwk
         mcK (mc_div, 1_000000000)  // A := A:D / 1_000000000
         mcRR(mc_mv, B, A)
         mcMR(mc_mv, @idata!q, D)
         mcK (mc_mul, iwk)          // A:D := D * iwk
         mcK (mc_div, 1_000000000)  // A := A:D / 1_000000000
         mcRR(mc_sub, B, A)         // B := re(!q*wk)

         mcRM(mc_mv, D, @rdata!q)
         mcK (mc_mul, iwk)          // A:D := D * iwk
         mcK (mc_div, 1_000000000)  // A := A:D / 1_000000000
         mcRR(mc_mv, C, A)
         mcRM(mc_mv, D, @idata!q)
         mcK (mc_mul, rwk)          // A:D := D * rwk
         mcK (mc_div, 1_000000000)  // A := A:D / 1_000000000
         mcRR(mc_sub, C, A)         // C := im(!q*wk)
         mcMR(mc_add, @rdata!p, B)  // !p +:= !q*wk
         mcMR(mc_add, @idata!p, C)
         mcMR(mc_sub, @rdata!q, C)  // !p -:= !q*wk
         mcMR(mc_sub, @idata!q, C)
       }
}

AND genreorder(rv, iv, n) BE
{ LET j = 0
  FOR i = 0 TO n-2 DO
  { LET k = n>>1
    // j is i with its bits is reverse order
    IF i<j DO
    { writef("// swap: %i4 %i4*n", i, j)
      mcRM(mc_mv,   A, @rv!i)
      mcRM(mc_mv,   B, @iv!i)
      mcRM(mc_mv,   C, @rv!j)
      mcRM(mc_mv,   D, @iv!j)
//mcPRF("Swapping %9.3d", A)
//mcPRF("+%9.3di", B)
//mcPRF(" with %9.3d", C)
//mcPRF("+%9.3di*n", D)
      mcMR(mc_mv,   @rv!i, C)
      mcMR(mc_mv,   @iv!i, D)
      mcMR(mc_mv,   @rv!j, A)
      mcMR(mc_mv,   @iv!j, B)
    }
    // k  =  100..00       10..0000..00
    // j  =  0xx..xx       11..10xx..xx
    // j' =  1xx..xx       00..01xx..xx
    // k' =  100..00       00..0100..00
    WHILE k<=j DO { j := j-k; k := k>>1 } //) "increment" j
    j := j+k                              //)
  }
}

AND pr(rv, iv, max) BE
{ FOR i = 0 TO max DO { writef("(%8.3d+%8.3di) ", rv!i, iv!i)
                        IF i REM 4 = 3 DO newline()
                      }
  newline()
}

AND mul(rx, ix, ry, iy) = VALOF
{ LET res =  muldiv(rx, ry, 1_000000000) - muldiv(ix, iy, 1_000000000)
  result2 := muldiv(rx, iy, 1_000000000) + muldiv(ix, ry, 1_000000000)
  RESULTIS res
}

