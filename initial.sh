if ${INITIAL} > /record/standard-output 2> /record/standard-error
then
  ${ECHO} ${?} > /record/status
else
  ${ECHO} ${?} > /record/status
fi &&
  if [ ! -e /record/standard-output ]
  then
    ${ECHO} missing standard-output >> /record/ERROR
  elif [ ! -z "$( ${CAT} /record/standard-output )" ]
  then
    ${ECHO} non-empty standard-output >> /record/ERROR
  fi