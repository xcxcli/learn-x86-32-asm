section header
	program_length:dd program_end
	entry:
		dw start
		dd section.code.start
	loc_len:dw (loc_end-loc_start)/4
	loc_start:
		Code_:dd section.code.start
		Data_:dd section.data.start
		Stack_:dd section.stack.start
	loc_end:
section code align=16 vstart=0
start:
	mov ax,[Stack_]
	mov ss,ax
	mov sp,stack_end
	mov ax,[Data_]
	mov ds,ax
	mov bx,msg
	mov cx,msg_end-msg
putc:
	mov al,[bx]
	mov ah,0eH
	int 10H
	inc bx
	loop putc
getc:
	xor ah,ah
	int 16H
	mov ah,0eH
	mov bl,7
	int 10H
	loop getc
section data align=16 vstart=0
	msg:
		db "This is a x86-32 os.",13,10
		db "Written By xcx.",13,10,0
	msg_end:
section stack align=16 vstart=0
	times 32 dd 0
stack_end:
section end
program_end:
