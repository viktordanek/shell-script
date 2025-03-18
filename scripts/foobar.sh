UUID=$( ${CAT} /singleton ) &&
  ${ECHO} ${UUID} file | ${SHA512SUM} | ${CUT} --bytes -128 > /singleton/file &&
  ${ECHO} ${UUID} standard.output | ${SHA512SUM} | ${CUT} --bytes -128 &&
  ${ECHO} ${UUID} standard.error | ${SHA512SUM} | ${CUT} --bytes -128 >&2