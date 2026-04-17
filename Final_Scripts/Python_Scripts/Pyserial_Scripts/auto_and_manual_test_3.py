
# -*- coding: utf-8 -*-
"""
Created on Thu Oct  9 21:00:08 2025

@author: Nisan Moshe Slomov
File Name: test_runner&
    
Description:
UART JSON Test Runner for FPGA using SalsaDeviceUART

Workflow:
1. Load JSON file containing test(s) and register definitions.
2. Initialize UART communication via SalsaDeviceUART class.
3. Write initial registers:
   - PLAIN_TEXT
   - KEY
   - NONCE
   - COUNTER
   Values are taken from `swap_bytes` in JSON (little endian).
4. Wait for user/FPGA indication before continuing.
5. Read and compare registers:
   - HASHING
   - CIPHER
   Compare received data with expected `swap_bytes` values.
6. Print results color-coded:
   - Green: OK
   - Red: ERROR
   - Cyan/Blue: Writing
   - Yellow: Reading
7. Close UART port after test completion.

Helper functions:
- hex_to_byte_list(hex_str) -> list of bytes
- write_register(uart, reg) -> write one register
- read_register(uart, reg) -> read one register
- write_registers_from_json(uart, reg_group) -> write all registers in group
- read_and_compare_registers(uart, reg_group) -> read group and compare
- wait_for_user() -> pause execution until user confirms
"""

# -*- coding: utf-8 -*-
import argparse
import sys
import json
from colorama import init, Fore
from salsa_pyserial_3_uart import SalsaDeviceUART  # Import the class from separate file
import datetime
import time
import re
import difflib
import base64

# Initialize colorama
init(autoreset=True)

# Global counters for test results
#test_passed_count = 0
#test_failed_count = 0


#===========================================================
#=================== Helper function =======================
#===========================================================

#---------------------------------------------------------------
#-------------------- hex_to_byte_list -------------------------
#---------------------------------------------------------------

def hex_to_byte_list(hex_str):
    """
    Converts a hex string (0x44332211) 
    to a list of 4 bytes [0x44, 0x33, 0x22, 0x11]
    """
    hex_str = hex_str.lower().replace('0x','')
    return [int(hex_str[i:i+2],16) for i in range(0,8,2)]

#---------------------------------------------------------------
#---------------------- write_register -------------------------
#---------------------------------------------------------------

def write_register(uart, reg):
    """
    Writes one register to the FPGA according to swap_bytes.
    """
    address = int(reg['address'],16)
    data_bytes = hex_to_byte_list(reg['swap_bytes'])
    uart.write_to_device(address, 0x01, data_bytes)

#---------------------------------------------------------------
#---------------------- read_register --------------------------
#---------------------------------------------------------------

def read_register(uart, reg):
    """
    Reads one register from the FPGA
    """
    address = int(reg['address'],16)
    return uart.read_from_device(address, 0x03)

#---------------------------------------------------------------
#----------------- write_registers_from_json -------------------
#---------------------------------------------------------------

def write_registers_from_json(uart, reg_group):
    """
    Writes a group of registers.
    """
    for reg in reg_group:
        write_register(uart, reg)

#---------------------------------------------------------------
#---------------- read_and_compare_registers -------------------
#---------------------------------------------------------------
            
