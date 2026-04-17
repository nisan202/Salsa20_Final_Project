# -*- coding: utf-8 -*-
"""
Created on Fri Dec  6 09:58:45 2024

author: Nisan Moshe Shlomov
Project: Final project

Salsa20 encryption & decryption 
In addition, we will generate random test vectors 
and initial and simple test vectors.

"""
"""
(i,j) = (row, colum)

      
                  j=0   j=1   j=2   j=3
matrix =   i=0  [(0,0) (0,1) (0,2) (0,3)
           i=1   (1,0) (1,1) (1,2) (1,3)
           i=2   (2,0) (2,1) (2,2) (2,3)
           i=3   (3,0) (3,1) (3,2) (3,3)]

"""

import numpy as np 
import random
import string
#import pandas as pd

#------------- --------------------------------------------------------------
def quarter_round(dw0,dw1,dw2,dw3,R1=7,R2=9,R3=13,R4=18):
    """
    Performing the quarter round function of the salsa encryption algorithm.
    recives 4 dw input (dw0-dw3), each 32 bit wide. 
    and, 4 parameters(R1-R4) for producing the rotate.
    The output of the function consists of 4 dw z0-z3 width each z 32 bits.
    """
    dw0 = np.uint32(dw0)
    dw1 = np.uint32(dw1)
    dw2 = np.uint32(dw2)
    dw3 = np.uint32(dw3)
    
    # function process
    # step 1
    add1 = ((dw0 + dw3) & 0xFFFFFFFF) # Avoid bandwidth errors
        # the rotated step
    rotated1 = ((add1 << R1) | (add1 >> (32 - R1))) & 0xFFFFFFFF 
    t1 = dw1 ^ rotated1
    
    # step 2
    add2 = ((t1 + dw0) & 0xFFFFFFFF) # Avoid bandwidth errors
        # the rotated step
    rotated2 = ((add2 << R2) | (add2 >> (32 - R2))) & 0xFFFFFFFF 
    t2 = dw2 ^ rotated2
    
    # step 3
    add3 = ((t2 + t1) & 0xFFFFFFFF) # Avoid bandwidth errors
        # the rotated step
    rotated3 = ((add3 << R3) | (add3 >> (32 - R3))) & 0xFFFFFFFF 
    t3 = dw3 ^ rotated3
    
    # step 4
    add4 = ((t3 + t2) & 0xFFFFFFFF) # Avoid bandwidth errors
        # the rotated step
    rotated4 = ((add4 << R4) | (add4 >> (32 - R4))) & 0xFFFFFFFF 
    t4 = dw0 ^ rotated4
    
    # outputs:
    z0,z1,z2,z3 = t4,t1,t2,t3
    
    return z0,z1,z2,z3

#---------------------------------------------------------------------------

def row_round(row_matrix_in):
    """
    Parameters
    ----------
    row_matrix_in : numpy 
        the 4x4 matrix input
        the function play qurter_round def on the row matrix 
    Returns
    -------
    row_matrix_out - the matrix after one round of qurter_round 
    """
    row_matrix_out = np.zeros((4,4), dtype=np.uint32)
    
    r0 = row_matrix_in[0,0] 
    r1 = row_matrix_in[0,1]
    r2 = row_matrix_in[0,2] 
    r3 = row_matrix_in[0,3] 
    r4 = row_matrix_in[1,0] 
    r5 = row_matrix_in[1,1] 
    r6 = row_matrix_in[1,2] 
    r7 = row_matrix_in[1,3] 
    r8 = row_matrix_in[2,0]
    r9 = row_matrix_in[2,1]
    r10 = row_matrix_in[2,2] 
    r11 = row_matrix_in[2,3] 
    r12 = row_matrix_in[3,0] 
    r13 = row_matrix_in[3,1] 
    r14 = row_matrix_in[3,2] 
    r15 = row_matrix_in[3,3] 
    
    z0,z1,z2,z3 = quarter_round(r0,r1,r2,r3)
    z5,z6,z7,z4 = quarter_round(r5,r6,r7,r4)
    z10,z11,z8,z9 = quarter_round(r10,r11,r8,r9)
    z15,z12,z13,z14 = quarter_round(r15,r12,r13,r14)
    
    
    row_matrix_out[0,0] = z0
    row_matrix_out[0,1] = z1
    row_matrix_out[0,2] = z2
    row_matrix_out[0,3] = z3
    row_matrix_out[1,0] = z4
    row_matrix_out[1,1] = z5
    row_matrix_out[1,2] = z6
    row_matrix_out[1,3] = z7
    row_matrix_out[2,0] = z8
    row_matrix_out[2,1] = z9
    row_matrix_out[2,2] = z10
    row_matrix_out[2,3] = z11
    row_matrix_out[3,0] = z12
    row_matrix_out[3,1] = z13
    row_matrix_out[3,2] = z14
    row_matrix_out[3,3] = z15
   
    return row_matrix_out

#---------------------------------------------------------------------------

def colum_round(colum_matrix_in):
    """
    Parameters
    ----------
    colum_matrix_in : numpy 
        the 4x4 matrix input
        the function play qurter_round def on the colum matrix 
    Returns
    -------
    row_matrix_out - the matrix after one round of qurter_round 
    """
    
    colum_matrix_out = np.zeros((4,4), dtype=np.uint32)
    
    c0 = colum_matrix_in[0,0] 
    c1 = colum_matrix_in[0,1]
    c2 = colum_matrix_in[0,2] 
    c3 = colum_matrix_in[0,3] 
    c4 = colum_matrix_in[1,0] 
    c5 = colum_matrix_in[1,1] 
    c6 = colum_matrix_in[1,2] 
    c7 = colum_matrix_in[1,3] 
    c8 = colum_matrix_in[2,0]
    c9 = colum_matrix_in[2,1]
    c10 = colum_matrix_in[2,2] 
    c11 = colum_matrix_in[2,3] 
    c12 = colum_matrix_in[3,0] 
    c13 = colum_matrix_in[3,1] 
    c14 = colum_matrix_in[3,2] 
    c15 = colum_matrix_in[3,3] 
    
    y0,y4,y8,y12 = quarter_round(c0,c4,c8,c12)
    y5,y9,y13,y1 = quarter_round(c5,c9,c13,c1)
    y10,y14,y2,y6 = quarter_round(c10,c14,c2,c6)
    y15,y3,y7,y11 = quarter_round(c15,c3,c7,c11)
    
    
    colum_matrix_out[0,0] = y0
    colum_matrix_out[0,1] = y1
    colum_matrix_out[0,2] = y2
    colum_matrix_out[0,3] = y3
    colum_matrix_out[1,0] = y4
    colum_matrix_out[1,1] = y5
    colum_matrix_out[1,2] = y6
    colum_matrix_out[1,3] = y7
    colum_matrix_out[2,0] = y8
    colum_matrix_out[2,1] = y9
    colum_matrix_out[2,2] = y10
    colum_matrix_out[2,3] = y11
    colum_matrix_out[3,0] = y12
    colum_matrix_out[3,1] = y13
    colum_matrix_out[3,2] = y14
    colum_matrix_out[3,3] = y15
    
    
    return colum_matrix_out

#---------------------------------------------------------------------------    

def double_round(double_matrix_in):
    """
    Parameters
    ----------
    double_matrix_in : numpy 
        the 4x4 matrix input
        the function play row_round & colum round on the double matrix
    Returns
    -------
    the matrix after one round
    double_matrix_out = row_round(colum_round(double_matrix_in)).
    """
    
    mtx2colum = double_matrix_in.copy()
    
    mtx_from_colum = colum_round(mtx2colum)
    
    double_matrix_out = row_round(mtx_from_colum)
    
    return double_matrix_out

#---------------------------------------------------------------------------

def salsa_hash(salsa_hash_matrix_in,sel=0):
    """
    Parameters
    ----------
    salsa_matrix_in :numpy 
        the 4x4 matrix input
        the function do the hash step.
    select : int
            select how match double_round we want to do
            select = 0 : r = 10
                   = 1 : r = 6
                   = 2 : r = 4
                   = else : r = 10
    Returns
    -------
    salsa_hash_matrix_out = salsa_hash_matrix_in + double_round{r}(salsa_hash_matrix_in)
    """
    
    # coding the select
    if sel == 0:
        r = 10
    elif sel == 1:
        r = 6
    elif sel == 2:
        r = 4
    else:
        r = 10
    
    # hash 
    matrix_for_loop = salsa_hash_matrix_in.copy()
    
    for i in range(r):
        matrix_for_loop = double_round(matrix_for_loop)
    
    # the final hashing
    salsa_hash_matrix_out = salsa_hash_matrix_in + matrix_for_loop
    
    return salsa_hash_matrix_out


#---------------------------------------------------------------------------
def generate_random_hex_string(length):
    """
    Creates a random string of given length 
    containing hexadecimal characters.
    Length: The length of the desired string.(if l=8 --> 8*4 = 32)    
    """
    # Defines the possible characters
    hex_digits = string.hexdigits[:16] # only 0-9_a-f 
    
    result = ''.join(random.choice(hex_digits) for _ in range(length))
    
    return result

#---------------------------------------------------------------------------
def random_key(sel=0): 
    """
    if sel = 1 --> do random 256
    """
    key_in = 8*[0]
    if (sel == 1): # 256 bits key
        for i in range(8):
            key_in[i] = generate_random_hex_string(8)
    elif (sel == 2): # 128 bits key
        for i in range(4):
            key_in[i] = generate_random_hex_string(8)
        key_in[4:] = key_in[:4]
    elif (sel == 0): # zeros
        for i in range(8):
            key_in[i] = "0" * 8
            
    return key_in       # k0 = msb , k7 = lsb

#---------------------------------------------------------------------------
def random_nonce(sel=0):
    """
    if sel=1: do random 
    """
    nonce = 2 * [0]
    if (sel == 1):
        for i in range(2):
            nonce[i] = generate_random_hex_string(8)
    else: # sel == 0
        for i in range(2):
            nonce[i] = "0" * 8
            
    return nonce
#---------------------------------------------------------------------------
def random_counter(sel=0):
    """
    if sel=1: do random 
    """
    count = 2 * [0]
    if (sel == 1):
        for i in range(2):
            count[i] = generate_random_hex_string(8)
    else: # sel == 0
        for i in range(2):
            count[i] = "0" * 8
            
    return count
#---------------------------------------------------------------------------

def four_constant_words(sel=1):
    """
    Parameters
    ----------
    select : int
        select between 16 Bytes and 32 Bytes.
        select = 0 : 16 Bytes --> constant = "expand 16-byte k"
        select = 1 : 32 Bytes --> constant = "expand 32-byte k"
        else : 32 bytes.

    Returns
    -------
    four constants word in one bus.
    """
    
    if (sel == 0): # "expand 16-byte k"
        const0 = int('61707865',16)
        const1 = int('3120646E',16)
        const2 = int('79622D36',16)
        const3 = int('6B206574',16)
    else:   # sel == 1 -->  "expand 32-byte k"
        const0 = int('61707865',16)
        const1 = int('3320646E',16)
        const2 = int('79622D32',16)
        const3 = int('6B206574',16)

    constants =  [const3,const2,const1,const0]
        
    return constants

#---------------------------------------------------------------------------

def initial_matrix(key,nonce,count,constant):
    """
    Parameters
    ----------
    key_words : 8 key words - 256 bits.
    nonce_words : 2 nonce words - 64 bits.
    count_words : 2 count words - 64 bits.
    constant_words : 4 constan words - 128 bits,
    create the matrix we need to send for hashing.
  
     [r,c]     c = 0        c = 1      c = 2       c = 3
     r = 0    [constant0    k0          k1          k2
     r = 1     k3         constant1     non0        non1
     r = 2     count0      count1     constant2     k4
     r = 3     k5           k6          k7         constant3]   
     
    Returns
    -------
    salsa_matrix_for_hash
    
    Note:
        In python list[0] points to the first from the left,
        while in hardware, in Verilog, it points to the first from the right.
    """
    
    # split key to k0 - k7
    k0 = int(key[7],16)     # msb
    k1 = int(key[6],16)
    k2 = int(key[5],16)
    k3 = int(key[4],16)
    k4 = int(key[3],16)
    k5 = int(key[2],16)
    k6 = int(key[1],16)
    k7 = int(key[0],16)     # lsb
        
    # split nonce_words to nonce0-nonce1:
    non0 = int(nonce[1],16)  # msb
    non1 = int(nonce[0],16)  # lsb
        
    # split count_words to count0-count1:
    count0 = int(count[1],16)  # msb
    count1 = int(count[0],16)  # lsb
    
    # split constant_words to constant0-constant3:
    constant0 = constant[3]   # msb
    constant1 = constant[2]
    constant2 = constant[1]
    constant3 = constant[0]   # lsb
        
    # Organization of the input matrix of the algorithm
    matrix = np.zeros((4, 4), dtype=np.uint32)
    
    matrix[0,0] = constant0
    matrix[0,1] = k0
    matrix[0,2] = k1
    matrix[0,3] = k2
    matrix[1,0] = k3
    matrix[1,1] = constant1
    matrix[1,2] = non0
    matrix[1,3] = non1
    matrix[2,0] = count0
    matrix[2,1] = count1
    matrix[2,2] = constant2
    matrix[2,3] = k4
    matrix[3,0] = k5
    matrix[3,1] = k6
    matrix[3,2] = k7
    matrix[3,3] = constant3

    
    salsa_matrix_for_hash = matrix.copy()
    
    return salsa_matrix_for_hash

#---------------------------------------------------------------------------
def random_plain(sel=0,size=4):
    """
    if sel=1: do random 
    """
    if (sel == 1):
        plain = np.random.randint(0, 2**32, size=(size, size), dtype=np.uint32)
    else: # sel == 0
        plain = np.zeros((size, size), dtype=np.uint32)
            
    return plain

#---------------------------------------------------------------------------
def cipher_text(hash_mtrx, plain_mtx):
    """
    bitwise xor
    """
    cipher = np.bitwise_xor(hash_mtrx, plain_mtx)
    
    return cipher

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------


###########################################################
def try0(num):
    vector = [
        {'test_number': i, 'nonce':random_nonce(1)}
        for i in range(num)
        ]
    for item in vector:
        print(f"Test number {item['test_number']}: ")
        print()
        print(f"Nonce =  {item['nonce']}")
        print("-" * 30)
        print()


# try0(3)

############################################################
def matrix2Binary_bas(matrix):
    """
    input:   4x4 matrix with DECIMAL values (plain/cipher/hash)
    output:  BINARY bus. 
    """
    mtx = matrix.flatten() # from 4x4 to 16x1
    
    hex_vals = [hex(x)[2:].zfill(8) for x in mtx]  # list of 16 str HEX value
    
    long_hex = ''.join(hex_vals) # bas of all hex value
    
    # binary bus with "0'b" in te begin of the bas. 
    # zfill(512) insure that the bas will be 512 bits.
    binary_padded = '0b' + bin(int(long_hex, 16))[2:].zfill(512)  
    
    return binary_padded

############################################################
def dec2hex_matrix(matrix):
    """
    input:  4x4 matrix with DECIMAL values (plain/cipher/hash)
    output: 4x4 matrix with HEX values. 
    """
    hex_matrix = np.vectorize(lambda x: f'{x:08x}')(matrix)
    
    return hex_matrix
    
############################################################
def constant2Binary_bas(constant):
    """
    input:  list with 4 DECIMAL values
    output: BINARY bus
    """
    hex_cons = np.vectorize(hex)(constant) # array with 4 HEX values
    
    long_cons = ''.join(x[2:] for x in hex_cons)   # bas of all hex value
    
    binary_cons = '0b' + bin(int(long_cons, 16))[2:].zfill(128)
    
    return binary_cons

############################################################
def random2Binary_bas(lis):
    """
    input:  list with "len(lis)" STR HEX values (key/nonce/counter)
    output: BINARY bus
    """
    l = len(lis)
    
    long_bus = ''.join(lis) # bas of all hex value
    
    binary_lis = '0b' + bin(int(long_bus, 16))[2:].zfill(l*32)
    
    return binary_lis

############################################################
def writelongbas(file,text,sp_tab,max_len = 80):
    """
    """
    #sp_tab2 = 2*sp_tab
    sp_tab2 = sp_tab + 4*" "
    for i in range(0, len(text), max_len):
        line = text[i:i+max_len]
        file.write(f"{sp_tab2}{line}\n")
    
############################################################
def generate_random_test_vectors(num,sel=1):
    """
    num = number of test vectors.
    sel = 1 default value --> random.
    sel = 0 - zeros.
    in constant def its depend 16 or 32 bits.
    so for now it will be always 32 bits - 
    so in constant sel = 1 also if we want zeros.
    salsa_hash(initial_mtx,0) - sel = 0 --> r = 10
    
    
    """
    
    with open(
            "C:/Users/HP/Desktop/Degree/Nisan_final_project/scripts/"
            "python_scripts/output_txt/salsa_test_vectors.txt", "w"
    ) as file:
        
        
        vector = [] # List of dictionaries
        
        for i in range(num):
            k_list_hex = random_key(sel)
            k_bin = random2Binary_bas(k_list_hex)
            k_bas_hex = ''.join(k_list_hex)
            
            
            n_list_hex = random_nonce(sel)
            n_bin = random2Binary_bas(n_list_hex)
            n_bas_hex = ''.join(n_list_hex)
               
                 
            count_list_hex = random_counter(sel)
            count_bin = random2Binary_bas(count_list_hex)
            count_bas_hex = ''.join(count_list_hex)
            
            
            cons_dec = four_constant_words(1)
            cons_list_hex = np.vectorize(hex)(cons_dec)
            cons_bin = constant2Binary_bas(cons_dec)
            #cons_bas_hex = ''.join(cons_list_hex)
            cons_bas_hex =  ''.join(x[2:] for x in cons_list_hex)
            
            initial_mtx = initial_matrix(k_list_hex,n_list_hex,count_list_hex,cons_dec)
            initial_mtx_hex = dec2hex_matrix(initial_mtx)
            initial_bin = matrix2Binary_bas(initial_mtx)
            initial_bas_hex = ''.join([item for sublist in initial_mtx_hex for item in sublist])
            
            
            hashing_mtx = salsa_hash(initial_mtx,0)
            hashing_mtx_hex = dec2hex_matrix(hashing_mtx)
            hashing_bin = matrix2Binary_bas(hashing_mtx)
            hashing_bas_hex = ''.join([item for sublist in hashing_mtx_hex for item in sublist])
            
            
            p_mtx = random_plain(sel,size=4)
            p_mtx_hex = dec2hex_matrix(p_mtx)
            p_bin = matrix2Binary_bas(p_mtx)
            p_bas_hex = ''.join([item for sublist in p_mtx_hex for item in sublist])
            
            
            c_mtx = cipher_text(hashing_mtx,p_mtx)
            c_mtx_hex = dec2hex_matrix(c_mtx)
            c_bin = matrix2Binary_bas(c_mtx)
            c_bas_hex = ''.join([item for sublist in c_mtx_hex for item in sublist])
            
            
            decryp = cipher_text(hashing_mtx,c_mtx)
            decryp_hex = dec2hex_matrix(decryp)
            decryp_bin = matrix2Binary_bas(decryp)
            decryp_bas_hex = ''.join([item for sublist in decryp_hex for item in sublist])
            
            
            if np.array_equal(decryp,p_mtx):
                mesg = "Encryption and decryption succeeded"
            else:
                mesg = "Encryption and decryption faild"
            
            vector.append({
                'test_number'           :i,
                'key_hex_list'          :k_list_hex,
                'key_bin'               :k_bin,
                'key_hex_bas'           :k_bas_hex,
                'nonce_hex_list'        :n_list_hex,
                'nonce_bin'             :n_bin,
                'nonce_hex_bas'         :n_bas_hex,
                'counter_hex_list'      :count_list_hex,
                'counter_bin'           :count_bin,
                'counter_hex_bas'       :count_bas_hex,
                'constant_hex_list'     :cons_list_hex,
                'constant_bin'          :cons_bin,
                'constant_hex_bas'      :cons_bas_hex,
                'initial_matrix_hex'    :initial_mtx_hex,
                'initial_bas_bin'       :initial_bin,
                'initial_hex_bas'       :initial_bas_hex,
                'hashing_matrix_hex'    :hashing_mtx_hex,
                'hashing_bas_bin'       :hashing_bin,
                'hashing_hex_bas'       :hashing_bas_hex,
                'plain_matrix_hex'      :p_mtx_hex,
                'plain_bas_bin'         :p_bin,
                'plain_hex_bas'         :p_bas_hex,
                'cipher_matrix_hex'     :c_mtx_hex,
                'cipher_bas_bin'        :c_bin,
                'cipher_hex_bas'        :c_bas_hex,
                'decryption_hex'        :decryp_hex,
                'decryption_bin'        :decryp_bin,
                'decryption_hex_bas'    :decryp_bas_hex,
                'message'               :mesg
            })
            
            
        sp_tab = "    " * 3
        tab = "    " * 2
        
        for item in vector:
            file.write(f"Test Number {item['test_number']}:\n")
            
            file.write(f"{tab}Key Vectors:\n")
            file.write(f"{sp_tab}Key_Hex_List = {item['key_hex_list']}\n")
            file.write(f"{sp_tab}Key_Hex_Bas = {item['key_hex_bas']}\n")
            file.write(f"{sp_tab}Key_Bin = \n")
            writelongbas(file,item['key_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            
            file.write(f"{tab}Nonce Vectors:\n")
            file.write(f"{sp_tab}Nonce_Hex_List = {item['nonce_hex_list']}\n")
            file.write(f"{sp_tab}Nonce_Hex_Bas = {item['nonce_hex_bas']}\n")
            file.write(f"{sp_tab}Nonce_Bin = \n")
            writelongbas(file,item['nonce_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            
            
            file.write(f"{tab}Counter Vectors:\n")
            file.write(f"{sp_tab}Counter_Hex_List = {item['counter_hex_list']}\n")
            file.write(f"{sp_tab}Counter_Hex_Bas = {item['counter_hex_bas']}\n")
            file.write(f"{sp_tab}Counter_Bin = \n")
            writelongbas(file,item['counter_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            
            
            file.write(f"{tab}Constant Vectors:\n")
            file.write(f"{sp_tab}Constants_Hex_List = {item['constant_hex_list']}\n")
            file.write(f"{sp_tab}Constants_Hex_Bas = {item['constant_hex_bas']}\n")
            file.write(f"{sp_tab}Constants_Bin = \n")
            writelongbas(file,item['constant_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            
            
            file.write(f"{tab}Initial Matrixs:\n")
            file.write(f"{sp_tab}Initial_Matrix_Hex = \n")
            mtx = ''.join([f"{sp_tab}{row}\n{sp_tab}" for row in item['initial_matrix_hex']])
            file.write(f"{sp_tab}{mtx}")
            file.write(f"Initial_Hex_Bas = {item['initial_hex_bas']}\n")
            file.write(f"{sp_tab}Initial_Bas_Bin = \n")
            writelongbas(file,item['initial_bas_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            
            
            file.write(f"{tab}Hashing Matrixs:\n")
            file.write(f"{sp_tab}Hashing_Matrix_Hex = \n")
            mtx = ''.join([f"{sp_tab}{row}\n{sp_tab}" for row in item['hashing_matrix_hex']])
            file.write(f"{sp_tab}{mtx}")
            file.write(f"Hashing_Hex_Bas = {item['hashing_hex_bas']}\n")
            file.write(f"{sp_tab}Hashing_Bas_Bin = \n")
            writelongbas(file,item['hashing_bas_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            
            
            file.write(f"{tab}Plain Text Matrixs:\n")
            file.write(f"{sp_tab}Plain_Matrix_Hex = \n")
            mtx = ''.join([f"{sp_tab}{row}\n{sp_tab}" for row in item['plain_matrix_hex']])
            file.write(f"{sp_tab}{mtx}")
            file.write(f"Plain_Hex_Bas = {item['plain_hex_bas']}\n")
            file.write(f"{sp_tab}Plain_Text_Bas_Bin = \n")
            writelongbas(file,item['plain_bas_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            
            
            file.write(f"{tab}Cipher Text Matrixs:\n")
            file.write(f"{sp_tab}Cipher_Matrix_Hex = \n")
            mtx = ''.join([f"{sp_tab}{row}\n{sp_tab}" for row in item['cipher_matrix_hex']])
            file.write(f"{sp_tab}{mtx}")
            file.write(f"Cipher_Hex_Bas = {item['cipher_hex_bas']}\n")
            file.write(f"{sp_tab}Cipher_Text_Bas_Bin = \n")
            writelongbas(file,item['cipher_bas_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            
            
            file.write(f"{tab}Decryption Text Matrixs:\n")
            file.write(f"{sp_tab}Decryption_Matrix_Hex = \n")
            mtx = ''.join([f"{sp_tab}{row}\n{sp_tab}" for row in item['decryption_hex']])
            file.write(f"{sp_tab}{mtx}")
            file.write(f"Decryption_Hex_Bas = {item['decryption_hex_bas']}\n")
            file.write(f"{sp_tab}Decryption_Text_Bas_Bin = \n")
            writelongbas(file,item['decryption_bin'],sp_tab,max_len = 80)
            file.write("\n\n")
            
            
            file.write(f"vectors ready: {item['message']}:\n" )
            
            file.write("-" * 200 + "\n\n")
        

###############################################################################
"""
k = random_key(0)
n = random_nonce(0)
c = random_counter(0)
cons = four_constant_words(1)
matx = initial_matrix(k,n,c,cons)

#hash_mtx = salsa_hash(matx,0)

m0 = colum_round(matx)
mr0 = row_round(m0)
"""  