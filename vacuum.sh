INPUT=${1} &&
  OUTPUT=${2} &&
  NAME=${3} &&
  ${MKDIR} ${OUTPUT} &&
  ${FIND} ${INPUT} | while read FILE
  do
    KEY=${FILE#${INPUT}} &&
      HASH=$( ${ECHO} ${KEY} ${UUID} | ${SHA512SUM} | ${CUT} --bytes -128 ) &&
      INDEX=$( ${FIND} ${OUTPUT}/${HASH} -mindepth 0 -maxdepth 0 -type f -name "${HASH}.*.key" | ${WC} --lines ) &&
      ${TOUCH} ${OUTPUT}/.gitkeep &&
      ${ECHO} ${NAME}${KEY} > ${OUTPUT}/${HASH}.${INDEX}.key &&
      ${STAT} --format "%a" ${FILE} > ${OUTPUT}/${HASH}.${INDEX}.stat &&
      ${CHMOD} 0777 ${OUTPUT}/${HASH}.${INDEX}.key ${OUTPUT}/${HASH}.${INDEX}.stat &&
      if [ -f ${FILE} ]
      then
        ${CAT} ${FILE} > ${OUTPUT}/${HASH}.${INDEX}.cat &&
          ${CHMOD} 0777 ${OUTPUT}/${HASH}.${INDEX}.cat
      fi
  done