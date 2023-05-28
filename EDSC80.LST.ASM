 
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ 
 
 	.PHASE 100h 
	CSEG 
noend	equ	1 
include RkConfig.mac 
; Platform selection 
;RK60k	EQU	1 
PALMIRA EQU	1 
include	RK86.MAC 
IFNDEF	?Ctrl 
;** RK86.MAC - Radio-86 computer specific constants & macro *** 
; 
;	09-Oct-1992  - first version 
;	15-Nov-1992  - Add 82XX.MAC 
;	02-Apr-2021  - Special version for original RK 
 
?Ctrl	equ	40h 
?Shift	equ	20h 
 
; IN and OUT MACRO comands 
@in	MACRO	addr 
	lda	addr 
	ENDM 
 
@out	MACRO	addr 
	sta	addr 
	ENDM 
 
GETMAXMEM	EQU 0F830h 
ENDIF 
include	E0DISP.MAC 
IFNDEF	TabStep 
;**************************************************** 
;    SC80 text screen editor    (C) TCHV,1989-93    * 
;                                                   * 
;  E0DISP.MAC - Display dependent macro definitions * 
;                                                   * 
;          This file is for Original 32k version    * 
;**************************************************** 
TabStep		equ	8 
;LimitedCharSet	equ	1 
 
ScrXOffset	equ	8 
ScrYOffset	equ	3 
ScrWidth	equ	78 
ScrHeight	equ	25 
 
LogicWidth	equ	64 ; 78 - 8 trailing blank symbols - 5 end blank symbols 
LogicHeight	equ	ScrHeight-2 
 
ScrSize		equ	(ScrHeight+ScrYOffset+2)*ScrWidth 
;ScrStart	equ	76D0h ; Display buffer start 
 
; Start address of physical screen - visible characters 
ScrOffset	equ	ScrYOffset*ScrWidth+ScrXOffset 
;VRAM		equ	ScrStart+ScrOffset 
 
SetScrAddr	macro 
		endm 
 
WriteNextSym	macro 
		mov	m,a 
		inx	h 
		endm 
 
space		equ	20h 
IFDEF	PALMIRA 
CURSOR_BLOCK	equ	0E8h 
CURSOR_LINE	equ	0D8h 
ELSE 
CURSOR_BLOCK	equ	0E3h 
CURSOR_LINE	equ	0D3h 
ENDIF 
 
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ 
ENDIF 
include	E0BREAK.MAC 
 
; 
;	E0break.mac - time safe break check 
; 
 
;PPI	equ	0F780h 
 
; Initialize break checking 
init_brk_check	macro 
		PUSH	H 
		;MVI	A,0FEH 
		;STA	PPI 
		LHLD	PPI_ADR 
		MVI	M,0FEH 
		POP	H 
		endm 
 
; Check for break key pressed (Z=1) 
check_break	macro 
		;LDA	PPI+1 
		PUSH	H 
		LHLD	PPI_ADR 
		INR	L 
		MOV	A,M 
		POP	H 
		ANI	40h 
		endm 
include	E0MAIN.ASM 
	;********************************************** 
;*        TCHV text full-screen editor        * 
;*               (c) 1989-92                  * 
;* Text processing and general control module * 
;********************************************** 
 
;	 6-Dec-1991 
;	 8-Dec-1991 -   80 - symbol mode for CP/M, 
;		macros SetScrAddr and WriteNextSym 
;	14-Jan-1992 -  Use some CP/M features 
;	28-Jan-1992 -  Change command table presentation 
;	01-Mar-1992 -  Delete some bugs 
;	15-Mar-1992 -  Add case insensitive search 
 
;	02-Apr-2021 -  Original RK back-adaptation 
;	25-Apr-2021 -  Controller addresses table 
 
 
PUBLIC	INFADR 
;PUBLIC	INFSTR 
 
.8080 
	CSEG 
	;ORG 104H 
 
StkSize	EQU	30h 
 
TXTBUFF	EQU	2000H 
WRK	EQU	1E00H 
 
 
IFNDEF	noend 
extrn	SETCURSOR,SETSCR ; From E0DISP.ASM 
extrn	GETCHC,GETCHR	; From E0GETC.ASM 
 
extrn   FNDCMD		; From E0CMDT.ASM 
ENDIF 
 
LineSym		equ	1ch 
DelimSym	equ	1bh 
 
INFSTR_OFFS	EQU	ScrWidth*(ScrHeight-1) 
;INFSTR	EQU	VRAM+INFSTR_OFFS 
MAXLEN	EQU	127 
 
PUBLIC	VRAM_ADR,PPI_ADR,DISP_ADR,DMA_ADR 
 
	JMP	START 
; Controller addresses table 
IFDEF	PALMIRA 
	VRAM_ADR:	DW 0B7C2h	; VRAM buffer visible start address - 0B7C2h 
	PPI_ADR:	DW 0C200h 	; VV55 keyboard Controller - 0C200h 
	PPI2_ADR:	DW 0C400h	; VV55 additional PPI  - 0C400h 
	DISP_ADR:	DW 0C000h	; VG75 Display Controller - 0C000h 
	DMA_ADR:	DW 0E000h	; VT57 DMA Controller - 0E000h 
ELSE 
IFDEF	RK60k 
	VRAM_ADR:	DW 0E7C2h	; VRAM buffer visible start address - 0E7C2h 
	PPI_ADR:	DW 0F780h 	; VV55 keyboard Controller - 0F780h 
	PPI2_ADR:	DW 0F7A0h	; VV55 additional PPI  - 0F7A0h 
	DISP_ADR:	DW 0F7C0h	; VG75 Display Controller - 0F7C0h 
	DMA_ADR:	DW 0F7E0h	; VT57 DMA Controller - 0F7E0h 
ELSE 
	VRAM_ADR:	DW 77C2h	; VRAM buffer visible start address - 77c2h 
	PPI_ADR:	DW 08000h 	; VV55 keyboard Controller - 8000h 
	PPI2_ADR:	DW 0A000h	; VV55 additional PPI  - 0A000h	 
	DISP_ADR:	DW 0C000h	; VG75 Display Controller - 0C000h 
	DMA_ADR:	DW 0E000h	; VT57 DMA Controller - 0E000h 
ENDIF 
ENDIF 
		DW 0,0,0,0 ; Reserved for future use 

 
START:: 
	CALL	GETMAXMEM;lhld	6 
	sphl 
	MVI	M,0FFH 
	MVI	A,1 
	STA	DISPOS 
	STA	DISPS0 
	LXI	H,0 
	SHLD	SCRBG0 
	CALL	INIT 
	MVI	A,0FFH 
	STA	?WIN1 
	LXI	H,101H 
	SHLD	CURX 
	SHLD	CURX0 
	LXI	H,1 
 	SHLD	CURSTR 
	CALL	CLS 
	CALL	OVRW 
	LXI	H,TXTBUFF 
	SHLD	nivgr 
	SHLD	BLBEG 
	SHLD	BLEND 
	XCHG 
	CALL	MAXRAM 
	SHLD	werhgr 
	XCHG 
	CALL	CHECKMEM 
	CPI	0FFH 
	JZ	M01 
	LHLD	nivgr 
	MVI	M,0DH 
	INX	H 
	MVI	M,0FFH 
M01:	SHLD	werhgr 
M00:	LHLD	nivgr 
	SHLD	SCRADR 
	SHLD	STRADR 
	SHLD	TABSRH 
	CALL	COMPST 
	LHLD	SCRADR 
	SHLD	SCRAD0 
	LHLD	STRADR 
	SHLD	STRAD0 
	CALL	CURSM 
	xra	a 
	sta	?StringBufActive 
	CALL	DISPLY 
	JMP	M03 
 
SETINF:	CALL	DRLIN 
	LHLD	STRADR 
	SHLD	TABSRH 
	CALL	CURSM 
	CALL	LINE 
 
	CALL	GETINFADR 
	SetScrAddr 
	mvi	c,8 
@@000:	mvi	a,space 
	WriteNextSym 
		mov	m,a 
		inx	h 
	dcr	c 
	JNZ	@@000 
 
	CALL	INFPR 
	DW	8 
	DC	'LINE: ' 

 
	LHLD	NUMSTR 
	CALL	?FBBCD 
	XCHG 
	CALL	GETINFADR 
	PUSH	D 
	LXI	D,22 
	DAD	D 
	POP	D 
	CALL	BPR 
	mvi	a,'/' 
	SetScrAddr 
	WriteNextSym 
		mov	m,a 
		inx	h 
	DCX	H 
	DCX	H 
	PUSH	H 
	LHLD	CURSTR 
	CALL	?FBBCD 
	XCHG 
	POP	H 
	CALL	BPR 
	CALL	INFPR 
	DW	36 
	DC	'     TEXT:' 


	LHLD	werhgr 
	XCHG 
	CALL	GETINFADR 
	PUSH	D 
	LXI	D,57 
	DAD	D 
	POP	D 
	SetScrAddr 
	mvi	a,'H' 
	WriteNextSym 
		mov	m,a 
		inx	h 
	dcx	h 
	DCX	H 
	CALL	BPR 
	call	INFPR 
	dw	51 
	dc	'H-' 
	CALL	GETINFADR 
	PUSH	D 
	LXI	D,50 
	DAD	D 
	POP	D 
	XCHG 
	LHLD	nivgr 
	XCHG 
	CALL	BPR 
	CALL	INFPR 
	DW	23 
	DC	'      COL:' 


	JMP	DISCUR 
 
WRMSRT:	CALL	SAVMOD 
OUT1:	CALL	DISPLY 
OUT3:	CALL	GETMAXMEM;lhld	6 
	sphl 
	JMP	M03 
 
MAXRAM:	CALL	GETMAXMEM;LHLD	6 
	push	b 
	lxi	b,-StkSize 
	dad	b 
	pop	b 
	RET 
 
CLS:	;lxi	h,ScrStart 
	lhld	VRAM_ADR 
	lxi	b,-ScrOffset 
	dad	b 
	lxi	b,ScrSize-1 
 
	SetScrAddr 
	mvi	a,8Dh ; 84H 
	WriteNextSym 
		mov	m,a 
		inx	h 
ClsLoop: 
	mvi	a,space 
	WriteNextSym 
		mov	m,a 
		inx	h 
	DCX	B 
	MOV	A,B 
	ORA	C 
	jnz	ClsLoop 
	RET 
 
INIT: 
	LHLD	VRAM_ADR 
	SHLD	SCRBEG 
	MVI	A,LogicHeight 
	STA	YSIZE 
	XRA	A 
	STA	YBEG 
	LHLD	VRAM_ADR 
	LXI	D,INFSTR_OFFS 
	DAD	D 
	SHLD	INFADR 
	RET 
 
DRLIN:	LDA	SCRBG0+1 
	ORA	A 
	RZ 
	LHLD	INFADR 
	LDA	?WIN1 
	ORA	A 
	JNZ	$+6 
	LHLD	INFAD0 
	LXI	B,-ScrWidth 
	DAD	B 
	MVI	A,LogicWidth-1 
	MVI	M,'^' 
	INX	H 
	DCR	A 
	JNZ	$-4 
	RET 
 
CHECKMEM:	MOV	A,M 
	CPI	0FFH 
	JNZ	CHKM0 
	DCX	H 
	MOV	A,M 
	INX	H 
	CPI	0DH 
	MVI	A,0FFH 
	RZ 
CHKM0:	INX	H 
	MOV	A,H 
	INR	A 
	CMP	D 
	JC	CHECKMEM 
	MOV	A,L 
	INR	A 
	CMP	E 
	JC	CHECKMEM 
	MVI	A,0 
	RET 
 
DISCUR:	LDA	CURX 
	MOV	L,A 
	MVI	H,0 
	CALL	?FBBCD 
	XCHG 
	CALL	GETINFADR 
	PUSH	D 
	LXI	D,35 
	DAD	D 
	POP	D 
	MOV	A,E 
	CALL	BPR1 
	MOV	A,D 
	JMP	BPR01 
 
INRCUR:	LHLD	CURSTR 
	INX	H 
	SHLD	CURSTR 
	RET 
 
DCRCUR:	LHLD	CURSTR 
	DCX	H 
	SHLD	CURSTR 
	RET 
 
COMPST:	LXI	D,0 
	LHLD	nivgr 
COMP1:	MOV	A,M 
	INX	H 
	CPI	0FFH 
	JZ	COMP0 
	CPI	0DH 
	JNZ	COMP1 
	INX	D 
	JMP	COMP1 
COMP0:	XCHG 
	SHLD	NUMSTR 
	RET 
 
