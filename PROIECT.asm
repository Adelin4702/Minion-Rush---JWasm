.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern memmove: proc
extern printf: proc
extern fprintf: proc
extern fopen: proc
extern fclose: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Exemplu proiect desenare",0
area_width EQU 601
area_height EQU 800
area DD 0

culoare DD 0F51D07h

mat_width EQU 5
mat_height EQU 16
mat DD 0

var_timp DD 0

file_name DB "score.txt" ,0 
fopen_format DB "a" ,0 
format DB "Scorul tau: %d ", 13, 10, 0
new_walls DD 2
nr_linii DD 16
coloana DD 2
var_arg DD 0
caracter DD 0
walls DD 0
banannas DD 1
new_banannas DD 1
contor DD 0
score DD 0
var_GO DD 0
f_ptr DD 0
var_coliziune DD 0
pornire DD 0

constanta_viteza DD -1


counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc


.code

initializare_mat proc
	push ebp
	mov ebp, esp
	
	;mov edi, area
	
	mov eax, mat_width
	mov ebx, mat_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov mat, eax
	
	mov eax, mat_height
	mov ebx, mat_width
	mul ebx
	mov ecx, eax
	
	mov edi, mat
	
	pune_0: 
		mov dword ptr [edi], 0
		add edi, 4
	loop pune_0
	
	mov esp, ebp
	pop ebp
	ret
initializare_mat endp


actualizare_mat proc
	push ebp
	mov ebp, esp
	
	mov eax, [ebp+8]
	mov walls, eax
	
	mov eax, [ebp+12]
	mov banannas, eax
	
	

	mov eax, mat_height ;;; plecam de la primul el de pe penultima linie
	sub eax, 2
	mov ebx, mat_width
	mul ebx
	inc eax
	shl eax, 2
	add eax, mat
	mov edi, eax
	
	mov ecx, mat_height ;;;calculam nr de elem peste care ne deplasam
	;dec ecx
	
	mov eax, mat_width  ;; calculam dim unei linii
	shl eax, 2
	
	muta_linii:
	    push ecx
		mov eax, mat_width
		shl eax, 2
		push eax
		push edi
		add eax, edi
		push eax
		call memmove
		add esp, 12
		
	    sub edi, 20
		
		pop ecx
	loop muta_linii
	
	
	;; punem bananele pe prima linie
	mov edi, mat
	mov edx, banannas
	mov ecx, 5
	ror edx, 3
	
	pune_banane:
		shr edx, 1
		jc pune_index_banana
		mov dword ptr[edi], 0
		jmp pus_banana
		
		pune_index_banana:
			mov dword ptr[edi], 2
			
		pus_banana:
			add edi, 4
	loop pune_banane
	
	;; punem prima linie
	mov edi, mat
	mov edx, walls
	mov ecx, 5
	
	pune_zid:
		shr edx, 1
		jc pune_culoare_zid
		;mov dword ptr[edi], 0
		jmp pus
		
		pune_culoare_zid:
			mov dword ptr[edi], 1
			
		pus:
			add edi, 4
	loop pune_zid
	
	mov esp, ebp
	pop ebp
	ret 8
actualizare_mat endp

afisare_mat proc
	push ebp
	mov ebp, esp


	mov edi, area ;; Registru pt afisare
	mov esi, mat ;; Regsitru pt deplasare pe mat

	mov nr_linii, 16
	afisare_linii:
		;push edx
		mov ebx, 5 ; 5 elemente per linie

		afisare_element:
		mov ecx, 50 ; 50 de linii un element
		push ebx ; salvam ebx pe stiva

		coloreaza:
			mov ebx, 120 ; lungimea liniei unui element e 120 de pixeli
			coloreaza_linie:
				cmp dword ptr [esi], 1 ; e zid
				je colo_zid
				
				cmp dword ptr [esi], 2 ; e banana
				je colo_banana
				
				mov dword ptr[edi], 168927h
				jmp continua
				
				colo_banana:
				mov dword ptr[edi], 0F9E410h
				jmp continua
				
				colo_zid:
				mov dword ptr[edi], 0E87E0Dh
				continua:
				add edi, 4
				dec ebx
				cmp ebx, 0
			ja coloreaza_linie

			mov eax, area_width
			sub eax, 120
			shl eax, 2
			add edi, eax
		loop coloreaza
		
		; aici putem sa folosim ebx fara sa il salvam pentru ca valoarea initiala cu 5 se afla pe stiva
		mov eax, area_width
		mov ebx, 50
		mul ebx
		shl eax, 2
		sub edi, eax
		add edi, 480
		
		add esi, 4
		
		pop ebx
		dec ebx
		cmp ebx, 0
		ja afisare_element

	add edi, 4
	push eax
	
	mov eax, area_width
	mov ebx, 49
	mul ebx
	shl eax, 2
	add edi, eax
	
	pop eax
	 mov edx, nr_linii
	 dec edx
	 mov nr_linii, edx
	
	cmp edx, 0
	jnbe afisare_linii
    
	push ecx
	
	mov ecx, coloana	
	push coloana
	call minion
	
	pop ecx
	
	mov esp, ebp
	pop ebp
	ret
