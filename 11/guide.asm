[bits 16]
	mov ax,cs
	mov ss,ax
	mov sp,7c00H
	mov ax,[cs:gdt_base+7c00H]
	mov dx,[cs:gdt_base+7c02H]
	mov bx,16
	div bx
	mov ds,ax
	mov bx,dx
	mov dword [bx],0
	mov dword [bx+4],0
	mov dword [bx+8],7c0001ffH ;Code
	mov dword [bx+12],00409800H
	mov dword [bx+16],8000ffffH ;Data
	mov dword [bx+20],0040920bH
	mov dword [bx+24],00007a00H ;Stack
	mov dword [bx+28],00409600H
	mov word [cs:gdt_size+7c00H],4*8-1
	lgdt [cs:gdt_size+7c00H]
	in al,92H
	or al,2
	out 92H,al
	cli
	mov eax,cr0
	or eax,1
	mov cr0,eax
	jmp dword 1000B:flush
[bits 32]
flush:
	mov cx,10000B
	mov ds,cx
	mov byte [0],'P'
	mov byte [2],'r'
	mov byte [4],'t'
	mov byte [6],'e'
	mov byte [8],'c'
	mov byte [10],'t'
	mov byte [14],'M'
	mov byte [16],'o'
	mov byte [18],'d'
	mov byte [20],'e'
	mov byte [24],'O'
	mov byte [26],'K'
	mov cx,11000B
	mov ss,cx
	mov esp,7c00H
	mov ebp,esp
	push byte '.'
	sub ebp,4
	cmp ebp,esp
	jnz halt
	pop eax
	mov [28],al
halt:
	hlt
gdt_size :dw 0
gdt_base :dd 7e00H
times 510-($-$$) db 0
dw 0aa55H
