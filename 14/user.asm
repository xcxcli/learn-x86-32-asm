salt_l equ 32
section header vstart=0
	length:		dd program_end
	Header:		dd header_end
	Stack:		dd 0
	Stack_len:	dd 1
	entry:		dd start
	Code:		dd section.code.start
	Code_len:	dd code_end
	Data:		dd section.data.start
	Data_len:	dd data_end
	salt_num:	dd (salt_end-salt)/salt_l
	salt:
		print_str:
			db "@print_str"
			times salt_l-($-print_str) db 0
		return:
			db "@return"
			times salt_l-($-return) db 0
		read_hard_disk:
			db "@read_hard_disk"
			times salt_l-($-read_hard_disk) db 0
		print_hex:
			db "@print_hex"
			times salt_l-($-print_hex) db 0
		salt_end:
header_end:
section data vstart=0
	msg: db 13,10,"From User Program:",13,10,0
	buffer: times 512 db 0
data_end:
[bits 32]
section code vstart=0
start:
	mov ax,ds
	mov fs,ax
	mov ax,[Stack]
	mov ss,ax
	mov esp,0
	mov ax,[Data]
	mov ds,ax
	mov ebx,msg
	call far [fs:print_str]
	mov eax,100
	mov ebx,buffer
	call far [fs:read_hard_disk]
	mov ebx,buffer
	call far [fs:print_str]
	mov edx,1234febaH
	call far [fs:print_hex]
	call far [fs:return]
code_end:
section end
program_end:
