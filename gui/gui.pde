//////////////////////////////////////////////////////////////////////////////////////////
//
//   Raspberry Pi/ Desktop GUI for controlling the HealthyPi HAT 5
//
//   Copyright (c) 2022 ProtoCentral
//
//   Dependant libraries:
//     * ControlP5
//     * Grafica
//
//   This software is licensed under the MIT License(http://opensource.org/licenses/MIT). 
//   
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT 
//   NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
//   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
//   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
//   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
/////////////////////////////////////////////////////////////////////////////////////////

import processing.serial.*;                  // Serial Library
import grafica.*;

// Java Swing Package For prompting message
import java.awt.*;
import javax.swing.*;
import static javax.swing.JOptionPane.*;

// File Packages to record the data into a text file
import javax.swing.JFileChooser;
import java.io.FileWriter;
import java.io.BufferedWriter;

// Date Format
import java.util.*;
import java.text.DateFormat;
import java.text.SimpleDateFormat;

// General Java Package
import java.math.*;
import controlP5.*;

import java.io.IOException;

//import edu.ucsd.sccn.LSL;

ControlP5 cp5;

Textlabel lblHR;
Textlabel lblSPO2;
Textlabel lblRR;
Textlabel lblBP;
Textlabel lblTemp;
Textlabel lblMQTT;
Textlabel lblMQTTStatus;
Textlabel lblRecordStatus;
Textlabel lblLSLStatus;

Toggle tglRecord;

Accordion accordion;
PImage pcLogo;

/************** Packet Validation  **********************/
private static final int CESState_Init = 0;
private static final int CESState_SOF1_Found = 1;
private static final int CESState_SOF2_Found = 2;
private static final int CESState_PktLen_Found = 3;

/*CES CMD IF Packet Format*/
private static final int CES_CMDIF_PKT_START_1 = 0x0A;
private static final int CES_CMDIF_PKT_START_2 = 0xFA;
private static final int CES_CMDIF_PKT_STOP = 0x0B;

/*CES CMD IF Packet Indices*/
private static final int CES_CMDIF_IND_LEN = 2;
private static final int CES_CMDIF_IND_LEN_MSB = 3;
private static final int CES_CMDIF_IND_PKTTYPE = 4;
private static int CES_CMDIF_PKT_OVERHEAD = 5;

/************** Packet Related Variables **********************/

int ecs_rx_state = 0;                                        // To check the state of the packet
int CES_Pkt_Len;                                             // To store the Packet Length Deatils
int CES_Pkt_Pos_Counter, CES_Data_Counter;                   // Packet and data counter
int CES_Pkt_PktType;                                         // To store the Packet Type
char CES_Pkt_Data_Counter[] = new char[1000];                // Buffer to store the data from the packet
char CES_Pkt_ECG_Counter[] = new char[4];                    // Buffer to hold ECG data
char CES_Pkt_Resp_Counter[] = new char[4];                   // Respiration Buffer
char CES_Pkt_SpO2_Counter_RED[] = new char[4];               // Buffer for SpO2 RED
char CES_Pkt_SpO2_Counter_IR[] = new char[4];                // Buffer for SpO2 IR
int pSize = 600;                                            // Total Size of the buffer
int arrayIndex = 0;  // Increment Variable for the buffer
int arrayIndex1=0;
int arrayIndex2=0;
int arrayIndex3=0;
float time = 0;                                              // X axis increment variable

// Buffer for ecg,spo2,respiration,and average of thos values
float[] xdata = new float[pSize];
float[] ecgdata = new float[pSize];
float[] respdata = new float[pSize];
float[] bpmArray = new float[pSize];
float[] ecg_avg = new float[pSize];                          
float[] resp_avg = new float[pSize];
float[] spo2data = new float[pSize];
float[] spo2Array_IR = new float[pSize];
float[] spo2Array_RED = new float[pSize];
float[] rpmArray = new float[pSize];
float[] ppgArray = new float[pSize];

char respdataTag=0; 

/************** Graph Related Variables **********************/

double maxe, mine, maxr, minr, maxs, mins;             // To Calculate the Minimum and Maximum of the Buffer
double ecg, resp, ppg_ir, ppg_red, spo2, redAvg, irAvg, ecgAvg, resAvg;  // To store the current ecg value
double respirationVoltage=20;                          // To store the current respiration value
boolean startPlot = false;                             // Conditional Variable to start and stop the plot

