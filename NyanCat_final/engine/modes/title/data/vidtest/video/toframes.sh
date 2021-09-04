ffmpeg -i in.mp4 -vf scale=256:224 -r 7 -t 00:20 frames/%d.png

#ffmpeg -i in.mp4 -vf scale=256:224 frames/%d.png
ffmpeg -i in.mp4 pre_sound.wav
