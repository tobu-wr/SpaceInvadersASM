%ifndef SDL_ASM
%define SDL_ASM

extern SDL_Init, SDL_Quit, SDL_CreateWindow, SDL_DestroyWindow, SDL_PollEvent

SDL_INIT_VIDEO: equ 0x00000020
SDL_WINDOWPOS_UNDEFINED: equ 0x1fff0000

%endif ; SDL_ASM
