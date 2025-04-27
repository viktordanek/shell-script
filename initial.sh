${LN} --symbolic ${DRAFT} /initial/script &&
  if ${INITIAL} > /initial/standard-output 2> /initial/standard-error
  then
    ${ECHO} ${?} > /initial/status
  else
    ${ECHO} ${?} > /initial/status
  fi &&
  if [ ! -f /initial/standard-output ]
  then
    ${ECHO} missing standard-output >> /work/initial/ERROR
  elif [ ! -z "$( ${CAT} /initial/standard-output )" ]
  then
    ${ECHO} non-empty standard-output >> /work/initial/ERROR
  elif [ ! -f /initial/standard-error ]
  then
    ${ECHO} missing standard-error >> /work/initial/ERROR
  elif [ ! -z "$( ${CAT} /initial/standard-error )" ]
  then
    ${ECHO} non-empty standard-error >> /work/initial/ERROR
  elif [ ! -f /initial/status ]
  then
    ${ECHO} missing status >> /work/initial/ERROR
  elif [ "$( ${CAT} /initial/status )" != 0 ]
  then
    ${ECHO} non-zero status >> /work/initial/ERROR
  elif [ ! -e /mount/target ]
  then
    ${ECHO} no target >> /work/initial/ERROR
  elif [ $( ${FIND} /mount -mindepth 1 -maxdepth 1 ! -name target | ${WC} --lines ) != 0 ]
  then
    ${ECHO} over target >> /work/initial/ERROR &&
      ${FIND} /mount -mindepth 1 -maxdepth 1 ! -name target >> /work/initial/ERROR
  fi &&
  ${CP} --recursive /mount/target /initial/target