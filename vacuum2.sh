${FIND} /input | while read FILE
  do
    KEY=${FILE#/input} &&
      HASH=$( ${ECHO} ${KEY} ${UUID} | ${SHA512SUM} | ${CUT} --bytes -128 ) &&
      INDEX=$( ${FIND} /output -mindepth 2 -maxdepth 2 -type d -name "${HASH}" | ${WC} --lines ) &&
      if [ ! -d /output/${INDEX} ]
      then
        ${MKDIR} /output/${INDEX} &&
          ${CHMOD} 0777 /output/${INDEX}
      fi &&
      ${MKDIR} /output/${INDEX}/${HASH} &&
      # ${DATE} +%s%N > /output/${INDEX}/${HASH}/trace &&
      ${ECHO} ${KEY} > /output/${INDEX}/${HASH}/key &&
      ${STAT} --format "%a" ${FILE} > /output/${INDEX}/${HASH}/stat &&
      ${CHMOD} 0777 /output/${INDEX}/${HASH} /output/${INDEX}/${HASH}/key /output/${INDEX}/${HASH}/stat &&
      if [ -f ${FILE} ]
      then
        ${CAT} ${FILE} > /output/${INDEX}/${HASH}/cat
          ${CHMOD} 0777 /output/${INDEX}/${HASH}/cat
      fi
  done