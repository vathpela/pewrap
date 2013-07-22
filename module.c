#include <efi.h>
#include <efilib.h>

EFI_STATUS
efi_main (EFI_HANDLE image_handle, EFI_SYSTEM_TABLE *systab)
{
	InitializeLib(image_handle, systab);
	Print(L"This program contains a list of public keys.\n");
	return EFI_SUCCESS;
}

uint8_t pubkey[] __attribute__ ((__section__(".keylist"))) = "" ;
