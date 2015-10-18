/*

This is an implementation of the Discrete Fourier Transform that
computes the cosine and sine series representing the complex results
of applying the transform. It also computes the inverse transform.

This program is primarily intended for checking the accuracy of the
fast fft algorithm (mcfft.b). If uses the MC package to dynamically
generate native code.

Implemented by Martin Richards (c) April 2008

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

 a1=1; a2
}


MANIFEST {

K = 12       // N=4096
//K = 10
//K = 4
//K = 3
//K = 2

N       = 1<<K    // N = 2^K
upb     = N-1     // UPB of data vectors
}

STATIC {
 rdata=0      // real components
 idata=0      // imaginary components
 rres=0       // real components of the result
 ires=0       // imaginary components of the result
 prupb = upb  // Upper bound for printing
}

// sin(a)/4 returns sine((2*pi)*(a/4096))/4 as a signed fraction.
// The values are rounded.

LET sinby4(a) = VALOF
{ LET sintab = TABLE
  #x00000000,#x001921fb,#x003243f1,#x004b65e1,#x006487c4,#x007da998,#x0096cb58,
  #x00afed02,#x00c90e90,#x00e22fff,#x00fb514b,#x01147271,#x012d936c,#x0146b438,
  #x015fd4d2,#x0178f536,#x0192155f,#x01ab354b,#x01c454f5,#x01dd7459,#x01f69373,
  #x020fb240,#x0228d0bb,#x0241eee2,#x025b0caf,#x02742a1f,#x028d472e,#x02a663d8,
  #x02bf801a,#x02d89bf0,#x02f1b755,#x030ad245,#x0323ecbe,#x033d06bb,#x03562038,
  #x036f3931,#x038851a2,#x03a16988,#x03ba80df,#x03d397a3,#x03ecadcf,#x0405c361,
  #x041ed854,#x0437eca4,#x0451004d,#x046a134c,#x0483259d,#x049c373c,#x04b54825,
  #x04ce5854,#x04e767c5,#x05007674,#x0519845e,#x0532917f,#x054b9dd3,#x0564a955,
  #x057db403,#x0596bdd7,#x05afc6d0,#x05c8cee7,#x05e1d61b,#x05fadc66,#x0613e1c5,
  #x062ce634,#x0645e9af,#x065eec33,#x0677edbb,#x0690ee44,#x06a9edc9,#x06c2ec48,
  #x06dbe9bb,#x06f4e620,#x070de172,#x0726dbae,#x073fd4cf,#x0758ccd2,#x0771c3b3,
  #x078ab96e,#x07a3adff,#x07bca163,#x07d59396,#x07ee8493,#x08077457,#x082062de,
  #x08395024,#x08523c25,#x086b26de,#x0884104b,#x089cf867,#x08b5df30,#x08cec4a0,
  #x08e7a8b5,#x09008b6a,#x09196cbc,#x09324ca7,#x094b2b27,#x09640837,#x097ce3d5,
  #x0995bdfd,#x09ae96aa,#x09c76dd8,#x09e04385,#x09f917ac,#x0a11ea49,#x0a2abb59,
  #x0a438ad7,#x0a5c58c0,#x0a752510,#x0a8defc3,#x0aa6b8d5,#x0abf8043,#x0ad84609,
  #x0af10a22,#x0b09cc8c,#x0b228d42,#x0b3b4c40,#x0b540982,#x0b6cc506,#x0b857ec7,
  #x0b9e36c0,#x0bb6ecef,#x0bcfa150,#x0be853de,#x0c010496,#x0c19b374,#x0c326075,
  #x0c4b0b94,#x0c63b4ce,#x0c7c5c1e,#x0c950182,#x0cada4f5,#x0cc64673,#x0cdee5f9,
  #x0cf78383,#x0d101f0e,#x0d28b894,#x0d415013,#x0d59e586,#x0d7278eb,#x0d8b0a3d,
  #x0da39978,#x0dbc2698,#x0dd4b19a,#x0ded3a7b,#x0e05c135,#x0e1e45c6,#x0e36c82a,
  #x0e4f485c,#x0e67c65a,#x0e80421e,#x0e98bba7,#x0eb132ef,#x0ec9a7f3,#x0ee21aaf,
  #x0efa8b20,#x0f12f941,#x0f2b650f,#x0f43ce86,#x0f5c35a3,#x0f749a61,#x0f8cfcbe,
  #x0fa55cb4,#x0fbdba40,#x0fd6155f,#x0fee6e0d,#x1006c446,#x101f1807,#x1037694b,
  #x104fb80e,#x1068044e,#x10804e06,#x10989532,#x10b0d9d0,#x10c91bda,#x10e15b4e,
  #x10f99827,#x1111d263,#x112a09fc,#x11423ef0,#x115a713a,#x1172a0d7,#x118acdc4,
  #x11a2f7fc,#x11bb1f7c,#x11d3443f,#x11eb6643,#x12038584,#x121ba1fd,#x1233bbac,
  #x124bd28c,#x1263e699,#x127bf7d1,#x1294062f,#x12ac11af,#x12c41a4f,#x12dc2009,
  #x12f422db,#x130c22c1,#x13241fb6,#x133c19b8,#x135410c3,#x136c04d2,#x1383f5e3,
  #x139be3f2,#x13b3cefa,#x13cbb6f8,#x13e39be9,#x13fb7dc9,#x14135c94,#x142b3846,
  #x144310dd,#x145ae653,#x1472b8a5,#x148a87d1,#x14a253d1,#x14ba1ca3,#x14d1e242,
  #x14e9a4ac,#x150163dc,#x15191fcf,#x1530d881,#x15488dee,#x15604013,#x1577eeec,
  #x158f9a76,#x15a742ac,#x15bee78c,#x15d68911,#x15ee2738,#x1605c1fd,#x161d595d,
  #x1634ed53,#x164c7ddd,#x16640af7,#x167b949d,#x16931acb,#x16aa9d7e,#x16c21cb2,
  #x16d99864,#x16f1108f,#x17088531,#x171ff646,#x173763c9,#x174ecdb8,#x1766340f,
  #x177d96ca,#x1794f5e6,#x17ac515f,#x17c3a931,#x17dafd59,#x17f24dd3,#x18099a9c,
  #x1820e3b0,#x1838290c,#x184f6aab,#x1866a88a,#x187de2a7,#x189518fc,#x18ac4b87,
  #x18c37a44,#x18daa52f,#x18f1cc45,#x1908ef82,#x19200ee3,#x19372a64,#x194e4201,
  #x196555b8,#x197c6584,#x19937161,#x19aa794d,#x19c17d44,#x19d87d42,#x19ef7944,
  #x1a067145,#x1a1d6544,#x1a34553b,#x1a4b4128,#x1a622907,#x1a790cd4,#x1a8fec8c,
  #x1aa6c82b,#x1abd9faf,#x1ad47312,#x1aeb4253,#x1b020d6c,#x1b18d45c,#x1b2f971e,
  #x1b4655ae,#x1b5d100a,#x1b73c62d,#x1b8a7815,#x1ba125bd,#x1bb7cf23,#x1bce7442,
  #x1be51518,#x1bfbb1a0,#x1c1249d8,#x1c28ddbb,#x1c3f6d47,#x1c55f878,#x1c6c7f4a,
  #x1c8301b9,#x1c997fc4,#x1caff965,#x1cc66e99,#x1cdcdf5e,#x1cf34baf,#x1d09b389,
  #x1d2016e9,#x1d3675cb,#x1d4cd02c,#x1d632608,#x1d79775c,#x1d8fc424,#x1da60c5d,
  #x1dbc5004,#x1dd28f15,#x1de8c98c,#x1dfeff67,#x1e1530a1,#x1e2b5d38,#x1e418528,
  #x1e57a86d,#x1e6dc705,#x1e83e0eb,#x1e99f61d,#x1eb00696,#x1ec61254,#x1edc1953,
  #x1ef21b90,#x1f081907,#x1f1e11b5,#x1f340596,#x1f49f4a8,#x1f5fdee6,#x1f75c44e,
  #x1f8ba4dc,#x1fa1808c,#x1fb7575c,#x1fcd2948,#x1fe2f64c,#x1ff8be65,#x200e8190,
  #x20243fca,#x2039f90f,#x204fad5b,#x20655cac,#x207b06fe,#x2090ac4d,#x20a64c97,
  #x20bbe7d8,#x20d17e0d,#x20e70f32,#x20fc9b44,#x21122240,#x2127a423,#x213d20e8,
  #x2152988d,#x21680b0f,#x217d786a,#x2192e09b,#x21a8439e,#x21bda171,#x21d2fa0f,
  #x21e84d76,#x21fd9ba3,#x2212e492,#x2228283f,#x223d66a8,#x22529fca,#x2267d3a0,
  #x227d0228,#x22922b5e,#x22a74f40,#x22bc6dca,#x22d186f8,#x22e69ac8,#x22fba936,
  #x2310b23e,#x2325b5df,#x233ab414,#x234facda,#x2364a02e,#x23798e0d,#x238e7673,
  #x23a3595e,#x23b836ca,#x23cd0eb3,#x23e1e117,#x23f6adf3,#x240b7543,#x24203704,
  #x2434f332,#x2449a9cc,#x245e5acc,#x24730631,#x2487abf7,#x249c4c1b,#x24b0e699,
  #x24c57b6f,#x24da0a9a,#x24ee9415,#x250317df,#x251795f3,#x252c0e4f,#x254080ef,
  #x2554edd1,#x256954f1,#x257db64c,#x259211df,#x25a667a7,#x25bab7a0,#x25cf01c8,
  #x25e3461b,#x25f78497,#x260bbd37,#x261feffa,#x26341cdb,#x264843d9,#x265c64ef,
  #x2670801a,#x26849558,#x2698a4a6,#x26acadff,#x26c0b162,#x26d4aecb,#x26e8a637,
  #x26fc97a3,#x2710830c,#x2724686e,#x273847c8,#x274c2115,#x275ff452,#x2773c17d,
  #x27878893,#x279b4990,#x27af0472,#x27c2b934,#x27d667d5,#x27ea1052,#x27fdb2a7,
  #x28114ed0,#x2824e4cc,#x28387498,#x284bfe2f,#x285f8190,#x2872feb6,#x288675a0,
  #x2899e64a,#x28ad50b1,#x28c0b4d2,#x28d412ab,#x28e76a37,#x28fabb75,#x290e0661,
  #x29214af8,#x29348937,#x2947c11c,#x295af2a3,#x296e1dc9,#x2981428c,#x299460e8,
  #x29a778db,#x29ba8a61,#x29cd9578,#x29e09a1c,#x29f3984c,#x2a069003,#x2a19813f,
  #x2a2c6bfd,#x2a3f503a,#x2a522df3,#x2a650525,#x2a77d5ce,#x2a8a9fea,#x2a9d6377,
  #x2ab02071,#x2ac2d6d6,#x2ad586a3,#x2ae82fd5,#x2afad269,#x2b0d6e5c,#x2b2003ac,
  #x2b329255,#x2b451a55,#x2b579ba8,#x2b6a164d,#x2b7c8a3f,#x2b8ef77d,#x2ba15e03,
  #x2bb3bdce,#x2bc616dd,#x2bd8692b,#x2beab4b6,#x2bfcf97c,#x2c0f3779,#x2c216eaa,
  #x2c339f0e,#x2c45c8a0,#x2c57eb5e,#x2c6a0746,#x2c7c1c55,#x2c8e2a87,#x2ca031da,
  #x2cb2324c,#x2cc42bd9,#x2cd61e7f,#x2ce80a3a,#x2cf9ef09,#x2d0bcce8,#x2d1da3d5,
  #x2d2f73cd,#x2d413ccd,#x2d52fed2,#x2d64b9da,#x2d766de2,#x2d881ae8,#x2d99c0e7,
  #x2dab5fdf,#x2dbcf7cb,#x2dce88aa,#x2de01278,#x2df19534,#x2e0310d9,#x2e148566,
  #x2e25f2d8,#x2e37592c,#x2e48b860,#x2e5a1070,#x2e6b615a,#x2e7cab1c,#x2e8dedb3,
  #x2e9f291b,#x2eb05d53,#x2ec18a58,#x2ed2b027,#x2ee3cebe,#x2ef4e619,#x2f05f637,
  #x2f16ff14,#x2f2800af,#x2f38fb03,#x2f49ee0f,#x2f5ad9d1,#x2f6bbe45,#x2f7c9b69,
  #x2f8d713a,#x2f9e3fb6,#x2faf06da,#x2fbfc6a3,#x2fd07f0f,#x2fe1301c,#x2ff1d9c7,
  #x30027c0c,#x301316eb,#x3023aa5f,#x30343667,#x3044bb00,#x30553828,#x3065addb,
  #x30761c18,#x308682dc,#x3096e223,#x30a739ed,#x30b78a36,#x30c7d2fb,#x30d8143b,
  #x30e84df3,#x30f8801f,#x3108aabf,#x3118cdcf,#x3128e94c,#x3138fd35,#x31490986,
  #x31590e3e,#x31690b59,#x317900d6,#x3188eeb2,#x3198d4ea,#x31a8b37c,#x31b88a66,
  #x31c859a5,#x31d82137,#x31e7e118,#x31f79948,#x320749c3,#x3216f287,#x32269391,
  #x32362ce0,#x3245be70,#x32554840,#x3264ca4c,#x32744493,#x3283b712,#x329321c7,
  #x32a284b0,#x32b1dfc9,#x32c13311,#x32d07e85,#x32dfc224,#x32eefdea,#x32fe31d5,
  #x330d5de3,#x331c8211,#x332b9e5e,#x333ab2c6,#x3349bf48,#x3358c3e2,#x3367c090,
  #x3376b551,#x3385a222,#x33948701,#x33a363ec,#x33b238e0,#x33c105db,#x33cfcadc,
  #x33de87de,#x33ed3ce1,#x33fbe9e2,#x340a8edf,#x34192bd5,#x3427c0c3,#x34364da6,
  #x3444d27b,#x34534f41,#x3461c3f5,#x34703095,#x347e951f,#x348cf190,#x349b45e7,
  #x34a99221,#x34b7d63c,#x34c61236,#x34d4460c,#x34e271bd,#x34f09546,#x34feb0a5,
  #x350cc3d8,#x351acedd,#x3528d1b1,#x3536cc52,#x3544bebf,#x3552a8f4,#x35608af1,
  #x356e64b2,#x357c3636,#x3589ff7a,#x3597c07d,#x35a5793c,#x35b329b5,#x35c0d1e7,
  #x35ce71ce,#x35dc0968,#x35e998b5,#x35f71fb1,#x36049e5b,#x361214b0,#x361f82af,
  #x362ce855,#x363a45a0,#x36479a8e,#x3654e71d,#x36622b4c,#x366f6717,#x367c9a7e,
  #x3689c57d,#x3696e814,#x36a4023f,#x36b113fd,#x36be1d4c,#x36cb1e2a,#x36d81695,
  #x36e5068a,#x36f1ee09,#x36fecd0e,#x370ba398,#x371871a5,#x37253733,#x3731f440,
  #x373ea8ca,#x374b54ce,#x3757f84c,#x37649341,#x377125ac,#x377daf89,#x378a30d8,
  #x3796a996,#x37a319c2,#x37af8159,#x37bbe05a,#x37c836c2,#x37d48490,#x37e0c9c3,
  #x37ed0657,#x37f93a4b,#x3805659e,#x3811884d,#x381da256,#x3829b3b9,#x3835bc71,
  #x3841bc7f,#x384db3e0,#x3859a292,#x38658894,#x387165e3,#x387d3a7e,#x38890663,
  #x3894c98f,#x38a08402,#x38ac35ba,#x38b7deb4,#x38c37eef,#x38cf1669,#x38daa520,
  #x38e62b13,#x38f1a840,#x38fd1ca4,#x3908883f,#x3913eb0e,#x391f4510,#x392a9642,
  #x3935dea4,#x39411e33,#x394c54ee,#x395782d3,#x3962a7e0,#x396dc414,#x3978d76c,
  #x3983e1e8,#x398ee385,#x3999dc42,#x39a4cc1c,#x39afb313,#x39ba9125,#x39c5664f,
  #x39d03291,#x39daf5e8,#x39e5b054,#x39f061d2,#x39fb0a60,#x3a05a9fd,#x3a1040a8,
  #x3a1ace5f,#x3a25531f,#x3a2fcee8,#x3a3a41b9,#x3a44ab8e,#x3a4f0c67,#x3a596442,
  #x3a63b31d,#x3a6df8f8,#x3a7835cf,#x3a8269a3,#x3a8c9470,#x3a96b636,#x3aa0cef3,
  #x3aaadea6,#x3ab4e54c,#x3abee2e5,#x3ac8d76f,#x3ad2c2e8,#x3adca54e,#x3ae67ea1,
  #x3af04edf,#x3afa1605,#x3b03d414,#x3b0d8909,#x3b1734e2,#x3b20d79e,#x3b2a713d,
  #x3b3401bb,#x3b3d8918,#x3b470753,#x3b507c69,#x3b59e85a,#x3b634b23,#x3b6ca4c4,
  #x3b75f53c,#x3b7f3c87,#x3b887aa6,#x3b91af97,#x3b9adb57,#x3ba3fde7,#x3bad1744,
  #x3bb6276e,#x3bbf2e62,#x3bc82c1f,#x3bd120a4,#x3bda0bf0,#x3be2ee01,#x3bebc6d5,
  #x3bf4966c,#x3bfd5cc4,#x3c0619dc,#x3c0ecdb2,#x3c177845,#x3c201994,#x3c28b19e,
  #x3c314060,#x3c39c5da,#x3c42420a,#x3c4ab4ef,#x3c531e88,#x3c5b7ed4,#x3c63d5d1,
  #x3c6c237e,#x3c7467d9,#x3c7ca2e2,#x3c84d496,#x3c8cfcf6,#x3c951bff,#x3c9d31b0,
  #x3ca53e09,#x3cad4107,#x3cb53aaa,#x3cbd2af0,#x3cc511d9,#x3cccef62,#x3cd4c38b,
  #x3cdc8e52,#x3ce44fb7,#x3cec07b8,#x3cf3b653,#x3cfb5b89,#x3d02f757,#x3d0a89bc,
  #x3d1212b7,#x3d199248,#x3d21086c,#x3d287523,#x3d2fd86c,#x3d373245,#x3d3e82ae,
  #x3d45c9a4,#x3d4d0728,#x3d543b37,#x3d5b65d2,#x3d6286f6,#x3d699ea3,#x3d70acd7,
  #x3d77b192,#x3d7eacd2,#x3d859e96,#x3d8c86de,#x3d9365a8,#x3d9a3af2,#x3da106bd,
  #x3da7c907,#x3dae81cf,#x3db53113,#x3dbbd6d4,#x3dc2730f,#x3dc905c5,#x3dcf8ef3,
  #x3dd60e99,#x3ddc84b5,#x3de2f148,#x3de9544f,#x3defadca,#x3df5fdb8,#x3dfc4418,
  #x3e0280e9,#x3e08b42a,#x3e0eddd9,#x3e14fdf7,#x3e1b1482,#x3e212179,#x3e2724db,
  #x3e2d1ea8,#x3e330ede,#x3e38f57c,#x3e3ed282,#x3e44a5ef,#x3e4a6fc1,#x3e502ff9,
  #x3e55e694,#x3e5b9392,#x3e6136f3,#x3e66d0b4,#x3e6c60d7,#x3e71e759,#x3e77643a,
  #x3e7cd778,#x3e824114,#x3e87a10c,#x3e8cf75f,#x3e92440d,#x3e978715,#x3e9cc076,
  #x3ea1f02f,#x3ea7163f,#x3eac32a6,#x3eb14563,#x3eb64e75,#x3ebb4ddb,#x3ec04394,
  #x3ec52fa0,#x3eca11fe,#x3eceeaad,#x3ed3b9ad,#x3ed87efc,#x3edd3a9a,#x3ee1ec87,
  #x3ee694c1,#x3eeb3347,#x3eefc81a,#x3ef45338,#x3ef8d4a1,#x3efd4c54,#x3f01ba50,
  #x3f061e95,#x3f0a7921,#x3f0ec9f5,#x3f13110f,#x3f174e70,#x3f1b8215,#x3f1fabff,
  #x3f23cc2e,#x3f27e29f,#x3f2bef53,#x3f2ff24a,#x3f33eb81,#x3f37dafa,#x3f3bc0b3,
  #x3f3f9cab,#x3f436ee3,#x3f473759,#x3f4af60d,#x3f4eaafe,#x3f52562c,#x3f55f796,
  #x3f598f3c,#x3f5d1d1d,#x3f60a138,#x3f641b8d,#x3f678c1c,#x3f6af2e3,#x3f6e4fe3,
  #x3f71a31b,#x3f74ec8a,#x3f782c30,#x3f7b620c,#x3f7e8e1e,#x3f81b065,#x3f84c8e2,
  #x3f87d792,#x3f8adc77,#x3f8dd78f,#x3f90c8da,#x3f93b058,#x3f968e07,#x3f9961e8,
  #x3f9c2bfb,#x3f9eec3e,#x3fa1a2b2,#x3fa44f55,#x3fa6f228,#x3fa98b2a,#x3fac1a5b,
  #x3fae9fbb,#x3fb11b48,#x3fb38d02,#x3fb5f4ea,#x3fb852ff,#x3fbaa740,#x3fbcf1ad,
  #x3fbf3246,#x3fc1690a,#x3fc395f9,#x3fc5b913,#x3fc7d258,#x3fc9e1c6,#x3fcbe75e,
  #x3fcde320,#x3fcfd50b,#x3fd1bd1e,#x3fd39b5a,#x3fd56fbe,#x3fd73a4a,#x3fd8fafe,
  #x3fdab1d9,#x3fdc5edc,#x3fde0205,#x3fdf9b55,#x3fe12acb,#x3fe2b067,#x3fe42c2a,
  #x3fe59e12,#x3fe7061f,#x3fe86452,#x3fe9b8a9,#x3feb0326,#x3fec43c7,#x3fed7a8c,
  #x3feea776,#x3fefca84,#x3ff0e3b6,#x3ff1f30b,#x3ff2f884,#x3ff3f420,#x3ff4e5e0,
  #x3ff5cdc3,#x3ff6abc8,#x3ff77ff1,#x3ff84a3c,#x3ff90aaa,#x3ff9c13a,#x3ffa6dec,
  #x3ffb10c1,#x3ffba9b8,#x3ffc38d1,#x3ffcbe0c,#x3ffd3969,#x3ffdaae7,#x3ffe1288,
  #x3ffe704a,#x3ffec42d,#x3fff0e32,#x3fff4e59,#x3fff84a1,#x3fffb10b,#x3fffd396,
  #x3fffec43,#x3ffffb11,#x40000000
  LET i = a & #x3FF
  LET q = (a>>10) & 3
  SWITCHON q INTO
  { CASE 0: RESULTIS sintab!i
    CASE 1: RESULTIS sintab!(1024-i)
    CASE 2: RESULTIS -sintab!i
    CASE 3: RESULTIS -sintab!(1024-i)
  }
}

LET cosby4(a) = sinby4(1024+a)

LET start() = VALOF
{ // Load the dynamic code generation package
  LET mcseg = globin(loadseg("mci386"))
  LET mcb = 0

writef("*nmcfftslow entered K=%n N=%n*n", K, N)

  UNLESS mcseg DO
  { sawritef("Trouble with MC package: mci386*n")
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

  prupb := upb>63 -> 63, upb

  rdata := getvec(upb)
  idata := getvec(upb)
  rres  := getvec(upb)
  ires  := getvec(upb)

  mcK(mc_debug, #b0000)

  genfracmul(1) // Create F1(frac, x, y) = (frac*x)/2^32  unsigned
                // where frac is a 32-bit fraction
  mcF(mc_end)   // End of code generation

  // Set the initial data
  FOR i = 0 TO upb DO
  { rdata!i, idata!i := (i & 8) = 0 -> i*25, -i*25, 0
    rres!i, ires!i := 0, 0
  }

  writef("*nOriginal data*n")

  pr(rdata, idata, prupb)
/*
prints  -- Original data
(       0,       0)(      25,       0)(      50,       0)(      75,       0)
(     100,       0)(     125,       0)(     150,       0)(     175,       0)
(    -200,       0)(    -225,       0)(    -250,       0)(    -275,       0)
(    -300,       0)(    -325,       0)(    -350,       0)(    -375,       0)
(     400,       0)(     425,       0)(     450,       0)(     475,       0)
(     500,       0)(     525,       0)(     550,       0)(     575,       0)
(    -600,       0)(    -625,       0)(    -650,       0)(    -675,       0)
(    -700,       0)(    -725,       0)(    -750,       0)(    -775,       0)
(     800,       0)(     825,       0)(     850,       0)(     875,       0)
(     900,       0)(     925,       0)(     950,       0)(     975,       0)
(   -1000,       0)(   -1025,       0)(   -1050,       0)(   -1075,       0)
(   -1100,       0)(   -1125,       0)(   -1150,       0)(   -1175,       0)
(    1200,       0)(    1225,       0)(    1250,       0)(    1275,       0)
(    1300,       0)(    1325,       0)(    1350,       0)(    1375,       0)
(   -1400,       0)(   -1425,       0)(   -1450,       0)(   -1475,       0)
(   -1500,       0)(   -1525,       0)(   -1550,       0)(   -1575,       0)
*/
  fft(rdata, idata, rres, ires, FALSE)

  writef("*nTransformed data*n")

  pr(rres, ires, prupb)
/*
prints   -- Transformed data
( -409600,       0)( -409607,     301)( -409587,     634)( -409623,     932)
( -409686,    1247)( -409729,    1573)( -409781,    1876)( -409834,    2182)
( -409953,    2465)( -409975,    2826)( -410138,    3166)( -410200,    3478)
( -410328,    3783)( -410471,    4073)( -410598,    4397)( -410732,    4760)
( -410900,    5046)( -411069,    5391)( -411238,    5702)( -411470,    5987)
( -411663,    6314)( -411846,    6655)( -412063,    6922)( -412306,    7274)
( -412533,    7604)( -412811,    7906)( -413053,    8237)( -413348,    8518)
( -413577,    8913)( -413917,    9217)( -414228,    9567)( -414563,    9872)
( -414881,   10163)( -415205,   10523)( -415565,   10847)( -415956,   11169)
( -416296,   11493)( -416693,   11809)( -417082,   12158)( -417467,   12506)
( -417897,   12823)( -418314,   13144)( -418768,   13533)( -419197,   13837)
( -419687,   14202)( -420177,   14539)( -420659,   14848)( -421181,   15173)
( -421678,   15528)( -422229,   15887)( -422733,   16243)( -423305,   16557)
( -423887,   16916)( -424463,   17248)( -425037,   17593)( -425630,   17950)
( -426238,   18336)( -426907,   18659)( -427537,   19032)( -428180,   19389)
( -428882,   19780)( -429552,   20122)( -430272,   20475)( -430969,   20860)
*/

  // Try filtering off the higher frequencies
  //FOR i = N/2 TO upb DO rres!i, ires!i := 0, 0

  fft(rres, ires, rdata, idata, TRUE)

  writef("*nData after applying the inverse transform*n")

  pr(rdata, idata, prupb)
