[BITS 32]

section .rodata
GDT64:                           ; Global Descriptor Table (64-bit).
    .Null: equ $ - GDT64         ; The null descriptor.
    dw 0                         ; Limit (low).
    dw 0                         ; Base (low).
    db 0                         ; Base (middle)
    db 0                         ; Access.
    db 0                         ; Granularity.
    db 0                         ; Base (high).
    .Code: equ $ - GDT64         ; The code descriptor.
    dw 0                         ; Limit (low).
    dw 0                         ; Base (low).
    db 0                         ; Base (middle)
    db 10011010b                 ; Access (exec/read).
    db 00100000b                 ; Granularity.
    db 0                         ; Base (high).
    .Data: equ $ - GDT64         ; The data descriptor.
    dw 0                         ; Limit (low).
    dw 0                         ; Base (low).
    db 0                         ; Base (middle)
    db 10010010b                 ; Access (read/write).
    db 00000000b                 ; Granularity.
    db 0                         ; Base (high).
    .Pointer:                    ; The GDT-pointer.
    dw $ - GDT64 - 1             ; Limit.
    dq GDT64                     ; Base.

section .text
enter_ia32e:
	mov ecx, 0xC0000080	; Set the C-register to 0xC0000080, which is the EFER MSR.
	rdmsr			; Read from the model-specific register.
	or eax, 1 << 8		; Set the LM-bit which is the 9th bit (bit 8).
	wrmsr			; Write to the model-specific register.
	ret

enter_long_mode:
	call enable_pae
	call id_map_pse_64
	call enable_paging
	call enter_ia32e
	lgdt [GDT64.Pointer]	; Load the 64-bit global descriptor table.
	jmp GDT64.Code:return	; Return in 64-bit mode.
return:
	ret

