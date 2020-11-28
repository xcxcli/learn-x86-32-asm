DataG	equ 1*8
Stack	equ 3*8
GPU		equ 4*8
Func	equ 5*8
Data	equ 6*8
Code	equ 7*8
length:	dd core_end
_Func:	dd section.func.start
_Data:	dd section.data.start
_Code:	dd section.code.start
entry:	dd start
		dw Code
[bits 32]
section func vstart=0
print_str:
	call _print_str
	retf
print_char:
	call _print_char
	retf
get_cursor:
	call _get_cursor
	retf
set_cursor:
	call _set_cursor
	retf
_print_str: ;dx:ebx
	push ecx
_print_str.lop:
	mov cl,[ebx]
	or cl,cl
	jz _print_str.exit
	call _print_char
	inc ebx
	jmp _print_str.lop
_print_str.exit:
	pop ecx
	ret
_print_char: ;cl
	pushad
	push es
	mov ax,GPU
	mov es,ax
	call _get_cursor
	cmp cl,13
	je _print_13
	cmp cl,10
	je _print_10
	mov bx,ax
	shl bx,1
	mov [es:ebx],cl
	inc ax
	jmp _roll_screen
_print_char.exit:
	call _set_cursor
	pop es
	popad
	ret
_print_13:
	mov bl,80
	div bl
	mul bl
	jmp _print_char.exit
_print_10: ;ax
	add ax,80
_roll_screen:
	cmp ax,2000
	jl _print_char.exit
	push ds
	mov ax,GPU
	mov ds,ax
	cld
	mov esi,80*2
	mov edi,0
	mov ecx,960
	rep movsd
	mov bx,1920*2
	mov ecx,80
_roll_screen.lop:
	mov word [ebx],720H
	inc bx
	inc bx
	loop _roll_screen.lop
	pop ds
	mov ax,1920
	jmp _print_char.exit
_get_cursor: ;ax(need dx)
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
_set_cursor: ;ax(need dx,bx)
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
print_hex: ;(edx)
	pushad
	push ds
	mov ax,Data
	mov ds,ax
	xor eax,eax
	mov ebx,hex_c
	mov ecx,8
print_hex.lop:
	rol edx,4
	mov al,dl
	and al,15
	xlat
	push ecx
	mov cl,al
	call _print_char
	pop ecx
	loop print_hex.lop
	pop ds
	popad
	retf
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
	retf
allocate_memory: ;(ecx)
	push ds
	push eax
	push ebx
	mov ax,Data
	mov ds,ax
	mov eax,[RAM]
	mov ebx,eax
	add eax,ecx
	mov ecx,ebx
	mov ebx,eax
	and ebx,0fffffffcH
	add ebx,4
	test eax,3
	cmovnz eax,ebx
	mov [RAM],eax
	pop ebx
	pop eax
	pop ds
	retf
set_gdt: ;((edx:eax):gdt)(ecx:selector)
	push ebx
	push es
	push ds
	mov bx,Data
	mov ds,bx
	sgdt [pgdt]
	mov bx,DataG
	mov es,bx
	movzx ebx,word [pgdt]
	inc ebx
	push ebx
	add ebx,[pgdt+2]
	mov [es:ebx],eax
	mov [es:ebx+4],edx
	add word [pgdt],8
	lgdt [pgdt]
	pop ecx
	pop ds
	pop es
	pop ebx
	retf
make_seg: ;(eax:pos,ebx:limit,ecx:props)((edx:eax):gdt)
	mov edx,eax
	shl eax,16
	mov ax,bx
	xor dx,dx
	rol edx,8
	bswap edx
	xor bx,bx
	or edx,ebx
	or edx,ecx
	retf
make_gate: ;(eax:pos,bx:selector,cx:props)((edx:eax):gate)
	push ebx
	mov edx,eax
	mov dx,cx
	shl ebx,16
	and eax,0000ffffH
	or eax,ebx
	pop ebx
	retf