/*
prints   -- Data after applying the inverse transform
(       0,       0)(      24,       0)(      50,       0)(      74,       0)
(     100,       0)(     124,       0)(     150,       0)(     174,       0)
(    -199,       0)(    -224,       0)(    -249,       0)(    -275,       0)
(    -300,       0)(    -325,       0)(    -349,       0)(    -375,       0)
(     400,       0)(     424,       0)(     450,       0)(     475,       0)
(     500,       0)(     524,       0)(     550,       0)(     574,       0)
(    -599,       0)(    -624,       0)(    -649,       0)(    -675,       0)
(    -700,       0)(    -724,       0)(    -749,       0)(    -775,       0)
(     800,       0)(     824,       0)(     850,       0)(     875,       0)
(     900,       0)(     924,       0)(     949,       0)(     975,       0)
(   -1000,       0)(   -1024,       0)(   -1049,       0)(   -1075,       0)
(   -1099,       0)(   -1124,       0)(   -1149,       0)(   -1174,       0)
(    1200,       0)(    1225,       0)(    1250,       0)(    1274,       0)
(    1300,       0)(    1324,       0)(    1350,       0)(    1374,       0)
(   -1399,       0)(   -1424,       0)(   -1450,       0)(   -1475,       0)
(   -1499,       0)(   -1524,       0)(   -1550,       0)(   -1574,       0)
*/

