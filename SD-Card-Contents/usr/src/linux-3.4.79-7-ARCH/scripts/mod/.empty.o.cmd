cmd_scripts/mod/empty.o := gcc -Wp,-MD,scripts/mod/.empty.o.d  -nostdinc -isystem /usr/lib/gcc/armv7l-unknown-linux-gnueabihf/4.8.2/include -I/build/linux-sun7i/src/linux-sunxi-8ea347bcb4b4a5e50ec0343afac579e933ce8402/arch/arm/include -Iarch/arm/include/generated -Iinclude  -include /build/linux-sun7i/src/linux-sunxi-8ea347bcb4b4a5e50ec0343afac579e933ce8402/include/linux/kconfig.h -D__KERNEL__ -mlittle-endian -Iarch/arm/mach-sun7i/include -Iarch/arm/plat-sunxi/include -Wall -Wundef -Wstrict-prototypes -Wno-trigraphs -fno-strict-aliasing -fno-common -Werror-implicit-function-declaration -Wno-format-security -fno-delete-null-pointer-checks -Os -marm -fno-dwarf2-cfi-asm -mabi=aapcs-linux -mno-thumb-interwork -funwind-tables -D__LINUX_ARM_ARCH__=7 -march=armv7-a -msoft-float -Uarm -Wframe-larger-than=1024 -fno-stack-protector -Wno-unused-but-set-variable -fomit-frame-pointer -Wdeclaration-after-statement -Wno-pointer-sign -fno-strict-overflow -fconserve-stack -DCC_HAVE_ASM_GOTO    -D"KBUILD_STR(s)=\#s" -D"KBUILD_BASENAME=KBUILD_STR(empty)"  -D"KBUILD_MODNAME=KBUILD_STR(empty)" -c -o scripts/mod/empty.o scripts/mod/empty.c

source_scripts/mod/empty.o := scripts/mod/empty.c

deps_scripts/mod/empty.o := \

scripts/mod/empty.o: $(deps_scripts/mod/empty.o)

$(deps_scripts/mod/empty.o):