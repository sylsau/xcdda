#!/bin/bash - 
#===============================================================================
#
#          FILE: xcdda.sh
# 
#         USAGE: ./xcdda.sh 
# 
#   DESCRIPTION: Simple and efficient audio CD ripping and tagging tool.
#     Rip audio CD to fully tagged FLAC media files without using the internet. 
#     Output to current directory.
# 
#       OPTIONS: ---
#  REQUIREMENTS: cdrdao, cdparanoia, cuetools, ffmpeg
#          BUGS: ---
#        AUTHOR: Sylvain Saubier (ResponSyS), mail@sylsau.com
#       CREATED: 06/09/16 23:32
#===============================================================================

[[ $DEBUG ]] && set -o nounset
set -o pipefail -o errexit -o errtrace
trap 'echo -e "ERROR: at ${FUNCNAME:-top level}:$LINENO\nPlease delete the working directory before executing this command again."' ERR

readonly PROGRAM_NAME="${0##*/}"
readonly SCRIPT_NAME="${0##*/}"
# Compute version from script moddate
RES="$( stat -c %y $0 | cut -d" " -f1 )"
readonly VERSION=${RES//-/}

readonly FFMPEG=${FFMPEG:-ffmpeg}
readonly CUETAG=${CUETAG:-cuetag} # might be cuetag.sh on Arch

## NOT USED
# Command used to run a program as admin (sudo), used to set the speed of CD drive with cdrdao
# Can be: 'pkexec' (Debian), 'gksudo' (Arch) or simply 'sudo'
#readonly RUN_AS_ADMIN=${RUN_AS_ADMIN:-pkexec}

readonly ERR_NO_CMD=10
readonly ERR_WRONG_ARG=30

readonly BASENAME='cdda'
readonly WORKDIR='/tmp/XCDDA'
TRACK_EXT='.flac'
TRACK_BITRATE='1000k'
LIST='list_wav.txt'
KEEP_FILES=0

# $1 = command to test (string)
fn_need_cmd() {
    if ! command -v "$1" > /dev/null 2>&1
    then fn_err "need '$1' (command not found)" $ERR_NO_CMD
    fi
}
# $1 = message (string)
m_say() {
    echo -e "$PROGRAM_NAME: $1"
}
# $1 = error message (string), $2 = return code (int)
fn_err() {
    m_say "'\e[1m'ERROR'\e[0m': $1" >&2
    exit $2
}

fn_help() {
    cat << EOF
$PROGRAM_NAME v${VERSION}
Simple and efficient audio CD ripping and tagging tool. Rip audio CD to fully tagged
FLAC media files without using the internet. Output to current directory.

REQUIREMENTS
	cdrdao, cdparanoia, cuetools, ffmpeg

USAGE
	$PROGRAM_NAME [-h|--help] [-k|--keep-files] [-f|--format FORMAT] [-b|--bitrate BITRATE]

		FORMAT 		Final output formats of the tracks (default: flac)
		BITRATE 	Bitrate of output tracks, in the format (NUMBER)k (default: 1000k)

HOW IT WORKS
	1. extract TOC file (cdrdao)
	2. convert TOC to CUE (cueconvert)
	3. extract audio data to WAV files (cdparanoia)
	4. convert WAV files to format of your choice (ffmpeg)
	5. tag FLAC files from CUE file (cuetag)

AUTHOR
	Written by Sylvain Saubier (<https://sylsau.com>)

REPORTING BUGS
	Mail at: <feedback@sylsau.com>
EOF
}

fn_need_cmd "cdrdao"
fn_need_cmd "cueconvert"
fn_need_cmd "cdparanoia"
fn_need_cmd "${FFMPEG}"
fn_need_cmd "${CUETAG}"
fn_need_cmd "cueprint" # requirement of cuetag
#fn_need_cmd "${RUN_AS_ADMIN}"

if test -n "$*"; then
    # Individually check provided args
    while test -n "$1" ; do
        case $1 in
            "-h"|"--help")
                fn_help
                exit
                ;;
            "-b"|"--bitrate")
                TRACK_BITRATE="$2"
		shift
                ;;
            "-f"|"--format")
                TRACK_EXT=".$2"
		shift
                ;;
            "-k"|"--keep-files")
                KEEP_FILES=1
                ;;
            "--wewlads")
                while true; do echo -n "WEW LADS!  " ; sleep 0.05 ; done
                ;;
            *)
                fn_err "invalid argument: $1" $ERR_WRONG_ARG
                ;;
        esac	# --- end of case ---
        # Delete $1
        shift
    done
fi

mkdir -v ${WORKDIR}
pushd ${WORKDIR}
m_say "directory changed to $(pwd)"

m_say "getting TOC file..."
#${RUN_AS_ADMIN} cdrdao read-toc ${BASENAME}.toc
cdrdao read-toc ${BASENAME}.toc

m_say "converting TOC file to CUE file..."
cueconvert --input-format=toc --output-format=cue ${BASENAME}.toc ${BASENAME}.cue

m_say "retrieving audio tracks from CDDA..."
cdparanoia --output-wav --batch --log-debug 

m_say "converting WAV tracks to FLAC..."
ls -x1 --color=never track*.wav > ${LIST}
for F in $(\ls -x1 --color=never track*wav); do
	${FFMPEG} -i $F -b:a $TRACK_BITRATE ${F%%.wav}$TRACK_EXT
done

m_say "tagging FLAC files from CUE file..."
$CUETAG ${BASENAME}.cue track*$TRACK_EXT

pushd && mv ${WORKDIR}/track*$TRACK_EXT ./
m_say "directory changed to $(pwd)"

if [[ $KEEP_FILES -eq 0 ]]; then
    m_say "cleaning..."
    m_say "deleting ${WORKDIR}"
    rm -frI -v ${WORKDIR}
else
    m_say "files have been kept in directory \"${WORKDIR}\"/"
fi
exit