COMCUR:	LHLD	nivgr 
	XCHG 
	LHLD	STRADR 
	MOV	A,L 
	SUB	E 
	MOV	C,A 
	MOV	A,H 
	SBB	D 
	MOV	B,A 
	INX	B 
	LXI	D,1 
COMP2:	DCX	B 
	MOV	A,B 
	ORA	C 
	JZ	COMP3 
	MOV	A,M 
	DCX	H 
	CPI	0DH 
	JNZ	$+4 
	INX	D 
	JMP	COMP2 
COMP3:	XCHG 
	SHLD	CURSTR 
	RET 
 
DISPLY:	PUSH	H 
	PUSH	B 
	PUSH	PSW 
	PUSH	D 
	CALL	SWPWN 
	JZ	DSPL0 
	CALL	DSPL1 
	CALL	SWPWN 
DSPL0:	CALL	DSPL1 
	POP	D 
	POP	PSW 
	POP	B 
	POP	H 
	RET 
 
DSPL1:	LHLD	SCRADR 
	XCHG 
	LHLD	SCRBEG 
	LDA	YSIZE 
	MOV	B,A 
	CALL	D01 
	SHLD	SCREND 
	RET 
 
 
D01: 
	XRA	A 
	STA	?END 
	PUSH	B 
 
	push	h 
	push	d 
	lda	?StringBufActive 
	ora	a 
	jz	@220 
	lhld	STRADR 
	xchg 
	mov	a,h 
	cmp	d 
	jnz	@220 
	mov	a,l 
	cmp	e 
	jnz	@220 
	pop	d 
	pop	h 
	push	d 
	lxi	d,STRRED 
	call	DISSTR 
	pop	d 
	xchg 
	CALL	NEXTST 
	xchg 
	jmp	@221 
@220: 
	pop	d 
	pop	h 
	;lda	DISPOS 
	CALL	DISSTR 
@221: 
	POP	B 
	CPI	0FFH 
	JZ	@11 
	INX	D 
	DCR	B 
	JNZ	D01 
	JMP	@12 
@11:	LDA	?END 
	ORA	A 
	JNZ	@110 
	MOV	A,B 
	STA	?END 
@110:	DCR	B 
	JZ	@12 
@9:	MVI	C,ScrWidth 
 
@10: 
	SetScrAddr 
 
@101:	mvi	a,space 
	WriteNextSym 
		mov	m,a 
		inx	h 
	DCR	C 
	JNZ	@10 
	DCR	B 
	JNZ	@9 
@12:	XCHG 
	RET 
 
;@ 
 
DELAY0:	DCX	B 
	MOV	A,B 
	ORA	C 
	JNZ	DELAY0 
	RET 
 
 
wlewo:	LDA	CURX 
	DCR	A 
	RZ 
	STA	CURX 
	JMP	CURSM 
 
wprawo:	LDA	CURX 
	CPI	MAXLEN 
	RNC 
	INR	A 
	STA	CURX 
	JMP	CURSM 
 
wp1:	LDA	DISPOS 
	ADI	8 
	STA	DISPOS 
	CALL	DISPLY 
	JMP	CURSM 
 
GETC:	PUSH	H 
	PUSH	D 
	PUSH	B 
	LHLD	TABSRH 
	LDA	CURX 
	MOV	C,A 
	MVI	B,1 
	MOV	E,B 
GTC0:	MOV	A,B 
	CMP	C 
	JNC	GTC3 
	MOV	A,M 
	INX	H 
	CPI	9 
	JZ	GTC1 
	CPI	0DH 
	JZ	GTC2 
	INR	B 
	INR	E 
	JMP	GTC0 
GTC1:	MOV	A,B 
	call	CalcNextTabPos 
	MOV	B,A 
	MOV	A,C 
	CMP	B 
	JC	GTC3 
	INR	E 
	JMP	GTC0 
GTC2:	MOV	A,C 
	SUB	B 
	ADD	E 
	MOV	E,A 
GTC3:	MOV	A,E 
	POP	B 
	POP	D 
	POP	H 
	RET 
 
CURCM:	PUSH	H 
	PUSH	B 
	LHLD	TABSRH 
	LDA	CURX 
	MOV	C,A 
	MVI	B,1 
CC0:	DCR	C 
	JZ	CC2 
	MOV	A,M 
	INX	H 
	CPI	9 
	JZ	CC1 
	CPI	0DH 
	JZ	CC3 
	CPI	0FFH 
	JZ	CC3 
	INR	B 
	JMP	CC0 
CC1:	MOV	A,B 
	call	CalcNextTabPos 
	MOV	B,A 
	JMP	CC0 
CC3:	INR	B 
	DCR	C 
	JNZ	CC3 
CC2:	MOV	A,B 
	STA	CURX 
	CALL	CURSM 
	POP	B 
	POP	H 
	RET 
 
CalcNextTabPos: 
	DCR	A 
	ORI	TabStep-1 
	ADI	2 
	ret 
 
INFCRM:	LDA	YSIZE 
	ADI	2 
	STA	CURY 
CURM:	push	h 
	lhld	CURX 
	call	SetCursor 
	pop	h 
	ret 
 
CURSM::	LDA	DISPOS 
	PUSH	B 
	MOV	B,A 
	LDA	CURX 
	SUB	B 
	POP	B 
	JC	LEFT 
	CPI	LogicWidth 
	JNC	RIGHT 
MovCur:	INR	A 
	mov	l,a 
	lda	CURY 
	MOV	h,A 
	LDA	YBEG 
	add	h 
	mov	h,a 
	call	SetCursor 
	ora	a 
	ret 
 
 
LEFT:	LDA	DISPOS 
	SUI	8 
	STA	DISPOS 
	JMP	CURM1 
 
RIGHT:	LDA	DISPOS 
	ADI	8 
	STA	DISPOS 
CURM1:	LDA	DISPOS 
	PUSH	B 
	MOV	B,A 
	LDA	CURX 
	SUB	B 
	POP	B 
	JC	LEFT 
	CPI	LogicWidth 
	JNC	RIGHT 
	CALL	DISPLY 
	jmp	MovCur 
 
;--------------------------------------------- 
 
wniz:	PUSH	D 
	LHLD	STRADR 
	CALL	NEXTST 
	POP	D 
	RZ 
	SHLD	STRADR 
	CALL	INRCUR 
	LDA	YSIZE 
	DCR	A 
	MOV	B,A 
	LDA	CURY 
	CMP	B 
	JNC	ROLLUP 
	INR	A 
	STA	CURY 
	JMP	CURSM 
 
RLUP:	LHLD	STRADR 
	CALL	NEXTST 
	RZ 
	SHLD	STRADR 
	CALL	INRCUR 
ROLLUP:	LHLD	SCRADR 
	CALL	NEXTST 
	SHLD	SCRADR 
	RZ 
	CALL	SCRUP 
	LHLD	SCREND 
	XCHG 
	LXI	B,-2*ScrWidth 
	LHLD	INFADR 
	DAD	B 
	lda	DISPOS 
	CALL	DISSTR 
	CPI	0FFH 
	JZ	wn20 
 
 
	INX	D 
	XCHG 
	SHLD	SCREND 
	RET 
wn20:	LXI	H,?END 
	INR	M 
	RET 
 
SCRDN:	LXI	H,0 
	DAD	SP 
	SHLD	PRSP 
	LXI	SP,LogicWidth-ScrWidth 
	LHLD	INFADR 
	LXI	D,LogicWidth-3*ScrWidth-1 
	DAD	D 
	XCHG 
	LXI	H,ScrWidth 
	DAD	D 
	LDA	YSIZE 
	DCR	A 
	MOV	B,A 
SCD1:	MVI	C,LogicWidth/4 
SCD0:	LDAX	D 
	MOV	M,A 
	DCX	H 
	DCX	D 
	LDAX	D 
	MOV	M,A 
	DCX	H 
	DCX	D 
	LDAX	D 
	MOV	M,A 
	DCX	H 
	DCX	D 
	LDAX	D 
	MOV	M,A 
	DCX	H 
	DCX	D 
	DCR	C 
	JNZ	SCD0 
	DAD	SP 
	XCHG 
	DAD	SP 
	XCHG 
	DCR	B 
	JNZ	SCD1 
	LHLD	PRSP 
	SPHL 
	RET 
 
SCRUP:	LXI	H,0 
	DAD	SP 
	SHLD	PRSP 
	LXI	SP,ScrWidth-LogicWidth 
	LXI	D,ScrWidth 
	LHLD	SCRBEG 
	DAD	D 
	XCHG 
	LHLD	SCRBEG 
 
	LDA	YSIZE 
	DCR	A 
	MOV	B,A 
 
SCU1:	MVI	C,LogicWidth/4 
SCU0:	LDAX	D 
	MOV	M,A 
	INX	H 
	INX	D 
	LDAX	D 
	MOV	M,A 
	INX	H 
	INX	D 
	LDAX	D 
	MOV	M,A 
	INX	H 
	INX	D 
	LDAX	D 
	MOV	M,A 
	INX	H 
	INX	D 
	DCR	C 
	JNZ	SCU0 
	DAD	SP 
	XCHG 
	DAD	SP 
	XCHG 
	DCR	B 
	JNZ	SCU1 
	LHLD	PRSP 
	SPHL 
	RET 
 
NEXTST:	MOV	A,M 
	CPI	0FFH 
	RZ 
	CPI	0DH 
	JZ	NXTS0 
	INX	H 
	JMP	NEXTST 
NXTS0:	INX	H 
	MOV	A,M 
	CPI	0FFH 
	RET 
 
wwerh:	PUSH	D 
	LHLD	STRADR 
	CALL	PREVST 
	POP	D 
	SHLD	STRADR 
	RZ 
	CALL	DCRCUR 
	LDA	CURY 
	DCR	A 
	JZ	ROLLDN 
	STA	CURY 
	JMP	CURSM 
 
 
RLDN:	LHLD	SCRADR 
	CALL	PREVST 
	RZ 
	LHLD	STRADR 
	CALL	PREVST 
	SHLD	STRADR 
	CALL	DCRCUR 
ROLLDN:	LHLD	SCRADR 
	CALL	PREVST 
	SHLD	SCRADR 
	RZ 
	PUSH	H 
	CALL	SCRDN 
	LHLD	SCRBEG 
	XCHG 
	POP	H 
	xCHG 
	lda	DISPOS 
	CALL	DISSTR 
 
	LXI	H,?END 
	MOV	A,M 
	ORA	A 
	JZ	RLD0 
	DCR	M 
	RET 
RLD0:	LHLD	SCREND 
	CALL	PREVST 
	SHLD	SCREND 
	RET 
 
PREVST:	DCX	H 
	LDA	nivgr+1 
	DCR	A 
	CMP	H 
	JZ	PREVS0 
PREVS1:	DCX	H 
	LDA	nivgr+1 
	DCR	A 
	CMP	H 
	JZ	PREVS2 
	MOV	A,M 
	CPI	0DH 
	JNZ	PREVS1 
PREVS2:	MVI	A,1 
	ORA	A 
	INX	H 
	RET 
 
PREVS0:	LHLD	nivgr 
	RET 
 
 
SETRST: 
	mvi	a,1 
	sta	?StringBufActive 
	LXI	H,STRRED 
	SHLD	TABSRH 
	LHLD	STRADR 
	LXI	D,STRRED 
	MVI	B,MAXLEN+1 
	MVI	C,0 
I00:	MOV	A,M 
	STAX	D 
	INX	H 
	INX	D 
	INR	C 
	CPI	0DH 
	JZ	I01 
	CPI	0FFH 
	JZ	I01 
	DCR	B 
	JNZ	I00 
	MVI	A,0DH 
	STAX	D 
	INR	C 
I01:	MOV	A,C 
	STA	OLDMES 
	STA	NEWMES 
	LHLD	SCRBEG 
	LDA	CURY 
	DCR	A 
	JZ	I02 
	LXI	B,ScrWidth 
I03:	DAD	B 
	DCR	A 
	JNZ	I03 
I02:	SHLD	VDADR 
	LHLD	BLBEG 
	SHLD	OLDBLB 
	CALL	CHKPNT 
	MVI	A,0 
	JC	$+4 
	CMA 
	STA	BEGCOR 
	LHLD	BLEND 
	SHLD	OLDBLE 
	CALL	CHKPNT 
  	MVI	A,0 
	JC	$+4 
	CMA 
	STA	ENDCOR 
	RET 
 
INSRED:	xra	a 
	sta	?StringBufActive 
	LDA	NEWMES 
	DCR	A 
	CALL	CAD1 
	INR	A 
	MOV	B,A 
I08:	DCX	H 
	DCR	B 
	JZ	I09 
	MOV	A,M 
	CPI	20H 
	JZ	I08 
	CPI	9 
	JZ	I08 
