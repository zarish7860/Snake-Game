[org 0x0100]

jmp start


clrscr:   
pusha
push cs
pop ds    
        
mov  ax, 0xb800               
mov  es, ax             ; point es to video base               
xor  di, di             ; point di to top left column               
mov  ax, 0x0720         ; space char in normal attribute               
mov  cx, 2000           ; number of screen locations 
     
cld                     ; auto increment mode               
rep  stosw              ; clear the whole screen 
 
    popa
ret 

printnum:     
push bp
mov bp,sp
pusha

mov di,80
mov ax,[bp+8]
mul di
mov di,ax
add di,[bp+6]
shl di,1
add di,8

mov ax,0xb800
mov es,ax
mov ax,[bp+4]
mov bx,10
mov cx,4
nextdigit:
mov dx,0
div bx
add dl,0x30
cmp dl,0x39
jbe skipalpha
add dl,7
skipalpha:
mov dh,0x07
mov [es:di],dx
sub di,2
loop nextdigit                        ; repeat for all digits on stack 

popa
pop bp
ret 6


printBorder2:
push bp
mov bp,sp
pusha

mov ax,0xB800
mov es,ax                        ;es has address of video segment

mov ax,'%'
mov ah,9

;To show upper boundary

mov dx,320                        ;dx has upper boundary's starting address
mov di,dx
cld
mov cx,80
rep stosw

;To show lower boundary

mov bx,3840                       ;bx has lower boundary's starting address
mov di,bx
cld
mov cx,80
rep stosw

;To show right and left boundaries

mov di,320
mov cx,22

pl2:
mov word[es:di],ax
add di,158                             ;after 1st column print in last column
mov word[es:di],ax
add di,2
loop pl2

mov di,990
mov cx,49

ph1:
mov word[es:di],ax
add di,2
loop ph1

mov di,2910
mov cx,49
ph2:
mov word[es:di],ax
add di,2
loop ph2

mov di,1300
mov cx,8
pv1:
mov word[es:di],ax
add di,160
loop pv1

mov di,1416
mov cx,8
pv2:
mov word[es:di],ax
add di,160
loop pv2

popa
pop bp
ret





printBorder1:
push bp
mov bp,sp
pusha

mov ax,0xB800
mov es,ax                        ;es has address of video segment

mov ax,'%'
mov ah,9

;To show upper boundary

mov dx,320                        ;dx has upper boundary's starting address
mov di,dx
cld
mov cx,80
rep stosw

;To show lower boundary

mov bx,3840                       ;bx has lower boundary's starting address
mov di,bx
cld
mov cx,80
rep stosw

;To show the pillars
mov cx,11
mov di,518
pu:
mov word[es:di],ax
add di,160
loop pu

mov cx,12
mov di,2038
pd:
mov word[es:di],ax
add di,160
loop pd

;To show right and left boundaries

mov di,320
mov cx,22

pl1:
mov word[es:di],ax
add di,158                             ;after 1st column print in last column
mov word[es:di],ax
add di,2
loop pl1

popa
pop bp
ret

printstr:     
push bp               
mov  bp, sp               
pusha
mov  ax, 0xb800               
mov  es, ax             ; point es to video base               
mov  al, 80             ; load al with columns per row               
mul  byte [bp+10]       ; multiply with y position               
add  ax, [bp+12]        ; add x position               
shl  ax, 1              ; turn into byte offset               
mov  di,ax              ; point di to required location               
mov  si, [bp+6]         ; point si to string               
mov  cx, [bp+4]         ; load length of string in cx               
mov  ah, [bp+8]         ; load attribute in ah 

cld                     ; auto increment mode 
nextchar:     
lodsb                   ; load next char in al               
stosw                   ; print char/attribute pair               
loop nextchar           ; repeat for the whole string 
 
popa
pop bp
ret  10 
 
printBorder:
pusha
mov ax,0xB800
mov es,ax                        ;es has address of video segment

mov ax,'%'
mov ah,9

;To show upper boundary

