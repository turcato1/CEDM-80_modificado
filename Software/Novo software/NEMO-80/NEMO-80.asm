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
ROMBEGIN        EQU 0000H
ROMSIZE         EQU 800H

; RAM first address and size (2 KiB = 2048 bytes, 2000H ~ 27FFH)
RAMBEGIN        EQU 2000H
RAMSIZE         EQU 800H

; Constants
CHR_0           EQU 0C0H
CHR_1           EQU 0F9H
CHR_2           EQU 0A4H
CHR_3           EQU 0B0H
CHR_4           EQU 099H
CHR_5           EQU 092H
CHR_6           EQU 082H
CHR_7           EQU 0F8H
CHR_8           EQU 080H
CHR_9           EQU 090H
CHR_A           EQU 088H
CHR_B           EQU 083H
CHR_C           EQU 0C6H
CHR_D           EQU 0A1H
CHR_E           EQU 086H
CHR_F           EQU 08EH


; I/O addresses
DISP            EQU 01H
SEL_DISP        EQU 03H
KEYB            EQU 01H

; RESERVADO PARA SISTEMA: END. 2600H ~ 27FF

; RAM para sistema até 27FF
RAM_SYS_START   EQU 2600H    ; Inicio da área de RAM reservada para sistema

RAM_DRAFT1      EQU 2766H    ; Área de rascunho para as subrotinas      
RAM_DRAFT2      EQU 2767H    ; Área de rascunho para as subrotinas
RAM_DRAFT3      EQU 2768H    ; Área de rascunho para as subrotinas
RAM_DRAFT4      EQU 2769H    ; Área de rascunho para as subrotinas
RAM_DRAFT5      EQU 276AH    ; Área de rascunho para as subrotinas
RAM_DRAFT6      EQU 276BH    ; Área de rascunho para as subrotinas
RAM_DRAFT7      EQU 276CH    ; Área de rascunho para as subrotinas
RAM_KEYB_CONV   EQU 276DH    ; Código da tecla pressionada já decodificado de 00 a 17 (24 teclas)
RAM_KEYBOARD    EQU 276EH    ; Valor binário na matriz da tecla pressionada
RAM_KEYB_COL    EQU 276FH    ; Coluna selecionada na varredura do teclado
RAM_DISPLAY     EQU 2770H    ; Caracteres a serem exibidos no display pos. 2770H a 2775H

; Stack = 2780H a 27FFH
RAM_STACK_0     EQU 2780H
RAM_STACK_127   EQU 27FFH

; Variáveis do programa, do endereço 25FF para trás (128 bytes)
VAR_VALUE_INS   EQU 25FEH
VAR_VALUE_IN    EQU 25FFH


;******** Beggining of monitor program ********
    ORG ROMBEGIN

; ********************** Programa principal ********************** 
; Ajustes e configuração iniciais
    LD SP, 27FFH                ; Ajusta o stack pointer no fim da memória RAM. Considerado 128 bytes de stack 2780 até 27FF

; Inicializações antes do programa
initialization:
    CALL sys_clean_ram_disp     ; Limpa a memória de exibição no display
    LD A,00H
    LD (VAR_VALUE_IN),A
    LD (VAR_VALUE_INS),A

    ; LD A,CHR_1
    ; LD (RAM_DISPLAY),A
    ; LD A,CHR_2
    ; LD (RAM_DISPLAY+1),A
    ; LD A,CHR_3
    ; LD (RAM_DISPLAY+2),A
    ; LD A,CHR_4
    ; LD (RAM_DISPLAY+3),A
    ; LD B,070H

; Inicio do programa
ini_program:
    LD HL,VAR_VALUE_INS
    CALL sys_in_addr
    CALL sys_clean_ram_disp
    LD A,(VAR_VALUE_INS)
    LD L,A
    LD A,(VAR_VALUE_IN)
    LD H,A
    INC HL
    INC HL
    LD A,L
    LD (VAR_VALUE_INS),A
    LD A,H
    LD (VAR_VALUE_IN),A
prg_loop:
    LD HL,VAR_VALUE_INS
    CALL sys_disp_addr
    JR prg_loop
    JP ini_program


    DB 0H,"SUBROUTINES",0H
; ********************** Subroutines ********************** 
;

; Subrotina de limpeza da area de memoria para o display
;
sys_clean_ram_disp:                 ;Inicializa area de memoria do display
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
    DB 00H

; Subrotina de exibição de dados no campo de endereço (sys_in_addr)
; HL (e HL+1) = posição de memória onde está o dado a ser exibido
sys_disp_addr:
    PUSH BC
    PUSH DE
    LD DE,RAM_DISPLAY+3
    CALL _sys_mem_conv2nibbles
    INC HL
    LD DE,RAM_DISPLAY+1
    CALL _sys_mem_conv2nibbles
    POP DE
    POP BC
    CALL sys_keyb_disp
    RET

