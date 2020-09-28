#!/bin/bash

PLATFORM=$1
REPO=git@github.com:lvasiljevic/pakedge-plural-openapi.git
REPO_NAME=pakedge-plural-openapi

git clone --depth 1   --filter=blob:none   --no-checkout $REPO
cd $REPO_NAME
git checkout develop -- bin/ content/${PLATFORM}/ make.sh README index_${PLATFORM}_* make_platform.sh version node_modules/
./make.sh ${PLATFORM} 2