""" Program to push HealthyPi 5 streaming data to a LSL stream
"""
import sys
import getopt
import serial

import time
from random import random as rand

from pylsl import StreamInfo, StreamOutlet, local_clock

""
"System Settings"
SERIAL_PORT_NAME = '/dev/tty.usbmodem2101'
SERIAL_BAUD = 115200
LSL_ENABLED = False

""
CESState_Init = 0
CESState_SOF1_Found = 1
CESState_SOF2_Found = 2
CESState_PktLen_Found = 3

"/*CES CMD IF Packet Format*"
CES_CMDIF_PKT_START_1   =   '0a'
CES_CMDIF_PKT_START_2   =   'fa'
CES_CMDIF_PKT_STOP      =   '0b' 

"CES CMD IF Packet Indices*"
CES_CMDIF_IND_LEN = 2
CES_CMDIF_IND_LEN_MSB = 3
CES_CMDIF_IND_PKTTYPE = 4
CES_CMDIF_PKT_OVERHEAD = 5

ecs_rx_state = CESState_Init

CES_Pkt_Data_Counter = [0] * 50
CES_Data_Counter = 0
CES_Pkt_ECG=bytearray()
CES_Pkt_Resp=bytearray()
CES_Pkt_PPG_IR=bytearray()

ser = serial.Serial(SERIAL_PORT_NAME,SERIAL_BAUD)

srate = 500
name = 'AU_BCI'
type = 'EEG'
n_channels = 6

if LSL_ENABLED==True:
    info = StreamInfo(name, type, n_channels, srate, 'float32', 'myuid34234')
    outlet = StreamOutlet(info)

def processRxChar(rxch):
    if ecs_rx_state==CESState_Init:
            #print(rxch)
        if rxch==CES_CMDIF_PKT_START_1:
                #print("Pkt Start")
                ecs_rx_state=CESState_SOF1_Found
        elif ecs_rx_state==CESState_SOF1_Found:
                if rxch==CES_CMDIF_PKT_START_2:
                    ecs_rx_state=CESState_SOF2_Found
                else:
                    ecs_rx_state=CESState_Init
        elif ecs_rx_state==CESState_SOF2_Found:
                ecs_rx_state = CESState_PktLen_Found
                CES_Pkt_Len = int(rxch,16) #int.from_bytes(rxch,'big')
                #print(CES_Pkt_Len)
                CES_Pkt_Pos_Counter = CES_CMDIF_IND_LEN
                CES_Data_Counter = 0
        elif ecs_rx_state==CESState_PktLen_Found:
                #print("Pkt Len Found")
                CES_Pkt_Pos_Counter+=1
                #print("Pkt Pos:") 
                #print(CES_Pkt_Pos_Counter)
                if CES_Pkt_Pos_Counter< CES_CMDIF_PKT_OVERHEAD:
                    if CES_Pkt_Pos_Counter==CES_CMDIF_IND_LEN_MSB:
                        CES_Pkt_Len = CES_Pkt_Len #(rxch<<8)|CES_Pkt_Len
                    elif CES_Pkt_Pos_Counter==CES_CMDIF_IND_PKTTYPE:
                        #rxch_bytes
                        CES_Pkt_PktType = int(rxch,16) #int.from_bytes(rxch,'big')
                elif CES_Pkt_Pos_Counter >= CES_CMDIF_PKT_OVERHEAD and CES_Pkt_Pos_Counter < CES_CMDIF_PKT_OVERHEAD+CES_Pkt_Len+1:
                    
                    if CES_Pkt_PktType==2:
                        CES_Data_Counter+=1
                        CES_Pkt_Data_Counter[CES_Data_Counter] = rxch
                else: 
                    "All data received"
                    if rxch==CES_CMDIF_PKT_STOP:
                        #print("Pkt Stop")
                        print(CES_Pkt_Len)

                        CES_Pkt_ECG.clear()
                        CES_Pkt_ECG.append(int(CES_Pkt_Data_Counter[0], 16))
                        CES_Pkt_ECG.append(int(CES_Pkt_Data_Counter[1], 16))
                        CES_Pkt_ECG.append(int(CES_Pkt_Data_Counter[2], 16))
                        CES_Pkt_ECG.append(int(CES_Pkt_Data_Counter[3], 16))

                        ecg_int_val=int.from_bytes(CES_Pkt_ECG,'little',signed=True)

                        CES_Pkt_PPG_IR.clear()
                        CES_Pkt_PPG_IR.append(int(CES_Pkt_Data_Counter[9], 16))
                        CES_Pkt_PPG_IR.append(int(CES_Pkt_Data_Counter[10], 16))
                        CES_Pkt_PPG_IR.append(int(CES_Pkt_Data_Counter[11], 16))
                        CES_Pkt_PPG_IR.append(int(CES_Pkt_Data_Counter[12],16))

                        ppg_int_val=int.from_bytes(CES_Pkt_PPG_IR,'little',signed=True)
                        #print(ppg_int_val)
                        if LSL_ENABLED==True:
                            lslsample=[(ppg_int_val*0.00001), (ppg_int_val*0.00001)]
                            outlet.push_sample(lslsample)
                            
                        #print(" ")

                        #print(CES_Pkt_PPG_IR)
                        #bytes_ppg_ir = int(CES_Pkt_PPG_IR.encode('hex'),16)
                        #bytes_ppg_ir = bytes(CES_Pkt_PPG_IR)
                        #ppg_int_val = int.from_bytes(bytes_ppg_ir, byteorder='big', signed=True)
                        #print(ppg_int_val)    

                        ecs_rx_state=CESState_Init
                    else:
                        ecs_rx_state=CESState_Init
    

