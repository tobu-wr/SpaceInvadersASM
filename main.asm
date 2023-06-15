%include "sdl.asm"

extern puts

section .text
global main
main:
    sub rsp,40

    ; init
    mov ecx,SDL_INIT_VIDEO ; flags
    call SDL_Init
    cmp eax,0
    je init_success
    mov rcx,init_msg_fail
    call puts
    jmp main_end
init_success:
    mov rcx,init_msg_success
    call puts

    ; create window
    mov rcx,title
    mov edx,SDL_WINDOWPOS_UNDEFINED ; x
    mov r8d,SDL_WINDOWPOS_UNDEFINED ; y
    mov r9d,256 ; w
    sub rsp,16
    mov dword [rsp+32],224 ; h
    mov dword [rsp+40],0 ; flags
    call SDL_CreateWindow
    add rsp,16
    cmp rax,0
    je create_window_fail
    jmp create_window_success
create_window_fail:
    mov rcx,create_window_msg_fail
    call puts
    jmp uninit
create_window_success:
    mov [window],rax
    mov rcx,create_window_msg_success
    call puts

    ; game loop
;game_loop:

    ; handle events
handle_event:
    mov rcx,0
    call SDL_PollEvent
    cmp eax,0
    je handle_event_end
    ; TODO: handle event
    jmp handle_event
handle_event_end:

    ; TODO

    ;jmp game_loop

    mov rcx,[window]
    call SDL_DestroyWindow

uninit:
    call SDL_Quit

main_end:
    add rsp,40
    mov eax,0
    ret

section .data
init_msg_success:
    db "SDL_Init() success", 0
init_msg_fail:
    db "SDL_Init() fail", 0
create_window_msg_success:
    db "SDL_CreateWindow() success", 0
create_window_msg_fail:
    db "SDL_CreateWindow() fail", 0
title:
    db "Space Invaders", 0
window:
    dq 0
