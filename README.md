# Backup Scripts
> **Disclaimer:** These instructions assume you have a certain level of proficiency with computers such as: flashing an ISO onto a USB drive, managing drive partitions/reformats, navigating and running commands on a CLI, running and modifying bash scripts, and general troubleshooting skills if something doesn't work exactly like it does here.

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
   
6. **Schedule `mirror-backup.bash` via cron** on the server run the command `crontab -e` this will open crontab in a text editor (usually the systems default like nano). Then append the following command `0 23 */2 * * /home/youruser/mirror-backup.bash` with the correct path substitution according to your system.  

## Why did I decide to build this?
I rebuilt the whole backup system from scratch to practice bash scripting, system admin fundamentals, CLI fluency, and to design a backup system on my own without following tutorials or asking AI for a step by step process. This implementation was guided by the friction encountered while designing the system piece by piece.

This started as an overhaul to a very simple backup system using a shared network folder using two networked (LAN) Windows machines. The intial backup system was simple and consisted of me manually dragging and dropping folders/files into the shared network folder located in the server machine. This backup method lacked structure, redundancy, and any form of automation. The server machine was already sitting idle in the living room running a copy of Windows XP. Now Windows 11 requires `TPM` (Trusted Platform Module) and the `MSI B150M BAZOOKA PLUS` is an old motherboard (LGA 1151 socket) so Windows 11 was never an option. Thus running an unsupported and insecure OS was part of what pushed me to rebuild the whole system using Linux as the base.

### Design notes
- **Push (client) vs. pull (server) architecture:** The client machine(s) push on-demand rather than the server pulling on a schedule. In my case the client machine is a high end PC so running it 24/7 makes no sense for my use case and thus it pulls when the user feels there are sufficient changes that need backup. A server-side pull job would essentially force me to keep the client machine powered on just for automation's sake, not worth it. It also forces me to have very high capacity drive(s) to store a lot of backups. Push-on-demand means client machines can be turned on or off as they are needed the only downside being that backups are user dependent and not set and forget. 
- **The confirmation prompt in push-backup.bash is intentional friction:** The script asks before it runs anything, rather than just firing off silently. This is not an oversight it is a deliberate checkpoint so a backup never kicks off by accident or in case the user decides to change his mind.
- **Mirror-backup.bash runs automatically:** The server runs on outdated hardware for two reasons: low energy consumption, and because it's what I had lying around. The sync itself needs no human intervention and runs automatically on a set schedule that can be adjusted to your liking. 
- **Month/day nested folder structure:** Balancing storage efficiency with recovery granularity: backups are only pushed when something meaningful actually changed, which naturally avoids wasted, redundant daily snapshots. Pushing on your own schedule also means you can adapt to how much things are actually changing, backing up more often during busy stretches and less during quiet ones.
- **Logging to a single-line, pipe-delimited format:** Logs let you check what happened after each `rsync` run without needing to be present or watching live, especially useful for the mirror job, which runs unattended.

## Author
Hector Rico — [MellowTangent](https://github.com/MellowTangent) · [LinkedIn](https://www.linkedin.com/in/hectorricodev/)
