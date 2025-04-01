#!/bin/bash

echo "ENTRYPOINT triggered."

if [ -t 1 ]; then
    # Run the provided command in interactive mode
    exec "$@"
fi

# Below will keep the detached daemon alive even the command is finished.
# if [ -t 1 ]; then
#     exec "$@"
# else
#     # Detached mode; keep the container alive even the command is finished.
#     tail -f /dev/null
# fi