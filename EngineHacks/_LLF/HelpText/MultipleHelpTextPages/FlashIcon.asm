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
mov r1, #0 
str r1, [r0, #0x34] @ do not pause 

mov r0, r4 
pop {r1} 
bx r1 
.ltorg 
.equ ProcGoto, 0x8002F24 
.global HelpBoxFlashIcon
.type HelpBoxFlashIcon, %function 
HelpBoxFlashIcon:
push {r4, lr} 
mov r4, r0 
ldr r0, [r4, #0x34] @ immediately idle 
cmp r0, #0 
bne Idle 

ldr r0, =0x8A00A98 @ HelpBoxControl
blh ProcFind 
cmp r0, #0 
bne FlashIconIfDoneScrolling
mov r0, r4 
mov r1, #2 @ exit 
blh ProcGoto 
b Exit 
FlashIconIfDoneScrolling: 
ldr r0, =0x8A01628 @ HelpBoxTextScroll
blh ProcFind 
cmp r0, #0 
bne Idle 

bl DrawTheSprite 
mov r0, r4 
mov r1, #1
blh ProcGoto 
b Exit 
Idle: 
mov r0, #0 
str r0, [r4, #0x34] @ do not immediately idle next time 
mov r0, r4 
mov r1, #0 
blh ProcGoto 

Exit: 
pop {r4} 
pop {r0} 
bx r0 
.ltorg 


// https://github.com/FireEmblemUniverse/fireemblem8u/blob/015f95751ef4d526c08bc424e1c5d6dba9d3c88d/src/scene.c#L1583
// int frame = (GetGameClock() / 2) & 0xf;
// https://github.com/FireEmblemUniverse/fireemblem8u/blob/015f95751ef4d526c08bc424e1c5d6dba9d3c88d/src/scene.c#L1777
// gBG0TilemapBuffer + TILEMAP_INDEX(sTalkState->xText, sTalkState->yText + 2 * i)
.equ GetLastHelpBoxInfo, 0x80895A8 
.equ HelpBoxControl, 0x8A00A98 
.equ sMutableHbi, 0x203E768 
.equ HelpTextHandle, 0x203E7C4 
.equ PutSprite, 0x80053E8 
.equ gPressKeyArrowSpriteLut, 0x8591430 
.equ GetGameClock, 0x8000D28 
DrawTheSprite: 
push {r4-r6, lr} 




ldr r0, =HelpBoxControl
blh ProcFind 
ldrh r4, [r0, #0x3C] @ x 
ldrh r5, [r0, #0x3E] @ y 
ldrh r2, [r0, #0x34] @ width 
ldrh r3, [r0, #0x36] @ height 

add r4, r2 
add r5, r3 
sub r4, #8 
sub r5, #8 @ bottom right of the help box 


blh GetGameClock 
lsr r0, #1 
mov r1, #0xF 
and r0, r1 
lsl r0, #2 


ldr r6, =gPressKeyArrowSpriteLut
ldr r6, [r6, r0] 

@PutSprite(0, proc->unk64, proc->unk66, gPressKeyArrowSpriteLut[frame], 4);
sub sp, #4 
mov r0, #4 @ vram tile 
str r0, [sp] 
mov r0, #0 @ priority 
mov r1, r4 
mov r2, r5 
mov r3, r6 
blh PutSprite, r4
add sp, #4 

pop {r4-r6} 
pop {r0} 
bx r0 
.ltorg 