; Subrotina auxiliar das subrotinas de exibição no display
; Converte 2 nibbles de uma posição de memória em 2 bytes para exibição no display
; HL - Posição de entrada do dado a ser separado em nibbles
; DE - Posição mais alta para escrita dos dados convertidos para display
_sys_mem_conv2nibbles
    LD A,(HL)
    AND 0FH
    CALL sys_conv_hexdisp
    LD A,C
    LD (DE),A
;    LD (RAM_DISPLAY+3),A
    DEC DE
    LD A,(HL)
    SRL A
    SRL A
    SRL A
    SRL A
    CALL sys_conv_hexdisp
    LD A,C
    LD (DE),A
;    LD (RAM_DISPLAY+2),A
    RET
    DB 00H

; Subrotina de entrada de dados no campo de endereço (sys_in_addr)
; O software fica preso nessa rotina até que uma tecla de 10 a 17 seja pressionada
; HL: Definição da primeira área de memória para uso com a entrada de dados
;    (4 dígitos, sequencia little endian)
; Teclas de 0 a F = serão reproduzidas no display e atualizam o valor em (HL)
; Teclas de 10 a 17 = encerram o loop da subrotina, tecla pressionada em RAM_KEYB_CONV
;       If !(keypress.bit7) then RST keyprsmem.bit7
;       If  (keypress.bit7) &&  (keyprsmem.bit7) then end
;       If  (keypress.bit7) && !(keyprsmem.bit7) then SET keyprsmem.bit7 and process the input
sys_in_addr:
    PUSH BC                     ; Guarda na pilha valor atual de BC para poder usar BC na subrotina
    CALL sys_clean_ram_disp     ; Limpa a memória de exibição no display
    LD A,00H
    LD (RAM_DRAFT1),A
.in_input_loop:
    CALL sys_keyb_disp          ; Chama atualização do display e teclado
    LD A,(RAM_KEYB_CONV)        ; Recupera tecla atualmente pressionada (keypress = RAM_KEYB_CONV)
    BIT 7,A                     ; Testa bit 7 de RAM_KEYB_CONV para verificar se alguma tecla está pressionada (keypress.bit7)
    JR Z,.in_reset_keyprsmem    ; Bit 7 keypress é zero (tecla solta): reseta bit 7 memória (keypressmem)
    LD A,(RAM_DRAFT1)           ; Recupera memória de tecla pressionada (keyprsmem)
    BIT 7,A                     ; Testa bit 7, sinalizador de tecla pressionada anteriormente (keyprsmem.bit7)
    JR NZ,.in_input_loop        ; bit 7 memória não zero (setado): não faz nada, finaliza a subrotina
    SET 7,A                     ; Seta bit 7 e segue com o processamento da tecla pressionada
    LD (RAM_DRAFT1),A           ; Salva na memória de tecla pressionada (keyprsmem), que há uma tecla pressionada (bit 7 setado)
    LD A,(RAM_KEYB_CONV)        ; Recupera tecla atualmente pressionada (keypress = RAM_KEYB_CONV)
    RES 7,A
    CP 10H
    JR C,.in_num_key
    JR .in_addr_end
.in_num_key:
    CALL sys_conv_hexdisp       ; Converte o código da tecla hex (= A) em código de exibição correspondente no display -> C
    CALL sys_shift_disp_left    ; Desloca no display 1 dígito para esquerda e acrescenta novo dígito contido em C
                                ; Atualização do valor na variável apontada por HL, suponha dado 16 bits = "WX YZ"
    LD C,A                      ; Guarda o valor digitado em C para poder usar o A, suponha valor digitado = "0K"
    INC HL                      ; Vai para a parte mais significativa dos 16 bits
    LD A,(HL)                   ; Lê o dado da parte mais significativa -> "WX"
    SLA A                       ; Desloca parte mais significativa para esquerda -> "X0"
    SLA A
    SLA A
    SLA A
    LD B,A                      ; Guarda valor deslocado em B -> B = "X0"
    DEC HL                      ; Coloca ponteiro na parte menos significativa
    LD A,(HL)                   ; Lê o dado da parte menos significativa -> A = "YZ"
    SRL A                       ; Desloca parte menos significativa para direita -> A = "0Y"
    SRL A
    SRL A
    SRL A
    OR B                        ; Combina partes deslocadas A e B -> "X0" OR "0Y" = "XY"
    INC HL                      ; Coloca ponteiro na parte mais significativa
    LD (HL),A                   ; Guarda valor combinado na parte mais significativa -> (HL) = "XY"
    DEC HL                      ; Coloca ponteiro na parte menos significativa
    LD A,(HL)                   ; Lê o dado da parte menos significativa -> A = "YZ"
    SLA A                       ; Desloca parte menos significativa para esquerda -> A = "Z0"
    SLA A
    SLA A
    SLA A
    OR C                        ; Combina valor digitado com valor deslocado -> "Z0" OR "0K" = "ZK"
    LD (HL),A                   ; Guarda valor combinado na parte menos significativa. Resultado final = "XYZK"
    JR .in_input_loop
