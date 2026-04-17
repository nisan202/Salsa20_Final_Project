# -*- coding: utf-8 -*-
"""
Created on Sun Oct 12 10:07:21 2025

@author: Nisan Moshe Slomov

File Name: text2bytes
    
Description:
    
"""

import argparse
import sys
import os
import numpy as np
from colorama import Fore, init

sys.path.append(r"C:\Users\HP\Desktop\Degree\Nisan_final_project\scripts\python_scripts")
import salsa_20_scripts

init(autoreset=True)

#--------------------------------------------------------
#--------------------------------------------------------

def txtfile_2_hexlist(text):
    """
    BE
    string text from file -> convert to hex number list
    'Chapter' = ['0x43','0x68','0x61','0x70','0x74','0x65','0x72']
    """
    #f = txtfile_2_hexlist(r"C:\Users\HP\Desktop\Degree\Nisan_final_project\
    #           scripts\python_scripts\frist_chapter_harry_poter.txt")
    #need to put "r" befor the real path OR turn the \ to / !!!
    
    byte_data = text.encode('utf-8')
    hex_list = [f"0x{b:02X}" for b in byte_data]
    
    return hex_list


#--------------------------------------------------------
#--------------------------------------------------------

def hex_list_to_dw(hex_list):
    """
    BE
    input = ['0x43','0x68','0x61','0x70','0x74','0x65','0x72']
    output = ['0x43686170','0x74657200']
    """
    merged_hex_strings = []
    n = len(hex_list)
    
    for i in range(0, n, 4):
        chunk = hex_list[i:i+4]
        merged_hex_suffix = "".join(val[2:] for val in chunk)
        
        if not merged_hex_suffix:
            continue
            
        merged_string = merged_hex_suffix.lower()
        
        if i + 4 >= n:
            target_length = 8
            current_length = len(merged_string)
            
            if current_length < target_length:
                padding_zeros = target_length - current_length
                merged_string = merged_string + '0' * padding_zeros
        
        merged_hex_strings.append('0x' + merged_string)
            
    return merged_hex_strings

#--------------------------------------------------------
#--------------------------------------------------------

def reverse_hex_list(hex_list):
    """
    Reverse the order of a list of hex strings.
    input = ['0x43686170','0x74657200']
    output = ['0x74657200','0x43686170']
    """
    swap_list =  hex_list[::-1]
    
    return swap_list

#--------------------------------------------------------
#--------------------------------------------------------

def byte_swap(hex_list_swap):
    """
    input = ['0x74657200','0x43686170']
    output = ['0x00726574','0x70616843']
    """
    reversed_list = []
    
    for hex_val in hex_list_swap:
        suffix = hex_val[2:]
        
        if len(suffix) % 2 != 0:
            print(f"{hex_val} not in the right length")
            reversed_list.append(hex_val)
            continue

        bytes_list = [suffix[i:i+2] for i in range(0, len(suffix), 2)]
        bytes_list.reverse()
        reversed_suffix = "".join(bytes_list)

        reversed_list.append('0x' + reversed_suffix)
        
    return reversed_list

#--------------------------------------------------------
#--------------------------------------------------------

def chunk_list(lst: list, n: int):
    """
    input: list of N hex dw
    output: sub lists - max 16 in each one 
    padding zeros in the klast one if necessary 
    """
    chunks = [lst[i:i + n] for i in range(0, len(lst), n)]
    
    len_last_one = len(chunks[-1])
    
    if len_last_one < n:
        padding = ['0x00000000'] * (n - len_last_one)
        chunks[-1] = chunks[-1] + padding
    
    return chunks

#--------------------------------------------------------    
#--------------------------------------------------------

def manual_counter_dec2hex(dec_num):
    """
    manual_counter_dec2hex(64) = ['00000000', '00000040']
    """
    msb = (dec_num >> 32) & 0xFFFFFFFF
    lsb = dec_num & 0xFFFFFFFF
    return [f"{msb:08x}", f"{lsb:08x}"]

#--------------------------------------------------------    
#--------------------------------------------------------

