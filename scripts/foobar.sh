${ECHO} ${TOKEN} > /sandbox/file &&
  ${ECHO} ${STANDARD_OUTPUT} &&
  ${ECHO} ${STANDARD_ERROR} >&2 &&
  ${ECHO} ${@} > /sandbox/arguments &&
  exit 1