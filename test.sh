${ECHO} AAAA ${TEST}  >> /work/DEBUG &&
if ${TEST} > /work/final/standard-output 2> /work/final/standard-error
then
${ECHO} AAAB >> /work/DEBUG &&
  ${ECHO} ${?} > /work/final/status
else
${ECHO} AAAC >> /work/DEBUG &&
  ${ECHO} ${?} > /work/final/status
fi