def read_and_compare_registers(uart, read_group, reg_group_name, expected_group=None, mode=None):
    """
    Reads a set of registers from UART and compares them to expected values.

    Supports two modes:
      1. Normal (Encrypt): compares each register in read_group to itself (expected inside same object).
      2. Decrypt mode: compares read_group values (e.g., CIPHER) against a *different* expected_group
         (e.g., PLAIN_TEXT from encrypt_mode).

    Parameters:
        uart            : UART device object
        read_group      : list of registers to read (the actual hardware addresses)
        reg_group_name  : descriptive name for logs (e.g. "CIPHER" or "PLAIN_TEXT")
        expected_group  : optional list of expected register values for comparison
        mode            : current test mode ("encrypt" / "decrypt"), only for logging aesthetics
    """
    
    global test_passed_count
    global test_failed_count
    
    results_for_summary = []
    current_section_passed = 0
    current_section_failed = 0
    
    # ---------------------- MODE + GROUP HEADER --------------------------------
    
    mode_str = f"MODE: {mode.upper()}" if mode else ""
    print_and_log(
        Fore.CYAN + f"\n{'='*90}\n>>> START READ and COMPARE for Group: {reg_group_name} --- {mode_str}\n{'='*90}",
        f"START READ and COMPARE Section: {reg_group_name} ({mode_str})"
    )
    
    if expected_group:
        print_and_log(
            Fore.YELLOW + f"Comparing {reg_group_name} read values against expected reference group.",
            f"Comparing {reg_group_name} values against reference group."
        )
    else:
        print_and_log(
            Fore.YELLOW + f"Comparing {reg_group_name} values against their own expected data.",
            f"Comparing {reg_group_name} values internally."
        )

    # ---------------------- MAIN LOOP --------------------------------
    
    # Prepare fixed-size list for true_value_be collection
    true_values_block = [None] * 16
    insert_index = 15  # start filling from the end backwards
    
    # idx: start from 0 and up to 15
    
    for idx, reg_read in enumerate(read_group):
        
        reg_expected = expected_group[idx] if expected_group else reg_read

        address = int(reg_read['address'], 16)
        expected_swap_bytes = reg_expected['swap_bytes']              # expected(LE)
        expected_bytes = hex_to_byte_list(expected_swap_bytes) # expected(LE)
        expected_value_be = reg_expected.get('value', 'N/A')               # expected (BE)
        
        # 1. Read from UART
        response_bytes = read_register(uart, reg_read)
        
        # 2. convert to BE and compare
        """
        for example:
            response_bytes = b'\x10\x20'
            expected_bytes = [0x10, 0x20]
            → True
        """
        true_value_be = bytes_to_true_hex(response_bytes) if response_bytes else "N/A"
        actual_swap_bytes = response_bytes.hex().upper() if response_bytes else "N/A"
        is_ok = response_bytes and list(response_bytes) == expected_bytes
        status = "PASS" if is_ok else "FAIL"
        
        # Add true_value_be to the 16-slot reverse list
        if insert_index >= 0:
            true_values_block[insert_index] = true_value_be
            insert_index -= 1
        
        #  # 3. Update counters
        if is_ok:
            current_section_passed += 1
        else:
            current_section_failed += 1
        
        # 4.print to konsole (compare with swap bytes)
        if is_ok:
            shell_output = Fore.GREEN + f"Address 0x{address:02X} OK. Read: {actual_swap_bytes}"
        else:
            shell_output = Fore.RED + f"Address 0x{address:02X} ERROR. Expected: {expected_swap_bytes} | Read (LE): {actual_swap_bytes}"
        
        # 5. log message
        log_msg = (f"READ Register | Group: {reg_group_name} | Address: 0x{address:02X} | Status: {status} | "
                   f"Expected (BE): {expected_value_be} | Actual (BE): {true_value_be} | "
                   f"Expected (LE): {expected_swap_bytes} | Actual (LE): 0x{actual_swap_bytes}") 
        print_and_log(shell_output, log_msg)
        
        # 6. save data to final tabel
        results_for_summary.append({
            'address': address,
            'expected_be': expected_value_be,
            'actual_be': true_value_be,
            'expected_le': expected_swap_bytes, 
            'actual_le': f"0x{actual_swap_bytes}", 
            'status': status
        })

    # ==========================================================
    # 7. bulding the final table - only to log
    # ==========================================================
    
    test_passed_count += current_section_passed
    test_failed_count += current_section_failed
    
    final_section_log = "\n" + "="*120
    final_section_log += "\n" + "-"*45 + f" READ SECTION SUMMARY [{reg_group_name}] ({mode_str}) " + "-"*40
    final_section_log += "\n" + "-"*41 + " (Big-Endian vs Little-Endian Display) " + "-"*40
    final_section_log += "\n" + "-"*30 + f" RESULTS: {current_section_passed} Passed / {current_section_failed} Failed in this group." + "-"*45
    final_section_log += "\n" + "="*120
    final_section_log += "\n| Address | Status | Expected (BE) | Actual (BE) | Expected (LE) | Actual (LE) |" 
    final_section_log += "\n|---------|--------|---------------|-------------|---------------|-------------|"
    
    
    for res in results_for_summary:
        final_section_log += (f"\n| 0x{res['address']:02X}    | {res['status']:<6} | {res['expected_be']:<13} | {res['actual_be']:<11} | {res['expected_le']:<13} | {res['actual_le']:<11} |") 
        
    final_section_log += "\n" + "="*120 + "\n"
    
    print_and_log(Fore.BLUE + "Read/Compare summary saved to log.", final_section_log)
    
    
    # cleaning None if we have in list
    filtered_block = [v for v in true_values_block if v is not None]
    
    # devide with '|'
    block_str = ' | '.join(filtered_block)
    
    add_to_shell = (Fore.MAGENTA + f"\nBig-Endien bas reading from {reg_group_name}, {mode_str}" + 
                    "\n" + block_str + "\n")                 
    
    add_to_log = ("\n" + "@"*120 + f"\nBig-Endien bas reading from {reg_group_name}, {mode_str}" + 
                  "\n" + block_str + "\n"  + "@"*120 + "\n\n")
    
    print_and_log(add_to_shell,add_to_log)

