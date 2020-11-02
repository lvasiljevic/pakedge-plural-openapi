#!/bin/bash

#check input argumennts
if [[ $# -lt 2 ]] ; then
    echo 'Error - platform and apiv[n].lua file not defined!'
    exit 1
fi

PLATFORM=${1}
AVAILABLE_API=${2}

METHOD_LIST="GET POST PUT DELETE"

declare -A METHODS_YAML
METHODS_YAML=(
	["GET"]="get:"
	["POST"]="post:"
	["DELETE"]="delete:"
	["PUT"]="put:"
)

get_api(){

	for METHOD in ${METHOD_LIST}; do
		ENDPOINTS_LIST=$(sed -nr '
		/'${METHOD}' = / {
		    :ending
		    /\},|\}\}$/! {
		        N   
		        b ending 
		    }
		    s/'${METHOD}' = (\{)(.*)(\}\,|\}\})/\2/p
		}
		' ${AVAILABLE_API})

		if [ ! -z "${ENDPOINTS_LIST}" ]; then
			ENDPOINTS=$(echo "${ENDPOINTS_LIST}" | grep -o -P '(?<=(\[")).*(?="\])')
			for ENDPOINT in ${ENDPOINTS}; do
				process_api ${METHOD} ${ENDPOINT}
			done
		fi
	done
}

