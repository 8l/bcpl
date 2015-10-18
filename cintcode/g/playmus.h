/*
This is the header file for playmus.b

Wriiten by Martin Richards (c) February 2009
*/

GLOBAL {
// BGPM globals
bg_s:ug
bg_t
bg_h
bg_p
bg_f
bg_c
bg_e
bg_ch

bggetch; bgputch;  bgwrnum
bgpush
error

bgpmco
bgpmfn

playmus_version // eg "Playmus v2.0"
sysin; sysout; sourcestream; tostream
sourcenamev; sourcefileno; sourcefileupb
getstreams
lineno      // <fno/ln> of latest character obtained by bggetch
nextlineno  // <fno/ln> of the next character obtained by bggetch
plineno     // <fno/ln> of latest character given to bgputch 
tokln       // fno/ln of the first character of the current token

startbarno  // Number of the first bar to play
endbarno    // Number of the last bar to play
start_msecs // Midi msecs of the start of the first bar to play
end_msecs   // Midi msecs of the end of the last bar to play

optPp; optLex; optTree; optPtree
optStrace   // Trace the creation of parse tree nodes.
optNtrace   // Trace notes as they are generated.
optMtrace   // Trace Midi commands as they are played.
tempoadj    // playing tempo adjustment as a percentage, 100=don't adjust
accompany   // =TRUE if accompaning
pitch       // Number of semitones to transpose every note up by
graphdata   // =TRUE to generate graph data
calibrating // =TRUE if calibrating Midi to Mic delay
waiting     // =TRUE if playmidi waits before playing
quitting    // =TRUE if quitting
die         // Function to cause a coroutine to commit suicide
killco      // Killer coroutine

notecount   // Count of recognised note events
totalerr    // Sum of all note event errors

newvec; mk1; mk2; mk3; mk4; mk5; mk6; mk7; mk8; mk9
// Return blks to their free lists
unmk1; unmk2; unmk3; unmk4; unmk5; unmk6; unmk7; unmk8; unmk9
// The free lists for ewach size
mk1list; mk2list; mk3list; mk4list; mk5list
mk6list; mk7list; mk8list; mk9list

blklist  // List of blocks of work space
blkb
blkp
blkt
blkitem
//treevec; treep; treet
bg_base; bg_baseupb; rec_p; rec_l; fin_p; fin_l

debugv              // To hold system debug flags 0 to 9
errcount; errmax
fatalerr; synerr; fatalsynerr
trerr
strv       // Short term sting buffer, typically for op names
fnolnstrv  // Short term sting buffer for <fno/ln> strings

appendmus // Append .mus to a file name
rch; ch; chbuf; chbufln; chcount; formtree; tree
prnote; prtree; opstr; prlineno
token; numval; noteletter; prevnoteletter
prevoctave; reloctave; notenumber; noteqbeats
notesharps; notelengthnum; prevlengthnum; dotcount
bgexp; bgbexp; argp; argt
wrc; wrs; chpos; charv; wordnode; stringval
rdtag
rdnum
dsw
lookupword
rdstrch
nametable
noteqbeats

checkfor
rdscore
rdscores
rdshape
rdnoteprim
rdnoteitem
rdnoteitems
rdnumber
rdinteger
rdstring

insertblocks
blockneeded
initshapeitems

// Globals for the translation stage
trscores
trscore
qbeatlength
shapelistlength
shapescan
prblockenv
istied
prties

currpartname
midichannel

veclist        // List of vectors that must be freevec'd
pushval
transposition  // Number of semitones to transpose this part up by
conductorblk

qbeats         // The qbeat position of the current item
currbarno      // Current bar number used in trscores
maxbarno       // Total number of bars in the piece
maxbeatno      // Total number of beats in the piece,
               // ie the sum of beats in each bar
barqerr
barno2qbeats
qbeats2barno
qbeats2msecs
barno2msecs
midilist       // The start of the midi list -> [link, msecs, <midi triple>]
midiliste      // Pointer to the last midi list item, or 0.
editnoteoffs
mergesort
prmidilist
fnoln2str      // s := fnoln2str(ln, fnolnstr)
note2str       // s := note2str(noteno, str)

scbase  // Parameters for scaling local qbeats to absolute qbeats
scfaca  // using
scfacb  //        absqbeat = scbase + muldiv(q, scfaca, scfacb)
        // or
qscale  //        absqbeat = qscale(q)

plist   // Previous tlist just before current par or tuplet construct.
pqpos   // Abs qbeat terminating position of items in ptlist
tlist   // Outstanding ties in the current note thread
tqpos   // Abs qbeat terminating position of items in tlist
clist   // Outstanding ties in the other concurrent note threads
cqpos   // Abs qbeat terminating position of items in clist

// Player globals
getrealmsecs
midichannel // 0 .. 15
getshapeval
lookupshapeval
playmidi
micbuf
tempodata     // Mapping from absolute qbeat values to msecs
              // tempodata!i the time is msecs of absolute qbeat 32*i

barmsecs      // Mapping from bar number to midi msecs
beatmsecs     // mapping from beat number to midi msecs

solochannels  // Bit pattern with 1<<chan set if chan is a solo channel

baseday       // Used by getrealmsecs
rmsecs0       // real msecs at startmsecs

currbarno     // Used by msecs2barno
currbeatno    // Used by msecs2beatno
soundv        // Buffer of cumulative data
soundp        // Position of next element of soundv to be updated
soundval      // Latest soundv element
soundmsecs    // real msecs of latest sound sample in soundv

genmidi

notecofn
soundco       // Coroutine to read sound samples into soundv
soundcofn
keyco         // The coroutine reading the keyboard
keycofn
playmidico    // The coroutine to output midi data
playmidicofn

bartabcb      // The bar table control block
bartab        // Mapping from bar number to qbeat (later msec) values
beattabcb     // The beat table control block
beattab       // Mapping from beat number to qbeat (later msec) values
barno
timesiga      // eg 6
timesigb      // eg 8
qbeatsperbeat // = 4096/timesigb, ie 1024 for crotchet beats
prevbeatqbeat // The qbeats value of the previous beat
beatcount     // Count of the most recent beat. In 6 8 time
              // beatcount will be 1, 2, 3, 4, 5,or 6. It must
              // be 1 at the next time signature or bar line. 

notecov       // Vector of recognition coroutines for notes 0..127
notecoupb     // Note coroutines are from votecov!1 to notecov!notecoupb
notecop       // Position of next note coroutine to run

freqtab       // Frequency table for notes 0..127
initfreqtab   // Function to initialise freqtab

eventv        // Circular table of recent events [mt, rt, weight, op]
              // Each event is separated from previous by at least 10 msecs.
              // op=-1 for a barline event, =-2 for a beat event,
              // otherwise it is a note-number.
eventp        // Position in eventv to store the next event item.
prevrt        // Real time of the most recent event in eventv, the next event
              // must be at least 10 msecs later.
pushevent     // Put and event in the eventv circular buffer.
newevents     // =TRUE when a newevent is in eventv. It is reset by calcrates

calcrates     // Calculate new estimated and correction play lines
clearevents   // Remove all previous events

msecsbase     // Real time at first call of getrealmsecs
real_msecs    // msecs since msecsbase
midi_msecs    // Current midi time

variablevol   // TRUE means volume can change while a not is being played.
chanvol       // -1 or the current channel volume

// The following two variables are used to convert between real and midi msecs.

ocr; ocm; crate // The origin of the current play line
oer; oem; erate // The origin of the estimated play line

r2m_msecs     // (r, or, om, rate) This converts real to midi msecs using
              // om + muldiv(real_msecs-or, rate, 1000)
m2r_msecs     // (r, or, om, rate) This converts midi to real msecs using
              // or + muldiv(real_msecs-om, 1000, rate)

calcrates     // Function to compute new values for play_rate, play_offset
              // curr_rate, curr_offset and revert_msecs. These values are
              // based on their previous values and the events in eventv.

calc_msecs    // Real time when calcrates should next be called.

midifd
micfd

pushbyte
pushh
pushw
pushw24
pushstr
pushpfx
pushnum
packw

//selectbank
//selectpatch

writemidi
wrmid1
wrmid2
wrmid3
}