mov dx,320                        ;dx has upper boundary's starting  address
mov di,dx
cld
mov cx,80
rep stosw

;To show lower boundary

mov bx,3840                       ;bx has lower boundary's starting address
mov di,bx
cld
mov cx,80
rep stosw

;To show right and left boundaries

mov di,320
mov cx,22

l1:
mov word[es:di],ax
add di,158                             ;after 1st column print in last column
mov word[es:di],ax
add di,2
loop l1

popa
ret



kbisr:        
pusha

in  al, 0x60                         ; read char from keyboard port   

cmp word[cs:currentpos],0            ; snake is currently vertical
jne l14

; So only Up and Down Keys will work

cmp al,200                          ; check for PgUp Key----01
jne l3

mov word[cs:up],1 

;All other flags are turned 0 
mov word[cs:down],0
mov word[cs:left],0
mov word[cs:right],0

;current position is turned vertical
mov word[cs:currentpos],1

l3:
cmp al,208                          ; check for PgDn Key----02
jne l14

mov word[cs:down],1   

;All other flags are turned 0
mov word[cs:up],0
mov word[cs:left],0
mov word[cs:right],0

;current position is turned vertical
mov word[cs:currentpos],1

l14:
cmp word[cs:currentpos],1
jne exit

;current position is vertical so only Left and Right Keys will work

l4:
cmp al,205        ; check for End Key-----03
jne l5

mov word[cs:right],1 

;All other flags are turned 0
mov word[cs:up],0
mov word[cs:left],0
mov word[cs:down],0

;current position is turned horizontal
mov word[cs:currentpos],0


l5:  
cmp al,203        ; check for Home Key----04
jne exit

mov word[cs:left],1    

;All other flags are turned 0
mov word[cs:up],0
mov word[cs:right],0
mov word[cs:down],0

;current position is turned horizontal
mov word[cs:currentpos],0

exit:

mov al,0x20
out 0x20,al
popa
iret

;Timer ISR

timer:  

pusha
push cs
pop ds
inc  word [cs:tickcount]             ; increment tick count 
push 65
push 0
push 0x07
push s_m
push 6
call printstr
push 0
push 70
push word [cs:score]               
call printnum                        ; print score
push 29
push 0
push 0x07
push r_l
push 16
call printstr
push 0
push 46
push word[cs:lives]
call printnum


push ax
push bx
push dx
push cx
cmp word[cs:tickcount],2000
jne qp
mov word[cs:tickcount],0
qp:
mov ax,word[cs:tickcount]
mov bx,360
mov dx,0
div bx
cmp dx,0
jne en

mov cl,[cs:speed]
sub cl,2
cmp cl,0
jne qw
mov cl,2
qw:
mov byte[cs:speed],cl
en:
pop cx
pop dx
pop bx
pop ax


mov ax,[cs:tickcount]
mov bl,[cs:speed]
mov bh,0
mov dx,0
div bx
cmp dx,0
jnz end2

inc word[cs:second]
call updateAdd                       ; updates the position of snake 
call printSnake
call incSize
cmp word[cs:pfruit],0
jne end2
call Rand
mov word[cs:pfruit],1

end2:
inc byte[cs:tick]
cmp byte[cs:tick],18
jne endt

mov byte[cs:tick],0
inc word[cs:sec]
dec word[cs:dsec]
cmp word[cs:sec],60
jne endt

mov word[cs:sec],0
mov word[cs:dsec],59
inc word[cs:min]
dec word[cs:dmin]
cmp word[cs:min],4

jne endt
cmp word[cs:snakesize],240
jne gonext
add word[cs:score],40
call Game_end1
gonext:
call newlife
endt:
push 8
push 0
push 0x07
push r_t
push 10
call printstr
call printmin
call printsec
call printdmin
call printdsec
endt1:
mov  al, 0x20               
out  0x20, al                        ; end of interrupt 
popa              
iret    
; return from interrupt 

del:  push cx
  mov cx,0xFFFF   
