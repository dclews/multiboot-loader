[BITS 32]

MB1_ALIGN equ 1<<0 ; align loaded modules on page boundaries
MB1_MEMINFO equ 1<<1 ; provide memory map
MB1_VBEINFO equ 1<<2 ; provide video mode information

MB1_FLAGS equ MB1_ALIGN | MB1_MEMINFO | MB1_VBEINFO
MB1_MAGIC equ 0x1BADB002
MB1_CHECKSUM equ -(MB1_MAGIC + MB1_FLAGS)

MB1_LOADER_ID equ 0x2BADB002

; Use EGA text mode.
MB1_MODE_TYPE equ 1
MB1_WIDTH equ 80
MB1_HEIGHT equ 50
MB1_DEPTH equ 0 ; Depth is 0 in text mode.

; Use VGA linear framebuffer mode.
;MB1_MODE_TYPE equ 0
;MB1_WIDTH equ 1024
;MB1_HEIGHT equ 768
;MB1_DEPTH equ 256

; Ignored until flags[2] is enabled.
MB1_HEADER_ADDR equ 0
MB1_LOAD_ADDR equ 0
MB1_LOAD_END_ADDR equ 0
MB1_BSS_END_ADDR equ 0
MB1_ENTRY_ADDR equ 0

section .multiboot
multiboot_header:
align 4
	dd MB1_MAGIC
	dd MB1_FLAGS
	dd MB1_CHECKSUM
	dd MB1_HEADER_ADDR
	dd MB1_LOAD_ADDR
	dd MB1_LOAD_END_ADDR
	dd MB1_BSS_END_ADDR
	dd MB1_ENTRY_ADDR
	dd MB1_MODE_TYPE
	dd MB1_WIDTH
	dd MB1_HEIGHT
	dd MB1_DEPTH

MB2_MAGIC equ 0xE85250D6
MB2_ELF_SHX_FLAG equ 0x20
MB2_FLAGS equ MB2_ELF_SHX_FLAG

multiboot2_header:
	dd MB2_MAGIC
	dd MB2_FLAGS
	dd multiboot2_header_end - multiboot2_header
	dd -(MB2_MAGIC + MB2_FLAGS + (multiboot2_header_end - multiboot2_header))

;	dw 0
;	dw 0
;	dw 8
multiboot2_header_end:

section .rodata
hello:
db 'hello',0

section .bootstrap_stack
stack_bottom:
times 16384 db 0; 16KB stack
stack_top:

section .text
extern unknown_bootloader_entry

global start
start:
	mov esp, stack_top
	call check_cpuid
	call setup_mode
	mov eax, hello
	call putstr
	jmp hang
	;call select_entry
check_cpuid:
	; Check if CPUID is supported by attempting to flip the ID bit (bit 21)
	; in the FLAGS register. If we can flip it, CPUID is available.
	pushad

	; Copy FLAGS in to EAX via stack
	pushfd
	pop eax

	; Store in ECX so we can compare it later.
	mov ecx, eax

	; Flip the ID bit.
	xor eax, 1 << 21

	; Copy EAX to FLAGS via the stack.
	push eax
	popfd

	; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
	pushfd
	pop eax

	; Restore FLAGS from the old version stored in EXC
	push ecx
	popfd

	;; Compare EAX and ECX.  If they are equal than CPUID is not supported.
	cmp eax, ecx
	je no_cpuid

	popad
	ret
no_cpuid:
	mov al, "1"
	jmp error

; Source: http://os.phil-opp.com/entering-longmode.html
setup_mode:
	; test if extended processor info in available
	pushad
	mov eax, 0x80000000    ; implicit argument for cpuid
	cpuid                  ; get highest supported argument
	cmp eax, 0x80000001    ; it needs to be at least 0x80000001
	jb mode_selected       ; if it's less, the CPU is too old for long mode

	; use extended info to test if long mode is available
	mov eax, 0x80000001    ; argument for extended processor info
	cpuid                  ; returns various feature bits in ecx and edx
	test edx, 1 << 29      ; test if the LM-bit is set in the D-register
	jz mode_selected       ; If it's not set, there is no long mode

mode_selected:
	popad
	ret

select_entry:
	cmp eax, MB1_LOADER_ID
	je boot_mb1
	
	cmp eax, MB2_MAGIC
	je boot_mb2

	call unknown_bootloader_entry ; ()
hang:
	cli

hang_loop:
	hlt
	jmp hang_loop

; Source: http://os.phil-opp.com/entering-longmode.html
; Prints `ERR: ` and the given error code to screen and hangs.
; parameter: error code (in ascii) in al
error:
	mov dword [0xb8000], 0x4f524f45
	mov dword [0xb8004], 0x4f3a4f52
	mov dword [0xb8008], 0x4f204f20
        mov byte  [0xb800a], al
	jmp hang

; str@eax
putstr:
	pushad
	mov edi, 0xb8000
putchar:
	mov byte bl, [eax] ; Move str[eax] into bl 
	cmp bl, 0
	je putstr_done
	mov byte [edi], bl ; Store bl ([str[eax], 0]) in vmem.
	add edi, 2
	inc eax
	jmp putchar
putstr_done:
	popad
	ret

extern multiboot1_entry
boot_mb1:
	push ebx ; push multiboot information
	call multiboot1_entry ; (multiboot1_information_raw)
	jmp hang

extern multiboot2_entry
boot_mb2:
	push ebx ; push multiboot information
	call multiboot2_entry ; (multiboot2_information_raw)
	jmp hang
