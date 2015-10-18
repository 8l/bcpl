/*
This program creates the file tigermothmodel.mdl representing
a tiger moth aircraft in .mdl format for use by the OpenGL program
gltiger.b

Implemented by Martin Richards (c) February 2014

############# UNDER DEVELOPMENT ##################################

OpenGL vertex data is stored as follows

vec3 position -- t(direction of thrust), w(direction of left wing),
              -- and l(diretion of lift)
vec3 colour   -- r, g, b
vec2 data   data[0] =1 rudder,
                    =2 elevator,
                    =3 left aileron,
                    =4 right aileron
                    =5 landscape and runway
            data[1] = distance from hinge in inches, to be multiplied
                      by the sine or cosine of control surface angle

The program outputs vertex and index items representing the mode. It
used a self entending vector for the vertices so that when vertices
can be reused. Every value of vertex data is represented by scaled
fixed point numbers with 3 digits after the decimal point.

In the .mdl language

s is followed by the scaling factor
v says the following values are vertex data
i say the following values are indices.
z marks the end of file
*/

GET "libhdr"

GLOBAL {
 stdin:ug
 stdout
 cur_r; cur_g; cur_b
 // If p is a self expanding array
 //   p!0 = number of elements in the array
 //   p!1 is current getvec'd vector for the array
 //   p!2 is the upb of the current vector
 // push(p, x) will push a value into the array.
 // p!0=p!2 The array is expanded, typically double in size.
 ///push

 ///varray      // Self expanding array of vertices
 addvertex   // Find or create a vertex, returning the vertex number
 vertexcount // Index of the next vertex to be created
 hashtab     // hash table for verices

 spacev
 spacep
 spacet
 newvec

 tracing
 tostream
}

MANIFEST {
// Vertex structure
v_x=0; v_y; v_z
v_r;   v_g; v_b
v_k;   v_d        // Control surface, distance from hinge
v_n               // Vertex number
v_chain           // Hash chain
v_size            // Number of words in a vertex node
v_upb = v_size-1

hashtabsize = 541
hashtabupb = hashtabsize-1

spaceupb = 500_000 * v_size

runwaylength =    600_000
runwaywidth  =     40_000
landsize     = 20_000_000
}


LET start() = VALOF
{ LET stdin = input()
  LET stdout = output()
  LET toname = "tigermothmodel.mdl" 
  LET ht = VEC hashtabsize
  LET argv = VEC 50
  ///LET vp, vv, vt = 0, 0, 0 // The vertex array self expanding array
  ///varray := @vp
  vertexcount := 0

  hashtab := ht
  FOR i = 0 TO hashtabupb DO hashtab!i := 0

  UNLESS rdargs("to/k,-t/s", argv, 50) DO
  { writef("Bad arguments for mktigermothmodel*n")
    RESULTIS 0
  }

  IF argv!0 DO toname := argv!0
  tracing := argv!1

  tostream := findoutput(toname)
  UNLESS toname DO
  { writef("trouble with file: %s*n", toname)
    RESULTIS 0
  }

  spacev := getvec(spaceupb)
  spacet := @spacev!spaceupb
  spacep := spacet

  UNLESS spacep DO
  { writef("Unable to allocate %n words of space*n")
    GOTO fin
  }
  
  colour(0,0,0)

  selectoutput(tostream)

  mktigermothmodel()

  endstream(tostream)
  selectoutput(stdout)
  writef("Space used %n out of %n*n", spacet-spacep, spacet)

fin:
  IF spacev DO freevec(spacev)
  RESULTIS 0
}

AND newvec(upb) = VALOF
{ LET p = spacep - upb - 1
  IF p < spacev DO
  { writef("error: spacev is not large enough*n")
    abort(999) 
  }
  spacep := p
  RESULTIS p
}

AND colour(r, g, b) BE
  cur_r, cur_g, cur_b := 1_000*r/255, 1_000*g/255, 1_000*b/255

AND findvertex(t,w,l, r,g,b, k,d) = VALOF
{ // Return the pointer to the  matching vertex node,
  // creating one if necessary.
  // t,w,h, etc are floating point numbers but the hash
  // computation just treats them as bit patterns to
  // produce a hash value in the range 0 to hashtabupb.
  LET hashval = ((t+w+l+r+g+b+k+d)>>1) MOD hashtabsize
  LET p = hashtab!hashval
  WHILE p DO // Search down the hash chain
  { IF p!v_x=t & p!v_y=w & p!v_z=l &
       p!v_r=r & p!v_g=g & p!v_b=b &
       p!v_k=k & p!v_d=d RESULTIS p // Vertex found
    p := p!v_chain
  }
  // Vertex not found
  p := newvec(v_upb)
  p!v_x, p!v_y, p!v_z := t, w, l
  p!v_r, p!v_g, p!v_b := r, g, b
  p!v_k, p!v_d        := k, d
  p!v_n := vertexcount
  p!v_chain := hashtab!hashval
  hashtab!hashval := p
  writef("v     %i6 %i6 %i6 %i4 %i4 %i4 %i4 %i6  // %i3*n",
         t,w,l, r,g,b, 1000*k, d, vertexcount)
  vertexcount := vertexcount+1
  RESULTIS p
}

AND addvertex(t,w,l, k,d) = findvertex(t,w,l, cur_r,cur_g,cur_b, k,d)

AND addlandvertex(n,w,h, r,g,b) = VALOF
{ colour(r,g,b)
  RESULTIS addvertex(n,w,h, 5, 0)
}

AND triangle(a,b,c, d,e,f, g,h,i) BE
{ // a, b, c are in directions forward, left and up
  // store as openGL t,w,l which are forward, left, up.
  // ie set t, w, l to a, b, c
  // do the same for def and ghi
  LET v0 = addvertex(a,b,c, 0, 0)!v_n
  LET v1 = addvertex(d,e,f, 0, 0)!v_n
  LET v2 = addvertex(g,h,i, 0, 0)!v_n
  writef("i %i4 %i4 %i4*n", v0, v1, v2)
}

AND quad(a,b,c, d,e,f, g,h,i, j,k,l) BE
{ // a, b, c are in directions forward, left and up
  // store as openGL t,w,l which are forward,left, up
  // ie set x, y, z to a, b, c
  // do the same for def, ghi and jkl
  LET v0 = addvertex(a,b,c, 0, 0)!v_n
  LET v1 = addvertex(d,e,f, 0, 0)!v_n
  LET v2 = addvertex(g,h,i, 0, 0)!v_n
  LET v3 = addvertex(j,k,l, 0, 0)!v_n
  writef("i %i4 %i4 %i4*n", v0, v1, v2)
  writef("i %i4 %i4 %i4*n", v0, v2, v3)
}

AND quadkd(a,b,c,k1,d1, d,e,f,k2,d2, g,h,i,k3,d3, j,k,l,k4,d4) BE
{ // a, b, c are in directions forward, left and up
  // store as openGL t,w,l which are forward, left, up
  // ie set x, y, z to a, b, c
  // do the same for def, ghi and jkl
  LET v0 = addvertex(a,b,c, k1, d1)!v_n
  LET v1 = addvertex(d,e,f, k2, d2)!v_n
  LET v2 = addvertex(g,h,i, k3, d3)!v_n
  LET v3 = addvertex(j,k,l, k4, d4)!v_n
  writef("i %i4 %i4 %i4*n", v0, v1, v2)
  writef("i %i4 %i4 %i4*n", v0, v2, v3)
}