v2:   loop v2
  mov cx,0xFFFF   
v3:   loop v3

  pop cx
  ret



printdsec:
pusha
push cs
pop ds 
 
    mov  ax, 0xb800               
mov  es, ax             ; point es to video base               
mov  ax, [cs:dsec]         ; load number in ax               
mov  bx, 10             ; use base 10 for division               
mov  cx, 0              ; initialize count of digits 


nextdigit3:    
mov  dx, 0              ; zero upper half of dividend               
div  bx                 ; divide by 10               
add  dl, 0x30           ; convert digit into ascii value               
push dx                 ; save ascii value on stack               
inc  cx                 ; increment count of values                
cmp  ax, 0              ; is the quotient zero               
jnz  nextdigit3          ; if no divide it again 

cmp word[cs:dsec],10
jae regular3
mov dh,0x07
mov dl,0
add dl,0x30
mov di,46
mov [es:di],dx
add di,2
jmp nextpos3

regular3:
    mov  di, 46              ; point di to top left column

nextpos3:      
pop  dx                 ; remove a digit from the stack               
mov  dh, 0x07           ; use normal attribute               
mov [es:di], dx         ; print char on screen               
add  di, 2              ; move to next screen location               
loop nextpos3            ; repeat for all digits on stack
    popa
ret


printdmin:
pusha
push cs
pop ds 
 
mov  ax, 0xb800               
mov  es, ax             ; point es to video base               
mov  ax, [cs:dmin]         ; load number in ax               
mov  bx, 10             ; use base 10 for division               
mov  cx, 0              ; initialize count of digits 


nextdigit2:    
mov  dx, 0              ; zero upper half of dividend               
div  bx                 ; divide by 10               
add  dl, 0x30           ; convert digit into ascii value               
push dx                 ; save ascii value on stack               
inc  cx                 ; increment count of values                
cmp  ax, 0              ; is the quotient zero               
jnz  nextdigit2          ; if no divide it again 

cmp word[cs:dmin],10
jae regular2
mov dh,0x07
mov dl,0
add dl,0x30
mov di,40
mov [es:di],dx
add di,2
jmp nextpos2

regular2:
    mov  di, 40              ; point di to top left column

nextpos2:      
pop  dx                 ; remove a digit from the stack               
mov  dh, 0x07           ; use normal attribute               
mov [es:di], dx         ; print char on screen               
add  di, 2              ; move to next screen location               
loop nextpos2            ; repeat for all digits on stack
  mov byte[es:44],':' 
    popa
ret

printmin:           
pusha
push cs
pop ds 
 
    mov  ax, 0xb800               
mov  es, ax             ; point es to video base               
mov  ax, [cs:min]         ; load number in ax               
mov  bx, 10             ; use base 10 for division               
mov  cx, 0              ; initialize count of digits 


nextdigit1:    
mov  dx, 0              ; zero upper half of dividend               
div  bx                 ; divide by 10               
add  dl, 0x30           ; convert digit into ascii value               
push dx                 ; save ascii value on stack               
inc  cx                 ; increment count of values                
cmp  ax, 0              ; is the quotient zero               
jnz  nextdigit1          ; if no divide it again 

cmp word[cs:min],10
jae regular1
mov dh,0x07
mov dl,0
add dl,0x30
mov di,0
mov [es:di],dx
add di,2
jmp nextpos1

regular1:
    mov  di, 0              ; point di to top left column

nextpos1:      
pop  dx                 ; remove a digit from the stack               
mov  dh, 0x07           ; use normal attribute               
mov [es:di], dx         ; print char on screen               
add  di, 2              ; move to next screen location               
loop nextpos1            ; repeat for all digits on stack
  mov byte[es:4],':' 
    popa
ret


printsec:           
pusha
push cs
pop ds 
 
    mov  ax, 0xb800               
mov  es, ax             ; point es to video base               
mov  ax, [cs:sec]         ; load number in ax      
mov  bx, 10             ; use base 10 for division               
mov  cx, 0              ; initialize count of digits 


