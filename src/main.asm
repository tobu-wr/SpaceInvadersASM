%include "sdl.asm"

extern puts, printf

width: equ 224
height: equ 256
scale: equ 2

cannon_y: equ 216
cannon_width: equ 13
cannon_height: equ 8

laser_height: equ 4

struc entity
    .texture: resq 1
    .srcrect: resb SDL_Rect_size
    .dstrect: resb SDL_Rect_size
    .alive: resb 1
endstruc

%macro create_invaders 5
    mov rcx, %1 ; texture
    mov edx, %2 ; w
    mov r8d, %3 ; h
    mov r9d, %4 ; row index
    mov dword [rsp + 32], 0 ; row count
    call create_invaders_func
%endmacro

%macro set_entity_texture 2
    mov rax, [%2] ; texture
    mov [%1 + entity.texture], rax
%endmacro

%macro set_entity_srcrect 5
    mov dword [%1 + entity.srcrect + SDL_Rect.x], %2
    mov dword [%1 + entity.srcrect + SDL_Rect.y], %3
    mov dword [%1 + entity.srcrect + SDL_Rect.w], %4
    mov dword [%1 + entity.srcrect + SDL_Rect.h], %5
%endmacro

%macro set_entity_dstrect 5
    mov dword [%1 + entity.dstrect + SDL_Rect.x], %2
    mov dword [%1 + entity.dstrect + SDL_Rect.y], %3
    mov dword [%1 + entity.dstrect + SDL_Rect.w], %4
    mov dword [%1 + entity.dstrect + SDL_Rect.h], %5
%endmacro

%macro render_entity 1
    mov rcx, %1 ; entity
    call render_entity_func
%endmacro

%macro load_texture 2
    mov rcx, %1 ; file
    call load_texture_func
    mov [%2], rax ; texture
%endmacro

%macro render_texture 3
    mov rcx, [renderer]
    mov rdx, [%1] ; texture
    lea r8, [%2] ; srcrect
    lea r9, [%3] ; dstrect
    call SDL_RenderCopy
%endmacro

%macro free_texture 1
    mov rcx, [%1] ; texture
    call SDL_DestroyTexture
%endmacro

%macro load_sound 2
    mov rcx, %1 ; file
    call load_sound_func
    mov [%2], rax ; sound
%endmacro

%macro play_sound 1
    mov ecx, -1 ; channel
    mov rdx, [%1] ; sound
    mov r8d, 0 ; loops
    call Mix_PlayChannel
%endmacro

%macro free_sound 1
    mov rcx, [%1] ; sound
    call Mix_FreeChunk
%endmacro

section .text
global main
main:
    sub rsp, 56

    ; init SDL
    mov ecx, SDL_INIT_VIDEO | SDL_INIT_AUDIO ; flags
    call SDL_Init
    test eax, eax
    je .init_sdl_success
    mov rcx, init_sdl_msg_fail
    call puts
    jmp .main_end
.init_sdl_success:
    mov rcx, init_sdl_msg_success
    call puts

    ; create window
    mov rcx, title
    mov edx, SDL_WINDOWPOS_UNDEFINED ; x
    mov r8d, SDL_WINDOWPOS_UNDEFINED ; y
    mov r9d, width * scale
    mov dword [rsp + 32], height * scale
    mov dword [rsp + 40], 0 ; flags
    call SDL_CreateWindow
    test rax, rax
    jne .create_window_success
    mov rcx, create_window_msg_fail
    call puts
    jmp .free_sdl
.create_window_success:
    mov [window], rax
    mov rcx, create_window_msg_success
    call puts

    ; create renderer
    mov rcx, [window]
    mov edx, -1 ; index
    mov r8d, 0 ; flags
    call SDL_CreateRenderer
    test rax, rax
    jne .create_renderer_success
    mov rcx, create_renderer_msg_fail
    call puts
    jmp .free_window
.create_renderer_success:
    mov [renderer], rax
    mov rcx, create_renderer_msg_success
    call puts

    ; set renderer size
    mov rcx, [renderer]
    mov edx, width
    mov r8d, height
    call SDL_RenderSetLogicalSize
    test eax, eax
    je .set_renderer_size_success
    mov rcx, set_renderer_size_msg_fail
    call puts
    jmp .free_renderer
.set_renderer_size_success:
    mov rcx, set_renderer_size_msg_success
    call puts

    ; init SDL_image
    mov ecx, IMG_INIT_PNG ; flags
    call IMG_Init
    cmp eax, IMG_INIT_PNG
    je .init_sdl_image_success
    mov rcx, init_sdl_image_msg_fail
    call puts
    jmp .free_renderer
