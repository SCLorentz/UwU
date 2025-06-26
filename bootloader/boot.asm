; execute usando: nasm -f bin boot.asm -o boot.img && qemu-system-x86_64 -drive format=raw,file=boot.img
; testes feitos com ajuda de AI para entender o funcionamento do bootloader e modo protegido

%macro print_pm 2
    ; %1 = string, %2 = posição de vídeo (ex: 0xb8000)
    mov esi, %1
    mov edi, %2
    mov ecx, 0
%%loop:
    mov al, [esi + ecx]
    or al, al
    jz %%done
    mov [edi + ecx*2], al
    mov byte [edi + ecx*2 + 1], 0x07
    inc ecx
    jmp %%loop
%%done:
%endmacro

[BITS 16]
[ORG 0x7C00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Mostrar mensagem
    mov si, msg_real
    call print_string

    ; Carregar GDT
    lgdt [gdt_descriptor]

    ; Ativar bit PE (Protection Enable)
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump para Protected Mode (limpa prefetch queue)
    jmp CODE_SEG:protected_mode_entry

; ---------------- Modo protegido ----------------

[BITS 32]
protected_mode_entry:
    ; Atualiza os registradores de segmento
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Configura pilha
    mov esp, 0x90000

    ; Mensagem modo protegido
    print_pm msg_prot, 0xb8000

    ; Loop infinito
.hang:
    hlt
    jmp .hang

; ---------------- Funções modo real ----------------
print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

; ---------------- GDT ----------------
gdt_start:
    ; null descriptor
    dq 0x0000000000000000

    ; code segment descriptor: base=0, limit=4GB, type=code
    dq 0x00CF9A000000FFFF

    ; data segment descriptor: base=0, limit=4GB, type=data
    dq 0x00CF92000000FFFF

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; ---------------- Constantes ----------------
CODE_SEG equ 0x08
DATA_SEG equ 0x10

msg_real db "Modo real: entrando em modo protegido...", 0
msg_prot db "Modo protegido ativado!!", 0

; Fill the rest of the boot sector with zeros (512b)
times 510-($-$$) db 0
    dw 0xAA55           ; Assinatura de boot (0xAA55) no final do setor de boot