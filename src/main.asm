%include "sdl.asm"

extern puts

width: equ 224
height: equ 256
scale: equ 2

struc entity
    .texture: resq 1
    .srcrect: resb SDL_Rect_size
    .dstrect: resb SDL_Rect_size
endstruc

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
    mov r9d, width * scale
    sub rsp, 16
    mov dword [rsp + 32], height * scale
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

    ; set renderer size
    mov rcx, [renderer]
    mov edx, width
    mov r8d, height
    call SDL_RenderSetLogicalSize
    cmp eax, 0
    je .set_renderer_size_success
    mov rcx, set_renderer_size_msg_fail
    call puts
    jmp .destroy_renderer
.set_renderer_size_success
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

    ; create textures
    create_texture space
    create_texture cannon
    create_texture large_invader
    create_texture medium_invader
    create_texture small_invader

    ; create entities
    mov rax, [cannon_texture]
    mov [cannon + entity.texture], rax
    mov dword [cannon + entity.dstrect + SDL_Rect.x], 0
    mov dword [cannon + entity.dstrect + SDL_Rect.y], 216
    mov dword [cannon + entity.dstrect + SDL_Rect.w], 13
    mov dword [cannon + entity.dstrect + SDL_Rect.h], 8

.game_loop:

    ; poll events
.poll_event:
    mov rcx, event
    call SDL_PollEvent
    cmp eax, 0
    je .poll_event_end
    cmp dword [event + SDL_Event.type], SDL_QUIT
    je .game_loop_end
    jmp .poll_event
.poll_event_end:

    ; handle keys
    ; FIXME!
    mov rcx, 0 ; numkeys
    call SDL_GetKeyboardState
    cmp byte [rax + SDL_SCANCODE_RIGHT], 0
    je .right_key_handled
    add dword [cannon + entity.dstrect + SDL_Rect.x], 1
.right_key_handled:
    cmp byte [rax + SDL_SCANCODE_LEFT], 0
    je .left_key_handled
    sub dword [cannon + entity.dstrect + SDL_Rect.x], 1
.left_key_handled:

    ; rendering
    render_texture space, 0, 0
    render_texture cannon, 0, cannon + entity.dstrect
    mov rcx, [renderer]
    call SDL_RenderPresent

    jmp .game_loop
.game_loop_end:

    ; cleanup
    destroy_texture space
    destroy_texture cannon
    destroy_texture large_invader
    destroy_texture medium_invader
    destroy_texture small_invader
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
cannon:
    resb entity_size
event:
    resb SDL_Event_size
