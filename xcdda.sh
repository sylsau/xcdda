#!/bin/bash - 
#===============================================================================
#
#          FILE: SyS-xcdda.sh
# 
#         USAGE: ./SyS-xcdda.sh 
# 
#   DESCRIPTION: Simple and efficient audio CD ripping and tagging tool. Rip audio CD to fully tagged FLAC media files.
# 
#       OPTIONS: ---
#  REQUIREMENTS: cdrdao, cdparanoia, cuetools, SyS-ffmpeg-mass-conv.sh
#          BUGS: ---
#        AUTHOR: Sylvain Saubier (ResponSyS), mail@systemicresponse.com
#       CREATED: 06/09/16 23:32
#      REVISION:  ---
#===============================================================================

v_help=0
v_basename='audio'
f_dir_working='XCDDA'
f_list='list_wav.txt'
f_script_conv='xcdda-conv.sh'
v_keep_files=0

function fn_exit {
    echo ":: Exiting..." > /dev/stderr
    exit
}

if test -n "$*"; then
    # Individually check provided args
    while test -n "$1" ; do
        case $1 in
            "-h"|"--help")
                v_help=1
                ;;
            "-k"|"--keep-files")
                v_keep_files=1
                ;;
            "--wewlads")
                while true; do echo -n "WEW LADS!  " ; sleep 0.05 ; done
                ;;
            *)
                echo ":: ERROR : Invalid argument: $1" > /dev/stderr
                fn_exit
                ;;
        esac	# --- end of case ---
        # Delete $1
        shift
    done
fi

if test $v_help -eq 1; then
    echo
    echo "Simple and efficient audio CD ripping and tagging tool. Everything is done from the CD itself (no internet connection required)."
    echo ">> Requires: cdrdao, cdparanoia, cuetools, SyS-ffmpeg-mass-conv.sh (https://github.com/ResponSySS/ffmpeg-mass-conv/)"
    echo "Shit's wonderful, use it, srsly."
    echo "Steps: "
    echo "   1. extract TOC file (cdrdao)"
    echo "   2. convert TOC to CUE (cueconvert)"
    echo "   3. extract audio data to WAV files (cdparanoia)"
    echo "   4. convert WAV files to FLAC files (ffmpeg)"
    echo "   5. tag FLAC files from CUE file (cuetag.sh)"
    echo
    echo "Usage:"
    echo "    $0 [-h|--help] [-k|--keep-files]"
    exit
fi

mkdir -v ./${f_dir_working} && pushd ./${f_dir_working} || exit
echo ":: Directory changed to $(pwd)"

echo ":: Getting TOC file..."
cdrdao read-toc ${v_basename}.toc || exit

echo ":: Converting TOC file to CUE file..."
cueconvert -i toc -o cue ${v_basename}.toc ${v_basename}.cue || exit

echo ":: Retrieving audio tracks from CDDA..."
cdparanoia -B -L || exit 

echo ":: Converting WAV tracks to FLAC..."
ls track*.wav > ${f_list} || exit
/usr/local/bin/SyS-ffmpeg-mass-conv.sh ${f_list} -xi .wav -xo .flac -e || exit

echo ":: Tagging FLAC files from CUE file..."
cuetag.sh ${v_basename}.cue track*.flac || exit

pushd && mv ./${f_dir_working}/track*.flac ./ || exit
echo ":: Directory changed to $(pwd)"

if test $v_keep_files -eq 0 ; then
    echo ":: Cleaning..."
    rm -fr ./${f_dir_working}
else
    echo ":: Files have been kept in directory ${f_dir_working}/"
fi
exit
