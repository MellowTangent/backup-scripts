# Backup Scripts
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
  On Windows you need to run them via WSL (Windows Subsystem for Linux).<br>
  https://learn.microsoft.com/en-us/windows/wsl/install<br>
  Note: plain Windows (cmd/PowerShell) ships with `ssh` out of the box, but not `rsync`.
- **Server machine** (mirror-backup.bash): Any Linux box with `rsync` and `openssh-server` installed (most Linux distros ship these by default).<br>
  In my case I decided to use Ubuntu because of its ease of use and stability.
- **Server machine specs:**<br>
  OS: Ubuntu 26.04 LTS
  MB: MSI B150M BAZOOKA PLUS<br>
  CPU: Intel Core i5-6402P - Stock Settings & Cooler<br>
  RAM: 8GB DDR4 - Stock<br>
  OS_SSD: 250 GB SSD<br>
  Primary_HDD: 2 TB HDD 7200 rpm<br>
  Secondary_HDD: 1 TB HDD 7200 rpm<br>
  PSU: EVGA Supernova G2 550W<br>
  
Note: You can consolidate OS_SSD and Primary_HDD into one drive if you lack the necessary amount of drives but at minimum two drives are needed for backup redundancy. As you can see we do not need a monster PC for this, so any old PC/laptop with a couple of spare drives will handle the job fine.
