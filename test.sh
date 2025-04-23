if ${TEST} > /work/final/standard-output 2> /work/final/standard-error
then
  ${ECHO} ${?} > /work/final/status
else
  ${ECHO} ${?} > /work/final/status
fi