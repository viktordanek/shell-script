SINGLETON=$( ${CAT} /singleton ) &&
  STANDARD_INPUT=$( ${CAT} ) &&
  ${ECHO} singleton ${SINGLETON} ${STANDARD_INPUT} ${@} ${FOOBAR} > /singleton &&
  ${ECHO} standard-output ${SINGLETON} ${STANDARD_INPUT} ${@} ${FOOBAR} &&
  ${ECHO} standard-error ${SINGLETON} ${STANDARD_INPUT} ${@} ${FOOBAR} >&2 &&
  exit $(( 0x$( ${ECHO} ${SINGLETON} ${STANDARD_INPUT} ${@} ${FOOBAR} | ${SHA512SUM} | ${CUT} --bytes -128 ) % 256 ))