[BITS 32]

section .multiboot
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

section .bootstrap_stack
stack_bottom:
times 16384 db 0; 16KB stack
stack_top:

section .text
extern unknown_bootloader_entry

global start
start:
	mov esp, stack_top
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