afisare_mat endp

new_state proc
	push ebp
	mov ebp, esp
	
	mov eax, [ebp+8];; arg1
	mov var_arg, eax
	
	mov eax, [ebp+12] ; arg2 =X
	mov caracter, eax
	
	mov ecx, [ebp+16]		 ; coloana

	mov eax, var_arg
	cmp eax, 2
	je final_new_state
	
	cmp eax, 3
	jne final_new_state
	
	mov eax, caracter
	cmp eax, 'A'
	jne Not_A
	
	cmp ecx, 0
	je final_new_state
	sub ecx, 1
	
	jmp final_new_state
	
	Not_A:
		cmp eax, 'D'
		jne final_new_state
	
		cmp ecx, 4
		jae final_new_state
	 
	inc ecx
	
	
	;coloana este singura care se poate schimba, deci ramane in ecx
	final_new_state:
	mov coloana, ecx
	mov esp, ebp
	pop ebp
	ret 12
new_state endp



; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width  ;;; 10!!! STANDARD si  nu se poate schimba 
	mul ebx
	mov ebx, symbol_height ;; 20 !!! STANDARD si  nu se poate schimba
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm



minion proc
	push ebp
	mov ebp, esp 

	mov eax, [ebp+8]
	mov ebx, 120
	mul ebx
	add eax, 60
	make_text_macro 'Q', area, eax , 775
	mov esp, ebp
	pop ebp
	ret 4
minion endp


game_over_and_score proc
	push ebp
	mov ebp, esp
	
	push eax
	push ebx
	push ecx
	push edx
	push edi
	
	
	cmp var_GO, 0
	je game_over_nou
	
	mov var_GO, 2
	jmp final_game_over
	
	game_over_nou:
	mov ebx, mat_height
	sub ebx, 1
	mov eax, mat_width
	mul ebx
	add eax, coloana
	shl eax, 2
	
	mov edi, mat
	add edi, eax
	
	cmp dword ptr [edi], 1
	jne nu_e_coliziune
	
	mov var_GO, 1
	
	nu_e_coliziune:
	cmp dword ptr [edi], 2
	jne final_game_over
	inc score
	
	final_game_over:
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop eax
	
	
	mov esp, ebp
	pop ebp
	ret
