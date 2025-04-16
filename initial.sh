${MKDIR} /work/initial &&
  ${MKDIR} /work/mount &&
  if ${INITIAL} > /work/initial/standard-output 2> /work/initial/standard-error
  then
    ${ECHO} ${?} > /work/initial/status
  else
    ${ECHO} ${?} > /work/initial/status
  fi &&
  if [ ! -f /work/initial/standard-output ]
  then
    ${ECHO} missing standard-output >> /work/initial/ERROR
  elif [ ! -z "$( ${CAT} /work/initial/standard-output )" ]
  then
    ${ECHO} non-empty standard-output >> /work/initial/ERROR
  elif [ ! -f /work/initial/standard-error ]
  then
    ${ECHO} missing standard-error >> /work/initial/ERROR
  elif [ ! -z "$( ${CAT} /work/initial/standard-error )" ]
  then
    ${ECHO} non-empty standard-error >> /work/initial/ERROR
  elif [ ! -f /work/initial/status ]
  then
    ${ECHO} missing status >> /work/initial/ERROR
  elif [ "$( ${CAT} /work/initial/status )" != 0 ]
  then
    ${ECHO} non-zero status >> /work/initial/ERROR
  elif [ ! -e /work/mount/target ]
  then
    ${ECHO} no target >> /work/initial/ERROR
  elif [ $( ${FIND} /work/mount -mindepth 1 ! -name target | ${WC} --lines ) != 0 ]
  then
    ${ECHO} over target >> /work/initial/ERROR
  fi