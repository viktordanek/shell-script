export RESOURCE=$( ${MKTEMP} --directory ) &&
  source ${MAKE_WRAPPER}/nix-support/setup-hook &&
  ${ECHO} ${@} > ${RESOURCE}/arguments &&
  #
  if ${HAS_STANDARD_INPUT}
  then
    ${ECHO} ${STANDARD_INPUT} > ${RESOURCE}/standard-input &&
      ${CHMOD} 0400 ${RESOURCE}/standard-input
      if ${CAT} ${RESOURCE}/standard-input ${INIT} $( ${CAT} ${RESOURCE}/arguments ) > ${RESOURCE}/init.standard-output 2> ${RESOURCE}/init.standard-error
      then
        STATUS=${?}
      else
        STATUS=${?}
      fi
  else
    if ${INIT} $( ${CAT} ${RESOURCE}/arguments ) > ${RESOURCE}/init.standard-output 2> ${RESOURCE}/init.standard-error
    then
      STATUS=${?}
    else
      STATUS=${?}
    fi
  fi &&
  ${ECHO} ${?} > ${RESOURCE}/init.status &&
  ${CHMOD}
   0400 ${RESOURCE}/init.standard-output ${RESOURCE}/init.standard-error ${RESOURCE}/init.status &&
  #
  #
  ${MAKE_WRAPPER_TEARDOWN} ${TEARDOWN} ${RESOURCE}/teardown.sh --set ORIGINATOR_PID ${ORIGINATOR_PID} --set RESOURCE ${RESOURCE} --set STATUS ${STATUS} &&
  ( ${RESOURCE}/teardown}.sh & ) &&
  if [ ${STATUS} != 0 ]
  then
    ${ECHO} ${RESOURCE} &&
      exit ${INIT_NONZERO_EXIT}
  elif [ ! -z $( ${CAT} ${RESOURCE}/init.standard-error ) ]
  then
      ${ECHO} ${RESOURCE} &&
        exit ${INIT_STDERR_PRESENT}
  else
      ${ECHO} ${RESOURCE}/target &&
  fi

