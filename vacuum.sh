INPUT=${1} &&
  OUTPUT=${2} &&
  UUID=${3}
  ${MKDIR} ${OUTPUT} &&
    ${FIND} ${INPUT} | while read FILE
    do
      KEY=${FILE#${INPUT}} &&
        HASH=$( ${ECHO} ${KEY} ${UUID} | ${SHA512SUM} | ${CUT} --bytes -128 ) &&
        if [ -f ${OUTPUT}/${KEY}.key ]
        then
          ${ECHO} COLLISION DETECTED >&2 &&
            exit 64
        fi &&
        ${CAT} ${FILE} > ${OUTPUT}/${KEY}.cat &&
        ${STAT} ${FILE} > ${OUTPUT}/${KEY}.stat &&
        ${ECHO} ${KEY} > ${OUTPUT}/${KEY}.key
        ${CHMOD} 0777 ${OUTPUT}/${KEY}.cat ${OUTPUT}/${KEY}.stat ${OUTPUT}/${KEY}.key
    done