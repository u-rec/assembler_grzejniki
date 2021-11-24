section .bss

dims    resd    2       ; ywmiary planszy
size    resd    1
actual  resb    1       ; która z 2 tablic ma aktualne wartości
tab     resq    1       ; wskaźniki do tablic floatow
stepn   resd    1       ; który to krok
g_num   resd    1       ; liczba wszystkich grzejników
gtlist  resq    1       ; lista temperatur wszystkich grzejników
gxlist  resq    1       ; lista pozycji x -//-
gylist  resq    1       ;      -//-     y -//-
c_temp  resd    1       ; wskaźnik do temperatury brzegu
weight  resd    1       ; wskaźnik do wagi symulacji

section .text
global start
global place
global step
extern print_state
extern malloc
        

start:
        movss   [rel c_temp], xmm0  ; temperatura chłodnicy
        movss   [rel weight], xmm1  ; waga symulacji
        mov     [rel dims], edi     ; przesuń szerokość do dims[rel 0]
        mov     [rel dims + 4], esi
        mov     [rel tab], rdx      ; wskaźnik do tablicy floatow
        mov     eax, esi        ; wysokość w eax
        mov     [rel dims + 0x4], eax       ;wysokość do dims[rel 1]
        imul    edi             ; szer * wys -> eax
        mov     [rel size], eax
        xor     eax, eax
        mov     [rel actual], al    ; która tablica jest aktualna
        mov     [rel stepn], eax      ; który to krok
        ret

place:                          ;dla każdej tablicy (x, y, temp) alokuje pamiec (malloc) i kopiuje zawartosc (rep movsd)
        push    rsi             ;tablica x
        push    rdx             ;talibca y
        push    rcx             ; tablica temperatur
        mov     [rel g_num], edi    ; l grzejników
        shl     edi, 2          ; bajty
        call    malloc 
        mov     [rel gtlist], rax   ; repeat 
        mov     edi, [rel g_num]
        shl     edi, 2
        call    malloc
        mov     [rel gxlist], rax
        mov     edi, [rel g_num]
        shl     edi, 2
        call    malloc
        mov     [rel gylist], rax
        mov     ecx, [rel g_num]
        pop     rsi             ;temperatury
        mov     rdi, [rel gtlist]
        rep     movsd
        mov     ecx, [rel g_num]
        pop     rsi             ;y
        mov     rdi, [rel gylist]
        rep     movsd
        mov     ecx, [rel g_num]
        pop     rsi             ;x
        mov     rdi, [rel gxlist]
        rep     movsd
        ret

chlodnica:                      ; szukane pole to chlodnica, zwroc temperature przywracajac stos do stanu sprzed wywolania prosby o pole obok
        add     rsp, 8
        mov     ecx, [rel c_temp]
        ret

left_temp:                      ;zaladowac aktualny numer pola do eax; funkcja zwraca temp. pola po lewej
        push    rax             ; zapamietuje aktualne pole
        xor     edx, edx
        div     DWORD [rel dims]
        test    edx, edx        ; sprawdzam, czy jest w 1 kolumnie
        jz      chlodnica       ;jesli tak zwracam stala c_temp
        movzx   eax, BYTE [rel actual]  ;sprawdzam ktora polowa macierzy ma dane o aktualnym kroku
        test    eax, eax
        jnz     left_druga      ; trzeba pobrac dane z 2 polowy macierzy
        pop     rax
        dec     eax
        mov     ecx, [r9 + 4 * rax]     ;pobieram pole po lewej z 1 polowy macierzy
        ret
left_druga:
        pop     rax     
        dec     eax
        add     eax, [rel size]  
        mov     ecx, [r9 + 4 * rax]     ;pobieram pole po lewej z 2 polowy macierzy
        ret

right_temp:                      ;zaladowac aktualny numer do eax; analogicznie jak lewa, inne funkcje sprawdzające brzeg
        push    rax
        inc     eax
        xor     edx, edx
        div     DWORD [rel dims]
        test    edx, edx
        jz      chlodnica
        movzx   eax, BYTE [rel actual]
        test    eax, eax
        jnz     right_druga
        pop     rax
        inc     eax
        mov     ecx, [r9 + 4 * rax]
        ret
right_druga:
        pop     rax
        inc     eax
        add     eax, [rel size]
        mov     ecx, [r9 + 4 * rax]
        ret

up_temp:                ;analogiczne jak lewo/prawo, inne funkcje sprawdzające brzeg
        push    rax
        xor     edx, edx
        div     DWORD [rel dims]
        test    eax, eax
        jz      chlodnica
        movzx   eax, byte [rel actual]
        test    eax, eax
        jnz     up_druga
        pop     rax
        sub     eax, DWORD [rel dims]
        mov     ecx, [r9 + 4 * rax]
        ret
up_druga:
        pop     rax
        sub     eax, DWORD [rel dims]
        add     eax, [rel size]
        mov     ecx, [r9 + 4 * rax]
        ret

