#!/bin/bash
# mirror-backup.bash
# Creates a mirrored copy of the primary backup drive onto a
# second drive, providing redundancy in case the primary
# backup drive fails. Intended to run on a schedule via cron
# on the backup server itself.

# --- CONFIG: Edit the stuff inside the quotation marks according to your system ---
PRIMARY_DRIVE="/path/to/primary/backup/drive/"      # the main backup drive being mirrored
MIRROR_DRIVE="/path/to/mirror/backup/drive/"         # the redundant copy destination
LOG_FILE="$HOME/mirror.log"
# ----------------------------------------------------------------------------------

start_time=$(date +%s) # record job start time

# Rsync switches and their functions:
# -a: archive mode (preserves permissions, timestamps, symlinks, recursive)
# -v: verbose output
# -h: human-readable sizes
# -n: test run
# --delete: remove files from the mirror that no longer exist on the primary,
#           keeping this a true mirror rather than an ever-growing archive
rsync -avh --delete "$PRIMARY_DRIVE" "$MIRROR_DRIVE"

# Capture rsync's exit code immediately, before any other command overwrites $?
rsync_status=$?

end_time=$(date +%s) # record job end time
duration=$((end_time - start_time)) # compute job runtime

# Break total seconds into h/m/s for a readable duration
hours=$((duration / 3600))
minutes=$(((duration % 3600) / 60))
seconds=$((duration % 60))

# After rsync is done obtain how much space (in percent) is left at hard drive PRIMARY_DRIVE and MIRROR_DRIVE
disk1=$(df -h "$MIRROR_DRIVE" | tail -n 1 | awk '{print $5}')
disk2=$(df -h "$PRIMARY_DRIVE" | tail -n 1 | awk '{print $5}')

if [ $rsync_status -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | SUCCESS | Mirror: $disk1 | Primary: $disk2 | Duration: ${hours}h ${minutes}m ${seconds}s" >> "$LOG_FILE"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') | FAILED | Mirror: $disk1 | Primary: $disk2 | Duration: ${hours}h ${minutes}m ${seconds}s" >> "$LOG_FILE"
fi

# The log is structured in a single line so that it is easy to grep/parse later.