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
	call id_map_pse_64
	call load_pml4
	call enable_pae
	call enter_ia32e
	call enable_paging
	lgdt [GDT64.Pointer]	; Load the 64-bit global descriptor table.
	jmp GDT64.Code:set_long_mode_segment_selectors ; Return in 64-bit mode.

set_long_mode_segment_selectors:
	mov ax, GDT64.Data	; Set the A-register to the data descriptor.
	mov ds, ax		; Set the data segment to the A-register.
	mov es, ax		; Set the extra segment to the A-register.
	mov fs, ax		; Set the F-segment to the A-register.
	mov gs, ax		; Set the G-segment to the A-register.
	mov ss, ax		; Set the stack segment to the A-register.
	jmp select_entry_64	; Can't ret as we have a new SS
