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
print_str: ;dx:bx
	push cx
print_str.lop:
	mov cl,[bx]
	or cl,cl
	jz print_str.exit
	call print_char
	inc bx
	jmp print_str.lop
print_str.exit:
	pop cx
	ret
print_char: ;cl
	pusha
	push es
	mov ax,0b800H
	mov es,ax
	call get_cursor
	cmp cl,13
	je _print_13
	cmp cl,10
	je _print_10
	mov bx,ax
	shl bx,1
	mov [es:bx],cl
	inc ax
	jmp _roll_screen
print_char.exit:
	call set_cursor
	pop es
	popa
	ret
_print_13:
	mov bl,80
	div bl
	mul bl
	jmp print_char.exit
_print_10: ;ax
	add ax,80
_roll_screen:
	cmp ax,2000
	jl print_char.exit
	push ds
	mov ax,0b800H
	mov ds,ax
	cld
	mov si,80*2
	mov di,0
	mov cx,960
	rep movsd
	mov bx,1920*2
	mov cx,80
_roll_screen.lop:
	mov word [bx],720H
	inc bx
	inc bx
	loop _roll_screen.lop
	pop ds
	mov ax,1920
	jmp print_char.exit
get_cursor: ;ax(need dx)
	mov dx,3d4H
	mov al,0eH
	out dx,al
	inc dx
	in al,dx
	mov ah,al
	dec dx
	mov al,0fH
	out dx,al
	inc dx
	in al,dx
	ret
set_cursor: ;ax(need dx,bx)
	mov bx,ax
	mov dx,3d4H
	mov al,0eH
	out dx,al
	inc dx
	mov al,bh
	out dx,al
	dec dx
	mov al,0fH
	out dx,al
	inc dx
	mov al,bl
	out dx,al
	ret
start:
	mov ax,0
	mov es,ax
	mov ax,[Stack_]
	mov ss,ax
	mov sp,stack_end
	mov ax,[Data_]
	mov ds,ax
	mov bx,msg
	call print_str
	mov bx,70H
	shl bx,2
	cli
	mov word [es:bx],int_70H
	mov word [es:bx+2],cs
	mov al,8bH
	out 70H,al
	mov al,12H
	out 71H,al
	mov al,0cH
	out 70H,al
	in al,71H
	in al,0a1H
	and al,0feH
	out 0a1H,al
	sti
	mov bx,done
	call print_str
	mov ax,0b800H
	mov ds,ax
	mov bx,12*160+33*2
	mov byte [bx],'0'
main_loop:
	hlt
	not byte [bx+1]
	jmp main_loop
int_70H:
	push cx
	mov cl,'A'
	call print_char
	pop cx
	pusha
	push ds
int_70H.lop:
	mov al,8aH
	out 70H,al
	in al,71H
	test al,80H
	jnz int_70H.lop
	mov al,80H
	out 70H,al
	in al,71H
	push ax
	mov al,82H
	out 70H,al
	in al,71H
	push ax
	mov al,84H
	out 70H,al
	in al,71H
	push ax
	mov al,0cH
	out 70H,al
	in al,71H
	mov ax,0b800H
	mov ds,ax
	pop ax
	call toNum
	mov bx,(12*80+36)*2
	mov [bx],ah
	mov [bx+2],al
	mov byte [bx+4],':'
	pop ax
	call toNum
	mov [bx+6],ah
	mov [bx+8],al
	mov byte [bx+10],':'
	pop ax
	call toNum
	mov [bx+12],ah
	mov [bx+14],al
	mov al,20H
	out 0a0H,al
	out 020H,al
	pop ds
	popa
	iret
toNum:
	mov ah,al
	and al,15
	add al,'0'
	shr ah,4
	and ah,15
	add ah,'0'
	ret
section data align=16 vstart=0
	msg:
		db "This is a x86-32 os.",13,10
		db "Written By xcx.",13,10,0
	done:
		db "Installed successfully.",13,10,0
section stack align=16 vstart=0
	times 32 dd 0
stack_end:
section end
program_end:
