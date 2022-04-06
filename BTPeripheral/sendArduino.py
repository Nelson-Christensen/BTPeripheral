import serial
import time

from serial.tools import list_ports
port = list(list_ports.comports())
for p in port:
    if p.device.find("cu.usbmodem") != -1:
        portInUse = p.device
        print(p.device)
        

arduino = serial.Serial(port=portInUse, baudrate=115200, timeout=.1)


def write_read(x):
    arduino.write(bytes(x, 'utf-8'))
    time.sleep(0.05)
    data = arduino.readline()
    return data
def write(x):
    arduino.write(bytes(x, 'utf-8'))
    print(bytes(x, 'utf-8'))
    return "sent"
