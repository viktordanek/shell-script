SINGLETON=$( ${CAT} /singleton ) &&
  STANDARD_INPUT=$( ${CAT} ) &&
  ${ECHO} singleton ${SINGLETON} ${STANDARD_INPUT} ${@}  > /singleton &&
  ${ECHO} standard-output ${SINGLETON} ${STANDARD_INPUT} ${@} &&
  ${ECHO} standard-error ${SINGLETON} ${STANDARD_INPUT} ${@} >&2 &&
  exit $(( 0x$( ${ECHO} ${SINGLETON} | ${SHA512SUM} | ${CUT} --bytes -128 ) % 256 ))