AND triangleland(x1,y1,z1, r1,g1,b1,
                 x2,y2,z2, r2,g2,b2,
                 x3,y3,z3, r3,g3,b3) BE
{ // 3D coords and colours of the the vertices of a triangle
  // of landscape or runway
  LET v0 = addlandvertex(x1,y1,z1, r1,g1,b1)!v_n
  LET v1 = addlandvertex(x2,y2,z2, r2,g2,b2)!v_n
  LET v2 = addlandvertex(x3,y3,z3, r3,g3,b3)!v_n
  writef("i %i4 %i4 %i4*n", v0, v1, v2)
}

AND quadland(x1,y1,z1, r1,g1,b1,
             x2,y2,z2, r2,g2,b2,
             x3,y3,z3, r3,g3,b3,
             x4,y4,z4, r4,g4,b4) BE
{ // 3D coords and colours of the the vertices of a quad
  // of landscpe or runway
  LET v0 = addlandvertex(x1,y1,z1, r1,g1,b1)!v_n
  LET v1 = addlandvertex(x2,y2,z2, r2,g2,b2)!v_n
  LET v2 = addlandvertex(x3,y3,z3, r3,g3,b3)!v_n
  LET v3 = addlandvertex(x4,y4,z4, r4,g4,b4)!v_n
  writef("i %i4 %i4 %i4*n", v0, v1, v2)
  writef("i %i4 %i4 %i4*n", v0, v2, v3)
}

