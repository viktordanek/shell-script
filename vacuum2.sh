${FIND} /input | while read FILE
  do
    KEY=${FILE#/input} &&
      HASH=$( ${ECHO} ${KEY} ${UUID} | ${SHA512SUM} | ${CUT} --bytes -128 ) &&
      if [ -d /output/0 ]
      then
        INDEX=$( ${FIND} /output -mindepth 2 -maxdepth 2 -type d -name "${HASH}" | ${WC} --lines )
      else
        INDEX=0
      fi &&
      if [ ! -d /output/${INDEX} ]
      then
        ${MKDIR} /output/${INDEX}
      fi &&
      ${MKDIR} /output/${INDEX}/${HASH} &&
      ${ECHO} ${KEY} > /output/${INDEX}/${HASH}/key &&
      ${STAT} --format "%a" ${FILE} > /output/${INDEX}/${HASH}/stat &&
      ${CHMOD} 0777 /output/${INDEX}/${HASH}/key /output/${INDEX}/${HASH}/stat &&
      if [ -f ${FILE} ]
      then
        ${CAT} ${FILE} > /output/${INDEX}/${HASH}/cat
          ${CHMOD} 0777 /output/${INDEX}/${HASH}/cat
      fi
  done