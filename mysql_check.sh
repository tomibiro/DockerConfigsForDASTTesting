#!/bin/bash

CONTAINER_NAME="mysql"

if [[ $(docker ps --filter "name=$CONTAINER_NAME" --format '{{.Names}}') == "$CONTAINER_NAME" ]]; then
    echo "✅ MySQL container is running: $CONTAINER_NAME"
else
    echo "❌ MySQL container does not run!" >&2
    exit 1 
fi

STATUS=$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null)

if [[ "$STATUS" == "healthy" ]]; then
    exit 0
else
    echo "⚠ MySQL can not be reached or does not exist: $STATUS" >&2
    exit 2
fi