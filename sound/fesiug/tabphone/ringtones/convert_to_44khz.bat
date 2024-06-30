@echo off
setlocal enabledelayedexpansion

:: Set the path to FFmpeg executable
set ffmpeg_path="C:\ffmpeg\bin\ffmpeg.exe"

:: Set the input directory
set input_dir="."

:: Set the output directory
set output_dir="44khz"

mkdir "%output_dir%"

:: Loop through all .ogg, .mp3, and .wav files in the input directory
for %%f in ("%input_dir%\*.ogg" "%input_dir%\*.mp3" "%input_dir%\*.wav") do (
    :: Get the file name without extension
    set "filename=%%~nf"
    :: Convert the file to 44.1 kHz and save it to the output directory
    %ffmpeg_path% -i "%%f" -ar 44100 "%output_dir%\!filename!.ogg"
)

echo Conversion complete.
pause
