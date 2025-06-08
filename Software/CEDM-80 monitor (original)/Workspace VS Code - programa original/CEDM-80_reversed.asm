
; Disassembly of the file "CEDM-80.BIN"
; CPU Type: Z80
; Created with dZ80 2.0
; on Friday, 02 of February 2024 at 08:01 PM
; 
; Engenharia reversa da ROM do computador (kit didático) CEDM-80 V1
; 

; Diretiva para o simulador DeZog, usado com a IDE VSCode, para informar que 
; o programa é para um computador com Z80 sem plataforma de mercado (MSX, ZX Spectrum etc.)
    DEVICE NOSLOT64K

; Distribuição de memória do CEDM-80 V1
; Linhas de endereçamento de A0 a A13 utilizadas (13 bits)
; 0000 ~ 0FFF : EPROM (2716), 4KBytes (embora, somente 2KBytes são endereçáveis em 1 memória)
; 2000 ~ 27FF : RAM (6116), 2KBytes
;
; Em bits (binário):
; XXMM MAAA AAAA AAAA : A = BITS DE ENDEREÇO, M = BITS DE SELEÇÃO DE MEMÓRIA, X = IRRELEVANTE
; 0000 0XXX XXXX XXXX : EPROM (0000 ~ 07FF)
; 0000 1XXX XXXX XXXX : EPROM (0800 ~ 0FFF)
; 0001 0XXX XXXX XXXX : NÃO USADO (1000 ~ 17FF)
; 0001 1XXX XXXX XXXX : NÃO USADO (1800 ~ 1FFF)
; 0010 0XXX XXXX XXXX : RAM (2000 ~ 27FF)

    ORG 0000H


	LD	SP,2800H		; Define a pilha (stack) começando no endereço 2800H
	PUSH	BC		
	PUSH	DE		
	PUSH	HL		
	PUSH	AF		
	LD	HL,27E6H		
	LD	(HL),19H		; Escreve 19H no endereço 27E6H
	LD	HL,005CH		
	LD	DE,27E7H		
	LD	BC,0006H		; Define execução de 6 vezes do comando LDIR (Cópia de um lugar para outro da memória, do local definido por (HL) para local (DE)
	LDIR			; Copia o que está na memória, a partir do endereço 005CH para 27E7H, 6 endereços na sequência (mensagem CEDM-80)
jmp2:				
	LD	SP,27E4H		; Redefine o stack pointer para o endereço 27E4H
	LD	HL,27E7H		; Define localização da mensagem CEDM-80
	LD	B,00H		; Parâmetro do sub1
	LD	E,06H		; Parâmetro do sub1
	LD	A,01H		; Parâmetro do sub1
jmp1:				
	CALL	sub1		; Chama endereço 0090H
	LD	A,C		
	ADD	A,A		
	DEC	E		
	JP	NZ, jmp1		
	LD	A,B		
	CP	00H		
	JP	Z, jmp2		
jmp3:				
	LD	HL,27E7H		
	CALL	sub2		; Chama endereço 009CH
	LD	A,D		
	OUT	(03H),A		; MULTIPLEXAÇÃO (seleciona coluna)
	IN	A,(01H)		; Lê teclado
	CP	00H		; Verifica se nenhuma tecla foi apertada
	JP	NZ, jmp3		; Se nenhuma tecla foi apertada, vai para JMP3 (loop), senão vai para SUB3
	CALL	sub3		; Chama endereço 00BDH
	CALL	sub4		; Chama endereço 00D8H
	CP	13H		
	JP	Z, jmp4		
	CP	10H		
	JP	C, jmp5		
jmp8:				
	CALL	sub5		; Chama endereço 00F0H
jmp9:				
	LD	HL,27E6H		
	LD	A,(HL)		
	JP	jmp6		
				
    DB	0C6H, 86H, 0A1H, 0AAH, 80H, 0C0H			; Mensagem codificada para os displays: "CEDM-80"
				
	JP	0350H		
				
jmp6:				
	LD	HL,0320H		
	ADD	A,L		
	LD	L,A		
	LD	A,(HL)		
	LD	C,A		
	LD	A,0AH		
	ADD	A,L		
	LD	L,A		
	LD	L,(HL)		
	LD	H,C		
	JP	(HL)		
jmp4:				
	LD	HL,27E6H		
	LD	A,(HL)		
	CP	15H		
	JP	Z, jmp7		
	JP	jmp8		
jmp5:				
	LD	HL,27E6H		
	LD	A,(HL)		
	CP	15H		
	JP	Z,0205H		
	NOP			
	JP	jmp9		
sub1:				; Faz a leitura de dado do endereço de I/O 01H
	LD	C,A		
	CALL	sub6		; Atualiza leitura do teclado
	IN	A,(01H)		; Lê dado no buffer do teclado
	CP	00H		; Verifica se foi pressionada alguma tecla
	RET	Z		; Se nenhuma tecla foi apertada, retorna ao programa que chamou
				
	LD	B,A		; Se alguma tecla foi apertada, transfere buffer lido para o reg. B
	LD	D,C		
	RET			
sub2:				; Texto a ser exibido deve estar no endereço apontado por HL
	LD	C,06H		
	LD	A,01H		
jmp27:				
	CALL	sub6		; Atualização do display
	ADD	A,A		
	DEC	C		
	RET	Z		
	JP	jmp27		
sub6:				
	PUSH	AF		
	OUT	(03H),A		; Seleciona linha definida pelo reg. A na multiplexação
	LD	A,(HL)		; Dado a ser escrito no display selecionado vem do endereço de memória HL
	OUT	(01H),A		; Atualiza display selecionado na multiplexação
	EXX			
	LD	DE,0100H		
jmp10:				
	DEC	DE		
	LD	A,D		
	OR	E		
	JP	NZ, jmp10		
	EXX			
	INC	HL		
	POP	AF		
	RET			
sub3:				
	LD	C,00H		
	LD	A,01H		
	CP	D		
	JP	Z, jmp11		
	ADD	A,A		
	LD	C,08H		
	CP	D		
	JP	Z, jmp11		
	ADD	A,A		
	LD	C,10H		
	CP	D		
	JP	Z, jmp11		
	JP	jmp2		
jmp11:				
	LD	D,C		
	RET			
sub4:				
	LD	E,08H		
	LD	C,00H		
	LD	A,01H		
jmp13:				
	CP	B		
	JP	Z, jmp12		
	INC	C		
	ADD	A,A		
	DEC	E		
	JP	NZ, jmp13		
	JP	jmp2		
jmp12:				
	LD	A,C		
	ADD	A,D		
	LD	B,A		
	RET			
				
	NOP			
				
sub5:				
	LD	HL,27E6H		
	LD	(HL),B		
	RET			
				
	LD	C,06H		
	LD	HL,27E6H		
	LD	(HL),17H		
	INC	HL		
jmp14:				
	LD	(HL),0FFH		
	INC	HL		
	DEC	C		
	JP	NZ, jmp14		
	LD	(HL),00H		
	INC	HL		
	LD	(HL),00H		
	INC	HL		
	LD	(HL),00H		
	JP	jmp2		
	LD	HL,27EEH		
	LD	A,B		
	RLD			
	INC	HL		
	RLD			
	CALL	sub7		; Chama endereço 0152H
	JP	jmp2		
	CALL	sub11		; Chama endereço 0140H
	LD	HL,27E6H		
	LD	(HL),18H		
	LD	HL,27EFH		
	CALL	sub7		; Chama endereço 0152H
	JP	jmp2		
	CALL	sub11		; Chama endereço 0140H
	LD	A,B		
	RLD			
	LD	A,(HL)		
	LD	(DE),A		
	LD	HL,27EFH		
	CALL	sub7		; Chama endereço 0152H
	JP	jmp2		
sub11:				
	LD	HL,27EEH		
	LD	E,(HL)		
	INC	HL		
	LD	D,(HL)		
	LD	A,(DE)		
	DEC	HL		
	DEC	HL		
	LD	(HL),A		
	PUSH	HL		
	LD	HL,27E6H		
	LD	(HL),18H		
	POP	HL		
	RET			
sub7:				
	LD	BC,27E7H		
	CALL	sub9		; Chama endereço 016EH
	DEC	HL		
	CALL	sub9		; Chama endereço 016EH
	DEC	HL		
	CALL	sub9		; Chama endereço 016EH
	RET			
sub12:				
	LD	HL,27EEH		
	LD	(HL),E		
	INC	HL		
	LD	(HL),D		
	DEC	HL		
	DEC	HL		
	LD	A,(DE)		
	LD	(HL),A		
	RET			
				
	RST	38H		
	RST	38H		
sub9:				; Exibe números em hexadecimal?
	LD	A,(HL)		
	PUSH	HL		
	LD	HL,27F0H		
	LD	(HL),A		
	XOR	A		
	RLD			
	CALL	sub10		; Chama endereço 0186H
	LD	(BC),A		
	INC	BC		
	XOR	A		
	RLD			
	CALL	sub10		; Chama endereço 0186H
	LD	(BC),A		
	INC	BC		
	POP	HL		
	RET			
sub10:				
	PUSH	DE		; Decodificação de Hexadecimal?
	LD	DE,018FH		
	ADD	A,E		
	LD	E,A		
	LD	A,(DE)		
	POP	DE		
	RET			
				
    DB	0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0F8H, 80H, 90H, 88H, 83H, 0C6H, 0A1H, 86H, 8EH			; Caracteres "0" a "F" tabelados para o display (hexadecimal)
				
	CALL	sub11		; Chama endereço 0140H
	INC	DE		
	CALL	sub12		; Chama endereço 0161H
	LD	HL,27EFH		
	CALL	sub7		; Chama endereço 0152H
	JP	jmp2		
	CALL	sub11		;Chama endereço 0140H
	DEC	DE		
	CALL	sub12		; Chama endereço 0161H
	LD	HL,27EFH		
	CALL	sub7		; Chama endereço 0152H
	JP	jmp2		
				
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
				
	LD	A,0FFH		
	OUT	(03H),A		
	LD	A,7FH		
	OUT	(01H),A		
	LD	HL,27EDH		
	LD	(HL),0C3H		
	LD	SP,27F8H		
	POP	AF		
	POP	HL		
	POP	DE		
	POP	BC		
	LD	SP,27E4H		
	JP	27EDH		;?
jmp19:				
	LD	HL,27E5H		
	LD	(HL),0FEH		
	JP	jmp7		
sub13:				
	LD	HL,27E7H		
	LD	(HL),0FFH		
	INC	HL		
	LD	(HL),0FFH		
	INC	HL		
	RET			
jmp7:				
	LD	DE,0304H		
	LD	HL,27E5H		
	INC	(HL)		
	INC	(HL)		
	LD	A,E		
	ADD	A,(HL)		
jmp15:				
	LD	E,A		
	LD	A,(DE)		
	LD	L,A		
	INC	DE		
	LD	A,(DE)		
	LD	H,A		
	JP	(HL)		
	LD	HL,27E5H		
	LD	DE,031BH		
	LD	A,E		
	ADD	A,(HL)		
	JP	jmp15		
	CALL	sub13		;Chama endereço 01EAH
	LD	(HL),88H		
	INC	HL		
	LD	(HL),0B7H		
	LD	HL,27F9H		
	JP	jmp16		
jmp16:				
	LD	BC,27EBH		
	CALL	sub9		;Chama endereço 016EH
	JP	jmp2		
	LD	HL,27F9H		
	LD	A,B		
	RLD			
	JP	jmp16		
	CALL	sub13		;Chama endereço 01EAH
	LD	(HL),83H		
	INC	HL		
	LD	(HL),0B7H		
	LD	HL,27FFH		
	JP	jmp16		
	LD	HL,27FFH		
	LD	A,B		
	RLD			
	JP	jmp16		
	CALL	sub13		;Chama endereço 01EAH
	LD	(HL),0C6H		
	INC	HL		
	LD	(HL),0B7H		
	LD	HL,27FEH		
	JP	jmp16		
	LD	HL,27FEH		
	LD	A,B		
	RLD			
	JP	jmp16		
	CALL	sub13		;Chama endereço 01EAH
	LD	(HL),0A1H		
	INC	HL		
	LD	(HL),0B7H		
	LD	HL,27FDH		
	JP	jmp16		
	LD	HL,27FDH		
	LD	A,B		
	RLD			
	JP	jmp16		
	CALL	sub13		;Chama endereço 01EAH
	LD	(HL),86H		
	INC	HL		
	LD	(HL),0B7H		
	LD	HL,27FCH		
	JP	jmp16		
	LD	HL,27FCH		
	LD	A,B		
	RLD			
	JP	jmp16		
	CALL	sub13		;Chama endereço 01EAH
	LD	(HL),89H		
	INC	HL		
	LD	(HL),0B7H		
	LD	HL,27FBH		
	JP	jmp16		
	LD	HL,27FBH		
	LD	A,B		
	RLD			
	JP	jmp16		
	CALL	sub13		;Chama endereço 01EAH
	LD	(HL),0C7H		
	INC	HL		
	LD	(HL),0B7H		
	LD	HL,27FAH		
	JP	jmp16		
	LD	HL,27FAH		
	LD	A,B		
	RLD			
	JP	jmp16		
	CALL	sub13		;Chama endereço 01EAH
	LD	(HL),8EH		
	INC	HL		
	LD	(HL),0B7H		
	LD	HL,27F8H		
	JP	jmp16		
	LD	HL,27F8H		
	LD	A,B		
	RLD			
	JP	jmp16		
	LD	A,I		
	LD	HL,27F7H		
	LD	(HL),A		
	CALL	sub13		;Chama endereço 01EAH
	LD	(HL),0F9H		
	INC	HL		
	LD	(HL),0B7H		
	LD	HL,27F7H		
	JP	jmp16		
	LD	HL,27F7H		
	LD	A,B		
	RLD			
	LD	A,(HL)		
	LD	I,A		
	JP	jmp16		
	LD	BC,27F2H		
	LD	A,0C3H		
	LD	(BC),A		
	INC	BC		
	LD	HL,27EEH		
	LD	A,(HL)		
	LD	(BC),A		
	INC	BC		
	INC	HL		
	LD	A,(HL)		
	LD	(BC),A		
	JP	jmp2		
	DJNZ	0308H		
	JR	NC, jmp17		
	LD	B,A		
	LD	(BC),A		
jmp17:				
	LD	E,(HL)		
	LD	(BC),A		
	LD	(HL),L		
	LD	(BC),A		
	ADC	A,H		
	LD	(BC),A		
	AND	E		
	LD	(BC),A		
	CP	D		
	LD	(BC),A		
	POP	DE		
	LD	(BC),A		
	JR	jmp18		
	JP	jmp19		
jmp18:				
	DAA			
	LD	(BC),A		
	LD	A,02H		
	LD	D,L		
	LD	(BC),A		
	LD	L,H		
	LD	(BC),A		
	ADD	A,E		
	LD	(BC),A		
	SBC	A,D		
	LD	(BC),A		
	OR	C		
	LD	(BC),A		
	RET	Z		
				
	LD	(BC),A		
	PUSH	HL		
	LD	(BC),A		
	RST	38H		
	RST	38H		
	RST	38H		
	NOP			
	LD	BC,0101H		
	LD	BC,0201H		
	LD	BC,0001H		
	PUSH	AF		
	LD	E,0AFH		
	SBC	A,A		
	RET	Z		
				
	JP	PO,0FF1H		;?
	CPL			
	RLA			
				
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
				
	LD	A,00H		
	LD	(2759H),A		
	LD	HL,0591H		
jmp35:				
	LD	DE,275AH		
	LD	BC,0006H		
	LDIR			
jmp21:				
	LD	HL,275AH		
	LD	B,00H		
	LD	E,06H		
	LD	A,01H		
jmp20:				
	CALL	sub1		;Chama endereço 0090H
	LD	A,C		
	ADD	A,A		
	DEC	E		
	JR	NZ, jmp20		
	LD	A,B		
	CP	00H		
	JR	Z, jmp21		
jmp22:				
	LD	HL,275AH		
	CALL	sub2		;Chama endereço 0090H
	LD	A,D		
	OUT	(03H),A		; MULTIPLEXAÇÃO
	IN	A,(01H)		; TECLADO
	CP	00H		
	JR	NZ, jmp22		
	CALL	sub3		;Chama endereço 00BDH
	CALL	sub4		;Chama endereço 00D8H
	CP	14H		
	JP	Z, jmp23		
	CP	10H		
	JR	C, jmp24		
	CP	13H		
	JR	Z, jmp26		
	JP	jmp21		
jmp26:				
	LD	A,(2759H)		
	CP	00H		
	JP	Z, jmp25		
	RST	00H		
jmp24:				
	LD	A,(2759H)		
	CP	00H		
	JR	Z,jmp29		
	CP	01H		
	JR	Z,jmp30		; 03DF
	CP	02H		
	JR	Z,jmp31		; 03E4
	RST	00H		
jmp23:				
	LD	A,(2759H)		
	CP	00H		
	JR	Z,jmp32		; 03C4
	CP	01H		
	JR	Z,jmp33		; 03CF
	CP	02H		
	JR	Z,jmp34		; 03FF
	RST	00H		
jmp32:				
	LD	HL,0597H		
	LD	A,01H		
	LD	(2759H),A		
	JP	jmp35		; 0358
jmp33:				
	LD	HL,059DH		
	LD	A,02H		
	LD	(2759H),A		
	JP	jmp35		; 0358
jmp29:				
	LD	HL,2750H		
	JR	jmp36		; 03E7
jmp30:				
	LD	HL,2752H		
	JR	jmp36		; 03E7
jmp31:				
	LD	HL,2754H		
jmp36:				
	LD	A,B		
	PUSH	HL		
	RLD			
	INC	HL		
	RLD			
	LD	BC,275CH		
	POP	HL		
	CALL	sub9		;Chama endereço 016EH
	INC	HL		
	LD	BC,275AH		
	CALL	sub9		;Chama endereço 016EH
	JP	jmp21		
jmp34:				
	LD	A,0FFH		
	OUT	(03H),A		; MULTIPLEXAÇÃO
	LD	A,0F7H		
	OUT	(01H),A		; DISPLAY
	CALL	sub14		;Chama endereço 0434H
	JP	C,jmp37		; 0575
	LD	(2756H),A		
	LD	HL,0FA0H		
	CALL	sub19		
	LD	HL,2750H		
	LD	BC,0007H		
	CALL	sub24		
	LD	HL,0FA0H		
	CALL	sub18		
	CALL	sub15		
	CALL	sub24		
	LD	HL,0FA0H		
	CALL	sub18		
	JP	jmp28		; 057D
sub14:				
	CALL	sub15		;Chama endereço 0441H
	RET	C		
				
	XOR	A		
jmp38:				
	ADD	A,(HL)		
	CPI			
	JP	PE,jmp38		
	OR	A		
	RET			
sub15:				
	LD	HL,2752H		
	LD	E,(HL)		
	INC	HL		
	LD	D,(HL)		
	INC	HL		
	LD	C,(HL)		
	INC	HL		
	LD	H,(HL)		
	LD	L,C		
	OR	A		
	SBC	HL,DE		
	LD	C,L		
	LD	B,H		
	INC	BC		
	EX	DE,HL		
	RET			
sub24:				
	LD	E,(HL)		
	CALL	sub16		;Chama endereço 045EH
	CPI			
	JP	PE,sub24		
	RET			
sub16:				
	LD	D,08H		
	OR	A		
	CALL	sub17		;Chama endereço 0471H
jmp39:				
	RR	E		
	CALL	sub17		;Chama endereço 0471H
	DEC	D		
	JR	NZ,jmp39		
	SCF			
	CALL	sub17		;Chama endereço 0471H
	RET			
sub17:				
	EXX			
	LD	H,00H		
	JR	C,jmp40		
	LD	L,10H		
	CALL	sub18		;Chama endereço 048FH
	LD	L,04H		
	JR	jmp41		; 0486
jmp40:				
	LD	L,08H		
	CALL	sub18		;Chama endereço 048FH
	LD	L,08H		
jmp41:				
	CALL	sub19		;Chama endereço 048BH
	EXX			
	RET			
sub19:				
	LD	C,9AH		
	JR	jmp42		; 0491
sub18:				
	LD	C,4DH		
jmp42:				
	ADD	HL,HL		
	LD	DE,0001H		
	LD	A,0FFH		
jmp43:				
	OUT	(04H),A		; SEM SENTIDO P/ V1! A LINHA A2 DE ENDEREÇO NÃO VAI PARA NENHUM PERIFÉRICO!!
	LD	B,C		
	DJNZ	049AH		
	XOR	40H		
	SBC	HL,DE		
	JR	NZ,jmp43		
	RET			
jmp25:				
	LD	HL,(2750H)		
	LD	(2757H),HL		
jmp44:				
	LD	A,0FFH		
	OUT	(03H),A		; MULTIPLEXAÇÃO
jmp47				
	LD	A,0BFH		
	OUT	(01H),A		; DISPLAY
	LD	HL,03E8H		
jmp45:				
	CALL	sub20		;Chama endereço 0517H
	JR	C,jmp44		; 04A9
	DEC	HL		
	LD	A,H		
	OR	L		
	JR	NZ,jmp45		; 04B4
jmp46:				
	CALL	sub20		;Chama endereço 0517H
	JR	NC,jmp46		; 04BE
	LD	HL,2750H		
	LD	BC,0007H		
	CALL	sub21		;Chama endereço 0532H
	JR	C,jmp47		; 04AD
	LD	BC,275CH		
	LD	HL,2750H		
	CALL	sub9		;Chama endereço 016EH
	INC	HL		
	LD	BC,275AH		
	CALL	sub9		;Chama endereço 016EH
	LD	DE,(2750H)		
	LD	B,20H		
	LD	HL,275AH		
	CALL	sub2		;Chama endereço 009CH
	DJNZ	04E4H		
	LD	HL,(2757H)		
	NOP			
	OR	A		
	SBC	HL,DE		
	JP	NZ,04A9H		
	LD	A,0FFH		
	OUT	(03H),A		; MULTIPLEXAÇÃO
	LD	A,0FEH		
	OUT	(01H),A		; DISPLAY
	CALL	sub15		;Chama endereço 0441H
	JP	C,0575H		
	CALL	sub21		;Chama endereço 0532H
	JP	C,0575H		
	CALL	sub14		;Chama endereço 0431H
	LD	HL,2756H		
	CP	(HL)		
	JP	NZ,0575H		
	JP	057DH		
sub20:				
	LD	DE,0000H		
	IN	A,(02H)		; TECLADO
	INC	DE		
	RLA			
	JR	C,051AH		
	LD	A,0BFH		
	OUT	(04H),A		; SEM SENTIDO!
	IN	A,(02H)		;TECLADO
	INC	DE		
	RLA			
	JR	NC,0524H		
	LD	A,0FFH		
	OUT	(04H),A		; SEM SENTIDO!
	LD	A,E		
	CP	66H		
	RET			
sub21:				
	XOR	A		
	EX	AF,AF'		
	CALL	sub22		;Chama endereço 053FH
	LD	(HL),E		
	CPI			
	JP	PE,0534H		
	EX	AF,AF'		
	RET			
sub22:				
	CALL	sub23		;Chama endereço 0550H
	LD	D,08H		
	CALL	sub23		
	RR	E		
	DEC	D		
	JR	NZ,0544H		
	CALL	sub23		;Chama endereço 0550H
	RET			
sub23:				
	EXX			
	LD	HL,0000H		
				
	CALL	sub20		;Chama endereço 0517H
	INC	D		
	DEC	D		
	JR	NZ,056CH		
	JR	C,0563H		
	DEC	L		
	DEC	L		
	SET	0,H		
	JR	0554H		
	INC	L		
	BIT	0,H		
	JR	Z,0554H		
	RL	L		
	EXX			
	RET			
				
	EX	AF,AF'		
	SCF			
	EX	AF,AF'		
	EXX			
	RET			
				
	RST	38H		
	RST	38H		
	RST	38H		
	RST	38H		
jmp37:				
	LD	HL,0585H		
	CALL	sub2		
	JR	0575H		
jmp28:				
	LD	HL,058BH		
	CALL	sub2		
	JR	jmp28		;057d
	ADD	A,(HL)		
	ADC	A,0CEH		
	RET	NZ		
				
	RST	38H		
	RST	38H		
				
	ADC	A,(HL)		; F
	LD	SP,HL		; I
	RET	Z		; N
				
	RST	38H		
	RST	38H		
	RST	38H		
				
	ADC	A,(HL)		; F
	LD	SP,HL		; I
	RST	00H		; L
	ADD	A,(HL)		; E
				
	RST	38H		
	RST	38H		
				
	ADC	A,(HL)		; F
	RET	NZ		; O
	RET	Z		; N
	ADD	A,A		; T
	ADD	A,(HL)		; E
				
	RST	38H		
				
	ADC	A,(HL)		; F
	LD	SP,HL		; I
	RET	Z		; N
	ADC	A,B		; A
	RST	00H		; L
				
	RST	38H		
