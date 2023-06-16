%ifndef SDL_ASM
%define SDL_ASM

extern SDL_Init, SDL_Quit, SDL_CreateWindow, SDL_DestroyWindow
extern SDL_CreateRenderer, SDL_DestroyRenderer
extern SDL_RWFromFile, SDL_LoadBMP_RW
extern SDL_PollEvent

struc SDL_Event
    .type: resd 1
    .padding: resb 52
endstruc

SDL_INIT_VIDEO: equ 0x20
SDL_WINDOWPOS_UNDEFINED: equ 0x1fff0000
SDL_QUIT: equ 0x100

section .text
SDL_LoadBMP:
    sub rsp, 40
    mov rdx, SDL_LoadBMP_mode ; mode
    call SDL_RWFromFile
    mov rcx, rax ; src
    mov edx, 1 ; freesrc
    call SDL_LoadBMP_RW
    add rsp, 40
    ret

section .data
SDL_LoadBMP_mode:
    db "rb", 0

%endif ; SDL_ASM
