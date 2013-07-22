ARCH		= $(shell uname -m | sed s,i[3456789]86,ia32,)
LIB_PATH	= /usr/lib64

EFI_INCLUDE	= /usr/include/efi
EFI_INCLUDES	= -nostdinc -I$(EFI_INCLUDE) -I$(EFI_INCLUDE)/$(ARCH) -I$(EFI_INCLUDE)/protocol
EFI_PATH	= /usr/lib64/gnuefi

LIB_GCC		= $(shell $(CC) -print-libgcc-file-name)
EFI_LIBS	= -lefi -lgnuefi $(LIB_GCC) 

EFI_CRT_OBJS 	= $(EFI_PATH)/crt0-efi-$(ARCH).o
EFI_LDS		= $(EFI_PATH)/elf_$(ARCH)_efi.lds

CFLAGS		= -ggdb -O0 -fno-stack-protector -fno-strict-aliasing -fpic \
		  -fshort-wchar -Wall -mno-red-zone -maccumulate-outgoing-args \
		  -mno-mmx -mno-sse \
		  $(EFI_INCLUDES)
ifeq ($(ARCH),x86_64)
	CFLAGS	+= -DEFI_FUNCTION_WRAPPER -DGNU_EFI_USE_MS_ABI
endif

LDFLAGS		= -nostdlib -znocombreloc -T $(EFI_LDS) -shared -Bsymbolic -L$(EFI_PATH) -L$(LIB_PATH) $(EFI_CRT_OBJS)

INSTALL		= install

VERSION		= 0.1

TARGET	= module.efi
OBJS	= module.o
SOURCES	= module.c

all: $(TARGET) pewrap

pewrap : pewrap.in
	sed "s/@@VERSION@@/$(VERSION)/g" pewrap.in > pewrap

module.o: $(SOURCES)

module.so: $(OBJS)
	$(LD) -o $@ $(LDFLAGS) $^ $(EFI_LIBS)
	@chmod -x $@

%.efi: %.so
	objcopy -j .text -j .sdata -j .data \
		-j .dynamic -j .dynsym  -j .rel \
		-j .rela -j .reloc -j .eh_frame \
		-j .vendor_cert \
		--target=efi-app-$(ARCH) $^ $@
	@chmod -x $@

clean:
	rm -rf $(TARGET) $(OBJS)
	rm -f *.debug *.so *.efi pewrap

install:
	$(INSTALL) -d -m 755 /usr/share/pewrap
	$(INSTALL) -m 644 module.efi /usr/share/pewrap/module.efi
	$(INSTALL) -d -m 755 /usr/bin
	$(INSTALL) -m 755 pewrap /usr/bin/pewrap

GITTAG = $(VERSION)

test-archive:
	@rm -rf /tmp/pewrap-$(VERSION) /tmp/pewrap-$(VERSION)-tmp
	@mkdir -p /tmp/pewrap-$(VERSION)-tmp
	@git archive --format=tar $(shell git branch | awk '/^*/ { print $$2 }') | ( cd /tmp/pewrap-$(VERSION)-tmp/ ; tar x )
	@git diff | ( cd /tmp/pewrap-$(VERSION)-tmp/ ; patch -s -p1 -b -z .gitdiff )
	@mv /tmp/pewrap-$(VERSION)-tmp/ /tmp/pewrap-$(VERSION)/
	@dir=$$PWD; cd /tmp; tar -c --bzip2 -f $$dir/pewrap-$(VERSION).tar.bz2 pewrap-$(VERSION)
	@rm -rf /tmp/pewrap-$(VERSION)
	@echo "The archive is in pewrap-$(VERSION).tar.bz2"

archive:
	git tag $(GITTAG) refs/heads/master
	@rm -rf /tmp/pewrap-$(VERSION) /tmp/pewrap-$(VERSION)-tmp
	@mkdir -p /tmp/pewrap-$(VERSION)-tmp
	@git archive --format=tar $(GITTAG) | ( cd /tmp/pewrap-$(VERSION)-tmp/ ; tar x )
	@mv /tmp/pewrap-$(VERSION)-tmp/ /tmp/pewrap-$(VERSION)/
	@dir=$$PWD; cd /tmp; tar -c --bzip2 -f $$dir/pewrap-$(VERSION).tar.bz2 pewrap-$(VERSION)
	@rm -rf /tmp/pewrap-$(VERSION)
	@echo "The archive is in pewrap-$(VERSION).tar.bz2"
