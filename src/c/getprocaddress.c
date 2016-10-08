unsigned int __cdecl GetAddress(char *szFunctionName, unsigned int dwFunctionLen);

typedef unsigned int(__stdcall *pfnGetProcAddress)(void *, const char *);
typedef void *(__stdcall *pfnLoadLibrary)(const char *);
typedef int (__stdcall *pfnMessageBox)(void *, const char *, const char *, unsigned int);

int main(void) {
	pfnGetProcAddress fnGetProcAddress;
	fnGetProcAddress = (pfnGetProcAddress)GetAddress("GetProcAddress", 14);

	pfnLoadLibrary fnLoadLibrary;
	fnLoadLibrary = (pfnLoadLibrary)GetAddress("LoadLibraryA", 12);

	pfnMessageBox fnMessageBox;
	fnMessageBox = (pfnMessageBox)fnGetProcAddress(fnLoadLibrary("user32"), "MessageBoxA");

	fnMessageBox((void*)0, "", "", 0L);

	return 0;
}