#---------------------------------------------------------------
#-------------------- write_fixed_register ---------------------
#---------------------------------------------------------------

def write_fixed_register(uart, address, swap_bytes):
    """
    Write a fixed register value to the FPGA - to debug mode
    """
    data_bytes = hex_to_byte_list(swap_bytes)
    uart.write_to_device(address, 0x01, data_bytes)
    
    # Description for CONTROL/STATUS**
    description = parse_control_status(address, swap_bytes)
    
    log_msg = (f"WRITE FIXED Register | Address: 0x{address:02X} | "
               f"Sent Data (swap_bytes LE): {swap_bytes} | Description: {description}")
    
    print_and_log(
        Fore.CYAN + f"Write 0x{address:02X} -> {swap_bytes} (Fixed Reg) {description}", 
        log_msg
    )

#---------------------------------------------------------------
#---------------------- wait_for_user --------------------------
#---------------------------------------------------------------

def wait_for_user():
    """
    Waits until the user presses only Enter.
    Ignores any other input.
    """
    while True:
        user_input = input(Fore.MAGENTA + "\nPress Enter to continue after FPGA processing...")
        if user_input == "":
            break
        print(Fore.YELLOW + "Just press Enter (no typing).")


#---------------------------------------------------------------
#---------------------- interactive_pause --------------------------
#---------------------------------------------------------------

def interactive_pause(uart):
    """
    Interactive debugging mode.
    Commands:
    - r <addr> : read register
    - w <addr> <value> : write register
    - c : continue
    - h : help
    """
    # start debug mode
    print_and_log(Fore.MAGENTA + "Entered interactive debug mode. Use 'c' to continue.",
                  "DEBUG MODE: Entered interactive session.")
    
    while True:
        cmd = input(Fore.MAGENTA + "Debug> ").strip()
        
        # ------------------- C: CONTINUE -------------------
        if cmd == "c":
            print_and_log(Fore.MAGENTA + "Continuing script execution.",
                          "DEBUG MODE: Continuing script execution.")
            break
        
        # ------------------- R: READ -------------------
        elif cmd.startswith("r "):
            try:
                _, addr_str = cmd.split()
                addr = int(addr_str, 16)
                val = uart.read_from_device(addr, 0x03)
                hex_parts = [f"{byte:02x}" for byte in val]
                display_val = "".join(hex_parts)
                
               # print to konsole
                shell_output = Fore.YELLOW + f"Read 0x{addr:02X} -> 0x{display_val}"
                
               # print to log
                log_msg = f"DEBUG READ | Address: 0x{addr:02X} | Value (LE): 0x{display_val}"
                print_and_log(shell_output, log_msg)
                
            except ValueError:
                print(Fore.RED + "Invalid read command. Use format: r <hex_addr> (e.g., r 0x10)")
            except Exception as e:
                print(Fore.RED + f"Error during read operation: {e}")

        # ------------------- W: WRITE -------------------
        elif cmd.startswith("w "):
            try:
                _, addr_str, value_str = cmd.split()
                addr = int(addr_str, 16)
                bytes_list = hex_to_byte_list(value_str)
                uart.write_to_device(addr, 0x01, bytes_list)
                
               # print to konsole
                shell_output = Fore.GREEN + f"Wrote 0x{value_str} to 0x{addr:02X}"
                
                # print to log
                log_msg = f"DEBUG WRITE | Address: 0x{addr:02X} | Sent Data (LE): 0x{value_str}"
                print_and_log(shell_output, log_msg)
                
            except ValueError:
                print(Fore.RED + "Invalid write command. Use format: w <hex_addr> <hex_value> (e.g., w 0x00 0x01000000)")
            except Exception as e:
                print(Fore.RED + f"Error during write operation: {e}")
                
        # ------------------- H: HELP -------------------
        elif cmd == "h":
            # print to konsole
            print("""
                  Commands (all values in little endian / swap_bytes format):
                      - r <addr>         : read register at hex address (e.g., r 0x10)
                      - w <addr> <value> : write register (value in 0x44332211 format)
                      - c                : continue script execution
                      - h                : show this help
                      """)
            print("Commands: r <addr>, w <addr> <value>, c=continue, h=help")
            
        # ------------------- UNKNOWN -------------------
        else:
            print(Fore.RED + "Unknown command, h for help")


#---------------------------------------------------------------
#--------------------- print_and_log ---------------------------
#---------------------------------------------------------------

def print_and_log(text_for_shell, text_for_log=""):
    """
    Prints a message to the shell and writes a more detailed message to the log file.
    """
   # print to shell
    print(text_for_shell)
    
    # print to log
    if not text_for_log:
        text_for_log = text_for_shell.strip() # default = data to shell
        
    timestamp = datetime.datetime.now().strftime("[%Y-%m-%d %H:%M:%S.%f]")
    
    global log_file
    if 'log_file' in globals() and log_file:
        log_file.write(f"{timestamp} {text_for_log}\n")


#---------------------------------------------------------------
#------------------- bytes_to_true_hex -------------------------
#---------------------------------------------------------------

def bytes_to_true_hex(byte_data):
    """
    Converts a bytes object (e.g., b'\x11\x22\x33\x44') 
    to a human-readable, correct big-endian hex string (e.g., '0x44332211').
    """
    
    if not byte_data:
        return "0x00000000"
    
    # 1.
    # convert little endian to big endian
    # val = b'\xc1\xca\xe0\x2b'  ->  reversed = b'\x2b\xe0\xca\xc1'
    reversed_data = byte_data[::-1]
    
    # 2.
    # convert to hex withot 'b'
    hex_string = reversed_data.hex().upper()
    
    # 3.
    # add "0x"
    return f"0x{hex_string}"


#---------------------------------------------------------------
#-------------------- parse_control_status ---------------------
#---------------------------------------------------------------

def parse_control_status(address, swap_bytes):
    """
    Provides a human-readable description for CONTROL (0x00) and STATUS (0x01) registers.
    """
    
    addr = int(address)
    value = int(swap_bytes, 16) # Value in LE (swap_bytes)
    
    if addr == 0x00:
        # CONTROL Register (based on common FPGA structures)
        description = "CONTROL:"
        if value & 0x04000000:
            description += " Start Operation"
        if value & 0x00010000:
            description += " | HASH_START (0x04010000)"
        if value & 0x00000100:
            description += " | CIPHER_START (0x04000100)"
        if value == 0x04000000:
             description = "CONTROL: Initial State (Ready)"
        return description
        
    elif addr == 0x01:
        # STATUS Register (based on common LED control in the flow)
        description = "STATUS:"
        if value & 0x01000000:
            description += " LED OFF (After HASHING)"
        elif value & 0x02000000:
            description += " LED OFF (After CIPHER)"
        else:
            description += " (Unknown State)"
        return description
        
    return "" # Not a control/status register

#---------------------------------------------------------------
#------------------ write_register_group -----------------------
#---------------------------------------------------------------

def write_register_group(uart, reg_group_name, reg_group):
    """
    Writes a list of registers (a Vector) to the device.
    reg_group_name is the key (e.g., 'PLAIN_TEXT') for logging clarity.
    reg_group is the list of register dictionaries.
    """

    section_start_log = (f"\n{'-'*100}"
                     f"\n{'-'*30} START WRITE Section: {reg_group_name} {'-'*30}"
                     f"\n{'-'*100}\n")
    print_and_log(Fore.YELLOW + f"Starting WRITE for Group: {reg_group_name}...", section_start_log)

    # keep Big Endien value
    be_values_to_concatenate = [] 
    
    for reg in reg_group:
        address = int(reg['address'], 16)
        swap_bytes = reg['swap_bytes'] # sen at LE 
        value_be = reg.get('value', 'N/A') # BE - to log
        
        # 1. convert to bytes and writing
        data_bytes_le = hex_to_byte_list(swap_bytes) 
        uart.write_to_device(address, 0x01, data_bytes_le)
        
        # 2.build log message
        log_msg = (f"WRITE Register | Group: {reg_group_name} | Address: 0x{address:02X} | "
                   f"Value (BE): {value_be} | Sent Data (swap_bytes LE): {swap_bytes}")
        
        # 3. print to konsole and log
        print_and_log(
            Fore.CYAN + f"Write 0x{address:02X} -> {swap_bytes}", 
            log_msg
        )
        
        # 4. keep BE without '0x'
        if value_be != 'N/A':
            be_values_to_concatenate.append(value_be[2:])

    # 5. MSB....LSB (Bytes order)
    full_vector_be = "".join(reversed(be_values_to_concatenate))
    
    final_log_msg = (f"\n\n{'#'*60}"
                 f"\n--- WRITE SECTION SUMMARY for {reg_group_name} ---"
                 f"\nFull Vector (Big-Endian, MSB-first): 0x{full_vector_be}"
                 f"\n{'#'*60}\n")
    
    print_and_log(
        Fore.BLUE + f"Write Section {reg_group_name} summary saved to log.", 
        final_log_msg
    )



#---------------------------------------------------------------
#------------------ decode_encrypt_log -----------------------
#---------------------------------------------------------------

def decode_encrypt_log() -> str:
    """
    Extracts all ENCRYPT blocks from the global log_file,
    combines the hex values in order of test ID, converts to UTF-8 text,
    and saves to a predefined output file.
    """
    
    log_file_path = ("C:/Users/HP/Desktop/Degree/Nisan_final_project/scripts/"
                     "python_scripts/pyserial_scripts/pyserial_output/uart_implementation_log.txt")
    
    # encrypt output file 
    output_file = ("C:/Users/HP/Desktop/Degree/Nisan_final_project/scripts/"
                   "python_scripts/pyserial_scripts/encrypt_output/encrypt_decoded_output.txt")
    
    # Reading the log file
    with open(log_file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
        
    all_hex = []
    current_test = []
    capture = False
    
    
    for line in lines:
        line = line.strip()
        
        if "Big-Endien bas reading from CIPHER, MODE: ENCRYPT" in line:
            capture = True
            current_test = []
            continue
        
        if capture:
            matches = re.findall(r'0x[0-9A-Fa-f]{8}', line)
            if matches:
                current_test.extend(matches)
                
            if len(current_test) == 16:
                all_hex.extend(current_test)  # list of all lists
                capture = False
    
            
    if not all_hex:
        return "No ENCRYPT blocks found in the log."


    # convert hex to byte
    byte_array = bytearray()
    for h in all_hex:
        val = int(h, 16)
        bytes_list = val.to_bytes(4,'big')
        byte_array.extend(bytes_list)
        
    encoded_text = base64.b64encode(byte_array).decode('ascii')
    
    line_length = 64
    formatted_text = '\n'.join(
        encoded_text[i:i+line_length] for i in range(0, len(encoded_text), line_length)
    )

    # write as a utf-8
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(formatted_text)

    return f"Decoded text saved to: {output_file}"


#---------------------------------------------------------------
#------------------ decode_decrypt_log -----------------------
#---------------------------------------------------------------

def decode_decrypt_log() -> str:
    """
    Extracts all DECRYPT blocks from the global log_file,
    combines the hex values in order of test ID, converts to UTF-8 text,
    and saves to a predefined output file.
    """
    
    log_file_path = ("C:/Users/HP/Desktop/Degree/Nisan_final_project/scripts/"
                     "python_scripts/pyserial_scripts/pyserial_output/uart_implementation_log.txt")
    
    # decrypt output file 
    output_file = ("C:/Users/HP/Desktop/Degree/Nisan_final_project/scripts/"
                   "python_scripts/pyserial_scripts/decrypt_output/decoded_output.txt")
    
    with open(log_file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
        
    all_hex = []
    current_test = []
    capture = False
    
    
    for line in lines:
        line = line.strip()
        
        if "Big-Endien bas reading from CIPHER, MODE: DECRYPT" in line:
            capture = True
            current_test = []
            continue
        
        if capture:
            matches = re.findall(r'0x[0-9A-Fa-f]{8}', line)
            if matches:
                current_test.extend(matches)
                
            if len(current_test) == 16:
                all_hex.extend(current_test) #list of all lists
                capture = False
    
            
    if not all_hex:
        return "No DECRYPT blocks found in the log."


    # convert hex to byte
    byte_array = bytearray()
    for h in all_hex:
        val = int(h, 16)
        # split to 4 bytes (big endian)
        bytes_list = val.to_bytes((val.bit_length() + 7) // 8, 'big')
        #bytes_list = val.to_bytes(4,'big')
        byte_array.extend(bytes_list)

    # write as a utf-8
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(byte_array.decode("utf-8"))

    return f"Decoded text saved to: {output_file}"



#---------------------------------------------------------------
#------------------ compare_with_original -----------------------
#---------------------------------------------------------------

def compare_with_original(decoded_file: str, original_file: str, diff_output: str):
    
    try:
        with open(decoded_file, "r", encoding="utf-8") as f1, open(original_file, "r", encoding="utf-8") as f2:
            text1 = f1.readlines()
            text2 = f2.readlines()

        d = difflib.HtmlDiff()
        html = d.make_file(text1, text2, "Decoded", "Original")


        with open(diff_output, "w", encoding="utf-8") as f:
            f.write(html)

        print(f"HTML diff created: {diff_output}")

    except FileNotFoundError as e:
        print(f"[ERROR] File not found: {e}")
    except Exception as e:
        print(f"[ERROR] Something went wrong during comparison: {e}")



"""   
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  
"""


#==========================================================================
#==========================================================================
#============================ Main Execution ==============================
#==========================================================================
#==========================================================================

if __name__ == "__main__":
    
    # === CLI Argument Parser ===
    parser = argparse.ArgumentParser(description="Run Salsa test using a JSON input file.")
    parser.add_argument(
        "-f", "--file",
        type=str,
        default="test_data.json",
        help="Path to JSON test file (default: test_data.json)"
    )
    
    try:
        args = parser.parse_args()
    except SystemExit as e:
        print("\n[ERROR] Invalid arguments provided.")
        print("Make sure to specify the JSON file with -f or --file, for example:")
        print("  python auto_and_manual_test_3.py --file path/to/test.json")
        sys.exit(1)
    
    
    # === Load the JSON file ===
    try:
        with open(args.file, "r") as f:
            tests = json.load(f)
    except FileNotFoundError:
        print(Fore.RED + f"\n[ERROR] JSON file not found: {args.file}")
        sys.exit(1)
    except json.JSONDecodeError:
        print(Fore.RED + f"\n[ERROR] Invalid JSON format in file: {args.file}")
        sys.exit(1)
    
    # === check if have tests ===
    if not tests:
        print(Fore.RED + "\n[ERROR] No tests found in the JSON file.")
        sys.exit(1)
    
    # ======= log file ==========
    LOG_FILE = ("C:/Users/HP/Desktop/Degree/Nisan_final_project/scripts/"
                "python_scripts/pyserial_scripts/pyserial_output/uart_implementation_log.txt") 
    try:
        log_f = open(LOG_FILE, "w", encoding="utf-8")
        print(Fore.BLUE + f"Test log will be saved to: {LOG_FILE}")
        
    except IOError as e:
        print(Fore.RED + f"\n[ERROR] Failed to open log file {LOG_FILE}: {e}")
        sys.exit(1)
        
    # ==== Global saving of the file object ====
    
    global log_file 
    log_file = log_f 

    # ======================================
    
    try:
        # === open port ===
        print(f"{Fore.BLUE}Attempting to open UART port COM4")
        dev = SalsaDeviceUART('COM4', 100000)
        print(Fore.BLUE + "UART port opened successfully.")
        
        
        # === mode section ===
        mode = None
        while True:
            while mode not in ["encrypt","decrypt"]:
                mode = input(Fore.MAGENTA + "Select mode (encrypt/decrypt): ").strip().lower()
                
                if mode not in ["encrypt","decrypt"]:
                    print(Fore.YELLOW + "Invalid mode. Please type 'encrypt' or 'decrypt'.")
                    
            print(Fore.CYAN + f"Mode selected: {mode.upper()}")  
        
            # --- Add debug mode selection here ---
            debug_mode = input(Fore.MAGENTA + "Enable debug mode? (y/n): ").strip().lower() == 'y'
            print(Fore.CYAN + f"Debug mode {'enabled' if debug_mode else 'disabled'}.\n")
            
            # number of test
            total_tests = len(tests)
        
            # === tests loop ===
            for i, test in enumerate(tests):
                test_title_shell = Fore.CYAN + "="*80 + "\n" + Fore.MAGENTA + f"*** STARTING TEST {i+1} of {total_tests}: {test['Test_ID']} - {test['Description']} ***" + "\n" + Fore.CYAN + "="*80
                test_title_log = (f"\n{'-'*108}" + f"\n{'-'*108}" + f"\n{'*'*108}" +
                      f"\n*{'*'*25} [TEST START] Test {i+1} of {total_tests} | ID: {test['Test_ID']} | Desc: {test['Description']} *{'*'*25}\n" +
                      f"{'-'*108}\n"+
                      f"*{'*'*40} START {mode.upper()} MODE TESTS *{'*'*40}\n" +
                      f"{'-'*108}\n" + f"\n{'*'*108}" + f"\n{'*'*108}")
                
                print_and_log(test_title_shell, test_title_log)
                
                #global test_passed_count
                #global test_failed_count
                
                test_passed_count = 0
                test_failed_count = 0
    
    
    # -------------------------------------------------------------------
    # --------------------------- FLOW ----------------------------------
    # -------------------------------------------------------------------
            
                # 1-2: Burn FPGA & release RST manually
                print(Fore.CYAN + "Step 1-2: Burn FPGA & release RST manually, then press Enter in debug mode.")
                
                if debug_mode:
                    interactive_pause(dev)
        
                # 3: Write CONTROL 0x00 -> 0x04000000
                write_fixed_register(dev, 0x00, "0x04000000")
                print(Fore.CYAN + "CONTROL 0x00 -> 0x04000000 written")
                
                if debug_mode:
                    interactive_pause(dev)
        
                # 4: Write initial registers from JSON
                plain_text_group = test['REGISTERS']['PLAIN_TEXT'][f"{mode}_mode"]
                write_register_group(dev,'PLAIN_TEXT', plain_text_group)
                                
                write_register_group(dev,'KEY', test['REGISTERS']['KEY'])
                write_register_group(dev,'NONCE', test['REGISTERS']['NONCE'])
                write_register_group(dev,'COUNTER', test['REGISTERS']['COUNTER'])
                print(Fore.CYAN + "Initial registers written")
                
                if debug_mode:
                    interactive_pause(dev)
        
                # 6: Write CONTROL 0x00 -> 0x04010000 (before HASHING)
                write_fixed_register(dev, 0x00, "0x04010000")
                print(Fore.CYAN + "CONTROL 0x00 -> 0x04010000 written (HASHING step)")
    
                if debug_mode:
                    interactive_pause(dev)
        
                # 8: Read HASHING registers
                read_and_compare_registers(dev, test['REGISTERS']['HASHING'], 'HASHING')
                
                if debug_mode:
                    interactive_pause(dev)
        
                # 10: Write STATUS 0x01 -> 0x01000000
                write_fixed_register(dev, 0x01, "0x01000000")
                print(Fore.CYAN + "STATUS 0x01 -> 0x01000000 written (LED off)")
                
                if debug_mode:
                    interactive_pause(dev)
        
                # 12: Write CONTROL 0x00 -> 0x04000100 (before CIPHER)
                write_fixed_register(dev, 0x00, "0x04000100")
                print(Fore.CYAN + "CONTROL 0x00 -> 0x04000100 written (CIPHER step)")
                
                if debug_mode:
                    interactive_pause(dev)
        
                # 14: Read CIPHER registers
                if mode == "encrypt":
                    print (Fore.CYAN + "Step 14: Reading and comparing CIPHER registers (Encryption mode)")
                    read_and_compare_registers(
                        dev,
                        read_group=test['REGISTERS']['CIPHER'],
                        reg_group_name='CIPHER',
                        expected_group=None,
                        mode=mode)
                else:
                    print(Fore.CYAN + "Step 14: Reading and comparing CIPHER vs PLAIN_TEXT (Decryption mode)")
                    read_and_compare_registers(
                        dev, 
                        read_group=test['REGISTERS']['CIPHER'],
                        reg_group_name='CIPHER',
                        expected_group=test['REGISTERS']['PLAIN_TEXT']['encrypt_mode'],
                        mode=mode)
                    
                if debug_mode:
                    interactive_pause(dev)
        
                # 16: Write STATUS 0x01 -> 0x02000000
                write_fixed_register(dev, 0x01, "0x02000000")
                print(Fore.CYAN + "STATUS 0x01 -> 0x02000000 written (LED off)")
                
                if debug_mode:
                    interactive_pause(dev)
        
                # 18: Read final CONTROL
                final_control = read_register(dev, {"address": "0x00", "swap_bytes": "0x04000000"})
                final_control_be = bytes_to_true_hex(final_control)
                print(Fore.CYAN + f"Final CONTROL 0x00 -> Read (BE): {final_control_be}")
    
                
                result_color = Fore.GREEN if test_failed_count == 0 else Fore.RED
                
                test_summary_shell = (f"\n{result_color}" + "="*80 + 
                          f"\n*** TEST {i+1} of {total_tests} SUMMARY: {test['Test_ID']} MODE: {mode.upper()}***" + 
                          f"\nTotal Checks: {test_passed_count + test_failed_count}" +
                          f"\nPASSED: {test_passed_count} | FAILED: {test_failed_count}" +
                          f"\nTest Status: {'SUCCESS' if test_failed_count == 0 else 'FAILURE'}" +
                          "\n" + "="*80 +
                          f"\n{result_color}Test ID {test['Test_ID']} Completed {'Successfully.' if test_failed_count == 0 else 'with Failure.'}" +
                          f"\n--- Test {i+1} of {total_tests} finished. ---")
                
                
                test_summary_log = ("\n" + "#"*109 +
                                    "\n"+ "#"*40 + f" [TEST END] Test {i+1} Completed." + "#"*40 +
                                    "\n"+ "#"*40 + f" Total Checks: {test_passed_count + test_failed_count}" + " "*12 + "#"*40 +
                                    "\n"+ "#"*40 + f" Passed: {test_passed_count}."  + " "*17 + "#"*40 +
                                    "\n"+ "#"*40 + f" Failed: {test_failed_count}."  + " "*18 + "#"*40 +
                                    "\n" + "#"*109)
                
                print_and_log(test_summary_shell, test_summary_log)
                
                
                if debug_mode:
                    interactive_pause(dev)
                
            
            #----------------------------------------------------------------#
            
            if mode == "encrypt":
                cont = input(Fore.MAGENTA + "Encryption tests completed. Run decryption tests now? (y/n): ").strip().lower()
                if cont == "y":
                    mode = "decrypt"
                    time.sleep(1.0)
                    continue
                else:
                    print(Fore.CYAN + "Ending communication. Closing UART and LOG.")
                    
                    if 'dev' in locals() and dev:
                        dev.close()
                        print(Fore.BLUE + "\nUART port closed.")
                        
                    if 'log_file' in globals() and log_file:
                        log_file.close()
                        print(Fore.BLUE + f"\nLog file {LOG_FILE} closed.")
                        
                    print(Fore.CYAN + "Create encrypt decoded file.")
                    result = decode_encrypt_log()
                    print(Fore.CYAN + result)     # the return from func
                        
                    break
            
            # mode == "decrypt"  
            else:
                print(Fore.CYAN + "Decryption tests completed.")
                
                if 'dev' in locals() and dev:
                    dev.close()
                    print(Fore.BLUE + "\nUART port closed.")
                    
                if 'log_file' in globals() and log_file:
                    log_file.close()
                    print(Fore.BLUE + f"\nLog file {LOG_FILE} closed.")
                    
                
                
                # ask if want to decode encrypt
                create_encrypt_output = input(Fore.MAGENTA + "Do you want to create the decoded text file from ENCRYPT blocks? (y/n): ").strip().lower()
                if create_encrypt_output == 'y':
                    encrypt_result = decode_encrypt_log()
                    print(Fore.CYAN + encrypt_result)     # the return from func
                    
                # ask if want to decode decrypt
                create_decrypt_output = input(Fore.MAGENTA + "Do you want to create the decoded text file from DECRYPT blocks? (y/n): ").strip().lower()
                if create_decrypt_output == 'y':
                    decrypt_result = decode_decrypt_log()
                    print(Fore.CYAN + decrypt_result)     # the return from func
                  
                    # ask if want to compare with original
                    compare_choice = input(Fore.MAGENTA + "Do you want to compare the decoded file with the original file? (y/n): ").strip().lower()
                    if compare_choice == 'y':
                        decoded_file = ("C:/Users/HP/Desktop/Degree/Nisan_final_project/scripts/"
                                       "python_scripts/pyserial_scripts/decrypt_output/decoded_output.txt")
                        
                        original_file = (r"C:\Users\HP\Desktop\Degree\Nisan_final_project\scripts\python_scripts\‏‏harry_potter_text2.txt")
                        
                        diff_output = ("C:/Users/HP/Desktop/Degree/Nisan_final_project/scripts/"
                                       "python_scripts/pyserial_scripts/decrypt_output/diff_output.html") 
                        
                        
                        compare_with_original(decoded_file,original_file,diff_output)
                
                
                print(Fore.CYAN + "Ending communication.")
                break

    except Exception as e:
        print(Fore.RED + f"\n[FATAL ERROR] An unexpected error occurred: {e}")
        sys.exit(1)
        
    finally:
        # === Closing the port connection ===
        if 'dev' in locals() and dev:
             dev.close()
             print(Fore.BLUE + "\nUART port closed.")

        # === Closing the log file ===
        if 'log_file' in globals() and log_file:
            log_file.close()
            print(Fore.BLUE + f"Log file {LOG_FILE} closed.")
            