I09:	INX	H 
	MVI	M,0DH 
	MOV	A,B 
	INR	A 
	STA	NEWMES 
INSR1:	LDA	OLDMES 
	MOV	C,A 
	LDA	NEWMES 
	SUB	C 
	JZ	I04 
	MVI	B,0 
	JNC	$+5 
	MVI	B,-1 
	MOV	C,A 
	PUSH	PSW 
	PUSH	B 
	LHLD	SCREND 
	DAD	B 
	SHLD	SCREND 
	LDA	OLDMES 
	CALL	CADR11 
	POP	B 
	PUSH	H 
	DAD	B 
	POP	B 
	MOV	D,H 
	MOV	E,L 
	POP	PSW 
	PUSH	PSW 
	CNC	UPSHT 
        POP	PSW 
	CC	DNSHT 
 
I04:	LHLD	STRADR 
	LXI	D,STRRED 
	LDA	NEWMES 
	MOV	B,A 
	ORA	A 
	RZ 
I06:	LDAX	D 
	MOV	M,A 
	INX	H 
	INX	D 
	DCR	B 
	JNZ	I06 
	RET 
 
UPSHT:	CALL	COMPADR 
U1:	INX	B 
	INX	H 
U0:	DCX	H 
	DCX	B 
	LDAX	B 
	MOV	M,A 
	MOV	A,D 
	CMP	H 
	JNZ	U0 
	MOV	A,E 
	CMP	L 
	JNZ	U0 
	JNZ	U0 
	RET 
 
DNSHT:	PUSH	B 
	CALL	COMPADR 
	POP	B 
D1:	DCX	B 
	DCX	D 
D0:	INX	B 
	INX	D 
	LDAX	B 
	STAX	D 
	MOV	A,H 
	CMP	D 
	JNZ	D0 
	MOV	A,L 
	CMP	E 
	JNZ	D0 
	RET 
 
COMPADR:PUSH	B 
	MOV	A,B 
	CMA 
	MOV	B,A 
	MOV	A,C 
	CMA 
	MOV	C,A 
	INX	B 
	MOV	H,D 
	MOV	L,E 
	DAD	B 
	POP	B 
	PUSH	H 
	PUSH	D 
	MOV	D,B 
	MOV	E,C 
	MOV	B,H 
	MOV	C,L 
	LHLD	BLBEG 
	CALL	CORPNT 
	LDA	BEGCOR 
	ORA	A 
	JNZ	$+6 
	SHLD	BLBEG 
	LHLD	BLEND 
	CALL	CORPNT 
	LDA	ENDCOR 
	ORA	A 
	JNZ	$+6 
	SHLD	BLEND 
	LHLD	STRAD0 
	CALL	CORPNT 
	SHLD	STRAD0 
	LHLD	SCRAD0 
	CALL	CORPNT 
	SHLD	SCRAD0 
	XRA	A 
	STA	BEGCOR 
	STA	ENDCOR 
	POP	D 
	POP	H 
	PUSH	D 
	XCHG 
	LHLD	werhgr 
	PUSH	H 
	CALL	CHKMEM 
	DAD	D 
	SHLD	werhgr 
	POP	B 
	POP	D 
	RET 
 
CHKMEM:	PUSH	H 
	LXI	H,8000H 
	CALL	CDEHL 
	POP	H 
	RC 
	PUSH	H 
	CALL	INV_H 
	PUSH	D 
	XCHG 
	CALL	MAXRAM 
	DAD	D 
	POP	D 
	CALL	CDEHL 
	POP	H 
	RNC 
	CALL	CLRSTR 
	CALL	INFPR 
	DW	40 
	DC	'OUT OF MEMORY' 



	CALL	GETCHR 
	JMP	OUT1 
 
CORPNT:	MOV	A,B 
	ORA	A 
	JP	CRPNT0 
	CALL	CDEHL 
	JNC	CRPNT1 
	PUSH	D 
	XCHG 
	DAD	B 
	XCHG 
	CALL	CDEHL 
	JC	CRPNT2 
        MOV	H,D 
	MOV	L,E 
CRPNT2:	POP	D 
	RET 
 
CRPNT0:	CALL	CDEHL 
	RC 
CRPNT1:	DAD	B 
	RET 
 
CDEHL:	MOV	A,H 
	CMP	D 
	RNZ 
	MOV	A,L 
	CMP	E 
	RET 
LFTM::	POP	B 
	CALL	wlewo 
	JMP	RED 
 
RHTM::	POP	B 
	CALL	wprawo 
	JMP	RED 
 
UPM::	CALL	INSRED 
	CALL	wwerh 
	JMP	OUT3 
 
DWNM::	CALL	INSRED 
	CALL	wniz 
	JMP	OUT3 
 
SCRLUP:: 
	CALL	INSRED 
	CALL	RLDN 
	JMP	OUT3 
 
SCRLDN:: 
	CALL	INSRED 
	CALL	RLUP 
	JMP	OUT3 
 
 
SETC:	PUSH	PSW 
	CALL	GETC 
	STA	CURX 
	CALL	CURCM 
	POP	PSW 
	RET 
 
 
M03:	CALL	SETINF 
	CALL	SETRST 
 
RED::	CALL	DISCUR 
	CALL	GETCHC 
 
	MOV	A,B 
	ANI	40H ; Ctrl flag 
	JNZ	ANDR 
 
	MOV	A,C ; All control symbols are less than 20h except for Backspace - 7Fh 
	CPI	7fH 
	jz	ANDR 
	 
	CPI	20H 
	JNC	PRCHR 
 
ANDR:	MOV	C,B 
 
	lxi	d,DISALL 
	PUSH	d 
 
	MVI	B,0 
	LXI	H,CMDTBL 
	CALL	FNDCMD 
 
	PUSH	H 
	PUSH	B 
	CALL	SETC 
	POP	B 
	POP	H 
 
        CALL	FNDCMD 
 
	pop	d 
	LXI	d,OUT1 
	PUSH	d 
 
	CALL	FNDCMD 
	PUSH	H 
	PUSH	B 
	CALL	INSRED 
	POP	B 
	POP	H 
	CALL	FNDCMD 
	PUSH	H 
	LHLD	BLEND 
	XCHG 
	LHLD	BLBEG 
	CALL	CDEHL 
	POP	H 
	CC	FNDCMD 
	RET 
 
DELCOR:	XCHG 
	CALL	COR 
	RC 
	DCX	H 
	RET 
 
 
LDEL::	LDA	CURX 
	DCR	A 
	RZ 
	STA	CURX 
	CALL	SETC 
 
RDEL::	CALL	FILSP 
	CALL	CAD 
	MOV	A,M 
	CPI	0DH 
	RZ 
	DCX	H 
	MOV	A,M 
	XCHG 
	PUSH	D 
	INX	D 
	MOV	B,D 
	MOV	C,E 
	POP	D 
	LXI	H,STRRED+MAXLEN-1 
	CALL	D0 
	LXI	H,DELCOR 
	CALL	CORRECT 
	LDA	NEWMES 
	DCR	A 
	STA	NEWMES 
	RET 
 
REPMOD:: 
	LDA	MODE 
	CPI	93H 
	JZ	INSERT 
	JMP	OVRW 
 
 
BSC::	CALL	INSRED 
	CALL	BSCR 
	JMP	OUT3 
 
TAB::	CALL	PRCH0 
;	CALL	wprawo 
	LDA	CURX 
	dcr	a 
	call	CalcNextTabPos 
	STA	CURX 
	RET 
 
REST::	LHLD	OLDBLB 
	SHLD	BLBEG 
	LHLD	OLDBLE 
	SHLD	BLEND 
	JMP	OUT1 
 
 
CR::	CALL	INSRED 
	LHLD	SCRADR 
	XCHG 
	MVI	A,1 
	STA	CURX 
	CALL	DISPLY 
CR0:	CALL	wniz 
	CPI	0FFH 
	JNZ	OUT1 
	MVI	M,0DH 
	INX	H 
	MVI	M,0FFH 
	SHLD	werhgr 
	LHLD	NUMSTR 
	INX	H 
	SHLD	NUMSTR 
	JMP	CR0 
 
PRCH0:	STA	SYM 
	LXI	H,STRRED 
	CALL	FILSP 
	CALL	CAD 
	LDA	MODE 
	CPI	93H 
	JZ	PRC00 
	LDA	NEWMES 
	CPI	MAXLEN+1 
	RNC 
	CALL	INSSYM 
PRC00:	CALL	?OUT 
	CZ	INSSYM 
	push	h 
	CALL	wprawo 
	pop	h 
	LDA	SYM 
	MOV	M,A 
	RET 
 
INSCTRL:: 
	POP	B 
	CALL	GETCHR 
 
PRCHR:	CALL	PRCH0 
;	CALL	SETC 
;	CALL	wprawo 
DISALL:	CALL	SETC 
	LXI	D,STRRED 
	LHLD	VDADR 
	lda	DISPOS 
	CALL	DISSTR 
	CALL	DISCUR 
	LDA	SCRBG0+1 
	ORA	A 
	JZ	RED 
	LHLD	SCRAD0 
	XCHG 
	LHLD	SCRBG0 
	LDA	YSIZE0 
	MOV	B,A 
DIS00:	LDA	STRADR 
	CMP	E 
	JNZ	DIS01 
	LDA	STRADR+1 
	CMP	D 
	JNZ	DIS01 
	LXI	D,STRRED 
	LDA	DISPOS 
	PUSH	PSW 
	LDA	DISPS0 
	STA	DISPOS 
	CALL	DISSTR 
	POP	PSW 
	STA	DISPOS 
	JMP	RED 
DIS01:	XCHG 
	CALL	NEXTST 
	XCHG 
	PUSH	B 
	LXI	B,ScrWidth 
	DAD	B 
	POP	B 
	DCR	B 
	JNZ	DIS00 
	JMP	RED 
 
?OUT:	CALL	GETC 
	MOV	B,A 
	LDA	NEWMES 
	SUB	B 
	RET 
 
FILSP:	CALL	?OUT 
	RNC 
	CMA 
	ADI	2 
	PUSH	PSW 
	CALL	CAD 
	POP	PSW 
	INX	H 
	MVI	M,0DH 
RED2:	DCX	H 
	MVI	M,20H 
	DCR	A 
	JNZ	RED2 
	CALL	GETC 
	INR	A 
	STA	NEWMES 
	RET 
 
INSSYM:	PUSH	H 
	CALL	CAD 
	INX	H 
	XCHG 
	LXI	H,STRRED+MAXLEN+1 
	LXI	B,STRRED+MAXLEN 
	CALL	U1 
	LDA	NEWMES 
	INR	A 
	CPI	MAXLEN+2 
	JNC	$+6 
	STA	NEWMES 
	MVI	A,0DH 
	STA	STRRED+MAXLEN 
	LXI	H,INSCOR 
	CALL	CORRECT 
	POP	H 
	RET 
 
CORRECT:	PUSH	H 
	XCHG 
	LHLD	BLBEG 
	XCHG 
	CALL	CORR 
	LDA	BEGCOR 
	ORA	A 
	JZ	$+6 
	SHLD	BLBEG 
	POP	H 
	XCHG 
	PUSH	D 
	LHLD	BLEND 
	XCHG 
	CALL	CORR 
	LDA	ENDCOR 
	ORA	A 
	JZ	$+6 
	SHLD	BLEND 
	POP	D 
 	RET 
 
CORR:	PCHL 
 
COR:	PUSH	H 
	CALL	CHKPNT 
	POP	H 
	RC 
	XCHG 
	CALL	CADR1 
	XCHG 
	JMP	CDEHL 
 
INSCOR:	XCHG 
	CALL	COR 
	RC 
	INX	H 
	RET 
 
CHKPNT:	XCHG 
	LHLD	STRADR 
	DCX	H 
	CALL	CDEHL 
	CMC 
	RC 
	LDA	NEWMES 
	DCR	A 
	CALL	CADR11 
	JMP	CDEHL 
 
CAD:	CALL	GETC 
	DCR	A 
CAD1:	MVI	B,0 
	MOV	C,A 
	LXI	H,STRRED 
	DAD	B 
	RET 
 
CADR1:	CALL	GETC 
	DCR	A 
CADR11:	MVI	B,0 
	MOV	C,A 
	LHLD	STRADR 
	DAD	B 
	RET 
 
 
SWPWIN:: 
	CALL	SWPWN 
	LHLD	STRADR 
	JMP	DISADR 
 
SWPWN:	LDA	SCRBG0+1 
	ORA	A 
	RZ 
	CALL	SETST0 
	LXI	H,SCRADR 
	LXI	D,SCRAD0 
	MVI	C,14 
SWPW0:	MOV	B,M 
	LDAX	D 
	MOV	M,A 
	MOV	A,B 
	STAX	D 
	INX	H 
	INX	D 
	DCR	C 
	JNZ	SWPW0 
	LDA	?WIN1 
	CMA 
	STA	?WIN1 
	MVI	A,1 
	ORA	A 
	RET 
 
YMAX	EQU	LogicHeight-3 
YMIN	EQU	2 
 
WINUP::	LDA	SCRBG0+1 
	ORA	A 
	JNZ	WINU0 
	MVI	A,YMAX 
	STA	YSIZE 
	INR	A 
	STA	YBEG0 
	MVI	A,YMIN 
	STA	YSIZE0 
	LHLD	INFADR 
	SHLD	INFAD0 
	LXI	B,-3*ScrWidth 
	DAD	B 
	SHLD	SCRBG0 
	SHLD	INFADR 
	JMP	WIN01 
WINU0:	LDA	?WIN1 
	ORA	A 
	JNZ	WINU1 
	CALL	SWPWN 
	CALL	WINU1 
	JMP	SWPWN 
WINU1:	LDA	YSIZE 
	CPI	YMIN 
	JZ	CLRW1 
	DCR	A 
	STA	YSIZE 
	LXI	H,YSIZE0 
	INR	M 
	LXI	H,YBEG0 
	DCR	M 
	LHLD	INFADR 
	LXI	B,-ScrWidth 
	DAD	B 
	SHLD	SCRBG0 
	SHLD	INFADR 
WIN01:	LDA	YSIZE 
	MOV	B,A 
	LDA	CURY 
	CMP	B 
	RC 
	CALL	wwerh 
	CALL	RLUP 
	JMP	WIN01 
 
CLRW1:	LXI	H,0 
	SHLD	SCRBEG 
	CALL	SWPWIN 
	MVI	A,0FFH 
	STA	?WIN1 
	JMP	INIT 
 
WINDN::	LDA	SCRBG0+1 
	ORA	A 
	JNZ	WIND0 
	XRA	A 
	STA	YBEG0 
	STA	?WIN1 
	MVI	A,YMAX 
	STA	YSIZE 
	LHLD	VRAM_ADR 
	SHLD	SCRBG0 
	MVI	A,YMIN 
	STA	YSIZE0 
	INR	A 
	STA	YBEG 
	LHLD	VRAM_ADR 
	LXI	D, 3*ScrWidth 
	DAD	D 
	SHLD	INFAD0 
	SHLD	SCRBEG 
	CALL	GETINFADR 
	SHLD	INFADR 
	JMP	WIND01 
WIND0:	LDA	?WIN1 
	ORA	A 
	JZ	WIND1 
	CALL	SWPWN 
	CALL	WIND1 
	JMP	SWPWN 
WIND1:	LDA	YSIZE 
	CPI	YMIN 
	JZ	CLRWD1 
	DCR	A 
	STA	YSIZE 
	LXI	H,YSIZE0 
	INR	M 
	LXI	H,YBEG 
	INR	M 
	LHLD	INFAD0 
	LXI	B,ScrWidth 
	DAD	B 
	SHLD	SCRBEG 
	SHLD	INFAD0 
WIND01:	LDA	YSIZE 
	MOV	B,A 
	LDA	CURY 
	CMP	B 
	RC 
	CALL	wwerh 
	CALL	RLUP 
	JMP	WIND01 
 
CLRWD1:	LXI	H,0 
	SHLD	SCRBEG 
	CALL	SWPWIN 
	MVI	A,0FFH 
	STA	?WIN1 
	JMP	INIT 
 
 
BSCR:	LHLD	SCRADR 
	SHLD	STRADR 
	LHLD	CURX 
	MOV	A,H 
	ORA	L 
	DCR	A 
	JNZ	CB1 
CB00:	LXI	H,0101H 
	SHLD	CURX 
	LDA	YSIZE 
	SUI	2 
	JZ	CURSM 
	MOV	B,A 
CB0:	LHLD	STRADR 
	CALL	NEXTST 
	JZ	CURSM 
	SHLD	STRADR 
	CALL	INRCUR 
	LXI	H,CURY 
	INR	M 
	DCR	B 
	JNZ	CB0 
	JMP	CURSM 
 
CB1:	LDA	CURY 
	LXI	H,101H 
	SHLD	CURX 
	LHLD	CURSTR 
	MOV	C,A 
	DCR	C 
	MOV	A,L 
	SUB	C 
	MOV	M,A 
	JNC	$+4 
	DCX	H 
	SHLD	CURSTR 
	JMP	CURSM 
 
 
 
NEW::	CALL	CLRSTR 
	CALL	INFPR 
	DW	33 
	DC	'NEW Y/N:' 

	LHLD	CURX 
	PUSH	H 
	LXI	H,ScrHeight*256+2AH 
	SHLD	CURX 
	CALL	CURM 
	CALL	GETCHR 
	CPI	59H 
	JNZ	NEW1 
	LHLD	nivgr 
	MVI	M,0DH 
	INX	H 
	MVI	M,0FFH 
	SHLD	werhgr 
	JMP	START 
NEW1:	POP	H 
	SHLD	CURX 
	JMP	CURSM 
 
kraj		EQU	16 
 
MaxStrLen	equ	15 
@extend_key	equ	0 
@backsp_key	equ	1 
@exit_key	equ	3 
 
Input_And_Show: 
	mvi	a,1 
	stax	b 
	xchg 
	SetScrAddr 
@put_str: 
	ldax	d 
	ora	a 
	jz	move_curs 
	WriteNextSym 
		mov	m,a 
		inx	h 
	inx	d 
	ldax	b 
	inr	a 
	stax	b 
	lda	CURX 
	inr	a 
	sta	CURX 
	jmp	@put_str 
 
INPSTR: 
	MVI	M,0 
	xchg 
Edit_Line: 
	MVI	A,1 
	STAX	B 
	MVI	A,kraj 
	STA	CURX 
	MVI	A,ScrHeight 
	STA	CURY 
	LHLD	INFADR 
	PUSH	D 
	LXI	D,kraj-1 
	DAD	D 
	POP	D 
move_curs: 
	call	CURM 
Get_key: 
	CALL	GETCHR 
	CPI	@extend_key 
	JNZ	No_extend 
	CALL	GETCHR 
	JMP	Ins_sym 
 
No_extend: 
	CPI	0DH 
	jz	exit_inp_str 
	CPI	@exit_key 
	JZ	IN4 
	CPI	@backsp_key 
	JNZ	Ins_Sym 
 
	LDAX	B 
	DCR	A 
	JZ	Get_Key 
	STAX	B 
	dcx	h 
	SetScrAddr 
	xra	a 
	WriteNextSym 
		mov	m,a 
		inx	h 
	dcx	h 
	SetScrAddr 
	dcx	d 
	LDA	CURX 
	DCR	A 
	STA	CURX 
	jmp	move_curs 
 
Ins_Sym: 
	stax	d 
	ldax	b 
	CPI	MaxStrLen 
	JZ	Get_Key 
	inr	a 
	stax	b 
	LDA	CURX 
	INR	A 
	STA	CURX 
	ldax	d 
	WriteNextSym 
		mov	m,a 
		inx	h 
	inx	d 
	jmp	move_curs 
 
exit_inp_str: 
	xra	a 
	stax	d 
	ret 
 
IN4:	LHLD	STRADR 
	CALL	DISADR 
	JMP	OUT1 
 
 
 
LINE:	push	b 
	;LHLD	INFADR 
	CALL	GETINFADR 
	LXI	B,-ScrWidth 
	DAD	B 
	SetScrAddr 
	MVI	c,LogicWidth 
CLR1:	mvi	a,LineSym 
	WriteNextSym 
		mov	m,a 
		inx	h 
	dcr	c 
	JNZ	CLR1 
	pop	b 
	RET 
 
CLRSTR:	PUSH	H 
	PUSH	PSW 
	push	b 
	CALL	LINE 
	LHLD	VRAM_ADR 
	LXI	B,INFSTR_OFFS-ScrWidth 
	DAD	B 
	SetScrAddr 
	mvi	c,LogicWidth 
CLR0:	mvi	a,space 
	writeNextSym 
		mov	m,a 
		inx	h 
	dcr	c 
	JNZ	CLR0 
 
	CALL	INFPR 
	DW	30 
	DB	DelimSym+80h 
 
	CALL	INFPR 
	DW	7 
	DB	DelimSym+80h 
	pop	b 
	POP	PSW 
	POP	H 
	RET 
 
INPSR:	CALL	CLRSTR 
	CALL	INFPR 
	DW	8 
	DC	'TARGET:' 

	LXI	H,STRSR 
	LXI	B,SRMES 
	JMP	INPSTR 
 
 
CONT_SRREP: 
	LDA	RPMES 
	ORA	A 
	JZ	CONT_SRH 
	JMP	RPREP0 
 
RPREP0:	CALL	MARK 
	JMP	RPREP1 
 
REPREP:	PUSH	H 
	CALL	GETINFADR 
	LXI	B,3 
	DAD	B 
	MVI	A,11 
	MVI	M,0 
	DCR	A 
	INX	H 
	JNZ	$-4 
	POP	H 
RPREP1:	LDA	RPMES 
	DCR	A 
	MOV	C,A 
	MVI	B,0 
	DAD	B 
	JMP	REP0 
 
REPLACE:: 
	LHLD	CURX 
	PUSH	H 
	CALL	INPSR 
	CALL	CLRSTR 
	CALL	INFPR 
	DW	7 
	DC	'REPLACE:' 

	LXI	H,STRREP 
	LXI	B,RPMES 
	CALL	INPSTR 
	CALL	CLRSTR 
	CALL	INFPR 
	DW	33 
	DC	'[G]LOBAL OR [S]TEP:' 




	LXI	H,ScrHeight*256+35H 
	SHLD	CURX 
	CALL	CURM 
REP2:	CALL	GETCHR 
	ANI	5FH 
	STA	RMODE 
	CPI	'S' 
	JZ	REP3 
	CPI	'G' 
	JNZ	REP2 
REP3:	CALL	CLRSTR 
	POP	H 
	SHLD	CURX 
	LHLD	STRADR 
REP0:	LDA	SRMES 
	DCR	A 
	JZ	IN4 
	STA	OLDMES 
	LDA	RPMES 
	DCR	A 
	JZ	IN4 
	CALL	SearchStr 
	PUSH	H 
	XCHG 
	CALL	DISAD1 
	CALL	DISPLY 
	POP	H 
	LDA	RMODE 
	CPI	'S' 
	JNZ	REP4 
	PUSH	H 
	CALL	CLRSTR 
	CALL	INFPR 
	DW	33 
	DC	'REPLACE Y/N' 


	POP	H 
REP1:	CALL	GETCHR 
	ANI	5FH 
	CPI	3 
	RZ 
	CPI	'N' 
	JZ	REPREP 
	CPI	'Y' 
	JNZ	REP1 
REP4:	PUSH	H 
	XCHG 
	LHLD	STRADR 
	PUSH	H 
	XCHG 
	SHLD	STRADR 
	LDA	RPMES 
	DCR	A 
	MOV	B,A 
	STA	NEWMES 
	LXI	H,STRREP 
	XCHG 
	LXI	H,STRRED 
RP0:	LDAX	D 
	MOV	M,A 
	DCR	B 
	INX	H 
	INX	D 
	JNZ	RP0 
	CALL	INSR1 
	POP	H 
	SHLD	STRADR 
	CALL	DISPLY 
	POP	H 
	JMP	REPREP 
 
CONT_SRH:: 
	CALL	MARK 
	INX	H 
	CALL	SearchStr 
	XCHG 
	JMP	DISAD1 
 
SEARCH:: 
	XRA	A 
	STA	RPMES 
	LHLD	CURX 
	PUSH	H 
	CALL	INPSR 
	POP	H 
	SHLD	CURX 
	LHLD	STRADR 
	call	SearchStr 
	XCHG 
	JMP	DISAD1 
 
GetSym	macro 
local	@no_upc 
	ldax	d 
	inx	d 
	cmp	b 
	jc	@no_upc 
	cpi	0ffh 
	jz	NotFound 
	cmp	c 
	jnc	@No_Upc 
	sui	20h 
@No_Upc: 
	endm 
 
SearchStr: 
	lxi	b,'a' SHL 8 + 'z'+1 
	xchg 
	lxi	h,STRSR 
	push	h 
@upcase_lp: 
	mov	a,m 
	cmp	b 
	jc	@noupcase 
	cmp	c 
	jnc	@noupcase 
	sui	20h 
@noupcase: 
	mov	m,a 
	inx	h 
	ora	a 
	jnz	@upcase_lp 
	pop	h 
 
	init_brk_check 
		PUSH	H 
		LHLD	PPI_ADR 
		MVI	M,0FEH 
		POP	H 
@SrhLoop: 
@SrhLp: 
	check_break 
		PUSH	H 
		LHLD	PPI_ADR 
		INR	L 
		MOV	A,M 
		POP	H 
		ANI	40h 
	jz	ABSRH 
	GetSym 
	ldax	d 
	inx	d 
	cmp	b 
	jc	..0000 
	cpi	0ffh 
	jz	NotFound 
	cmp	c 
	jnc	..0000 
	sui	20h 
..0000: 
        cmp	m 
	jnz	@SrhLp 
	inx	h 
	push	d 
@Cont:	GetSym 
	ldax	d 
	inx	d 
	cmp	b 
	jc	..0001 
	cpi	0ffh 
	jz	NotFound 
	cmp	c 
	jnc	..0001 
	sui	20h 
..0001: 
	cmp	m 
	inx	h 
	jz	@Cont 
	pop	d 
	dcx	h 
	xra	a 
	cmp	m 
	lxi	h,STRSR 
	jnz	@SrhLoop 
	dcx	d 
	xchg 
	ret 
 
NotFound: 
	CALL	CLRSTR 
	CALL	INFPR 
	DW	33 
	DC	'NOT FOUND' 


	CALL	GETCHR 
	CALL	CURM 
	JMP	OUT1 
 
ABSRH:	CALL	GETCHR 
	CALL	CLRSTR 
	CALL	INFPR 
	DW	33 
	DC	'SEARCH/REPLACE ABORTED' 





	CALL	GETCHR 
	CALL	CURM 
	JMP	OUT1 
 
 
LEND::	MVI	A,1 
	STA	CURX 
	RET 
 
REND::	LDA	NEWMES 
	CPI	MAXLEN+1 
	JC	$+4 
	DCR	A 
	STA	CURX 
	JMP	CURCM 
 
BRKSTR:: 
	LHLD	NUMSTR 
	INX	H 
	SHLD	NUMSTR 
	CALL	INSSYM 
	CALL	CAD 
	MVI	M,0DH 
	JMP	CR 
 
INSSPC:: 
	CALL	INSSYM 
	CALL	CAD 
	MVI	M,20H 
	RET 
 
DELLT::	CALL	FILSP 
	LXI	H,LDCOR 
	CALL	CORRECT 
	CALL	GETC 
	MOV	C,A 
	LDA	NEWMES 
	SUB	C 
	CALL	CAD1 
	PUSH	PSW 
	PUSH	H 
	CALL	CAD 
	MOV	B,H 
	MOV	C,L 
	POP	H 
	POP	PSW 
	INR	A 
	STA	NEWMES 
	LXI	D,STRRED 
	CALL	D1 
	MVI	A,1 
	STA	CURX 
	RET 
 
LDCOR:	XCHG 
	PUSH	H 
	CALL	CHKPNT 
	POP	H 
	RC 
	XCHG 
	CALL	CADR1 
	CALL	CDEHL 
	XCHG 
	JNC	LDC0 
	XCHG 
	CALL	INV_H 
	DAD	D 
	XCHG 
	LHLD	STRADR 
	DAD	D 
	INX	H 
	RET 
LDC0:	LHLD	STRADR 
	RET 
 
DELRT::	CALL	GETC 
	MOV	B,A 
	LDA	NEWMES 
	CMP	B 
	RC 
	CALL	CAD 
	MVI	M,0DH 
	LXI	H,RDCOR 
	CALL	CORRECT 
	CALL	GETC 
	STA	NEWMES 
	RET 
 
RDCOR:	XCHG 
	PUSH	H 
	CALL	CHKPNT 
	POP	H 
	RC 
	XCHG 
	CALL	CADR1 
	CALL	CDEHL 
	RC 
	XCHG 
	RET 
 
JoinStr:: 
	LHLD	STRADR 
	CALL	NEXTST 
	RZ 
	LHLD	NUMSTR 
	DCX	H 
	SHLD	NUMSTR 
	LDA	NEWMES 
	DCR	A 
	STA	NEWMES 
	JMP	INSR1 
 
BEGBUF:: 
	LXI	H,1 
	SHLD	CURSTR 
	LHLD	nivgr 
	SHLD	SCRADR 
	SHLD	STRADR 
	LXI	H,0101H 
	SHLD	CURX 
	JMP	CURSM 
 
ENDBUF:: 
DREND:	LHLD	NUMSTR 
	INX	H 
	SHLD	CURSTR 
	LHLD	werhgr 
	SHLD	SCRADR 
	SHLD	STRADR 
	LXI	H,101H 
	SHLD	CURX 
	CALL	PAGEUP 
	JMP	CB00 
 
PAGEUP:: 
	LDA	YSIZE 
	DCR	A 
	MOV	B,A 
 
STR2:	LHLD	SCRADR 
	CALL	PREVST 
	SHLD	SCRADR 
	JNZ	$+7 
	LXI	H,CURY 
	DCR	M 
	LHLD	STRADR 
	CALL	PREVST 
	SHLD	STRADR 
	JZ	STR3 
	CALL	DCRCUR 
	DCR	B 
	JNZ	STR2 
	JMP	CURSM 
STR3:	JMP	BEGBUF 
 
PAGEDN:: 
	LDA	YSIZE 
	DCR	A 
	MOV	B,A 
 
DR3:	LHLD	STRADR 
	CALL	NEXTST 
	JZ	DREND 
	SHLD	STRADR 
	LHLD	SCRADR 
	CALL	NEXTST 
	SHLD	SCRADR 
	CALL	INRCUR 
	DCR	B 
	JNZ	DR3 
	RET 
 
	.comment % 
MODSCR:: 
	LHLD	CURX 
	PUSH	H 
	CALL	CLRSTR 
	CALL	INFPR 
	DW	33 
	DC	'NULL (0-9):' 
	LXI	H,ScrHeight*256+2DH 
	SHLD	CURX 
	CALL	CURM 
MODSC0:	CALL	GETCHR 
	CPI	30H 
	JC	MODSC0 
	CPI	3AH 
	JNC	MODSC0 
	PUSH	PSW 
	CALL	CLS 
	POP	PSW 
	SUI	30H-7 
	STA	LPOS 
	SUI	6 
	LHLD	VRAM_ADR 
	PUSH	D 
	LXI	H,0E7B9H-0E7C2H 
	DAD	D 
	POP	D 
	DCR	A 
	DCX	H 
	JNZ	$-2 
	MVI	M,0F1H 
	POP	H 
	SHLD	CURX 
	JMP	SAVMOD 
% 
 
 
DELLIN:: 
	LHLD	STRADR 
	MOV	D,H 
	MOV	E,L 
	CALL	NEXTST 
	RZ 
	PUSH	H 
	LHLD	NUMSTR 
	DCX	H 
	SHLD	NUMSTR 
	PUSH	D 
	LXI	H,DLCOR 
	CALL	CORRECT 
	POP	D 
	POP	H 
	MOV	B,H 
	MOV	C,L 
	JMP	DNSHT 
 
DLCOR:	LHLD	STRADR 
	RET 
 
INSERT:	MVI	A,0B3H 
	STA	MODE 
	MVI	A,CURSOR_BLOCK ; 0EDH 
	JMP	WIDCUR 
 
OVRW:	MVI	A,93H 
	STA	MODE 
	MVI	A,CURSOR_LINE ; 0DDH 
WIDCUR: 
	call	SETSCR 
	JMP	CURSM 
 
SAVMOD:	LDA	MODE 
	CPI	93H 
	PUSH	PSW 
	CNZ	INSERT 
	POP	PSW 
	CZ	OVRW 
	RET 
 
DISBEG:: 
	LHLD	BLBEG 
	JMP	DISADR 
 
DISEND:: 
	LHLD	BLEND 
	JMP	DISADR 
 
MARK:	LXI	H,NEWMES 
	CALL	GETC 
	CMP	M 
	JC	MAR0 
	MOV	A,M 
MAR0:	DCR	A 
	JMP	CADR11 
 
MRBEG::	CALL	MARK 
	SHLD	BLBEG 
	RET 
 
MREND::	CALL	MARK 
	SHLD	BLEND 
	RET 
;------------- Main block commands ----------- 
 
DELBL::	CALL	DBL 
	CALL	COMPST 
	LHLD	BLBEG 
	SHLD	BLEND 
	JMP	DISADR 
DBL:	LHLD	BLBEG 
	XCHG 
	LHLD	BLEND 
	MOV	B,H 
	MOV	C,L 
	JMP	DNSHT 
 
INV_H:	MOV	A,H 
	CMA 
	MOV	H,A 
	MOV	A,L 
	CMA 
	MOV	L,A 
	RET 
 
JBLCU:	LHLD	DSTADR 
	DCX	H 
	CALL	CDEHL 
	RNC 
	LHLD	BLEND 
	DCX	H 
	CALL	CDEHL 
	RC 
	LHLD	BLBEG 
	DCX	H 
	CALL	CDEHL 
	JC	INBLK 
	PUSH	D 
	CALL	BLKSIZ 
	INX	H 
	POP	D 
	DAD	D 
	XCHG 
	RET 
INBLK:	PUSH	D 
	CALL	GLBSIZ 
	XCHG 
	POP	H 
	CALL	CSUB 
	XCHG 
	RET 
 
JBLCD:	LHLD	BLBEG 
	DCX	H 
	CALL	CDEHL 
	RNC 
	LHLD	DSTADR 
	DCX	H 
	CALL	CDEHL 
	RC 
	LHLD	BLEND 
	DCX	H 
	CALL	CDEHL 
	JNC	INBLD 
	PUSH	D 
	CALL	BLKSIZ 
	INX	H 
	POP	D 
	XCHG 
	CALL	CSUB 
	XCHG 
	RET 
 
INBLD:	LHLD	DSTADR 
	DAD	D 
	XCHG 
	LHLD	BLEND 
	XCHG 
	CALL	CSUB 
	XCHG 
	RET 
 
COPYBL:: 
	CALL	CBL 
	CALL	COMPST 
	LHLD	BLBEG 
	JMP	DISADR 
CBL:	CALL	CHBL 
	JNC	CBL1 
	LHLD	BLEND 
	DCX	H 
	CALL	CDEHL 
	JNC	OUT1 
CBL1:	CALL	BLKSIZ 
	XCHG 
	LHLD	DSTADR 
	MOV	B,H 
	MOV	C,L 
	PUSH	H 
	DAD	D 
	PUSH	H 
	INX	H 
	XCHG 
	CALL	UPSHT 
	LHLD	BLBEG 
	MOV	B,H 
	MOV	C,L 
	POP	H 
	INX	H 
	SHLD	BLEND 
	DCX	H 
	XCHG 
	POP	H 
	SHLD	BLBEG 
	XCHG 
	JMP	D1 
 
CHBL:	CALL	MARK 
	SHLD	DSTADR 
	XCHG 
	LHLD	BLBEG 
	DCX	H 
	JMP	CDEHL 
 
JMPBL::	CALL	CHBL 
	JNC	JBLUP 
	LHLD	BLEND 
	CALL	CDEHL 
	JC	JBLDN 
	JMP	OUT1 
JBLUP:	LHLD	SCRAD0 
	XCHG 
	CALL	JBLCU 
	XCHG 
	SHLD	SCRAD0 
	CALL	BLKSIZ 
	XCHG 
	LHLD	DSTADR 
	PUSH	H 
	PUSH	D 
	CALL	JBLU 
JBLEX:	POP	D 
	POP	H 
	SHLD	BLBEG 
	PUSH	H 
	DAD	D 
	INX	H 
	SHLD	BLEND 
	POP	H 
	JMP	DISADR 
 
JBLDN:	LHLD	SCRAD0 
	XCHG 
	CALL	JBLCD 
	XCHG 
	SHLD	SCRAD0 
	CALL	BLKSIZ 
	XCHG 
	LHLD	DSTADR 
	PUSH	H 
	PUSH	D 
	CALL	JBLD 
	POP	D 
	POP	H 
	SHLD	BLEND 
	DCX	H 
	CALL	CSUB 
	SHLD	BLBEG 
	JMP	DISADR 
 
SETST0:	PUSH	H 
	LDA	CURY0 
	LHLD	SCRAD0 
	MOV	B,A 
SST00:	DCR	B 
	JZ	SST01 
	CALL	NEXTST 
	JNZ	SST00 
SST01:	SHLD	STRAD0 
	POP	H 
	RET 
 
 
JBLU:	CALL	BLKSIZ 
	INX	H 
	PUSH	H 
	CALL	GLBSIZ 
	POP	D 
	CALL	?DVNHD 
	LHLD	DSTADR 
	MOV	A,D 
	ORA	E 
	PUSH	PSW	; ? End of relocation 
	DAD	D 
	MOV	B,H 
	MOV	C,L 
	DCX	B 
	LHLD	BLBEG 
	XCHG 
 	DCX	D 
	LHLD	BLEND 
	DCX	H 
	CALL	GREXU	; "Great" Exchange 
	XCHG 
	INX	H 
	SHLD	BLEND 
	LHLD	DSTADR 
 	SHLD	BLBEG 
	XCHG 
	INX	H 
	SHLD	DSTADR 
	POP	PSW	; Z - the end 
	RZ 
JBLD:	CALL	BLKSIZ 
	INX	H 
	PUSH	H 
	LHLD	BLEND 
	DCX	H 
	XCHG 
	LHLD	DSTADR 
	CALL	CSUB 
	DCX	H 
	POP	D 
	CALL	?DVNHD 
	LHLD	DSTADR 
	MOV	A,D 
	ORA	E 
	PUSH	PSW	; ? End of relocation 
	CALL	CSUB 
	MOV	B,H 
	MOV	C,L 
	LHLD	BLEND 
	DCX	H 
	XCHG 
 	INX	D 
	LHLD	BLBEG 
	CALL	GREXD	; "Great" Exchange 
	XCHG 
	SHLD	BLBEG 
	LHLD	DSTADR 
 	SHLD	BLEND 
	XCHG 
	SHLD	DSTADR 
	POP	PSW	; Z - the end 
	JNZ	JBLU 
	RET 
 
BLKSIZ:	LHLD	BLBEG 
	XCHG 
	LHLD	BLEND 
	DCX	H 
	JMP	CSUB 
 
GLBSIZ:	LHLD	DSTADR 
	XCHG 
	LHLD	BLBEG 
	JMP	CSUB 
 
GREXU:	MOV	A,E 
	CMP	C 
	JNZ	GREXU0 
	MOV	A,D 
	CMP	B 
	RZ 
GREXU0:	PUSH	B 
GREXU1:	MOV	C,M 
	LDAX	D 
	MOV	M,A 
	MOV	A,C 
	STAX	D 
	DCX	H 
	DCX	D 
	MOV	A,D 
	CMP	B 
	JNZ	GREXU1 
	POP	B 
	MOV	A,E 
	CMP	C 
        JNZ	GREXU0 
	RET 
 
 
GREXD:	MOV	A,E 
	CMP	C 
	JNZ	GREXD0 
	MOV	A,D 
	CMP	B 
	RZ 
GREXD0:	PUSH	B 
GREXD1:	MOV	C,M 
	LDAX	D 
	MOV	M,A 
	MOV	A,C 
	STAX	D 
	INX	H 
	INX	D 
	MOV	A,D 
	CMP	B 
	JNZ	GREXD1 
	POP	B 
	MOV	A,E 
	CMP	C 
	JNZ	GREXD0 
	RET 
 
DSTADR:	DS	2 
;------------------------------------------ 
 
DISADR:	XCHG 
	LHLD	SCRADR 
	CALL	DA2 
	SHLD	SCRADR 
	XCHG 
	CALL	CDEHL 
	XCHG 
	JC	DISAD1 
	LHLD	SCREND 
	CALL	DA2 
	SHLD	SCREND 
	XCHG 
	CALL	CDEHL 
	XCHG 
	JNC	DISAD1 
DAD1:	CALL	DA1 
	SHLD	STRADR 
	LHLD	SCRADR 
	MVI	B,0 
DAD0:	INR	B 
	MOV	A,B 
	STA	CURY 
	CALL	NEXTST 
	CALL	CDEHL 
	JZ	DAD0 
	JNC	DSAD0 
	JMP	DAD0 
 
DA1:	MOV	H,D 
	MOV	L,E 
DA2:	DCX	H 
	MOV	A,M 
	CPI	0DH 
	JNZ	DI3 
	INX	H 
	RET 
DI3:	INX	H 
	JMP	PREVST 
 
DISAD1:	CALL	DA1 
	SHLD	SCRADR 
	LDA	CURY 
	MOV	C,A 
DS6:	DCR	C 
	JZ	DAD1 
	CALL	PREVST 
	JZ	DAD1 
	SHLD	SCRADR 
	JMP	DS6 
 
DSAD0:	LHLD	STRADR 
	SHLD	TABSRH 
DS5:	MVI	B,1 
DS0:	MOV	A,D 
	CMP	H 
	JNZ	DS1 
	MOV	A,E 
	CMP	L 
	JZ	DISAD0 
DS1:	INX	H 
	INR	B 
	JNZ	DS0 
DISAD0:	MOV	A,B 
	STA	CURX 
	CALL	COMCUR 
	JMP	CURCM 
 
BPR:	MOV	A,E 
	CALL	BPR1 
	MOV	A,D 
	JMP	BPR1 
BPR1:	PUSH	PSW 
	call	BPR01 
	POP	PSW 
	RRC 
	RRC 
	RRC 
	RRC 
BPR01:	ANI	0FH 
	ADI	48 
	CPI	58 
	JC	$+5 
	ADI	7 
	SetScrAddr 
	WriteNextSym 
		mov	m,a 
		inx	h 
	DCX	H 
	DCX	H 
	RET 
 
GETINFADR: 
	PUSH	B 
	LHLD	VRAM_ADR 
	LXI	B,INFSTR_OFFS 
	DAD	B 
	POP	B 
	RET 
 
INFPR:	POP	H 
	MOV	E,M 
	INX	H 
	MOV	D,M 
	INX	H 
 	PUSH	H 
	CALL	GETINFADR 
	DAD	D 
	XCHG 
	POP	H 
	JMP	print0 
 
PRINT:	POP	H 
	MOV	E,M 
	INX	H 
	MOV	D,M 
	INX	H 
 
PRINT0:	xchg 
	SetScrAddr 
@prnt:	ldax	d 
	ORA	A 
	JM	PRINT1 
 
	WriteNextSym 
		mov	m,a 
		inx	h 
	inx	d 
	JMP	@prnt 
 
PRINT1:	ANI	7FH 
	WriteNextSym 
		mov	m,a 
		inx	h 
	xchg 
	inx	h 
	pchl 
 
CALC::	CALL	CLRSTR 
	CALL	INFPR 
	DW	31 
	DC	'= 0000H  0000DEC' 



CALC0:	CALL	INFPR 
	DW	10 
	DC	'EXPR=' 

	LXI	H,FILNAM 
	LXI	B,NAMMES 
	PUSH	H 
	CALL	INPSTR 
	POP	H 
	CALL	COMPUTE 
	PUSH	H 
	XCHG 
	CALL	GETINFADR 
	PUSH	B 
	LXI	B,36 
	DAD	B 
	POP	B 
	CALL	BPR 
	POP	H 
	CALL	?FBBCD 
	XCHG 
	CALL	GETINFADR 
	PUSH	B 
	LXI	B,43 
	DAD	B 
	POP	B 
	CALL	BPR 
	JMP	CALC0 
 
COMPUTE:CALL	GETVL1 
	MOV	A,M 
	INX	H 
	MOV	B,D 
	MOV	C,E 
	PUSH	PSW 
	PUSH	B 
	CALL	GETVL1 
	POP	B 
	MOV	H,B 
	MOV	L,C 
	POP	PSW 
 
	CPI	'+' 
	JZ	CADD 
	CPI	'-' 
	JZ	CSUB 
	CPI	'*' 
	JZ	?MULHD 
	CPI	'/' 
	JZ	?DVNHD 
	JMP	ERR 
 
CADD:	DAD	D 
	RET 
 
ERR:	JMP	IN4 
 
CSUB:	XCHG 
	CALL	?NEGHL 
	DAD	D 
	RET 
 
 
 
GETVL1:	LXI	D,0 
	MOV	A,M 
	CALL	GET4 
	ORA	A 
	RM 
GET2:	MOV	A,M 
	CALL	GET4 
	ORA	A 
	JM	GET1 
	XCHG 
	DAD	H 
	DAD	H 
	DAD	H 
	DAD	H 
	XCHG 
	ORA	E 
	MOV	E,A 
	INX	H 
	JMP	GET2 
GET1:	MOV	A,M 
	CPI	'H' 
	JZ	GET3 
	PUSH	H 
	XCHG 
	CALL	?FBCDB 
	XCHG 
	POP	H 
	RET 
 
GET3:	INX	H 
	RET 
 
GET4:	SUI	'0' 
	RC 
	CPI	0AH 
	RC 
	SUI	7 
	RC 
	CPI	16 
	RC 
GET5:	MVI	A,-7 
	RET 
 
?FBBCD: LXI	D,0 
	MVI	C,16 
?FBBC0:	DAD	H 
	MOV	A,E 
	ADC	A 
	DAA 
	MOV	E,A 
	MOV	A,D 
	ADC	A 
	DAA 
	MOV	D,A 
	DCR	C 
	JNZ	?FBBC0 
	XCHG 
	RET 
?FBCDB:	LXI	D,0 
	XCHG 
	MVI	C,16 
?FBCB0:	XRA	A 
	MOV	A,D 
	RAR 
	CALL	CORR_A 
	MOV	D,A 
	MOV	A,E 
	RAR 
	CALL	CORR_A 
	MOV	E,A 
	MOV	A,H 
	RAR 
	MOV	H,A 
	MOV	A,L 
	RAR 
	MOV	L,A 
	DCR	C 
	JNZ	?FBCB0 
	RET 
 
CORR_A:	PUSH	PSW 
	MOV	B,A 
	ANI	8 
	JZ	NOCR1 
	MOV	A,B 
	SUI	3 
	MOV	B,A 
NOCR1:	MOV	A,B 
	ANI	80H 
	JZ	NOCR2 
	MOV	A,B 
	SUI	30H 
	MOV	B,A 
NOCR2:	POP	PSW 
	MOV	A,B 
	RET 
 
 
; 16-BIT MULTIPLY 
; HL *= DE 
?MULHD:	MOV	B,H 
	MOV	C,L 
	LXI	H,0 
	MVI	A,16 
?01:	DAD	H 
	XCHG 
	DAD	H 
	XCHG 
	JNC	?02 
	DAD	B 
?02:	DCR	A 
	JNZ	?01 
	RET 
 
 
; 16 - BIT UNSIGNED DIVISION 
; HL /= DE 
; DE = HL % DE 
?DVNHD:	MOV	B,D 
	MOV	C,E 
	LXI	D,0 
	MVI	A,16 
?21:	PUSH	PSW 
	DAD	H 
	MOV	A,E 
	RAL 
	MOV	E,A 
	MOV	A,D 
	RAL 
	MOV	D,A 
	JC	?22 
	MOV	A,E 
	SUB	C 
	MOV	A,D 
	SBB	B 
	JC	?23 
?22:	MOV	A,E 
	SUB	C 
	MOV	E,A 
	MOV	A,D 
	SBB	B 
	MOV	D,A 
	INR	L 
?23:	POP	PSW 
	DCR	A 
	JNZ	?21 
	RET 
 
?ABSHL:	MOV	A,H 
	ORA	A 
	RP 
?NEGHL:	DCX	H 
?NOTHL:	MOV	A,L 
	CMA 
	MOV	L,A 
	MOV	A,H 
	CMA 
	MOV	H,A 
	RET 
 
 
EXIT::	call	CLS 
	JMP	0F800h;rst	0 
 
;----- Display one editor string ---------- 
DISSTR::	SetScrAddr 
	MVI	B,0 
	LDA	DISPOS 
	MOV	C,A   
	call	_SkipSyms 
	MVI	C,LogicWidth 
	push	h 
_DispNxtChr: 
	LDAX	D 
	CPI	0FFH 
	JZ	_BlankEos ; Blank to end of screen 
	CPI	13 
	JZ	_BlankEos 
	CPI	9 
	JZ	_DispTab 
ifdef	LimitedCharSet 
	;ORA	A 
	;JP	$+5 
	;MVI	A,0D6H 
endif 
	WriteNextSym 
		mov	m,a 
		inx	h 
	INX	D 
	INR	B 
	DCR	C 
	JNZ	_DispNxtChr 
 
_Eos:	POP	H 
	lxi	b,ScrWidth 
	dad	b 
_SkipToEol: 
	LDAX	D 
	CPI	13 
	RZ 
	cpi	0ffh 
	RZ 
	INX	D 
	JMP	_SkipToEol 
 
_DispTab: 
	call	CalcTab 
	INX	D 
_DspT:	push	psw 
	mvi	a,space 
	WriteNextSym 
		mov	m,a 
		inx	h 
	pop	psw 
	INR	B 
	DCR	C 
	JZ	_Eos 
	DCR	A 
	JNZ	_DspT 
	JMP	_DispNxtChr 
 
 