nextdigit0:    
mov  dx, 0              ; zero upper half of dividend               
div  bx                 ; divide by 10               
add  dl, 0x30           ; convert digit into ascii value               
push dx                 ; save ascii value on stack               
inc  cx                 ; increment count of values                
cmp  ax, 0              ; is the quotient zero               
jnz  nextdigit0          ; if no divide it again 

cmp word[cs:sec],10
jae regular
mov dh,0x07
mov dl,0
add dl,0x30
mov di,6
mov [es:di],dx
add di,2
jmp nextpos0

regular:
    mov  di, 6              ; point di to top left column

nextpos0:      
pop  dx                 ; remove a digit from the stack               
mov  dh, 0x07           ; use normal attribute               
mov [es:di], dx         ; print char on screen               
add  di, 2              ; move to next screen location               
loop nextpos0            ; repeat for all digits on stack
 
    popa
ret



incSize:
cmp word[cs:move],0
je finish
inc word[cs:snakesize]
dec word[cs:move]
finish:
ret


printSnake:
pusha

mov ax,0xb800
mov es,ax
mov ah,11
mov al,'@'

mov bx,0

mov dx,word[cs:snakehead]   ; snake has updated head address at snake head

mov si,word[cs:snake+bx]
mov word[cs:snake+bx],dx
mov di,dx
mov cx,word[es:di]
mov word[es:di],ax

cmp cx,0x0720
je t7

cmp di,word[cs:fruitloc]
jne t4
call beep1
mov word[cs:move],3
inc word[cs:snakesize]
mov word[cs:pfruit],0
add word[cs:score],10
jmp t7
t4:
call beep
call newlife
jmp stop


t7:
mov bx,2
mov al,'#'
mov cx,word[cs:snakesize]

t2:
mov dx,word[cs:snake+bx]
mov word[cs:snake+bx],si
mov di,si
mov word[es:di],ax
add bx,2
dec cx

cmp cx,0
jne t3

cmp word[cs:move],0
jne stop
mov di,dx
mov word[es:di],0x0720
mov word[cs:move],0
jmp stop

t3:
mov si,word[cs:snake+bx]
mov word[cs:snake+bx],dx
mov di,dx
mov word[es:di],ax
add bx,2
dec cx

cmp cx,0
jne t2

cmp word[cs:move],0
jne stop
mov di,si
mov word[es:di],0x0720
mov word[cs:move],0
jmp stop
stop:
popa
ret 



updateAdd:
pusha

cmp word[cs:left],1
jne p2
sub word[cs:snakehead],2

p2:
cmp word[cs:right],1
jne p4
add word[cs:snakehead],2

p4:
cmp word[cs:up],1
jne p6
sub word[cs:snakehead],160

p6:
cmp word[cs:down],1
jne exit1
add word[cs:snakehead],160

exit1:
popa
ret 

;initializes the array snake to starting address of snake
initialize:
push bp
mov bp,sp
pusha
mov ax,0xb800
mov es,ax

mov bx,0
mov dx,word[cs:snakehead]
mov cx,word[cs:snakesize]

t1:
mov word[cs:snake+bx],dx
add bx,2
add dx,2
loop t1

sub bx,2
mov word[cs:snaketail],dx

popa
pop bp
ret 

lag: push bp
mov bp,sp
push ax
mov ax,0xffff
l: dec ax
jz e
jmp l
e: pop ax
pop bp
ret

beep1: 
push bp
mov bp,sp

in al, 61h  ;Save state
push ax  
mov bx, 6818; 1193180/175
mov al, 6Bh  ; Select Channel 2, write LSB/BSB mode 3
out 43h, al 
mov ax, bx 
out 24h, al  ; Send the LSB
mov al, ah   
out 42h, al  ; Send the MSB
in al, 61h   ; Get the 8255 Port Contence
or al, 3h      
out 61h, al  ;End able speaker and use clock channel 2 for input
mov cx, 03h ; High order wait value
mov dx, 0D04h; Low order wait value
mov ax, 86h;Wait service
int 15h        
pop ax;restore Speaker state
out 61h, al

