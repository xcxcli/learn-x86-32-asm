disk_id equ 100
section dir align=16 vstart=07c00H
	mov ax,0
	mov ss,ax
	mov sp,ax
	mov ax,[cs:disk_base]
	mov dx,[cs:disk_base+2]
	mov bx,16
	div bx
	mov ds,ax
	mov es,ax
	xor di,di
	xor bx,bx
	mov si,disk_id
	call read_hard_disk
	mov ax,[0]
	mov dx,[2]
	mov bx,512
	div bx
	cmp dx,0
	jnz _1
	dec ax
_1:
	cmp ax,0
	jz direct
	push ds
	mov cx,ax
_2:
	mov ax,ds
	add ax,32
	mov ds,ax
	xor bx,bx
	inc si
	call read_hard_disk
	loop _2
	pop ds
direct:
	mov ax,[6]
	mov dx,[8]
	call calc_loc
	mov [6],ax
	mov cx,[10]
	mov bx,12
_3:
	mov ax,[bx]
	mov dx,[bx+2]
	call calc_loc
	mov [bx],ax
	add bx,4
	loop _3
	jmp far [4]
read_hard_disk: ;di:si=>dx:bx
	pusha
	mov dx,1f2H
	mov al,1
	out dx,al
	inc dx
	mov ax,si
	out dx,al
	inc dx
	mov al,ah
	out dx,al
	inc dx
	mov ax,di
	out dx,al
	inc dx
	mov al,0e0H
	or al,ah
	out dx,al
	inc dx
	mov al,20H
	out dx,al
read_hard_disk.waits:
	in al,dx
	and al,88H
	cmp al,8
	jnz read_hard_disk.waits
	mov cx,256
	mov dx,1f0H
read_hard_disk.read:
	in ax,dx
	mov [bx],ax
	inc bx
	inc bx
	loop read_hard_disk.read
	popa
	ret
calc_loc: ;dx:ax
	push dx
	add ax,[cs:disk_base]
	adc dx,[cs:disk_base+2]
	shr ax,4
	ror dx,4
	and dx,0f000H
	or ax,dx
	pop dx
	ret
disk_base:dd 10000H
times 510-($-$$) db 0
dw 0aa55H
