%include "sdl.asm"

extern puts, printf

width: equ 224
height: equ 256
scale: equ 2

cannon_width: equ 13

struc entity
    .texture: resq 1
    .srcrect: resb SDL_Rect_size
    .dstrect: resb SDL_Rect_size
endstruc

%macro load_texture 1
    mov rcx, %1_file
    call load_texture_func
    mov [%1_texture], rax
%endmacro

%macro render_texture 3
    mov rcx, [renderer]
    mov rdx, [%1_texture]
    mov r8, %2 ; srcrect
    mov r9, %3 ; dstrect
    call SDL_RenderCopy
%endmacro

%macro free_texture 1
    mov rcx, [%1_texture]
    call SDL_DestroyTexture
%endmacro

%macro load_sound 1
    mov rcx, %1_file
    call load_sound_func
    mov [%1_sound], rax
%endmacro

%macro play_sound 1
    mov ecx, -1 ; channel
    mov rdx, [%1_sound]
    mov r8d, 0 ; loops
    call Mix_PlayChannel
%endmacro

%macro free_sound 1
    mov rcx, [%1_sound]
    call Mix_FreeChunk
%endmacro

section .text
global main
main:
    sub rsp, 40

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
    sub rsp, 16
    mov dword [rsp + 32], height * scale
    mov dword [rsp + 40], 0 ; flags
    call SDL_CreateWindow
    add rsp, 16
    test rax, rax
    jne .create_window_success
    mov rcx, create_window_msg_fail
    call puts
    jmp .quit_sdl
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
    jmp .destroy_window
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
    jmp .destroy_renderer
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
    jmp .destroy_renderer
.init_sdl_image_success:
    mov rcx, init_sdl_image_msg_success
    call puts

    ; init SDL_mixer
    mov ecx, 44_100 ; frequency
    mov dx, AUDIO_U8 ; format
    mov r8w, 1 ; channels
    mov r9w, 512 ; chunksize
    call Mix_OpenAudio
    test eax, eax
    je .init_sdl_mixer_success
    mov rcx, init_sdl_mixer_msg_fail
    call puts
    jmp .quit_sdl_image
.init_sdl_mixer_success:
    mov rcx, init_sdl_mixer_msg_success
    call puts

    ; load textures
    load_texture space
    load_texture cannon
    load_texture large_invader
    load_texture medium_invader
    load_texture small_invader

    ; load sounds
    load_sound laser

    ; create entities
    mov rax, [cannon_texture]
    mov [cannon + entity.texture], rax
    mov dword [cannon + entity.dstrect + SDL_Rect.x], 0
    mov dword [cannon + entity.dstrect + SDL_Rect.y], 216
    mov dword [cannon + entity.dstrect + SDL_Rect.w], cannon_width
    mov dword [cannon + entity.dstrect + SDL_Rect.h], 8

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
    je .right_key_handled
    cmp dword [cannon + entity.dstrect + SDL_Rect.x], width - cannon_width
    je .right_key_handled
    inc dword [cannon + entity.dstrect + SDL_Rect.x]
.right_key_handled:
    cmp byte [rax + SDL_SCANCODE_LEFT], 0
    je .left_key_handled
    cmp dword [cannon + entity.dstrect + SDL_Rect.x], 0
    je .left_key_handled
    dec dword [cannon + entity.dstrect + SDL_Rect.x]
.left_key_handled:
    mov al, byte [rax + SDL_SCANCODE_SPACE]
    cmp al, byte [space_key_state]
    je .space_key_handled
    mov byte [space_key_state], al
    test al, al
    je .space_key_handled
    play_sound laser
.space_key_handled:

    ; render
    render_texture space, 0, 0
    render_texture cannon, 0, cannon + entity.dstrect
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
    free_texture space
    free_texture cannon
    free_texture large_invader
    free_texture medium_invader
    free_texture small_invader
    free_sound laser
    call Mix_CloseAudio
.quit_sdl_image:
    call IMG_Quit
.destroy_renderer:
    mov rcx, [renderer]
    call SDL_DestroyRenderer
.destroy_window:
    mov rcx, [window]
    call SDL_DestroyWindow
.quit_sdl:
    call SDL_Quit

.main_end:
    add rsp, 40
    xor eax, eax
    ret

; input: rcx = file
; output: rax = texture
load_texture_func:
    sub rsp, 40
    call IMG_Load
    test rax, rax
    je .end
    ; TODO: push surface
    mov rcx, [renderer]
    mov rdx, rax ; surface
    call SDL_CreateTextureFromSurface
    ; TODO: pop surface to rcx
    ; TODO: push texture
    ;call SDL_FreeSurface
    ; TODO: pop texture to rax
.end:
    add rsp, 40
    ret

; input: rcx = file
; output: rax = sound
load_sound_func:
    sub rsp, 56
    mov [rsp + 40], rcx
    call Mix_LoadWAV
    mov rdx, [rsp + 40]
    test rax, rax
    jne .success
    mov rcx, load_sound_msg_fail ; format
    jmp .end
.success:
    mov rcx, load_sound_msg_success ; format
.end:
    mov [rsp + 40], rax
    call printf
    mov rax, [rsp + 40]
    add rsp, 56
    ret

section .data
init_sdl_msg_success:
    db "SDL_Init() success", 0
init_sdl_msg_fail:
    db "SDL_Init() fail", 0
create_window_msg_success:
    db "SDL_CreateWindow() success", 0
create_window_msg_fail:
    db "SDL_CreateWindow() fail", 0
create_renderer_msg_success:
    db "SDL_CreateRenderer() success", 0
create_renderer_msg_fail:
    db "SDL_CreateRenderer() fail", 0
set_renderer_size_msg_success:
    db "SDL_RenderSetLogicalSize() success", 0
set_renderer_size_msg_fail:
    db "SDL_RenderSetLogicalSize() fail", 0
init_sdl_image_msg_success:
    db "IMG_Init() success", 0
init_sdl_image_msg_fail:
    db "IMG_Init() fail", 0
init_sdl_mixer_msg_success:
    db "Mix_OpenAudio() success", 0
init_sdl_mixer_msg_fail:
    db "Mix_OpenAudio() fail", 0
load_sound_msg_success:
    db "%s successfully loaded", 10, 0
load_sound_msg_fail:
    db "Failed to load %s", 10, 0
title:
    db "Space Invaders", 0
space_file:
    db "res/space.png", 0
cannon_file:
    db "res/cannon.png", 0
large_invader_file:
    db "res/large_invader.png", 0
medium_invader_file:
    db "res/medium_invader.png", 0
small_invader_file:
    db "res/small_invader.png", 0
laser_file:
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
large_invader_texture:
    resq 1
medium_invader_texture:
    resq 1
small_invader_texture:
    resq 1
laser_sound:
    resq 1
cannon:
    resb entity_size
event:
    resb SDL_Event_size
keyboard_state:
    resq 1
ticks:
    resd 1
