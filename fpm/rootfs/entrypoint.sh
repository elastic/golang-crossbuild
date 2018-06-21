#!/usr/bin/env sh

if [ -z ${EXEC_UID+x} ] || [ -z ${EXEC_GID+x} ]; then
  exec "$@"
fi

groupadd -f -g "$EXEC_GID" fpm
useradd -N -m -c 'FPM User' -u "$EXEC_UID" -g "$EXEC_GID" fpm

su-exec fpm "$@"
