%ifndef SDL_ASM
%define SDL_ASM

extern SDL_Init, SDL_Quit, SDL_CreateWindow, SDL_DestroyWindow
extern SDL_CreateRenderer, SDL_DestroyRenderer
extern IMG_Init, IMG_Quit
extern SDL_PollEvent

struc SDL_Event
    .type: resd 1
    .padding: resb 52
endstruc

SDL_INIT_VIDEO: equ 0x20
SDL_WINDOWPOS_UNDEFINED: equ 0x1fff0000
SDL_QUIT: equ 0x100
IMG_INIT_PNG: equ 2

%endif ; SDL_ASM