process_api(){
	METHOD=${1}
	IFS='/' read -r -a ENDPOINT_SEG <<< ${2}

	ENDPOINT_YAML=""
	ENDPOINT_MATCH_YAML=""
	API_FILE=""
	ID_PARAMETER=false

	if [[ ${#ENDPOINT_SEG[@]} -lt 4 ]]; then
		SHORT_ENDPOINT=true
	else
		SHORT_ENDPOINT=false
	fi

	for INDEX in ${!ENDPOINT_SEG[@]}; do
		if [[ ${INDEX} -gt 0 ]]; then

			if [[ ${INDEX} -eq 1 ]]; then
				API_VERSION=${ENDPOINT_SEG[INDEX]}
			else
				if [[ ${ENDPOINT_SEG[INDEX]} == ":"* ]]; then
					TMP=$(echo ${ENDPOINT_SEG[INDEX]}| cut -d ':' -f2)
					API_FILE_SEG=${ENDPOINT_SEG[INDEX - 1]::-1}${TMP}
					ENDPOINT_SEG[INDEX]='{'${API_FILE_SEG}'}'
					ID_PARAMETER=true
					ID_PARAMETER_NAME=${API_FILE_SEG}
				else
					API_FILE_SEG=${ENDPOINT_SEG[INDEX]}
				fi
				ENDPOINT_YAML=${ENDPOINT_YAML}/${ENDPOINT_SEG[INDEX]}
				ENDPOINT_MATCH_YAML=${ENDPOINT_MATCH_YAML}"\/"${ENDPOINT_SEG[INDEX]}
			fi

			if [[ ${INDEX} -eq 3 ]] ; then
				API_FILE=${API_FILE_SEG}
			fi

			if [[ ${INDEX} -gt 3 ]] ; then
				API_FILE=${API_FILE}-${API_FILE_SEG}
			fi

			if [[ ${INDEX} -eq 2 ]]; then
				API_FOLDER=${ENDPOINT_SEG[INDEX]}

				if [ "${SHORT_ENDPOINT}" = true ]; then
					API_FILE=${ENDPOINT_SEG[INDEX]}
				fi
			fi
		fi
	done
	if [ -f "content/common/${API_VERSION}/paths/common_index.yaml" ]; then
		COMMON_ENDPINT_EXISTS=$(cat "content/common/${API_VERSION}/paths/common_index.yaml" | grep -F -- ${ENDPOINT_YAML}:)
	fi
	if [ -z "${COMMON_ENDPINT_EXISTS}" ]; then
		gen_tamplate_files ${ENDPOINT_YAML} ${API_VERSION} ${METHOD} ${API_FOLDER} ${API_FILE} ${ID_PARAMETER} ${ENDPOINT_MATCH_YAML} ${ID_PARAMETER_NAME}
	fi
}

gen_tamplate_files(){
	ENDPOINT_YAML=${1}
	API_VERSION=${2}
	METHOD=${3}
	API_FOLDER=${4}
	API_FILE=${5}
	ID_PARAMETER=${6}
	ENDPOINT_MATCH_YAML=${7}
	ID_PARAMETER_NAME=${8}

	GENERATE_TAMPLATE=false

	FOLDER_PATHS="content/${PLATFORM}/${API_VERSION}/paths/${API_FOLDER}"
	mkdir -p "${FOLDER_PATHS}"

	INDEX_PATHS_YAML="content/${PLATFORM}/${API_VERSION}/paths/${PLATFORM}_index.yaml"
	if [ ! -f "${INDEX_PATHS_YAML}" ]; then
		touch "${INDEX_PATHS_YAML}"
	fi

	ENDPOINT_EXISTS=$(cat ${INDEX_PATHS_YAML} | grep -F ${ENDPOINT_YAML}:)
	if [ ! -z "${ENDPOINT_EXISTS}" ]; then
		ENDPOINT_EXISTS=$(cat ${INDEX_PATHS_YAML} | grep -F ./${API_FOLDER}/${API_FILE}-${METHOD}.yaml)
		if [ -z "${ENDPOINT_EXISTS}" ]; then
			TMP=${ENDPOINT_MATCH_YAML}:
			sed "/^${TMP}$/r"<(
			    echo "  ${METHODS_YAML[${METHOD}]}"
			    echo "    tags:"
			    echo "      - ${API_FOLDER}"
			    echo '    $ref: "./'${API_FOLDER}'/'${API_FILE}'-'${METHOD}'.yaml"'
			) -i -- ${INDEX_PATHS_YAML}
			GENERATE_TAMPLATE=true
		fi
	else
			echo "${ENDPOINT_YAML}:" 							>> ${INDEX_PATHS_YAML}
		    echo "  ${METHODS_YAML[${METHOD}]}" 	>> ${INDEX_PATHS_YAML}
		    echo "    tags:" 						>> ${INDEX_PATHS_YAML}
		    echo "      - ${API_FOLDER}"			>> ${INDEX_PATHS_YAML}
		    echo '    $ref: "./'${API_FOLDER}'/'${API_FILE}'-'${METHOD}'.yaml"' >> ${INDEX_PATHS_YAML}
		    GENERATE_TAMPLATE=true
	fi

	if [ "${GENERATE_TAMPLATE}" = true ]; then

		echo "New endpoint detected: ${ENDPOINT_YAML}"

		FOLDER_REQUEST="content/${PLATFORM}/${API_VERSION}/request/${API_FOLDER}"
		FOLDER_RESPONSE="content/${PLATFORM}/${API_VERSION}/response/${API_FOLDER}"
		FOLDER_SCHEMAS="content/${PLATFORM}/${API_VERSION}/schemas/${API_FOLDER}"
		FOLDER_PARAMETERS="content/${PLATFORM}/${API_VERSION}/parameters/path"
		FOLDER_HEADERS="content/${PLATFORM}/${API_VERSION}/headers"
		FOLDER_ROUTERS="routers/${PLATFORM}"

		OPERATION_ID=${API_FILE}-${METHOD}
		API_FILE_BASE=${API_FILE}-${METHOD}.yaml
		API_FILE_200=${API_FILE}-200-${METHOD}.yaml
		API_FILE_400=${API_FILE}-400-${METHOD}.yaml
		API_FILE_PARAMETER=${ID_PARAMETER_NAME}.yaml
		API_FILE_ROUTER=${PLATFORM}_${API_VERSION}.yaml
		MERGE_FILE_ROUTER=${PLATFORM}_${API_VERSION}.txt

		mkdir -p "${FOLDER_REQUEST}"
		mkdir -p "${FOLDER_RESPONSE}"
		mkdir -p "${FOLDER_SCHEMAS}"
		mkdir -p "${FOLDER_PARAMETERS}"
		mkdir -p "${FOLDER_ROUTERS}"

		VERSION=$(echo ${API_VERSION}| cut -d 'v' -f 2)

		# Make sure we have templates if nothing new is defined
		PREVIOUS_VERSION=$((VERSION-1)) #Works only if we don't skip versions
		if [ ! -d "templates/${API_VERSION}" ]; then
			cp -rf templates/v${PREVIOUS_VERSION} templates/${API_VERSION}
		fi

		# Generate main router file
		if [ ! -f "${FOLDER_ROUTERS}/${API_FILE_ROUTER}" ]; then
			cp -rf "templates/${API_VERSION}/routers/template-1.yaml" "${FOLDER_ROUTERS}/${API_FILE_ROUTER}"

			sed "/^paths:$/r"<(
			    echo '  $ref: "./'${INDEX_PATHS_YAML}'"'
			) -i -- ${FOLDER_ROUTERS}/${API_FILE_ROUTER}

			sed "/^components:$/r"<(
				echo "  schemas:"
			    echo '    $ref: "./content/'${PLATFORM}'/'${API_VERSION}'/schemas/'${PLATFORM}'_index.yaml"'
			    echo "  responses:"
			    echo '    $ref: "./content/'${PLATFORM}'/'${API_VERSION}'/response/'${PLATFORM}'_index.yaml"'
			) -i -- ${FOLDER_ROUTERS}/${API_FILE_ROUTER}

			sed -i "s^url: https://localhost:3001/api/.*^url: https://localhost:3001/api/${API_VERSION}^" ${FOLDER_ROUTERS}/${API_FILE_ROUTER}
			sed -i 's^version: ###^version: "'${VERSION}'"^' ${FOLDER_ROUTERS}/${API_FILE_ROUTER}
		fi

		# Generate list of files to merge
		if [ ! -f "${FOLDER_ROUTERS}/${MERGE_FILE_ROUTER}" ]; then
			if [ -d "content/common/${API_VERSION}" ]; then
				echo "${PLATFORM} common" > "${FOLDER_ROUTERS}/${MERGE_FILE_ROUTER}"
			else
				echo "${PLATFORM}" > "${FOLDER_ROUTERS}/${MERGE_FILE_ROUTER}"
			fi
		fi

		# Add tags in main router file
		TAGS_EXISTS=$(cat ${FOLDER_ROUTERS}/${API_FILE_ROUTER} | grep -F -- "- name: ${API_FOLDER}")
		if [ -z "${TAGS_EXISTS}" ]; then
			sed "/^tags:$/r"<(
			    echo "  - name: ${API_FOLDER}"
			    echo "    description: API for ${API_FOLDER}"
			) -i -- ${FOLDER_ROUTERS}/${API_FILE_ROUTER}
		fi

		# Add generic response messagges
		if [ ! -d "content/${PLATFORM}/${API_VERSION}/response/generic" ]; then
			cp -rf templates/${API_VERSION}/response/generic content/${PLATFORM}/${API_VERSION}/response/generic
		fi

		# Add generic schemas
		if [ ! -d "content/${PLATFORM}/${API_VERSION}/schemas/generic" ]; then
			cp -rf templates/${API_VERSION}/schemas/generic content/${PLATFORM}/${API_VERSION}/schemas/generic
		fi

		# Add generic headers
		if [ ! -d "${FOLDER_HEADERS}" ]; then
			cp -rf templates/${API_VERSION}/headers "${FOLDER_HEADERS}"
		else
			cp -rf templates/${API_VERSION}/headers/* "${FOLDER_HEADERS}"
		fi

		if [ "${METHOD}" = "GET" ]; then
			if [ ! -f "${FOLDER_PATHS}/${API_FILE_BASE}" ]; then
				cp -rf "templates/${API_VERSION}/paths/template-GET-1.yaml" "${FOLDER_PATHS}/${API_FILE_BASE}"
				
				sed -i "s^description: XXXX the XXXX configuration.^description: ${METHOD} the ${ENDPOINT_YAML} configuration.^" ${FOLDER_PATHS}/${API_FILE_BASE}
				sed -i "s^operationId: XXXX^operationId: ${OPERATION_ID}^" ${FOLDER_PATHS}/${API_FILE_BASE}

				sed "/^tags:$/r"<(
				    echo "  - ${API_FOLDER}"
				) -i -- ${FOLDER_PATHS}/${API_FILE_BASE}

				sed "/^responses:$/r"<(
				    echo "  '200':"
				    echo '    $ref: "../../response/'${API_FOLDER}'/'${API_FILE_200}'"'
				) -i -- ${FOLDER_PATHS}/${API_FILE_BASE}

				if [ "${ID_PARAMETER}" = true ]; then
					echo "" 															>> ${FOLDER_PATHS}/${API_FILE_BASE}
					echo "parameters:" 													>> ${FOLDER_PATHS}/${API_FILE_BASE}
		    		echo '  - $ref: "../../parameters/path/'${API_FILE_PARAMETER}'"' 	>> ${FOLDER_PATHS}/${API_FILE_BASE}
				fi
			fi

			if [ ! -f "${FOLDER_RESPONSE}/${API_FILE_200}" ]; then
				cp -rf "templates/${API_VERSION}/response/template-GET-200.yaml" "${FOLDER_RESPONSE}/${API_FILE_200}"
				sed -i 's^$ref: XXXX^$ref: "../../schemas/'${API_FOLDER}'/'${API_FILE_200}'"^' ${FOLDER_RESPONSE}/${API_FILE_200}
			fi

			if [ ! -f "${FOLDER_SCHEMAS}/${API_FILE_200}" ]; then
				cp -rf "templates/${API_VERSION}/schemas/template-GET-200.yaml" "${FOLDER_SCHEMAS}/${API_FILE_200}"
				sed -i 's^response: XXXX^response: '${ENDPOINT_YAML}'^' ${FOLDER_SCHEMAS}/${API_FILE_200}
				sed -i 's^description: Tamplate schema for endpoint XXXX.^description: Tamplate schema for endpoint '${ENDPOINT_YAML}'.^' ${FOLDER_SCHEMAS}/${API_FILE_200}
			fi

		elif [ "${METHOD}" = "DELETE" ]; then

			if [ ! -f "${FOLDER_PATHS}/${API_FILE_BASE}" ]; then
				cp -rf "templates/${API_VERSION}/paths/template-GET-1.yaml" "${FOLDER_PATHS}/${API_FILE_BASE}"
				
				sed -i "s^description: XXXX the XXXX configuration.^description: ${METHOD} the ${ENDPOINT_YAML} configuration.^" ${FOLDER_PATHS}/${API_FILE_BASE}
				sed -i "s^operationId: XXXX^operationId: ${OPERATION_ID}^" ${FOLDER_PATHS}/${API_FILE_BASE}

				sed "/^tags:$/r"<(
				    echo "  - ${API_FOLDER}"
				) -i -- ${FOLDER_PATHS}/${API_FILE_BASE}

				sed "/^responses:$/r"<(
				    echo "  '200':"
				    echo '    $ref: "../../response/'${API_FOLDER}'/'${API_FILE_200}'"'
				) -i -- ${FOLDER_PATHS}/${API_FILE_BASE}

				sed "/^responses:$/r"<(
				    echo "  '400':"
				    echo '    $ref: "../../response/'${API_FOLDER}'/'${API_FILE_400}'"'
				) -i -- ${FOLDER_PATHS}/${API_FILE_BASE}

				if [ "${ID_PARAMETER}" = true ]; then
					echo "" 															>> ${FOLDER_PATHS}/${API_FILE_BASE}
					echo "parameters:" 													>> ${FOLDER_PATHS}/${API_FILE_BASE}
		    		echo '  - $ref: "../../parameters/path/'${API_FILE_PARAMETER}'"' 	>> ${FOLDER_PATHS}/${API_FILE_BASE}
				fi
			fi
			# 200 RESPONSE
			if [ ! -f "${FOLDER_RESPONSE}/${API_FILE_200}" ]; then
				cp -rf "templates/${API_VERSION}/response/template-DELETE-200.yaml" "${FOLDER_RESPONSE}/${API_FILE_200}"
				sed -i 's^$ref: XXXX^$ref: "../../schemas/'${API_FOLDER}'/'${API_FILE_200}'"^' ${FOLDER_RESPONSE}/${API_FILE_200}
				sed -i 's^description: Successful response for XXXX^description: Successful response for '${ENDPOINT_YAML}'^' ${FOLDER_RESPONSE}/${API_FILE_200}
			fi
			# 200 SCHEMA
			if [ ! -f "${FOLDER_SCHEMAS}/${API_FILE_200}" ]; then
				cp -rf "templates/${API_VERSION}/schemas/template-DELETE-200.yaml" "${FOLDER_SCHEMAS}/${API_FILE_200}"
				sed -i 's^response: XXXX^response: '${ENDPOINT_YAML}'^' ${FOLDER_SCHEMAS}/${API_FILE_200}
				sed -i 's^description: Tamplate schema for endpoint XXXX.^description: Tamplate schema for endpoint '${ENDPOINT_YAML}'.^' ${FOLDER_SCHEMAS}/${API_FILE_200}
			fi
			# 400 RESPONSE
			if [ ! -f "${FOLDER_RESPONSE}/${API_FILE_400}" ]; then
				cp -rf "templates/${API_VERSION}/response/template-DELETE-400.yaml" "${FOLDER_RESPONSE}/${API_FILE_400}"
				sed -i 's^$ref: XXXX^$ref: "../../schemas/'${API_FOLDER}'/'${API_FILE_400}'"^' ${FOLDER_RESPONSE}/${API_FILE_400}
				sed -i 's^description: Bad request for XXXX^description: Bad request for '${ENDPOINT_YAML}'.^' ${FOLDER_RESPONSE}/${API_FILE_400}
			fi
			# 400 SCHEMA
			if [ ! -f "${FOLDER_SCHEMAS}/${API_FILE_400}" ]; then
				cp -rf "templates/${API_VERSION}/schemas/template-DELETE-400.yaml" "${FOLDER_SCHEMAS}/${API_FILE_400}"
				sed -i 's^Can not do XXXX^Can not do '${ENDPOINT_YAML}'^' ${FOLDER_SCHEMAS}/${API_FILE_400}
				sed -i 's^description: Error in setting XXXX.^description: Error in setting '${ENDPOINT_YAML}'.^' ${FOLDER_SCHEMAS}/${API_FILE_400}
			fi

		elif [ "${METHOD}" = "POST" ]; then

			REQUEST_EXISTS=$(cat ${FOLDER_ROUTERS}/${API_FILE_ROUTER} | grep -F -- "requestBodies:")
			if [ -z "${REQUEST_EXISTS}" ]; then
				sed "/^components:$/r"<(
				    echo "  requestBodies:"
				    echo '    $ref: "./content/'${PLATFORM}'/'${API_VERSION}'/request/'${PLATFORM}'_index.yaml"'
				) -i -- ${FOLDER_ROUTERS}/${API_FILE_ROUTER}
			fi

			if [ ! -f "${FOLDER_PATHS}/${API_FILE_BASE}" ]; then
				cp -rf "templates/${API_VERSION}/paths/template-POST-1.yaml" "${FOLDER_PATHS}/${API_FILE_BASE}"
				
				sed -i "s^description: XXXX the XXXX configuration.^description: ${METHOD} the ${ENDPOINT_YAML} configuration.^" ${FOLDER_PATHS}/${API_FILE_BASE}
				sed -i "s^operationId: XXXX^operationId: ${OPERATION_ID}^" ${FOLDER_PATHS}/${API_FILE_BASE}

				sed "/^tags:$/r"<(
				    echo "  - ${API_FOLDER}"
				) -i -- ${FOLDER_PATHS}/${API_FILE_BASE}

				sed "/^responses:$/r"<(
				    echo "  '200':"
				    echo '    $ref: "../../response/'${API_FOLDER}'/'${API_FILE_200}'"'
				) -i -- ${FOLDER_PATHS}/${API_FILE_BASE}

				sed "/^responses:$/r"<(
				    echo "  '400':"
				    echo '    $ref: "../../response/'${API_FOLDER}'/'${API_FILE_400}'"'
				) -i -- ${FOLDER_PATHS}/${API_FILE_BASE}

				sed "/^requestBody:$/r"<(
				    echo '  $ref: "../../request/'${API_FOLDER}'/'${API_FILE_BASE}'"'
				) -i -- ${FOLDER_PATHS}/${API_FILE_BASE}

				if [ "${ID_PARAMETER}" = true ]; then
					echo "" 															>> ${FOLDER_PATHS}/${API_FILE_BASE}
					echo "parameters:" 													>> ${FOLDER_PATHS}/${API_FILE_BASE}
		    		echo '  - $ref: "../../parameters/path/'${API_FILE_PARAMETER}'"' 	>> ${FOLDER_PATHS}/${API_FILE_BASE}
				fi
			fi

			#REQUEST
			if [ ! -f "${FOLDER_REQUEST}/${API_FILE_BASE}" ]; then
				cp -rf "templates/${API_VERSION}/request/template-POST-1.yaml" "${FOLDER_REQUEST}/${API_FILE_BASE}"
				sed -i 's^$ref: XXXX^$ref: "../../schemas/'${API_FOLDER}'/'${API_FILE_BASE}'"^' "${FOLDER_REQUEST}/${API_FILE_BASE}"
				sed -i 's^description: Request for XXXX^description: Request for '${ENDPOINT_YAML}'^' "${FOLDER_REQUEST}/${API_FILE_BASE}"
			fi

			#REQUEST SCHEMAS
			if [ ! -f "${FOLDER_SCHEMAS}/${API_FILE_BASE}" ]; then
				cp -rf "templates/${API_VERSION}/schemas/template-POST-1.yaml" "${FOLDER_SCHEMAS}/${API_FILE_BASE}"
			fi

			# 200 RESPONSE
			if [ ! -f "${FOLDER_RESPONSE}/${API_FILE_200}" ]; then
				cp -rf "templates/${API_VERSION}/response/template-POST-200.yaml" "${FOLDER_RESPONSE}/${API_FILE_200}"
				sed -i 's^$ref: XXXX^$ref: "../../schemas/'${API_FOLDER}'/'${API_FILE_200}'"^' ${FOLDER_RESPONSE}/${API_FILE_200}
				sed -i 's^description: Successful response for XXXX^description: Successful response for '${ENDPOINT_YAML}'^' ${FOLDER_RESPONSE}/${API_FILE_200}
			fi

			# 200 SCHEMA
			if [ ! -f "${FOLDER_SCHEMAS}/${API_FILE_200}" ]; then
				cp -rf "templates/${API_VERSION}/schemas/template-POST-200.yaml" "${FOLDER_SCHEMAS}/${API_FILE_200}"
				sed -i 's^response: XXXX^response: '${ENDPOINT_YAML}'^' ${FOLDER_SCHEMAS}/${API_FILE_200}
				sed -i 's^description: Tamplate schema for endpoint XXXX.^description: Tamplate schema for endpoint '${ENDPOINT_YAML}'.^' ${FOLDER_SCHEMAS}/${API_FILE_200}
			fi
			# 400 RESPONSE
			if [ ! -f "${FOLDER_RESPONSE}/${API_FILE_400}" ]; then
				cp -rf "templates/${API_VERSION}/response/template-POST-400.yaml" "${FOLDER_RESPONSE}/${API_FILE_400}"
				sed -i 's^$ref: XXXX^$ref: "../../schemas/'${API_FOLDER}'/'${API_FILE_400}'"^' ${FOLDER_RESPONSE}/${API_FILE_400}
				sed -i 's^description: Bad request for XXXX^description: Bad request for '${ENDPOINT_YAML}'.^' ${FOLDER_RESPONSE}/${API_FILE_400}
			fi
			# 400 SCHEMA
			if [ ! -f "${FOLDER_SCHEMAS}/${API_FILE_400}" ]; then
				cp -rf "templates/${API_VERSION}/schemas/template-POST-400.yaml" "${FOLDER_SCHEMAS}/${API_FILE_400}"
				sed -i 's^Can not do XXXX^Can not do '${ENDPOINT_YAML}'^' ${FOLDER_SCHEMAS}/${API_FILE_400}
				sed -i 's^description: Error in setting XXXX.^description: Error in setting '${ENDPOINT_YAML}'.^' ${FOLDER_SCHEMAS}/${API_FILE_400}
			fi

		elif [ "${METHOD}" = "PUT" ]; then

			REQUEST_EXISTS=$(cat ${FOLDER_ROUTERS}/${API_FILE_ROUTER} | grep -F -- "requestBodies:")
			if [ -z "${REQUEST_EXISTS}" ]; then
				sed "/^components:$/r"<(
				    echo "  requestBodies:"
				    echo '    $ref: "./content/'${PLATFORM}'/'${API_VERSION}'/request/'${PLATFORM}'_index.yaml"'
				) -i -- ${FOLDER_ROUTERS}/${API_FILE_ROUTER}
			fi

			if [ ! -f "${FOLDER_PATHS}/${API_FILE_BASE}" ]; then
				cp -rf "templates/${API_VERSION}/paths/template-PUT-1.yaml" "${FOLDER_PATHS}/${API_FILE_BASE}"
				
				sed -i "s^description: XXXX the XXXX configuration.^description: ${METHOD} the ${ENDPOINT_YAML} configuration.^" ${FOLDER_PATHS}/${API_FILE_BASE}
				sed -i "s^operationId: XXXX^operationId: ${OPERATION_ID}^" ${FOLDER_PATHS}/${API_FILE_BASE}

				sed "/^tags:$/r"<(
				    echo "  - ${API_FOLDER}"
				) -i -- ${FOLDER_PATHS}/${API_FILE_BASE}

				sed "/^responses:$/r"<(
				    echo "  '200':"
				    echo '    $ref: "../../response/'${API_FOLDER}'/'${API_FILE_200}'"'
				) -i -- ${FOLDER_PATHS}/${API_FILE_BASE}

				sed "/^responses:$/r"<(
				    echo "  '400':"
				    echo '    $ref: "../../response/'${API_FOLDER}'/'${API_FILE_400}'"'
				) -i -- ${FOLDER_PATHS}/${API_FILE_BASE}

				sed "/^requestBody:$/r"<(
				    echo '  $ref: "../../request/'${API_FOLDER}'/'${API_FILE_BASE}'"'
				) -i -- ${FOLDER_PATHS}/${API_FILE_BASE}

				if [ "${ID_PARAMETER}" = true ]; then
					echo "" 															>> ${FOLDER_PATHS}/${API_FILE_BASE}
					echo "parameters:" 													>> ${FOLDER_PATHS}/${API_FILE_BASE}
		    		echo '  - $ref: "../../parameters/path/'${API_FILE_PARAMETER}'"' 	>> ${FOLDER_PATHS}/${API_FILE_BASE}
				fi
			fi

			#REQUEST
			if [ ! -f "${FOLDER_REQUEST}/${API_FILE_BASE}" ]; then
				cp -rf "templates/${API_VERSION}/request/template-PUT-1.yaml" "${FOLDER_REQUEST}/${API_FILE_BASE}"
				sed -i 's^$ref: XXXX^$ref: "../../schemas/'${API_FOLDER}'/'${API_FILE_BASE}'"^' "${FOLDER_REQUEST}/${API_FILE_BASE}"
				sed -i 's^description: Request for XXXX^description: Request for '${ENDPOINT_YAML}'^' "${FOLDER_REQUEST}/${API_FILE_BASE}"
			fi

			#REQUEST SCHEMAS
			if [ ! -f "${FOLDER_SCHEMAS}/${API_FILE_BASE}" ]; then
				cp -rf "templates/${API_VERSION}/schemas/template-PUT-1.yaml" "${FOLDER_SCHEMAS}/${API_FILE_BASE}"
			fi

			# 200 RESPONSE
			if [ ! -f "${FOLDER_RESPONSE}/${API_FILE_200}" ]; then
				cp -rf "templates/${API_VERSION}/response/template-PUT-200.yaml" "${FOLDER_RESPONSE}/${API_FILE_200}"
				sed -i 's^$ref: XXXX^$ref: "../../schemas/'${API_FOLDER}'/'${API_FILE_200}'"^' ${FOLDER_RESPONSE}/${API_FILE_200}
				sed -i 's^description: Successful response for XXXX^description: Successful response for '${ENDPOINT_YAML}'^' ${FOLDER_RESPONSE}/${API_FILE_200}
			fi

			# 200 SCHEMA
			if [ ! -f "${FOLDER_SCHEMAS}/${API_FILE_200}" ]; then
				cp -rf "templates/${API_VERSION}/schemas/template-PUT-200.yaml" "${FOLDER_SCHEMAS}/${API_FILE_200}"
				sed -i 's^response: XXXX^response: '${ENDPOINT_YAML}'^' ${FOLDER_SCHEMAS}/${API_FILE_200}
				sed -i 's^description: Tamplate schema for endpoint XXXX.^description: Tamplate schema for endpoint '${ENDPOINT_YAML}'.^' ${FOLDER_SCHEMAS}/${API_FILE_200}
			fi
			# 400 RESPONSE
			if [ ! -f "${FOLDER_RESPONSE}/${API_FILE_400}" ]; then
				cp -rf "templates/${API_VERSION}/response/template-PUT-400.yaml" "${FOLDER_RESPONSE}/${API_FILE_400}"
				sed -i 's^$ref: XXXX^$ref: "../../schemas/'${API_FOLDER}'/'${API_FILE_400}'"^' ${FOLDER_RESPONSE}/${API_FILE_400}
				sed -i 's^description: Bad request for XXXX^description: Bad request for '${ENDPOINT_YAML}'.^' ${FOLDER_RESPONSE}/${API_FILE_400}
			fi
			# 400 SCHEMA
			if [ ! -f "${FOLDER_SCHEMAS}/${API_FILE_400}" ]; then
				cp -rf "templates/${API_VERSION}/schemas/template-PUT-400.yaml" "${FOLDER_SCHEMAS}/${API_FILE_400}"
				sed -i 's^Can not do XXXX^Can not do '${ENDPOINT_YAML}'^' ${FOLDER_SCHEMAS}/${API_FILE_400}
				sed -i 's^description: Error in setting XXXX.^description: Error in setting '${ENDPOINT_YAML}'.^' ${FOLDER_SCHEMAS}/${API_FILE_400}
			fi
		fi

		if [ "${ID_PARAMETER}" = true ]; then
			PARAMETERS_EXISTS=$(cat ${FOLDER_ROUTERS}/${API_FILE_ROUTER} | grep -F -- "parameters:")
			if [ -z "${PARAMETERS_EXISTS}" ]; then
				sed "/^components:$/r"<(
				    echo "  parameters:"
				    echo '    $ref: "./content/'${PLATFORM}'/'${API_VERSION}'/parameters/'${PLATFORM}'_index.yaml"'
				) -i -- ${FOLDER_ROUTERS}/${API_FILE_ROUTER}
			fi

			if [ ! -f "${FOLDER_PARAMETERS}/${API_FILE_PARAMETER}" ]; then
				cat > "${FOLDER_PARAMETERS}/${API_FILE_PARAMETER}" <<-END
					### This file is automatically generated and it should be verified! ###
					in: path
					name: ${ID_PARAMETER_NAME}
					required: true
					schema:
					  type: string
				END
			fi
		fi	
	fi
}

get_api