section data vstart=0
	pgdt:
		dw 0
		dd 0
	hex_c: db "0123456789ABCDEF"
	cpu_st: db 13,10
	cpu_s: times 48 db 0
		db 13,10,0
	pre_esp: dd 0
	buffer: times 512 db 0
	RAM: dd 00100000H
	msg1: db "Welcome to xcx's os!",0
	msg2: db 13,10,'Call Gate Mounted.',0
	msg3: db 13,10,'Done.',0
	tcb_chain: dd 0
	salt:
		salt_l	equ 32
		salt1:
			db "@print_str"
			times salt_l-($-salt1) db 0
			dd print_str
			dw Func
		salt2:
			db "@read_hard_disk"
			times salt_l-($-salt2) db 0
			dd read_hard_disk
			dw Func
		salt3:
			db "@print_hex"
			times salt_l-($-salt3) db 0
			dd print_hex
			dw Func
		salt4:
			db "@return"
			times salt_l-($-salt4) db 0
			dd call_program.return
			dw Code
		salt_item	equ salt_l+6
		salt_num	equ ($-salt)/salt_item
section code vstart=0
start:
	mov ax,Data
	mov ds,ax
	mov ebx,msg1
	call Func:print_str
	mov edi,cpu_s
	mov eax,80000002H
	cpuid
	mov [edi],eax
	mov [edi+4],ebx
	mov [edi+8],ecx
	mov [edi+12],edx
	mov eax,80000003H
	cpuid
	mov [edi+16],eax
	mov [edi+20],ebx
	mov [edi+24],ecx
	mov [edi+28],edx
	mov eax,80000004H
	cpuid
	mov [edi+32],eax
	mov [edi+36],ebx
	mov [edi+40],ecx
	mov [edi+44],edx
	mov ebx,cpu_st
	call Func:print_str
	mov edi,salt
	mov ecx,salt_num
call_gate_loop:
	push ecx
	mov eax,[edi+salt_l]
	mov bx,[edi+salt_l+4]
	mov cx,1110110000000000B
	call Func:make_gate
	call Func:set_gdt
	mov [edi+salt_l+4],cx
	add edi,salt_item
	pop ecx
	loop call_gate_loop
	mov ebx,msg2
	call far [salt1+salt_l]
	mov esi,50
	call call_program
	mov ebx,msg3
	call Func:print_str
	hlt
set_tcb: ;(ecx:tcb_pos)
	push eax
	push ds
	push es
	mov ax,Data
	mov ds,ax
	mov ax,DataG
	mov es,ax
	mov eax,[tcb_chain]
	mov [es:ecx],eax
	mov [tcb_chain],ecx
	pop es
	pop ds
	pop eax
	ret
call_program: ;(esi:pos)
	mov ecx,70
	call Func:allocate_memory
	call set_tcb
	push esi
	push ecx
	call load_program
	mov [pre_esp],esp
	mov ax,DataG
	mov ds,ax
	ltr [ecx+24]
	lldt [ecx+16]
	mov eax,[ecx+68]
	mov ds,eax
	push dword [8]
	push dword 0
	push dword [20]
	push dword [16]
	retf
call_program.return:
	mov ax,Data
	mov ds,ax
	mov ax,Stack
	mov ss,ax
	mov esp,[pre_esp]
	ret
set_ldt: ;((edx:eax):ldt,esi:tcb_pos)(ecx:selector)
	push edi
	push ds
	mov cx,DataG
	mov ds,cx
	xor ecx,ecx
	mov edi,[esi+12]
	mov cx,[esi+10]
	inc cx
	mov [edi+ecx],eax
	mov [edi+ecx+4],edx
	add cx,7
	mov [esi+10],cx
	sub cx,3
	pop ds
	pop edi
	ret
load_program: ;(pos,tcb_pos)#push
	pushad
	push ds
	push es
	mov ebp,esp
	mov cx,DataG
	mov es,cx
	mov esi,[ebp+44] ;tcb_pos
	mov ecx,20*8
	call Func:allocate_memory
	mov [es:esi+12],ecx
	mov word [es:esi+10],0ffffH
	mov ax,Data
	mov ds,ax
	mov eax,[ebp+48] ;pos
	mov ebx,buffer
	call Func:read_hard_disk
	mov eax,[buffer]
	mov ebx,eax
	and ebx,0fffffe00H
	add ebx,512
	test eax,511
	cmovnz eax,ebx
	mov ecx,eax
	call Func:allocate_memory
	mov [es:esi+6],ecx
	mov ebx,ecx
	push ebx
	shr eax,9
	mov ecx,eax
	mov ax,DataG
	mov ds,ax
	mov eax,[ebp+48]
