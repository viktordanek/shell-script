 ${FIND} ${INPUT} | while read FILE
  do
    KEY=${FILE#${INPUT}} &&
      HASH=$( ${ECHO} ${KEY} ${UUID} | ${SHA512SUM} | ${CUT} --bytes -128 ) &&
      INDEX=$( ${FIND} ${OUTPUT} -mindepth 2 -maxdepth 2 -type d -name "${HASH}" | ${WC} --lines ) &&
      if [ ${INDEX} == 0 ]
      then
        ${MKDIR} ${OUTPUT}/${HASH}
      fi &&
      ${MKDIR} ${OUTPUT}/${HASH}/${INDEX} &&
      ${ECHO} ${KEY} > ${OUTPUT}/${HASH}/${INDEX}/key &&
      ${STAT} --format "%a" ${FILE} > ${OUTPUT}/${HASH}/${INDEX}/stat &&
      ${CHMOD} 0777 ${OUTPUT}/${HASH}/${INDEX}/key ${OUTPUT}/${HASH}/${INDEX}/stat &&
      if [ -f ${FILE} ]
      then
        ${CAT} ${FILE} > ${OUTPUT}/${HASH}/${INDEX}/cat &&
          ${CHMOD} 0777 ${OUTPUT}/${HASH}/${INDEX}/cat
      fi
  done