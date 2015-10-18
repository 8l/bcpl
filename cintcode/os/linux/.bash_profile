# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

HOST=`/sbin/ifconfig | grep Bcast | sed -e "s/.*inet addr://; s/ .*//"`
HOST=`ipcalc -h $HOST`
HOST=`echo $HOST | sed -e "s/HOSTNAME=//"`

#HOST=`hostname`:
HOST=`expr $HOST : '\([^.]*\)'`
export HOST

PS1=$HOST"$ "
export PS1

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

BCPLROOT=$HOME/distribution/BCPL/cintcode
BCPLPATH=$BCPLROOT/cin
BCPLHDRS=$BCPLROOT/g
PATH=$PATH:$BCPLROOT/bin

BCPL64ROOT=$HOME/distribution/BCPL64/cintcode
BCPL64PATH=$BCPL64ROOT/cin
BCPL64HDRS=$BCPL64ROOT/g
PATH=$PATH:$BCPL64ROOT/bin

MCPLROOT=$HOME/distribution/MCPL/mintcode
MCPLPATH=$MCPLROOT/min
MCPLHDRS=$MCPLROOT/g
PATH=$PATH:$MCPLROOT/bin

POSROOT=$HOME/distribution/Cintpos/cintpos
POSPATH=$POSROOT/cin
POSHDRS=$POSROOT/g
PATH=$PATH:$POSROOT/bin

PVSROOT=$HOME/PVS
PVSPATH=$PVSROOT/commobj:$PVSROOT/taskobj:$PVSROOT/bin
PVSHDRS=$PVSROOT/pvshdr
PATH=$PATH:$PVSROOT/bin

MRPVSROOT=$HOME/MRPVS
MRPVSPATH=$MRPVSROOT/cin:$POSROOT/cin
MRPVSHDRS=$MRPVSROOT/pvshdr:$POSROOT/g

MUSHDRS=$HOME/distribution/Musprogs/g

PATH=$PATH:.

export BCPLROOT BCPLPATH BCPLHDRS
export BCPL64ROOT BCPL64PATH BCPL64HDRS
export MCPLROOT MCPLPATH MCPLHDRS
export POSROOT POSPATH POSHDRS
export PVSROOT PVSPATH PVSHDRS
export MRPVSROOT MRPVSPATH MRPVSHDRS
export MUSHDRS

export PATH
unset USERNAME

export PRINTER=acacia

date >BASHDATE
@echo ".bash_profile run\n"
