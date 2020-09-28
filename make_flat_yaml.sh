#!/bin/bash

PLATFORM=$1
VERSION=$2
FILE_NAME=index_${PLATFORM}_v${VERSION}.yaml
FLAT_YAML=flat_${PLATFORM}_v${VERSION}.yaml

node_modules/@apidevtools/swagger-cli/bin/swagger-cli.js bundle ${FILE_NAME} > ./bin/${FLAT_YAML}