AND mktigermothmodel() BE
{ // The origin is the centre of gravity of the tigermoth
  // For landsacpe and the runway, the origin is the start of the runway

  // The tigermoth coordinates are as follows

  // first  t is the distance forward of the centre of gravity
  // second w is the distance left of the centre of gravity
  // third  l is the distance above the centre of gravity

  writef("// Tiger Moth Model*n")
  newline()
  writef("// The v parameters are*n")
  writef("//        t      w      l     r    g    b    k    d*n")
  newline()
  writef("// ie t = direction of thrust*n")
  writef("//    w = direction of left wing*n")
  writef("//    l = direction of lift*n")
  newline()
  writef("//    k = 0   fixed surface*n")
  writef("//    k = 1   rudder*n")
  writef("//    k = 2   elevator*n")
  writef("//    k = 3   left aileron*n")
  writef("//    k = 4   right aileron*n")
  writef("//    k = 5   landscape and runway*n")
  newline()
  writef("s 1000*n*n")

  writef("// Cockpit floor*n")
  colour(90,80,30)
  quad( 1_000, 0_800, 0_000,
        1_000,-0_800, 0_000,
       -5_800,-0_800, 0_000,
       -5_800, 0_800, 0_000)

  writef("// Left lower wing*n")
  colour(165,165,30)            // Under surface

  //     -t       w       l
  quad(-0_500,  1_000, -2_000,  // Panel A
       -3_767,  1_000, -2_218,
       -4_396,  6_000, -1_745, 
       -1_129,  6_000, -1_527)

  colour(155,155,20)            // Under surface
  quadkd(-4_396,  6_000, -1_745, 0,     0,// Panel D left Aileron
         -5_546,  6_000, -1_821, 3, 1_150,
         -6_297, 13_766, -1_255, 3, 1_150,
         -5_147, 14_166, -1_179, 0,     0)

  colour(155,155,60)
  //colour(255,155,60)
  quad(-3_767,  1_000, -2_218,  // Panel B
       -4_917,  1_000, -2_294,
       -5_546,  6_000, -1_821,
       -4_396,  6_000, -1_745) 

  colour(155,155,90)
  quad(-1_129,  6_000, -1_527,  // Panel C
       -4_396,  6_000, -1_745,
       -5_147, 14_166, -1_179,
       -1_880, 14_166, -0_961)

  writef("// Left lower wing upper surface*n")
  colour(120,140,60)

  quad(-0_500,  1_000, -2_000,  // Panel A1
       -1_500,  1_000, -1_800,
       -2_129,  6_000, -1_327, 
       -1_129,  6_000, -1_527)

  colour(120,130,50)
  quad(-1_500,  1_000, -1_800,  // Panel A2
       -3_767,  1_000, -2_118,
       -4_396,  6_000, -1_645, 
       -2_129,  6_000, -1_327)

  quad(-3_767,  1_000, -2_118,  // Panel B
       -4_917,  1_000, -2_294,
       -5_546,  6_000, -1_821,
       -4_396,  6_000, -1_645) 

  colour(120,140,60)
  quad(-1_129,  6_000, -1_527,  // Panel C1
       -2_129,  6_000, -1_327,
       -2_880, 14_166, -0_761,
       -1_880, 14_166, -0_961)

  colour(120,130,50)
  quad(-2_129,  6_000, -1_327,  // Panel C2
       -4_396,  6_000, -1_645,
       -5_147, 14_166, -1_079,
       -2_880, 14_166, -0_761)

  colour(120,140,60)
  quadkd(-4_396,  6_000, -1_645, 0,     0, // Panel D Aileron
         -5_546,  6_000, -1_821, 3, 1_150,
         -6_297, 13_766, -1_255, 3, 1_150,
         -5_147, 14_166, -1_079, 0,     0)

   writef("// Left lower wing tip*n")
  colour(130,150,60)
  triangle(-1_880, 14_167,-1_006,
           -2_880, 14_167,-0_761,
           -3_880, 14_467,-0_980)
  colour(130,150,60)
  triangle(-2_880, 14_167,-0_761,
           -5_147, 14_167,-1_079,
           -3_880, 14_467,-0_980)
  colour(160,160,40)
  triangle(-5_147, 14_167,-1_079,
           -5_147, 14_167,-1_179,
           -3_880, 14_467,-0_980)
  colour(170,170,50)
  triangle(-5_147, 14_167,-1_179,
           -1_880, 14_167,-0_961,
           -3_880, 14_467,-0_980)

   writef("// Right lower wing*n")
  colour(165,165,30)        // Under surface

  quad(-0_500, -1_000, -2_000,  // Panel A
       -3_767, -1_000, -2_218,
       -4_396, -6_000, -1_745, 
       -1_129, -6_000, -1_527)

  quad(-3_767, -1_000, -2_218,  // Panel B
       -4_917, -1_000, -2_294,
       -5_546, -6_000, -1_821,
       -4_396, -6_000, -1_745) 

  quad(-1_129, -6_000, -1_527,  // Panel C
       -4_396, -6_000, -1_745,
       -5_147,-14_166, -1_179,
       -1_880,-14_166, -0_961)

  colour(155,155,20)            // Under surface
  quadkd(-4_396, -6_000, -1_745, 0,     0, // Panel D Aileron
         -5_546, -6_000, -1_821, 4, 1_150,
         -6_297,-13_766, -1_255, 4, 1_150,
         -5_147,-14_166, -1_179, 0,     0)

   writef("// Right lower wing upper surface*n")
  colour(120,140,60)

  quad(-0_500, -1_000, -2_000,  // Panel A1
       -1_500, -1_000, -1_800,
       -2_129, -6_000, -1_327, 
       -1_129, -6_000, -1_527)

  colour(120,130,50)
  quad(-1_500, -1_000, -1_800,  // Panel A2
       -3_767, -1_000, -2_118,
       -4_396, -6_000, -1_645, 
       -2_129, -6_000, -1_327)

  quad(-3_767, -1_000, -2_118,  // Panel B
       -4_917, -1_000, -2_294,
       -5_546, -6_000, -1_821,
       -4_396, -6_000, -1_645) 

  colour(120,140,60)
  quad(-1_129, -6_000, -1_527,  // Panel C1
       -2_129, -6_000, -1_327,
       -2_880,-14_166, -0_761,
       -1_880,-14_166, -0_961)

  colour(120,130,50)
  quad(-2_129, -6_000, -1_327,  // Panel C2
       -4_396, -6_000, -1_645,
       -5_147,-14_166, -1_079,
       -2_880,-14_166, -0_761)

  colour(120,140,60)
  quadkd(-4_396, -6_000, -1_645, 0,     0,  // Panel D Aileron
         -5_546, -6_000, -1_821, 4, 1_150,
         -6_297,-13_766, -1_255, 4, 1_150,
         -5_147,-14_166, -1_079, 0,     0)

   writef("// Right lower wing tip*n")
  colour(130,150,60)
  triangle(-1_880,-14_167,-1_006,
           -2_880,-14_167,-0_761,
           -3_880,-14_467,-0_980)
  colour(130,150,60)
  triangle(-2_880,-14_167,-0_761,
           -5_147,-14_167,-1_079,
           -3_880,-14_467,-0_980)
  colour(160,160,40)
  triangle(-5_147,-14_167,-1_079,
           -5_147,-14_167,-1_179,
           -3_880,-14_467,-0_980)
  colour(170,170,50)
  triangle(-5_147,-14_167,-1_179,
           -1_880,-14_167,-0_961,
           -3_880,-14_467,-0_980)

  writef(" // Left upper wing*n")
  colour(200,200,30)           // Under surface
  quad( 1_333,  1_000,  2_900,
       -1_967,  1_000,  2_671,
       -3_297, 14_167,  3_671, 
        0_003, 14_167,  3_894)
  quad(-1_967,  1_000,  2_671,
       -3_084,  2_200,  2_606,
       -4_414, 13_767,  3_645, 
       -3_297, 14_167,  3_671)

  colour(150,170,90)           // Top surface
  quad( 1_333,  1_000,  2_900, // Panel A1
        0_333,  1_000,  3_100,
       -0_997, 14_167,  4_094, 
        0_003, 14_167,  3_894)

  colour(140,160,80)           // Top surface
  quad( 0_333,  1_000,  3_100, // Panel A2
       -1_967,  1_000,  2_771,
       -3_297, 14_167,  3_771, 
       -0_997, 14_167,  4_094)

  colour(150,170,90)           // Top surface
  quad(-1_967,  1_000,  2_771, // Panel B
       -3_084,  2_200,  2_606,
       -4_414, 13_767,  3_645, 
       -3_297, 14_167,  3_771)

  writef(" // Left upper wing tip*n")
  colour(130,150,60)
  triangle( 0_003, 14_167, 3_894,
           -0_997, 14_167, 4_094,
           -1_997, 14_467, 3_874)
  colour(130,150,60)
  triangle(-0_997, 14_167, 4_094,
           -3_297, 14_167, 3_771,
           -1_997, 14_467, 3_874)
  colour(160,160,40)
  triangle(-3_297, 14_167, 3_771,
           -3_297, 14_167, 3_671,
           -1_997, 14_467, 3_874)
  colour(170,170,50)
  triangle(-3_297, 14_167, 3_671,
            0_003, 14_167, 3_894,
           -1_997, 14_467, 3_874)


   writef("// Right upper wing*n")
  colour(200,200,30)           // Under surface
  quad( 1_333, -1_000,  2_900,
       -1_967, -1_000,  2_671,
       -3_297,-14_167,  3_671, 
        0_003,-14_167,  3_894)
  quad(-1_967, -1_000,  2_671,
       -3_084, -2_200,  2_606,
       -4_414,-13_767,  3_645, 
       -3_297,-14_167,  3_671)

  colour(150,170,90)           // Top surface
  quad( 1_333, -1_000,  2_900, // Panel A1
        0_333, -1_000,  3_100,
       -0_997,-14_167,  4_094, 
        0_003,-14_167,  3_894)

  colour(140,160,80)           // Top surface
  quad( 0_333, -1_000,  3_100, // Panel A2
       -1_967, -1_000,  2_771,
       -3_297,-14_167,  3_771, 
       -0_997,-14_167,  4_094)

  colour(150,170,90)           // Top surface
  quad(-1_967, -1_000,  2_771, // Panel B
       -3_084, -2_200,  2_606,
       -4_414,-13_767,  3_645, 
       -3_297,-14_167,  3_771)

   writef("// Right upper wing tip*n")
  colour(130,150,60)
  triangle( 0_003,-14_167, 3_894,
           -0_997,-14_167, 4_094,
           -1_997,-14_467, 3_874)
  colour(130,150,60)
  triangle(-0_997,-14_167, 4_094,
           -3_297,-14_167, 3_771,
           -1_997,-14_467, 3_874)
  colour(160,160,40)
  triangle(-3_297,-14_167, 3_771,
           -3_297,-14_167, 3_671,
           -1_997,-14_467, 3_874)
  colour(170,170,50)
  triangle(-3_297,-14_167, 3_671,
            0_003,-14_167, 3_894,
           -1_997,-14_467, 3_874)


  writef(" // Wing root strut forward left*n")
  colour(80,80,80)
  //quad(  0_433,  0_950, 2_900,
  //       0_633,  0_950, 2_900,
  //       0_633,  1_000,     0,
  //       0_433,  1_000,     0)
   strut(0_433,  0_950,  2_900,
         0_433,  1_000,      0)

  writef(" // Wing root strut rear left*n")
  colour(80,80,80)
  //quad( -1_967,  0_950,  2_616,
  //      -1_767,  0_950,  2_616,
  //      -0_868,  1_000,      0,
  //      -1_068,  1_000,      0)
   strut(-1_967, 0_950,  2_616,
         -1_068, 1_000,      0)

   writef("// Wing root strut diag left*n")
  colour(80,80,80)
  //quad(  0_433,  0_950, 2_900,
  //       0_633,  0_950, 2_900,
  //      -0_868,  1_000,     0,
  //      -1_068,  1_000,     0)
   strut( 0_433,  0_950,  2_900,
         -1_068,  1_000,      0)

   writef("// Wing root strut forward right*n")
  colour(80,80,80)
  //quad(  0_433, -0_950, 2_900,
  //       0_633, -0_950, 2_900,
  //       0_633, -1_000,     0,
  //       0_433, -1_000,     0)
   strut(0_433, -0_950,  2_900,
         0_433, -1_000,      0)

  writef(" // Wing root strut rear right*n")
  colour(80,80,80)
  //quad( -1_967, -0_950,  2_616,
  //      -1_767, -0_950,  2_616,
  //      -0_868, -1_000,      0,
  //      -1_068, -1_000,      0)
   strut(-1_967, -0_950,  2_616,
         -1_068, -1_000,      0)

   writef("// Wing root strut diag right*n")
  colour(80,80,80)
  //quad(  0_433, -0_950, 2_900,
  //       0_633, -0_950, 2_900,
  //      -0_868, -1_000,     0,
  //      -1_068, -1_000,     0)
   strut( 0_433, -0_950,  2_900,
         -1_068,  -1_000,     0)

   writef("// Wing strut forward left*n")
  colour(80,80,80)
  //quad( -2_200,  10_000, -1_120,
  //      -2_450,  10_000, -1_120,
  //      -0_550,  10_000,  3_315,
  //      -0_300,  10_000,  3_315)
   strut(-2_200,  10_000, -1_120,
         -0_300,  10_000, 3_445)

   writef("// Wing strut rear left*n")
  colour(80,80,80)
  //quad( -4_500,  10_000, -1_260,
  //      -4_750,  10_000, -1_260,
  //      -2_850,  10_000,  3_210,
  //      -2_500,  10_000,  3_210)
   strut(-4_500,  10_000, -1_260,
         -2_500,  10_000, 3_410)

   writef("// Wing strut forward right*n")
  colour(80,80,80)
  //quad( -2_200, -10_000, -1_120,
  //      -2_450, -10_000, -1_120,
  //      -0_550, -10_000,  3_445,
  //      -0_300, -10_000,  3_445)
   strut(-2_200, -10_000, -1_120,
         -0_300, -10_000, 3_445)

   writef("// Wing strut rear right*n")
  colour(80,80,80)
  //quad( -4_500, -10_000, -1_260,
  //      -4_750, -10_000, -1_260,
  //      -2_850, -10_000,  3_210,
  //      -2_500, -10_000,  3_210)
   strut(-4_500, -10_000, -1_260,
         -2_500, -10_000, 3_410)

   writef("// Wheel strut left*n")
  colour(80,80,80)
  //quad( -0_768,  1_000, -2_000,
  //      -1_168,  1_000, -2_000,
  //      -0_468,  2_000, -3_800,
  //      -0_068,  2_000, -3_800)
   strut(-0_768,  1_000, -2_000,
         -0_068,  2_000, -3_800)

  writef(" // Wheel strut diag left*n")
  colour(80,80,80)
  //quad(  1_600,  1_000, -2_000,
  //       1_800,  1_000, -2_000,
  //      -0_368,  2_000, -3_800,
  //      -0_168,  2_000, -3_800)
   strut( 1_600,  1_000, -2_000,
         -0_168,  2_000, -3_800)

   writef("// Wheel strut centre left*n")
  colour(80,80,80)
  //quad( -0_500,  0_000, -2_900,
  //      -0_650,  0_000, -2_900,
  //      -0_318,  2_000, -3_800,
  //      -0_168,  2_000, -3_800)
   strut(-0_500,  0_000, -2_900,
         -0_168,  2_000, -3_800)

   writef("// Wheel strut right*n")
  colour(80,80,80)
  //quad( -0_768, -1_000, -2_000,
  //      -1_168, -1_000, -2_000,
  //      -0_468, -2_000, -3_800,
  //      -0_068, -2_000, -3_800)
   strut(-0_768, -1_000, -2_000,
         -0_068, -2_000, -3_800)

   writef("// Wheel strut diag right*n")
  colour(80,80,80)
  //quad(  1_600, -1_000, -2_000,
  //       1_800, -1_000, -2_000,
  //      -0_368, -2_000, -3_800,
  //      -0_168, -2_000, -3_800)
   strut( 1_600, -1_000, -2_000,
         -0_168, -2_000, -3_800)

   writef("// Wheel strut centre right*n")
  colour(80,80,80)
  //quad( -0_500, -0_000, -2_900,
  //      -0_650, -0_000, -2_900,
  //      -0_318, -2_000, -3_800,
  //      -0_168, -2_000, -3_800)
   strut(-0_500, -0_000, -2_900,
         -0_168, -2_000, -3_800)


   writef("// Left wheel*n")
  colour(20,20,20)
  quad( -0_268,       2_000, -3_800,
        -0_268,       2_100, -3_800-0_700,
        -0_268-0_500, 2_100, -3_800-0_500,
        -0_268-0_700, 2_100, -3_800)
  quad( -0_268,       2_000, -3_800,
        -0_268,       2_100, -3_800-0_700,
        -0_268+0_500, 2_100, -3_800-0_500,
        -0_268+0_700, 2_100, -3_800)
  quad( -0_268,       2_000, -3_800,
        -0_268,       2_100, -3_800+0_700,
        -0_268-0_500, 2_100, -3_800+0_500,
        -0_268-0_700, 2_100, -3_800)
  quad( -0_268,       2_000, -3_800,
        -0_268,       2_100, -3_800+0_700,
        -0_268+0_500, 2_100, -3_800+0_500,
        -0_268+0_700, 2_100, -3_800)

  quad( -0_268,       2_200, -3_800,
        -0_268,       2_100, -3_800-0_700,
        -0_268-0_500, 2_100, -3_800-0_500,
        -0_268-0_700, 2_100, -3_800)
  quad( -0_268,       2_200, -3_800,
        -0_268,       2_100, -3_800-0_700,
        -0_268+0_500, 2_100, -3_800-0_500,
        -0_268+0_700, 2_100, -3_800)
  quad( -0_268,       2_200, -3_800,
        -0_268,       2_100, -3_800+0_700,
        -0_268-0_500, 2_100, -3_800+0_500,
        -0_268-0_700, 2_100, -3_800)
  quad( -0_268,       2_200, -3_800,
        -0_268,       2_100, -3_800+0_700,
        -0_268+0_500, 2_100, -3_800+0_500,
        -0_268+0_700, 2_100, -3_800)

   writef("// Right wheel*n")
  colour(20,20,20)
  quad( -0_268,      -2_000, -3_800,
        -0_268,      -2_100, -3_800-0_700,
        -0_268-0_500,-2_100, -3_800-0_500,
        -0_268-0_700,-2_100, -3_800)
  quad( -0_268,      -2_000, -3_800,
        -0_268,      -2_100, -3_800-0_700,
        -0_268+0_500,-2_100, -3_800-0_500,
        -0_268+0_700,-2_100, -3_800)
  quad( -0_268,      -2_000, -3_800,
        -0_268,      -2_100, -3_800+0_700,
        -0_268-0_500,-2_100, -3_800+0_500,
        -0_268-0_700,-2_100, -3_800)
  quad( -0_268,      -2_000, -3_800,
        -0_268,      -2_100, -3_800+0_700,
        -0_268+0_500,-2_100, -3_800+0_500,
        -0_268+0_700,-2_100, -3_800)

  quad( -0_268,      -2_200, -3_800,
        -0_268,      -2_100, -3_800-0_700,
        -0_268-0_500,-2_100, -3_800-0_500,
        -0_268-0_700,-2_100, -3_800)
  quad( -0_268,      -2_200, -3_800,
        -0_268,      -2_100, -3_800-0_700,
        -0_268+0_500,-2_100, -3_800-0_500,
        -0_268+0_700,-2_100, -3_800)
  quad( -0_268,      -2_200, -3_800,
        -0_268,      -2_100, -3_800+0_700,
        -0_268-0_500,-2_100, -3_800+0_500,
        -0_268-0_700,-2_100, -3_800)
  quad( -0_268,      -2_200, -3_800,
        -0_268,      -2_100, -3_800+0_700,
        -0_268+0_500,-2_100, -3_800+0_500,
        -0_268+0_700,-2_100, -3_800)

   writef("// Fueltank front*n")
  colour(200,200,230)       // Top surface
  quad( 1_333,  1_000,  2_900,
        1_333, -1_000,  2_900,
        0_033, -1_000,  3_100,
        0_033,  1_000,  3_100)

   writef("// Fueltank back*n")
  colour(180,180,210)       // Top surface
  quad( 0_033,  1_000,  3_100,
        0_033, -1_000,  3_100,
       -1_967, -1_000,  2_616,
       -1_967,  1_000,  2_616)

   writef("// Fueltank left side*n")
  colour(160,160,190)
  triangle( 1_333,  1_000, 2_900,
            0_033,  1_000, 3_100,
           -1_967,  1_000, 2_616)

   writef("// Fueltank right side*n")
  colour(160,160,190)
  triangle(-0_500+1_833, -1_000, -2_000+4_900,
           -1_800+1_833, -1_000, -1_800+4_900,
           -3_800+1_833, -1_000, -2_284+4_900) 

   writef("// Fuselage*n")

   writef("// Prop shaft*n")
  colour(40,40,90)
  triangle( 5_500,     0,      0,
            4_700, 0_200, 0_300,
            4_700, 0_200,-0_300)
  colour(60,60,40)
  triangle( 5_500,     0,      0,
            4_700, 0_200,-0_300,
            4_700,-0_200,-0_300)
  colour(40,40,90)
  triangle( 5_500,     0,      0,
            4_700,-0_200,-0_300,
            4_700,-0_200, 0_300)
  colour(60,60,40)
  triangle( 5_500,     0,      0,
            4_700,-0_200, 0_300,
            4_700, 0_200, 0_300)


   writef("// Engine front lower centre*n")
  colour(140,140,160)
  triangle( 5_000,     0,      0,
            4_500, 0_350, -1_750,
            4_500,-0_350, -1_750)

   writef("// Engine front lower left*n")
  colour(140,120,130)
  triangle( 5_000,     0,      0,
            4_500, 0_350, -1_750,
            4_500, 0_550,      0)

   writef("// Engine front lower right*n")
  colour(140,120,130)
  triangle( 5_000,     0,      0,
            4_500,-0_350, -1_750,
            4_500,-0_550,      0)

   writef("// Engine front upper centre*n")
  colour(140,140,160)
  triangle( 5_000,     0,     0,
            4_500, 0_350, 0_500,
            4_500,-0_350, 0_500)

   writef("// Engine front upper left and right*n")
  colour(100,140,180)
  triangle( 5_000,     0,     0,
            4_500, 0_350, 0_500,
            4_500, 0_550,     0)
  triangle( 5_000,     0,     0,
            4_500,-0_350, 0_500,
            4_500,-0_550,     0)

   writef("// Engine left lower*n")
  colour(80,80,60)
  quad( 1_033, 1_000,      0,
        1_800, 1_000, -2_000,
        4_500, 0_350, -1_750,
        4_500, 0_550,      0)

  writef(" // Engine right lower*n")
  colour(80,100,60)
  quad( 1_033,-1_000,      0,
        1_800,-1_000, -2_000,
        4_500,-0_350, -1_750,
        4_500,-0_550,      0)

   writef("// Engine top left*n")
  colour(100,130,60)
  quad(  1_033, 0_750,  0_950,
         1_033, 1_000,  0_000,
         4_500, 0_550,  0_000,
         4_500, 0_350,  0_500)

   writef("// Engine top centre*n")
  colour(130,160,90)
  quad(  1_033, 0_750,  0_950,
         1_033,-0_750,  0_950,
         4_500,-0_350,  0_500,
         4_500, 0_350,  0_500)

   writef("// Engine top right*n")
  colour(100,130,60)
  quad(  1_033,-0_750,  0_950,
         1_033,-1_000,  0_000,
         4_500,-0_550,  0_000,
         4_500,-0_350,  0_500)

   writef("// Engine bottom*n")
  colour(100,80,50)
  quad(  4_500, 0_350, -1_750,
         4_500,-0_350, -1_750,
         1_800,-1_000, -2_000,
         1_800, 1_000, -2_000)


   writef("// Front cockpit left*n")
  colour(120,140,60)
  quad( -2_000, 1_000,  0_000,
        -2_000, 0_853,  0_600,
        -3_300, 0_853,  0_600,
        -3_300, 1_000,  0_000)

  writef(" // Front cockpit right*n")
  colour(120,140,60)
  quad( -2_000,-1_000,  0_000,
        -2_000,-0_853,  0_600,
        -3_300,-0_853,  0_600,
        -3_300,-1_000,  0_000)

   writef("// Top front left*n")
  colour(100,120,40)
  quad(  1_033, 0_750,  0_950,
        -2_000, 0_750,  1_000,
        -2_000, 1_000,  0_000,
         1_033, 1_000,  0_000)

   writef("// Top front middle*n")
  colour(120,140,60)
  quad(  1_033, 0_750,  0_950,
         1_033,-0_750,  0_950,
        -2_000,-0_750,  1_000,
        -2_000, 0_750,  1_000)

   writef("// Top front right*n")
  colour(100,120,40)
  quad(  1_033,-0_750,  0_950,
        -2_000,-0_750,  1_000,
        -2_000,-1_000,  0_000,
         1_033,-1_000,  0_000)


  writef(" // Front wind shield*n")
  colour(180,200,150)
  quad( -1_300, 0_450,  1_000, // Centre
        -2_000, 0_450,  1_400,
        -2_000,-0_450,  1_400,
        -1_300,-0_450,  1_000)
  colour(220,220,180)
  triangle( -1_300, 0_450,  1_000, // Left
            -2_000, 0_450,  1_400,
            -2_000, 0_650,  1_000)
  triangle( -1_300,-0_450,  1_000, // Right
            -2_000,-0_450,  1_400,
            -2_000,-0_650,  1_000)


   writef("// Top left middle*n")
  colour(120,165,90)
  quad( -3_300, 0_750,  1_000,
        -3_300, 1_000,  0_000,
        -4_300, 1_000,  0_000,
        -4_300, 0_750,  1_000)

   writef("// Top centre middle*n")
  colour(120,140,60)
  quad( -3_300, 0_750,  1_000,
        -3_300,-0_750,  1_000,
        -4_300,-0_750,  1_000,
        -4_300, 0_750,  1_000)

   writef("// Top right middle*n")
  colour(130,160,90)
  quad( -3_300,-0_750,  1_000,
        -3_300,-1_000,  0_000,
        -4_300,-1_000,  0_000,
        -4_300,-0_750,  1_000)

   writef("// Rear cockpit left*n")
  colour(120,140,60)
  quad( -4_300, 1_000,  0_000,
        -4_300, 0_840,  0_600,
        -5_583, 0_770,  0_600,
        -5_583, 1_000,  0_000)

   writef("// Rear wind shield*n")
  colour(180,200,150)
  quad( -3_600, 0_450,  1_000, // Centre
        -4_300, 0_450,  1_400,
        -4_300,-0_450,  1_400,
        -3_600,-0_450,  1_000)
  colour(220,220,180)
  triangle( -3_600, 0_450,  1_000, // Left
            -4_300, 0_450,  1_400,
            -4_300, 0_650,  1_000)
  triangle( -3_600,-0_450,  1_000, // Right
            -4_300,-0_450,  1_400,
            -4_300,-0_650,  1_000)



   writef("// Rear cockpit right*n")
  colour(110,140,70)
  quad( -4_300,-1_000,  0_000,
        -4_300,-0_840,  0_600,
        -5_583,-0_770,  0_600,
        -5_583,-1_000,  0_000)
   writef("// Lower left middle*n")
  colour(140,110,70)
  quad(  1_033, 1_000,      0,
         1_800, 1_000, -2_000,
        -3_583, 1_000, -2_238,
        -3_300, 1_000,      0)

  colour(155,100,70)
  triangle( -3_300, 1_000,      0,
            -3_583, 1_000, -2_238,
            -5_583, 1_000,      0)

   writef("// Bottom middle*n")
  colour(120,100,60)
  quad(  1_800, 1_000, -2_000,
        -3_583, 1_000, -2_238,
        -3_583,-1_000, -2_238,
         1_800,-1_000, -2_000)

  writef(" // Lower right middle*n")
  colour(140,100,70)
  quad(  1_033,-1_000,      0,
         1_800,-1_000, -2_000,
        -3_583,-1_000, -2_238,
        -3_300,-1_000,      0)

  colour(120,100,70)
  triangle( -3_300,-1_000,      0,
            -3_583,-1_000, -2_238,
            -5_583,-1_000,      0)

  writef(" // Lower left back*n")
  colour(165,115,80)
  quad( -5_583, 1_000,      0,
       -16_000, 0_050,      0,
       -16_000, 0_050, -0_667,
        -3_583, 1_000, -2_238)

  writef(" // Bottom back*n")
  colour(130,90,60)
  quad( -3_583, 1_000, -2_238,
       -16_000, 0_050, -0_667,
       -16_000,-0_050, -0_667,
        -3_583,-1_000, -2_238)

   writef("// Lower right back*n")
  colour(150,140,80)
  quad( -5_583,-1_000,      0,
       -16_000,-0_050,      0,
       -16_000,-0_050, -0_667,
        -3_583,-1_000, -2_238)

   writef("// Top left back*n")
  colour(130,125,85)
  triangle( -5_583, 0_650,  0_950,
            -5_583, 1_000,  0_000,
           -16_000, 0_050,      0)

   writef("// Top centre back*n")
  colour(130,160,90)
  quad( -5_583, 0_650,  0_950,
        -5_583,-0_650,  0_950,
       -16_000,-0_050,      0,
       -16_000, 0_050,      0)

   writef("// Top right back*n")
  colour(130,120,80)
  triangle( -5_583,-0_650,  0_950,
            -5_583,-1_000,  0_000,
           -16_000,-0_050,      0)

   writef("// End back*n")
  colour(120,165,95)
  quad(-16_000, 0_050,      0,
       -16_000,-0_050,      0,
       -16_000,-0_050, -0_667,
       -16_000, 0_050, -0_667)

   writef("// Fin*n")

  colour(170,180,80)
  quad(-14_000, 0_000,     0,      // Fin
       -16_000, 0_050,     0,
       -16_000, 0_100, 1_000,
       -15_200, 0_000, 1_000)
  quad(-14_000, 0_000,     0,      // Fin
       -16_000,-0_050,     0,
       -16_000,-0_100, 1_000,
       -15_200, 0_000, 1_000)
    
  colour(70,120,40)
  quadkd(-15_200,   0, 1_000, 1,-0_800, // Rudder
         -16_000, 100, 1_000, 0,     0,
         -16_800,   0, 3_100, 1, 0_800,
         -16_000,   0, 2_550, 0,     0)
  colour(70,125,30)
  quadkd(-15_200,   0, 1_000, 1,-0_800, // Rudder
         -16_000,-100, 1_000, 0,     0,
         -16_800,   0, 3_100, 1, 0_800,
         -16_000,   0, 2_550, 0,     0)
  colour(70, 80,40)
  quadkd(-16_000, 100, 1_000, 0,     0,
         -16_800,   0, 3_100, 1, 0_800,
         -17_566,   0, 2_600, 1, 1_566,
         -17_816,   0, 1_667, 1, 1_816)
  quadkd(-16_000,-100, 1_000, 0,     0,
         -16_800,   0, 3_100, 1, 0_800,
         -17_566,   0, 2_600, 1, 1_566,
         -17_816,   0, 1_667, 1, 1_866)
  colour(70,120,40)
  quadkd(-16_000, 100, 1_000, 0,     0,
         -17_816,   0, 1_667, 1, 1_816,
         -17_816,   0, 1_000, 1, 1_816,
         -17_566,   0,     0, 1, 1_566)
  quadkd(-16_000,-100, 1_000, 0,     0,
         -17_816,   0, 1_667, 1, 1_816,
         -17_816,   0, 1_000, 1, 1_816,
         -17_566,   0,     0, 1, 1_566)
  colour(70, 80,40)
  quadkd(-16_000, 100, 1_000, 0,     0,
         -17_566,   0,     0, 1, 1_566,
         -17_000,   0,-0_583, 1, 1_000,
         -16_000,   0,-0_667, 0,     0)
  quadkd(-16_000,-100, 1_000, 0,     0,
         -17_566,   0,     0, 1, 1_566,
         -17_000,   0,-0_583, 1, 1_000,
         -16_000,   0,-0_667, 0,     0)

   writef("// Tail skid*n")
  colour(40, 40, 40)
  quadkd(-16_000, 0, -0_667, 0,     0,
         -16_200, 0, -0_667, 1, 0_200,
         -16_500, 0, -0_900, 1, 0_500,
         -16_300, 0, -0_900, 1, 0_300)



   writef("// Tailplane and elevator*n")

  colour(120,180,50)
  triangle(-16_000, 0_000, 100,
           -13_900, 0_600,   0,
           -13_900,-0_600,   0)
  triangle(-16_000, 0_000,-100,
           -13_900, 0_600,   0,
           -13_900,-0_600,   0)

  colour(120,200,50)
  quad(-16_000, 2_800, 100, // Left tailplane upper
       -13_900, 0_600,   0,
       -14_600, 2_800,   0,
       -16_000, 4_500,   0)
  colour(120,180,50)
  triangle(-16_000, 0_000, 100,
           -13_900, 0_600,   0,
           -16_000, 2_800, 100)
  colour(100,200,50)
  quad(-16_000, 2_800,-100, // Left tailplane lower
       -13_900, 0_600,   0,
       -14_600, 2_800,   0,
       -16_000, 4_500,   0)
  colour(120,200,70)
  triangle(-16_000, 0_000,-100,
           -13_900, 0_600,   0,
           -16_000, 2_800,-100)

  colour(120,200,50)
  quad(-16_000,-2_800, 100, // Right tailplane upper
       -13_900,-0_600,   0,
       -14_600,-2_800,   0,
       -16_000,-4_500,   0)
  colour(120,180,50)
  triangle(-16_000, 0_000, 100,
           -13_900,-0_600,   0,
           -16_000,-2_800, 100)
  colour(100,200,50)
  quad(-16_000,-2_800,-100, // Right tailplane lower
       -13_900,-0_600,   0,
       -14_600,-2_800,   0,
       -16_000,-4_500,   0)
  colour(120,200,70)
  triangle(-16_000, 0_000,-100,
           -13_900,-0_600,   0,
           -16_000,-2_800,-100)

  colour(165,100,50) 
  quadkd(-16_000,     0, 100, 0,     0, // Left elevator
         -17_200, 0_600,   0, 2, 1_200, // pt 1
         -17_500, 0_900,   0, 2, 1_500, // pt 2
         -16_000, 2_800, 100, 0,     0)
  quadkd(-16_000,     0,-100, 0,     0, // Left elevator
         -17_200, 0_600,   0, 2, 1_200, // pt 1
         -17_500, 0_900,   0, 2, 1_500, // pt 2
         -16_000, 2_800,-100, 0,     0)

  colour(170,150,80) 
  quadkd(-16_000, 2_800, 100, 0,  0, // Left elevator
         -17_500, 0_900,   0, 2, 1_500, // pt 2
         -17_666, 2_000,   0, 2, 1_666, // pt 3
         -17_650, 3_500,   0, 2, 1_650) // pt 4
  quadkd(-16_000, 2_800,-100, 0,     0, // Left elevator
         -17_500, 0_900,   0, 2, 1_500, // pt 2
         -17_666, 2_000,   0, 2, 1_666, // pt 3
         -17_650, 3_500,   0, 2, 1_650) // pt 4

  colour(120,170,60) 
  quadkd(-16_000, 2_800, 100, 0,     0, // Left elevator
         -17_650, 3_500,   0, 2, 1_650, // pt 4
         -17_200, 4_650,   0, 2, 1_200, // pt 5
         -16_700, 4_833,   0, 2, 0_700) // pt 6
  quadkd(-16_000, 2_800,-100, 0,     0, // Left elevator
         -17_650, 3_500,   0, 2, 1_650, // pt 4
         -17_200, 4_650,   0, 2, 1_200, // pt 5
         -16_700, 4_833,   0, 2, 0_700) // pt 6

  colour(160,120,40) 
  quadkd(-16_000, 2_800, 100, 0,     0, // Left elevator
         -16_700, 4_833,   0, 2, 0_700, // pt 6
         -16_300, 4_750,   0, 2, 0_300, // pt 7
         -16_000, 4_500,   0, 0,     0) // pt 8
  quadkd(-16_000, 2_800,-100, 0,     0, // Left elevator
         -16_700, 4_833,   0, 2, 0_700, // pt 6
         -16_300, 4_750,   0, 2, 0_300, // pt 7
         -16_000, 4_500,   0, 0,     0) // pt 8




  colour(165,100,50) 
  quadkd(-16_000,     0, 100, 0,     0, // Right elevator
         -17_200,-0_600,   0, 2, 1_200, // pt 1
         -17_500,-0_900,   0, 2, 1_500, // pt 2
         -16_000,-2_800, 100, 0,     0)
  quadkd(-16_000,     0,-100, 0,     0, // Right elevator
         -17_200,-0_600,   0, 2, 1_200, // pt 1
         -17_500,-0_900,   0, 2, 1_500, // pt 2
         -16_000,-2_800,-100, 0,     0)

  colour(170,150,80) 
  quadkd(-16_000,-2_800, 100, 0,     0, // Right elevator
         -17_500,-0_900,   0, 2, 1_500, // pt 2
         -17_666,-2_000,   0, 2, 1_666, // pt 3
         -17_650,-3_500,   0, 2, 1_650) // pt 4
  quadkd(-16_000,-2_800,-100, 0,     0, // Right elevator
         -17_500,-0_900,   0, 2, 1_500, // pt 2
         -17_666,-2_000,   0, 2, 1_666, // pt 3
         -17_650,-3_500,   0, 2, 1_650) // pt 4

  colour(120,170,60) 
  quadkd(-16_000,-2_800, 100, 0,     0, // Right elevator
         -17_650,-3_500,   0, 2, 1_650, // pt 4
         -17_200,-4_650,   0, 2, 1_200, // pt 5
         -16_700,-4_833,   0, 2, 0_700) // pt 6
  quadkd(-16_000,-2_800,-100, 0,     0, // Right elevator
         -17_650,-3_500,   0, 2, 1_650, // pt 4
         -17_200,-4_650,   0, 2, 1_200, // pt 5
         -16_700,-4_833,   0, 2, 0_700) // pt 6

  colour(160,120,40) 
  quadkd(-16_000,-2_800, 100, 0,     0, // Right elevator
         -16_700,-4_833,   0, 2, 0_700, // pt 6
         -16_300,-4_750,   0, 2, 0_300, // pt 7
         -16_000,-4_500,   0, 2,     0) // pt 8
  quadkd(-16_000,-2_800,-100, 0,     0, // Right elevator
         -16_700,-4_833,   0, 2, 0_700, // pt 6
         -16_300,-4_750,   0, 2, 0_300, // pt 7
         -16_000,-4_500,   0, 0,     0) // pt 8

  colour(165,100,50) 
  quadkd(-16_000,     0, 100, 0,     0, // Right elevator
         -17_200,-0_600,   0, 2, 1_200, // pt 1
         -17_500,-0_900,   0, 2, 1_500, // pt 2
         -16_000,-2_800, 100, 0,     0)
  quadkd(-16_000,     0,-100, 0,     0, // Right elevator
         -17_200,-0_600,   0, 2, 1_200, // pt 1
         -17_500,-0_900,   0, 2, 1_500, // pt 2
         -16_000,-2_800,-100, 0,     0)


// Construct the landscape and runway
  writef("// Runway*n")

  { MANIFEST { ns = 50_000
               ws =  5_000
             }
    FOR n = 0 TO 600_000-ns BY ns DO
      FOR w = -20_000 TO 20_000-ws BY ws DO
      { LET m = (17*n XOR 5*w)>>1
        LET r = 150 + m MOD 23
        LET g = 160 + m MOD 13
        LET b = 170 + m MOD 37
        quadland( n,       w, 1_000, r,  g, b,
                  n,    w+ws, 1_000, r,  g, b,
                  n+ns, w+ws, 1_000, r,  g, b,
                  n+ns,    w, 1_000, r,  g, b)
      }
  }
  writef("// The land*n")
  // Plot a square region of land
  plotland(-5_000_000, -5_000_000, 10_000_000)
}