load_program.read:
	call Func:read_hard_disk
	inc eax
	loop load_program.read
	pop edi
	mov eax,edi
	mov ebx,[edi+4]
	dec ebx
	mov ecx,0040f200H
	call Func:make_seg ;User.Header
	call set_ldt
	or cl,3
	mov [esi+68],cx
	mov [edi+4],cx
	mov eax,edi
	add eax,[edi+20]
	mov ebx,[edi+24]
	dec ebx
	mov ecx,0040f800H
	call Func:make_seg ;User.Code
	call set_ldt
	or cl,3
	mov [edi+20],cx
	mov eax,edi
	add eax,[edi+28]
	mov ebx,[edi+32]
	dec ebx
	mov ecx,0040f200H
	call Func:make_seg ;User.Data
	call set_ldt
	or cl,3
	mov [edi+28],cx
	mov ecx,[edi+12]
	mov ebx,0fffffH
	sub ebx,ecx
	mov eax,4096
	mul ecx
	mov ecx,eax
	call Func:allocate_memory
	add eax,ecx
	mov ecx,00c0f600H
	call Func:make_seg ;User.Stack
	call set_ldt
	or cl,3
	mov [edi+8],cx
	mov ax,Data
	mov ds,ax
	cld
	mov ecx,[es:edi+36]
	add edi,40
	push esi
load_program.salt:
	push ecx
	push edi
	mov ecx,salt_num
	mov esi,salt
	load_program.lop:
		push ecx
		push edi
		push esi
		mov ecx,salt_l/4
		repe cmpsd
		jnz load_program.jump
		mov eax,[esi]
		mov [es:edi-salt_l],eax
		mov ax,[esi+4]
		or al,3
		mov [es:edi-salt_l+4],ax
		load_program.jump:
		pop esi
		add esi,salt_item
		pop edi
		pop ecx
		loop load_program.lop
	pop edi
	add edi,salt_l
	pop ecx
	loop load_program.salt
	pop esi
	mov ax,DataG
	mov ds,ax
	mov cx,4096
	mov eax,ecx
	mov dword [esi+26],1
	call Func:allocate_memory
	add eax,ecx
	mov [esi+30],eax
	mov ebx,0ffffeH
	mov ecx,00c09600H
	call Func:make_seg ;Stack DPL 0
	call set_ldt
	mov [esi+34],cx
	mov dword [esi+36],0
	mov cx,4096
	mov eax,ecx
	mov dword [esi+40],1
	call Func:allocate_memory
	add eax,ecx
	mov [esi+44],eax
	mov ebx,0ffffeH
	mov ecx,00c0b600H
	call Func:make_seg ;Stack DPL 1
	call set_ldt
	or cl,1
	mov [esi+48],cx
	mov dword [esi+50],0
	mov cx,4096
	mov eax,ecx
	mov dword [esi+54],1
	call Func:allocate_memory
	add eax,ecx
	mov [esi+58],eax
	mov ebx,0ffffeH
	mov ecx,00c0d600H
	call Func:make_seg ;Stack DPL 2
	call set_ldt
	or cl,2
	mov [esi+62],cx
	mov dword [esi+64],0
	mov eax,[esi+12]
	movzx ebx,word [esi+10]
	mov ecx,00408200H
	call Func:make_seg
	call Func:set_gdt
	mov [esi+16],cx
	mov ecx,103
	mov [esi+18],cx
	inc ecx
	call Func:allocate_memory
	mov [esi+20],ecx
	mov word [ecx],0
	mov dx,[esi+34]
	mov [ecx+8],dx
	mov dx,[esi+48]
	mov [ecx+16],dx
	mov dx,[esi+62]
	mov [ecx+24],dx
	mov dx,[esi+16]
	mov [ecx+96],dx
	mov dx,[esi+18]
	mov [ecx+102],dx
	mov eax,[esi+20]
	movzx ebx,word [esi+18]
	mov ecx,00408900H
	call Func:make_seg
	call Func:set_gdt
	mov [esi+24],cx
	pop es
	pop ds
	popad
	ret 8
section end
core_end:
