;===========================================================================
; Thiago Turcato do Rego - 2023
; Project: NEMO-80, New Monitor for CEDM-80
; File: NEMO-80.asm
;===========================================================================

;============ TERMINOLOGY, CONVENTIONS AND ORGANIZATION ====================
; -- TERMINOLOGIES --
; subr.  = subroutines
; drcly = directly
; aux. = auxiliary
; 
; -- SYMBOLS CONVENTIONS --
; - Symbols in UPPER CASE LETTERS = constants
; - Labels starting with "." are local jump entry points
; - Labels starting with "_" are local subroutines (aux. subr.)
; - Labels starting with lower case letters (except for the cases below) 
;    are general function calls, open to any user
; - Labels starting with "dmsg_" are ascii text formated messages to use 
;    for display (user interface messages)
;
;=============================================================================

; Compilation directives for allocating memory (no bank) and SLD file generation
 DEVICE NOSLOT64K
 SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION    

;******** Constants definition ********
; ROM first address and size (2 KiB = 2048 bytes, 0000H ~ 07FFH)
ROMBEGIN            EQU 0000H
ROMSIZE             EQU 800H

; RAM first address and size (2 KiB = 2048 bytes, 2000H ~ 27FFH)
RAMBEGIN            EQU 2000H
RAMSIZE             EQU 800H

; Constants
CHR_0      EQU 0C0H
CHR_1      EQU 0F9H
CHR_2      EQU 0A4H
CHR_3      EQU 0B0H
CHR_4      EQU 099H
CHR_5      EQU 092H
CHR_6      EQU 082H
CHR_7      EQU 0F8H
CHR_8      EQU 080H
CHR_9      EQU 090H
CHR_A      EQU 088H
CHR_B      EQU 083H
CHR_C      EQU 0C6H
CHR_D      EQU 0A1H
CHR_E      EQU 086H
CHR_F      EQU 08EH


; I/O addresses
DISP            EQU 01H
SEL_DISP        EQU 03H
KEYB            EQU 01H

; RESERVADO PARA SISTEMA: END. 2600H ~ 27FF

; RAM para sistema até 27FF
RAM_DISPLAY    EQU 2770H    ; Caracteres a serem exibidos no display pos. 2770H a 2775H
RAM_KEYBOARD   EQU 276EH
RAM_KEYB_COL   EQU 276FH
RAM_KEYB_CONV  EQU 276DH

; Stack = 2780H a 27FFH


; Variáveis do programa, do endereço 25FF para trás
VAR_VALUE_IN   EQU 25FFH


;******** Beggining of monitor program ********
    ORG ROMBEGIN

; ********************** Programa principal ********************** 
; Ajustes e configuração iniciais
    LD SP, 27FFH                ; Ajusta o stack pointer no fim da memória RAM. Considerado 128 bytes de stack 2780 até 27FF

; Inicializações antes do programa
initialization:
    CALL clean_ram_disp         ; Limpa a memória de exibição no display

; Inicio do programa
ini_program:
    CALL keyb_disp              ; Chama atualização do display e teclado
    LD A,(RAM_KEYB_CONV)

    CALL keyb_disp              ; Chama atualização do display e teclado
    JP ini_program

.keypressed
    RES 7,A                     ; Remove bit 7, sinalizador de tecla pressionada
    LD C,A
    LD B,00H
    LD HL,d_numchar
    ADD HL,BC
    LD A,(HL)
    LD (RAM_DISPLAY),A          ; Exibe código da tecla apertada
    RET


; ********************** Subroutines ********************** 
;

; Subrotina de limpeza da area de memoria para o display
;
clean_ram_disp:                 ;Inicializa area de memoria do display
    PUSH HL
    PUSH BC
    LD HL,RAM_DISPLAY           ; Inicio da RAM para display
    LD B,06                     ; Preparar ponteiro para 6 endereços a partir do inicio da RAM para display
.loop_clean_disp:               ; Inicializa area de memoria do display, com FFH (nenhum segmento aceso)
    LD (HL),0FFH
    INC HL
    DJNZ .loop_clean_disp
    POP BC
    POP HL
    RET

; Subrotina de entradas de dados sequencial pelo teclado (in_data)
; Entradas: 
; (HL)   = DADO DE SISTEMA, sinalizador de tecla pressionada anteriormente +
;          número de dígitos já inputados (zerar essa variavel antes de chamar a subrotina)
; (HL+1) = dígitos 1 e 2
; (HL+2) = dígitos 3 e 4
; (HL+3) = dígitos 5 e 6
; 
; Lógica em pseudo-programa de intertravamento para que o processamento da tecla ocorra uma vez 
;  quando a tecla for pressionada:
;
; If !(keypress.bit7) then RST keyprsmem.bit7
; If  (keypress.bit7) &&  (keyprsmem.bit7) then end
; If  (keypress.bit7) && !(keyprsmem.bit7) then SET keyprsmem.bit7 and process the input
in_data:
    PUSH BC                     ; Guarda na pilha valor atual de BC para poder usar BC na subrotina
    PUSH DE                     ; Guarda o valor atual de DE para poder usar o D para o dado atualmente na variável de entrada
    LD A,(RAM_KEYB_CONV)        ; Recupera tecla atualmente pressionada (keypress = RAM_KEYB_CONV)
    BIT 7,A                     ; Testa bit 7 de RAM_KEYB_CONV para verificar se alguma tecla está pressionada (keypress.bit7)
    JR Z,.reset_keyprsmem       ; Bit 7 keypress é zero (tecla solta): reseta bit 7 memória (keypressmem)
    LD A,(HL)                   ; Recupera memória de tecla pressionada (keyprsmem)
    BIT 7,A                     ; Testa bit 7, sinalizador de tecla pressionada anteriormente (keyprsmem.bit7)
    JR NZ,.end_in_data          ; bit 7 memória não zero (setado): não faz nada, finaliza a subrotina
    SET 7,A                     ; Seta bit 7 e segue com o processamento da tecla pressionada
    LD (HL),A                   ; Salva na memória de tecla pressionada (keyprsmem), que há uma tecla pressionada (bit 7 setado)
    AND 0FH                     ; Remove a parte mais significativa. Parte menos significativa é em qual digito está
    LD C,A                      ; Armazena em C, qual o dígito atual no processo de entrada para poder usar A para processar valor de entrada
    SRL C                       ; Divide o contador de dígitos por dois para calcular offset na memória de escrita do input.
    LD B,00H                    ; Zera a parte mais significativa de BC para poder usar BC para somar o ponteiro de memória HL
    BIT 0,A                     ; Verifica se o valor de contagem do dígito é par ou impar.
    JR NZ,.input_msnibble       ; Se for ímpar, valor vai no nibble mais significativo
                                ; Se par, valor vai no nibble menos significativo. 
    LD A,(RAM_KEYB_CONV)        ; Recupera qual tecla foi pressionada atualmente
    AND 0F                      ; Garante que a parte mais significativa esteja zero
    JR .input_writevar          ; Vai para trecho onde o valor de A será escrito dentro da variável de entrada
.input_msnibble
    LD A,(RAM_KEYB_CONV)        ; Recupera qual tecla foi pressionada atualmente
    SLA A                       ; Desloca o valor da tecla, um nibble para a esquerda (4x SLA A), prench. c/ zero a parte menos significativa
    SLA A
    SLA A
    SLA A
.input_writevar
    INC HL                      ; Faz com que o ponteiro vá para a próxima posição de memória, onde começa a escrita da var. de entrada
    ADD HL,BC                   ; Soma o valor do ponteiro HL com o offset calculado BC
    JR C,.in_data_end           ; Se a soma do ponteiro estourar, significa erro e a subrotina é finalizada forçosamente
    LD D,A                      ; Salva em D o valor atual da tecla pressionada
    LD A,(HL)                   ; Recupera valor atual da variável de entrada para "encaixar" nova tecla pressionada
    OR D                        ; Monta o valor da tecla pressionada em A
    LD (HL),A                   ; Devolve o valor processado para a variável de entrada na posição HL
    JR .in_data_end             ; Vai para o fim da subrotina. Fim do processamento de entrada (input)
.reset_keyprsmem
    LD A,(HL)                   ; HL contém a posição de memória de 
    RES 7,A                     ; Remove bit 7, sinalizador de tecla pressionada anteriormente
    LD (HL),A
.in_data_end
    POP DE
    POP BC
    RET

; Subrotina de atualização do display/teclado
; Dados relevantes
; (RAM_DISPLAY) = Inicio da sequencia das 6 posições de memória lidas pelo sistema para exibição no display
;                 Dado gravado nas posições de memória são o estado de cada segmento do display
; (RAM_KEYB_CONV) = Posição de memória onde é armazenado o código da tecla apertada e se há uma tecla apertada
;                   Bits (1 byte):  P X X X K K K K
;                   P: Se 1, alguma tecla pressionada; Se 0, nenhuma tecla pressionada
;                   X: "Don't care" (sem função)
;                   KKKK: 1 nibble do código de tecla cf. abaixo:
;                   0 a 9H: Teclas "0" a "9" pressionadas (com o bit P)
;                   A a FH: Teclas "A" a "F" pressionadas (com o bit P)
;                   10H: Tecla "ADR"
;                   11H: Tecla "DAT"
;                   12H: Tecla "-"
;                   13H: Tecla "+"
;                   14H: Tecla "GO"
;                   15H: Tecla "REG"
;                   16H: Tecla "IV"
;                   17H: Tecla Vazia
;                   
keyb_disp:
    PUSH BC
    PUSH HL
    LD A,00                     
    LD (RAM_KEYB_CONV),A        ; Limpa variável de memória do teclado antes de ler o teclado
    LD A,01H                    ; Ajusta A para apontar para a primeira coluna de displays (mais significativa) 
    LD HL,RAM_DISPLAY           ; Carrega no ponteiro HL primeiro endereço da RAM de sistema para o display
.loop:
    OUT (SEL_DISP),A            ; Seleciona display apontado por A
    LD C,A                      ; Guarda o valor de A
    LD A,0FFH    
    OUT (DISP),A
    ;LD B, 1
    ;CALL delay_ms
    IN A,(KEYB)                 ; Lê o teclado na coluna atual
    CP 00
    JR Z,.wr_display            ; Se nada foi lido do teclado (nenhuma tecla apertada), vai para a atualização do display direto
    LD (RAM_KEYBOARD),A         ; Se algo foi lido do teclado, registra tecla para a coluna atual
    LD A,C                      ; Recupera dado de qual coluna está sendo atualizada
    LD (RAM_KEYB_COL),A         ; Registra na memória de qual coluna é a tecla apertada
.keyb_cnv:
    LD A,(RAM_KEYBOARD)         ; Converte posição da tecla no valor correspondente que representa (função da tecla)
    CP 01                       ; Não foi considerada ainda a coluna nesse ponto
    JP Z,.num_0
    CP 02
    JP Z,.num_1
    CP 04
    JP Z,.num_2
    CP 08
    JP Z,.num_3
    CP 16
    JP Z,.num_4
    CP 32
    JP Z,.num_5
    CP 64
    JP Z,.num_6
    CP 128
    JP Z,.num_7
    RET
.num_0:
    LD A,00H
    LD B,A
    JR .keyb_col
.num_1:
    LD A,01H
    LD B,A
    JR .keyb_col
.num_2:
    LD A,02H
    LD B,A
    JR .keyb_col
.num_3:
    LD A,03H
    LD B,A
    JR .keyb_col
.num_4:
    LD A,04H
    LD B,A
    JR .keyb_col
.num_5:
    LD A,05H
    LD B,A
    JR .keyb_col
.num_6:
    LD A,06H
    LD B,A
    JR .keyb_col
.num_7:
    LD A,07H
    LD B,A
.keyb_col:
    LD A,(RAM_KEYB_COL)         ; Decodifica a coluna e calcula o código correto da tecla (0~7H: coluna 1, 8~FH: coluna 2; 10~17H: coluna 3)
    CP 01
    JR Z,.keyb_cnv_plus0
    CP 02
    JR Z,.keyb_cnv_plus8
    CP 04
    JR Z,.keyb_cnv_plus16
    JR .wr_display
.keyb_cnv_plus0:                ; Identificado como tecla da coluna 1 (0~7H)
    LD A,B
    JR .keyb_cnv_end
.keyb_cnv_plus8:                ; Identificado como tecla da coluna 2 (8~FH)
    LD A,B
    ADD A,08
    JR .keyb_cnv_end
.keyb_cnv_plus16:               ; Identificado como tecla da coluna 1 (10~17H)
    LD A,B
    ADD A,16
