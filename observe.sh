${MKDIR} /work/mounts &&
  ${MKDIR} /work/initial &&
  ${FIND} ${OUT}/bin -type l -name "initial.*.shelled.sh" | ${SORT} | while read FILE
  do
    NAME=$( ${BASENAME} "$FILE" ) &&
      HASH_1=${NAME#initial.} &&
      HASH=${HASH_1%.shelled.sh} &&
      ${MKDIR} /work/mounts/${HASH} &&
      ${MKDIR} /work/initial/${HASH} &&
      ${LN} --symbolic ${OUT}/bin/initial.${HASH}.sh /work/initial/${HASH}/sh &&
      if ${FILE} > /work/initial/${HASH}/standard-output 2> /work/initial/${HASH}/standard-error
      then
        ${ECHO} ${?} > /work/initial/${HASH}/status
      else
        ${ECHO} ${?} > /work/initial/${HASH}/status
      fi &&
      if [ ! -e /work/initial/${HASH}/standard-output ]
      then
        ${ECHO} missing standard-output for ${HASH} >> /work/ERROR
      elif [ ! -L /work/initial/${HASH}/sh ]
      then
        ${ECHO} missing symbolic link for ${HASH} >> /work/error
      elif [ $( ${READLINK} /work/initial/${HASH}/sh != ${OUT}/bin/initial.${HASH}.sh ) ]
      then
        ${ECHO} symbolic link for ${HASH} does not point to target
      elif [ ! -z "$( ${CAT} /work/initial/${HASH}/standard-output ) }" ]
      then
        ${ECHO} non-empty standard-output for ${HASH} >> /work/ERROR &&
          ${CAT} /work/initial/${HASH}/standard-output >> /work/ERROR
      elif [ ! -e /work/initial/${HASH}/standard-error ]
      then
        ${ECHO} missing standard-error for ${HASH} >> /work/ERROR
      elif [ ! -z "$( ${CAT} /work/initial/${HASH}/standard-error ) }" ]
      then
        ${ECHO} non-empty standard-error for ${HASH} >> /work/ERROR &&
          ${CAT} /work/initial/${HASH}/standard-error >> /work/ERROR
      elif [ ! -e /work/mounts/${HASH}/status ]
      then
        ${ECHO} missing status for ${HASH} >> /work/ERROR
      elif [ "$( ${CAT} /work/mounts/${HASH}/status != 0 ) }" ]
      then
        ${ECHO} non-zero status for ${HASH} >> /work/ERROR &&
          ${CAT} /work/mounts/${HASH}/status >> /work/ERROR
      elif [ ! -e /work/mounts/${HASH}/target ]
      then
        ${ECHO} initial did not create target >> /work/ERROR
      elif [ $( ${FIND} /work/mounts/${HASH} -mindepth 1 -maxdepth 1 ! -name target | ${SORT} | ${WC} --lines ) != 0 ]
      then
        ${ECHO} initial over created >> /work/ERROR &&
          ${FIND} /work/mounts -mindepth 1 -maxdepth 1 ! -name standard-output ! -name standard-error ! -name status ! -name mount | ${SORT} >> /work/ERROR
      fi
  done