if [ ${1} -lt 3 ]
then
  ${ECHO} -n ${1}
else
  ${ECHO} -n $(( $( ${FIB} $(( ${1} - 2 )) ) * $( ${FIB} $(( ${1} - 1 )) ) ))
fi