#BTPeripheral

## Make Application Launch on Startup

### Creating the bash script

Create a file called `launch.sh` in the parent directory and add the following content:

```
#! /bin/bash
export PATH=/usr/local/bin:$PATH
export PATH=$PATH:/bin

cd ./BTPeripheral
echo waiting 3s before attempting to pull
sleep 3
git config pull.rebase false
git pull

echo waiting 1s before attempting to start
sleep 1

swift build
sleep 3
swift run

```

This file is responsible for git pulling to get the latest version of this repo and then starting up the swift application.

### Create Automation

1. Open up the `Automator` app
2. Create new Application Automation (File -> New -> Application)
3. Add a `Run applescript` action and paste the following content:

```
on run {input, parameters}
	
	tell application "Terminal"
		activate
		do script "cd ~/sites/quixel" in window 1

		-- we use chmod to make launch.sh an executable
		do script "chmod +x ./launch.sh && ./launch.sh" in window 1
	end tell

	return input
end run
```
To run with sony camera install "imaging edge desktop" then change the Automator script to
```
on run {input, parameters}		set cameraConnected to 0	set sayonce to 0	repeat while cameraConnected = 0				set USB_Drives to {}		set USB to paragraphs of (do shell script "system_profiler SPUSBDataType -detailLevel basic")		repeat with i from 1 to (count of USB)						if item i of USB contains "ILCE-7RM3" then				set cameraConnected to 1			else				if sayonce is 0 then					say "Connect camera"				end if				set sayonce to 1				delay 0.1			end if		end repeat				delay 1	end repeat	delay 1			tell application "Finder"		activate		if folder "master" of folder "folders" of (path to documents folder) exists then			"ok"		else			make new folder at folder "folders" of (path to documents folder) with properties {name:"namnlös mapp"}			set name of folder "namnlös mapp" of folder "folders" of (path to documents folder) to "master"		end if	end tell	delay 1	tell application "Remote" to activate	delay 5		tell application "System Events" to key code 36 #return, to activate the camera selected. This have had som issues with the script. 								The key sending is not reliable.	delay 5			tell application "Terminal"		activate		do script "cd ~/Documents/Github/" in window 1				-- we use chmod to make launch.sh an executable		do script "chmod +x ./launch.sh && ./launch.sh" in window 1	end tell		return inputend run
```

Where you replace the cd path to the path to your `launch.sh` file.

4. Save the automation to the same folder as the launch.sh file 5. Double click the automation to run it to make sure it has all the correct permissions (Terminal needs to be closed when you run it)

### Run Automation on startup

#### Auto Launch App

Go to `System Preferences -> Users & Groups -> Login Items` and add your new Automator app.

#### Auto Sign in

Go to `System Preferences -> Users & Groups -> Login Options` and change automatic login to your user account

#### test with arduino 

String inputString = "";         // a String to hold incoming data
bool stringA = false;  // whether the string is complete
bool stringB = false; 
bool stringC = false; 

void setup() {
  // initialize serial:
   Serial.begin(115200);
 Serial.setTimeout(1);
    pinMode(12, OUTPUT);

  // reserve 200 bytes for the inputString:
  inputString.reserve(20);
}

void loop() {
  // print the string when a newline arrives:
  if (stringA) {

      digitalWrite(12, HIGH);   // turn the LED on (HIGH is the voltage level)
      delay(100);
      digitalWrite(12, LOW);
    
    // clear the string:
    stringA = false;
  }
  if (stringB) {

      digitalWrite(12, HIGH);   // turn the LED on (HIGH is the voltage level)
      delay(1000);
      digitalWrite(12, LOW);
    
    // clear the string:
    stringB = false;
  }
    if (stringC) {

      digitalWrite(12, HIGH);   // turn the LED on (HIGH is the voltage level)
      delay(500);
      digitalWrite(12, LOW);
      delay(1000);
      digitalWrite(12, HIGH);   // turn the LED on (HIGH is the voltage level)
      delay(500);
      digitalWrite(12, LOW);
    
    // clear the string:
    stringC = false;
  }
}

/*
  SerialEvent occurs whenever a new data comes in the hardware serial RX. This
  routine is run between each time loop() runs, so using delay inside loop can
  delay response. Multiple bytes of data may be available.
*/
void serialEvent() {
  while (Serial.available()) {
    // get the new byte:
    char inChar = (char)Serial.read();
    // add it to the inputString:
    inputString += inChar;

    
    // if the incoming character is a newline, set a flag so the main loop can
    // do something about it:
    if (inChar == 'A') {
      stringA = true;
    }
    if (inChar == 'B') {
      stringB = true;
    }
    if (inChar == 'C') {
      stringC = true;
    }
  }
}
