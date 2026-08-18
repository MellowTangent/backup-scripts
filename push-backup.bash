#!/bin/bash
# push-backup.bash
# Pushes local files to a remote backup server via rsync.
# Destination folders are namespaced by hostname and date
# (YYYY-MM/YYYY-MM-DD) so multiple machines can share one
# backup drive without collisions, and each backup gets its
# own granular snapshot without keeping every single day.

# --- CONFIG: Edit the stuff inside the quotation marks according to your system ---
REMOTE_USER="youruser"                        #  username of account associated with machine that is being backed up
REMOTE_HOST="192.168.1.1"                     # replace with your server's IP
REMOTE_DESTINATION="/path/to/backup/drive"    # base backup directory on the server
LOCAL_SOURCE="/path/to/local/folder/"         # what you're backing up (trailing slash matters for rsync)
LOG_FILE="$HOME/push.log"
SSH_KEY="$HOME/.ssh/file_name"
# ----------------------------------------------------------------------------------

month=$(date +"%Y-%m")  # initialize variable with date in the following format: YYYY-MM
day=$(date +"%Y-%m-%d") # initialize variable with date in the following format: YYYY-MM-DD

echo -e "Back-up $HOSTNAME to server?\n"
echo -e "Press 1 for (YES) OR Press 2 for (NO)\n"
read user_input

if [ "$user_input" -eq 1 ]; then
    echo -e "\n- STARTING BACKUP! -\n" # prompt's are for the user and logging.txt file

    start_time=$(date +%s) # record job start time

    # Rsync swtiches and their functions:
    # -a: archive mode (preserves permissions, timestamps, symlinks, recursive)
    # -v: verbose output
    # -h: human-readable sizes
    # -n: test run
    # -e: specifies the remote shell rsync uses to connect
    # --progress: live transfer progress
    # --mkpath: automatically create the full destination path if it doesn't exist
    rsync -avh --progress --mkpath -e "ssh -i $SSH_KEY" "$LOCAL_SOURCE" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DESTINATION}/$HOSTNAME/$month/$day/"

    # Capture rsync's exit code
    rsync_status=$?

    end_time=$(date +%s) # record job end time
    duration=$((end_time - start_time)) # compute job runtime

    # Break total seconds into h/m/s for a readable duration
    hours=$((duration / 3600))
    minutes=$(((duration % 3600) / 60))
    seconds=$((duration % 60))

    if [ $rsync_status -eq 0 ]; then
        echo -e "\n- BACKUP SUCCESSFUL! -"
        echo -e "- Duration: ${hours}h ${minutes}m ${seconds}s -\n"
        echo "$(date '+%Y-%m-%d %H:%M:%S') | SUCCESS | Duration: ${hours}h ${minutes}m ${seconds}s" >> "$LOG_FILE"
    else
        echo -e "\n- BACKUP FAILED! -"
        echo -e "- Duration: ${hours}h ${minutes}m ${seconds}s -\n"
        echo "$(date '+%Y-%m-%d %H:%M:%S') | FAILED | Duration: ${hours}h ${minutes}m ${seconds}s" >> "$LOG_FILE"
    fi
else
    echo -e "\n- BACKUP CANCELLED! -\n"
fi

# The log is structured in a single line so that it is easy to grep/parse later.