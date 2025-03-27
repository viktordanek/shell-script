exec 201> ${RESOURCE}.lock &&
  if ${FLOCK} 201
  then
    if [ ${STATUS} == 0 ]
    then
      ${TAIL} --follow /dev/null --pid ${ORIGINATOR_PID}
    fi &&
    if ${RELEASE} > ${RESOURCE}/release.standard-output 2> ${RESOURCE}/release.standard-error
    then
      STATUS=${?}
    else
      STATUS=${?}
    fi &&
    ${ECHO} ${STATUS} > ${RESOURCE}/release.status &&
    ${CHMOD} 0400 ${RESOURCE}/release.standard-output ${RESOURCE}/release.standard-error ${RESOURCE}/release.status &&
    ( ${POST} || ${TRUE} ) &&
    ${RM} ${RESOURCE}.lock
  else
    ${ECHO} FAILED TO LOCK ${RESOURCE}.lock >&2 &&
      exit ${LOCK_FAILURE}
  fi

