$ cxx /DEFINE="forVmsItanium" cintsys.c
$ cxx /DEFINE="forVmsItanium" /NOOPTIMIZE cinterp.c
$ cxx /DEFINE="forVmsItanium" /DEFINE="FASTyes" /object=fasterp cinterp.c
$ cxx /DEFINE="forVmsItanium" kblib.c
$ cxx /DEFINE="forVmsItanium" nrastlib.c
$ cxx /DEFINE="forVmsItanium" sdlfn.c
$ cxx /DEFINE="forVmsItanium" sdldrawlib.c
$ link cintsys, cinterp, fasterp, kblib, nrastlib, sdlfn, sdldrawlib
