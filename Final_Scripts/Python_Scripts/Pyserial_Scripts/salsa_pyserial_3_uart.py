# -*- coding: utf-8 -*-
"""
Created on Mon Oct  6 16:53:55 2025

@author: HP
"""

# -*- coding: utf-8 -*-
"""
SalsaDeviceUART with colored HEX prints and clear address/command
"""

import serial
import time
from colorama import init, Fore, Style

# Initialize colorama
init(autoreset=True)


class SalsaDeviceUART:
    def __init__(self, port='COM4', baudrate=100000, timeout=1):
        """Open serial port once for communication"""
        self.ser = serial.Serial(port, baudrate, timeout=timeout)
        print(Fore.GREEN + f" Port {port} opened successfully ({baudrate}bps)")

    def _enter_active_mode(self):
        """Send 0xAA to release from IDLE"""
        self.ser.write(bytes([0xAA]))
        self.ser.flush()
        time.sleep(0.02)

    def _send_and_wait(self, frame, expected_bytes=0):
        """Send frame and wait for response if needed (no printing here)"""
        self.ser.write(frame)
        self.ser.flush()
        time.sleep(0.02)

        if expected_bytes > 0:
            response = self.ser.read(expected_bytes)
            return response
        return None


    def write_to_device(self, address, command, data_bytes):
        """Write 4-byte data to device"""
        if len(data_bytes) != 4:
            raise ValueError("data_bytes must contain exactly 4 bytes")

        print(Fore.CYAN + f"\nWriting to Address 0x{address:02X}")
        self._enter_active_mode()

        frame = bytes([address, command] + data_bytes)

        hex_frame = ' '.join(f"{b:02X}" for b in frame)
        print(Fore.BLUE + f"[Address: 0x{address:02X} | Command: 0x{command:02X} | WRITE] ➡ Sending: {hex_frame}")

        self._send_and_wait(frame)
        print(Fore.GREEN + f"Writing completed for Address 0x{address:02X}")



    def read_from_device(self, address, command):
        """Read 4-byte data from device"""
        print(Fore.CYAN + f"\nReading from Address 0x{address:02X}")
        self._enter_active_mode()

        frame = bytes([address, command])

        hex_frame = ' '.join(f"{b:02X}" for b in frame)
        print(Fore.BLUE + f"[Address: 0x{address:02X} | Command: 0x{command:02X} | READ] ➡ Sending: {hex_frame}")

        response = self._send_and_wait(frame, expected_bytes=4)
  
        if response:
            hex_response = ' '.join(f"{b:02X}" for b in response)
            print(Fore.YELLOW + f"[Address: 0x{address:02X} | READ]  Received: {hex_response}")
        else:
            print(Fore.RED + f"[Address: 0x{address:02X} | READ]  No valid response")

        return response


    def close(self):
        if self.ser.is_open:
            self.ser.close()
            print(Fore.GREEN + "Port closed")


# === Example usage ===
if __name__ == "__main__":
    dev = SalsaDeviceUART('COM4', 100000)

    try:
        dev.write_to_device(address=0x10, command=0x01, data_bytes=[0x11, 0x22, 0x33, 0x44])
        
        dev.write_to_device(address=0x09, command=0x01, data_bytes=[0x10, 0xAA, 0xFF, 0x55])
        
        data = dev.read_from_device(address=0x01, command=0x03)
        
        data = dev.read_from_device(address=0x10, command=0x03)
        
        data = dev.read_from_device(address=0x09, command=0x03)

    finally:
        dev.close()