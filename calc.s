section .data
    err: db "Error: Insufficient Number of Arguments on Stack",10,0
    err2: db "Error: Operand Stack Overflow",10,0
    err3: db "wrong Y value",10,0
    inp: db "calc: ",0
    head: dd 0
    next_char: db 0
    buf_in: dd 0
    next_link_add: dd 0
    dec: db 0
    finished_read: dd 0
    count_loop_times: dd 0
    sum_carry: dd 0
    odd_num: dd 0
    last_link: dd 0
    pos_pow_counter: dd 0
    pos_pow_activated: dd 0
    neg_pow_counter: dd 0
    prev: dd 0
    curr: dd 0
    count_hex_digits: dd 0
    convert_val: dd 0
    total_operations_done: dd 0
    add_to_delete_1: dd 0
    add_to_delete_2: dd 0
    debug_activated: dd 0

section .rodata
    format_err: db "%s",0
    format_err2: db "%s",0
    format_inp: db "%s",0
    format_char: db "%c" ,0
    format_int: db "%i" ,10, 0
    format_char_pop_and_print: db "%X" ,0
    format_enter: db "%X",10 ,0
    format_padding_zeros: db "%02X" ,0

section .bss
    stack_size equ 5
    stack: resd stack_size
    buf: resb 81
    temp_buf: resb 81
    temp_buf2: resb 81

section .text
align 16
     global main 
     extern printf 
     extern fflush
     extern malloc 
     extern calloc 
     extern free 
     extern gets 
     extern fgets
     extern getchar

jmp main

