// The header file for chk8.b

GLOBAL {
 spacev: ug     // A stack-like area to hold various vectors and other items.
 spacep         // Position of next free location
 spacet         // Pointer to the last word of spacev.

 origid         // function to map id to its original id.

 tracing        // Cause trace output to be generated.

 checkno        // The self testing check number.


 // Information about the current set of relations

 relv           // Vector of relations, bounds 1..reln
                // relv!0 holds the number of relations

 relcount       // The number of non-deleted relations.

 maxid          // The largest id used in the current set of relations.

 idvecs         // idvecs!id and idvecs!(id-1) point to the first
                // and last elements of a vector holding the relations
                // that use id. If a relation is deleted it entry here
                // is cleared.

 idcountv       // idcountv!id is the length of idvecs!id.

 rellist        // The list of relation nodes that need further processing.

 mat            // The current  2nx2n matrix composed of the concatenations
                // of four nxn matrices A, B, C and D.
                // mat!0 = n.

 matprev        // The previous version ob mat.
                // The difference between mat and matprev gives
                // the newly discovered information.

 intmat         // The intersection matrix used in explorechildren.

 varinfo        // Information about each variable.
                // varinfo!i = -3            The value of vi is not known,
                //                           but there is some information
                //                           about vi stored in mat. This
                //                           information is of the form
                //                           vi=vj, vi=~vj, ~vi->vj or ~vi->~vj
                // varinfo!i = -2            vi was deleted since nothing was
                //                           known about vi and it appeared in
                //                           only one relation.
                // varinfo!i = -1            Nothing is known about vi
                // varinfo!i =  0            vi =  0
                // varinfo!i =  1            vi =  1
                // varinfo!i = 2j   (i>j>0)  vi =  vj
                // varinfo!i = 2j+1 (i>j>0)  vi = ~vj

 id2prev        // This is zero or the vector mapping id to its
                // previous identifier number.
                // id2prev!0 is zero or the parent mapping vector.

 maxdepth       // The current maximum depth allowed by the algorithm.

 // Functions in chk8
 rdrels         // Read relations in from a given file
 rdhex          // Read a hex number, ignoring comments
 rdnum          // Read a decimal number, ignoring comments
 
 // Functions in module trans1

 exchargs        // Exchange arguments i and j in a relation.
 ignorearg       // Remove argument i assuming it is unconstrained.
 isunconstrained // Returns TRUE if the specified relation places
                 // no constraint on the specified argument.
 standardised    // Returns TRUE if the given relation is in standard form
 standardise     // Sort relation arguments and remove duplicates.

 split           // Attempt to split a relation into two factors.

 // Functions in module apfns
 // These apply newly discovered information about one or two
 // arguments of a relation.

 apnot             // Negate argument i in a relation

 apset1            // Apply  ai  =   1
 apset0            // Apply  ai  =   0
 apeq              // Apply  ai  =  aj
 apne              // Apply  ai ~=  aj

 apimppp           // Apply  ai ->  aj
 apimppn           // Apply  ai -> ~aj
 apimpnp           // Apply ~ai ->  aj
 apimpnn           // Apply ~ai -> ~aj

 setunconstrainedarg  // (rel, argi) modify the bit pattern so that
                      // argument argi is unconstrained.

 // Functions in module apvar
 // These apply newly discovered information about one or two
 // variables to every relevent relation.

 ignorevar         // eliminate a variable that is only used once.

 apvarset1         // Apply  vi  =   1 to all relations
 apvarset0         // Apply  vi  =   0 to all relations
 apvareq           // Apply  vi  =  vj to all relations
 apvarne           // Apply  vi ~=  vj to all relations

 apvarimppp        // Apply  vi ->  vj to all relations
 apvarimppn        // Apply  vi -> ~vj to all relations
 apvarimpnp        // Apply ~vi ->  vj to all relations
 apvarimpnn        // Apply ~vi -> ~vj to all relations

 combine           // Apply COMBINE and RESTRICT to a pair of relations
 addarg            // Add an unconstrained variable to a relation
 sortargs          // Sort the arguments of a relation



 // Functions in module relimps

 imptab          // A 32x256x4 matrix of implication bit patterns
                 // set by setimptab and used by findimps.

 setimptab       // Initialise the implication table

 findimps        // Function to find the previously undiscovered
                 // implications implied by a given relation.
                 // It sets newpp, newpn, newnp and newnn and
                 // updates the fields prevpp, prevpn, prevnp
                 // and prevnn in the relation node.
 primps          // Print the given implication bit patterns

 // Functions in module bmat.

 bm_mk         // Allocate a boolean matrix.
 bm_pr         // Output a matrix.
 bm_set        // Set every element to zero or one.
 bm_copy       // Copy one matrix into another.
 bm_and        // AND one matrix into another. Return FALSE
               //    if the resulting matrix contains one(s).
 bm_or         // OR  one matrix into another.

 bm_imppp      // Set the bits corresponding to  vi ->  vj
 bm_imppn      // Set the bits corresponding to  vi -> ~vj
 bm_impnp      // Set the bits corresponding to ~vi ->  vj
 bm_impnn      // Set the bits corresponding to ~vi -> ~vj

 bm_set0       // Set the bits corresponding to  vi = 0
 bm_set1       // Set the bits corresponding to  vi = 1
 bm_seteq      // Set the bits corresponding to  vi = vj
 bm_setne      // Set the bits corresponding to  vi =~vj

 bm_setbit     // Set an individual bit.
 bm_warshall   // Form the transitive closure of the given matrix.
 bm_apnewinfo  // Apply the information in mat that is
               // not in matprev, and update matprev.
               // Information of the form vi=0, vi=1,
               // vi=vj and vi~=vj is stored in varinfo
               // and vi to be eliminated from all relations.
               // If vi=~vi then the current set of relations
               // cannot be satisfied.
               // New information of the form
               // vi->vj, vi->~vj, ~vi->vj and ~vi->~vj
               // is used to simplify the relations.

 // Functions in module engine

 explore          // explore(depth)
                  // If depth<= maxdepth apply the algorithm
                  // recursively to the current relations,
                  // returning:

                  //    TRUE, result2=FALSE  if unsatisfiable.
                  //    TRUE, result2=TRUE   if satisfiable
                  //    FALSE answer not known using this maxdepth.

 explorechildren  // Set up and explore each child of the current
                  // using a given pivot relation.

 // Functions in module utils
 utils            // utils module

 bug              // Report programming bug

 pairblks
 freepairs
 mk2
 unmk2

 ch
 token
 lexval
 lineno
 
 rdrels
 wrrels
 wrrel

 renameidentifiers
 invec            // (x, v, n) return TRUE if x is in v!0 .. v!(n-1)
 length           // Return the length of a list

 wrvars

 pushrel          // Push a relation onto the stack
 poprel           // Pop an item off the stack

 rmref            // remove ref to a relation for a specified variable

 andrelbits1
 andrelbits2
 andrelbits4
 andrelbits8v

 // Functions in module debug

 selfcheck        // Debugging functions
}