.in_reset_keyprsmem:
    LD A,(RAM_DRAFT1)           ; HL contém a posição de memória da variável de sistema
    RES 7,A                     ; Reseta o bit 7, sinalizador de tecla pressionada anteriormente
    LD (RAM_DRAFT1),A           ; Grava de volta na memória de sinalização de tecla pressionada anteriormente
    JR .in_input_loop
.in_addr_end:
    POP BC                      ; Recupera registrador BC
    RET
    DB 00H

; Subrotina que converte um digito hexadecimal para exibição no display (_conv_hexdisp)
; A = num. hexadecimal 1 dígito
; C = retorna o valor para exibição no display
sys_conv_hexdisp:
    PUSH AF
    PUSH BC
    PUSH HL
    AND 0FH                     ; Isola o nibble menos significativo do código da tecla
    LD C,A
    LD B,00H
    LD HL,DB_NUMCHAR
    ADD HL,BC
    LD A,(HL)
    POP HL
    POP BC
    LD C,A
    POP AF
    RET
    DB 00H

; Sub-subrotina de deslocamento da memória do display (RAM_DISPLAY) em 1 dígito para esquerda
; C = valor a ser inserido
sys_shift_disp_left:
    PUSH HL
    PUSH DE
    PUSH BC
    LD HL,RAM_DISPLAY
    LD D,H
    LD E,L
    INC HL
    LD C,03
    LD B,00
    LDIR
    INC DE
    POP BC
    PUSH AF
    DEC HL
    LD A,C
    LD (HL),A
    POP AF
    POP DE
    POP HL
    RET
    DB 00H

; Subrotina de atualização do display/teclado (sys_keyb_disp)
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
sys_keyb_disp:
    PUSH BC
    PUSH HL
    LD A,00                     
    LD (RAM_KEYB_CONV),A        ; Limpa variável de memória do teclado antes de ler o teclado
    LD A,01H                    ; Ajusta A para apontar para a primeira coluna de displays (mais significativa) 
    LD HL,RAM_DISPLAY           ; Carrega no ponteiro HL primeiro endereço da RAM de sistema para o display
.keyb_disp_loop:
    OUT (SEL_DISP),A            ; Seleciona display apontado por A
    LD C,A                      ; Guarda o valor de A
    LD A,0FFH    
    OUT (DISP),A
    ;LD B, 1
    ;CALL sys_delay_ms
    IN A,(KEYB)                 ; Lê o teclado na coluna atual
    CP 00
    JR Z,.wr_display            ; Se nada foi lido do teclado (nenhuma tecla apertada), vai para a atualização do display direto
    LD (RAM_KEYBOARD),A         ; Se algo foi lido do teclado, registra tecla para a coluna atual
    LD A,C                      ; Recupera dado de qual coluna está sendo atualizada
    LD (RAM_KEYB_COL),A         ; Registra na memória de qual coluna é a tecla apertada
.keyb_disp_cnv:
    LD A,(RAM_KEYBOARD)         ; Converte posição da tecla no valor correspondente que representa (função da tecla)
    CP 01                       ; Não foi considerada ainda a coluna nesse ponto
    JP Z,.keyb_disp_num_0
    CP 02
    JP Z,.keyb_disp_num_1
    CP 04
    JP Z,.keyb_disp_num_2
    CP 08
    JP Z,.keyb_disp_num_3
    CP 16
    JP Z,.keyb_disp_num_4
    CP 32
    JP Z,.keyb_disp_num_5
    CP 64
    JP Z,.keyb_disp_num_6
    CP 128
    JP Z,.keyb_disp_num_7
    RET
.keyb_disp_num_0:
    LD A,00H
    LD B,A
    JR .keyb_col
.keyb_disp_num_1:
    LD A,01H
    LD B,A
    JR .keyb_col
.keyb_disp_num_2:
    LD A,02H
    LD B,A
    JR .keyb_col
.keyb_disp_num_3:
    LD A,03H
    LD B,A
    JR .keyb_col
.keyb_disp_num_4:
    LD A,04H
    LD B,A
    JR .keyb_col
.keyb_disp_num_5:
    LD A,05H
    LD B,A
    JR .keyb_col
.keyb_disp_num_6:
    LD A,06H
    LD B,A
    JR .keyb_col
.keyb_disp_num_7:
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
    CALL sys_delay_ms
    INC HL
    LD A,C
    ADD A,A
    CP 64
    JP NZ, .keyb_disp_loop      ; Se não chegou na última coluna de atualização do display (64), vai para o próximo loop
    POP HL
    POP BC
    RET
    DB 00H

; Delay (operative, ms) for clk = 2 MHz (sys_delay_ms);
; Input: B = delay time (ms) 0,5% ;
; Affects registers A, B, F
sys_delay_ms:
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
    DB 00H

; Código dos caracteres para exibição no display em sequencia de endereços para facilitar a conversão numérica
DB_NUMCHAR EQU $
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
