#!/usr/bin/env bash

set -o errexit

source /mnt/liferay/scripts/_common.sh

LCP_SECRET_DATABASE_NAME="${LCP_SECRET_DATABASE_NAME:-lportal}"

main() {
    if [[ "${LOCAL_STACK}" == "true" ]]
    then
      return
    fi

    heapdump_dir="${LIFERAY_HOME}/data/heap-dump/"

    # If the heapdump directory does not exist, create it
    if [ ! -d "${heapdump_dir}" ]; then
        echo "[SaaS] Heapdump directory does not exist. Creating it now."
        echo "[SaaS] Creating heapdump directory: ${heapdump_dir}"
        mkdir -p "${heapdump_dir}"

    # If the heapdump directory exists, delete files older than 10 days
    elif [ -d "${heapdump_dir}" ]; then
        echo "[SaaS] Started the cleanup process"

        old_dumps=$(find "$heapdump_dir" -type f -mtime +10)

        for old_dump in $old_dumps
        do
            echo "[SaaS] Removing: ${old_dump}"
            rm "$old_dump"
        done

        echo "[SaaS] Finished the cleanup process"
    fi
}

main "$@"