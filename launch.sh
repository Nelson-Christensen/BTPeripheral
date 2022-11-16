#! /bin/bash
export PATH=/usr/local/bin:$PATH
export PATH=$PATH:/bin

curl www.creekside.se/download/mk3/version.json --output ./version_server.json

if cmp ./version.json ./version_server.json | grep "differ"; then
    echo "New version available"
    curl www.creekside.se/download/mk3/BTPeripheral.zip --output ./BTPeripheral.zip
    echo "Remote old files"
    rm -r ./BTPeripheral
    echo "Unpack new files"
    unzip -q ./BTPeripheral.zip
    echo "Remove zip file"
    rm ./BTPeripheral.zip
    echo "Update Version"
    cp ./version_server.json ./version.json
else
    echo "Up to date"
fi

cd ./BTPeripheral

echo waiting 1s before attempting to start
sleep 1

swift build
sleep 3
swift run
