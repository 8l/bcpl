// Tests on relations chk8

GET "libhdr"
GET "chk3.h"

// Discover all the relations of the form 
// vi -> vj, vi->~vj, ~vi->vj and ~vi->~vj
// implied by relation rel. For any such discovery it calls
// bm_setbitpp(vi, vj), bm_setbitpp(vi, vj), bm_setbitpp(vi, vj)
// bm_setbitnn(vi, vj).
LET findimps(rel) BE
// rel need not be in standard form, ie the variables can be
// in any order and any may be zero

// The relation bits are defined as follows:

//     [abcdefgh, v0, v1, v2]

// v0   01010101
// v1   00110011
// v2   00001111

// ie d=1 means v0=1, v1=1, v2=0 is a valid setting.

{ LET a = rel!r_w0
  LET v0, v1, v2 = rel!r_v0, rel!r_v1, rel!r_v2

  IF v2 DO
  { IF (a&#xF0)=0 DO bm_setvar0(v2)  // v2 must be zero
    IF (a&#x0F)=0 DO bm_setvar1(v2)  // v2 must be one
    IF v1 DO // Find implications involving v2 and v1
    { IF (a&#x0C)=0 DO bm_setbitpp(v1, v2) //  v1 -> v2
      IF (a&#xC0)=0 DO bm_setbitpn(v1, v2) //  v1 ->~v2
      IF (a&#x03)=0 DO bm_setbitnp(v1, v2) // ~v1 -> v2
      IF (a&#x30)=0 DO bm_setbitnn(v1, v2) // ~v1 ->~v2
    }
    IF v0 DO // Find implications involving v2 and v0
    { IF (a&#x0A)=0 DO bm_setbitpp(v0, v2) //  v0 -> v2
      IF (a&#xA0)=0 DO bm_setbitpn(v0, v2) //  v0 ->~v2
      IF (a&#x05)=0 DO bm_setbitnp(v0, v2) // ~v0 -> v2
      IF (a&#x50)=0 DO bm_setbitnn(v0, v2) // ~v0 ->~v2
    }
  }
  IF v1 DO
  { IF (a&#xCC)=0 DO bm_setvar0(v1)  // v1 must be zero
    IF (a&#x33)=0 DO bm_setvar1(v1)  // v1 must be one
    IF (a&#x66)=0 DO bm_setvareq(v1, v0)  // v1=v0
    IF (a&#x99)=0 DO bm_setvarne(v1, v0)  // v1=~v0
    IF v0 DO // Find implications involving v1 and v0
    { IF (a&#x22)=0 DO bm_setbitpp(v0, v1) //  v0 -> v1
      IF (a&#x88)=0 DO bm_setbitpn(v0, v1) //  v0 ->~v1
      IF (a&#x11)=0 DO bm_setbitnp(v0, v1) // ~v0 -> v1
      IF (a&#x44)=0 DO bm_setbitnn(v0, v1) // ~v0 ->~v1
    }
  }
  IF v0 DO
  { IF (a&#xAA)=0 DO bm_setvar0(v0)  // v0 must be zero
    IF (a&#x55)=0 DO bm_setvar1(v0)  // v0 must be one
  }
}
