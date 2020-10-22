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
	mov dword [bx],0
	mov dword [bx+4],0
	mov dword [bx+8],0000ffffH ;Data_Global
	mov dword [bx+12],00cf9200H
	mov dword [bx+16],7c0001ffH ;Code
	mov dword [bx+20],00409800H
	mov dword [bx+24],7c0001ffH ;Data
	mov dword [bx+28],00409200H
	mov dword [bx+32],7c00fffeH ;Stack
	mov dword [bx+36],00cf9600H
	mov word [cs:gdt+7c00H],5*8-1
	lgdt [cs:gdt+7c00H]
	in al,92H
	or al,2
	out 92H,al
	cli
	mov eax,cr0
	or eax,1
	mov cr0,eax
	jmp dword 10000B:flush
[bits 32]
flush:
	mov ax,11000B
	mov ds,ax
	mov ax,1000B
	mov es,ax
	mov fs,ax
	mov gs,ax
	mov eax,100000B
	mov ss,ax
	xor esp,esp

	mov ecx,62-1
i:
	push ecx
	xor bx,bx
	j:
		mov ax,[bx+string]
		cmp ah,al
		jge _
		xchg ah,al
		mov [bx+string],ax
		_:
		inc bx
		loop j
	pop ecx
	loop i

	xor ebx,ebx
	mov esi,0b8000H
	mov cx,62
k:
	mov al,[ebx+string]
	mov [es:esi],al
	inc ebx
	add si,2
	loop k
	hlt
	string: db "1nZ0lLkMNbBXfWAI852uEh43FYdrVz6JCSpyRgsiOQ7PHTeomxqGDtvj9KacwU"
gdt:
	dw 0
	dd 7e00H
times 510-($-$$) db 0
dw 0aa55H
