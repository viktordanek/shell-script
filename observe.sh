${MKDIR} /work/mounts &&
  ${FIND} ${OUT} -type f -name "initial.*.shelled.sh" | while read FILE
  do
    NAME=$( ${BASENAME} "$FILE" ) &&
      HASH_1=${NAME#initial.} &&
      HASH=${HASH_1%.wrapped.sh} &&
      ${MKDIR} /work/mounts/${HASH} &&
      ${MKDIR} /work/mounts/${HASH}/mount &&
      if ${FILE} > /work/mounts/${HASH}/standard-output 2> /work/mounts/${HASH}/standard-error
      then
        ${ECHO} ${?} > /work/mounts/${HASH}/status
      else
        ${ECHO} ${?} > /work/mounts/${HASH}/status
      fi &&
      if [ ! -e /work/mounts/${HASH}/standard-output ]
      then
        ${ECHO} missing standard-output for ${HASH} >> /work/ERROR
      elif [ ! -z "$( ${CAT} /work/mounts/standard-output ) }" ]
      then
        ${ECHO} non-empty standard-output for ${HASH} >> /work/ERROR &&
          ${CAT} /work/mounts/standard-output >> /work/ERROR
      elif [ ! -e /work/mounts/${HASH}/standard-error ]
      then
        ${ECHO} missing standard-error for ${HASH} >> /work/ERROR
      elif [ ! -z "$( ${CAT} /work/mounts/standard-error ) }" ]
      then
        ${ECHO} non-empty standard-error for ${HASH} >> /work/ERROR &&
          ${CAT} /work/mounts/standard-error >> /work/ERROR
      elif [ ! -e /work/mounts/${HASH}/status ]
      then
        ${ECHO} missing status for ${HASH} >> /work/ERROR
      elif [ "$( ${CAT} /work/mounts/status != 0 ) }" ]
      then
        ${ECHO} non-zero status for ${HASH} >> /work/ERROR &&
          ${CAT} /work/mounts/status >> /work/ERROR
      elif [ ! -e /work/mounts/${HASH}/mount/target ]
      then
        ${ECHO} initial did not create target >> /work/ERROR
      elif [ $( ${FIND} /work/mounts -mindepth 1 -maxdepth 1 ! -name standard-output ! -name standard-error ! -name status ! -name mount | ${WC} --lines ) != 0 ]
      then
        ${ECHO} initial over created >> /work/ERROR &&
          ${FIND} /work/mounts -mindepth 1 -maxdepth 1 ! -name standard-output ! -name standard-error ! -name status ! -name mount >> /work/ERROR
      fi
  done