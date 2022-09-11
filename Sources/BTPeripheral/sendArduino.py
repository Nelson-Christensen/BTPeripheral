import serial
import time

from serial.tools import list_ports
port = list(list_ports.comports())
arduino = serial.Serial()
arduinoFound = 0
for p in port:
    if p.device.find("cu.usbmodem") != -1:
        portInUse = p.device
        print(p.device)
        arduinoFound = 1
        
if arduinoFound == 1:
    print ("found Device")
    try:
        arduino = serial.Serial(port=portInUse, baudrate=115200, timeout=.1)
    except:
        print("Serial Error, did not establish contact, try connect usb and restart this program!")


def write_read(x):
    if arduinoFound == 1:
        arduino.write(bytes(x, 'utf-8'))
        time.sleep(0.05)
        data = arduino.readline()
    return data


def write(x):
    if arduino.isOpen() == True:
        try:
            arduino.write(bytes(x, 'utf-8'))
            print(bytes(x, 'utf-8'))
        except:
            print("Device Error, did not write, try connect usb and restart this program!")

    return "sent"
