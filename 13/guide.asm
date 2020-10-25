os_start	equ 40000H
os_pos		equ 1

Data		equ 1*8
Code		equ 2*8
Stack		equ 3*8
GPU			equ 4*8
[bits 16]
	mov ax,cs
	mov ss,ax
	mov sp,7c00H
	mov eax,[cs:gdt+7c02H]
	xor edx,edx
	mov ebx,16
	div ebx
	mov ds,ax
	mov bx,dx
	mov dword [bx+8],0000ffffH ;Data
	mov dword [bx+12],00cf9200H
	mov dword [bx+16],7c0001ffH ;Code
	mov dword [bx+20],00409800H
	mov dword [bx+24],7c00fffeH ;Stack
	mov dword [bx+28],00cf9600H
	mov dword [bx+32],80007fffH ;GPU
	mov dword [bx+36],0040920bH
	mov word [cs:gdt+7c00H],5*8-1
	lgdt [cs:gdt+7c00H]
	in al,92H
	or al,2
	out 92H,al
	cli
	mov eax,cr0
	or eax,1
	mov cr0,eax
	jmp dword Code:flush
[bits 32]
flush:
	mov ax,Data
	mov ds,ax
	mov ax,Stack
	mov ss,ax
	xor esp,esp
	mov eax,os_pos
	mov ebx,os_start
	mov edi,ebx
	call read_hard_disk
	mov eax,[edi]
	xor edx,edx
	mov ecx,512
	div ecx
	or edx,edx
	jnz ndec
	dec eax
ndec:
	or eax,eax
	jz start
	mov ecx,eax
	mov eax,os_pos+1
read_loop:
	call read_hard_disk
	inc eax
	loop read_loop
start:
	mov esi,[gdt+7c02H]
	mov eax,[edi+4]
	mov ebx,[edi+8]
	sub ebx,eax
	dec ebx
	add eax,edi
	mov ecx,00409800H
	call make_gdt
	mov [esi+5*8],eax
	mov [esi+5*8+4],edx
	mov eax,[edi+8]
	mov ebx,[edi+12]
	sub ebx,eax
	dec ebx
	add eax,edi
	mov ecx,00409200H
	call make_gdt
	mov [esi+6*8],eax
	mov [esi+6*8+4],edx
	mov eax,[edi+12]
	mov ebx,[edi+0]
	sub ebx,eax
	dec ebx
	add eax,edi
	mov ecx,00409800H
	call make_gdt
	mov [esi+7*8],eax
	mov [esi+7*8+4],edx
	mov word [gdt+7c00H],8*8-1
	lgdt [gdt+7c00H]
	jmp far [edi+16]
read_hard_disk: ;(eax:from,(ds:ebx):to)(ebx+=512)
	push eax
	push ecx
	push edx
	push eax
	mov dx,1f2H
	mov al,1
	out dx,al
	pop eax
	inc dx
	out dx,al
	mov cl,8
	shr eax,cl
	inc dx
	out dx,al
	shr eax,cl
	inc dx
	out dx,al
	shr eax,cl
	or al,0e0H
	inc dx
	out dx,al
	mov al,20H
	inc dx
	out dx,al
read_hard_disk.w:
	in al,dx
	and al,0x88
	cmp al,0x08
	jnz read_hard_disk.w
	mov ecx,128
	mov dx,1f0H
read_hard_disk.r:
	in eax,dx
	mov [ebx],eax
	add ebx,4
	loop read_hard_disk.r
	pop edx
	pop ecx
	pop eax
	ret
make_gdt: ;(eax:pos,ebx:limit,ecx:props)((edx:eax):gdt)
	mov edx,eax
	shl eax,16
	mov ax,bx
	xor dx,dx
	rol edx,8
	bswap edx
	xor bx,bx
	or edx,ebx
	or edx,ecx
	ret
gdt:
	dw 0
	dd 7e00H
times 510-($-$$) db 0
dw 0aa55H
