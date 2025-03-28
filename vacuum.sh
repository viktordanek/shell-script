INPUT=${1} &&
  OUTPUT=${2} &&
  NAME=${3} &&
  ${MKDIR} ${OUTPUT} &&
  ${FIND} ${INPUT} | while read FILE
  do
    KEY=${FILE#${INPUT}} &&
      HASH=$( ${ECHO} ${KEY} ${UUID} | ${SHA512SUM} | ${CUT} --bytes -128 ) &&
      INDEX=$( ${FIND} ${OUTPUT}/${HASH} -mindepth 0 -maxdepth 0 -type f -name "${HASH}.*.key" | ${WC} --lines ) &&
      ${CAT} ${FILE} > ${OUTPUT}/${HASH}.${INDEX}.cat &&
      ${STAT} --format "%a" ${FILE} > ${OUTPUT}/${HASH}.${INDEX}.stat &&
      ${ECHO} ${NAME}${KEY} > ${OUTPUT}/${HASH}.${INDEX}.key &&
      ${CHMOD} 0777 ${OUTPUT}/${HASH}.${INDEX}.cat ${OUTPUT}/${HASH}.${INDEX}.stat ${OUTPUT}/${HASH}.${INDEX}.key
  done