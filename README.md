# Backup Scripts
> **Disclaimer:** These instructions assume you have a certain level of proficiency with computers such as: flashing an ISO onto a USB drive, navigating and running commands on a CLI, running and modifying bash scripts, and general troubleshooting skills if something doesn't work exactly like it does here.

A self built backup system for keeping files synced across a
home network. It consists of a client side push script and a server side mirror
script. 
## Overview
- **push-backup.bash** — Pushes `folders/files` to the server with `rsync` via a `ssh` connection to the server. A folder named after the machine's `hostname` and the current `date` is created in the server, nested like this: (`./hostname/YYYY-MM/YYYY-MM-DD/`).<br>
  Each backup gets its own snapshot instead of overwriting the last one so you get the level of granularity that you desire with a snapshot resolution of up to a day.<br>
  The script is manually ran on the machine to be backed up.
- **mirror-backup.bash** — Mirrors the primary backup drive (Drive A) onto a second drive (Drive B) with `rsync`, no `ssh` connection required.
  If the primary drive dies (Drive A), there is still a recent copy on the secondary drive (Drive B).<br> 
  This script runs automatically every two days as a cronjob and runs on the server itself which should be running 24/7.
## Requirements
- **Client machine** (push-backup.bash): Windows or any Linux distribution will do here since all we care about is having access to `rsync` and `openssh-client`. These are native on Linux and makes the setup a lot easier.<br>
  On Windows you need to run them via `WSL` (Windows Subsystem for Linux).<br>
  https://learn.microsoft.com/en-us/windows/wsl/install<br>
  Note: plain Windows (cmd/PowerShell) ships with `ssh` out of the box, but not `rsync`.
- **Server machine** (mirror-backup.bash): Any Linux box with `rsync` and `openssh-server` installed (most Linux distros ship these by default).<br>
  In my case I decided to use Ubuntu because of its ease of use and stability.
- **Server machine specs:**<br>
  OS: Ubuntu 26.04 LTS<br>
  MB: MSI B150M BAZOOKA PLUS<br>
  CPU: Intel Core i5-6402P - Stock Settings & Cooler<br>
  RAM: 8GB DDR4 - Stock<br>
  OS_SSD: 250 GB SSD<br>
  Primary_HDD: 2 TB HDD 7200 rpm<br>
  Secondary_HDD: 1 TB HDD 7200 rpm<br>
  PSU: EVGA Supernova G2 550W<br>

  Note: You can consolidate OS_SSD and Primary_HDD into one drive if you lack the necessary amount of drives but at minimum two drives are needed for backup redundancy. As you can see we do not need a monster PC for this, so any old PC/laptop with a couple of spare drives will handle the job fine.
- **Client machine specs:**<br>
  OS: Any Linux Distribution or Windows running `WSL`<br>
  
  Note: The rest of the systems components don't matter as long as you can run a CLI (command line interface).

## Setup
1. **Install the requirements.** Make sure `rsync` and `openssh-client` are available on each client machine (see Requirements above — Windows users need `WSL` installed first), and that the server has `rsync` and `openssh-server` running.
2. **Clone the repo and copy `push-backup.bash` to each client machine** you want to back up:<br>
   `git clone https://github.com/MellowTangent/backup-scripts.git`
3. **Edit the config block at the top of `push-backup.bash`:**
   - `REMOTE_USER` — the username on the server (`whoami` on the server).
   - `REMOTE_HOST` — your server's IP address (`ip a` or `hostname -I` on the server).
   - `REMOTE_DESTINATION` — the base backup directory on the server.
   - `LOCAL_SOURCE` — the local folder you're backing up (trailing slash matters for rsync).
   - `LOG_FILE` — where this machine's backup log gets written.<br>
   `$HOSTNAME` is pulled automatically from the client machine, no config needed.
4. **Run it manually whenever you want to back up that machine:**
   `./push-backup.bash`<br>
   You'll be prompted to confirm (`1` for yes, `2` for no) before anything runs.
5. **Copy `mirror-backup.bash` to the backup server**, and edit its config block:
   - `PRIMARY_DRIVE` — the main backup drive being mirrored (`lsblk` or `df -h` to find mounted drives).
   - `MIRROR_DRIVE` — the redundant copy destination.
   - `LOG_FILE` — where the mirror job's log gets written.<br>
   
   Note: this script runs with the switch `--delete` meaning files removed from `PRIMARY_DRIVE` are removed from `MIRROR_DRIVE` too on the next run, not just added to. In essence `MIRROR_DRIVE` is a perfect copy of `PRIMARY_DRIVE` and is not a cumulative copy of all the changes. 
6. **Schedule `mirror-backup.bash` via cron** on the server, e.g.:
   `0 23 */2 * * /path/to/mirror-backup.bash`