game_over_and_score endp

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta si X va contine codul ascii )
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	call game_over_and_score
	cmp var_GO, 1
	je afis_game_over
	
	cmp var_GO, 2
	je final_draw
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	
	
	cmp eax, 3
	jz evt_keyboard
	
	cmp eax, 2
	jz evt_time
	
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset  ;; memset(zona de memorie, , valoarea pusa in fiecare fragment de zona, lungimea zonei)
	add esp, 12
	
	;mov eax, area_width 
	;shl eax, 2
	; mov edi, area
	
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	
	push eax
	push 056EE29h
	push area
	call memset
	add esp, 12

	
	make_text_macro 'E', area, 0, 0
	make_text_macro 'A', area, 10, 0
	make_text_macro 'S', area, 20, 0
	make_text_macro 'Y', area, 30, 0           
	
	make_text_macro 'H', area, 560, 0
	make_text_macro 'A', area, 570, 0
	make_text_macro 'R', area, 580, 0
	make_text_macro 'D', area, 590, 0
	
	make_text_macro 'X', area, 260, 0   ; X = sageata stanga
	make_text_macro 'C', area, 270, 0
	make_text_macro 'H', area, 280, 0
	make_text_macro 'O', area, 290, 0
	make_text_macro 'O', area, 300, 0
	make_text_macro 'S', area, 310, 0
	make_text_macro 'E', area, 320, 0
	make_text_macro 'W', area, 330, 0   ; Y = sageata dreapta

	
	evt_click:
		push eax
		push ebx
		
		mov eax, [ebp+arg2]  ;; x
		mov ebx, [ebp+arg3]  ;; y
		
		cmp ebx, 15
		ja apasat_in_afara
		
		cmp eax, 0
		jbe apasat_in_afara
		
		cmp eax, 40
		ja nu_e_easy
		
		mov constanta_viteza, 2
		jmp Porneste
		
		nu_e_easy:
			cmp eax, 560
			jb apasat_in_afara
			
		mov constanta_viteza, 0
		
		cmp constanta_viteza, -1
		je apasat_in_afara
		
		Porneste:
			mov pornire, 1
		
		apasat_in_afara:
		pop ebx
		pop eax
	
		jmp final_draw
		
	
	
	evt_keyboard:
	
		cmp pornire, 0
		je final_draw
		
		push coloana
		push [ebp+arg2]
		push [ebp+8]
		call new_state
		
		jmp afiseaza_matricea
		
	evt_time:
		cmp pornire, 0
		je final_draw
	
		;push eax
		mov eax, constanta_viteza
		cmp var_timp, eax
		jb afiseaza_matricea
		;pop eax
		
		
		mov var_timp, 0
		
		cmp contor, 4
		jb apeleaza_cu_0
			push eax
			push ebx
			push edx
		
			mov eax, new_banannas
			mov ebx, 11
			mul ebx
			mov new_banannas, eax
		
			pop edx
			pop ebx
			pop eax
			
			mov contor, 0
			push eax     ;;  generare ziduri random
			push edx
			push ebx
		
			mov eax, new_walls
			mov ebx, 3
			mul ebx
			mov new_walls, eax
		
			pop ebx
			pop edx
			pop eax
		
			add new_walls, 3
		
			push new_banannas
			push new_walls
			call actualizare_mat
			
			jmp afiseaza_matricea
			
		apeleaza_cu_0:
			inc contor
			push 0
			push 0
			call actualizare_mat
			
		afiseaza_matricea:
			inc var_timp
			call afisare_mat
		
		
	;; linii paralele ||  Verticale
	mov ecx, area_height;; lungimea
	
	mov eax, 0
    mov eax, area_width
    mov ebx, 5
	div ebx
	shl eax, 2
	add eax, area
	
	mov edi, eax
		
	bucla_verticale:
		
		mov dword ptr [edi], 0
	    mov dword ptr [edi+120*4], 0
		mov dword ptr [edi+240*4], 0
		mov dword ptr [edi+360*4], 0
		
		mov eax, area_width
		shl eax, 2
		add edi, eax
		
	loop bucla_verticale
	
	jmp final_draw
	
	afis_game_over:
		make_text_macro 'G', area, 260, 400
		make_text_macro 'A', area, 270, 400
		make_text_macro 'M', area, 280, 400
		make_text_macro 'E', area, 290, 400
		
		make_text_macro 'O', area, 310, 400
		make_text_macro 'V', area, 320, 400
		make_text_macro 'E', area, 330, 400
		make_text_macro 'R', area, 340, 400
		
	
		push eax
		push ebx
		push ecx
		push edx
		push edi

		mov eax, coloana
		mov ebx, 120
		mul ebx
		add eax, 30
		
		mov var_coliziune, eax
		make_text_macro 'T', area, var_coliziune, 765
		add var_coliziune, 10
		make_text_macro 'B', area, var_coliziune, 765
		add var_coliziune, 10
		make_text_macro 'O', area, var_coliziune, 765
		add var_coliziune, 10
		make_text_macro 'O', area, var_coliziune, 765
		add var_coliziune, 10
		make_text_macro 'M', area, var_coliziune, 765
		add var_coliziune, 10
		make_text_macro 'T', area, var_coliziune, 765
		
		pop esi
		pop edx
		pop ecx
		pop ebx
		pop eax
		
		
	;;;;;;scrie_in_fisier
		
		push offset fopen_format
		push offset file_name
		call fopen
		add esp, 8
		mov f_ptr, eax

		
		push score
		push offset format
		push f_ptr
		call fprintf
		add esp, 12
		
		push  f_ptr
		call fclose
		add esp, 4
		
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start: ;;;; SITE CULORI HTML COLOR CODES


	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	
	
	call initializare_mat
	
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	terminarea_programului:
	
	;??? Scriere in fisier
	
	cmp constanta_viteza, 0
	je viteza_normala
	
		shr score, 1
		
	viteza_normala:
	mov ebx, score
	push score
	push offset format
	call printf
	add esp, 8
	push 0
	call exit
end start
