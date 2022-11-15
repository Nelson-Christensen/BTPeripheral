#! /bin/bash
export PATH=/usr/local/bin:$PATH
export PATH=$PATH:/bin

echo waiting 3s before attempting to pull
sleep 3
git config pull.rebase false
git pull

echo waiting 1s before attempting to start
sleep 1

swift build
sleep 3
swift run
