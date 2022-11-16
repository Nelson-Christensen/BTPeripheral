#! /bin/bash
export PATH=/usr/local/bin:$PATH
export PATH=$PATH:/bin

HTTP_URL="www.creekside.se/download/mk3/"
VERSION_URL="version.json"
VERSION_OUTPUT="--output ./version_server.json"
MD5_URL="md5sum.md5"
MD5_OUTPUT="--output ./md5sum_server.md5"
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
            md5 -q ./BTPeripheral.zip > ./md5sum.md5
            CURL_OUTPUT=`${CURL_CMD} ${CURL_MAX_CONNECTION_TIMEOUT} ${HTTP_URL}${MD5_URL} ${MD5_OUTPUT}`
            if [[ ${CURL_OUTPUT} -ne 200 ]]; then
                echo "Curl connection failed with return code - ${CURL_OUTPUT}"
            else
                if cmp ./md5sum.md5 ./md5sum_server.md5 | grep "differ"; then
                    echo "md5sum missmatch"
                else
                    echo "md5sum correct"
                    echo "Remove old files"
                    rm -rf ./BTPeripheral
                    echo "Unpack new files"
                    unzip -q ./BTPeripheral.zip
                    echo "Remove zip file"
                    rm ./BTPeripheral.zip
                    echo "Update Version"
                    #cp ./version_server.json ./version.json
                fi
            fi
        fi
    else
        echo "Up to date"
    fi
fi

cd ./BTPeripheral

echo waiting 1s before attempting to start
sleep 1

swift build
sleep 3
swift run
