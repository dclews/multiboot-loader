[BITS 32]
%include "src/string.nasm"
%include "src/x86_64.nasm"
%include "src/paging.nasm"
%include "src/multiboot.nasm"


section .rodata
unknown_boot_str:
db 'Jumping to unknown_bootloader_entry',0
hang_str:
db 'Hanging',0
no_cpuid_str:
db 'No CPUID available',0

section .bootstrap_stack
stack_bottom:
times 16384 db 0; 16KB stack
stack_top:

section .text
extern unknown_bootloader_entry

global start
start:
	mov esp, stack_top
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
	je select_pmode

	; test if extended processor info is available
	pushad
	mov eax, 0x80000000    ; implicit argument for cpuid
	cpuid                  ; get highest supported argument
	cmp eax, 0x80000001    ; it needs to be at least 0x80000001
	jb select_pmode       ; if it's less, the CPU is too old for long mode

	; use extended info to test if long mode is available
	mov eax, 0x80000001    ; argument for extended processor info
	cpuid                  ; returns various feature bits in ecx and edx
	test edx, 1 << 29      ; test if the LM-bit is set in the D-register
	jz select_pmode       ; If it's not set, there is no long mode

select_long_mode:
	call enable_pae
	call id_map_pse_64
	call enable_paging
	call enter_ia32e
	call enter_long_mode
	popad
	jmp select_entry

select_pmode:
	popad
	jmp select_entry

select_entry:
	cmp eax, MB1_LOADER_ID
	je boot_mb1

	cmp eax, MB2_MAGIC
	je boot_mb2

	mov eax, unknown_boot_str
	call putstr
	call unknown_bootloader_entry ; ()

hang:
	cli
hang_loop:
	hlt
	jmp hang_loop


