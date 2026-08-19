# Rsync Based Home Network Backup System

> **Disclaimer** — These instructions assume you have an intermediate level of proficiency. You should be familiar with flashing an ISO onto a USB drive, managing drive partitions/reformats, navigating and running commands on a CLI (command line interface), running and modifying bash scripts, setting up ssh keys, and general troubleshooting skills.

> **AI Use** — Built and debugged this myself Claude was used as a glorified spell checker and to brainstorm design choices.

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
  On Windows you need to run them via `WSL` (Windows Subsystem for Linux). [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)<br>
  Note: plain Windows (cmd/PowerShell) ships with `ssh` out of the box, but not `rsync`.
- **Server machine** (mirror-backup.bash): Any Linux box with `rsync` and `openssh-server` installed (most Linux distros ship these by default).<br>
  In my case I decided to use Ubuntu because of its ease of use and stability. [Ubuntu](https://ubuntu.com/download)<br>
- **Client machine specs:**<br>
  OS: Any Linux Distribution or Windows running `WSL`<br>
  
  Note: The rest of the computer's components don't matter as long as you can run a CLI.
- **Server machine specs:**<br>
  OS: Ubuntu 26.04 LTS<br>
  MB: MSI B150M BAZOOKA PLUS<br>
  CPU: Intel Core i5-6402P - Stock Settings & Cooler<br>
  RAM: 8GB DDR4 - Stock<br>
  OS_SSD: 250 GB SSD<br>
  Primary_HDD: 2 TB HDD 7200 rpm<br>
  Secondary_HDD: 1 TB HDD 7200 rpm<br>
  PSU: EVGA Supernova G2 550W<br>

  Note: You can consolidate OS_SSD and Primary_HDD into one drive if you lack the necessary amount of drives but at minimum two drives are needed for backup redundancy. Technically you can use one drive and partition it into smaller chunks but that removes drive redundancy which we want. As you can see any old PC with a couple of spare drives will handle the job just fine.

## Setup
1. **Install the requirements** (Windows users need `WSL` installed first)<br> 
Open the terminal in preferred Linux Distro or use `WSL` if on Windows and use the commands `whereis ssh` and `whereis rsync` on each machine (client and server) to make sure `ssh` and `rsync` are installed, otherwise install them via:<br>
   `sudo apt update`<br>
   `sudo apt install openssh-client openssh-server rsync`<br>
   
   Note: this installs everything needed regardless of the machine's role. The two commands work on both client and server machines.<br>
   On the server, confirm `sshd` is running with `sudo systemctl status ssh`, and if it's not, start it with `sudo systemctl enable --now ssh`.
2. **Clone the repo to get `push-backup.bash`**<br>
   Run the following command on both the client and server computers to copy the scripts to your home directory: `cd ~ && git clone https://github.com/MellowTangent/backup-scripts.git`
3. **Open and edit `push-backup.bash`** (Only edit the strings inside the double quotation marks at the very top of the script)<br>
   Run the following command on the client computer: `cd ~/backup-scripts && nano push-backup.bash`<br>
   Fields to edit:<br>
   - `REMOTE_USER` — the username on the server (`whoami` on the server).
   - `REMOTE_HOST` — your server's IP address (`ip a` or `hostname -I` on the server).
   - `REMOTE_DESTINATION` — the path of the backup directory on the server. Run `df -h` on the server to see mounted paths.
   - `LOCAL_SOURCE` — the local path of the folder or file you're backing up (trailing slash matters for rsync). Run `df -h` to see mounted paths (use column 6: Mounted on, for correct path and use the same forward slash format for the rest of the path). Note: if you're on Windows via `WSL`, your Windows drives are mounted under `/mnt/`, e.g. your C: drive is `/mnt/c/`, not `/c/` or `C:\`.
   - `LOG_FILE` — where this machine's backup log gets written.<br>
   `$HOSTNAME` is pulled automatically from the client machine, no config needed.<br>
   - `SSH_KEY` — The locaion where you can find your ssh keys usually under home/user/.ssh/<br>

   To save the script and exit the editor press: `Ctrl + O` then `Enter` to confirm, then `Ctrl + X` to exit.
4. **Run `push-backup.bash` manually to backup client machine**<br>
   We want to make the script executable so run the command: `chmod 700 push-backup.bash`<br>
   Run this command to run the script `./push-backup.bash`<br> 
   You'll be prompted to confirm (`1` for yes, `2` for no) before anything runs.<br>
   You will see a bunch of stuff running in the terminal, and either `BACKUP SUCCESSFUL!` or `BACKUP FAILED!` — both outcomes get logged to a text file in your home directory.
5. **Open and edit `mirror-backup.bash`** (Only edit the strings inside the double quotation marks at the very top of the script)<br>
   Run the following command on the server computer: `cd ~/backup-scripts && nano mirror-backup.bash`<br>
   Fields to edit:<br>
   - `PRIMARY_DRIVE` — the path of the main backup drive being mirrored (`lsblk` or `df -h` to find mounted drives).
   - `MIRROR_DRIVE` — the path of the redundant copy destination.
   - `LOG_FILE` — where the mirror job's log gets written.<br>
   To save the script and exit the editor press: `Ctrl + O` then `Enter` to confirm, then `Ctrl + X` to exit.<br>
  We want to make the script executable so run the command `chmod 700 mirror-backup.bash`
   
   Note: this script runs with the switch `--delete` meaning files removed from `PRIMARY_DRIVE` are removed from `MIRROR_DRIVE` too on the next run, not just added to. In essence `MIRROR_DRIVE` is a perfect copy of `PRIMARY_DRIVE` and is not a cumulative copy of all the changes. 
   
6. **Schedule `mirror-backup.bash`.** On the server computer run the command `crontab -e`; this will open crontab in a text editor (usually the system's default like nano). Then append the following command at the VERY END of the file `0 23 */2 * * /home/youruser/mirror-backup.bash` with the correct path substitution according to your system.  

## Why did I decide to build this?
I rebuilt my entire backup system so I could practice bash scripting, system administration, CLI fluency, and to design a backup system driven by my own logic and needs. This implementation was guided by the friction encountered while designing the system bit by bit. The project started as a simple one liner command that was run whenever `rsync -avh --progress "/path/to/local/folder/" "youruser@your.server.ip:/path/to/backup/destination/"`.

The project slowly evolved into an extensive overhaul of a very simple backup system. The initial backup system consisted of me manually dragging and dropping folders/files into a shared network folder located in the server running a copy of Windows XP. This backup method lacked structure, redundancy, automation, and security. Thus the need for something more robust, interactive, with built in redundancy.

### Design notes
- **Why Linux instead of Windows for the server?** the server's motherboard (`MSI B150M BAZOOKA PLUS`, LGA 1151 socket) doesn't support `TPM` (Trusted Platform Module), which Windows 11 requires to install. That ruled out running the latest Windows on this hardware entirely, and was a big part of why Linux made sense here.
- **Why not a true headless Ubuntu server?** This was my first time running a full Linux distro on its own drive, not as a partition or a USB ISO, and administering it almost entirely through the CLI over an SSH connection. I wanted the familiarity of a GUI as a fallback while I got comfortable with that, and there are some applications I'll be installing down the line that only have a GUI.
- **Push (client) vs. pull (server) architecture:** The client machine(s) push on-demand rather than the server pulling on a schedule. In my case the client machine is a high end PC so running it 24/7 makes no sense for my use case and thus it pulls when the user feels there are sufficient changes that need backup. A server-side pull job would essentially force me to keep the client machine powered on just for automation's sake, not worth it. It also forces me to have very high capacity drive(s) to store a lot of backups. Push-on-demand means client machines can be turned on or off as they are needed the only downside being that backups are user dependent and not set and forget. 
- **The confirmation prompt in push-backup.bash is intentional friction:** The script asks before it runs anything, rather than just firing off silently. This is not an oversight it is a deliberate checkpoint so a backup never kicks off by accident or in case the user decides to change their mind.
- **Mirror-backup.bash runs automatically:** The server runs on outdated hardware for two reasons: low energy consumption, and because it's what I had lying around. The sync itself needs no human intervention and runs automatically on a set schedule that can be adjusted to your liking. 
- **Month/day nested folder structure:** Balancing storage efficiency with recovery granularity: backups are only pushed when something meaningful actually changed, which naturally avoids wasted, redundant daily snapshots. Pushing on your own schedule also means you can adapt to how much things are actually changing, backing up more often during busy stretches and less during quiet ones.
- **Logging to a single-line, pipe-delimited format:** Logs let you check what happened after each `rsync` run without needing to be present or watching live, especially useful for the mirror job, which runs unattended.
- **Security:** The server didn't have any firewalls deployed initially, to avoid `ssh` connectivity issues while the backup implementation was still being built out. Once the implementation was rock solid, firewalls were activated on the server.
- **SSH hardening:** Password authentication was replaced with SSH key-based auth across all client machines (each with its own dedicated key), and `PermitRootLogin no` was set to disable direct root login over SSH, closing off a common brute-force target entirely.
- **Future improvements:** Creating a 'Restore" script that pulls backups from the server machine. Create a consolidated backup script that combines both a backup and restore function. 

## Author
Hector Rico — [MellowTangent](https://github.com/MellowTangent) · [LinkedIn](https://www.linkedin.com/in/hectorricodev/)
