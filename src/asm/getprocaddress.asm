; By SIGSEGV
; Modified by dtm

global _start
;global _GetFunction

section .text
	jmp _start

	dwKernelBase:				dd	  0
	dwExportDirectory:   		dd	  0
	szGetProcAddress			db    "GetProcAddress", 0
	dwGetProcAddressLen			dd    $-szGetProcAddress
	szLoadLibrary				db    "LoadLibraryA", 0
	dwLoadLibraryLen 			dd    $-szLoadLibrary 
	szMessageBox 				db    "MessageBoxA", 0
	szUser32					db    "user32", 0
	szString 					db    "", 0

_start:
	push 	ebp
	mov 	ebp,	esp
	sub 	esp, 	0x10

	mov		ebx, [dwGetProcAddressLen]
	push	ebx
	push	szGetProcAddress
	call	_GetFunction
	add 	esp, 0x08
	mov 	[ebp - 4], eax

	mov	 	ebx, [dwLoadLibraryLen]
	push	ebx
	push	szLoadLibrary
	call 	_GetFunction
	add 	esp, 0x08
	mov 	[ebp - 8], eax

	push	szUser32
	call	eax 						; LoadLibraryA
	add 	esp, 0x04

	push	szMessageBox
	push	eax
	call 	[ebp - 4]					; GetProcAddress
	add 	esp, 0x08

	push	0
	lea 	ebx, [szString]
	push	ebx
	push	ebx
	push	0
	call	eax
	add 	esp, 0x10	

	mov 	esp, 	ebp
	pop 	ebp
	ret

; pfnFunction = GetAddress("FunctionName", strlen("FunctionName"));
_GetFunction:
	push	ebp
	mov 	ebp, 	esp

	mov		ebx,	[fs:0x30]   						; get a pointer to the PEB
	mov		ebx,	[ebx + 0x0C]   						; get PEB->Ldr
	mov		ebx,	[ebx + 0x14]   						; get PEB->Ldr.InMemoryOrderModuleList.Flink (1st entry)
	mov		ebx,	[ebx]	 							; 2nd Entry
	mov		ebx,	[ebx]	 							; 3rd Entry
	mov		ebx,	[ebx + 0x10]   						; Get Kernel32 Base
	mov		[dwKernelBase],	ebx
	add		ebx,	[ebx + 0x3C]						; Start of PE header
	mov		ebx,	[ebx + 0x78]						; RVA of export dir
	add		ebx,	[dwKernelBase] 						; VA of export dir
	mov		[dwExportDirectory],	ebx

	mov 	edx, 	[ebp + 0x08]
	;lea 	edx,	[edx]						; string of function name
	mov 	ecx,	[ebp + 0x0C]						; strlen of function name
	call 	GetFunctionAddress

	mov 	esp, 	ebp
	pop 	ebp
	ret 												; return address

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	  <<<<< GetFunctionAddress >>>>>>											;
;	 Extracts Function Address From Export Directory and returns it in eax   	;
;	 Parameters :  Function name in edx , Length in ecx						;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFunctionAddress:
	push 	ebx
	push 	esi
	push 	edi

	mov		esi,	[dwExportDirectory]
	mov		esi,	[esi + 0x20]						; RVA of ENT
	add		esi,	[dwKernelBase]  					; VA of ENT
	xor 	ebx,	ebx
	cld

looper:
	inc 	ebx
	lodsd
	add 	eax, 	[dwKernelBase]   					; eax now points to the string of a function
	push 	esi											; preserve it for the outer loop
	mov 	esi,	eax
	mov 	edi,	edx
	cld
	push 	ecx
	repe 	cmpsb
	pop 	ecx
	pop 	esi
	jne 	looper

	dec 	ebx
	mov 	eax,	[dwExportDirectory]
	mov 	eax,	[eax + 0x24]	   					; RVA of EOT
	add 	eax,	[dwKernelBase]	 					; VA of EOT
	movzx 	eax, 	WORD [ebx*2 + eax]					; eax now holds the ordinal of our function
	mov 	ebx,	[dwExportDirectory]
	mov 	ebx,	[ebx + 0x1C]	   					; RVA of EAT
	add 	ebx,	[dwKernelBase]	 					; VA of EAT
	mov 	ebx,	[eax*4 + ebx]
	add 	ebx,	[dwKernelBase]
	mov 	eax,	ebx

	pop 	edi
	pop 	esi
	pop 	ebx
	ret
