#!/bin/bash


#check input argumennts
if [[ $# -eq 0 ]] ; then
    echo 'Error - platform not defined!'
    echo 'Valid platform is wr1'
    exit 1
fi
PLATFORM="${1,,}"

#checkplatform
if [ "${PLATFORM}" != "wr1" ]; then
    echo 'Error - bad platform. Valid platforms are wr1!'
    exit 1
fi
HTML_DOC="bin/index_"${PLATFORM}".html"
YAML_FILE=index.yaml
HTML_FILE=bin/index.html
#generate html
./node_modules/@openapitools/openapi-generator-cli/bin/openapi-generator generate -g html2 -i ${YAML_FILE} -o bin/
if [ $? -ne 0 ]; then
    exit 1
fi
mv ${HTML_FILE} ${HTML_DOC}
#open documentation
firefox ${HTML_DOC}