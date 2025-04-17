${FIND} /mount/resources -mindepth 1 -maxdepth 1 -type f -name teardown.sh | while read TEARDOWN
do
  ${TEARDOWN}
done &&
  exec 201> /mount/resources.lock &&
  if ${FLOCK} 201
  then
    if [ $( ${FIND} /mount/resources -mindepth 1 | ${WC} --lines ) == 0 ]
    then
      ${RM} --recursive --force /mount/resources
    fi
  else
    ${ECHO} ${FLOCK_ERROR_MESSAGE} >&2 &&
      exit ${FLOCK_ERROR_CODE}
  fi