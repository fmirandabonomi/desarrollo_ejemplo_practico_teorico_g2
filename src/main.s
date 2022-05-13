.syntax unified
.cpu cortex-m3
.fpu softvfp
.thumb


.section .text.main
.global main
.type main, %function
main:
    // Configurar puertos
    bl configura_puertos
    // lazo infinito
0:
    bl espera_flanco_ascendente
    bl pulsa_led_200ms
    b 0b
.size main, . - main

.set RCC_base,0x40021000
.set RCC_APB2ENR,0x18 // offset
.set IOPBEN_mask,(1<<3)
.set IOPCEN_mask,(1<<4)

.set GPIOB_base,0x40010C00
.set GPIOC_base,0x40011000
.set GPIO_CRH, 0x04
.set CRH_PIN10_mask, (0xF << (4*(10-8)))
.set CRH_PIN10_ENTRADA_PR, (0b1000 << (4*(10-8)))
.set CRH_PIN13_mask, (0xF << (4*(13-8)))
.set CRH_PIN13_SALIDA_2MHZ_PP, (0b0010 << (4*(13-8)))
.set GPIO_BSRR, 0x10
.set GPIO_BRR, 0x14
.set PIN10_mask, (1<<10)
.set PIN13_mask, (1<<13)
.set GPIO_IDR, 0x08 

.text
configura_puertos:
    // Habilito reloj puertos usados
    ldr R0,=RCC_base
    ldr R1,[R0,#RCC_APB2ENR]
    orrs R1,#(IOPBEN_mask | IOPCEN_mask)
    str R1,[R0,#RCC_APB2ENR]
    // Config. PB10 entrada, flotante
    ldr R0,=GPIOB_base
    ldr R1,[R0,#GPIO_CRH]
    bics R1,#CRH_PIN10_mask
    orrs R1,#CRH_PIN10_ENTRADA_PR
    str R1,[R0,#GPIO_CRH]
    // Config. PC13 salida (inicia en 1), push-pull, 2MHz
    ldr R0,=GPIOC_base
    movs R1,#PIN13_mask
    str R1,[R0,#GPIO_BSRR]
    ldr R1,[R0,#GPIO_CRH]
    bics R1,#CRH_PIN13_mask
    orrs R1,#CRH_PIN13_SALIDA_2MHZ_PP
    str R1,[R0,#GPIO_CRH]
    bx lr

espera_flanco_ascendente:
    ldr R0,=GPIOB_base
    // espera PB10 = 0
0:
    ldr R1,[R0,#GPIO_IDR]    
    tst R1,#PIN10_mask
    bne 0b
    // espera PB10 = 1 
0:
    ldr R1,[R0,#GPIO_IDR]    
    tst R1,#PIN10_mask
    beq 0b
    bx lr

.set ITERACIONES_ESPERA, (200*8000)/3
pulsa_led_200ms:
    ldr R0,=GPIOC_base
    // enciende led
    movs R1,#PIN13_mask
    str R1,[R0,#GPIO_BRR]
    // espera 200ms
    // Cada iteración: 3 ciclos
    ldr R1,=ITERACIONES_ESPERA
0:
    subs R1,#1 // 1 ciclo
    bne 0b // branch: 2 ciclos
    // apaga led
    movs R1,#PIN13_mask
    str R1,[R0,#GPIO_BSRR]
    bx lr