AND strut(t1, w1, l1, t4, w4, l4) BE
{ LET t2 = (3*t1+t4)/4
  LET w2 = (3*w1+w4)/4
  LET l2 = (3*l1+l4)/4
  LET t3 = (3*t4+t1)/4
  LET w3 = (3*w4+w1)/4
  LET l3 = (3*l4+l1)/4
  LET ta, wa =  50, 30
  LET tb, wb = 110, 50

  colour(80,80,80)
  quad(t1-ta,w1,l1, t1,w1+wa,l1, t2,w2+wb,l2, t2-tb,w2,l2)
  colour(85,75,80)
  quad(t1-ta,w1,l1, t1,w1-wa,l1, t2,w2-wb,l2, t2-tb,w2,l2)
  colour(85,80,85)
  quad(t1,w1+wa,l1, t1+ta,w1,l1, t2+tb,w2,l2, t2,w2+wb,l2)
  colour(75,80,80)
  quad(t1,w1-wa,l1, t1+ta,w1,l1, t2+tb,w2,l2, t2,w2-wb,l2)

  colour(90,80,80)
  quad(t2-tb,w2,l2, t2,w2+wb,l2, t3,w3+wb,l3, t3-tb,w3,l3)
  colour(95,75,80)
  quad(t2,w2+wb,l2, t2+tb,w2,l2, t3+tb,w3,l3, t3,w3+wb,l3)
  colour(90,85,80)
  quad(t2+tb,w2,l2, t2,w2-wb,l2, t3,w3-wb,l3, t3+tb,w3,l3)
  colour(80,80,85)
  quad(t2,w2-wb,l2, t2-tb,w2,l2, t3-tb,w3,l3, t3,w3-wb,l3)


  colour(80,80,80)
  quad(t4-ta,w4,l4, t4,w4+wa,l4, t3,w3+wb,l3, t3-tb,w3,l3)
  colour(85,75,80)
  quad(t4-ta,w4,l4, t4,w4-wa,l4, t3,w3-wb,l3, t3-tb,w3,l3)
  colour(85,80,85)
  quad(t4,w4+wa,l4, t4+ta,w4,l4, t3+tb,w3,l3, t3,w3+wb,l3)
  colour(75,80,80)
  quad(t4,w4-wa,l4, t4+ta,w4,l4, t3+tb,w3,l3, t3,w3-wb,l3)
}

