INPUT=${1} &&
  OUTPUT=${2} &&
  UUID=${3}
  ${MKDIR} ${OUTPUT} &&
    ${FIND} ${INPUT} | while read FILE
    do
      KEY=${FILE#${INPUT}} &&
        HASH=$( ${ECHO} ${KEY} ${UUID} | ${SHA512SUM} | ${CUT} --bytes -128 ) &&
        if [ -f ${OUTPUT}/${HASH}.key ]
        then
          ${ECHO} COLLISION DETECTED FOR KEY=${KEY} HASH=${HASH} UUID=${UUID} >&2 &&
            exit 64
        fi &&
        ${CAT} ${FILE} > ${OUTPUT}/${HASH}.cat &&
        ${STAT} ${FILE} > ${OUTPUT}/${HASH}.stat &&
        ${ECHO} ${KEY} > ${OUTPUT}/${HASH}.key
        ${CHMOD} 0777 ${OUTPUT}/${HASH}.cat ${OUTPUT}/${HASH}.stat ${OUTPUT}/${HASH}.key
    done