pop bp
ret


beep: 
push bp
mov bp,sp
pusha

mov     dx,4010       ; Number of times to repeat whole routine.
mov     bx,200           ; Frequency value.
mov     al, 10110110b    ; The Magic Number (use this binary number only)
out     43h, al          ; Send it to the initializing port 43h Timer 2.

next:              ; This is were we will jump back to 2000 times.
mov     ax, bx           ; Move our Frequency value into ax.
out     42h, al          ; Send LSb to port 42h.
mov     al, ah           ; Move MSb into al 
out     42h, al          ; Send MSb to port 42h.

in      al, 61h          ; Get current value of port 61h.
OR      al, 00000011b    ; OR al to this value, forcing first two bits high.
out     61h, al          ; copy it to port 61h of the PPI chip

; to turn ON the speaker.
mov     cx, 20           ; Repeat loop 20 times
delay:                ; here is where we loop back too.
loop    delay         ; Jump repeatedly to delay until cx = 0
inc     bx               ; Incrementing the value of bx lowers
; the frequency each time we repeat the
; whole routine
dec     dx               ; decrement repeat routine count
cmp     dx, 0            ; Is dx (repeat count) = to 0

jnz     next      ; If not jump to next
; and do whole routine again.
; else dx = 0 time to turn speaker OFF
in      al,61h           ; Get current value of port 61h.
and     al,11111100b     ; and al to this value, forcing first two bits low.
out     61h,al           ; copy it to port 61h of the PPI chip

popa
pop bp
ret 

Rand:
pusha
d2:
int  0x1a
add ch,1          ;hours
add cl,1          ;minutes

mov ah,cl
mov al,ch

mov dl,dh
add dx,word[cs:tickcount]

add ax,dx
mov dl,dh
mov dh,0
add dx,word[cs:tickcount]

mov bx,3356

div bx
add dx,320
;dx has randomly generated number

mov ax,dx
shr ax,1
shl ax,1

mov dx,0xb800
mov es,dx
mov di,ax

cmp word[es:di],0x0720
jne d2

d1:
mov dh,0x07
mov bx,word[cs:fcount]
inc word[cs:fcount]
cmp word[cs:fcount],10
jne d4
mov word[cs:fcount],0
d4:
mov dl,byte[cs:fruit+bx]
mov word[es:di],dx
mov word[cs:fruitloc],di

popa
ret 

Game_end1:
call clrscr
mov ah,0x13
mov al,1
mov bh,0
mov bl,7
mov dx,0x0400
mov cx,24
push cs
pop es
mov bp,ending_message1
int 0x10
push 4
push 30
push word[cs:score]
call printnum
jmp endt


Game_end:
call clrscr
mov ah,0x13
mov al,1
mov bh,0
mov bl,7
mov dx,0x0400
mov cx,24
push cs
pop es
mov bp,ending_message
int 0x10
push 4
push 30
push word[cs:score]
call printnum
jmp endt



newlife:
dec word[cs:lives]
cmp word[cs:lives],0
je Game_end
mov byte[cs:speed],14
mov word[cs:snakehead],1980
mov word[cs:sec],0
mov byte[cs:tick],0
mov word[cs:min],0
mov word[cs:dsec],59 
mov word[cs:dmin],3
mov word[cs:pfruit],0
mov word[cs:fruitloc],0
mov word[cs:fcount],0
mov word[cs:tickcount],0
mov word[cs:second], 1
mov word[cs:currentpos], 0
mov word[cs:up], 0
mov word[cs:move], 0
mov word[cs:down], 0
mov word[cs:left], 1
mov word[cs:right],0
mov word[cs:head], 0
mov word[cs:incsize],0
mov word[cs:snakesize],20





cmp byte[cs:Emode],1
jne c2
call clrscr
call printBorder 
call initialize
ret
c2:
cmp byte[cs:Mmode],1
jne c3
call clrscr
call printBorder1
call initialize 
ret
c3:
call clrscr
call printBorder2 
call initialize
ret



