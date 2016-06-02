ENTRY(start)

SECTIONS
{
	. = 1M;
	.text BLOCK(4K) : ALIGN(4K)
	{
		KEEP(*(.multiboot))	
		*(.text)
		LD_TEXT_END = .;
	}
	.rodata BLOCK(4K) : ALIGN(4K)
	{
		*(.rodata)
		LD_RODATA_END = .;
	}
	.data BLOCK(4K) : ALIGN(4K)
	{
		*(.data)
		LD_DATA_END = .;
	}
	.bss BLOCK(4K) : ALIGN(4K)
	{
		*(COMMON)
		*(.bss)
		KEEP(*(.bootstrap_stack))
		LD_BSS_END = .;
	}
}