GPlot plotPPG;
GPlot plotECG;
GPlot plotResp;

int step = 0;
int stepsPerCycle = 100;
int lastStepTime = 0;
boolean clockwise = true;
float scale = 5;

/************** File Related Variables **********************/

boolean logging = false;                                // Variable to check whether to record the data or not
FileWriter output;                                      // In-built writer class object to write the data to file
JFileChooser jFileChooser;                              // Helps to choose particular folder to save the file
Date date;                                              // Variables to record the date related values                              
BufferedWriter bufferedWriter;
DateFormat dateFormat;

/************** Port Related Variables **********************/

Serial port = null;                                     // Oject for communicating via serial port
String[] comList;                                       // Buffer that holds the serial ports that are paired to the laptop
char inString = '\0';                                   // To receive the bytes from the packet
String selectedPort;                                    // Holds the selected port number

/************** Logo Related Variables **********************/

PImage logo;
boolean gStatus;                                        // Boolean variable to save the grid visibility status

int nPoints1 = pSize;
int totalPlotsHeight=0;
int totalPlotsWidth=0;
int heightHeader=100;
int updateCounter=0;

boolean is_raspberrypi=false;

int global_hr;
int global_rr;
float global_temp;
int global_spo2;

int global_test=0;

boolean ECG_leadOff,spo2_leadOff;
boolean ShowWarning = true;
boolean ShowWarningSpo2=true;

String globalPortName="";

String strRecordStatus="Not Recording";


//LSL Related Variables
boolean lslEnabled=false;
String strLSLStatus="Disabled";

//LSL.StreamOutlet outlet;
//LSL.StreamOutlet outlet2;

/*public void enableLSL()
{
  lslEnabled=true;
  strLSLStatus="LSL Status: Enabled";
  lblLSLStatus.setText(strLSLStatus);
  lblLSLStatus.setColorValue(color(0,255,0));
}

public void disableLSL()
{
  lslEnabled=false;
  strLSLStatus="Disabled";
  lblLSLStatus.setText(strLSLStatus);
  lblLSLStatus.setColorValue(color(255,0,0));
}*/

public void setup() 
{
    println(System.getProperty("os.name"));
    println(System.getProperty("os.arch"));
    
    GPointsArray pointsPPG = new GPointsArray(nPoints1);
    GPointsArray pointsECG = new GPointsArray(nPoints1);
    GPointsArray pointsResp = new GPointsArray(nPoints1);
  
    size(1366, 768, JAVA2D);
    //fullScreen();
     
    heightHeader=100;
    println("Height:"+height);
    totalPlotsHeight=height-heightHeader;
    
    pcLogo = loadImage("protocentral.jpg");
    
    makeGUI();
    
    plotECG = new GPlot(this);
    plotECG.setPos(0,50);
    plotECG.setDim(width, (totalPlotsHeight/3)-10);
    plotECG.setBgColor(0);
    //plotECG.setBoxBgColor(0);
    plotECG.setLineColor(color(0, 255, 0));
    plotECG.setLineWidth(3);
    plotECG.setMar(35,25,10,50);
    
    //plotECG.getYAxis().setLineColor(color(255,255,255));
    //plotECG.getYAxis().setFontColor(color(255,255,255));
    
    //plotECG.setYLim(-2.00,+4.00);
    
    plotPPG = new GPlot(this);
    plotPPG.setPos(0,(totalPlotsHeight/3+60));
    plotPPG.setDim(width, (totalPlotsHeight/3)-10);
    plotPPG.setBgColor(0);
    plotPPG.setBoxBgColor(0);
    plotPPG.setLineColor(color(255, 255, 0));
    plotPPG.setLineWidth(3);
    plotPPG.setMar(0,0,0,0);
  
    plotResp = new GPlot(this);
    plotResp.setPos(0,(totalPlotsHeight/3+totalPlotsHeight/3+70));
    plotResp.setDim(width, (totalPlotsHeight/3)-10);
    plotResp.setBgColor(0);
    plotResp.setBoxBgColor(0);
    plotResp.setLineColor(color(0,0,255));
    plotResp.setLineWidth(3);
    plotResp.setMar(0,0,0,0);
  
    for (int i = 0; i < nPoints1; i++) 
    {
      pointsPPG.add(i,0);
      pointsECG.add(i,0);
      pointsResp.add(i,0); 
    }
  
    plotECG.setPoints(pointsECG);
    plotPPG.setPoints(pointsPPG);
    plotResp.setPoints(pointsPPG);
  
    for (int i=0; i<pSize; i++) 
    {
      time = time + 1;
      xdata[i]=time;
      ecgdata[i] = 0;
      respdata[i] = 0;
      ppgArray[i] = 0;
    }
    time = 0;
    
    delay(2000);
    if(System.getProperty("os.arch").contains("arm"))
    {
      startSerial("/dev/ttyAMA0",115200);
      checkForExternalStorage();
    }
    
    //enableLSL();
    
    /*if(lslEnabled)
    {
      LSL.StreamInfo info = new LSL.StreamInfo("HealthyPi","ECG,PPG Red, PPG IR",3,125,LSL.ChannelFormat.int32,"1234567");
      try {
        outlet = new LSL.StreamOutlet(info);
        //outlet2 = new LSL.StreamOut
      } catch (Exception e)
      {
      }
    }*/
}

