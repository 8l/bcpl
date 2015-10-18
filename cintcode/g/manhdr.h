/*      SYSTEM MANIFESTS

        Aborts
        Actions
        Errors
*/


MANIFEST
$( // Aborts:
   Abort_impossible     = 299
   Abort_ictionnotnnown = 298
   Abort_keyoutofrange  = 297
   Abort_discerror      = 296
   Abort_badfreelock    = 295
   Abort_discfull       = 294
   Abort_invalidchecksum        = 293
   Abort_loadsegfailure = 292
   Abort_createtaskfailure      = 291
   Abort_keyalreadyallocated    = 290
   Abort_keyalreadyfree = 289
   Abort_objecttoolarge = 288
   Abort_bitmapcorrupt  = 287
   Abort_sequence_error = 286     // file handler three error


   // Actions: for device handler task packets

   Action_nil=0
   Action_startup=100 // Leave 1 - 99 free 
   Action_getblock
   Action_untilfree
   Action_setmap
   Action_die

   Action_resumework
   Action_locateobject

   Action_setaccess
   Action_write
   Action_read
   Action_closeinput
   Action_closeoutput
   Action_closeinoutput
   Action_close
   Action_end
   Action_freelock
   Action_deleteobject
   Action_renameobject
   Action_getremipaddr   // for TCPHAND   MR 3/4/03

   Action_copydir
   Action_note
   Action_point
   Action_createdir
   Action_examineobject
   Action_examinenext
   Action_discinfo

   Action_findinput
   Action_findoutput
   Action_findinoutput
   Action_findappend

   Action_setcomment        // special version of FH3

   Action_aliasobject       // For Fileserver FH only
   Action_setroot           // For Fileserver FH only

   Action_endtoinput
   Action_rewind

   Action_self_immolation       // For COHAND
   Action_ttyin                 // For COHAND
   Action_ttyout                // For COHAND
   Action_exclusiveinput        // For COHAND  MR 28/4/03
   Action_exclusiverdch         // For COHAND  MR 28/4/03
   Action_devices               // For COHAND  MR 28/4/03

   Action_debug                 // For TCPHAND etc  MR 26/1/04

   // Environment vector offsets:
   Envec_szblk          = 1
   Envec_secorg         = 2
   Envec_nsur           = 3
   Envec_nsecblk        = 4
   Envec_nblktrk        = 5
   Envec_nresblk        = 6
   Envec_prefac         = 7
   Envec_intfac         = 8
   Envec_lowcyl         = 9
   Envec_upcyl          = 10
   Envec_nbuffers       = 11


   // Errors:
   Error_getvecfailure  = 103
   Error_nodefaultdir   = 201
   Error_objectinuse    = 202
   Error_objectexists   = 203
   Error_dirnotfound    = 204
   Error_objectnotfound = 205
   Error_badstreamname  = 206
   Error_objecttoolarge = 207
   Error_busy           = 208
   Error_actionnotknown = 209
   Error_invalidcomponentname   = 210
   Error_invalidlock    = 211
   Error_objectwrongtype        = 212
   Error_discnotvalidated       = 213
   Error_discwriteprotected     = 214
   Error_renameacrossdevices    = 215
   Error_directorynotempty      = 216
   Error_toomanylevels          = 217
   Error_device_not_mounted     = 218
   Error_point_error            = 219
   Error_commenttoobig		= 220	// special modified FH3

   // Fileserver filing system errors

   error_insufficientaccess     = 230
   Error_nomoreentries          = 232
   Error_illegaldelete          = 233
   Error_file_in_root           = 234  // Attempt to create file in root dir
   Error_open_in_fs             = 2214
   Error_invalid_uid            = 2217
$)