def generate_test_vectors_from_file(input_filepath, output_filepath):    
    """
    
    """
    # ==== Open file and read text ====
    if not os.path.exists(input_filepath):
        print("File not found! Check the path.\n")
    else:
        with open(input_filepath, "r", encoding="utf-8") as f:
            text = f.read()
        print("File read successfully!\n")
    
    # ==== Convert text to hex list ====
    """
    BE,string text from file -> convert to hex number list 
    """
    hex_txt_lst = txtfile_2_hexlist(text)
    
    # ==== Concatenation 4 hex byte to 1 dw hex list ====
    """
    BE,
    input = ['0x43','0x68','0x61','0x70','0x74','0x65','0x72']
    output = ['0x43686170','0x74657200']
    """
    hex_dw_lst = hex_list_to_dw(hex_txt_lst)
    
    # ==== Dividing the dw list into chunks of 16 ====
    """
    BE,
    input = ['0x43686170', ......., 0x74657200']
    output = [['0x43686170'.....],[....],[.....'0x74657200']]
    """
    hex_dw_lst_chunk = chunk_list(hex_dw_lst,16)
     
    # ==== Number of tests - beginnig from 0 ====
    # going to for in range so, dont need to do "-1"
    number_of_chunk = len(hex_dw_lst_chunk)
    
    
    # =============================================
    # =============================================
    # =============================================
    
    vector = [] # List of dictionaries
    
    """=============================================
    nonce and key are constants for a given message,
    (msg <= (2^64 -1)blocks)
    ================================================"""
    # Nonce:
    nonce_lst_hex = salsa_20_scripts.random_nonce(1)  # 1: doing random
    nonce_bin     = salsa_20_scripts.random2Binary_bas(nonce_lst_hex)
    nonce_hex_bas = ''.join(nonce_lst_hex)
    
    # Key:
    key_lst_hex   = salsa_20_scripts.random_key(1)    # 1: random 0f 256 bits key
    key_bin       = salsa_20_scripts.random2Binary_bas(key_lst_hex)
    key_hex_bas     = ''.join(key_lst_hex)
    
    # constant in decimal
    constant     = salsa_20_scripts.four_constant_words(1)
    cons_lst_hex = np.vectorize(hex)(constant)
    cons_bin     = salsa_20_scripts.constant2Binary_bas(constant)
    cons_hex_bas =  ''.join(x[2:] for x in cons_lst_hex)
    
    
    
    for i in range(number_of_chunk):
        
        # Counter
        counter_lst_hex = manual_counter_dec2hex(i)
        counter_bin = salsa_20_scripts.random2Binary_bas(counter_lst_hex)
        counter_bas_hex = ''.join(counter_lst_hex)
        
        # Initial Data
        initial_mtx = salsa_20_scripts.initial_matrix(key_lst_hex,nonce_lst_hex,counter_lst_hex,constant)
        initial_mtx_hex = salsa_20_scripts.dec2hex_matrix(initial_mtx)
        initial_bin = salsa_20_scripts.matrix2Binary_bas(initial_mtx)
        initial_bas_hex = ''.join([item for sublist in initial_mtx_hex for item in sublist])
        
        # Hashing Data
        hashing_dec_mtx = salsa_20_scripts.salsa_hash(initial_mtx,0)
        hashing_mtx_hex = salsa_20_scripts.dec2hex_matrix(hashing_dec_mtx)
        hashing_bin = salsa_20_scripts.matrix2Binary_bas(hashing_dec_mtx)
        hashing_bas_hex = ''.join([item for sublist in hashing_mtx_hex for item in sublist])
        
        # Plain
        plain_hex_lst_chunk_i  = hex_dw_lst_chunk[i]
        plain_dec_list_chunk_i = [int(x, 16) for x in plain_hex_lst_chunk_i]
        plain_dec_mtx          = np.array(plain_dec_list_chunk_i,dtype=np.uint32).reshape(4, 4)
        plain_mtx_hex          = salsa_20_scripts.dec2hex_matrix(plain_dec_mtx)
        plain_bin              = salsa_20_scripts.matrix2Binary_bas(plain_dec_mtx) 
        plain_hex_bas          = ''.join([item for sublist in plain_mtx_hex for item in sublist])
        
        # Cipher
        cipher_dec_mtx = salsa_20_scripts.cipher_text(hashing_dec_mtx,plain_dec_mtx)
        cipher_mtx_hex = salsa_20_scripts.dec2hex_matrix(cipher_dec_mtx)
        cipher_bin     = salsa_20_scripts.matrix2Binary_bas(cipher_dec_mtx)
        cipher_hex_bas = ''.join([item for sublist in cipher_mtx_hex for item in sublist])
        
        # Decryption
        decryp_dec_mtx = salsa_20_scripts.cipher_text(hashing_dec_mtx,cipher_dec_mtx)
        decryp_hex_mtx = salsa_20_scripts.dec2hex_matrix(decryp_dec_mtx)
        decryp_bin     = salsa_20_scripts.matrix2Binary_bas(decryp_dec_mtx)
        decryp_bas_hex = ''.join([item for sublist in decryp_hex_mtx for item in sublist])
    
    
        # Mesg - check if succeeded
        if np.array_equal(decryp_dec_mtx,plain_dec_mtx):
            mesg = "Encryption and decryption succeeded"
        else:
            mesg = "Encryption and decryption faild"
        
        # list of dictionaries
        # the contant for txt vectors file 
        
        vector.append({
            'test_number'           :i,
            'key_hex_list'          :key_lst_hex,
            'key_bin'               :key_bin,
            'key_hex_bas'           :key_hex_bas,
            'nonce_hex_list'        :nonce_lst_hex,
            'nonce_bin'             :nonce_bin,
            'nonce_hex_bas'         :nonce_hex_bas,
            'counter_hex_list'      :counter_lst_hex,
            'counter_bin'           :counter_bin,
            'counter_hex_bas'       :counter_bas_hex,
            'constant_hex_list'     :cons_lst_hex,
            'constant_bin'          :cons_bin,
            'constant_hex_bas'      :cons_hex_bas,
            'initial_matrix_hex'    :initial_mtx_hex,
            'initial_bas_bin'       :initial_bin,
            'initial_hex_bas'       :initial_bas_hex,
            'hashing_matrix_hex'    :hashing_mtx_hex,
            'hashing_bas_bin'       :hashing_bin,
            'hashing_hex_bas'       :hashing_bas_hex,
            'plain_matrix_hex'      :plain_mtx_hex,
            'plain_bas_bin'         :plain_bin,
            'plain_hex_bas'         :plain_hex_bas,
            'cipher_matrix_hex'     :cipher_mtx_hex,
            'cipher_bas_bin'        :cipher_bin,
            'cipher_hex_bas'        :cipher_hex_bas,
            'decryption_hex'        :decryp_hex_mtx,
            'decryption_bin'        :decryp_bin,
            'decryption_hex_bas'    :decryp_bas_hex,
            'message'               :mesg
        })
        
        
    sp_tab = "    " * 3
    tab = "    " * 2
    
      
    # ==== Open file and write text ====
    print ("open output file to write:")
    
    with open(output_filepath, "w", encoding="utf-8") as file:
        print("File open successfully!\n")
        
        for item in vector:
            file.write(f"Test Number {item['test_number']}:\n")
            
            # Key prints:
            file.write(f"{tab}Key Vectors:\n")
            file.write(f"{sp_tab}Key_Hex_List = {item['key_hex_list']}\n")
            file.write(f"{sp_tab}Key_Hex_Bas = {item['key_hex_bas']}\n")
            file.write(f"{sp_tab}Key_Bin = \n")
            salsa_20_scripts.writelongbas(file,item['key_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            # Nonce prints:
            file.write(f"{tab}Nonce Vectors:\n")
            file.write(f"{sp_tab}Nonce_Hex_List = {item['nonce_hex_list']}\n")
            file.write(f"{sp_tab}Nonce_Hex_Bas = {item['nonce_hex_bas']}\n")
            file.write(f"{sp_tab}Nonce_Bin = \n")
            salsa_20_scripts.writelongbas(file,item['nonce_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            # Counter prints:
            file.write(f"{tab}Counter Vectors:\n")
            file.write(f"{sp_tab}Counter_Hex_List = {item['counter_hex_list']}\n")
            file.write(f"{sp_tab}Counter_Hex_Bas = {item['counter_hex_bas']}\n")
            file.write(f"{sp_tab}Counter_Bin = \n")
            salsa_20_scripts.writelongbas(file,item['counter_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            # Constant prints:
            file.write(f"{tab}Constant Vectors:\n")
            file.write(f"{sp_tab}Constants_Hex_List = {item['constant_hex_list']}\n")
            file.write(f"{sp_tab}Constants_Hex_Bas = {item['constant_hex_bas']}\n")
            file.write(f"{sp_tab}Constants_Bin = \n")
            salsa_20_scripts.writelongbas(file,item['constant_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            
            # Initial prints:
            file.write(f"{tab}Initial Matrixs:\n")
            file.write(f"{sp_tab}Initial_Matrix_Hex = \n")
            mtx = ''.join([f"{sp_tab}{row}\n{sp_tab}" for row in item['initial_matrix_hex']])
            file.write(f"{sp_tab}{mtx}")
            file.write(f"Initial_Hex_Bas = {item['initial_hex_bas']}\n")
            file.write(f"{sp_tab}Initial_Bas_Bin = \n")
            salsa_20_scripts.writelongbas(file,item['initial_bas_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            
            # Hashing prints:
            file.write(f"{tab}Hashing Matrixs:\n")
            file.write(f"{sp_tab}Hashing_Matrix_Hex = \n")
            mtx = ''.join([f"{sp_tab}{row}\n{sp_tab}" for row in item['hashing_matrix_hex']])
            file.write(f"{sp_tab}{mtx}")
            file.write(f"Hashing_Hex_Bas = {item['hashing_hex_bas']}\n")
            file.write(f"{sp_tab}Hashing_Bas_Bin = \n")
            salsa_20_scripts.writelongbas(file,item['hashing_bas_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            
            # Plain prints:
            file.write(f"{tab}Plain Text Matrixs:\n")
            file.write(f"{sp_tab}Plain_Matrix_Hex = \n")
            mtx = ''.join([f"{sp_tab}{row}\n{sp_tab}" for row in item['plain_matrix_hex']])
            file.write(f"{sp_tab}{mtx}")
            file.write(f"Plain_Hex_Bas = {item['plain_hex_bas']}\n")
            file.write(f"{sp_tab}Plain_Text_Bas_Bin = \n")
            salsa_20_scripts.writelongbas(file,item['plain_bas_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            
            # Cipher prints:
            file.write(f"{tab}Cipher Text Matrixs:\n")
            file.write(f"{sp_tab}Cipher_Matrix_Hex = \n")
            mtx = ''.join([f"{sp_tab}{row}\n{sp_tab}" for row in item['cipher_matrix_hex']])
            file.write(f"{sp_tab}{mtx}")
            file.write(f"Cipher_Hex_Bas = {item['cipher_hex_bas']}\n")
            file.write(f"{sp_tab}Cipher_Text_Bas_Bin = \n")
            salsa_20_scripts.writelongbas(file,item['cipher_bas_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            
            # Decryption prints:
            file.write(f"{tab}Decryption Text Matrixs:\n")
            file.write(f"{sp_tab}Decryption_Matrix_Hex = \n")
            mtx = ''.join([f"{sp_tab}{row}\n{sp_tab}" for row in item['decryption_hex']])
            file.write(f"{sp_tab}{mtx}")
            file.write(f"Decryption_Hex_Bas = {item['decryption_hex_bas']}\n")
            file.write(f"{sp_tab}Decryption_Text_Bas_Bin = \n")
            salsa_20_scripts.writelongbas(file,item['decryption_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            # Message print
            file.write(f"vectors ready: {item['message']}:\n" )
            
            # General
            file.write("-" * 200 + "\n\n")
            

###############################################################################
# ================================ main =======================================
   
in_file = (r"C:\Users\HP\Desktop\Degree\Nisan_final_project\scripts\python_scripts\‏‏harry_potter_text2.txt")

out_file = ("C:/Users/HP/Desktop/Degree/Nisan_final_project/scripts/"
            "python_scripts/output_txt/vectors_from_text_file.txt")

generate_test_vectors_from_file(in_file,out_file)






