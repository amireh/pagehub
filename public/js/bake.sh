#!/usr/bin/env bash

UGLIFY_CMD="uglifyjs -nc"

SCRIPTS=('jqModal' 'shortcut' 'dynamism' 'pagehub' 'pagehub_ui')
DEST="ugly"
COMBINED="${DEST}/all.js"

# Verify all the scripts exist before we do anything
for script in ${SCRIPTS[@]}; do
  if [ ! -f "${script}.js" ]; then
    echo "Script ${script} does not exist. [ ERROR ]"
    exit 1
  fi
done

if [ -f ${COMBINED} ]; then
  echo "Removing existing file: ${COMBINED}"
  rm ${COMBINED}
fi

# Compress the files and combine them as we go
for script in ${SCRIPTS[@]}; do
  TMP_IN="${script}.js"
  TMP_OUT="${DEST}/${script}.js"

  echo "Compressing and adding script: ${TMP_IN}"
  if [ -f "${TMP_OUT}" ]; then
    rm ${TMP_OUT}
  fi

  ${UGLIFY_CMD} ${TMP_IN} > ${TMP_OUT}
  cat ${TMP_OUT} >> ${COMBINED}

  ORIG_SZ=`stat -c %s ${TMP_IN}`
  CMPR_SZ=`stat -c %s ${TMP_OUT}`
  let "CMPR_DIFF=${ORIG_SZ}-${CMPR_SZ}"

  echo "  Script compressed from ${ORIG_SZ}b to ${CMPR_SZ}b (${CMPR_DIFF}b bytes reduced)"
done

COMBINED_SZ=`stat -c %s ${COMBINED}`
echo "Generated: ${COMBINED}, filesize: ${COMBINED_SZ}"
