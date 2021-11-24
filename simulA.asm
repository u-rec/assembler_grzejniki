section .data

ALL_ST  dd      10000

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
        movss   [rel c_temp], dword xmm0  ; temperatura chłodnicy
        movss   [rel weight], dword xmm1  ; waga symulacji
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

place:
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

chlodnica:
        add     rsp, 8
        mov     ecx, [rel c_temp]
        ret

left_temp:                      ;zaladowac aktualny numer do eax
        push    rax
        xor     edx, edx
        div     DWORD [rel dims]
        test    edx, edx
        jz      chlodnica
        movzx   eax, BYTE [rel actual]
        test    eax, eax
        jnz     left_druga
        pop     rax
        dec     eax
        mov     ecx, [r9 + 4 * rax]
        ret
left_druga:
        pop     rax
        dec     eax
        add     eax, [rel size]  
        mov     ecx, [r9 + 4 * rax]
        ret

right_temp:                      ;zaladowac aktualny numer do eax
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

up_temp:
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

down_temp:
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

this_val:
        movzx   ecx, byte [rel actual]
        test    ecx, ecx
        jnz     this_druga
        mov     ecx, [r9 + 4 * rax]
        ret
this_druga:      
        add     eax, [rel size]
        mov     ecx, [r9 + 4* rax]
        ret

step:
        push    rbx
        mov     r9, [rel tab]
        mov     eax, [rel stepn]
        cmp     eax, [ALL_ST]
        jge     end_state
        mov     r8d, [rel size]
        test    r8d, r8d
        jz      end_state
        dec     r8d
loop_step:
        finit
        finit
        mov     eax, r8d
        call    this_val
        push    rcx
        fld     DWORD [rsp]
        add     rsp, 8
        mov     eax, r8d
        call    left_temp
        push    rcx
        fld     DWORD [rsp]
        fsub    st1
        fstp    DWORD [rsp] ;podmiana wierzchołka stosu na różnicę z lewą
        mov     eax, r8d
        call    right_temp
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
        fadd    DWORD [rsp]
        fadd    DWORD [rsp + 8]
        fadd    DWORD [rsp + 16]
        fadd    DWORD [rsp + 24]
        add     rsp, 32
        fld     DWORD [rel weight]
        fmul    st1
        fadd    st2
        movzx   ebx, byte [rel actual]
        test    ebx, ebx
        jz      save_in_second
        fstp    DWORD [r9 + 4 * r8]
        jmp     end_save
save_in_second:
        mov     ecx, [rel size]
        add     ecx, r8d
        fstp    DWORD [r9 + 4 * rcx]
end_save:
        dec     r8d
        cmp     r8d, 0
        jnl     loop_step
        mov     ebx, [rel g_num]
        test    ebx, ebx
        jz      zero_g
        dec     ebx
loop_g:
        mov     r10, [rel gylist]
        mov     eax, [r10 + 4*rbx]
        mov     edi, [rel dims]
        imul    edi
        mov     r10, [rel gxlist]
        add     eax, [r10 + 4*rbx]
        movzx   edx, byte [rel actual]
        mov     r10, [rel gtlist]
        mov     ecx, [r10 + 4*rbx]
        test    edx, edx
        jz      save_g_in_sec
        mov     [r9 + 4*rax], ecx
        jmp     end_save_g
save_g_in_sec:
        mov     esi, [rel size]
        add     esi, eax
        mov     [r9 + 4*rsi], ecx
end_save_g:
        dec     ebx
        cmp     ebx, 0
        jnl     loop_g
zero_g:
        inc     DWORD [rel stepn]
        lea     rdi, [r9]
        mov     esi, [rel dims]
        mov     edx, [rel dims+0x4]
        inc     byte [rel actual]
        and     byte [rel actual], 1
        movzx   ecx, byte [rel actual]
        call    print_state
end_state:
        pop     rbx
        ret


