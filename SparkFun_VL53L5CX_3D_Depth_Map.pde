import processing.serial.*;
import g4p_controls.*;
import controlP5.*;
import static javax.swing.JOptionPane.*;
import java.awt.*;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import javax.swing.JFileChooser;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.FileOutputStream;
import java.time.format.DateTimeFormatter;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.io.PrintWriter;

ControlP5 cp5;
Graph g1;
int time = 0;

boolean portSelected = false;
String selectedPort;
String[] comList;
int arraySize = 200;
int arrayIndex = 0;
String msg = "Click Connect Button To Proceed";
boolean paused;
boolean serialSet;
float mmValue[] = new float[arraySize];
float XValues[] = new float[arraySize];

//get date and time for file name
DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy_MM_dd_HHmmss");
LocalDateTime now = LocalDateTime.now();
BufferedWriter output = null;
String startTimeFormat = dtf.format(now);
File outputFile = new File("/users/morganchu/desktop/Jul_5_MultiZone_Accuracy_Testing", startTimeFormat + "_TOF.csv");


// Serial Port Variables
Serial port; // Initialize Serial object
String buff = ""; // Create a serial buffer
int[] depths = new int[64]; // Create a list to parse serial into 

float t = 0;
Textlabel value;
long startTime = System.nanoTime();

void setup(){
  
  size(1760, 1080);
  surface.setResizable(true);
  createGUI();
  customGUI();
  g1 = new Graph();
  g1.GraphAxis(100, 50, width-200, height-100);
  strokeWeight(4);  // Thicker
  line(20, 40, 80, 40);
  strokeWeight(4);
  g1.GraphColor = color(0, 255, 0);
  //g1.GrapthC

  setChartSettings();
  for (int i=0; i<arraySize; i++)
  {
    t = t + 1;
    XValues[i]= t;
    mmValue[i] = 0;
  }
  t = 0;
  cp5 = new ControlP5(this);
  value = cp5.addTextlabel("label")
    .setText("0 mm")
    .setPosition(width-310, 100)
    .setColorValue(0xffffff00)
    .setFont(createFont("Arial Bold", 45))
    ;
  println(arraySize);
  setChartSettings();
   
  // Fill our list with 0s to avoid a null pointer exception
  // in case the sensor data is not immediately available
  for(int idx = 0; idx < 64; idx++){
    depths[idx] = 0; 
  }
}


void draw()
{
  background(0);
  while (portSelected == true && serialSet == false)
  {
    startSerial();
  }
  g1.DrawAxis();
  g1.LineGraph(XValues, mmValue);
}

void startSerial()
{
  try
  {
    port = new Serial(this, selectedPort, 115200);
    port.clear();
    port.bufferUntil(10);
    serialSet = true;
    msgBox.setText("Port Connected");
  }
  catch(Exception e)
  {
    msgBox.setText("Port Connection Failed");
    showMessageDialog(null, "Port is busy", "Alert", ERROR_MESSAGE);
    portSelected = false;
    portList.setEnabled(true);
    portList.setItems(comList, 0);
  }
}

int datalow = 0, datamed, datahigh;
// Handle incoming serial data
void serialEvent(Serial port){ 
    buff = (port.readString()); // read the whole line //<>//
    buff = buff.substring(0, buff.length()-1); // remove the Carriage Return
    if (buff != "") {
      depths = int(split(buff, ',')); // split at commas into our array
    }
    processdata(depths);
}

int[] prevData = new int[10];
int prevIndex = 0;
int count = 0;
int total = 0;
int avg = 0;
int val = 0;
float increment = 0.0;
void processdata(int[] depths){
    Arrays.sort(depths);
    for(int i = 0; i < 63; i++){
      if(depths[i] > 10 && datalow == 0){
        datalow = depths[i];
      }
    }
 
    prevData[prevIndex] = datalow; //<>//
    prevIndex++;
    count++;
    increment++;
    
    if(prevIndex == 9){
      prevIndex = 0;
    }
    
    if(count > 9){
      for(int i : prevData){ //<>//
        total += i;
      }
      avg = total / 10;
      total = 0;
      mmValue[arrayIndex] = avg;
      try {
            PrintWriter output = new PrintWriter(new BufferedWriter(new FileWriter(outputFile, true)));
            output.write(String.valueOf(increment/15) + "," + String.valueOf(avg) + "\n");
            output.close();
      }
       catch(IOException e) {
            e.printStackTrace();
      }
      XValues[arrayIndex] = t;
      val = avg;
    }
    else{
      mmValue[arrayIndex] = datalow;
      XValues[arrayIndex] = t;
      val = datalow;
    }
    
    t = t+1;
    arrayIndex++;
    value.setText(String.valueOf(val) + "mm");
  
    if (arrayIndex == arraySize)
        {
          //try {
          //  BufferedWriter output = new BufferedWriter(new FileWriter(outputFile));
          //  for(float f : mmValue){
          //    output.write(String.valueOf(f) + "\n");
          //  }
          //  output.close();
          //}
          //catch(IOException e) {
          //  e.printStackTrace();
          //}
          arrayIndex = 0;
          t = 0;
          //  println("done");
        }
    
    datalow = 0;
}

public void customGUI() {
  comList = port.list();
  String comList1[] = new String[comList.length+1];
  comList1[0] = "SELECT THE PORT";
  for (int i = 1; i <= comList.length; i++)
  {
    comList1[i] = comList[i-1];
  }
  comList=comList1;
  portList.setItems(comList1, 0);
  msgBox.setFont(new Font("Arial Bold", Font.PLAIN, 25));
  msgBox.setLocalColor(2, color(0xffffff00));
}

void setChartSettings() {
  g1.xDiv=10;
  g1.xMax=arraySize;
  g1.xMin=0;
  g1.yMax=300;
  g1.yMin = 0;
  g1.yDiv=20;
}