public void draw() 
{
    background(0);
    fill(19,88,113);
    rect(0, 0, width, 55);
    image(pcLogo, 10, 10);
  
    GPointsArray pointsPPG = new GPointsArray(nPoints1);
    GPointsArray pointsECG = new GPointsArray(nPoints1);
    GPointsArray pointsResp = new GPointsArray(nPoints1);
  
    if (startPlot)                             
    {
      for(int i=0; i<nPoints1;i++)
      {    
        pointsECG.add(i,ecgdata[i]);
        pointsPPG.add(i,spo2data[i]); 
        pointsResp.add(i,respdata[i]);
        
      }
    } 
    
    plotECG.setPoints(pointsECG);
    plotPPG.setPoints(pointsPPG);
    plotResp.setPoints(pointsResp);
    
    plotECG.beginDraw();
    plotECG.drawBackground();
    plotECG.drawYAxis();
    plotECG.drawLines();
    plotECG.endDraw();
    
    plotPPG.beginDraw();
    plotPPG.drawBackground();
    plotPPG.drawLines();
    plotPPG.endDraw();
  
    plotResp.beginDraw();
    plotResp.drawBackground();
    plotResp.drawLines();
    plotResp.endDraw();
}

public void makeGUI()
{  
   cp5 = new ControlP5(this);
   
   cp5.addButton("Exit")
     //setValue(0)
     .setColorBackground(color(255,255,255))
     .setColorLabel(color(0))
     .setPosition(width-110,5)
     .setSize(90,40)
     .setFont(createFont("verdana",16));

    tglRecord = cp5.addToggle("record")
     .setPosition(width-225,5)
     //.setLabel("Record Data")
     .setLabelVisible(true)
     .setSize(90,20)
     .setFont(createFont("verdana",10))
     .setValue(false)
     .setColorBackground(color(255,255,255))
     .setColorLabel(color(255,255,255))
     .setMode(ControlP5.SWITCH);
                 
      if(!System.getProperty("os.arch").contains("arm"))
      {     
          cp5.addScrollableList("Select Serial port")
             .setPosition(300, 5)
             .setSize(150, 400)
             .setColorBackground(color(255,255,255))
             .setColorLabel(color(0))
             .setColorValueLabel(color(0))
             //.setColorForeground(color(0))
             .setFont(createFont("verdana",12))
             .setBarHeight(40)
             .close()
             .setItemHeight(40)
             .addItems(port.list())
             .setType(ScrollableList.DROPDOWN) // currently supported DROPDOWN and LIST
             .addCallback(new CallbackListener() 
             {
                public void controlEvent(CallbackEvent event) 
                {
                  if (event.getAction() == ControlP5.ACTION_RELEASED) 
                  {
                    globalPortName=event.getController().getLabel();
                    //startSerial(event.getController().getLabel(),115200);
                  }
                }
             } 
           );    
           
           cp5.addButton("Open")
             .setValue(0)
             .setColorBackground(color(255,255,255))
             .setColorLabel(color(0))           
             .setPosition(470,5)
             .setSize(80,40)
             .setFont(createFont("verdana",16));
        }
 
       lblHR = cp5.addTextlabel("lblHR")
      .setText("Heartrate: --- bpm")
      .setPosition(width-550,50)
      .setColorValue(color(255,255,255))
      .setFont(createFont("verdana",40));
      
      lblSPO2 = cp5.addTextlabel("lblSPO2")
      .setText("SpO2: --- %")
      .setPosition(width-550,(totalPlotsHeight/3+10))
      .setColorValue(color(255,255,255))
      .setFont(createFont("verdana",40));
 
      lblRR = cp5.addTextlabel("lblRR")
      .setText("Respiration: --- bpm")
      .setPosition(width-550,(totalPlotsHeight/3+totalPlotsHeight/3+10))
      .setColorValue(color(255,255,255))
      .setFont(createFont("verdana",40));
    
      lblTemp = cp5.addTextlabel("lblTemp")
      .setText("Body Temp: --- C")
      .setPosition(width-550,height-60)
      .setColorValue(color(255,255,255))
      .setFont(createFont("verdana",40));
      
     lblRecordStatus = cp5.addTextlabel("lblRecordStatus")
      .setText("Record status: " + strRecordStatus)
      .setPosition(10,height-25)
      .setColorValue(color(255,255,255))
      .setFont(createFont("verdana",14));
      
    lblLSLStatus = cp5.addTextlabel("lbLSLStatus")
      .setText("LSL Sender: " + strLSLStatus)
      .setPosition((width/2)-100,height-25)
      .setColorValue(color(255,255,255))
      .setFont(createFont("verdana",14));
          
    if(height<=480) //condition for Raspberry Pi 7" display
    {  
        lblHR.setFont(createFont("verdana",20));
        lblHR.setPosition(width-200,5+heightHeader);      
        
        lblSPO2.setFont(createFont("verdana",20));
        lblSPO2.setPosition(width-200,(totalPlotsHeight/3+heightHeader));
      
        lblTemp.setPosition((width/3)*2,height-25)
        .setFont(createFont("verdana",20));
        
        lblRR.setPosition(width-200,(totalPlotsHeight/3+totalPlotsHeight/3+10+heightHeader))
        .setFont(createFont("verdana",20));
       
    }
}



