@Don't have more than 1 of these equal to 1 at a time. Issues will arise.
.equ FE6, 0
.equ FE7, 0
.equ FE8, 1	@untested

.thumb
.org 0

@jumped to at 22410 (fe6)
@r4 = char data ptr

.equ crit_warning_cutoff, 24	@anything less than or equal this won't trigger the !

.equ GetDebuffs, FramePointers+4
.equ DebuffArrowFrame, FramePointers+8
.equ BuffArrowFrame, FramePointers+12
.equ AnyDebuffsBitfieldLink, FramePointers+16
.equ AnyBuffsBitfieldLink, FramePointers+20

.if FE6 == 1
	.equ WarningCache, 			0x0203ACC0	@free space in ram. Change this if necessary.
	.equ OptionByte2, 			0x0202AA66
	.equ CameraStuff, 			0x0202AA08
	.equ WRAMDisplay, 			0x08003870
	.equ CurrentCharPtr, 		0x030044B0
	.equ Can_Equip_Item, 		0x08016538
	@ .equ Get_Unit_Max_Hp, TODO
	.equ Get_Item_Crit, 		0x08017224
	.equ Check_Effectiveness, 	0x08016A10
	.equ Talk_Check, 			0x0806AF4C
	.equ return_addr, 			0x0802241A+1
	.equ x_coord, 				0x0E
	.equ y_coord, 				0x0F
	.equ maximum_hp, 			0x10
	.equ current_hp, 			0x11
	.equ inventory_slot1, 		0x1C
	.equ status_byte, 			0x2E
.endif

.if FE7 == 1
	.equ WarningCache, 			0x0203ACC0	@free space in ram. Change this if necessary.
	.equ OptionByte2, 			0x0202BC39
	.equ CameraStuff, 			0x0202BBB8
	.equ WRAMDisplay, 			0x08004388
	.equ CurrentCharPtr,		0x03004690
	.equ Can_Equip_Item, 		0x080161A4
	@ .equ Get_Unit_Max_Hp, TODO
	.equ Get_Item_Crit, 		0x08017328
	.equ Check_Effectiveness, 	0x08016820
	.equ Talk_Check, 			0x080789FC
	.equ return_addr, 			0x08025C16+1
	.equ x_coord, 				0x10
	.equ y_coord, 				0x11
	.equ maximum_hp, 			0x12
	.equ current_hp, 			0x13
	.equ inventory_slot1, 		0x1E
	.equ status_byte, 			0x30
.endif

.if FE8 == 1
	.equ WarningCache, 			0x0203AE00	@free space in ram. Change this if necessary.
	.equ OptionByte2, 			0x0202BD31
	.equ CameraStuff, 			0x0202BCB0
	.equ WRAMDisplay, 			0x08002BB8
	.equ CurrentCharPtr,		0x03004E50
	.equ Can_Equip_Item, 		0x08016574
	.equ Get_Unit_Max_Hp,		0x08019190
	.equ Get_Item_Crit, 		0x08017624
	.equ Check_Effectiveness, 	0x08016BEC
	.equ Slayer_Check, 			0x08016C88
	.equ Talk_Check, 			0x08083F68
	.equ return_addr, 			0x080276BE+1
	.equ x_coord, 				0x10
	.equ y_coord, 				0x11
	.equ maximum_hp, 			0x12
	.equ current_hp, 			0x13
	.equ inventory_slot1, 		0x1E
	.equ status_byte, 			0x30
.endif

push	{r4-r7}
add		sp,#-0x10

@First, check if all this stuff is even enabled
ldr		r0,=OptionByte2
ldrb	r0,[r0]
.if FE8 == 1
mov		r1,#0x80
.else
@ NOTE: this is either the fe6-specific bit, or teq has added an extra setting in the original impl of this
mov		r1,#0x20
.endif
tst		r0,r1
beq		HpBars					@if bit isn't set, hp bars are on (at the very least)
b		GoBack