fin:
  IF mcseg DO unloadseg(mcseg)  
  RESULTIS 0
}

AND fft(rd, id, rr, ir, inv) BE
{ // Compute the fourier transform if inv=FALSE
  // Compute the inverse fourier transform if inv=TRUE
  LET a  = 4096/N // cos a + i sin a = w = Nth root of unity
  IF inv DO a := 4096-a // For inverse transform use the inverse root

  FOR k = 0 TO upb DO
  { LET ak = a*k // angle corresponding to w^-k or w^k
    LET re, im = 0, 0

//writef("N=%n  a=%n cosby=%x8 sinby4=%x8*n",
//        N, ak, cosby4(a), sinby4(a))
    FOR i = 0 TO upb DO
    { LET ai = ak * i // angle corresponding to (w^k)^i or (w^-k)^i
      LET sby4 = sinby4(ai)
      LET cby4 = cosby4(ai)
      LET x  = rd!i
      LET y  = id!i
      LET x4 = x * 4
      LET y4 = y * 4
      LET xc = mcCall(1, cby4, x4)
      LET yc = mcCall(1, cby4, y4)
      LET xs = mcCall(1, sby4, x4)
      LET ys = mcCall(1, sby4, y4)
      re := re + xc - ys      // ie add: x*cos ai - y*sin ai
      im := im + xs + yc      // ie add: x*sin ai + y*cos ai
                     
//writef("re=%8i, im=%8i*n", re, im)
    }
//newline()
    TEST inv
    THEN rr!k, ir!k := re/N, im/N
    ELSE rr!k, ir!k := re, im
  }
}

AND genfracmul(fno, frac, x, y) BE
{ // Return the rounded integer result of multiplying signed
  // fraction frac by signed integer x.
  mcKKK(mc_entry, fno, 3, 0)
  mcRA( mc_mv,  A, a1)
  mcA(  mc_mul, a2)      // D:A := a1 + a2
  mcRK( mc_rsh, A, 31)
  mcRR( mc_add, A, D)    // return rounded senior 32-bits
  mcF(mc_rtn)
  mcF(mc_endfn)
}

AND pr(rv, iv, max) BE
{ FOR i = 0 TO max DO { writef("(%8i,%8i)", rv!i, iv!i)
                        IF i REM 4 = 3 DO newline()
                      }
  newline()
}

