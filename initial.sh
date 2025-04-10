if ${INITIAL} > /mount/standard-output 2> /mount/standard-error
then
  ${ECHO} ${?} > /mount/status
else
  ${ECHO} ${?} > /mount/status
fi &&
  if [ ! -e /mount/status ]
  then
      exit 63
  elif [ $( ${CAT} /mount/status ) != 0 ]
  then
    exit 62
  elif [ ! -e /mount/standard-error ]
  then
    exit 61
  elif [ ! -z $( ${CAT} /mount/standard-error ) ]
  then
    exit 60
  elif [ ! -e /mount/standard-output ]
  then
    exit 59
  elif [ ! -z $( ${CAT} /mount/standard-output ) ]
  then
    exit 58
  elif [ ! -e /mount/target ]
  then
    exit 57
  elif [ $( ${FIND} /mount -mindepth 1 -maxdepth 1 ! -name status ! -name standard-error ! -name standard-output ! -name target ) == 0 ]
  then
    exit 56
  fi