.init_sdl_image_success:
    mov rcx, init_sdl_image_msg_success
    call puts

    ; init SDL_mixer
    mov ecx, 44100 ; frequency
    mov dx, AUDIO_U8 ; format
    mov r8w, 1 ; channels
    mov r9w, 512 ; chunksize
    call Mix_OpenAudio
    test eax, eax
    je .init_sdl_mixer_success
    mov rcx, init_sdl_mixer_msg_fail
    call puts
    jmp .free_sdl_image
.init_sdl_mixer_success:
    mov rcx, init_sdl_mixer_msg_success
    call puts

    ; load textures
    load_texture space_texture_file, space_texture
    load_texture cannon_texture_file, cannon_texture
    load_texture laser_texture_file, laser_texture
    load_texture large_invader_texture_file, large_invader_texture
    load_texture medium_invader_texture_file, medium_invader_texture
    load_texture small_invader_texture_file, small_invader_texture
    load_texture saucer_texture_file, saucer_texture

    ; load sounds
    load_sound laser_sound_file, laser_sound

    ; create cannon
    set_entity_texture cannon, cannon_texture
    set_entity_srcrect cannon, 0, 0, cannon_width, cannon_height
    set_entity_dstrect cannon, 0, cannon_y, cannon_width, cannon_height
    mov byte [cannon + entity.alive], 1

    ; create laser
    set_entity_texture laser, laser_texture
    set_entity_srcrect laser, 0, 0, 1, laser_height
    set_entity_dstrect laser, 0, -laser_height, 1, laser_height
    mov byte [laser + entity.alive], 1

    ; create invaders
    create_invaders small_invader_texture, 8, 8, 0, 1
    create_invaders medium_invader_texture, 11, 8, 1, 2
    create_invaders large_invader_texture, 12, 8, 3, 2

    ; get keyboard state
    mov rcx, 0 ; numkeys
    call SDL_GetKeyboardState
    mov [keyboard_state], rax

    ; init tick count
    call SDL_GetTicks
    mov [ticks], eax

.game_loop:

    ; poll events
.poll_event:
    mov rcx, event
    call SDL_PollEvent
    test eax, eax
    je .poll_event_end
    cmp dword [event + SDL_Event.type], SDL_QUIT
    je .game_loop_end
    jmp .poll_event
.poll_event_end:

    ; handle keys
    mov rax, [keyboard_state]
    cmp byte [rax + SDL_SCANCODE_RIGHT], 0
    je .right_key_end
    cmp dword [cannon + entity.dstrect + SDL_Rect.x], width - cannon_width
    je .right_key_end
    inc dword [cannon + entity.dstrect + SDL_Rect.x]
.right_key_end:
    cmp byte [rax + SDL_SCANCODE_LEFT], 0
    je .left_key_end
    cmp dword [cannon + entity.dstrect + SDL_Rect.x], 0
    je .left_key_end
    dec dword [cannon + entity.dstrect + SDL_Rect.x]
.left_key_end:
    mov al, [rax + SDL_SCANCODE_SPACE]
    cmp al, [space_key_state]
    je .space_key_end
    mov [space_key_state], al
    test al, al
    je .space_key_end
    play_sound laser_sound
    mov eax, [cannon + entity.dstrect + SDL_Rect.x]
    add eax, cannon_width / 2
    mov [laser + entity.dstrect + SDL_Rect.x], eax
    mov dword [laser + entity.dstrect + SDL_Rect.y], cannon_y - laser_height
.space_key_end:

    ; update laser position
    sub dword [laser + entity.dstrect + SDL_Rect.y], 4

    ; render
    render_texture space_texture, 0, 0
    render_entity cannon
    render_entity laser
    render_entity invaders
    mov rcx, [renderer]
    call SDL_RenderPresent

    ; limit framerate to ~60fps
    call SDL_GetTicks
    mov ecx, eax
    sub eax, [ticks]
    mov [ticks], ecx
    mov ecx, 16
    sub ecx, eax
    jna .delay_end
    call SDL_Delay
.delay_end:

    jmp .game_loop
.game_loop_end:

    ; cleanup
    free_texture space_texture
    free_texture cannon_texture
    free_texture laser_texture
    free_texture large_invader_texture
    free_texture medium_invader_texture
    free_texture small_invader_texture
    free_texture saucer_texture
    free_sound laser_sound
    call Mix_CloseAudio
.free_sdl_image:
    call IMG_Quit
.free_renderer:
    mov rcx, [renderer]
    call SDL_DestroyRenderer
.free_window:
    mov rcx, [window]
    call SDL_DestroyWindow
.free_sdl:
    call SDL_Quit

.main_end:
    add rsp, 56
    xor eax, eax
    ret

