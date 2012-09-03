#!/usr/bin/env bash

CMPR_CMD="yui"
SHEETS=('pagehub' 'settings' 'skins/light' 'skins/dark')

# Verify all the sheets exist before we do anything
for sheet in ${SHEETS[@]}; do
  if [ ! -f "${sheet}.css" ]; then
    echo "Script ${sheet} does not exist. [ ERROR ]"
    exit 1
  fi
done

# Compress the files and combine them as we go
for sheet in ${SHEETS[@]}; do
  TMP_IN="${sheet}.css"
  TMP_OUT="${sheet}.min.css"

  echo "Compressing sheet: ${TMP_IN} to ${TMP_OUT}"
  if [ -f "${TMP_OUT}" ]; then
    rm ${TMP_OUT}
  fi

  ${CMPR_CMD} ${TMP_IN} -o ${TMP_OUT}

  ORIG_SZ=`stat -c %s ${TMP_IN}`
  CMPR_SZ=`stat -c %s ${TMP_OUT}`
  let "CMPR_DIFF=${ORIG_SZ}-${CMPR_SZ}"

  echo "  Sheet compressed from ${ORIG_SZ}b to ${CMPR_SZ}b (${CMPR_DIFF}b bytes reduced)"
done