_BlankEos: 
	push	psw 
	mvi	a,space 
	WriteNextSym 
		mov	m,a 
		inx	h 
	pop	psw 
	DCR	C 
	JNZ	_BlankEos 
	JMP	_Eos 
 
;	* 
_SkipSyms: 
	INR	B 
	DCR	C 
	rz 
	LDAX	D 
	CPI	0FFH 
	rz 
	CPI	0DH 
	rz 
	CPI	9 
	jnz	_ContSkipping 
	call	CalcTab 
_SkTabLp: 
	DCR	A 
	JZ	_ContSkipping 
	INR	B 
	DCR	C 
	rz 
	jmp	_SkTabLp 
 
_ContSkipping: 
	INX	D 
	JMP	_SkipSyms 
 
CalcTab:MOV	A,B 
	DCR	A 
	ANI	TabStep-1 
	SUI	TabStep+1 
	CMA 
	ret 
 
;--------------- DISSTR ---------- 
PUBLIC BLBEG,BLEND,CDEHL,CLRSTR,CURX,DISADR,FILNAM,INFPR,INPSTR,MARK,MAXRAM 
PUBLIC NAMMES,nivgr,werhgr,OUT1,PRINT 
 
 
nivgr	EQU	WRK 
werhgr	EQU	WRK+2 
VDADR	EQU	WRK+4 
SCREND	EQU	WRK+6 
NUMSTR	EQU	WRK+8 
CURSTR	EQU	WRK+10 
BLBEG	EQU	WRK+12 
BLEND	EQU	WRK+14 
OLDBLB	EQU	WRK+16 
OLDBLE	EQU	WRK+18 
BEGCOR	EQU	WRK+20 
ENDCOR	EQU	WRK+21 
SRMES	EQU	WRK+22 
RPMES	EQU	WRK+23 
NAMMES	EQU	WRK+24 
OLDMES	EQU	WRK+25 
NEWMES	EQU	WRK+26 
MODE	EQU	WRK+27 
RMODE	EQU	WRK+28	; 1 
 
SCRADR	EQU	WRK+32 
STRADR	EQU	WRK+34 
SCRBEG	EQU	WRK+36 
INFADR	EQU	WRK+38 
YSIZE	EQU	WRK+40 
YBEG	EQU	WRK+41 
CURX	EQU	WRK+42 
CURY	EQU	WRK+43 
DISPOS	EQU	WRK+44 
?END	EQU	WRK+45 
 
SCRAD0	EQU	WRK+46 
STRAD0	EQU	WRK+48 
SCRBG0	EQU	WRK+50 
INFAD0	EQU	WRK+52 
YSIZE0	EQU	WRK+54 
YBEG0	EQU	WRK+55 
CURX0	EQU	WRK+56 
CURY0	EQU	WRK+57 
DISPS0	EQU	WRK+58 
?StringBufActive	EQU	WRK+59 
 
?WIN1	EQU	WRK+60 
;PRSP	EQU	WRK+59 
TABSRH	EQU	WRK+61 
;?END	EQU	WRK+63 
SYM	EQU	WRK+66	; 1 
STRSR	EQU	WRK+97 
STRREP	EQU	WRK+111 
FILNAM	EQU	WRK+125 
STRRED	EQU	WRK+125 
PRSP:	DS	2 
IFNDEF	noend 
	END 
ENDIF 
 
 
include	E0DISP.ASM 
;----- Display one editor string ---------- 
 
;include E0DISP.MAC 
;include RK86.MAC 
IFNDEF	CURSM 
extrn CURSM 
EXTRN	DISP_ADR, DMA_ADR, VRAM_ADR 
ENDIF 
 
SETSCR:: 
	;RET 
 
	;LXI	H,DISP+1 
	LHLD	DISP_ADR 
	INX	H 
	MVI	M,0 
	DCX	H 
 
IFDEF	Palmira 
	MVI	M,4DH;ScrWidth-1 
	MVI	M,5DH;(ScrHeight+5-1) 
	MVI	M,0EFH 
ELSE 
	MVI	M,ScrWidth-1 
	MVI	M,(ScrHeight+5-1) 
 	MVI	M,99H 
ENDIF 
	mov	m,a 
	INX	H 
	MVI	M,27H 
	MOV	A,M 
	MOV	A,M 
	ANI	20H 
	JZ	$-3 
 
	;LXI	H,DMA+8 
	LHLD	DMA_ADR 
	PUSH	B 
	LXI	B,8 
	DAD	B 
	POP	B 
	MVI	M,80H 
	PUSH	H ; DMA+8 
	;MVI	L,Low(DMA+4) 
	DCR	L 
	DCR	L 
	DCR	L 
	DCR	L 
	PUSH	B 
	XCHG 
	LHLD	VRAM_ADR 
	LXI	B,-ScrOffset 
	DAD	B 
	XCHG 
	MOV	M,E 
	MOV	M,D 
	POP	D 
	INX	H 
	MVI	M,Low(ScrSize-1) 
	MVI	M,High(ScrSize-1) or 40h 
	;MVI	L,Low(DMA+8) 
	POP	H ; DMA+8 
	MVI	M,0A4H 
	RET 
	 
SetCursor:: 
	MVI	A,80H 
	;STA	DISP+1 
	XCHG 
	LHLD	DISP_ADR 
	INX	H 
	MOV	M,A 
	DCX	H 
	MOV     A,E 
	PUSH	H 
	LXI	H,LPOS 
	ADD	M 
	INX	H 
	ADD	M 
	POP	H 
	DCR	A 
	ADI	ScrXOffset 
	;STA	DISP 
	MOV	M,A 
	MOV	A,D 
	ADI	2 
	;STA	DISP 
	MOV	M,A 
	RET 
 
LPOS:	DB	0 
;RK_END 
@RK_END:: 
	DW	0 
IFNDEF	noend 
	END 
ENDIF 
include	E0FILEIO.ASM 
;******************************************************** 
;*  SC80 text screen editor       File I/O module  Tape * 
;*                        (c) TCHV,1989-93              * 
;******************************************************** 
 
IFNDEF	nivgr 
EXTRN	nivgr,werhgr,START,CURX,BLBEG,BLEND 
EXTRN	JMPBL,OUT1, MARK,DISADR 
ENDIF 
 
RDFIL::	LXI	H,0 
	CALL	0F824H 
	XCHG 
	SHLD	werhgr 
	JMP	START 
 
 
RDBL::	LHLD	werhgr 
	INX	H 
	LXI	D,-2000H 
	DAD	D 
	CALL	0F824H ; Read block from tape 
	XCHG 
	SHLD	BLEND 
	DCX	H 
	SHLD    werhgr 
	POP	H 
	SHLD	CURX 
	CALL	JMPBL 
	JMP	OUT1 
 
WRFIL:: 
	CALL	MARK 
	PUSH	H 
	LHLD	nivgr 
	XCHG 
	LHLD	werhgr 
	XCHG 
	CALL	WRSEG 
	POP	H 
	JMP	DISADR 
 
WRBL::	CALL	MARK 
	PUSH	H 
	LHLD	BLBEG 
	XCHG 
	LHLD	BLEND 
	DCX	H 
	XCHG 
	CALL	WRSEG 
	POP	H 
	JMP	DISADR 
 
 
WRSEG: 
	CALL	0F82AH ; Checksum calc 
	JMP	0F827H ; Write block to tape 
IFNDEF	noend 
	END 
ENDIF 
include	E0GETC.ASM 
; 
;	E0GETC.ASM -	ED SC80  get symbol module (OS dependent) 
;			RK version (hardware dependent) 
;			Uses external PPI_ADR 
 
?Ctrl	equ	40h 
?Shift	equ	20h 
 
IFNDEF	PPI_ADR 
EXTRN	PPI_ADR 
ENDIF 
 
; Return SYMBOL and SHIFT/CNTRL flags 
; 	40h - CNTRL  &  80h - SHIFT 
;	B - SYMBOL or MASK 
;	C - SYMBOL 
GETCHC:: 
	CALL	GETCHR 
	PUSH	H 
	push	psw 
	ANI	3FH 
	MOV	C,A 
	LDA	@CTRL 
	;LDA	PPI+2 
	LHLD	PPI_ADR 
	INX	H 
	INX	H 
	ANA	M 
	PUSH	H ; PPI+2 
	MOV	A,C 
	JNZ	$+5 
	ORI	40H 
	MOV	C,A 
 
	LDA	@SHFT 
	POP	H 
	ANA	M 
	MOV	A,C 
	JNZ	$+5 
	ORI	80H 
	mov	b,a 
	pop	psw 
	mov	c,a 
	POP	H 
	RET 
 
; Get character from concole (returns in Acc) 
GETCHR:: 
	PUSH	H 
	PUSH	D 
	PUSH	B 
	CALL	GTC 
	;CALL	0F803h 
	POP	B 
	POP	D 
	POP	H 
	RET 
 
GTC:	LHLD	PNT 
	MOV	A,M 
	CPI	0FFH 
	JZ	GTCH0 
 	INX	H 
	SHLD	PNT 
	JMP	??RUS 
 
GTCH0:	MVI	B,50 
RP3:	PUSH	B 
	CALL	GTVECT 
	POP	B 
	LDA	NREP 
	CPI	1 
	JNZ	RP1 
	XRA	A 
	STA	NREP 
	DCR	B 
	JNZ	RP3 
	INR	A 
	STA	NREP 
	LXI	H,ET1 
	SHLD	PNT 
	JMP	GTC 
RP1:	LDA	NREP 
	ORA	A 
	JNZ	RP01 
	LXI	H,ET1 
RP02:	INX	H 
	MOV	A,M 
	CPI	0FFH 
	JNZ	RP02 
	SHLD	PNT 
	PUSH	H 
	CALL	MDEL 
	POP	H 
	DCX	H 
	MOV	A,M 
	JMP	??RUS 
 
RP01:	CALL	MDEL 
	LXI	H,ET1 
	MOV	A,M 
	INX	H 
	SHLD	PNT 
??RUS:	CPI	0FEH 
	RNZ 
	;LDA	PPI+2 
	PUSH	H 
	LHLD	PPI_ADR 
	INX	H 
	INX	H 
	MOV	A,M 
	XRI	8 
	;STA	PPI+2 
	MOV	M,A 
	POP	H 
	JMP	GTC 
 
MDEL:	EI 
	LXI	H,1000 
RP2:	DCX	H 
	MOV	A,H 
	ORA	L 
	JNZ	RP2 
	DI 
 	RET 
 
; (ET1) - Pressed keys vector (in order of press) 
; (NREP) - Repeat number 
GTVECT:	MVI	B,5 
GETC0:	PUSH	B 
	LDA	@RD 
	ORA	A 
	MVI	A,0 
	STA	@RD 
	JNZ	$+6 
	CALL	KBDSCN 
	POP	B 
	LXI	H,PRESS 
	MOV	A,M 
	CPI	0FFH 
	JNZ	GTV04 
	DCR	B 
	JNZ	GETC0 
	STA	ET1 
	JMP	GTVECT 
 
GTV04: 	LXI	H,ET2 
	LXI	D,ET1 
	PUSH	H 
	PUSH	D 
GTV08:	LDAX	D 
	MOV	M,A 
	INX	H 
	INX	D 
	CPI	0FFH 
	JNZ	GTV08 
	POP	D 
	POP	H 
 
GTV00:	MOV	A,M 
	CPI	0FFH 
	JZ	GTV06 
 
	LXI	B,PRESS 
GTV07:	LDAX	B 
	CPI	0FFH 
	JZ	GTV01 
	CMP	M 
	INX	B 
	JNZ	GTV07 
	MVI	M,0FDH 
	STAX	D 
	INX	D 
	DCX	B 
	MVI	A,0FDH 
	STAX	B 
	INX	B 
GTV01:	INX	H 
	JMP	GTV00 
 
GTV06:	LXI	B,PRESS 
	DCX	B 
GTV10:	INX	B 
	LDAX	B 
	CPI	0FDH 
	JZ	GTV10 
	CPI	0FFH 
	JZ	REP 
	DCX	B 
GTV11:	INX	B 
	LDAX	B 
	CPI	0FDH 
	JZ	GTV11 
	CPI	0FFH 
	JZ	GTV22 
	STAX	D 
	INX	D 
	JMP	GTV11 
GTV22:	XRA	A 
	STA	NREP 
GTV21:	MVI	A,0FFH 
	STAX	D 
	RET 
 
REP:	LDA	NREP 
	ORA	A 
	JZ	GTV31 
	LXI	H,ET2 