down_temp:              ;analogicznie jak pozostale
        push    rax
        xor     edx, edx
        div     DWORD [rel dims]
        inc     eax
        cmp     DWORD [rel dims + 0x4], eax
        jbe     chlodnica
        movzx   eax, byte [rel actual]
        test    eax, eax
        jnz     down_druga
        pop     rax
        add     eax, DWORD [rel dims]
        mov     ecx, [r9 + 4 * rax]
        ret
down_druga:
        pop     rax
        add     eax, DWORD [rel dims]
        add     eax, [rel size]
        mov     ecx, [r9 + 4 * rax]
        ret

this_val:               ;pobierz temperaturę pola o numerze w rax
        movzx   ecx, byte [rel actual]
        test    ecx, ecx
        jnz     this_druga
        mov     ecx, [r9 + 4 * rax]     ;1 polowa
        ret
this_druga:                             ; 2 polowa
        add     eax, [rel size]
        mov     ecx, [r9 + 4* rax]      
        ret

step:
        push    rbx
        mov     r9, [rel tab]           ;zaladuj adres macierzy 
        mov     r8d, [rel size]         ; zaladuj rozmiar macierzy
        test    r8d, r8d
        jz      end_state
        dec     r8d
loop_step:
        finit                           ;inicjalizacja procesora fpu
        mov     eax, r8d
        call    this_val                ;wynik w rcx
        push    rcx
        fld     DWORD [rsp]             ;ładuje wynik na stos fpu
        add     rsp, 8                  ;i usuwa ze stosu memory
        mov     eax, r8d
        call    left_temp
        push    rcx
        fld     DWORD [rsp]             ;laduje temperature po lewej na stos fpu
        fsub    st1
        fstp    DWORD [rsp]             ;w pamieci podmiana temperatury lewej komorki na roznice
        mov     eax, r8d
        call    right_temp              ;dalej analogicznie jak dla lewej
        push    rcx
        fld     DWORD [rsp]
        fsub    st1
        fstp    DWORD [rsp]
        mov     eax, r8d
        call    up_temp
        push    rcx
        fld     DWORD [rsp]
        fsub    st1
        fstp    DWORD [rsp]
        mov     eax, r8d
        call    down_temp
        push    rcx
        fld     DWORD [rsp]
        fsub    st1
        fstp    DWORD [rsp]
        fldz
        fadd    DWORD [rsp]             ;dodanie wyliczonych wczesniej roznic 
        fadd    DWORD [rsp + 8]
        fadd    DWORD [rsp + 16]
        fadd    DWORD [rsp + 24]
        add     rsp, 32                 ;porzadek w stosie
        fld     DWORD [rel weight]      ;pomnozenie razy stala
        fmul    st1
        fadd    st2
        movzx   ebx, byte [rel actual]  ;sprawdzenie gdzie zapisac
        test    ebx, ebx
        jz      save_in_second
        fstp    DWORD [r9 + 4 * r8]     ;w pierwszej polowce macierzy
        jmp     end_save
save_in_second:                         ; w drugiej polowce macierzy
        mov     ecx, [rel size]
        add     ecx, r8d
        fstp    DWORD [r9 + 4 * rcx]
end_save:
        dec     r8d                     ;czy sa jeszcze komorki do obliczenia
        cmp     r8d, 0
        jnl     loop_step
        mov     ebx, [rel g_num]        ;podmien grzejniki na stala
        test    ebx, ebx
        jz      zero_g                  ;chyba ze ich nie ma
        dec     ebx
loop_g:
        mov     r10, [rel gylist]       ;zaladuj do pamieci odpowiednia listy, policz (y*width+x)
        mov     eax, [r10 + 4*rbx]      
        mov     edi, [rel dims]
        imul    edi
        mov     r10, [rel gxlist]
        add     eax, [r10 + 4*rbx]      ;numer komorki z grzejnikiem do eax
        movzx   edx, byte [rel actual]  ;sprawdz polowke
        mov     r10, [rel gtlist]
        mov     ecx, [r10 + 4*rbx]      ;temperatura do podmiany
        test    edx, edx
        jz      save_g_in_sec
        mov     [r9 + 4*rax], ecx       ;zapisz temperature do odpowiedniej komorki pamieci
        jmp     end_save_g
save_g_in_sec:                          ;w 2 polowie macierzy
        mov     esi, [rel size]
        add     esi, eax
        mov     [r9 + 4*rsi], ecx
end_save_g:
        dec     ebx
        cmp     ebx, 0
        jnl     loop_g
zero_g:
        inc     DWORD [rel stepn]       ;na koniec: zwieksz numer kroku
        lea     rdi, [r9]               ; zaladuj adres macierzy 
        mov     esi, [rel dims]         ;zaladuj wymiary 
        mov     edx, [rel dims+0x4]
        inc     byte [rel actual]       ;zmiana numeru polowki
        and     byte [rel actual], 1
        movzx   ecx, byte [rel actual]  
        call    print_state             ;wypisanie stanu
end_state:
        pop     rbx                     ;koniec: przywroc rbx <abi>
        ret


