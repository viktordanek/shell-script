if ${INITIAL} > ${RECORD}/standard-output 2> ${RECORD}/standard-error
then
  ${ECHO} ${?} > ${RECORD}/status
else
  ${ECHO} ${?} > ${RECORD}/status
fi