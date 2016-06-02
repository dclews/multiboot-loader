extern crate nasm;

use std::env;
use std::fs::{File, copy, create_dir_all};
use std::io::Write;

fn main() {
    let target = env::var("TARGET").unwrap();

    let out_dir = env::var("OUT_DIR").unwrap();
    let mut nasm_files: Vec<&str> = Vec::new();
    let mut defines: Vec<&str> = Vec::new();
    nasm_files.push("multiboot_loader.nasm");


    if env::var("CARGO_FEATURE_LONG_MODE").is_ok() {
       defines.push("LONG_MODE"); 
    }

    nasm::compile_library("multiboot_loader", nasm_files.as_slice(), nasm::BuildType::STATIC, defines.as_slice());
    println!("cargo:rustc-link-search=native={}", out_dir);
    println!("cargo:rustc-link-lib=static={}", "multiboot_loader");
}
