#!/bin/bash

PLATFORM=$1
REPO=<repo>
cd ..
git clone --depth 1   --filter=blob:none   --no-checkout $REPO
cd $REPO
git checkout develop -- bin/ content/${PLATFORM}/ make.sh README index.yaml make_platform.sh version
./make.sh ${PLATFORM}