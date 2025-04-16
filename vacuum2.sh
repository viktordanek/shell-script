${FIND} /input | while read FILE
  do
    KEY=${FILE#/input} &&
      HASH=$( ${ECHO} ${KEY} ${UUID} | ${SHA512SUM} | ${CUT} --bytes -128 ) &&
      INDEX=$( ${FIND} /output -mindepth 2 -maxdepth 2 -type d -name "${HASH}" | ${WC} --lines ) &&
      if [ ${INDEX} == 0 ]
      then
        ${MKDIR} /output/${HASH}
      fi &&
      ${MKDIR} /output/${HASH}/index
      ${ECHO} ${KEY} > /output/${HASH}/${INDEX}/key &&
      ${STAT} --format "%a" ${FILE} > /output/${HASH}/${INDEX}/stat &&
      ${CHMOD} 0777 /output/${HASH}/${INDEX}/key /output/${HASH}/${INDEX}/stat &&
      if [ -f ${FILE} ]
      then
        ${CAT} ${FILE} > /output/${HASH}/${INDEX}/cat &&
          ${CHMOD} 0777 /output/${HASH}/${INDEX}/cat
      fi
  done