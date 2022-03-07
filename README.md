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
cd ./BTPeripheral
swift main.swift
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

Where you replace the cd path to the path to your `launch.sh` file.

4. Save the automation to the same folder as the launch.sh file 5. Double click the automation to run it to make sure it has all the correct permissions (Terminal needs to be closed when you run it)

### Run Automation on startup

#### Auto Launch App

Go to `System Preferences -> Users & Groups -> Login Items` and add your new Automator app.

#### Auto Sign in

Go to `System Preferences -> Users & Groups -> Login Options` and change automatic login to your user account
