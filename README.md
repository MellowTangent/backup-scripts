# Backup Scripts

A self built backup system for keeping files synced across a
home network. It consists of a client side push script and a server side mirror
script. 

## Overview
- **push-backup.bash** — Pushes files to the server via rsync, into a folder named after the machine's hostname and the current date nested     like this: (`hostname/YYYY-MM/YYYY-MM-DD/`). 
  Each backup gets its own snapshot instead of overwriting the last one so you get the level of granularity that you desire with a snapshot     resolution of up to a day.
  The script is manually ran on the machine to be backed up.
- **mirror-backup.bash** — Mirrors the primary backup drive (Drive A) onto a second drive (Drive B), so
  if the primary drive dies (Drive A), there's still a recent copy on the other (Drive B). 
  This script runs automatically every two days as a cronjob and runs on the server itself.

## Requirements
- **Client machine** (push-backup.bash): needs `rsync` and an SSH
  client. Native on Linux/macOS. On Windows, run via WSL — plain
  Windows (cmd/PowerShell) does not ship with rsync.
- **Server machine** (mirror-backup.bash): any Linux box with `rsync`
  installed, and `openssh-server` running.
- **Server machine hardware** — what I run it on: Intel Core i5-6402P (4 cores) @ 3.40GHz, 8GB RAM, two separate physical drives (1TB + 2TB HDD) for the primary/mirror pair. You don't need a monster PC for this — rsync isn't resource intensive, so any low-power x86 box with a couple of spare drives will handle it fine.

