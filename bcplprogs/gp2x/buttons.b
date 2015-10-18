GET "libhdr"

MANIFEST {
 b_up         = 1<<0
 b_up_left    = 1<<1
 b_left       = 1<<2
 b_down_left  = 1<<3
 b_down       = 1<<4
 b_down_right = 1<<5
 b_right      = 1<<6
 b_up_right   = 1<<7
 b_start      = 1<<8
 b_select     = 1<<9
 b_fl         = 1<<10
 b_fr         = 1<<11
 b_fa         = 1<<12
 b_fb         = 1<<13
 b_fx         = 1<<14
 b_fy         = 1<<15
 b_vol_up     = 1<<16
 b_vol_down   = 1<<17
 b_tat        = 1<<18  
}

LET start() = VALOF
{ LET prev = 0
  writef("*nButton test entered*n*n")
  writef("Press any buttons -- pressing X will exit*n*n")

  { LET buttons = sys(Sys_buttons)
    writef("buttons=%x8*n", buttons)
    UNLESS buttons=prev DO
    {
      IF (buttons & b_up        )~=0 DO writef("Joystick UP*n")
      IF (buttons & b_up_left   )~=0 DO writef("Joystick UP_LEFT*n")
      IF (buttons & b_left      )~=0 DO writef("Joystick LEFT*n")
      IF (buttons & b_down_left )~=0 DO writef("Joystick DOWN_LEFT*n")
      IF (buttons & b_down      )~=0 DO writef("Joystick DOWN*n")
      IF (buttons & b_down_right)~=0 DO writef("Joystick DOWN_RIGHT*n")
      IF (buttons & b_right     )~=0 DO writef("Joystick RIGHT*n")
      IF (buttons & b_up_right  )~=0 DO writef("Joystick UP_RIGHT*n")
      IF (buttons & b_start     )~=0 DO writef("START*n")
      IF (buttons & b_select    )~=0 DO writef("SELECT*n")
      IF (buttons & b_fl        )~=0 DO writef("BUTTON LEFT*n")
      IF (buttons & b_fr        )~=0 DO writef("BUTTON RIGHT*n")
      IF (buttons & b_fa        )~=0 DO writef("A*n")
      IF (buttons & b_fb        )~=0 DO writef("B*n")
      IF (buttons & b_fx        )~=0 DO writef("X*n")
      IF (buttons & b_fy        )~=0 DO writef("Y*n")
      IF (buttons & b_vol_up    )~=0 DO writef("VOL_UP*n")
      IF (buttons & b_vol_down  )~=0 DO writef("VOL_DOWN*n")
      IF (buttons & b_tat       )~=0 DO writef("TAT*n")
    }
    prev := buttons
  } REPEATUNTIL (prev&b_fx)~=0 | prev<0

  TEST prev<0
  THEN writef("*nExiting -- unable to read the buttons*n")
  ELSE writef("*nExiting because X was hit*n")
  RESULTIS 0
}
