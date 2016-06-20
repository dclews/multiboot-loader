[BITS 32]
section .text
putstr_hang:
	call putstr
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

