# xcdda
Simple and efficient audio CD ripping and tagging tool. Everything is done from the CD itself (no internet connection required).  
**Requires: cdrdao, cdparanoia, cuetools, [SyS-ffmpeg-mass-conv.sh](https://github.com/ResponSySS/ffmpeg-mass-conv/)**  
Shit's wonderful, use it, srsly.

### How it works:

1. extract TOC file (cdrdao)
2. convert TOC to CUE (cueconvert)
3. extract audio data to WAV files (cdparanoia)
4. convert WAV files to FLAC files (ffmpeg)
5. tag FLAC files from CUE file (cuetag.sh)

### Usage:

`xcdda.sh`
