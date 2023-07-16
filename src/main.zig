/// Game Window using SDL2
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
    @cInclude("SDL2/SDL_mixer.h");
});

const std = @import("std");

const LEVEL_WIDTH: i32 = 640;
const LEVEL_HEIGHT: i32 = 400;
const PLAYER_WIDTH: u32 = 40;
const PLAYER_HEIGHT: u32 = 40;
const PLAYER_SPEED: u32 = 2;

const Player = struct { srcrect: c.SDL_Rect, dstrect: c.SDL_Rect, texture: ?*c.SDL_Texture, speed: c_int };

pub fn main() !void {
    const chunksize: u32 = 1024;
    const music_volume: u32 = 64; // MAX Volume: 128

    const sdl_status: c_int = c.SDL_Init(c.SDL_INIT_VIDEO);
    defer c.SDL_Quit();

    if (sdl_status == -1) {
        std.debug.print("SDL_Init Error\n", .{});
    }

    // Create window
    const window: ?*c.SDL_Window = c.SDL_CreateWindow("Odaeger", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, LEVEL_WIDTH, LEVEL_HEIGHT, 0);
    defer c.SDL_DestroyWindow(window);

    // Initialize SDL_mixer
    const open_audio: c_int = c.Mix_OpenAudio(c.MIX_DEFAULT_FREQUENCY, c.MIX_DEFAULT_FORMAT, 2, chunksize);
    defer c.Mix_CloseAudio();

    if (open_audio == -1) {
        std.debug.print("Mix_OpenAudio Error\n", .{});
    }

    // Create renderer
    const rend: ?*c.SDL_Renderer = c.SDL_CreateRenderer(window, 0, c.SDL_RENDERER_ACCELERATED);
    defer c.SDL_DestroyRenderer(rend);

    const music: ?*c.Mix_Music = c.Mix_LoadMUS("assets/music/test.ogg");

    // Create player surface
    const player_surface: [*]c.SDL_Surface = c.IMG_Load("assets/art/player.png");
    defer c.SDL_FreeSurface(player_surface);

    // Create player texture
    const player_texture: ?*c.SDL_Texture = c.SDL_CreateTextureFromSurface(rend, player_surface);
    defer c.SDL_DestroyTexture(player_texture);

    // Source and destination rectangle of the player
    const player_srcrect: c.SDL_Rect = c.SDL_Rect{ .x = 0, .y = 0, .w = PLAYER_WIDTH, .h = PLAYER_HEIGHT };
    var player_dstrect: c.SDL_Rect = c.SDL_Rect{ .x = 20, .y = 20, .w = PLAYER_WIDTH, .h = PLAYER_HEIGHT };

    var player = Player{ .srcrect = player_srcrect, .dstrect = player_dstrect, .texture = player_texture, .speed = PLAYER_SPEED };

    // [ Red, Green, Blue, Alpha ]
    _ = c.SDL_SetRenderDrawColor(rend, 255, 255, 255, 255);

    _ = c.Mix_VolumeMusic(music_volume);

    // Start background music (-1 means infinity)
    const music_status: c_int = c.Mix_PlayMusic(music, -1);

    if (music_status == -1) {
        std.debug.print("Mix_PlayMusic Error\n", .{});
    }

    mainloop: while (true) {
        // Game loop
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => break :mainloop,
                c.SDL_KEYDOWN => {
                    if (event.key.keysym.scancode == c.SDL_SCANCODE_ESCAPE) {
                        break :mainloop;
                    }
                },
                else => {},
            }
        }

        // Hold Movement Keybindings
        var state: [*]const u8 = c.SDL_GetKeyboardState(null);
        if (state[c.SDL_SCANCODE_RIGHT] == 1) {
            player.dstrect.x += player.speed;
        }
        if (state[c.SDL_SCANCODE_LEFT] == 1) {
            player.dstrect.x -= player.speed;
        }
        if (state[c.SDL_SCANCODE_DOWN] == 1) {
            player.dstrect.y += player.speed;
        }
        if (state[c.SDL_SCANCODE_UP] == 1) {
            player.dstrect.y -= player.speed;
        }

        // Player boundaries
        if (player.dstrect.x < 0) {
            // left boundary
            player.dstrect.x = 0;
        }
        if (player.dstrect.x + player.dstrect.w > LEVEL_WIDTH) {
            // right boundary
            player.dstrect.x = LEVEL_WIDTH - player.dstrect.w;
        }
        if (player.dstrect.y + player.dstrect.h > LEVEL_HEIGHT) {
            // bottom boundary
            player.dstrect.y = LEVEL_HEIGHT - player.dstrect.h;
        }
        if (player.dstrect.y < 0) {
            // top boundary
            player.dstrect.y = 0;
        }

        // Clear renderer
        _ = c.SDL_RenderClear(rend);

        // Render the player
        _ = c.SDL_RenderCopy(rend, player.texture, &player.srcrect, &player.dstrect);

        // Updates the screen (renderer)
        c.SDL_RenderPresent(rend);

        // Calculates to 60 fps
        // 1000 ms equals 1s
        const miliseconds: i32 = 1000;
        const gameplay_frames: i32 = 60;
        c.SDL_Delay(miliseconds / gameplay_frames);
    }
}