%macro pop_op 0; pop the last operand in the per stack
    cmp dword [head] , 0;check if the stack is empty
    je %%popError;if the stack is empty jump to send error
    sub dword [head] , 1; -1 to head, to pop the last operand (the orignal head point to the next available place
    mov eax , [head];move head to eax, in the next 4 rows we calculate the adress to the right place in the stack
    mov ebx , 4
    mul ebx
    add eax , stack
    mov edx , [eax] ;move the pointer adress as prepariton for push
    ;mov ecx , 0
    ;mov byte ecx , [edx]
    push edx
    jmp %%final_pop_op
    %%popError:
        push err
        push format_err
        call printf
        jmp loop_input
    %%final_pop_op:
       ;; inc dword [total_operations_done]
%endmacro

%macro push_op 1; push the next operand to the stack
    mov cl , %1;move to ecx the argument (the number that we want to add to the list)
    mov byte [next_char] , 0
    mov byte [next_char] , cl; update next_char with the next char to insert
    cmp dword [head] , stack_size;check if there is 5 operand in the stack, if there is we jump for sending error
    ;cmp dword [head] , 5
    je %%pushError
    mov dword ecx , 1;in the next 5 rows we allocate new memory to the next number 
    mov dword ebx , 5
    push ecx
    push ebx
    call calloc
    mov ecx , eax;save the pointers that gets from the calloc func
    mov eax , [head];in the next 4 rows we calculate the adrees for saving the new pointer (the new number)
    mov ebx , 4
    mul ebx
    add eax , stack
    mov [eax] , ecx;save the new pointer in the right place in the stack
    mov edx , 0
    mov dl , [next_char]
    mov [ecx] , dl;save the number in memory
    add dword [head] , 1;incress the head (+1)
    jmp %%final_push_op
    %%pushError:
        push err2
        push format_err2
        call printf
    %%final_push_op:
%endmacro

%macro hexa_to_decimal 0
    mov ebx , buf ;calculate decimal value of the 2 hexadecimal digits
    add ebx , [buf_in]
    mov edx , 0
    mov dl , [ebx]
    cmp dl , 0
    je %%fin_hexa_to_decimal
    mov ebx ,[buf_in]
    add ebx ,1
    mov [buf_in], ebx
    mov ebx, buf
    add ebx, [buf_in]
    mov ecx , 0
    mov cl, [ebx]
    cmp cl , 0
    je %%odd_num
    %%continue_hexa_to_decimal:
        mov eax, 0
        mov al, dl
        cmp al , 65
        jge %%capital_letter1
        sub al, 48
        jmp %%next_letter
        %%capital_letter1:
            sub al , 55
        %%next_letter:
        cmp cl , 65
        jge %%capital_letter2
        sub cl, 48
        jmp %%next_letter2
        %%capital_letter2:
            sub cl , 55
        %%next_letter2:
        mov ebx , 0
        mov bl,16
        mul bl
        add al, cl
        mov byte [dec] , al
        add dword [buf_in] , 1
        cmp dword [finished_read] , 1
        jne %%fin_hexa_to_decimal
        ;mov dl , 0
        jmp connect_odd
        ;jmp %%fin_hexa_to_decimal
    %%odd_num:
        mov dword [finished_read] , 1
        mov cl , dl
        mov dl , 48
        jmp %%continue_hexa_to_decimal
    %%fin_hexa_to_decimal:
%endmacro

%macro decimal_to_hexa 1
    pushad
    
    mov eax , %1
    mov dword [convert_val] , eax ; Save the dec value we want to convert
    
    mov ebx , 0
    
    ; Count the number of hex digits that will be after the conversion
    %%loop_hex:
        cmp dword eax , 16
        jb %%before_counted
        mov ebx , 16
        mov edx , 0
        cwd
        div ebx
        inc dword [count_hex_digits]
        jmp %%loop_hex
    
    ; prepare all registers to the conversion
    %%before_counted:
    popad
    mov dword eax , [convert_val]
    mov dword edi , [count_hex_digits]
    push edi
    
    cmp dword eax , 0
    jne %%counted
    mov byte [buf] , 48
    jmp %%finished_dec_to_hex
    
    ; Convert the dec number by divide it in each iteration by 16 . 
    ;The Sheerit we get is the mist right digit we did not found yet
    %%counted:
        mov edx , 0
        cmp dword eax , 0
        je %%finished_dec_to_hex
        mov ebx , 16
        cwd
        div ebx
        ; Calculate the right place for the digit
        mov dword ecx , [count_hex_digits]
        mov dword esi , buf
        add dword esi , ecx
        mov byte [esi] , dl
        cmp dl , 9
        ja over_9
        add dword [esi] , 48
        jmp after_over_9
        over_9:
        add dword [esi] , 55
        after_over_9:
        ; Return the buf value to the original value
        sub dword esi , ecx
        dec dword [count_hex_digits]
        jmp %%counted
    ; add terminating 0 at the end of the buffer
    %%finished_dec_to_hex:
        pop edi
        mov dword [count_hex_digits] , edi
        inc dword [count_hex_digits]
        mov eax , buf
        add eax , [count_hex_digits]
        ;inc eax
        mov byte [eax] , 0
        ;dec eax
        sub eax , [count_hex_digits]
%endmacro

%macro free_memory 1
    mov eax , %1
    %%free_loop:
        inc eax
        cmp dword [eax] , 0
        je %%free_last_one
        mov ebx , [eax]
        dec eax
        push ebx
        push eax
        call free
        pop eax
        pop ebx
        mov eax , ebx
        jmp %%free_loop
    %%free_last_one:
        dec eax
        push eax
        call free
%endmacro

add_operand:;function that enter entire number as linked list to the stack
    hexa_to_decimal
    ; what else we need to do is to enter the decimal value to a varaiable of type byte and its the value that we need to enter to the linked list
    cmp byte dl , 0;if the value is 0 we finished to read all the number
    je add_operand_check_debug
    connect_odd:
    cmp dword [buf_in] , 2;buf_in countes the number of digits we already read from buffer, if its zero we need to push new linked list to the stack
    je push_first
    mov eax , -1 ;calculate the value of the top of the stack and put it in eax
    add eax , [head]
    mov ebx , 4
    mul ebx
    add eax , stack
    mov edx , [eax]
    mov [next_link_add] , edx ;save the next value of the linked list that the new item will point at
    ; allocate new space for new link
    mov dword ecx , 1
    mov dword ebx , 5
    push ecx
    push ebx
    call calloc
    ; calculate again the top of the stack
    mov ecx , eax
    mov eax , -1
    add eax , [head]
    mov ebx , 4
    mul ebx
    add eax , stack
    mov [eax] , ecx
    ;mov ebx , buf
    ;add ebx , [buf_in]
    ;mov dl , [ebx]
    mov ebx , [dec]
    mov [ecx] , ebx ; enter the value of the number to the new space allocated. we probably need to change this! because we didnt changed the decimal value to the byte value
    inc ecx
    mov edx , [next_link_add] ;make the link point to the next link
    mov dword [ecx] , edx
    jmp add_operand
    push_first:
        ;hexa_to_decimal
        mov cl , [dec]
        push_op cl
        mov eax , -1 ;calculate the value of the top of the stack and put it in eax
        add eax , [head]
        mov ebx , 4
        mul ebx
        add eax , stack
        mov ebx , [eax]
        inc ebx
        mov dword [ebx] , 0
        jmp add_operand
    add_operand_check_debug:
        cmp dword [debug_activated] , 1
        je print_no_pop
        jmp loop_input


pop_and_print:
    inc dword [total_operations_done]
    n_pop_and_print:
    ; Cheack Stack validity
    cmp dword [head] , 0
    je PAndPError
    
    ; Pop first linked list in stack
    pop_op
    pop eax
    ;;dec dword [total_operations_done]
    mov dword [count_loop_times] , 1
    mov [add_to_delete_1] , eax
    ; Loop for push all the data of the links and their matching format
    loop:
        ; Push data
        mov ebx , 0
        mov bl , [eax]
        push ebx
        
        ;Check if this is the last link
        inc eax
        mov ecx , eax
        dec eax
        cmp dword [ecx] , 0
        je last_one
        
        ;Push the correct format
        push format_padding_zeros
        jmp after_last_one
        last_one:
            push format_char_pop_and_print
        
        ; Update values for next iteration
        after_last_one:
            inc eax
            cmp dword [eax] , 0
            je clean_useless_zeros
            mov eax , [eax]
            add dword [count_loop_times] , 1
            jmp loop
        
        ; If there are data of zeros in top of stack clean it
        clean_useless_zeros:
            ; put in ecx the data in the top of the stack
            ; Check if the data is zero
            ; if no zero continue
            ; else, pop it without printing it
            pop edx
            pop ecx
            cmp ecx , 0
            jne nozero
            dec dword [count_loop_times]
            cmp dword [count_loop_times] , 0
            jne clean_useless_zeros
            inc dword [count_loop_times]
            nozero:
                push ecx
                push format_char_pop_and_print ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
        ; print all data in stack
        end_of_list:
            cmp dword [count_loop_times] , 0
            je finish_print
            call printf
            dec dword [count_loop_times]
            pop edx
            pop edx
            jmp end_of_list
            finish_print:
                mov eax , 10
                push eax
                push format_char
                call printf
                jmp fin_pap
    PAndPError:
        push err
        push format_err
        call printf
        ;;inc dword [total_operations_done]
        cmp dword [debug_activated] , 1
        je print_no_pop
        jmp loop_input
    fin_pap:
        ;;inc dword [total_operations_done]
        free_memory [add_to_delete_1]
        cmp dword [debug_activated] , 1
        je print_no_pop
        jmp loop_input

print_no_pop:
    mov eax , [head]
    dec eax
    mov ebx , 4
    mul ebx
    add eax , stack
    
    mov eax , [eax]

    ;dec dword [total_operations_done]
    mov dword [count_loop_times] , 1
    mov [add_to_delete_1] , eax
    ; Loop for push all the data of the links and their matching format
    nnn_loop:
        ; Push data
        mov ebx , 0
        mov bl , [eax]
        push ebx
        
        ;Check if this is the last link
        inc eax
        mov ecx , eax
        dec eax
        cmp dword [ecx] , 0
        je nnn_last_one
        
        ;Push the correct format
        push format_padding_zeros
        jmp nnn_after_last_one
        nnn_last_one:
            push format_char_pop_and_print
        
        ; Update values for next iteration
        nnn_after_last_one:
            inc eax
            cmp dword [eax] , 0
            je nnn_clean_useless_zeros
            mov eax , [eax]
            add dword [count_loop_times] , 1
            jmp nnn_loop
        
        ; If there are data of zeros in top of stack clean it
        nnn_clean_useless_zeros:
            ; put in ecx the data in the top of the stack
            ; Check if the data is zero
            ; if no zero continue
            ; else, pop it without printing it
            pop edx
            pop ecx
            cmp ecx , 0
            jne nnn_nozero
            dec dword [count_loop_times]
            cmp dword [count_loop_times] , 0
            jne nnn_clean_useless_zeros
            inc dword [count_loop_times]
            nnn_nozero:
                push ecx
                push edx
        
        ; print all data in stack
        nnn_end_of_list:
            cmp dword [count_loop_times] , 0
            je nnn_finish_print
            call printf
            dec dword [count_loop_times]
            pop edx
            pop edx
            jmp nnn_end_of_list
            nnn_finish_print:
                mov eax , 10
                push eax
                push format_char
                call printf
                jmp nnn_fin_pap
    nnn_PAndPError:
        push err
        push format_err
        call printf
        jmp loop_input
    nnn_fin_pap:
        jmp loop_input
        
        
plus_op:
    inc dword [total_operations_done]
    n_plus_op:
    cmp dword [head] , 2
    jb plop_err
    
    mov dword [sum_carry] , 0
    pop_op
   ;; dec dword [total_operations_done]
    pop_op
   ;; dec dword [total_operations_done]
    pop ebx
    pop ecx
    mov dword [add_to_delete_1] , ebx
    mov dword [add_to_delete_2] , ecx
    push ebx
    push ecx
    mov edx , 0
    mov dl, [ebx]
    add dl, [ecx]
    jnc not_carry
    mov dword [sum_carry],1
    not_carry:
    mov ecx , 0
    push_op dl
    pop ebx
    pop ebx
    mov eax , [head];in the next 4 rows we calculate the adrees for saving the new pointer (the new number)
    dec eax
    mov ebx , 4
    mul ebx
    add eax , stack
    mov ebx , 0
    mov ebx ,[eax]
    mov [last_link],ebx
    pop ecx
    pop ebx
    inc ebx
    inc ecx
    mov ebx ,[ebx]
    mov ecx ,[ecx]
    push ebx
    push ecx
    loop_plus:
        cmp ebx,0
        je after_loop_plus
        cmp ecx , 0
        je ebx_to_ecx
        ;cmp ecx,1
        jmp con_loop_plus
        ebx_to_ecx:
        mov ecx , ebx
        jmp after_loop_plus
        con_loop_plus:
        mov dword ecx , 1
        mov dword ebx , 5
        push ecx
        push ebx
        call calloc
        pop ebx
        pop ebx
        pop ebx
        pop ecx
        mov dl, [ebx]
        cmp dword [sum_carry],1
        je update_carry1
        clc
        jmp continue_update_carry1
        update_carry1:
        stc
        continue_update_carry1:
        adc dl, [ecx]
        jnc not_carry1
        mov dword [sum_carry],1
        jmp continue_carry1
        not_carry1:
        mov dword [sum_carry],0
        continue_carry1:
        mov [eax], dl
        mov edx, [last_link]
        inc edx
        mov dword [edx], eax
        mov [last_link], eax
        inc ebx
        inc ecx
        mov ebx ,[ebx]
        mov ecx ,[ecx]
        push ebx
        push ecx
        jmp loop_plus
    after_loop_plus:
        cmp ecx,0
        je final_plus
        push ecx
        mov dword ecx , 1
        mov dword ebx , 5
        push ecx
        push ebx
        call calloc
        pop ebx
        pop ebx
        pop ecx
        mov dl, [ecx]
        cmp dword [sum_carry],1
        je update_carry2
        clc
        jmp continue_update_carry2
        update_carry2:
        stc
        continue_update_carry2:
        adc dl, 0
        jnc not_carry2
        mov dword [sum_carry],1
        jmp continue_carry2
        not_carry2:
        mov dword [sum_carry],0
        continue_carry2:
        mov [eax], dl
        mov edx, [last_link]
        inc edx
        mov [edx], eax
        mov [last_link], eax
        inc ecx
        mov ecx ,[ecx]
        jmp after_loop_plus
        final_plus:
            cmp dword  [sum_carry],1
            jne finish_plus
            mov dword ecx , 1
            mov dword ebx , 5
            push ecx
            push ebx
            call calloc
            pop ebx
            pop ebx
            mov edx, [last_link]
            inc edx
            mov [edx], eax
            mov byte [eax],1
            inc eax
            mov dword [eax],0
            free_memory [add_to_delete_1]
            free_memory [add_to_delete_2]
            cmp dword [pos_pow_activated] , 1
            je back_to_pos_pow_from_plus
            ;;inc dword [total_operations_done]
            ;mov dword esi , [add_to_delete_1]
            ;free_memory esi
            ;mov dword esi , [add_to_delete_2]
            ;free_memory esi
            cmp dword [debug_activated] , 1
            je print_no_pop
            jmp loop_input
            back_to_pos_pow_from_plus:
                jmp pos_pow_plus_fin
            finish_plus:
                mov edx, [last_link]
                inc edx
                mov dword [edx], 0
                free_memory [add_to_delete_1]
                free_memory [add_to_delete_2]
                cmp dword [pos_pow_activated] , 1
                je back_to_pos_pow_from_plus
               ;; inc dword [total_operations_done]
                cmp dword [debug_activated] , 1
                je print_no_pop
                jmp loop_input
    plop_err:
        push err
        push format_err
        call printf
        jmp loop_input
       
duplicate_op:
    inc dword [total_operations_done]
    ; calculate the place of the top of the stack
    n_duplicate_op:
    cmp dword [head] , stack_size
    ;cmp dword [head] , 5
    je duplicate_error
    
    cmp dword [head] , 0
    je duplicate_error_2
    
    mov eax , [head]
    dec eax
    mov ebx , 4
    mul ebx
    add eax , stack
    mov ebx , [eax]
    push eax
    push ebx
    
    ; Duplicate the first link and insert it to the top of the stack as a new number
    push_op [ebx]
    
    ; make ecx be the pointer on the duplicating number and ebx the pointer on the number we are duplicating
    pop ebx
    pop ebx
    pop ebx
    pop eax
    mov ecx , eax
    add dword  ecx , 4
    mov ecx , [ecx]
    inc ebx
    inc ecx
    push ebx
    push ecx
    
    loop_dup:
        ; if we arrive to the end of the number we are duplicating, finish the loop
        cmp dword [ebx] , 0
        je fin_loop_dup
        
        ; allocate memory for a new link
        mov dword ecx , 1
        mov dword ebx , 5
        push ecx
        push ebx
        call calloc
        
        pop ebx
        pop ebx
        pop ecx
        pop ebx
        
        ; calculate the value of the data in the new link
        ; And calculate the value of the 'next address pointer' of the previous link
        mov [ecx] , eax
        mov edx , 0
        mov ebx , [ebx]
        mov dl, [ebx]
        mov [eax] , dl
        
        ; Update the values of ebx and ecx and advance them to the next link
        ;mov ebx , [ebx]
        mov ecx , [ecx]
        inc ebx
        inc ecx
        push ebx
        push ecx
        jmp loop_dup
        
        ; Add terminating zero to the end of the new number
        ; Finish operation and check: if we are using this function from positive_power_op, go back to there
        ; Else, back to loop_input
        fin_loop_dup:
            mov byte [ecx] , 0
            cmp dword [pos_pow_activated] , 1
            je back_to_pos_pow
            ;;inc dword [total_operations_done]
            cmp dword [debug_activated] , 1
            je print_no_pop
            jmp loop_input
            back_to_pos_pow:
                jmp pos_pow_dup_fin
    
    duplicate_error:
        push err2
        push format_err2
        call printf
        jmp loop_input
        
    duplicate_error_2:
        push err
        push format_err
        call printf
        jmp loop_input
        
positive_power_op:
    inc dword [total_operations_done]
   n_positive_power_op:
    mov dword [pos_pow_activated] , 1

    cmp dword [head] , 2
    jb pos_power_err
    
    ; Calculate the top of the stack (X value)
    mov eax , [head]
    dec eax
    mov ebx , 4
    mul ebx
    add eax , stack
    
    ; Calculate the place of the Y value
    mov ebx , eax
    sub ebx , 4
    
    ; Check validity of Y value
    mov ecx , 0
    mov ecx , [ebx]
    
    cmp dword [ecx] , 200
    ja y_val_err
    
    inc ecx
    cmp dword [ecx] , 0
    jne y_val_err
    
    ; put the Y value in a global varaiable 'pos_pow_counter'
    dec ecx
    mov edx , 0
    mov dl , [ecx]
    mov [pos_pow_counter] , dl
    
    mov dword [add_to_delete_1] , ecx
    
    ; make the second top place in the stack point to X 
    ; and decrease the value of head by 1 so that the stack will contain only one value of X
    mov ecx , [eax]
    mov [ebx] , ecx
    
    sub dword [head] , 1
    
    ;Free Y memory
    free_memory [add_to_delete_1]
    
    ; The loop duplicates the value of X and sums the 2 values togheter to one value for 'pos_pow_counter' times.
    loop_pos_pow:
        ; If we finished all the duplicating , finish loop
        cmp dword [pos_pow_counter] , 0
        je fin_pos_pow
        
        ; Duplicate X and sum
        jmp n_duplicate_op
        pos_pow_dup_fin:
        jmp n_plus_op
        pos_pow_plus_fin:
         ;inc dword [total_operations_done]
        ; Decrease pos_pow_counter by 1 and back to loop
        mov edx , 0
        mov byte dl , [pos_pow_counter]
        dec dl
        mov byte [pos_pow_counter] , dl
        
        jmp loop_pos_pow
    
    fin_pos_pow:
       ;; inc dword [total_operations_done]
        cmp dword [debug_activated] , 1
        je print_no_pop
        jmp loop_input
    
    pos_power_err:
        push err
        push format_err
        call printf
        ;;inc dword [total_operations_done]
        cmp dword [debug_activated] , 1
        je print_no_pop
        jmp loop_input
    
    y_val_err:
        push err3
        push format_err
        call printf
        ;;inc dword [total_operations_done]
        cmp dword [debug_activated] , 1
        je print_no_pop
        jmp loop_input

negative_power_op:
    inc dword [total_operations_done]
  n_negative_power_op:
   ;; inc dword [total_operations_done]

    ; Check validity of the stack
    cmp dword [head] , 2
    jb neg_power_err
    
    ; Calculate the top of the stack (Place of X value)
    mov eax , [head]
    dec eax
    mov ebx , 4
    mul ebx
    add eax , stack
    
    ; Calculate the place of Y
    mov ebx , eax
    sub ebx , 4
    
    ; put in ecx the Y value
    mov ecx , 0
    mov ecx , [ebx]
    
    ; check validity of Y
    cmp dword [ecx] , 200
    ja neg_y_val_err
    
    inc ecx
    cmp dword [ecx] , 0
    jne y_val_err
    
    ; put the Y value in 'neg_pow_counter'
    dec ecx
    mov edx , 0
    mov dl , [ecx]
    mov [neg_pow_counter] , dl
    
    mov dword [add_to_delete_1] , ecx
    
    ; make the second top place in the stack point to X 
    ; and decrease the value of head by 1 so that the stack will contain only one value of X
    
    mov ecx , [eax]
    mov [ebx] , ecx
    
    sub dword [head] , 1
    
    pushad
    
    ;Free memory of Y linked list
    free_memory [add_to_delete_1]
    
    pop ecx
    popad
    
    ; Edge Case: if the power is 0, then X is the result, back to loop_input
    cmp dword [neg_pow_counter] , 0
    je end_neg_op
    
    ; Loop in loop
    ; The Inside Loop go over the linked list and divide the number by 2
    ; The outside Loop countes the number of times we dividing the number
    neg_op_all_divs:
        cmp dword [neg_pow_counter] , 0
        je end_neg_op
        
        ; Divide the first link of the linked list
        mov edx , 0
        mov dl , [ecx]
        shr dl , 1
        mov [ecx] , dl
        
        ; Save the prev varaiable to be the first link and the curr varaiable to the second link
        mov dword [prev] , ecx
        inc ecx
        mov ebx , [ecx]
        mov dword [curr] , ebx
        
        mov eax , [eax]
        
        ; Inside Loop staritng from the second link
        neg_op_loop:
            ; if we arrive to the end of the linked list
            cmp dword [curr] , 0
            je fin_one_div
            
            ; Divide Curr by 2
            mov edx , 0
            mov ecx , [curr]
            mov byte dl , [ecx]
            shr dl , 1
            mov [ecx] , dl
            
            jnc not_carry_neg_pow
            
            ; If we have carry , add 128 to prev link
            mov dword eax , [prev]
            add dword [eax] , 128
            
            ; Calculate the new prev and curr value and back to the loop
            not_carry_neg_pow:
                inc eax
                mov dword edi , [eax]
                mov eax , edi
                
                mov ebx , eax
                inc ebx
                mov ebx , [ebx]
                
                mov dword [prev] , eax
                mov dword [curr] , ebx
                
                jmp neg_op_loop
            
        ; prepare all values for the next iteration of the outside loop 
        fin_one_div:
            dec dword [neg_pow_counter]
            
            mov eax , [head]
            dec eax
            mov ebx , 4
            mul ebx
            add eax , stack
            
            mov ecx , [eax]
            
            jmp neg_op_all_divs
    
    neg_power_err:
        push err
        push format_err
        call printf
        cmp dword [debug_activated] , 1
        je print_no_pop
        jmp loop_input
    
    neg_y_val_err:
        push err3
        push format_err
        call printf
        cmp dword [debug_activated] , 1
        je print_no_pop
        jmp loop_input
        
    end_neg_op:
        cmp dword [debug_activated] , 1
        je print_no_pop
        jmp loop_input
        
count_binary_1s:
    inc dword [total_operations_done]
    n_count_binary_1s:
    ;inc dword [total_operations_done]

    ; Cheack validity of stack
    cmp dword [head] , 1
    jb binary_1s_Stack_Error

    ; Calculate the top of the stack
    mov eax , [head]
    dec eax
    mov ebx , 4
    mul ebx
    add eax , stack
    
    ; put in edx the first link
    mov edx , 0
    mov edx , [eax]
    
    mov ebx , 0
    
    ; The Inside loop count the 1s in each link
    ; The outside loop goes over all links
    loop_1s:
        inside_loop:
            ; if the value of [edx] is 0 we finished counting it
            cmp byte [edx] , 0
            je next_link_to_count
            
            ; shift right , and if carry flag is on, count it as 1
            mov ecx , 0
            mov cl , [edx]
            shr cl ,1
            jnc donot_count
            inc ebx
            donot_count:
            mov [edx] , cl
            jmp inside_loop
            
        next_link_to_count:
        ; If its the last link, continue
        ; else, prepare for the next iteration
        inc edx
        cmp dword [edx] , 0
        je stop_sum
        mov edx , [edx]
        jmp loop_1s
        
        stop_sum:
            ; calculate the hex value of the sum and insert it to buf
            ; treat the sum like input so go to check_input
            decimal_to_hexa ebx
            
            pop_op
            pop eax
            mov [add_to_delete_1] , eax
            free_memory [add_to_delete_1]
            
            jmp check_input
            
    binary_1s_Stack_Error:
        push err
        push format_err
        call printf
        cmp dword [debug_activated] , 1
        je print_no_pop
        jmp loop_input
        
    
check_input:
    rttui1:
    mov eax , 0
    mov ebx , 0
    mov ecx , 0
    mov edx , 0
    mov esi , 0
    mov edi , 0
    ;mov al , [buf]
    mov byte [next_char] , 0
    mov dword [buf_in] , 0
    mov dword [next_link_add] , 0
    mov byte [dec] , 0
    mov dword [finished_read] , 0
    mov dword [count_loop_times] , 0
    mov dword [pos_pow_counter] , 0
    mov dword [pos_pow_activated] , 0
    mov dword [sum_carry] , 0
    mov dword [odd_num] , 0
    mov dword [last_link] , 0
    mov dword [neg_pow_counter] , 0
    mov dword [count_hex_digits] , 0
    mov dword [add_to_delete_1] , 0
    mov dword [add_to_delete_2] , 0

    cmp byte [buf] , 113 ;if quit
    je End
    
    cmp byte [buf] , 112 ;if pop and print
    je pop_and_print
    
    cmp byte [buf] , 43 ;if plus
    je plus_op
    
    cmp byte [buf] , 100 ;if duplicate
    je duplicate_op
    
    cmp byte [buf] , 94 ;if positive power
    je positive_power_op
    
    cmp byte [buf] , 118 ;if negative power
    je negative_power_op
    
    cmp byte [buf] , 110 ;if count 1s in binary number
    je count_binary_1s
    
    mov ecx , buf
    mov eax , temp_buf2
    clean_padding_zeros:
        cmp byte [ecx] , 0
        je only_one_zero
        cmp byte [ecx] , 48
        je its_zero
        jmp finish_clean_zeros
        its_zero:
            inc ecx
            jmp clean_padding_zeros
        finish_clean_zeros:
            cmp byte [ecx] , 0
            je all_in_temp
            mov ebx , 0
            mov bl , [ecx]
            mov [eax] , bl
            inc ecx
            inc eax
            jmp finish_clean_zeros
        all_in_temp:
            mov eax , buf
            mov ebx , temp_buf2
            copy_digits:
                cmp byte [ebx] , 0
                je all_in_buf
                mov ecx , 0
                mov cl , [ebx]
                mov [eax] , cl
                mov byte [ebx] , 0
                inc eax
                inc ebx
                jmp copy_digits
        only_one_zero:
            mov eax , buf
            mov byte [eax] , 48
            inc eax
    all_in_buf:
    mov byte [eax] , 0
    mov eax , 0
    mov ebx , 0
    mov ecx , 0
    mov edx, buf
    loop_counter_digits:
        mov al ,[edx]
        cmp byte [edx], 0
        je end_of_loop
        cmp dword [odd_num],0
        je even_num
        mov dword [odd_num],0
        jmp continue_loop
        even_num:
            mov dword [odd_num],1
        continue_loop:
            inc edx
            jmp loop_counter_digits
        end_of_loop:
            cmp dword [odd_num],1
            je push_zero_to_buff
        retu_my_calc:
    jmp add_operand

push_zero_to_buff:
    mov edx, buf
    mov ecx, temp_buf
    mov byte [ecx],48
    inc ecx
    looper:
    cmp byte [edx], 0
    je end_of_looper
    mov eax , 0
    mov al ,[edx]
    mov [ecx], al
    inc ecx
    inc edx
    jmp looper
    end_of_looper:
    mov byte [edx] , 0
    mov edx, buf
    mov ecx, temp_buf
    retu_looper:
    cmp byte [ecx], 0
    je end_of_retu_looper
    rttui1010:
    mov eax , 0
    mov al ,[ecx]
    mov [edx], al
    mov byte [ecx] , 0
    inc ecx
    inc edx
    jmp retu_looper
    end_of_retu_looper:
    mov byte [edx] , 0
    jmp retu_my_calc
main:
    mov edx , [esp+4]
    cmp edx , 2
    jne start_program
    mov dword [debug_activated] , 1
    start_program:
    jmp myCalc

myCalc:
    loop_input:
        push inp
        push format_inp
        call printf
        mov dword [odd_num],0
        push buf
        call gets
        add esp , 4
        jmp check_input
        ;inc edx
        rttui2:
        after_gets:
        jmp loop_input
End:
    ; Delete what is left in stack
    loop_to_delete_all_stack:
        cmp dword [head] , 0
        je rest_of_end
        
        mov eax , [head]
        dec eax
        mov ebx , 4
        mul ebx
        add eax , stack
        
        free_memory [eax]
        dec dword [head]
        jmp loop_to_delete_all_stack
    
    ; Print total operations made and exit gracefully
    rest_of_end:
        push dword [total_operations_done]
        push format_enter
        call printf
        ;push 10
        ;push format_char_pop_and_print
        ;call printf
        mov eax , 1
        mov ebx , 0
        int 0x80
