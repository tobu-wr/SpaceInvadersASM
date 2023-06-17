%include "sdl.asm"

extern puts

%macro create_texture 1
    mov rcx, %1_file
    call create_texture_func
    mov [%1_texture], rax
%endmacro

%macro render_texture 3
    mov rcx, [renderer]
    mov rdx, [%1_texture] ; texture
    mov r8, %2 ; srcrect
    mov r9, %3 ; dstrect
    call SDL_RenderCopy
%endmacro

%macro destroy_texture 1
    mov rcx, [%1_texture]
    call SDL_DestroyTexture
%endmacro

struc entity
    .srcrect: resb SDL_Rect_size
    .dstrect: resb SDL_Rect_size
    .texture: resq 1
endstruc

section .text
global main
main:
    sub rsp, 40

    ; init SDL
    mov ecx, SDL_INIT_VIDEO ; flags
    call SDL_Init
    cmp eax, 0
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
    mov r9d, 224 ; w
    sub rsp, 16
    mov dword [rsp + 32], 256 ; h
    mov dword [rsp + 40], 0 ; flags
    call SDL_CreateWindow
    add rsp, 16
    cmp rax, 0
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
    cmp rax, 0
    jne .create_renderer_success
    mov rcx, create_renderer_msg_fail
    call puts
    jmp .destroy_window
.create_renderer_success:
    mov [renderer], rax
    mov rcx, create_renderer_msg_success
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

    ; create textures
    create_texture background
    create_texture player
    create_texture ennemy1
    create_texture ennemy2
    create_texture ennemy3

    ; TODO: create entities

.game_loop:

    ; handle events
.handle_event:
    mov rcx, event
    call SDL_PollEvent
    cmp eax, 0
    je .handle_event_end
    cmp dword [event + SDL_Event.type], SDL_QUIT
    je .game_loop_end
    jmp .handle_event
.handle_event_end:

    ; TODO: update game logic

    ; rendering
    render_texture background, 0, 0
    mov rcx, [renderer]
    call SDL_RenderPresent

    jmp .game_loop
.game_loop_end:

    ; cleanup
    destroy_texture background
    destroy_texture player
    destroy_texture ennemy1
    destroy_texture ennemy2
    destroy_texture ennemy3
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
create_texture_func:
    sub rsp, 40
    call IMG_Load
    cmp rax, 0
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
init_sdl_image_msg_success:
    db "IMG_Init() success", 0
init_sdl_image_msg_fail:
    db "IMG_Init() fail", 0
title:
    db "Space Invaders", 0
background_file:
    db "res/background.png", 0
player_file:
    db "res/player.png", 0
ennemy1_file:
    db "res/ennemy1.png", 0
ennemy2_file:
    db "res/ennemy2.png", 0
ennemy3_file:
    db "res/ennemy3.png", 0

section .bss
window:
    resq 1
renderer:
    resq 1
background_texture:
    resq 1
player_texture:
    resq 1
ennemy1_texture:
    resq 1
ennemy2_texture:
    resq 1
ennemy3_texture:
    resq 1
event:
    resb SDL_Event_size
