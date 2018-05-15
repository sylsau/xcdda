#!/bin/bash - 
#===============================================================================
#
#          FILE: xcdda.sh
# 
#         USAGE: ./xcdda.sh 
# 
#   DESCRIPTION: Simple and efficient audio CD ripping and tagging tool. Rip audio CD to fully tagged FLAC media files without using the internet. Output to current directory.
# 
#       OPTIONS: ---
#  REQUIREMENTS: cdrdao, cdparanoia, cuetools, ffmpeg-bulk.sh
#          BUGS: ---
#        AUTHOR: Sylvain Saubier (ResponSyS), mail@sylsau.com
#       CREATED: 06/09/16 23:32
#===============================================================================

readonly PROGRAM_NAME="${0##*/}"
readonly SCRIPT_NAME="${0##*/}"
readonly VERSION="2018.02.01"

# Path to ffmpeg-bulk.sh script
readonly FFMPEG_BULK=${FFMPEG_BULK:-$HOME/Devel/Src/Bash/ffmpeg-bulk/ffmpeg-bulk.sh}

readonly ERR_NO_CMD=10
readonly ERR_WRONG_ARG=30

readonly BASENAME='cdda'
readonly WORKDIR='XCDDA'
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
    m_say "${FMT_BOLD}ERROR${FMT_OFF}: $1" >&2
    exit $2
}

fn_help() {
    cat << EOF
$PROGRAM_NAME v${VERSION}
Simple and efficient audio CD ripping and tagging tool. Rip audio CD to fully tagged
FLAC media files without using the internet. Output to current directory.

REQUIREMENTS
    cdrdao, cdparanoia, cuetools, ffmpeg-bulk (<https://github.com/ResponSySS/ffmpeg-bulk/>)

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
    Mail at: <feedback@sylsau.com>
EOF
}

fn_need_cmd "cdrdao"
fn_need_cmd "cueconvert"
fn_need_cmd "cdparanoia"
fn_need_cmd "ffmpeg"
fn_need_cmd "${FFMPEG_BULK}"
fn_need_cmd "cuetag.sh"

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
ls -x1 --color=never track*.wav > ${LIST} || exit
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
