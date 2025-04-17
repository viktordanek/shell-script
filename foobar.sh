if [ -f /singleton ]
  then
    SINGLETON=$( ${CAT} /singleton )
  else
    SINGLETON=""
  fi &&
  STANDARD_INPUT=$( ${CAT} ) &&
  if [ -f /singleton ]
  then
    ${ECHO} singleton ${SINGLETON} ${STANDARD_INPUT} ${@} > /singleton
  fi &&
  ${ECHO} standard-output ${SINGLETON} ${STANDARD_INPUT} ${@} &&
  ${ECHO} standard-error ${SINGLETON} ${STANDARD_INPUT} ${@} >&2 &&
  exit $(( 0x$( ${ECHO} ${SINGLETON} | ${SHA512SUM} | ${CUT} --bytes -128 ) % 256 ))