#!/usr/bin/env bash

set -o errexit

# Delete empty files from /opt/liferay/osgi/configs
find /opt/liferay/osgi/configs -type f -empty -delete