HpBars:
mov		r0,#0
str		r0,[sp]					@bool for whether the unit is on the screen
mov		r1,#x_coord
ldsb	r1,[r4,r1]
lsl		r1,#4
ldr		r2,=CameraStuff
mov		r3,#0xC
ldsh	r0,[r2,r3]				@camera x
sub		r3,r1,r0				@r3= x - camera_x
mov		r0,#y_coord
ldsb	r0,[r4,r0]
lsl		r0,#4
mov		r1,#0xE
ldsh	r1,[r2,r1]				@camera y
sub		r2,r0,r1				@r2 = y - camera_y
mov		r1,r3
add		r1,#0x10
mov		r0,#0x80
lsl		r0,#1
cmp		r1,r0
bhi		CheckIfSelected			@x is either >0x100 or <0, so out of range
mov		r0,r2
add		r0,#0x10
cmp		r0,#0xB0
bhi		CheckIfSelected			@y is either >0xB0 or <0, so out of range
mov		r1,#1
str		r1,[sp]					@change bool to true (display whatever)
str		r3,[sp,#0x4]			@sp+4 = x - x'
str		r2,[sp,#0x8]			@sp+8 = y - y'
ldr		r1,=#0x201
str		r1,[sp,#0xC]			@constant to determine where things get drawn
@Find out whether we even need to display an hp bar
.if FE8 == 1 @ TODO: other games
	mov		r0, r4				@ arg r0 = Unit
	ldr		r1, =Get_Unit_Max_Hp
	mov		r14,r1
	.short	0xF800
.else
	mov		r0,#maximum_hp
	ldsb	r0,[r4,r0]
.endif
mov		r2,#current_hp
ldsb	r2,[r4,r2]
cmp		r2,r0
@bge		CheckIfSelected			@if hp is max, don't show the bar
bge		CheckIfBuffs			@if hp is max, check for debuffs
mov		r1,r0 @ arg r1 = mhp
sub		r0,r2
mov		r2,#9
mul		r0,r2 @ arg r0 = damage*9
swi		#6						@damage*9/maxHP
@Call the drawing routine
ldr		r1,=WRAMDisplay
mov		r14,r1
lsl		r2,r0,#2
ldr		r3,FramePointers		@EA defined
add		r2,r3
ldr		r2,[r2]
ldr		r1,[sp,#0xC]			@0x201
ldr		r3,[sp,#0x4]			@x-x'
add		r0,r3,r1
sub		r1,#2					@0x1FF
and		r0,r1
ldr		r1,[sp,#0x8]			@y-y'
add		r1,#0xFB
mov		r3,#0xFF
and		r1,r3
mov		r3,#0
.short	0xF800					@call routine to display bars

CheckIfBuffs:
@first, some setup
mov		r0,r4
ldr		r1,GetDebuffs
mov		lr,r1
.short	0xF800
mov		r6,r0
mov		r5,#0

@now we check
ldr		r0,[r6,#4]
ldr		r1,AnyBuffsBitfieldLink
ldr		r1,[r1]
tst		r0,r1
beq		CheckIfDebuffs

	mov		r0,r13
	mov		r1,r5
	ldr		r2,BuffArrowFrame
	mov		r3,#0xF7
	bl		DrawArrow
	add		r5,#4 @if two arrows must be drawn on a unit, this will shift it to the right by 4 pixels
	
CheckIfDebuffs:
ldr		r0,[r6]
ldr		r1,AnyDebuffsBitfieldLink
ldr		r1,[r1]
tst		r0,r1
beq		CheckIfSelected

	DrawDebuffArrow:
	mov		r0,r13
	mov		r1,r5
	ldr		r2,DebuffArrowFrame
	mov		r3,#0xF9
	bl		DrawArrow

@This section is for effectiveness/talk/wta/whatever, which only display if a unit is selected. Since checking for this every frame makes it super laggy, we create a cache. First byte will be reserved for status of the operation: 0 if unit isn't selected, 1 if filling the cache, 2 if done
CheckIfSelected:
ldr		r6,=CurrentCharPtr
ldr		r6,[r6]
cmp		r6,#0
beq		UnitNotSelected			@no current unit
ldrb	r0,[r6,#0xB]
mov		r1,#0xC0
tst		r0,r1
bne		UnitNotSelected			@selecting enemy/ally shouldn't do anything

ldrb	r0,[r6,#0xC]			@status byte
mov		r1,#1					@do not display standing map sprite
tst		r0,r1
bne		CheckIfFirstPass

UnitNotSelected:
ldr		r0,=WarningCache
mov		r1,#0
str		r1,[r0]
b		GoBack

CheckIfFirstPass:
ldr		r0,=WarningCache
ldrb	r1,[r0]
cmp		r1,#2
beq		DisplayOtherIcons
@at this point, we must be on the first pass
ldrb	r1,[r0,#1]				@most recent allegiance byte we looked at
ldrb	r2,[r4,#0xB]			@current allegiance
cmp		r2,r1
bgt		FirstPass				@we haven't looped through all the units yet if current>previous
mov		r1,#2
strb	r1,[r0]					@first pass is complete
b		DisplayOtherIcons

FirstPass:
strb	r2,[r0,#1]				@replace previous looked-at unit with current one
mov		r1,#1
strb	r1,[r0]					@and ensure we're still in first-pass mode
mov		r7,#0					@initialize the bitfield we write to the cache

@Effectiveness/Critical checks (WTA/D would also go here, if applicable)
ldr		r0,=OptionByte2
ldrb	r0,[r0]
mov		r1,#0x10
tst		r0,r1
bne		TalkEventCheck			@if this bit is set, we only want hp bars and talk icons
ldrb	r0,[r4,#0xB]
mov		r1,#0x80
tst		r0,r1
beq		TalkEventCheck			@if not enemy, no need for this check

@slayer check for fe8
.if FE8 == 1
	mov 	r0,r4
	mov		r1,r6
	ldr		r2,=Slayer_Check
	mov		r14,r2
	.short	0xF800
	cmp		r0,#0
	bne		IsEffective
.endif
@priority system for making effective warning appear before high crit warning regardless of item order in unit's inventory
push	{r7}
mov		r7,#0
BeginningOfLoop:
mov		r5,#inventory_slot1
LoopThroughItems:
ldrh	r1,[r4,r5]
cmp		r1,#0
beq		NextItem
mov		r0,r4
ldr		r2,=Can_Equip_Item
mov		r14,r2
.short	0xF800
cmp		r0,#0
beq		NextItem
ldrh	r0,[r4,r5]
mov		r1,r6
ldr		r2,=Check_Effectiveness
mov		r14,r2
.short	0xF800
cmp		r0,#0
bne		IsEffective
@cmp		r7,#0
@beq		CheckCrit @optional setting: if unit has a high crit weapon as their first item, then that will be prioritized over having an effective weapon
cmp		r7,#5
blt		NextItem
CheckCrit:
ldrh	r0,[r4,r5]
ldr		r1,=Get_Item_Crit
mov		r14,r1
.short	0xF800
cmp		r0,#crit_warning_cutoff
ble		NextItem
cmp		r0,#255
bne		IsCritty @255 means cannot crit
NextItem:
add		r5,#2
add		r7,#1
cmp		r5,#inventory_slot1+8
ble		LoopThroughItems
cmp		r7,#5
bne		NoDangerousItem
b		BeginningOfLoop

IsEffective:
mov		r0,#1
b		TransitionFromWarning

IsCritty:
mov		r0,#2

TransitionFromWarning:
pop		{r7}
orr		r7,r0
b		TalkEventCheck

NoDangerousItem:
pop		{r7}

TalkEventCheck:
ldr		r0,[r6]
ldrb	r0,[r0,#4]				@active unit's char id
ldr		r1,[r4]
ldrb	r1,[r1,#4]				@current unit's char id
ldr		r2,=Talk_Check
mov		r14,r2
.short	0xF800
cmp		r0,#0
beq		WriteToCache
mov		r0,#4
orr		r7,r0
WriteToCache:
ldr		r0,=WarningCache
add		r0,#2					@first 2 bytes are occupied
ldrb	r1,[r4,#0xB]
add		r0,r1
strb	r7,[r0]
b		GoBack					@opting to do the displaying on the second pass

DisplayOtherIcons:
ldr		r5,=WarningCache
add		r5,#2
ldrb	r0,[r4,#0xB]
ldrb	r5,[r5,r0]
cmp		r5,#0
beq		GoBack					@nothing to display
@DisplayEffective
mov		r0,#1					@effective
tst		r0,r5
beq		DisplayCrit
mov		r0,#0
mov		r1,sp
bl		Draw_Warning_Sign
DisplayCrit:
mov		r0,#2
tst		r0,r5
beq		DisplayTalk
mov		r0,#8
mov		r1,sp
bl		Draw_Warning_Sign
DisplayTalk:
mov		r0,#4
tst		r0,r5
beq		GoBack
mov		r0,#0x10
mov		r1,sp
bl		Draw_Warning_Sign

GoBack:
add		sp,#0x10
pop		{r4-r7}
mov		r0,#status_byte
ldrb	r0,[r4,r0]
lsl		r0,#0x1C
lsr		r0,#0x1C
ldr		r1,=return_addr
bx		r1

DrawArrow:
push	{r4,r14}
ldr		r4,=WRAMDisplay
mov		lr,r4
@lsl	r1,#2
ldr		r4,[r0,#0x4]			@x-x'
add		r4,r1
ldr		r1,[r0,#0xC]			@0x201
add		r4,r1
sub		r1,#2					@0x1FF
and		r4,r1
ldr		r1,[r0,#0x8]			@y-y'
mov		r0,r4
add		r1,r3
mov		r3,#0xFF
and		r1,r3
mov		r3,#0
.short	0xF800
pop		{r4}
pop		{r0}
bx		r0

Draw_Warning_Sign:
@r0=thing to determine what we're drawing, r1=sp (to retrieve x and y stuff)
push	{r4,r5,r14}
ldr		r2,[r1]					@bool to determine whether we're on screen
cmp		r2,#0
beq		FinishedDrawing
mov		r4,r0
mov		r5,r1
ldr		r1,=WRAMDisplay
mov		r14,r1
ldr		r1,[r5,#0xC]			@0x201
ldr		r0,[r5,#0x4]			@x-x'
add		r0,r1
add		r0,#0xB					@tweak for x coordinate, whatever that means
sub		r1,#2
and		r0,r1
ldr		r1,[r5,#0x8]			@y-y'
add		r1,#0xEE				@y coordinate tweak?
mov		r2,#0xFF
and		r1,r2
mov 	r2,#(WS_FrameData - LoadFrameData - 4)
LoadFrameData:
add 	r2,pc
add 	r2,r4
mov		r3,#0
.short	0xF800					@call routine to display bars
FinishedDrawing:
pop		{r4-r5}
pop		{r0}
bx		r0

.ltorg
.align

WS_FrameData: @should be the OAM data
.long 0x000f0001 @8x8 sprite
.long 0x087601ff @the tile is 0x76
Killer_FrameData:
.long 0x000f0001
.long 0x087701ff @tile #0x77
Talk_FrameData:
.long 0x400f0001 @16x8 sprite
.long 0x087001ee @tile #0x70
FramePointers:
@
