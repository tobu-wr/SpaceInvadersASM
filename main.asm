extern puts
extern SDL_Init, SDL_Quit, SDL_CreateWindow, SDL_DestroyWindow, SDL_PollEvent

struc SDL_Event
    type: resd 1
endstruc

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
    jmp end
init_success:
    mov rcx,init_msg_success
    call puts

    ; create window
    mov rcx,title
    mov edx,SDL_WINDOWPOS_UNDEFINED ; x
    mov r8d,SDL_WINDOWPOS_UNDEFINED ; y
    mov r9d,320 ; w
    sub rsp,16
    mov dword [rsp+32],200 ; h
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
game_loop:
    ; handle events
    mov rcx,event
    call SDL_PollEvent


    ; resume here

    ;jmp game_loop


    mov rcx,[window]
    call SDL_DestroyWindow

uninit:
    call SDL_Quit

end:
    add rsp,40
    mov eax,0
    ret

section .data
SDL_INIT_VIDEO: equ 0x20
SDL_WINDOWPOS_UNDEFINED: equ 0x1fff0000

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
event:
    istruc SDL_Event
        at type, dd 0
    iend
    