/*
This defined the function drawtegermoth() used by draw3d.b and tiger.b

Implemented by Martin Richards (c) January 2013
*/

LET drawtigermoth() BE
{
  // The origin is the centre of gravity

  // Cockpit floor
  setcolour(maprgb(90,80,30))
  cdrawquad3d (1_000, 0_800, 0_000,
               1_000,-0_800, 0_000,
              -5_800,-0_800, 0_000,
              -5_800, 0_800, 0_000)

  // Left lower wing
  setcolour(maprgb(165,165,30))        // Under surface

  cdrawquad3d(-0_500,  1_000, -2_000,  // Panel A
              -3_767,  1_000, -2_218,
              -4_396,  6_000, -1_745, 
              -1_129,  6_000, -1_527)

  cdrawquad3d(-3_767,  1_000, -2_218,  // Panel B
              -4_917,  1_000, -2_294,
              -5_546,  6_000, -1_821,
              -4_396,  6_000, -1_745) 

  cdrawquad3d(-1_129,  6_000, -1_527,  // Panel C
              -4_396,  6_000, -1_745,
              -5_147, 14_166, -1_179,
              -1_880, 14_166, -0_961)

  { // Aileron deflection 1 inch from hinge
    LET a = muldiv(0_600, c_aileron, 32_768*17)

    setcolour(maprgb(155,155,20))            // Under surface
    cdrawquad3d(-4_396,      6_000, -1_745,  // Panel D Aileron
                -5_546+3*a,  6_000, -1_821-14*a,
                -6_297+3*a, 13_766, -1_255-14*a,
                -5_147,     14_166, -1_179)
  }

  // Left lower wing upper surface
  setcolour(maprgb(120,140,60))

  cdrawquad3d(-0_500,  1_000, -2_000,  // Panel A1
              -1_500,  1_000, -1_800,
              -2_129,  6_000, -1_327, 
              -1_129,  6_000, -1_527)

  setcolour(maprgb(120,130,50))
  cdrawquad3d(-1_500,  1_000, -1_800,  // Panel A2
              -3_767,  1_000, -2_118,
              -4_396,  6_000, -1_645, 
              -2_129,  6_000, -1_327)

  cdrawquad3d(-3_767,  1_000, -2_118,  // Panel B
              -4_917,  1_000, -2_294,
              -5_546,  6_000, -1_821,
              -4_396,  6_000, -1_645) 

  setcolour(maprgb(120,140,60))
  cdrawquad3d(-1_129,  6_000, -1_527,  // Panel C1
              -2_129,  6_000, -1_327,
              -2_880, 14_166, -0_761,
              -1_880, 14_166, -0_961)

  setcolour(maprgb(120,130,50))
  cdrawquad3d(-2_129,  6_000, -1_327,  // Panel C2
              -4_396,  6_000, -1_645,
              -5_147, 14_166, -1_079,
              -2_880, 14_166, -0_761)

  { // Aileron deflection 1 inch from hinge
    LET a = muldiv(0_600, c_aileron, 32_768*17)

    setcolour(maprgb(120,140,60))
    cdrawquad3d(-4_396,      6_000, -1_645,  // Panel D Aileron
                -5_546+3*a,  6_000, -1_821-14*a,
                -6_297+3*a, 13_766, -1_255-14*a,
                -5_147,     14_166, -0_979)
  }

  // Left lower wing tip
  setcolour(maprgb(130,150,60))
  cdrawtriangle3d(-1_880, 14_167,-1_006,
                  -2_880, 14_167,-0_761,
                  -3_880, 14_467,-0_980)
  setcolour(maprgb(130,150,60))
  cdrawtriangle3d(-2_880, 14_167,-0_761,
                  -5_147, 14_167,-1_079,
                  -3_880, 14_467,-0_980)
  setcolour(maprgb(160,160,40))
  cdrawtriangle3d(-5_147, 14_167,-1_079,
                  -5_147, 14_167,-1_179,
                  -3_880, 14_467,-0_980)
  setcolour(maprgb(170,170,50))
  cdrawtriangle3d(-5_147, 14_167,-1_179,
                  -1_880, 14_167,-0_961,
                  -3_880, 14_467,-0_980)

  // Right lower wing
  setcolour(maprgb(165,165,30))        // Under surface

  cdrawquad3d(-0_500, -1_000, -2_000,  // Panel A
              -3_767, -1_000, -2_218,
              -4_396, -6_000, -1_745, 
              -1_129, -6_000, -1_527)

  cdrawquad3d(-3_767, -1_000, -2_218,  // Panel B
              -4_917, -1_000, -2_294,
              -5_546, -6_000, -1_821,
              -4_396, -6_000, -1_745) 

  cdrawquad3d(-1_129, -6_000, -1_527,  // Panel C
              -4_396, -6_000, -1_745,
              -5_147,-14_166, -1_179,
              -1_880,-14_166, -0_961)

  { // Aileron deflection 1 inch from hinge
    LET a = muldiv(0_600, c_aileron, 32_768*17)

    setcolour(maprgb(155,155,20))            // Under surface
    cdrawquad3d(-4_396,     -6_000, -1_745,  // Panel D Aileron
                -5_546+3*a, -6_000, -1_821+14*a,
                -6_297+3*a,-13_766, -1_255+14*a,
                -5_147,    -14_166, -1_179)
  }

  // Right lower wing upper surface
  setcolour(maprgb(120,140,60))

  cdrawquad3d(-0_500, -1_000, -2_000,  // Panel A1
              -1_500, -1_000, -1_800,
              -2_129, -6_000, -1_327, 
              -1_129, -6_000, -1_527)

  setcolour(maprgb(120,130,50))
  cdrawquad3d(-1_500, -1_000, -1_800,  // Panel A2
              -3_767, -1_000, -2_118,
              -4_396, -6_000, -1_645, 
              -2_129, -6_000, -1_327)

  cdrawquad3d(-3_767, -1_000, -2_118,  // Panel B
              -4_917, -1_000, -2_294,
              -5_546, -6_000, -1_821,
              -4_396, -6_000, -1_645) 

  setcolour(maprgb(120,140,60))
  cdrawquad3d(-1_129, -6_000, -1_527,  // Panel C1
              -2_129, -6_000, -1_327,
              -2_880,-14_166, -0_761,
              -1_880,-14_166, -0_961)

  setcolour(maprgb(120,130,50))
  cdrawquad3d(-2_129, -6_000, -1_327,  // Panel C2
              -4_396, -6_000, -1_645,
              -5_147,-14_166, -1_079,
              -2_880,-14_166, -0_761)

  { // Aileron deflection 1 inch from hinge
    LET a = muldiv(0_600, c_aileron, 32_768*17)

    setcolour(maprgb(120,140,60))
    cdrawquad3d(-4_396,     -6_000, -1_645,  // Panel D Aileron
                -5_546+3*a, -6_000, -1_821+14*a,
                -6_297+3*a,-13_766, -1_255+14*a,
                -5_147,    -14_166, -0_979)
  }

  // Right lower wing tip
  setcolour(maprgb(130,150,60))
  cdrawtriangle3d(-1_880,-14_167,-1_006,
                  -2_880,-14_167,-0_761,
                  -3_880,-14_467,-0_980)
  setcolour(maprgb(130,150,60))
  cdrawtriangle3d(-2_880,-14_167,-0_761,
                  -5_147,-14_167,-1_079,
                  -3_880,-14_467,-0_980)
  setcolour(maprgb(160,160,40))
  cdrawtriangle3d(-5_147,-14_167,-1_079,
                  -5_147,-14_167,-1_179,
                  -3_880,-14_467,-0_980)
  setcolour(maprgb(170,170,50))
  cdrawtriangle3d(-5_147,-14_167,-1_179,
                  -1_880,-14_167,-0_961,
                  -3_880,-14_467,-0_980)

  // Left upper wing
  setcolour(maprgb(200,200,30))       // Under surface
  cdrawquad3d( 1_333,  1_000,  2_900,
              -1_967,  1_000,  2_671,
              -3_297, 14_167,  3_671, 
               0_003, 14_167,  3_894)
  cdrawquad3d(-1_967,  1_000,  2_671,
              -3_084,  2_200,  2_606,
              -4_414, 13_767,  3_645, 
              -3_297, 14_167,  3_671)

  setcolour(maprgb(150,170,90))       // Top surface
  cdrawquad3d( 1_333,  1_000,  2_900, // Panel A1
               0_333,  1_000,  3_100,
              -0_997, 14_167,  4_094, 
               0_003, 14_167,  3_894)

  setcolour(maprgb(140,160,80))       // Top surface
  cdrawquad3d( 0_333,  1_000,  3_100, // Panel A2
              -1_967,  1_000,  2_771,
              -3_297, 14_167,  3_771, 
              -0_997, 14_167,  4_094)

  setcolour(maprgb(150,170,90))       // Top surface
  cdrawquad3d(-1_967,  1_000,  2_771, // Panel B
              -3_084,  2_200,  2_606,
              -4_414, 13_767,  3_645, 
              -3_297, 14_167,  3_771)

  // Left upper wing tip
  setcolour(maprgb(130,150,60))
  cdrawtriangle3d( 0_003, 14_167, 3_894,
                  -0_997, 14_167, 4_094,
                  -1_997, 14_467, 3_874)
  setcolour(maprgb(130,150,60))
  cdrawtriangle3d(-0_997, 14_167, 4_094,
                  -3_297, 14_167, 3_771,
                  -1_997, 14_467, 3_874)
  setcolour(maprgb(160,160,40))
  cdrawtriangle3d(-3_297, 14_167, 3_771,
                  -3_297, 14_167, 3_671,
                  -1_997, 14_467, 3_874)
  setcolour(maprgb(170,170,50))
  cdrawtriangle3d(-3_297, 14_167, 3_671,
                   0_003, 14_167, 3_894,
                  -1_997, 14_467, 3_874)


  // Right upper wing
  setcolour(maprgb(200,200,30))       // Under surface
  cdrawquad3d( 1_333, -1_000,  2_900,
              -1_967, -1_000,  2_671,
              -3_297,-14_167,  3_671, 
               0_003,-14_167,  3_894)
  cdrawquad3d(-1_967, -1_000,  2_671,
              -3_084, -2_200,  2_606,
              -4_414,-13_767,  3_645, 
              -3_297,-14_167,  3_671)

  setcolour(maprgb(150,170,90))       // Top surface
  cdrawquad3d( 1_333, -1_000,  2_900, // Panel A1
               0_333, -1_000,  3_100,
              -0_997,-14_167,  4_094, 
               0_003,-14_167,  3_894)

  setcolour(maprgb(140,160,80))       // Top surface
  cdrawquad3d( 0_333, -1_000,  3_100, // Panel A2
              -1_967, -1_000,  2_771,
              -3_297,-14_167,  3_771, 
              -0_997,-14_167,  4_094)

  setcolour(maprgb(150,170,90))       // Top surface
  cdrawquad3d(-1_967, -1_000,  2_771, // Panel B
              -3_084, -2_200,  2_606,
              -4_414,-13_767,  3_645, 
              -3_297,-14_167,  3_771)

  // Right upper wing tip
  setcolour(maprgb(130,150,60))
  cdrawtriangle3d( 0_003,-14_167, 3_894,
                  -0_997,-14_167, 4_094,
                  -1_997,-14_467, 3_874)
  setcolour(maprgb(130,150,60))
  cdrawtriangle3d(-0_997,-14_167, 4_094,
                  -3_297,-14_167, 3_771,
                  -1_997,-14_467, 3_874)
  setcolour(maprgb(160,160,40))
  cdrawtriangle3d(-3_297,-14_167, 3_771,
                  -3_297,-14_167, 3_671,
                  -1_997,-14_467, 3_874)
  setcolour(maprgb(170,170,50))
  cdrawtriangle3d(-3_297,-14_167, 3_671,
                   0_003,-14_167, 3_894,
                  -1_997,-14_467, 3_874)


  // Wing root strut forward left
  setcolour(maprgb(80,80,80))
  cdrawquad3d(  0_433,  0_950, 2_900,
                0_633,  0_950, 2_900,
                0_633,  1_000,     0,
                0_433,  1_000,     0)

  // Wing root strut rear left
  setcolour(maprgb(80,80,80))
  cdrawquad3d( -1_967,  0_950,  2_616,
               -1_767,  0_950,  2_616,
               -0_868,  1_000,      0,
               -1_068,  1_000,      0)

  // Wing root strut diag left
  setcolour(maprgb(80,80,80))
  cdrawquad3d(  0_433,  0_950, 2_900,
                0_633,  0_950, 2_900,
               -0_868,  1_000,     0,
               -1_068,  1_000,     0)

  // Wing root strut forward right
  setcolour(maprgb(80,80,80))
  cdrawquad3d(  0_433, -0_950, 2_900,
                0_633, -0_950, 2_900,
                0_633, -1_000,     0,
                0_433, -1_000,     0)

  // Wing root strut rear right
  setcolour(maprgb(80,80,80))
  cdrawquad3d( -1_967, -0_950,  2_616,
               -1_767, -0_950,  2_616,
               -0_868, -1_000,      0,
               -1_068, -1_000,      0)

  // Wing root strut diag right
  setcolour(maprgb(80,80,80))
  cdrawquad3d(  0_433, -0_950, 2_900,
                0_633, -0_950, 2_900,
               -0_868, -1_000,     0,
               -1_068, -1_000,     0)

  // Wing strut forward left
  setcolour(maprgb(80,80,80))
  cdrawquad3d( -2_200,  10_000, -1_120,
               -2_450,  10_000, -1_120,
               -0_550,  10_000,  3_315,
               -0_300,  10_000,  3_315)

  // Wing strut rear left
  setcolour(maprgb(80,80,80))
  cdrawquad3d( -4_500,  10_000, -1_260,
               -4_750,  10_000, -1_260,
               -2_850,  10_000,  3_210,
               -2_500,  10_000,  3_210)

  // Wing strut forward right
  setcolour(maprgb(80,80,80))
  cdrawquad3d( -2_200, -10_000, -1_120,
               -2_450, -10_000, -1_120,
               -0_550, -10_000,  3_315,
               -0_300, -10_000,  3_315)

  // Wing strut rear right
  setcolour(maprgb(80,80,80))
  cdrawquad3d( -4_500, -10_000, -1_260,
               -4_750, -10_000, -1_260,
               -2_850, -10_000,  3_210,
               -2_500, -10_000,  3_210)

  // Wheel strut left
  setcolour(maprgb(80,80,80))
  cdrawquad3d( -0_768,  1_000, -2_000,
               -1_168,  1_000, -2_000,
               -0_468,  2_000, -3_800,
               -0_068,  2_000, -3_800)

  // Wheel strut diag left
  setcolour(maprgb(80,80,80))
  cdrawquad3d(  1_600,  1_000, -2_000,
                1_800,  1_000, -2_000,
               -0_368,  2_000, -3_800,
               -0_168,  2_000, -3_800)

  // Wheel strut centre left
  setcolour(maprgb(80,80,80))
  cdrawquad3d( -0_500,  0_000, -2_900,
               -0_650,  0_000, -2_900,
               -0_318,  2_000, -3_800,
               -0_168,  2_000, -3_800)

  // Wheel strut right
  setcolour(maprgb(80,80,80))
  cdrawquad3d( -0_768, -1_000, -2_000,
               -1_168, -1_000, -2_000,
               -0_468, -2_000, -3_800,
               -0_068, -2_000, -3_800)

  // Wheel strut diag right
  setcolour(maprgb(80,80,80))
  cdrawquad3d(  1_600, -1_000, -2_000,
                1_800, -1_000, -2_000,
               -0_368, -2_000, -3_800,
               -0_168, -2_000, -3_800)

  // Wheel strut centre right
  setcolour(maprgb(80,80,80))
  cdrawquad3d( -0_500, -0_000, -2_900,
               -0_650, -0_000, -2_900,
               -0_318, -2_000, -3_800,
               -0_168, -2_000, -3_800)


  // Left wheel
  setcolour(maprgb(20,20,20))
  cdrawquad3d( -0_268,       2_100, -3_800,
               -0_268,       2_100, -3_800-0_700,
               -0_268-0_500, 2_100, -3_800-0_500,
               -0_268-0_700, 2_100, -3_800)
  cdrawquad3d( -0_268,       2_100, -3_800,
               -0_268,       2_100, -3_800-0_700,
               -0_268+0_500, 2_100, -3_800-0_500,
               -0_268+0_700, 2_100, -3_800)
  cdrawquad3d( -0_268,       2_100, -3_800,
               -0_268,       2_100, -3_800+0_700,
               -0_268-0_500, 2_100, -3_800+0_500,
               -0_268-0_700, 2_100, -3_800)
  cdrawquad3d( -0_268,       2_100, -3_800,
               -0_268,       2_100, -3_800+0_700,
               -0_268+0_500, 2_100, -3_800+0_500,
               -0_268+0_700, 2_100, -3_800)

  // Right wheel
  setcolour(maprgb(20,20,20))
  cdrawquad3d( -0_268,      -2_100, -3_800,
               -0_268,      -2_100, -3_800-0_700,
               -0_268-0_500,-2_100, -3_800-0_500,
               -0_268-0_700,-2_100, -3_800)
  cdrawquad3d( -0_268,      -2_100, -3_800,
               -0_268,      -2_100, -3_800-0_700,
               -0_268+0_500,-2_100, -3_800-0_500,
               -0_268+0_700,-2_100, -3_800)
  cdrawquad3d( -0_268,      -2_100, -3_800,
               -0_268,      -2_100, -3_800+0_700,
               -0_268-0_500,-2_100, -3_800+0_500,
               -0_268-0_700,-2_100, -3_800)
  cdrawquad3d( -0_268,      -2_100, -3_800,
               -0_268,      -2_100, -3_800+0_700,
               -0_268+0_500,-2_100, -3_800+0_500,
               -0_268+0_700,-2_100, -3_800)


  // Fueltank front
  setcolour(maprgb(200,200,230))       // Top surface
  cdrawquad3d( 1_333,  1_000,  2_900,
               1_333, -1_000,  2_900,
               0_033, -1_000,  3_100,
               0_033,  1_000,  3_100)

  // Fueltank back
  setcolour(maprgb(180,180,210))       // Top surface
  cdrawquad3d( 0_033,  1_000,  3_100,
               0_033, -1_000,  3_100,
              -1_967, -1_000,  2_616,
              -1_967,  1_000,  2_616)

  // Fueltank left side
  setcolour(maprgb(160,160,190))
  cdrawtriangle3d( 1_333,  1_000, 2_900,
                   0_033,  1_000, 3_100,
                  -1_967,  1_000, 2_616)

  // Fueltank right side
  setcolour(maprgb(160,160,190))
  cdrawtriangle3d(-0_500+1_833, -1_000, -2_000+4_900,
                  -1_800+1_833, -1_000, -1_800+4_900,
                  -3_800+1_833, -1_000, -2_284+4_900) 

  // Fuselage

  // Prop shaft
  setcolour(maprgb(40,40,90))
  cdrawtriangle3d( 5_500,     0,      0,
                   4_700, 0_200, 0_300,
                   4_700, 0_200,-0_300)
  setcolour(maprgb(60,60,40))
  cdrawtriangle3d( 5_500,     0,      0,
                   4_700, 0_200,-0_300,
                   4_700,-0_200,-0_300)
  setcolour(maprgb(40,40,90))
  cdrawtriangle3d( 5_500,     0,      0,
                   4_700,-0_200,-0_300,
                   4_700,-0_200, 0_300)
  setcolour(maprgb(60,60,40))
  cdrawtriangle3d( 5_500,     0,      0,
                   4_700,-0_200, 0_300,
                   4_700, 0_200, 0_300)


  // Engine front lower centre
  setcolour(maprgb(140,140,160))
  cdrawtriangle3d( 5_000,     0,      0,
                   4_500, 0_550, -1_750,
                   4_500,-0_550, -1_750)

  // Engine front lower left
  setcolour(maprgb(140,120,130))
  cdrawtriangle3d( 5_000,     0,      0,
                   4_500, 0_550, -1_750,
                   4_500, 0_550,      0)

  // Engine front lower right
  setcolour(maprgb(140,120,130))
  cdrawtriangle3d( 5_000,     0,      0,
                   4_500,-0_550, -1_750,
                   4_500,-0_550,      0)

  // Engine front upper centre
  setcolour(maprgb(140,140,160))
  cdrawtriangle3d( 5_000,     0,     0,
                   4_500, 0_550, 0_500,
                   4_500,-0_550, 0_500)

  // Engine front upper left
  setcolour(maprgb(100,140,180))
  cdrawtriangle3d( 5_000,     0,     0,
                   4_500, 0_550, 0_500,
                   4_500, 0_550,     0)
  cdrawtriangle3d( 5_000,     0,     0,
                   4_500,-0_550, 0_500,
                   4_500,-0_550,     0)

  // Engine left lower
  setcolour(maprgb(80,80,60))
  cdrawquad3d( 1_033, 1_000,      0,
               1_800, 1_000, -2_000,
               4_500, 0_550, -1_750,
               4_500, 0_550,      0)

  // Engine right lower
  setcolour(maprgb(80,100,60))
  cdrawquad3d( 1_033,-1_000,      0,
               1_800,-1_000, -2_000,
               4_500,-0_550, -1_750,
               4_500,-0_550,      0)

  // Engine top left
  setcolour(maprgb(100,130,60))
  cdrawquad3d(  1_033, 0_900,  0_950,
                1_033, 0_900,  0_000,
                4_500, 0_550,  0_000,
                4_500, 0_550,  0_500)

  // Engine top centre
  setcolour(maprgb(130,160,90))
  cdrawquad3d(  1_033, 0_900,  0_950,
                1_033,-0_900,  0_950,
                4_500,-0_550,  0_500,
                4_500, 0_550,  0_500)

  // Engine top right
  setcolour(maprgb(100,130,60))
  cdrawquad3d(  1_033,-0_900,  0_950,
                1_033,-0_900,  0_000,
                4_500,-0_550,  0_000,
                4_500,-0_550,  0_500)

  // Engine bottom
  setcolour(maprgb(100,80,50))
  cdrawquad3d(  4_500, 0_550, -1_750,
                4_500,-0_550, -1_750,
                1_800,-1_000, -2_000,
                1_800, 1_000, -2_000)


  // Front cockpit left
  setcolour(maprgb(120,140,60))
  cdrawquad3d( -2_000, 1_000,  0_000,
               -2_000, 0_870,  0_600,
               -3_300, 0_870,  0_600,
               -3_300, 1_000,  0_000)

  // Front cockpit right
  setcolour(maprgb(120,140,60))
  cdrawquad3d( -2_000,-1_000,  0_000,
               -2_000,-0_870,  0_600,
               -3_300,-0_870,  0_600,
               -3_300,-1_000,  0_000)

  // Top front left
  setcolour(maprgb(100,120,40))
  cdrawquad3d(  1_033, 0_900,  0_950,
               -2_000, 0_750,  1_000,
               -2_000, 0_750,  0_000,
                1_033, 0_900,  0_000)

  // Top front middle
  setcolour(maprgb(120,140,60))
  cdrawquad3d(  1_033, 0_900,  0_950,
                1_033,-0_900,  0_950,
               -2_000,-0_750,  1_000,
               -2_000, 0_750,  1_000)

  // Top front right
  setcolour(maprgb(100,120,40))
  cdrawquad3d(  1_033,-0_900,  0_950,
               -2_000,-0_750,  1_000,
               -2_000,-0_750,  0_000,
                1_033,-0_900,  0_000)


  // Front wind shield
  setcolour(maprgb(180,200,150))
  cdrawquad3d( -1_300, 0_450,  1_000,
               -2_000, 0_450,  1_400,
               -2_000,-0_450,  1_400,
               -1_300,-0_450,  1_000)
  setcolour(maprgb(220,220,180))
  cdrawtriangle3d( -1_300, 0_450,  1_000,
                   -2_000, 0_450,  1_400,
                   -2_000, 0_650,  1_000)

  setcolour(maprgb(170,200,150))
  cdrawtriangle3d( -1_300,-0_450,  1_000,
                   -2_000,-0_450,  1_400,
                   -2_000,-0_650,  1_000)


  // Top left middle
  setcolour(maprgb(130,160,90))
  cdrawquad3d( -3_300, 0_750,  1_000,
               -3_300, 1_000,  0_000,
               -4_300, 1_000,  0_000,
               -4_300, 0_750,  1_000)

  // Top centre middle
  setcolour(maprgb(120,140,60))
  cdrawquad3d( -3_300, 0_750,  1_000,
               -3_300,-0_750,  1_000,
               -4_300,-0_750,  1_000,
               -4_300, 0_750,  1_000)

  // Top right middle
  setcolour(maprgb(130,160,90))
  cdrawquad3d( -3_300,-0_750,  1_000,
               -3_300,-1_000,  0_000,
               -4_300,-1_000,  0_000,
               -4_300,-0_750,  1_000)

  // Rear cockpit left
  setcolour(maprgb(120,140,60))
  cdrawquad3d( -4_300, 1_000,  0_000,
               -4_300, 0_870,  0_600,
               -5_583, 0_870,  0_600,
               -5_583, 1_000,  0_000)

  // Rear wind shield
  setcolour(maprgb(180,200,150))
  cdrawquad3d( -3_600, 0_450,  1_000,
               -4_300, 0_450,  1_400,
               -4_300,-0_450,  1_400,
               -3_600,-0_450,  1_000)
  setcolour(maprgb(220,220,180))
  cdrawtriangle3d( -3_600, 0_450,  1_000,
                   -4_300, 0_450,  1_400,
                   -4_300, 0_650,  1_000)

  setcolour(maprgb(170,200,150))
  cdrawtriangle3d( -3_600,-0_450,  1_000,
                   -4_300,-0_450,  1_400,
                   -4_300,-0_650,  1_000)



  // Rear cockpit right
  setcolour(maprgb(110,140,70))
  cdrawquad3d( -4_300,-1_000,  0_000,
               -4_300,-0_870,  0_600,
               -5_583,-0_870,  0_600,
               -5_583,-1_000,  0_000)


  // Lower left middle
  setcolour(maprgb(140,110,70))
  cdrawquad3d(  1_033, 1_000,      0,
                1_800, 1_000, -2_000,
               -3_583, 1_000, -2_238,
               -3_583, 1_000,      0)

  // Bottom middle
  setcolour(maprgb(120,100,60))
  cdrawquad3d(  1_800, 1_000, -2_000,
               -3_583, 1_000, -2_238,
               -3_583,-1_000, -2_238,
                1_800,-1_000, -2_000)

  // Lower right middle
  setcolour(maprgb(140,110,70))
  cdrawquad3d(  1_033,-1_000,      0,
                1_800,-1_000, -2_000,
               -3_583,-1_000, -2_238,
               -3_583,-1_000,      0)

  // Lower left back
  setcolour(maprgb(160,120,80))
  cdrawquad3d( -3_583, 1_000,      0,
              -16_000, 0_050,      0,
              -16_000, 0_050, -0_667,
               -3_583, 1_000, -2_238)

  // Bottom back
  setcolour(maprgb(130,90,60))
  cdrawquad3d( -3_583, 1_000, -2_238,
              -16_000, 0_050, -0_667,
              -16_000,-0_050, -0_667,
               -3_583,-1_000, -2_238)

  // Lower right back
  setcolour(maprgb(160,140,80))
  cdrawquad3d( -3_583,-1_000,      0,
              -16_000,-0_050,      0,
              -16_000,-0_050, -0_667,
               -3_583,-1_000, -2_238)

  // Top left back
  setcolour(maprgb(130,130,80))
  cdrawtriangle3d( -5_583, 0_650,  0_950,
                   -5_583, 1_000,  0_000,
                  -13_900, 0_150,      0)

  // Top centre back
  setcolour(maprgb(130,160,90))
  cdrawquad3d( -5_583, 0_650,  0_950,
               -5_583,-0_650,  0_950,
              -13_900,-0_150,      0,
              -13_900, 0_150,      0)

  // Top right back
  setcolour(maprgb(130,130,80))
  cdrawtriangle3d( -5_583,-0_650,  0_950,
                   -5_583,-1_000,  0_000,
                  -13_900,-0_150,      0)



  // Fin
  { // Rudder deflection 1 inch from hinge
    LET a = muldiv(1_100, c_rudder, 32_768*17)

    setcolour(maprgb(170,180,80))
    cdrawquad3d(-14_000, 0_000,     0,   // Fin
                -16_000, 0_000,     0,
                -16_000, 0_000, 1_000,
                -15_200, 0_000, 1_000)
    
    setcolour(maprgb(70,120,40))
    cdrawquad3d(-15_200-3*a,  9*a, 1_000,  // Rudder
                -16_000,        0, 1_000,
                -16_800+3*a,-10*a, 3_100,
                -16_000,        0, 2_550)
    setcolour(maprgb(70, 80,40))
    cdrawquad3d(-16_000,        0, 1_000,
                -16_800+3*a,-10*a, 3_100,
                -17_566+4*a,-14*a, 2_600,
                -17_816+4*a,-17*a, 1_667)
    setcolour(maprgb(70,120,40))
    cdrawquad3d(-16_000,        0, 1_000,
                -17_816+4*a,-17*a, 1_667,
                -17_816+4*a,-17*a, 1_000,
                -17_566+4*a,-14*a,     0)
    setcolour(maprgb(70, 80,40))
    cdrawquad3d(-16_000,        0, 1_000,
                -17_566+4*a,-14*a,     0,
                -17_000+2*a,- 8*a,-0_583,
                -16_000,        0,-0_667)

    // Tail skid
    setcolour(maprgb(20, 20,20))
    cdrawquad3d(-16_000,        0, -0_667,
                -16_200,        0, -0_667,
                -16_500+2*a, -8*a, -0_900,
                -16_300+2*a, -7*a, -0_900)

  }

  // Tailplane and elevator
  { // Elevator deflection 1 inch from hinge
    LET a = muldiv(0_600, c_elevator, 32_768*17)

    setcolour(maprgb(160,200,50)) 
    cdrawquad3d(-16_000, 0_000,     0, // Left tailplane
                -13_900, 0_600,     0,
                -14_600, 2_800,     0,
                -16_000, 4_500,     0)

    setcolour(maprgb(120,200,50))
    cdrawtriangle3d(-13_900, 0_600,     0,
                    -13_900,-0_600,     0,
                    -16_000, 0_000,     0)

    cdrawquad3d(-16_000, 0_000,     0, // Right tailplane
                -13_900,-0_600,     0,
                -14_600,-2_800,     0,
                -16_000,-4_500,     0)

    setcolour(maprgb(170,150,80)) 
    cdrawquad3d(-16_000, 0_000,     0, // Left elevator
                -17_200+4*a, 0_600, -15*a, // pt 1
                -17_500+5*a, 0_900, -16*a, // pt 2
                -17_666+5*a, 2_000, -17*a) // pt 3

    setcolour(maprgb(120,170,60)) 
    cdrawquad3d(-16_000,     0_000,     0, // Left elevator
                -17_666+5*a, 2_000, -17*a, // pt 3
                -17_450+4*a, 3_500, -16*a, // pt 4
                -17_200+4*a, 4_650, -14*a) // pt 5

    setcolour(maprgb(160,120,40)) 
    cdrawquad3d(-16_000,     0_000,     0, // Left elevator
                -17_200+4*a, 4_650, -14*a, // pt 5
                -16_700+a/2, 4_833,  -2*a, // pt 6
                -16_000,     4_500,     a) // pt 7

    setcolour(maprgb(170,150,80)) 
    cdrawquad3d(-16_000, 0_000,     0,     // Right elevator
                -17_200+4*a,-0_600, -15*a, // pt 1
                -17_500+5*a,-0_900, -16*a, // pt 2
                -17_666+5*a,-2_000, -17*a) // pt 3

    setcolour(maprgb(120,170,60)) 
    cdrawquad3d(-16_000,     0_000,     0, // Right elevator
                -17_666+5*a,-2_000, -17*a, // pt 3
                -17_450+4*a,-3_500, -16*a, // pt 4
                -17_200+4*a,-4_650, -14*a) // pt 5

    setcolour(maprgb(160,120,40)) 
    cdrawquad3d(-16_000,     0_000,     0, // Right elevator
                -17_200+4*a,-4_650, -14*a, // pt 5
                -16_700+a/2,-4_833,  -2*a, // pt 6
                -16_000,    -4_500,     a) // pt 7
  }
}



