if ${INITIAL} > /record/standard-output 2> /record/standard-error
then
  ${ECHO} ${?} > /record/status
else
  ${ECHO} ${?} > /record/status
fi &&
  if [ ! -f /record/standard-output ]
  then
    ${ECHO} missing standard-output >> /record/ERROR
  elif [ ! -z "$( ${CAT} /record/standard-output )" ]
  then
    ${ECHO} non-empty standard-output >> /record/ERROR
  elif [ ! -f /record/standard-error ]
  then
    ${ECHO} missing standard-error >> /record/ERROR
  elif [ ! -z "$( ${CAT} /record/standard-error )" ]
  then
    ${ECHO} non-empty standard-error >> /record/ERROR
  fi