void record(boolean theFlag) {
  if(theFlag==true) {
   print("Recording started");
   RecordData();
  } else {
    if(logging==true)
    {
     print("Stop record");
     StopRecord();
    }
  }
  //println("a toggle event.");
}

public void Exit() 
{
  int dialogResult = JOptionPane.showConfirmDialog (null, "Would You Like to Close The Application?");
  if (dialogResult == JOptionPane.YES_OPTION) {
    try
    {
      //Runtime runtime = Runtime.getRuntime();
      //Process proc = runtime.exec("sudo shutdown -h now");
      System.exit(0);
    }
    catch(Exception e)
    {
      exit();
    }
  } else
  {
  }
}

public void Open()
{
  if(globalPortName!=null && globalPortName!="") startSerial(globalPortName,115200);
}

public void StopRecord()
{
  //Stop logging
  //if(logging==true)
  //{
    logging=false;
     setRecordStatus("Stopped Recording");
  
  //Close file
  try
  {
    bufferedWriter.close();
    output.close();
    
    println("Closed all files");
  }
  catch(Exception e)
  {
    println(e);
  }
  //}
}

String globalSelectedPath;

public void setRecordStatus(String RecordStatus)
{
    lblRecordStatus.setText("Status: "+ RecordStatus);
}

public void checkForExternalStorage()
{
  String storagePath;

    
      storagePath="/media/pi/";
      File[] usbFiles = listFiles(storagePath);
      //print(str(usbFiles.length));
      //print(usbFiles[0]);
      if(usbFiles!=null)
      {
      if(usbFiles.length<=0)
        {
          setRecordStatus("No storage device found. Not recording data");
          
        }
        else
        {
          RecordData();
        }   
      }
      else {
        setRecordStatus("No storage device found. Not recording data");
      }
        
}
public void RecordData()
{
    String storagePath;
  
    if(logging==false)
    {
      //Check if Raspberry Pi
      if(System.getProperty("os.arch").contains("arm"))
      {
        storagePath="/media/pi/";
        File[] usbFiles = listFiles(storagePath);
        print(str(usbFiles.length));
        //print(usbFiles[0]);
        if(usbFiles.length<=0)
          {
            //JFrame f = new JFrame();
            //JOptionPane.showMessageDialog(f,"No storage device found!","No device",JOptionPane.WARNING_MESSAGE);
            setRecordStatus("No storage device found. Not recording data");
          }
          else
          {
            storagePath=usbFiles[0].getPath();
            
            try
            {
              if(port!=null)
                port.stop();
              //USB storage present
              //jFileChooser = new JFileChooser(storagePath);
              long currentTime=System.currentTimeMillis();
              String filename = currentTime + ".csv";
              //jFileChooser.setSelectedFile(new File(filename));
              //jFileChooser.showSaveDialog(null);
              //String filePath = jFileChooser.getSelectedFile()+"";
              
              logging = true;
              date = new Date();
              //output = new FileWriter(jFileChooser.getSelectedFile(), true);
              output = new FileWriter(storagePath+"/"+filename, true);
              setRecordStatus("Recording to "+filename);
              bufferedWriter = new BufferedWriter(output);
              bufferedWriter.write("Log started at: " + date.toString()+"");
              bufferedWriter.newLine();
              //bufferedWriter.write("TimeStamp,ECG,SpO2,Respiration");
              bufferedWriter.write("Sampling rate for all signals: 125 Hz");
              bufferedWriter.newLine();
              bufferedWriter.write("Format: ECG, PPG, Respiration, Temperature, Heartrate, SpO2, Respiration Rate");
              bufferedWriter.newLine();
              startSerial("/dev/ttyAMA0",115200);
            }
            catch(Exception e)
            {
              println(e);
            }
        
          }
          
      } else 
      {
        //Not Raspberry Pi
        try
        {
          selectFolder("Select a folder to save log files", "folderSelected");
        }
        catch(Exception e)
        {
          println(e);
        }
      
      }  
    }
}

void folderSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    try
    {
      globalSelectedPath= selection.getAbsolutePath();
      println("User selected " + selection.getAbsolutePath());
      
      long currentTime=System.currentTimeMillis();
      String filename = currentTime + ".csv";
      
      if(port!=null)
        port.stop();
      
      logging = true;
      date = new Date();
      output = new FileWriter(globalSelectedPath+"/"+filename, true);
      setRecordStatus("Recording to "+ globalSelectedPath + "/" + filename);
      bufferedWriter = new BufferedWriter(output);
      bufferedWriter.write("Log started at: " + date.toString()+"");
      bufferedWriter.newLine();
      bufferedWriter.write("Sampling rate for all signals: 125 Hz");
      bufferedWriter.newLine();
      bufferedWriter.write("Format: ECG, PPG, Respiration, Temperature, Heartrate, SpO2, Respiration Rate");
      bufferedWriter.newLine();
      
      Open();
    }
    catch(Exception e)
    {
      println(e);
    }
  }
}

void startSerial(String startPortName, int baud)
{
  try
  {
      port = new Serial(this,startPortName, baud);
      port.clear();
      startPlot = true;
  }
  catch(Exception e)
  {

    showMessageDialog(null, "Port is invalid or busy", "Alert", ERROR_MESSAGE);
    //System.exit (0);
  }
}

void serialEvent (Serial blePort) 
{
  inString = blePort.readChar();
  ecsProcessData(inString);
}

// Send data to LSL
void sendLSL(float m_ecg, float m_ppg_red, float m_ppg_ir, float m_resp)
{
  float[] sample = new float[3];

  sample[0] = (float) m_ecg;
  sample[1] = (float) m_ppg_red;
  sample[2] = (float) m_ppg_ir;
  //sample[3] = (float) m_resp;

  try
  {
    //outlet.push_sample(sample);
  }
  catch(Exception e)
  {
    println(e);
  }
}

