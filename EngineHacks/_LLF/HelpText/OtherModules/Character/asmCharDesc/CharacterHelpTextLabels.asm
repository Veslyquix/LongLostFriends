.thumb

.include "../CharacterDefs.s"

.global CharacterHelpTextLabels
.type CharacterHelpTextLabels, %function


		CharacterHelpTextLabels:
		push	{r4-r7,r14}
		ldr		r4, =gHelpTextStuff
		ldr		r5, =CharacterLabelLink
		ldr		r6, =Text_InsertString
		mov		r7, #0 @loop variable

		DisplayNextLabel:
		lsl		r1, r7, #1
		ldrh	r0, [r5,r1]
		ldr		r3, =String_GetFromIndex
		mov		lr, r3
		.short	0xF800
		mov		r3, r0
		mov		r1, #0 @spacing
		cmp		r7, #0
		beq		GoToText_InsertString
	
			mov		r1, #0x32
		
		GoToText_InsertString:
		mov		r0, r4
		mov		r2, #8 @font color
		mov		lr, r6
		.short	0xF800
		
		add		r7, #1
		cmp		r7, #2
		blt		DisplayNextLabel
		
		mov		r0, #1 @Number of lines needed for labels
		pop		{r4-r7}
		pop		{r1}
		bx		r1
		
		.align
		.ltorg

