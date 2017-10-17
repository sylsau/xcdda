#!/bin/bash - 
#===============================================================================
#
#          FILE: xcdda.sh
# 
#         USAGE: ./xcdda.sh 
# 
#   DESCRIPTION: Simple and efficient audio CD ripping and tagging tool. Rip audio CD to fully tagged FLAC media files.
# 
#       OPTIONS: ---
#  REQUIREMENTS: cdrdao, cdparanoia, cuetools, ffmpeg-mass-conv.sh
#          BUGS: ---
#        AUTHOR: Sylvain Saubier (ResponSyS), mail@systemicresponse.com
#       CREATED: 06/09/16 23:32
#      REVISION:  ---
#===============================================================================

PROGRAM_NAME="xcdda.sh"

ERR_WRONG_ARG=10
ERR_WRONG_ARG=30

BASENAME='cdda'
WORKDIR='XCDDA'
LIST='list_wav.txt'
KEEP_FILES=0

# $1 = command to test (string)
fn_needCmd() {
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
    m_say "${FMT_BOLD}ERROR${FMT_OFF}: $1" >&2
    exit $2
}

fn_help() {
    cat 1>&2 << EOF
$PROGRAM_NAME 20170917
Simple and efficient audio CD ripping and tagging tool. Rip audio CD to fully tagged
FLAC media files.

REQUIREMENTS
    cdrdao, cdparanoia, cuetools, ffmpeg-mass-conv.sh (<https://github.com/ResponSySS/ffmpeg-mass-conv/>)

USAGE
    $PROGRAM_NAME [-h|--help] [-k|--keep-files]

HOW IT WORKS
    1. extract TOC file (cdrdao)
    2. convert TOC to CUE (cueconvert)
    3. extract audio data to WAV files (cdparanoia)
    4. convert WAV files to FLAC files (ffmpeg)
    5. tag FLAC files from CUE file (cuetag.sh)

AUTHOR
    Written by Sylvain Saubier (<http://SystemicResponse.com>)

REPORTING BUGS
    Mail at: <feedback@systemicresponse.com>
EOF
}

fn_needCmd "cdrdao"
fn_needCmd "cueconvert"
fn_needCmd "cdparanoia"
fn_needCmd "ffmpeg"
fn_needCmd "ffmpeg-mass-conv.sh"
fn_needCmd "cuetag.sh"

if test -n "$*"; then
    # Individually check provided args
    while test -n "$1" ; do
        case $1 in
            "-h"|"--help")
                fn_help
                exit
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

mkdir -v ./${WORKDIR} && pushd ./${WORKDIR} || exit
m_say "directory changed to $(pwd)"

m_say "getting TOC file..."
cdrdao read-toc ${BASENAME}.toc || exit

m_say "converting TOC file to CUE file..."
cueconvert -i toc -o cue ${BASENAME}.toc ${BASENAME}.cue || exit

m_say "retrieving audio tracks from CDDA..."
cdparanoia -B -L || exit 

m_say "converting WAV tracks to FLAC..."
ls -x --color=never track*.wav > ${LIST} || exit
ffmpeg-mass-conv.sh ${LIST} -xi .wav -xo .flac -e || exit

m_say "tagging FLAC files from CUE file..."
cuetag.sh ${BASENAME}.cue track*.flac || exit

pushd && mv ./${WORKDIR}/track*.flac ./ || exit
m_say "directory changed to $(pwd)"

if test $KEEP_FILES -eq 0 ; then
    m_say "cleaning..."
    rm -fr ./${WORKDIR}
else
    m_say "files have been kept in directory \"${WORKDIR}\"/"
fi
exit
