STANDARD_INPUT=${ceb56d2bcebc8e9cc485a093712de696d47b96ca866254795e566f370e2e76d92d7522558aaf4e9e7cdd6b603b527cee48a1af68a0abc1b68f2348f055346408} &&
  INITIAL=$( ${CAT} /sandbox/input ) &&
  ${ECHO} ${INITIAL} ${STANDARD_INPUT} ${INITIAL} ${TOKEN} ${NAME} ${@} /sandbox/file | ${SHA512SUM} | ${CUT} --bytes -128 | ${TR} -d "\n" > /sandbox/output &&
  ${ECHO} ${INITIAL} ${STANDARD_INPUT} ${INITIAL} ${TOKEN} ${NAME} ${@} standard-output | ${SHA512SUM} | ${CUT} --bytes -128 | ${TR} -d "\n" &&
  ${ECHO} ${INITIAL} ${STANDARD_INPUT} ${INITIAL} ${TOKEN} ${NAME} ${@} standard-error | ${SHA512SUM} | ${CUT} --bytes -128 | ${TR} -d "\n" >&2 &&
  exit $(( ( 0x$( ${ECHO} ${INITIAL} ${STANDARD_INPUT} ${INITIAL} ${TOKEN} ${NAME} ${@} status | ${SHA512SUM} | ${CUT} --bytes -128 ) ) & 0xFF ))