GTV30:	MOV	A,M 
	INX	H 
	CPI	0FFH 
	JZ	GTV31 
	CPI	0FDH 
	JZ	GTV30 
	XRA	A 
	STA	NREP 
	JMP	GTV21 
 
GTV31:	LDA	NREP 
	INR	A 
	JZ	GTV21 
	STA	NREP 
	JMP	GTV21 
 
; (PRESS) -  Pressed keys vector (in order of discover) 
KBDSCN:	LXI	B,40H 
	LXI	H,PRESS 
	LXI	D,807FH 
 
	PUSH	B 
	;LDA	PPI+2 
	;MOV	B,A 
	PUSH	H 
	LHLD	PPI_ADR 
	INX	H 
	INX	H 
	MOV	B,M 
	POP	H 
	LDA	@RUS 
	ANA	B 
	JNZ	$+6 
	MVI	M,0FEH 
	INX	H 
	POP	B 
 
NORM0:	CALL	?PRESS 
	CZ	FOUND 
	INR	B 
	DCR	C 
	JNZ	NORM0 
	MVI	M,0FFH 
	RET 
 
?PRESS:	CALL	GETMSK 
	PUSH	H 
	LHLD	PPI_ADR 
	MOV	M,E 
	;STA	PPI 
	;LDA	PPI+1 
	NOP 
	NOP 
	NOP 
	INX	H 
	MOV	A,M 
	POP	H 
	ANA	D 
	RNZ 
 
	PUSH	H 
	LXI	H,200 
?PRES0:	;LDA	PPI+1 
	PUSH	H 
	LHLD	PPI_ADR 
	INX	H 
	MOV	A,M 
	POP	H 
	ANA	D 
	JNZ	?PRES1 
	DCX	H 
	MOV	A,H 
	ORA	L 
	JNZ	?PRES0 
?PRES1:	POP	H 
	RET 
 
 
GETMSK:	MOV	A,D 
	RLC 
	MOV	D,A 
	RNC 
	MOV	A,E 
	RLC 
	MOV	E,A 
	RET 
 
FOUND:	PUSH	H 
	PUSH	D 
	PUSH	B 
	MOV	E,B 
	MVI	D,0 
	LXI	H,KEYBRD 
	DAD	D 
	MOV	A,M 
	MOV	E,A 
 
	CPI	21H 
	CNC	MODCHR 
	MOV	A,E 
	POP	B 
	POP	D 
	POP	H 
	MOV	M,A 
	INX	H 
	RET 
 
MODCHR:	MOV	E,A 
	CPI	40H 
	JNC	MOD4 
	CPI	3CH 
	JNC	MOD3 
MOD4:	;LDA	PPI+2 
	PUSH	H 
	LHLD	PPI_ADR 
	INX	H 
	INX	H 
	MOV	B,M 
	POP	H 
	;MOV	B,A 
	LDA	@CTRL 
	ANA	B 
	JZ	SCTRL 
	;LDA	PPI+2 
	PUSH	H 
	LHLD	PPI_ADR 
	INX	H 
	INX	H 
	MOV	A,M 
	POP	H 
	ANI	8 
	JNZ	SHIFT0 
	;LDA	PPI+2 
	;MOV	B,A 
	PUSH	H 
	LHLD	PPI_ADR 
	INX	H 
	INX	H 
	MOV	B,M 
	POP	H 
 
	LDA	@SHFT 
	ANA	B 
	JZ	@SHIFT 
	RET 
 
MOD3:	;LDA	PPI+2 
	;MOV	B,A 
	PUSH	H 
	LHLD	PPI_ADR 
	INX	H 
	INX	H 
	MOV	B,M 
	POP	H 
	LDA	@SHFT 
	ANA	B 
	JNZ	SH3 
	RET 
 
SCTRL:	MOV	A,E 
	CPI	40H 
	RC 
	SUI	40H 
	MOV	E,A 
	RET 
 
SHIFT0:	;LDA	PPI+2 
	;MOV	B,A 
	PUSH	H 
	LHLD	PPI_ADR 
	INX	H 
	INX	H 
	MOV	B,M 
	POP	H 
	LDA	@SHFT 
	ANA	B 
	JZ	SH5 
	MOV	A,E 
	CPI	40H 
	RC 
	ADI	20H 
	MOV	E,A 
	RET 
 
@SHIFT:	;LDA	PPI+2 
	PUSH	H 
	LHLD	PPI_ADR 
	INX	H 
	INX	H 
	MOV	A,M 
	POP	H 
	ANI	8 
	RNZ 
SH3:	MOV	A,E 
	CPI	40H 
	JC	SH5 
	ADI	20H 
	JMP	SH1 
SH5:	MOV	A,E 
	CPI	40H 
	JC	SB 
SH1:	MOV	E,A 
	RET 
SB:	SUI	10H 
	JMP	SH1 
 
 
KEYBRD:	DB	0CH,1FH,1BH,0,1,2,3,4 

	DB	9,0AH,0DH 
	DB	7FH; Here was 5FH 
	DB	8,19H,18H,1AH 
	DB	'0123456789:;<=>?' 



	DB	'@ABCDEFGHIJKLMNO' 



	DB	'PQRSTUVWXYZ[\]^ ' 



 
 
@RUS:	DB	80H 
@CTRL:	DB	?Ctrl 
@SHFT:	DB	?Shift 
@RD:	DB	0 
 
PNT:	DW	ET1 
ET1:	DB	0ffh 
	ds	9 
	;DSEG 
NREP:	DS	1 
PRESS:	DS	10 
ET2:	DS	10 
IFNDEF	noend 
	END 
ENDIF 
 
 
include	E0CMDT.ASM 
;******************************************************** 
;*  SC80 text screen editor       COMMAND table module  * 
;*                        (c) TCHV,1989-93              * 
;******************************************************** 
 
 
IFNDEF INFADR 
INCLUDE E0DISP.MAC 
PUBLIC	FNDCMD 
EXTRN INFADR 
ENDIF 
 
@Left		equ	8h 
@Right		equ	18h 
@Up		equ	19h 
@Down		equ	1Ah 
@Str		equ	31 
Shift		equ	80h 
Cntrl		equ	40h 
 
 
CMD	MACRO	Adr1,Key1,Adr2,Key2 
;extrn	Adr1 
	DW	Adr1,Key1 
	ifnb	<Adr2> 
;extrn	Adr2 
	DW	Adr2,Key2 
	endif 
	ENDM 
 
	;dseg 
; *** Editor command table *** 
; DW CMD_ADDR 
; DB First Command sym, should be ANDed with 40h or ORed with 40h if Ctrl assumed pressed 
; DB Second command sym or 0 
CMDTBL:: 
	CMD	LFTM,	@Left,		RHTM,	@Right 
	DW	LFTM,@Left 
	DW	RHTM,@Right 
	CMD	UPM,	@Up,		DWNM,	@Down 
	DW	UPM,@Up 
	DW	DWNM,@Down 
	CMD	SCRLUP,	Shift+@Up,	SCRLDN,	Shift+@Down 
	DW	SCRLUP,Shift+@Up 
	DW	SCRLDN,Shift+@Down 
	CMD	REPMOD,	2 
	DW	REPMOD,2 
	DW	0 
 
	CMD	INSCTRL,0 
	DW	INSCTRL,0 
	CMD	LDEL,	3Fh,		RDEL,	3 
	DW	LDEL,3Fh 
	DW	RDEL,3 
	CMD	TAB,	9,		BSC,	12 
	DW	TAB,9 
	DW	BSC,12 
	CMD	CR,	13,		REST,	27 
	DW	CR,13 
	DW	REST,27 
	CMD	DELLT,	Cntrl+1,	DELRT,	Cntrl+3 
	DW	DELLT,Cntrl+1 
	DW	DELRT,Cntrl+3 
	CMD	LEND,	Cntrl+@Left,	REND,	Cntrl+@Right 
	DW	LEND,Cntrl+@Left 
	DW	REND,Cntrl+@Right 
	CMD	INSSPC,	Cntrl+2,	BRKSTR,	Cntrl+13 
	DW	INSSPC,Cntrl+2 
	DW	BRKSTR,Cntrl+13 
	DW	0 
 
	CMD	JoinStr,'J' 
	DW	JoinStr,'J' 
	DW	0 
 
	CMD	CALC,	@Str+'C'*256;,	ASSM	@Str+'A'*256 
	DW	CALC,@Str+'C'*256 
	CMD	SEARCH,	@Str+'S'*256,	REPLACE,@Str+'R'*256 
	DW	SEARCH,@Str+'S'*256 
	DW	REPLACE,@Str+'R'*256 
	CMD	NEW,	@Str+'N'*256;,	VERIFY,	@Str+'V'*256 
	DW	NEW,@Str+'N'*256 
	CMD	BEGBUF,	@Str+@Up*256,	ENDBUF,	@Str+@Down*256 
	DW	BEGBUF,@Str+@Up*256 
	DW	ENDBUF,@Str+@Down*256 
	CMD	EXIT,	@Str+'E'*256 
	DW	EXIT,@Str+'E'*256 
	CMD	RDFIL,	@Str+('R'-Cntrl)*256 
	DW	RDFIL,@Str+('R'-Cntrl)*256 
	CMD	WRFIL,	@Str+('W'-Cntrl)*256 
	DW	WRFIL,@Str+('W'-Cntrl)*256 
	CMD	PAGEUP,	Cntrl+@Up,	PAGEDN,	Cntrl+@Down 
	DW	PAGEUP,Cntrl+@Up 
	DW	PAGEDN,Cntrl+@Down 
 
	CMD	DELLIN,	'D', 	CONT_SRREP, 	'L' ; Continue SEARCH/REPLACE 
	DW	DELLIN,'D' 
	DW	CONT_SRREP,'L' 
	CMD	SWPWIN,	'W', WINUP,'U' 
	DW	SWPWIN,'W' 
	DW	WINUP,'U' 
	CMD	WINDN,	'K' 
	DW	WINDN,'K' 
 
	;*****	Block	commands ***** 
	CMD	DISBEG,	'Q'+@Left*256,	DISEND,	'Q'+@Right*256 
	DW	DISBEG,'Q'+@Left*256 
	DW	DISEND,'Q'+@Right*256 
	CMD	MRBEG,	'Q'+@Up*256,	MREND,	'Q'+@Down*256 
	DW	MRBEG,'Q'+@Up*256 
	DW	MREND,'Q'+@Down*256 
	CMD	RDBL,	'Q'+('R'-Cntrl)*256 
	DW	RDBL,'Q'+('R'-Cntrl)*256 
	DW	0 
	CMD	DELBL,	'Q'+('D'-Cntrl)*256 
	DW	DELBL,'Q'+('D'-Cntrl)*256 
	CMD	WRBL,	'Q'+('W'-Cntrl)*256 
	DW	WRBL,'Q'+('W'-Cntrl)*256 
	CMD	COPYBL,	'Q'+('C'-Cntrl)*256 
	DW	COPYBL,'Q'+('C'-Cntrl)*256 
	CMD	JMPBL,	'Q'+('J'-Cntrl)*256 
	DW	JMPBL,'Q'+('J'-Cntrl)*256 
	DW	0 
 
	cseg 
 
; **************  Find disk command **************** 
; Executes command or returns if command not found 
; c - first char of command sequence ;  HL - pointer to command table 
FNDCMD:	INX	H 
	inr	m	; Test High byte of command adress 
	dcr	m 
	INX	H 
	rz	; Return if command not found 
	mov	a,c 
	CMP	M 
	JZ	FirstSym	; First symbol is ok 
	INX	H 
ContCmdSearch: 
	INX	H 
	JNZ	FNDCMD 
	INX	D 
	INX	D 
	RET 
 
FirstSym: 
	INX	H 
	INR	M 
	DCR	M	; is second symbol required 
	JZ	CmdFound 
 
	push	h 
	MOV	C,A 
	;lxi	h,INFSTR+1 
	CALL	GETINFADR 
	INX	H 
	SetScrAddr 
	MVI	A,'^' 
	WriteNextSym 
		mov	m,a 
		inx	h 
 
	mov	a,c 
	ANI	3FH 
	ADI	40H 
	WriteNextSym 
		mov	m,a 
		inx	h 
	POP	H 
 
	MOV	A,B	; Read next symbol if needed 
	ORA	A 
	CZ	GETCHR 
	ani	11011111b	; toupper(Acc) 
	MOV	B,A 
	CMP	M 
	JNZ	ContCmdSearch 
 
CmdFound: 
	pop	d	; Drop	return address 
	dcx	h 
	dcx	h 
	mov	d,m 
	dcx	h 
	mov	e,m 
	XCHG 
	PCHL 
 
	END 
