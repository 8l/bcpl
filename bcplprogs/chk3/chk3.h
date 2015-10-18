// Header for the chk3 programs

GLOBAL {
 relspace: ug   // Space for the relation nodes
 relspacep      // Position of next relation node
 relspaceupb    // Upb of relspace

 relv           // Vector of relations, bounds 1..reln
 reln           // Number of relations
 relvupb        // Upb of relv

 maxid          // Variable ids are in the range 1..maxid

 refs           // refs!i is list of each relation using i (i>=2)
 refcount       // refcount!i is the length of refs!i (i>=2)

 varinfo        // information about each variable number i, as follows:

                // varinfo!i = -2      was used in only one relation
                // varinfo!i = -1      nothing known about vi
                // varinfo!i =  0      if vi = 0
                // varinfo!i =  1      if vi = 1
                // varinfo!i =  2*j    if vi = vj
                // varinfo!i =  2*j+1  if vi =~vj

 id2orig        // mapping from new variable numbers to the original ones.
                // id2orig!0 is zero or the parent mapping vector.
 origid         // function to find the original id using id2orig

 relstack       // Stack of relations that have recently changed
 relstackp      // Top of relstack -- points to latest item pushed
 relstackupb    // Upb of relstack

 tracing        // Cause trace output to be generated
 debug          // To control debugging


 // Boolean matrices
 matn           // (=maxid) Size of matrix
 matnw          // Number of 32-bit words in a row

 mata           //  vi ->  vj
 matb           //  vi -> ~vj
 matc           // ~vi ->  vj
 matd           // ~vi -> ~vj

 // The matrices before the latest changes
 mataprev       //  vi ->  vj
 matbprev       //  vi -> ~vj
 matcprev       // ~vi ->  vj
 matdprev       // ~vi -> ~vj

// Functions in chk3
 rdrels         // Read relations in from a given file
 rdhex          // Read a hex number, ignoring comments
 rdnum          // Read a decimal number, ignoring comments
 
 wrrels         // Write relations out to file
 wrrel          // Write a relation out to file

 // Functions in module trans1

 testtrans1      // Test all functions in module trans1

 exchargs        // Exchange arguments i and j in a relation
 ignorearg       // remove argument i assuming it is unconstrained
 standardise     // Standardise a relation


 // Functions in module apfns

 testapfns       // Test all the functions in this module

 apnot           // Negate argument i in a relation

 apis1           // Apply  ai  =   1
 apis0           // Apply  ai  =   0
 apeq            // Apply  ai  =  aj
 apne            // Apply  ai ~=  aj

 apimppp         // Apply  ai ->  aj
 apimppn         // Apply  ai -> ~aj
 apimpnp         // Apply ~ai ->  aj
 apimpnn         // Apply ~ai -> ~aj

 // Functions in module apvar

 testapvar       // Test all the functions in this module

 ignorevar       // eliminate an ignorable varible from a relation

 apvarset1       // Apply  vi  =   1 to all relations
 apvarset0       // Apply  vi  =   0 to all relations
 apvareq         // Apply  vi  =  vj to all relations
 apvarne         // Apply  vi ~=  vj to all relations

 apvarimppp      // Apply  vi ->  vj to all relations
 apvarimppn      // Apply  vi -> ~vj to all relations
 apvarimpnp      // Apply ~vi ->  vj to all relations
 apvarimpnn      // Apply ~vi -> ~vj to all relations

 // Functions in module tests

 testfindimps    // Test all the functions in this module

 findimps

 // Functions in module bmat

 testbmat        // Test all the functions in this module

 bm_setmatsize   // Set the size of the boolean matrices
 bm_mkmat        // Allocate and clear the boolean matices
 bm_clrmat       // Clear the boolean matrices
 bm_warshall     // Form the transitive closure
 bm_setbitpp     // Set the bits corresponding to  vi ->  vj
 bm_setbitpn     // Set the bits corresponding to  vi -> ~vj
 bm_setbitnp     // Set the bits corresponding to ~vi ->  vj
 bm_setbitnn     // Set the bits corresponding to ~vi -> ~vj
 bm_setvar0      // Set the bits corresponding to  vi = 0
 bm_setvar1      // Set the bits corresponding to  vi = 1
 bm_setvareq     // Set the bits corresponding to  vi = vj
 bm_setvarne     // Set the bits corresponding to  vi =~vj
 bm_setbit       // Set an individual bit
 bm_prmat        // Output a matrix
 bm_findnewinfo  // Find bits that have changed


 // Functions in module engine

 testengine       // Test all the functions in this module

 explore          // Apply the recursive explore algorithm

 // Functions in module utils

 testutils        // Test all the functions in this module

 bug              // Report programming bug

 pairblks
 freepairs
 newrel
 mkrel
 mk2
 unmk2

 ch
 token
 lexval
 
 rdrels
 wrrels
 formlists
 length

 wrvars

 pushrel          // Push a relation onto the relstack
 poprel           // Pop an item off the relstack

 rmref            // remove ref to a relation for a specified variable

 // Functions in module debug

 checkeqv         // Check that two relations are equivalent
 inittest         // Reset the global environment
 testallvars      // Exercise a test function
 selfcheck        // Debugging functions
 selftest
 selftesting
 evalrel
}

MANIFEST {
 // Relation node fields
 r_w0=0
 r_a0; r_a1; r_a2
 r_instack  // TRUE if this relation is in relstack
 r_weight   // Cumulative variable use counts
 r_varcount // Number variables -- unused ones are zero
 r_numb     // Relation number
 r_upb

 relnmax=1000
 //relspaceupb=relnmax*r_upb

 // rdrels symbols
 s_eof=1
 s_var
 s_bits
}

