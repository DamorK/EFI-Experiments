cmake_minimum_required(VERSION 3.13)
project(efi-app-skeleton)

add_library(app SHARED main.c)

target_include_directories(app PRIVATE
    /usr/include/efi
    /usr/include/efi/x86_64
)

target_compile_definitions(app PRIVATE
    EFI_FUNCTION_WRAPPER
)

target_compile_options(app PRIVATE
    -fpic
    -fno-stack-protector
    -fno-stack-check
    -fshort-wchar
    -mno-red-zone
)

target_link_options(app PRIVATE
    -shared
    -nostdlib
    -znocombreloc
    -Wl,-Bsymbolic
    -T /usr/lib/elf_x86_64_efi.lds
    /usr/lib/crt0-efi-x86_64.o
)

target_link_libraries(app PRIVATE
    gnuefi
    efi
)

add_custom_target(app-final ALL
    COMMAND objcopy -j .text
                    -j .sdata
                    -j .data
                    -j .dynamic
                    -j .dynsym
                    -j .rel
                    -j .rela
                    -j .reloc
                    --target=efi-app-x86_64
                    $<TARGET_FILE:app>
                    app.efi
    DEPENDS app
)
