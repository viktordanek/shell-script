${ECHO} ${0} &&
if [ ${1} -lt 3 ]
then
  ${ECHO} ${1}
else
  ${ECHO} $(( $( ${FIB} $(( ${1} - 2 )) ) * $( ${FIB} $(( ${1} - 1 )) ) ))
fi