#!/bin/sh
# Debug, ReleaseSafe, ReleaseSmall, ReleaseFast are the options for -O
zig build-exe ../src/main.zig -lc -lSDL2 -lSDL2_image -lSDL2_mixer -O ReleaseSafe -flto -fstrip
