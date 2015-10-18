// Header for TRIPOS CLI and some commands.

//    (e.g. C, SPOOL, STACK, etc.)

MANIFEST
{
return_severe    =  20
return_hard      =  10
return_soft      =   5
return_ok        =   0
cli_module_gn    =  149
cli_initialstack =  50000       // Changed 21/5/2001
cli_initialfaillevel = return_hard



// cli_state flags
clibit_noprompt  =  #b000000001  // Don't output a prompt
clibit_eofdel    =  #b000000010  // Delete this task if EOF received
clibit_comcom    =  #b000000100  // Currently execution a command-command
clibit_maincli   =  #b000001000  // Executing the main CLI
clibit_newcli    =  #b000010000  // Executing a new CLI
clibit_runcli    =  #b000100000  // Executing a CLI invoked by run
clibit_mbxcli    =  #b001000000  // Executing an MBX CLI
clibit_tcpcli    =  #b010000000  // Execution a TCP CLI
clibit_endcli    =  #b100000000  // endcli has been executed on this CLI
}

GLOBAL
{
cli_tallyflag:     132
cli_init:          133
cli_result2:       134
cli_data:          135  // CLI dependent data  MR 10/7/03
cli_commanddir:    136
cli_returncode:    137
cli_commandname:   138
cli_faillevel:     139
cli_prompt:        140
cli_standardinput: 141
cli_currentinput:  142
cli_commandfile:   143  // Name of temporary command file used in
                        // command-commands
cli_status:        144  // Contains the CLI status flags
cli_preloadlist:   145
cli_currentoutput: 146
cli_defaultstack:  147
cli_standardoutput:148
cli_module:        149
}
