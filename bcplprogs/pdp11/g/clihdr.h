// Header for TRIPOS CLI and some commands
// (e.g. C, SPOOL, STACK, etc.)

MANIFEST
$(
   return.severe        =  20
   return.hard          =  10
   return.soft          =   5
   return.ok            =   0
   flag.break           =   1
   flag.commbreak       =   2
   cli.module.gn        =  149
   cli.initialstack     =  500                  // LSI4TRIPOS, 68000TRIPOS
// cli.initialstack     =  700                  // 8086TRIPOS
   cli.initialfaillevel = return.hard
$)

GLOBAL
$(
   cli.init             : 133
   cli.result2          : 134
   cli.undefglobval     : 135
   cli.commanddir       : 136
   cli.returncode       : 137
   cli.commandname      : 138
   cli.faillevel        : 139
   cli.prompt           : 140
   cli.standardinput    : 141
   cli.currentinput     : 142
   cli.commandfile      : 143
   cli.interactive      : 144
   cli.background       : 145
   cli.currentoutput    : 146
   cli.defaultstack     : 147
   cli.standardoutput   : 148
   cli.module           : 149
$)