MANIFEST {
 spaceupb = 200000 // The total amount of work space

 // Relation node fields
 r_link=0 // Pointer to next relation mode.

 r_w0; r_w1; r_w2; r_w3; r_w4; r_w5; r_w6; r_w7 // The relation bit pattern
 r_a; r_b; r_c; r_d; r_e; r_f; r_g; r_h // The argument variabl numbers

 // The relation bit pattern is held in fields w0 to w7
 // w0 holds bits 0 to 31, w1 holds bits 32 to 63, etc.
 // The bits are numbered from the least significant end.

 // bit   0 is 1 if hgfedcba can be 00000000
 // bit   1 is 1 if hgfedcba can be 00000001
 // bit   2 is 1 if hgfedcba can be 00000010
 // ...
 // bit 254 is 1 if hgfedcba can be 11111110
 // bit 255 is 1 if hgfedcba can be 11111111

 r_inrellist // TRUE if this relation is in rellist, a list linked using
             // the r_link field.
 r_args      // Number of non zero arguments. After simplication
             // all zero arguments will be at the end of the argument list.
 r_relno     // Relation number - position in relv.
 r_deleted   // TRUE if the relation is no longer of interest.
             // It is either always satisfied or subsumes another relation
             // or information in the matrix.

 r_prevpp    // Previously known implications  ai ->  aj  i>j
 r_prevpn    // Previously known implications  ai -> ~aj  i>j
 r_prevnp    // Previously known implications ~ai ->  aj  i>j
 r_prevnn    // Previously known implications ~ai -> ~aj  i>j

 r_size         // Number of words in a relation node
 r_upb=r_size-1 // The UPB of a relation node

 // rdrels symbols
 s_eof=1
 s_var
 s_bits
}

