if [ -f /singleton ]
  then
    SINGLETON=$( ${CAT} /singleton )
      ${ECHO} singleton ${SINGLETON} ${STANDARD_INPUT} ${@} > /singleton
  else
    SINGLETON=""
  fi &&
  ${ECHO} standard-output ${SINGLETON} ${STANDARD_INPUT} ${@} &&
  ${ECHO} standard-error ${SINGLETON} ${STANDARD_INPUT} ${@} >&2 &&
  exit $(( 0x$( ${ECHO} ${SINGLETON} | ${SHA512SUM} | ${CUT} --bytes -128 ) % 256 ))