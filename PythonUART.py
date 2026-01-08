import serial
import time

SERIAL_PORT = 'COM15' 
BAUD_RATE = 15200      
data_list = []     

try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
    print(f"Connected to {SERIAL_PORT} at {BAUD_RATE} baud.")
    ser.reset_input_buffer()

    while True:
        if ser.in_waiting > 0:
            line = ser.readline().decode('utf-8').rstrip()
            
            if line:
                data_list.append(line)
                print(f"Received: {line}")
                print(f"List size: {len(data_list)}")

except serial.SerialException as e:
    print(f"Error opening{e}")

except KeyboardInterrupt:
    print("\nStopped")

finally:
    if 'ser' in locals() and ser.is_open:
        ser.close()
        print("Serial port closed.")
        
    # Optional: Print final list contents
    print("Data", data_list)
