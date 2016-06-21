[BITS 32]
section .bss
global pml4
pml4:
resb 4096 ; [512*u64]
global pdp
pdp:
resb 4096 ; [512*u64]
global pd
pd:
resb 4096 ; [512*u64]
global pt
pt:
resb 4096 ; [512*u64]

section .text
enable_pae:
	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax
	ret

id_map_pse_64:
	; Mapping 2MB is simple with PSE+PAE as it can be handled by one PDE.
	; PML4[0] -> PDP[0]
	mov eax, pdp
	or eax, 0b11 ; Set as present and writable.
	mov [pml4], eax

	; PDP[0] -> PD[0]
	mov eax, pd
	or eax, 0b11 ; Set as P+W
	mov [pdp], eax

	; PD[0] -> PT[0]
	mov eax, 0b10000011 ; Set as P+W+4M
	mov [pd], eax
	ret

load_pml4:
	mov eax, pml4
	mov cr3, eax
	ret

enable_paging:
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax
	ret
