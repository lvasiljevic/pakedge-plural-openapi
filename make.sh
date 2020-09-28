#!/bin/bash

generate_openapi() {
    #generate html
    ./node_modules/@openapitools/openapi-generator-cli/bin/openapi-generator generate -g html2 -i ${1} -o bin/
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

#check input argumennts
if [[ $# -le 1 ]] ; then
    echo 'Error - platform not defined!'
    echo 'Valid platform is [wr1]'
    echo 'start with ./make.sh <platform> <version>'
    echo 'eg. ./make.sh wr1 2'
    exit 1
fi
PLATFORM="${1,,}"
VERSION="${2:-all}"

#checkplatform
if [ "${PLATFORM}" != "wr1" ]; then
    echo 'Error - bad platform. Valid platforms are wr1!'
    exit 1
fi
HTML_DOC="bin/index_"${PLATFORM}_v${VERSION}".html"
YAML_FILE_V1=index_${PLATFORM}_v1.yaml
YAML_FILE_V2=index_${PLATFORM}_v2.yaml
HTML_FILE=bin/index.html

if [ "${VERSION}" == "1" ]; then
    #print 1 in yaml
    generate_openapi ${YAML_FILE_V1}
elif [ "${VERSION}" == "2" ]; then
    #print 2 in yaml
    generate_openapi ${YAML_FILE_V2}
fi


mv ${HTML_FILE} ${HTML_DOC}
#open documentation
firefox ${HTML_DOC}