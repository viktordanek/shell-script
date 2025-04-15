${MKDIR} ${WORK}/mounts &&
  ${MKDIR} ${WORK}/initial &&
  ${FIND} ${OUT}/bin -type l -name "initial.*.shelled.sh" | ${SORT} | while read FILE
  do
    NAME=$( ${BASENAME} "$FILE" ) &&
      HASH_1=${NAME#initial.} &&
      HASH=${HASH_1%.shelled.sh} &&
      ${MKDIR} ${WORK}/mounts/${HASH} &&
      ${MKDIR} ${WORK}/initial/${HASH} &&
      ${LN} --symbolic ${OUT}/bin/initial.${HASH}.sh ${WORK}/initial/${HASH}/sh &&
      if ${FILE} > ${WORK}/initial/${HASH}/standard-output 2> ${WORK}/initial/${HASH}/standard-error
      then
        ${ECHO} ${?} > ${WORK}/initial/${HASH}/status
      else
        ${ECHO} ${?} > ${WORK}/initial/${HASH}/status
      fi &&
      if [ ! -e ${WORK}/initial/${HASH}/standard-output ]
      then
        ${ECHO} missing standard-output for ${HASH} >> ${WORK}/ERROR
      elif [ ! -L ${WORK}/initial/${HASH}/sh ]
      then
        ${ECHO} missing symbolic link for ${HASH} >> ${WORK}/error
      elif [ $( ${READLINK} ${WORK}/initial/${HASH}/sh != ${OUT}/bin/initial.${HASH}.sh ) ]
      then
        ${ECHO} symbolic link for ${HASH} does not point to target
      elif [ ! -z "$( ${CAT} ${WORK}/initial/${HASH}/standard-output ) }" ]
      then
        ${ECHO} non-empty standard-output for ${HASH} >> ${WORK}/ERROR &&
          ${CAT} ${WORK}/initial/${HASH}/standard-output >> ${WORK}/ERROR
      elif [ ! -e ${WORK}/initial/${HASH}/standard-error ]
      then
        ${ECHO} missing standard-error for ${HASH} >> ${WORK}/ERROR
      elif [ ! -z "$( ${CAT} ${WORK}/initial/${HASH}/standard-error ) }" ]
      then
        ${ECHO} non-empty standard-error for ${HASH} >> ${WORK}/ERROR &&
          ${CAT} ${WORK}/initial/${HASH}/standard-error >> ${WORK}/ERROR
      elif [ ! -e ${WORK}/mounts/${HASH}/status ]
      then
        ${ECHO} missing status for ${HASH} >> ${WORK}/ERROR
      elif [ "$( ${CAT} ${WORK}/mounts/${HASH}/status != 0 ) }" ]
      then
        ${ECHO} non-zero status for ${HASH} >> ${WORK}/ERROR &&
          ${CAT} ${WORK}/mounts/${HASH}/status >> ${WORK}/ERROR
      elif [ ! -e ${WORK}/mounts/${HASH}/target ]
      then
        ${ECHO} initial did not create target >> ${WORK}/ERROR
      elif [ $( ${FIND} ${WORK}/mounts/${HASH} -mindepth 1 -maxdepth 1 ! -name target | ${SORT} | ${WC} --lines ) != 0 ]
      then
        ${ECHO} initial over created >> ${WORK}/ERROR &&
          ${FIND} ${WORK}/mounts -mindepth 1 -maxdepth 1 ! -name standard-output ! -name standard-error ! -name status ! -name mount | ${SORT} >> ${WORK}/ERROR
      fi
  done