SINGLETON=$( ${CAT} /singleton/file ) &&
  STANDARD_INPUT=$( ${CAT} ) &&
  ${CHMOD} 0777 /singleton/file &&
  ${ECHO} singleton ${SINGLETON} ${STANDARD_INPUT} > /singleton/file &&
  ${ECHO} standard-output ${SINGLETON} ${STANDARD_INPUT} &&
  ${ECHO} standard-error ${SINGLETON} ${STANDARD_INPUT} >&2