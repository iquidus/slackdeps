#!/bin/bash

# make-slacklist.sh

## Copyright 2012 Luke Williams, xocel@iquidus.org
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This script is a part of slackdeps, it is used to generate a blacklist from a local 
# slackware mirror. It writes each package found to a blacklist which can then be used 
# by slackdeps.

SCR_NAME=$(basename $0)     # Name of this script
VERSION=20120908			# Current version of this script
SLACKLIST="/etc/slackdeps/slacklist" # Slacklist

function usage {
	# Print usage
	cat << EOF

Usage: make-slacklist.sh [options] <local mirror>

This script is a part of slackdeps, it is used to generate a blacklist from a local 
slackware mirror. It writes each package found to a blacklist which can then be used 
by slackdeps. It can be used like this:
    make-slacklist.sh /path/to/local/slack/mirror
    
options:    -e, --exclude-dir <directory name> (Excludes a package directory)

Exclude Dir:
	Excludes a single package directory (Packages in this directory will not be 
	written to the blacklist). <directory name> is the directories name, e.g xap.
	It can be used like this:
		make-slacklist.sh -e xap /mirror/slackware64-current slack
	
	To exclude multiple packages you can use the option more than once. e.g
		make-slacklist.sh -e xap -e kde /mirror/slackware64-current slack
EOF
}

packageName () {
	# Accepts long/full package name.
	# E.g gimp-2.6.11-x86_64-1.txz or gimp-2.6.11-x86_64-1
	# Echo's shortname e.g gimp
	# Handles names with hyphons, e.g xine-lib-1.1.19-x86_64-2 returns xine-lib 
	PKG=($(echo $1 | tr "-" "\n"))
	PKG_NAME=${PKG[0]}
	if [ ${#PKG[@]} -gt 4 ]; then
		# Name most likely contains one or more '-'
		# So put it back together	
		ENDLOOP=$((${#PKG[@]} - 3))
		COUNT=1
		while [ $COUNT -lt $ENDLOOP ]; do
			PKG_NAME="$PKG_NAME-${PKG[$COUNT]}"
			COUNT=$(($COUNT + 1))
		done
	fi
	echo $PKG_NAME
}

PACKAGES=()
EXCLUDE=()
MIRROR=""
OUTPUT=""

if [ $# -lt 1 ]; then
	usage
	exit 1
fi

while [ 0 ]; do
	if [ "$1" == "--exclude-dir" -o "$1" == "-e" ]; then
		if [ ! -z $2 ]; then
			EXCLUDE=("${EXCLUDE[@]}" "$2")
		else
			usage
			exit 1
		fi
		shift 2
	else
		MIRROR=$1
		OUTPUT="$SLACKLIST"
		shift 1
		break
	fi
done

if [ "$MIRROR" == "" ]; then
	usage
	exit 1
fi

FIND_ARGS=""

if [ "${#EXCLUDE[@]}" -gt 0 ]; then
	for e in "${EXCLUDE[@]}"; do
		FIND_ARGS="$FIND_ARGS-depth -not -path *slackware*/$e/* "
	done
fi

FIND_ARGS="$FIND_ARGS-type f -name *.txz -or -name *.tgz -or -name *.tlz -or -name *.tbz"

# Find packages
for i in $(find $MIRROR/slackware*/ $FIND_ARGS); do
	PACKAGES=("${PACKAGES[@]}" $(packageName $(basename $i)))
done

# Remove duplicates
PACKAGES=($(echo ${PACKAGES[@]} | tr " " "\n" | sort -u))

if [ -e "$OUTPUT" ]; then
	rm "$OUTPUT"
fi

# Write to output file 
for x in "${PACKAGES[@]}"; do
	echo "$x" >> "$OUTPUT"
done