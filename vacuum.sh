${FIND} /input | while read FILE
  do
    KEY=${FILE#/input} &&
      HASH=$( ${ECHO} ${KEY} ${UUID} | ${SHA512SUM} | ${CUT} --bytes -128 ) &&
      INDEX=$( ${FIND} /output/${HASH} -mindepth 0 -maxdepth 0 -type f -name "${HASH}.*.key" | ${WC} --lines ) &&
      ${ECHO} ${KEY} > /output/${HASH}.${INDEX}.key &&
      ${STAT} --format "%a" ${FILE} > /output/${HASH}.${INDEX}.stat &&
      ${CHMOD} 0777 /output/${HASH}.${INDEX}.key /output/${HASH}.${INDEX}.stat &&
      if [ -f ${FILE} ]
      then
        ${CAT} ${FILE} > /output/${HASH}.${INDEX}.cat &&
          ${CHMOD} 0777 /output/${HASH}.${INDEX}.cat
      fi
  done