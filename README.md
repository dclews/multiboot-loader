# multiboot-loader
Simply include in Cargo.toml, ensure that the .multiboot section is in the first 8KB of the kernel and provide these entry points:
* multiboot1_entry(multiboot_info*)
* multiboot2_entry(multiboot2_info*)
