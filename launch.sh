#! /bin/bash
export PATH=/usr/local/bin:$PATH
export PATH=$PATH:/bin

HTTP_URL="www.creekside.se/download/mk3/"
VERSION_URL="version.json"
VERSION_OUTPUT="--output ./version_server.json"
APP_URL="BTPeripheral.zip"
APP_OUTPUT="--output ./BTPeripheral.zip"
CURL_CMD="curl -w %{http_code}"
CURL_MAX_TIMEOUT="-m 100"

CURL_OUTPUT=`${CURL_CMD} ${CURL_MAX_CONNECTION_TIMEOUT} ${HTTP_URL}${VERSION_URL} ${VERSION_OUTPUT}`
if [[ ${CURL_OUTPUT} -ne 200 ]]; then
    echo "Curl connection failed with return code - ${CURL_OUTPUT}"
else
    echo "Curl connection success"
    if cmp ./version.json ./version_server.json | grep "differ"; then
        echo "New version available"
        CURL_OUTPUT=`${CURL_CMD} ${CURL_MAX_CONNECTION_TIMEOUT} ${HTTP_URL}${APP_URL} ${APP_OUTPUT}`
        if [[ ${CURL_OUTPUT} -ne 200 ]]; then
            echo "Curl connection failed with return code - ${CURL_OUTPUT}"
        else
            echo "Remove old files"
            rm -r ./mk3_macmini
            echo "Unpack new files"
            unzip -q ./mk3_macmini.zip
            echo "Remove zip file"
            rm ./mk3_macmini.zip
            echo "Update Version"
            #cp ./version_server.json ./version.json
        fi
    else
        echo "Up to date"
    fi
fi

cd ./mk3_macmini

echo waiting 1s before attempting to start
sleep 1

swift build
sleep 3
swift run