start:    

call clrscr
mov ah,0x13
mov al,1
mov bh,0
mov bl,7
mov dx,0x0902
mov cx,25
push cs
pop es
mov bp,message
int 0x10
mov ah,0x13
mov al,1
mov bh,0
mov bl,7
mov dx,0x0b02
mov cx,105
push cs
pop es
mov bp,message1
int 0x10
mov ah,0x13
mov al,1
mov bh,0
mov bl,7
mov dx,0x0d02
mov cx,90
push cs
pop es
mov bp,message2
int 0x10
mov ah,0x13
mov al,1
mov bh,0
mov bl,7
mov dx,0x0f02
mov cx,107
push cs
pop es
mov bp,message3
int 0x10
mov ah,0x13
mov al,1
mov bh,0
mov bl,7
mov dx,0x1102
mov cx,34
push cs
pop es
mov bp,message4
int 0x10
mov ah,0x13
mov al,1
mov bh,0
mov bl,7
mov dx,0x1802
mov cx,57
push cs
pop es
mov bp,message5
int 0x10

mov ah,0
int 0x16

cmp ah, 0x12
je easy
cmp ah,0x32
je medium1
cmp ah,0x20
je difficuilt
mov ax,4c00h
int 21h


easy:
call clrscr
call printBorder 
call initialize
mov byte[Emode],1
jmp do

medium1:
call clrscr
call printBorder1 
call initialize
mov byte[Mmode],1
jmp do

difficuilt:
call clrscr
call printBorder2 
call initialize
mov byte[Dmode],1


do:
xor  ax, ax               
mov  es, ax                       ; point es to IVT base   
mov ax,[es:9*4]
mov [oldkb],ax
mov ax,[es:9*4+2]
mov [oldkb+2],ax

cli                                  ; disable interrupts      

mov  word [es:9*4], kbisr          ; store offset at n*4               
mov  [es:9*4+2], cs               ; store segment at n*4+2

mov  word [es:8*4], timer          ; store offset at n*4               
mov  [es:8*4+2], cs               ; store segment at n*4+2  

sti                               ; enable interrupts      

ending:
mov  dx, start                    ; end of resident portion               
add  dx, 15                       ; round up to next para               
mov  cl, 4               
shr  dx, cl                       ; number of paras                
mov  ax, 0x3100                   ; terminate and stay resident               
int  0x21 

sec: dw 0
tick: db 0
min:dw 0
dmin:dw 3
dsec:dw 59
Emode: db 0
Mmode:db 0
Dmode:db 0
r_l: db 'Remaining Lives:'
r_t:db 'Time Left:'
s_m: db 'Score:'
message:db'Welcome to the Snake Game'
message1:db 'Instructions: 1)To move the snake left, right, up and down use Left, Right, Up and Down keys Respectively'
message2: db 'You are given with three lives touching to the boundary and with snake body loses one life'
message3: db 'Maximum size of snake can be 240. If this size is not gain in 4 mins one life will be end otherwise you win'
message4: db 'Select the level you want to chose'
message5: db '1)Easy(Press e)  2)Medium(Press m)   3)Difficult(Press d)'
ending_message1: db 'You Win. And Score is:'
ending_message: db 'You Lose. And Score is :'
snakehead: dw 1980
snaketail: dw 0                  ; To store snake tail 
tickcount:  dw 0
second: dw 1
snakesize: dw 20
currentpos: dw 0
oldkb: dd 0
up: dw 0
move: dw 0
down: dw 0
left: dw 1
right: dw 0
head: dw 0
incsize: dw 0
lives: dw 3
len1: dw 6
temp: dw 0
fruitloc: dw 0
score: dw 0
speed: db 14
pfruit: dw 0      ; if fruit is present or not
fcount: dw 0
fruit: db 'a','b','&','^','*','+','$','$','~','=',0
snake: dw 0

