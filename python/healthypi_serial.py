import serial

SERIAL_BAUD = 115200

ser = serial.Serial('/dev/tty.usbmodem101', SERIAL_BAUD)

while True:
    try:
        ser_bytes = ser.read()
        print(ser_bytes)
    except:
        print("Keyboard Interrupt")
        break