while True:
    #try:
        ser_bytes = ser.read()

        #rxch=ser_bytes.decode('base64')
        rxch=bytes.hex(ser_bytes)
        #print(ser_bytes)
        #print(rxch)

        #ecsProcessData(ser_bytes)
        #print(ecs_rx_state)
        if ecs_rx_state==CESState_Init:
            #print(rxch)
            if rxch==CES_CMDIF_PKT_START_1:
                #print("Pkt Start")
                ecs_rx_state=CESState_SOF1_Found
        elif ecs_rx_state==CESState_SOF1_Found:
                if rxch==CES_CMDIF_PKT_START_2:
                    ecs_rx_state=CESState_SOF2_Found
                else:
                    ecs_rx_state=CESState_Init
        elif ecs_rx_state==CESState_SOF2_Found:
                ecs_rx_state = CESState_PktLen_Found
                CES_Pkt_Len = int(rxch,16) #int.from_bytes(rxch,'big')
                #print(CES_Pkt_Len)
                CES_Pkt_Pos_Counter = CES_CMDIF_IND_LEN
                CES_Data_Counter = 0
        elif ecs_rx_state==CESState_PktLen_Found:
                #print("Pkt Len Found")
                CES_Pkt_Pos_Counter+=1
                #print("Pkt Pos:") 
                #print(CES_Pkt_Pos_Counter)
                if CES_Pkt_Pos_Counter< CES_CMDIF_PKT_OVERHEAD:
                    if CES_Pkt_Pos_Counter==CES_CMDIF_IND_LEN_MSB:
                        CES_Pkt_Len = CES_Pkt_Len #(rxch<<8)|CES_Pkt_Len
                    elif CES_Pkt_Pos_Counter==CES_CMDIF_IND_PKTTYPE:
                        #rxch_bytes
                        CES_Pkt_PktType = int(rxch,16) #int.from_bytes(rxch,'big')
                elif CES_Pkt_Pos_Counter >= CES_CMDIF_PKT_OVERHEAD and CES_Pkt_Pos_Counter < CES_CMDIF_PKT_OVERHEAD+CES_Pkt_Len+1:
                    
                    if CES_Pkt_PktType==2:
                        CES_Data_Counter+=1
                        CES_Pkt_Data_Counter[CES_Data_Counter] = rxch
                else: 
                    "All data received"
                    if rxch==CES_CMDIF_PKT_STOP:
                        #print("Pkt Stop")
                        print(CES_Pkt_Len)

                        CES_Pkt_ECG.clear()
                        CES_Pkt_ECG.append(int(CES_Pkt_Data_Counter[0], 16))
                        CES_Pkt_ECG.append(int(CES_Pkt_Data_Counter[1], 16))
                        CES_Pkt_ECG.append(int(CES_Pkt_Data_Counter[2], 16))
                        CES_Pkt_ECG.append(int(CES_Pkt_Data_Counter[3], 16))

                        ecg_int_val=int.from_bytes(CES_Pkt_ECG,'little',signed=True)

                        CES_Pkt_PPG_IR.clear()
                        CES_Pkt_PPG_IR.append(int(CES_Pkt_Data_Counter[9], 16))
                        CES_Pkt_PPG_IR.append(int(CES_Pkt_Data_Counter[10], 16))
                        CES_Pkt_PPG_IR.append(int(CES_Pkt_Data_Counter[11], 16))
                        CES_Pkt_PPG_IR.append(int(CES_Pkt_Data_Counter[12],16))

                        ppg_int_val=int.from_bytes(CES_Pkt_PPG_IR,'little',signed=True)
                        #print(ppg_int_val)
                        if LSL_ENABLED==True:
                            lslsample=[(ppg_int_val*0.00001), (ppg_int_val*0.00001)]
                            outlet.push_sample(lslsample)
                            
                        #print(" ")

                        #print(CES_Pkt_PPG_IR)
                        #bytes_ppg_ir = int(CES_Pkt_PPG_IR.encode('hex'),16)
                        #bytes_ppg_ir = bytes(CES_Pkt_PPG_IR)
                        #ppg_int_val = int.from_bytes(bytes_ppg_ir, byteorder='big', signed=True)
                        #print(ppg_int_val)    

                        ecs_rx_state=CESState_Init
                    else:
                        ecs_rx_state=CESState_Init