; inputs:
; - rcx = texture
; - edx = w
; - r8d = h
; - r9d = row index
; - stack = row count
create_invaders_func:
    sub rsp, 40

    ; set_entity_texture invaders, rcx
    ; set_entity_srcrect invaders, 0, 0
    ; set_entity_dstrect invaders, 0, 0, small_invader_width, small_invader_height
    ; mov byte [invaders + entity.alive], 1

    add rsp, 40
    ret

; input: rcx = entity
render_entity_func:
    sub rsp, 40
    cmp byte [rcx + entity.alive], 0
    je .end
    mov rax, rcx
    render_texture rax + entity.texture, rax + entity.srcrect, rax + entity.dstrect
.end:
    add rsp, 40
    ret

; input: rcx = file
; output: rax = texture
load_texture_func:
    sub rsp, 56
    mov [rsp + 48], rcx
    call IMG_Load
    mov [rsp + 40], rax
    test rax, rax
    jne .load_img_success
    mov rcx, load_texture_msg_fail ; format
    jmp .end
.load_img_success:
    mov rcx, [renderer]
    mov rdx, rax ; surface
    call SDL_CreateTextureFromSurface
    mov rcx, [rsp + 40]
    mov [rsp + 40], rax
    call SDL_FreeSurface
    cmp qword [rsp + 40], 0
    jne .create_texture_success
    mov rcx, load_texture_msg_fail ; format
    jmp .end
.create_texture_success:
    mov rcx, load_texture_msg_success ; format
.end:
    mov rdx, [rsp + 48]
    call printf
    mov rax, [rsp + 40]
    add rsp, 56
    ret

; input: rcx = file
; output: rax = sound
load_sound_func:
    sub rsp, 40
    mov [rsp + 32], rcx
    call Mix_LoadWAV
    mov rdx, [rsp + 32]
    test rax, rax
    jne .success
    mov rcx, load_sound_msg_fail ; format
    jmp .end
.success:
    mov rcx, load_sound_msg_success ; format
.end:
    mov [rsp + 32], rax
    call printf
    mov rax, [rsp + 32]
    add rsp, 40
    ret

section .data
init_sdl_msg_success:
    db "OK > SDL_Init() success", 0
init_sdl_msg_fail:
    db "ERR > SDL_Init() fail", 0
create_window_msg_success:
    db "OK > SDL_CreateWindow() success", 0
create_window_msg_fail:
    db "ERR > SDL_CreateWindow() fail", 0
create_renderer_msg_success:
    db "OK > SDL_CreateRenderer() success", 0
create_renderer_msg_fail:
    db "ERR > SDL_CreateRenderer() fail", 0
set_renderer_size_msg_success:
    db "OK > SDL_RenderSetLogicalSize() success", 0
set_renderer_size_msg_fail:
    db "ERR > SDL_RenderSetLogicalSize() fail", 0
init_sdl_image_msg_success:
    db "OK > IMG_Init() success", 0
init_sdl_image_msg_fail:
    db "ERR > IMG_Init() fail", 0
init_sdl_mixer_msg_success:
    db "OK > Mix_OpenAudio() success", 0
init_sdl_mixer_msg_fail:
    db "ERR > Mix_OpenAudio() fail", 0
load_texture_msg_success:
    db "OK > Texture successfully loaded (%s)", 10, 0
load_texture_msg_fail:
    db "ERR > Failed to load texture (%s)", 10, 0
load_sound_msg_success:
    db "OK > Sound successfully loaded (%s)", 10, 0
load_sound_msg_fail:
    db "ERR > Failed to load sound (%s)", 10, 0
title:
    db "Space Invaders", 0
space_texture_file:
    db "res/space.png", 0
cannon_texture_file:
    db "res/cannon.png", 0
laser_texture_file:
    db "res/laser.png", 0
large_invader_texture_file:
    db "res/large_invader.png", 0
medium_invader_texture_file:
    db "res/medium_invader.png", 0
small_invader_texture_file:
    db "res/small_invader.png", 0
saucer_texture_file:
    db "res/saucer.png", 0
laser_sound_file:
    db "res/laser.wav", 0
space_key_state:
    db 0

section .bss
window:
    resq 1
renderer:
    resq 1
space_texture:
    resq 1
cannon_texture:
    resq 1
laser_texture:
    resq 1
large_invader_texture:
    resq 1
medium_invader_texture:
    resq 1
small_invader_texture:
    resq 1
saucer_texture:
    resq 1
laser_sound:
    resq 1
cannon:
    resb entity_size
laser:
    resb entity_size
invaders:
    resq entity_size * 5 * 11
event:
    resb SDL_Event_size
keyboard_state:
    resq 1
ticks:
    resd 1