AND height(n, w) = VALOF
{ // Make it zero on or near the runway.
  // Make it small near the runway and typically larger
  // away from the runway.
  LET size = landsize
  LET halfsize = size/2
  LET h = randheight(n, w,
                     -halfsize, +halfsize, // x coords
                     -halfsize, +halfsize, // y coords
                      0, 0, 0, 0)          // corner heights
  LET dist = (ABS(n - runwaylength/2)) + (ABS(w))
  LET factor = ?   // Will be in the range 0 to 1_000 depending on dist
  LET d1, d2 = 600_000, 3_000_000
  IF dist <= d1 DO factor := 0
  IF dist >= d2 DO factor := 1_000
  IF d1<dist<d2 DO factor := muldiv(1_000, dist-d1, d2-d1)
  // factor is a function of dist. Below d1 it is zero. Between
  // d1 and d2 it grows linearly to 1_000. Above d2 it remains at 1_000.
//sawritef("dist=%9.3d  factor=%6.3d h=%i9*n", dist, factor, h)
  h := muldiv(h, factor, 1_000) / 1000
//sawritef("h=%i9  h^2=%i9*n", h, h*h)
  RESULTIS (h * h)
}

AND randvalue(x, y, max) = VALOF
{ LET a = 123*x >> 1
  LET b = 541*y >> 3
  LET hashval = ABS((a*b XOR b XOR #x1234567)/3)
  hashval := hashval MOD (max+1)
//sawritef("randvalue: (%i9 %i9 %i9) => %i4*n", x, y, max, hashval) 
  RESULTIS hashval
}

AND randheight(x, y, x0, x1, y0, y1, h0, h1, h2, h3) = VALOF
{ // Return a random height depending on x and y only.
  // The result is in the range 0 to 1000
  LET k0, k1, k2, k3 = ?, ?, ?, ?
  LET size = x1-x0
  LET sz   = size>1_000_000 -> 1_000_000, size/2
  LET sz2  = sz/2

  TEST sz < 100_000
  THEN { // Use linear interpolation based on the heights
         // of the corners.
         // The formula is
         //     h = a + bp + cq + dpq
         // where a = h0
         //       b = h1 - h0
         //       c = h2 - h0
         //       d = h3 - h2 - h1 + h0
         //       p = (x-x0)/(x1-x0) 
         // and   q = (y-y0)/(y1-y0) 
         // This formula agrees with the heights at four the vertices,
         // and for fixed x it is linear in y, and vice-versa.
         LET a = h0
         LET b = h1-h0
         LET c = h2-h0
         LET d = h3-h2-h1+h0
         b := muldiv(b, x-x0, x1-x0)
         c := muldiv(c, y-y0, y1-y0)
         d := muldiv(muldiv(d, x-x0, x1-x0), y-y0, y1-y0)
         RESULTIS a+b+c+d
       }
  ELSE { // Calculate the heights of the vertices of the 1/2 sized square
         // containing x,y.
         LET mx = (x0+x1)/2
         LET my = (y0+y1)/2
         LET mh = (h0+h1+h2+h3)/4 + randvalue(mx, my, sz) - sz2
         TEST x<mx
         THEN TEST y<my
              THEN { // Lower left
                     LET k1 = (h0+h1)/2 + randvalue(mx, y0, sz) - sz2
                     LET k2 = (h0+h2)/2 + randvalue(x0, my, sz) - sz2
                     h1, h2, h3 := k1, k2, mh
                     x1, y1 := mx, my
                     LOOP
                   }
              ELSE { // Upper left
                     LET k0 = (h0+h2)/2 + randvalue(x0, my, sz) - sz2
                     LET k3 = (h2+h3)/2 + randvalue(mx, y1, sz) - sz2
                     h0, h1, h3 := k0, mh, k3 
                     x1, y0 := mx, my
                     LOOP
                   }
         ELSE TEST y<my
              THEN { // Lower right
                     LET k0 = (h0+h1)/2 + randvalue(mx, y0, sz) - sz2
                     LET k3 = (h1+h3)/2 + randvalue(x1, my, sz) - sz2
                     h0, h2, h3 := k0, mh, k3
                     x0, y1 := mx, my
                     LOOP
                   }
              ELSE { // Upper right
                     LET k1 = (h1+h3)/2 + randvalue(x1, my, sz) - sz2
                     LET k2 = (h0+h2)/2 + randvalue(mx, y1, sz) - sz2
                     h0, h1, h2 := mh, k1, k2
                     x0, y0 := mx, my
                     LOOP
                   }
       }
} REPEAT

AND plotland(n, w, size) BE
{ LET sz = size/80
  FOR i = 0 TO 79 DO
  { LET n0 = n + i*sz
    LET n1 = n0 + sz
    FOR j = 0 TO 79 DO
    { LET w0 = w + j*sz
      LET w1 = w0 + sz
      LET h0 = height(n0, w0)
      LET h1 = height(n0, w1)
      LET h2 = height(n1, w1)
      LET h3 = height(n1, w0)
      LET r, g, b = redfn(n0,w0,h0), greenfn(n0,w0,h0), bluefn(n0,w0,h0)
//sawritef("calling qualdland(%n,%n,%n,...)*n", n0, w0, h0)
      //quadland(n0,w0,h0, r, g, b,
      //         n0,w1,h1, r, g, b,
      //         n1,w1,h2, r, g, b,
      //         n1,w0,h3, r, g, b)
      triangleland( n0,w0,h0, r,  g, b,
                    n0,w1,h1, r,  g, b,
                    n1,w1,h2, r,  g, b)
      triangleland( n0,w0,h0, r XOR 16,  g XOR 16, b XOR 16,
                    n1,w1,h2, r XOR 16,  g XOR 16, b XOR 16,
                    n1,w0,h3, r XOR 16,  g XOR 16, b XOR 16)

    }
  } 
}

AND plotland1(x0, y0, sx, sy, h0, h1, h2, h3) BE
{ // This construct a rectangle of land with its south western corner
  // at (x0,y0) using world coordinates. The east-west size of the
  // square is sx, and sy is the north-south size. The vertices are
  // numbered 0 to 3 anticlockwise starting ar (x0,y0). 
  LET x2, y2 = x0+sx, y0+sy

  TEST sx > 1000_000
  THEN { FOR i = 0 TO 9 DO
         { LET xa = (x0 * (10-i) + x2 *  i   ) / 10
           LET xb = (x0 * ( 9-i) + x2 * (i+1)) / 10
           LET sx1 = xb-xa

           LET ha = (h0 * (10-i) + h1 *  i   ) / 10
           LET hb = (h0 * ( 9-i) + h1 * (i+1)) / 10
           LET hc = (h2 * ( 9-i) + h2 * (i+1)) / 10
           LET hd = (h2 * (10-i) + h3 *  i   ) / 10

           ha := ha + height(xa, y0, sx1)
           hb := hb + height(xa, y0, sx1)
           hc := hc + height(xb, y2, sx1)
           hd := hd + height(xb, y2, sx1)

           FOR j = 0 TO 9 DO
           { LET ya = (y0 * (10-j) + y2 *  j   ) / 10
             LET yb = (y0 * ( 9-j) + y2 * (j+1)) / 10
             LET sy1 = yb-ya

             LET ka = (ha * (10-j) + hd *  j   ) / 10
             LET kb = (hb * ( 9-j) + hc * (j+1)) / 10
             LET kc = (hb * ( 9-j) + hc * (j+1)) / 10
             LET kd = (ha * (10-j) + hd *  j   ) / 10

             ka := ka + height(xa, ya, sy1)
             kb := kb + height(xb, ya, sy1)
             kc := kc + height(xb, yb, sy1)
             kd := kd + height(xa, yb, sy1)

             plotland(xa, ya, sx1, sy1, ka, kb, kc, kd)
           }
         }
       }
  ELSE { LET r, g, b = redfn(x0,y0,h0), greenfn(x0,y0,h0), bluefn(x0,y0,h0)
sawritef("calling qualdland(%n,%n,%n,...)*n", x0, y0, h0)
         quadland(x0,y0,h0, r, g, b,
                  x0,y2,h1, r, g, b,
                  x2,y2,h2, r, g, b,
                  x2,y0,h3, r, g, b)
       }
}

AND redfn(x,y,h)  = VALOF
{ LET col = 10 + h/3_000 +
            ((x * 12345)>>1) MOD  17 +
            ((y * 23456)>>1) MOD  37 +
            ((h * 34567)>>1) MOD  53
  IF col > 255 DO col := 255
  RESULTIS col
}

AND greenfn(x,y,h) = VALOF
{ LET col = 150 + h/3_000 +
            ((x * 123456)>>1) MOD  17 +
            ((y * 234567)>>1) MOD  37 +
            ((h * 345678)>>1) MOD  53
  IF col > 255 DO col := 255
  RESULTIS col
}

AND bluefn(x,y,h) = VALOF
{ LET col = 20 + h/3_000 +
            ((x * 1234567)>>1) MOD  17 +
            ((y * 2345678)>>1) MOD  37 +
            ((h * 3456789)>>1) MOD  53
  IF col > 255 DO col := 255
  RESULTIS col
}