.keyb_cnv_end:
    SET 7,A                     ; Seta o bit 7 do valor convertido para dizer que a tecla foi lida, especialmente no caso do zero (0H)
    LD (RAM_KEYB_CONV),A
.wr_display:
    LD A,(HL)
    OUT (DISP),A
    LD B, 2
    CALL delay_ms
    INC HL
    LD A,C
    ADD A,A
    CP 64
    JP NZ, .loop                ; Se não chegou na última coluna de atualização do display (64), vai para o próximo loop
    POP HL
    POP BC
    RET



; Subrotina para entrada de valor binário via teclado
; Entradas: 
; HL = posição onde será armazenado o valor de entrada
; D = indice de posição do dígito de entrada
; Registradores afetados

bin_input:
    PUSH DE
.test_key
    LD A,(RAM_KEYB_CONV)
    CP 00
    JR Z,.reset_bit
    CP 01
    JR Z,.set_bit
    POP DE
    RET
.set_bit
    LD E,(HL)
    LD A,D
    CP 00
    JR Z,.set_bit0
    CP 01
    JR Z,.set_bit1
    CP 02
    JR Z,.set_bit2
    CP 03
    JR Z,.set_bit3
    CP 04
    JR Z,.set_bit4
    CP 05
    JR Z,.set_bit5
    POP DE
    RET
.reset_bit
    LD E,(HL)
    LD A,D
    CP 00
    JR Z,.rst_bit0
    CP 01
    JR Z,.rst_bit1
    CP 02
    JR Z,.rst_bit2
    CP 03
    JR Z,.rst_bit3
    CP 04
    JR Z,.rst_bit4
    CP 05
    JR Z,.rst_bit5
    POP DE
    RET
.rst_bit0
    RES 0,E
    JR .end_bin_input
.rst_bit1
    RES 1,E
    JR .end_bin_input
.rst_bit2
    RES 2,E
    JR .end_bin_input
.rst_bit3
    RES 3,E
    JR .end_bin_input
.rst_bit4
    RES 4,E
    JR .end_bin_input
.rst_bit5
    RES 5,E
    JR .end_bin_input
.set_bit0
    SET 0,E
    JR .end_bin_input
.set_bit1
    SET 1,E
    JR .end_bin_input
.set_bit2
    SET 2,E
    JR .end_bin_input
.set_bit3
    SET 3,E
    JR .end_bin_input
.set_bit4
    SET 4,E
    JR .end_bin_input
.set_bit5
    SET 5,E
    JR .end_bin_input
.end_bin_input
    LD (HL),E
    POP DE
    RET



; Delay (operative, ms) for clk = 2 MHz ;
; Input: B = delay time (ms) 0,5% ;
; Affects registers A, B, F
delay_ms:
    PUSH AF
.delay_mult:
    LD A, B
    LD B, 152                ;Number of loops adjusted to A = delay ms with minimum error
.delay_1ms:
    DJNZ .delay_1ms
    LD B, A
    DJNZ .delay_mult
    POP AF
    RET

; Código dos caracteres para exibição no display em sequencia de endereços para facilitar a conversão numérica
;
;
d_numchar EQU $
    DB      0C0H                ; Caractere 0
    DB      0F9H                ; Caractere 1
    DB      0A4H                ; Caractere 2
    DB      0B0H                ; Caractere 3
    DB      099H                ; Caractere 4
    DB      092H                ; Caractere 5
    DB      082H                ; Caractere 6
    DB      0F8H                ; Caractere 7
    DB      080H                ; Caractere 8
    DB      090H                ; Caractere 9
    DB      088H                ; Caractere A
    DB      083H                ; Caractere B
    DB      0C6H                ; Caractere C
    DB      0A1H                ; Caractere D
    DB      086H                ; Caractere E
    DB      08EH                ; Caractere F

    DB      0FFH                ; Tecla especial 1
    DB      0FFH                ; Tecla especial 2
    DB      0FFH                ; Tecla especial 3
    DB      0FFH                ; Tecla especial 4
    DB      0FFH                ; Tecla especial 5
    DB      0FFH                ; Tecla especial 6
    DB      0FFH                ; Tecla especial 7
    DB      0FFH                ; Tecla especial 8