void ecsProcessData(char rxch)
{
  switch(ecs_rx_state)
  {
  case CESState_Init:
    if (rxch==CES_CMDIF_PKT_START_1)
      ecs_rx_state=CESState_SOF1_Found;
    break;

  case CESState_SOF1_Found:
    if (rxch==CES_CMDIF_PKT_START_2)
      ecs_rx_state=CESState_SOF2_Found;
    else
      ecs_rx_state=CESState_Init;                    //Invalid Packet, reset state to init
    break;

  case CESState_SOF2_Found:
    //    println("inside 3");
    ecs_rx_state = CESState_PktLen_Found;
    CES_Pkt_Len = (int) rxch;
    CES_Pkt_Pos_Counter = CES_CMDIF_IND_LEN;
    CES_Data_Counter = 0;
    break;

  case CESState_PktLen_Found:
    //    println("inside 4");
    CES_Pkt_Pos_Counter++;
    if (CES_Pkt_Pos_Counter < CES_CMDIF_PKT_OVERHEAD)  //Read Header
    {
      if (CES_Pkt_Pos_Counter==CES_CMDIF_IND_LEN_MSB)
        CES_Pkt_Len = (int) ((rxch<<8)|CES_Pkt_Len);
      else if (CES_Pkt_Pos_Counter==CES_CMDIF_IND_PKTTYPE)
        CES_Pkt_PktType = (int) rxch;
    } else if ( (CES_Pkt_Pos_Counter >= CES_CMDIF_PKT_OVERHEAD) && (CES_Pkt_Pos_Counter < CES_CMDIF_PKT_OVERHEAD+CES_Pkt_Len+1) )  //Read Data
    {
      if (CES_Pkt_PktType == 2)
      {
        CES_Pkt_Data_Counter[CES_Data_Counter++] = (char) (rxch);          // Buffer that assigns the data separated from the packet
      }
    } else  //All  and data received
    {
      if (rxch==CES_CMDIF_PKT_STOP)
      {     
        println(CES_Pkt_Len);
        CES_Pkt_ECG_Counter[0] = CES_Pkt_Data_Counter[0];
        CES_Pkt_ECG_Counter[1] = CES_Pkt_Data_Counter[1];
        CES_Pkt_ECG_Counter[2] = CES_Pkt_Data_Counter[2];
        CES_Pkt_ECG_Counter[3] = CES_Pkt_Data_Counter[3];

        CES_Pkt_Resp_Counter[0] = CES_Pkt_Data_Counter[4];
        CES_Pkt_Resp_Counter[1] = CES_Pkt_Data_Counter[5];
        CES_Pkt_Resp_Counter[2] = CES_Pkt_Data_Counter[6];
        CES_Pkt_Resp_Counter[3] = CES_Pkt_Data_Counter[7];
        
        respdataTag = CES_Pkt_Data_Counter[8];

        CES_Pkt_SpO2_Counter_IR[0] = CES_Pkt_Data_Counter[9];
        CES_Pkt_SpO2_Counter_IR[1] = CES_Pkt_Data_Counter[10];
        CES_Pkt_SpO2_Counter_IR[2] = CES_Pkt_Data_Counter[11];
        CES_Pkt_SpO2_Counter_IR[3] = CES_Pkt_Data_Counter[12];

        CES_Pkt_SpO2_Counter_RED[0] = CES_Pkt_Data_Counter[13];
        CES_Pkt_SpO2_Counter_RED[1] = CES_Pkt_Data_Counter[14];
        CES_Pkt_SpO2_Counter_RED[2] = CES_Pkt_Data_Counter[15];
        CES_Pkt_SpO2_Counter_RED[3] = CES_Pkt_Data_Counter[16];

        float Temp_Value = (float) (((int) CES_Pkt_Data_Counter[17]| CES_Pkt_Data_Counter[18]<<8)/100.00);                // Temperature
        
        int global_spo2= (int) (CES_Pkt_Data_Counter[19]);
        int global_HeartRate = (int) (CES_Pkt_Data_Counter[20]);
        int global_RespirationRate = (int) (CES_Pkt_Data_Counter[21]);
        
        int leadstatus =  CES_Pkt_Data_Counter[19];
      /*  leadstatus &= 0x01; 
        if(leadstatus== 0x01) ECG_leadOff = true;  
        else ECG_leadOff = false;*/
              
        leadstatus &= 0x02; 
        if(leadstatus == 0x02) spo2_leadOff = true;
        else spo2_leadOff = false;
            
        int data1 = CES_Pkt_ECG_Counter[0] | CES_Pkt_ECG_Counter[1]<<8 | CES_Pkt_ECG_Counter[2]<<16 | CES_Pkt_ECG_Counter[3]<<24; //reversePacket(CES_Pkt_ECG_Counter, CES_Pkt_ECG_Counter.length-1);
        ecg = (double) data1/1000; //ECG from board is in uV, convert here to mV

        int data2 = CES_Pkt_Resp_Counter[0] | CES_Pkt_Resp_Counter[1] <<8 | CES_Pkt_Resp_Counter[2] <<16 | CES_Pkt_Resp_Counter[3] <<24; //reversePacket(CES_Pkt_ECG_Counter, CES_Pkt_ECG_Counter.length-1);
        resp = (double) data2;
       
        int data3 = reversePacket(CES_Pkt_SpO2_Counter_IR, CES_Pkt_SpO2_Counter_IR.length-1);
        ppg_ir = (double) data3;

        int data4 = reversePacket(CES_Pkt_SpO2_Counter_RED, CES_Pkt_SpO2_Counter_RED.length-1);
        ppg_red = (double) data4;

        ecg_avg[arrayIndex1] = (float)ecg;

        spo2Array_IR[arrayIndex2] = (float)ppg_ir;
        spo2Array_RED[arrayIndex2] = (float)ppg_red;
        redAvg = averageValue(spo2Array_RED);
        irAvg = averageValue(spo2Array_IR);
        spo2 = (spo2Array_IR[arrayIndex2] - irAvg);
       
        resp_avg[arrayIndex3]= (float)resp;
      
        time = time+1;
        xdata[arrayIndex] = time;

        ecgdata[arrayIndex1] = (float)ecg;
        spo2data[arrayIndex2] = (float)spo2;
        ppgArray[arrayIndex2] = (float)spo2;
        
        arrayIndex1++;
        arrayIndex2++;
        
        if(lslEnabled == true)
        {
          sendLSL((float)ecg*(-0.001), (float)ppg_ir, (float)ppg_red, (float)resp);
        }
        
        if(respdataTag==0x00)
        {
          respdata[arrayIndex3]= (float)resp;
          arrayIndex3++;
          
        }
       
        if(ECG_leadOff == true)
        {
           if(ShowWarning == true)
           {
             lblHR.setColorValue(color(255,0,0));
             lblRR.setColorValue(color(255,0,0));
             lblHR.setText("LEAD ERROR");
             lblRR.setText("LEAD ERROR");
             ShowWarning = false;
           }
        }
        else 
        {
          if(ShowWarning == false)
          {
             lblHR.setColorValue(color(255,255,255));
             lblRR.setColorValue(color(255,255,255));
             ShowWarning = true;
          }
          lblRR.setText("Respiration: " + global_RespirationRate+ " rpm");
          lblHR.setText("Heart Rate: " + global_HeartRate + " bpm");          
        }
        
        if(spo2_leadOff == true)
        {
          if(ShowWarningSpo2 == true)
           {
             lblSPO2.setColorValue(color(255,0,0));
             lblSPO2.setText("SpO2 Probe Error");
             ShowWarningSpo2 = false;
           }
        }
        else 
        {
           if(ShowWarningSpo2 == false)
            {
               lblSPO2.setColorValue(color(255,255,255));
               ShowWarningSpo2 = true;
            }
           lblSPO2.setText("SpO2: " + global_spo2 + "%");
        }
       
        
        updateCounter++;

        if(updateCounter==100)
        {
          if (startPlot)
          {
            //global_temp=Temp_Value;
            //Temp_Value=37.2;
            lblTemp.setText("Temperature: "+Temp_Value+" F");
            
          }
          updateCounter=0;
        }
        
        if (arrayIndex1 == pSize)
        {  
          arrayIndex1 = 0;
        }  
        
         if (arrayIndex2 == pSize)
        {  
          arrayIndex2 = 0;
        } 
        
         if (arrayIndex3 == pSize)
        {  
          arrayIndex3 = 0;
        } 

        if (logging == true)
        {
          try 
          {
            //date = new Date();
            //dateFormat = new SimpleDateFormat("HH:mm:ss");
            bufferedWriter.write(ecg+","+ppg_red+","+resp+","+Temp_Value+","+global_HeartRate+","+global_spo2+","+global_RespirationRate);
            bufferedWriter.newLine();
          }
          catch(IOException e) 
          {
            println("It broke!!!");
            e.printStackTrace();
          }
        }
          ecs_rx_state=CESState_Init;
      } 
      else
      {
        ecs_rx_state=CESState_Init;
      }
    }
    break;

  default:
    break;
  }
}


/*********************************************** Recursive Function To Reverse The data *********************************************************/

public int reversePacket(char DataRcvPacket[], int n)
{
  if (n == 0)
    return (int) DataRcvPacket[n]<<(n*8);
  else
    return (DataRcvPacket[n]<<(n*8))| reversePacket(DataRcvPacket, n-1);
}

/*************** Function to Calculate Average *********************/
double averageValue(float dataArray[])
{

  float total = 0;
  for (int i=0; i<dataArray.length; i++)
  {
    total = total + dataArray[i];
  }
  return total/dataArray.length;
}
