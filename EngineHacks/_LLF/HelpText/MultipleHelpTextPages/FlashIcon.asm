.thumb 
.macro blh to, reg=r3
  ldr \reg, =\to
  mov lr, \reg
  .short 0xf800
.endm

.equ BreakProcLoop, 0x8002E94 
.equ ProcFind, 0x8002E9C 
.equ ProcStart, 0x8002C7C
.equ EndProc, 0x8002D6C 
.equ gObj_8x8, 0x8590F44
.equ PushToSecondaryOAM, 0x08002BB8	@{U}

// void LoadIconPalette(unsigned which, unsigned bank); //! FE8U = 0x80035D5
.global HelpBoxOnOpenHook
.type HelpBoxOnOpenHook, %function 
HelpBoxOnOpenHook: 
push {lr} 
cmp r0, #0 
beq SkipSomething 
mov r1, r0 
add r1, #0x28 
mov r0, #1 
strb r0, [r1] 
SkipSomething: 

ldr r0, =HelpBoxFlashIconProc @ sanity check that it isn't already running 
blh ProcFind 
cmp r0, #0 
beq NothingToEnd 
blh EndProc 

NothingToEnd: 
ldr r0, =HelpBoxFlashIconProc
mov r1, #3 @ root 3 
blh ProcStart 

mov r0, r4 
pop {r1} 
bx r1 
.ltorg 

.global HelpBoxFlashIcon
.type HelpBoxFlashIcon, %function 
HelpBoxFlashIcon:
push {r4, lr} 
mov r4, r0 

ldr r0, =0x8A00A98 @ HelpBoxControl
blh ProcFind 
cmp r0, #0 
bne FlashIconIfDoneScrolling
mov r0, r4 
blh BreakProcLoop 
b Exit 
FlashIconIfDoneScrolling: 
ldr r0, =0x8A01628 @ HelpBoxTextScroll
blh ProcFind 
cmp r0, #0 
bne Idle 

bl DrawTheSprite 


Exit: 
Idle: 

pop {r4} 
pop {r0} 
bx r0 
.ltorg 

// https://github.com/FireEmblemUniverse/fireemblem8u/blob/015f95751ef4d526c08bc424e1c5d6dba9d3c88d/src/scene.c#L1583
// int frame = (GetGameClock() / 2) & 0xf;
// https://github.com/FireEmblemUniverse/fireemblem8u/blob/015f95751ef4d526c08bc424e1c5d6dba9d3c88d/src/scene.c#L1777
// gBG0TilemapBuffer + TILEMAP_INDEX(sTalkState->xText, sTalkState->yText + 2 * i)
.equ sTalkStateCore, 0x3000048 
DrawTheSprite: 
push {r4, lr} 

mov r0, #0 
mov r1, #0 

mov r2, #4 @ blue triangle 

mov r3, r2 @ VRAM Tile 

lsl r0, #4 @ 16 pixels per coord 
lsl r1, #4 


@ldr r2, =0x202BCBC @(gCurrentRealCameraPos )	@{U}
@@ldr r2, =0x202BCB8 @(gCurrentRealCameraPos )	@{J}
@ldrh r2, [r2]
@sub r0, r2
@ldr r2, =0x202BCBC @(gCurrentRealCameraPos )	@{U}
@@ldr r2, =0x202BCB8 @(gCurrentRealCameraPos )	@{J}
@ldrh r2, [r2, #2] 
@sub r1, r2

lsl r0, #23 @ only 9 bits used for coords 
lsr r0, #23 
lsl r1, #24 
lsr r1, #24 


mov r2, #0 @ 0, 1, 2, or 3 as valid here?
		@ probably 8, 16, 32, and 64 pixel squares 
lsl r2, #0xe @ bits E-F determine size 
orr r0, r2                    @ Sprite size, 8x8

@mov r2, #0x4 @ blend bit
@lsl r2, #8 
@orr r1, r2 
@ r1 also has sprite shape (default is square, but can also be horizontal or vertical rectangle) 



@mov r3, r3 @ Vram tile 
mov r2, #16 @ palette # 16 - icon palette 
lsl r2, #12 @ bits 12-15 
orr r3, r2 @ palette | flips | tile 

@mov r2, #2 
@lsl r2, #10 
@orr r3, r2 @ priority 2 (display above unit sprites but below battle stats with anims off etc) 

ldr r2, =gObj_8x8 
blh PushToSecondaryOAM, r4 

pop {r4} 
pop {r0} 
bx r0 
.ltorg 





