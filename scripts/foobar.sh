SINGLETON=$( ${CAT} /singleton ) &&
  STANDARD_INPUT=$( ${CAT} ) &&
  ${ECHO} singleton ${SINGLETON} ${STANDARD_INPUT} > /singleton/file &&
  ${ECHO} standard-output ${SINGLETON} ${STANDARD_INPUT} &&
  ${ECHO} standard-error ${SINGLETON} ${STANDARD_INPUT} >&2