#! /bin/sh
#
# import-gnulib.sh -- imports a copy of gnulib into findutils
# Copyright (C) 2003,2004,2005,2006,2007 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
# USA.
#
##########################################################################
#
# This script is intended to populate the "gnulib" directory
# with a subset of the gnulib code, as provided by "gnulib-tool".
#
# To use it, just run this script with the top-level sourec directory 
# as your working directory.

# If CDPATH is set, it will sometimes print the name of the directory
# to which you have moved.  Unsetting CDPATH prevents this, as does
# prefixing it with ".".
unset CDPATH

## Defaults
# cvsdir=/doesnotexist
configfile="./import-gnulib.config"
need_checkout=yes


usage() {
    cat >&2 <<EOF
usage: $0 [-d gnulib-directory]

The default behaviour is to check out the Gnulib code via anonymous
CVS (or update it if there is a version already checked out).  The
checkout or update is performed to the gnulib version indicated in
the configuration file $configfile.

If you wish to work with a different version of gnulib, use the -d option
to specify the directory containing the gnulib code.
EOF
}


do_checkout () {
    local cvsdir="$1"
    echo checking out gnulib from CVS in $cvsdir

    if [ -z "$gnulib_version" ] ; then
        echo "Error: There should be a gnulib_version setting in $configfile, but there is not." >&2
        exit 1
    fi
    
    
    if ! [ -d "$cvsdir" ] ; then	
        if mkdir "$cvsdir" ; then
    	echo "Created $cvsdir"
        else
    	echo "Failed to create $cvsdir" >&2
    	exit 1
        fi
    fi
    
    # Decide if gnulib_version is probably a date or probably a tag.  
    if date -d yesterday >/dev/null ; then
        # It looks like GNU date is available
        if date -d "$gnulib_version" >/dev/null ; then
    	# Looks like a date.
    	cvs_sticky_option="-D"
        else
    	echo "Warning: assuming $gnulib_version is a CVS tag rather than a date" >&2
    	cvs_sticky_option="-r"
        fi
    else
    	# GNU date unavailable, assume the version is a date
    	cvs_sticky_option="-D"
    fi



    (
        # Change directory unconditionally (rater than  using checkout -d) so that
        # cvs does not pick up defaults from ./CVS.  Those defaults refer to our
        # own CVS repository for our code, not to gnulib.
        cd $cvsdir 
        if test -d gnulib/CVS ; then
    	cd gnulib
    	cmd=update
    	root="" # use previous 
        else
    	root="-d :pserver:anonymous@cvs.sv.gnu.org:/sources/gnulib"
    	cmd=checkout
    	args=gnulib
        fi
        set -x
        cvs -q -z3 $root  $cmd $cvs_sticky_option "$gnulib_version" $args
        set +x
    )
}

run_gnulib_tool() {
    local tool="$1"
    if test -f "$tool"
    then
        true
    else
        echo "$tool does not exist, did you specify the right directory?" >&2
        exit 1
    fi
    
    if test -x "$tool"
    then
        true
    else
        echo "$tool is not executable" >&2
        exit 1
    fi
    
    
    if [ -d gnulib ]
    then
        echo "Warning: directory gnulib already exists, removing it." >&2
        rm -rf gnulib
    fi
    mkdir gnulib
    
    set -x
    if "$tool" --import --symlink --with-tests --dir=. --lib=libgnulib --source-base=gnulib/lib --m4-base=gnulib/m4  $modules
    then
        set +x
    else
        set +x
        echo "$tool failed, exiting." >&2
        exit 1
    fi
}


hack_gnulib_tool_output() {
    local gnulibdir="${1}"
    for file in $extra_files; do
      case $file in
        */mdate-sh | */texinfo.tex) dest=doc;;
        *) dest=build-aux;;
      esac
      test -d "$dest" || mkdir "$dest"
      cp -fp "${gnulibdir}"/"$file" "$dest" || exit
    done




    cat > gnulib/Makefile.am <<EOF
# Copyright (C) 2004 Free Software Foundation, Inc.
#
# This file is free software, distributed under the terms of the GNU
# General Public License.  As a special exception to the GNU General
# Public License, this file may be distributed as part of a program
# that contains a configuration script generated by Automake, under
# the same distribution terms as the rest of that program.
#
# This file was generated by $0 $@.
#
SUBDIRS = lib
EOF
}


refresh_output_files() {
    aclocal -I m4 -I gnulib/m4     &&     
    autoheader                     &&     
    autoconf                       &&     
    automake --add-missing --copy 
}


update_version_file() {
    local ver
    outfile="lib/gnulib-version.c"
    if [ -z "$gnulib_version" ] ; then
	ver="unknown (locally modified code; no version number available)"
    else
	ver="$gnulib_version"
    fi
    

    cat > "${outfile}".new <<EOF
/* This file is automatically generated by $0 and simply records which version of gnulib we used. */
const char * const gnulib_version = "$ver";
EOF
    if test -f "$outfile" ; then
	if diff "${outfile}".new "${outfile}" > /dev/null ; then
	    rm "${outfile}".new
	    return 0
	fi
    fi
    mv "${outfile}".new "${outfile}"
}


main() {
    ## Option parsing
    local gnulibdir=/doesnotexist
    while getopts "d:" opt
    do
      case "$opt" in
          d)  gnulibdir="$OPTARG" ; need_checkout=no ;;
          **) usage; exit 1;;
      esac
    done

    # We need the config file to tell us which modules 
    # to use, even if we don't want to know the CVS version.
    . $configfile || exit 1

    ## If -d was not given, do CVS checkout/update
    if [ $need_checkout = yes ] ; then
        do_checkout gnulib-cvs
	gnulibdir=gnulib-cvs/gnulib
    else
        echo "Warning: using gnulib code which already exists in $gnulibdir" >&2
    fi
    
    ## Invoke gnulib-tool to import the code.
    local tool="${gnulibdir}"/gnulib-tool

    if run_gnulib_tool "${tool}" && 
	hack_gnulib_tool_output "${gnulibdir}" &&
	refresh_output_files && 
	update_version_file   ; then
	echo Done.
    else
	echo FAILED >&2
	exit 1
    fi
}

main "$@"