MANIFEST {
nametablesize = 541
blkupb = 10_000
micbufupb = 1023
soundvupb = #xFFFF // Room for about 1.5 seconds of sound
eventvupb = 4*20-1 // Allow for 20 event items [rt, mt, weight, note]

// BGPM markers
s_eof     =  -2
s_eom     =  -3

// BGPM builtin macros
s_def     =  -4
s_set     =  -5
s_get     =  -6
s_eval    =  -7
s_lquote  =  -8
s_rquote  =  -9
s_comment = -10
s_char    = -11
s_rep     = -12
s_rnd     = -13  // Signed random number
s_urnd    = -14  // Unsigned random number

// BGPM special characters
c_call    = '$'
c_apply   = ';'
c_sep     = '!'
c_comment = '%' 
c_lquote  = '<'
c_rquote  = '>'
c_arg     = '#'

// General selectors
h1=0; h2; h3; h4; h5; h6; h7; h8; h9

// Lex tokens and other symbols
s_altoclef=1          // [-, Altoclef, ln]
s_arranger            // [-, Arranger, ln, str]
s_bank                // [-, Bank, ln, byte, byte]
s_barlabel            // [-, Barlabel, ln, str]
s_barline             // [-, Barline, ln]
s_bassclef            // [-, Bassclef, ln]
s_block               // [-, Block, ln, note_item,
                      //     envblk, shapeitems, qstart, qend]
s_colon               // [-, Colon, ln, qlen]
s_composer            // [-, Composer, ln, str]
s_conductor           // [-, Conductor, ln, note-item]
s_control             // [-, Control, ln, byte, byte]
s_delay               // [-, Delay, ln, note_item, shapelist]
s_delayadj            // [-, Delayadj, ln, note_item, shapelist]
s_doublebar           // [-, Doublebar, ln]
s_instrument          // [-, Instrument, ln, str]
s_instrumentname      // [-, Instrumentname, ln, str]
s_instrumentshortname // [-, Instrumentshortname, ln, str]
s_interval            // [-, Interval, ln, msecs]
s_keysig              // [-, Keysig, ln, note, mode]
s_lcurly
s_legato              // [-, Legato, ln, note_item, shapelist]
s_legatoadj           // [-, Legatoadj, ln, note_item, shapelist]
s_legon               // [-, Legon, ln]
s_legoff              // [-, Legoff, ln]
s_list
s_lparen
s_lsquare
s_major               // A mode
s_minor               // A mode
s_msecsmap            // [-, Msecsmap, v]
s_name                // [-, Name, ln, str]
s_neg
s_nonvarvol           // [-, Nonvarvol, ln]
s_note                // [-, Note, ln, <letter,sharps,n>, qlen]
s_notetied            // [-, Notetied, ln, <letter,sharps,n>, qlen]
s_null                // [-, Null, ln]
s_num                 // [-, Num, ln, value]
s_numtied             // [-, Numtied, ln, value]
s_opus                // [-, Opus, ln, str]
s_par                 // [-, Par, ln, note_list, qlen]
s_part                // [-, Part, ln, body, channel]
s_partlabel           // [-, partlabel, ln, str]
s_patch               // [-, patch, ln, byte]
s_pedon               // [-, Pedon, ln]
s_pedoff              // [-, Pedoff, ln]
s_pedoffon            // [-, Pedoffon, ln]
s_portaon             // [-, Portaon, ln]
s_portaoff            // [-, Portaoff, ln]
s_rcurly
s_repeatback          // [-, Repeatback, ln]
s_repeatbackforward   // [-, Repeatforwardback, ln]
s_repeatforward       // [-, Repeatforward, ln]
s_rest                // [-, Rest, ln, qlen]
s_rparen
s_rsquare
s_score               // [-, Score, ln, str, conductor, parts]
s_seq                 // [-, Seq, ln, note_list, qlen]
s_space               // [-, Space, ln, qlen]
s_star                // [-, Star, ln]
s_startied            // [-, Startied, ln]
s_string
s_softon              // [-, Softon, ln]
s_softoff             // [-, Softoff, ln]
s_solo                // [-, Solo, ln, body, channel]
s_tempo               // [-, Tempo, ln, note_item, shapelist]
s_tempoadj            // [-, Tempo, ln, note_item, shapelist]
s_tenorclef           // [-, Tenorclef, ln]
s_timesig             // [-, Timesig, ln, byte, byte]
s_title               // [-, Title, ln, str]
s_transposition       // [-, Transposition, ln, semitones_up]
s_trebleclef          // [-, Trebleclef, ln]
s_tuplet              // [-, Tuplet, ln, note_item, note_item]
s_varvol              // [-, Varvol, ln]
s_vibrate             // [-, Vibrate, ln, note_item, shapelist]
s_vibrateadj          // [-, Vibrateadj, ln, note_item, shapelist]
s_vibamp              // [-, Vibamp, ln, note_item, shapelist]
s_vibampadj           // [-, Vibampadj, ln, note_item, shapelist]
s_vol                 // [-, Vol, ln, note_item, shapelist]
s_voladj              // [-, Voladj, ln, note_item, shapelist]
s_volmap              // [-, Volmap, ln, shapelist]
s_word

// MIDI opcodes
midi_note_off     = #x80
midi_note_on      = #x90
midi_keypressure  = #xA0
midi_control      = #xB0
midi_progchange   = #xC0
midi_chanpressure = #xD0
midi_pitchbend    = #xE0
midi_sysex        = #xF0
}
