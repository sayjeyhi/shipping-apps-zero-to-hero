

## 🔐 Accounts

- **GitHub** (To publish docker images)
- **Cloudflare** (DNS)
- **Server provider** (Hetzner, DigitalOcean)
- **Domain**
  - your domain connected to cloudflare
  - OR I will give you a sub domain
  - https://XX.iwaskidding.com/

## 💻 Required Tools

- **SSH client + terminal** (mac default terminal has it)
- **Git** (mac default terminal has it)
- **Docker** (preferably OrbStack)
- **Editor** (vscode, cursor, etc)


## 🎯 Optional

- **Docker Hub** account




# Review linux base commands

### Add a user
```bash
adduser NAME
```
add info and password. Then get user info:

```bash
id NAME
```
this will show access and we can see user has no `sudo` access.
then we will add access with:
```bash
usermod -aG sudo NAME
```

### Switch user
```bash
su - NAME
```
check if changed:
```bash
whoami
```
we can logout with `exit`

### Create ssh key access to a new user
```bash
mkdir .ssh
chmod 700 ~/.ssh
```
then we should add keys:
```bash
nano ~/.ssh/unauthorized_keys
```
use copy SSH public key to this file and save it:
```bash
pbcopy < ~/.ssh/id_rsa.pub
```
then we need to change access to this file:
```bash
chmod 600 ~/.ssh/unauthorized_keys
```


### Server ssh config
```bash
nano ~/etc/ssh/sshd_config

# press ctrl+w to search
# remove root access, and login by password
PermitRootLogin=No
PasswordAuthentication=No
```
then we need to restart `systemctl`:
```bash
sudo systemctl reload sshd
```
then we can test and see we can not login as root.


### Set up basics firewall
we will use `ufw` tool which is pre-installed on Ubuntu servers.
```bash
sudo ufw allow OpenSSH
sudo ufw allow http
sudo ufw allow https

# apply stuff
sudo ufw enable

# see what we have
sudo ufw status
```


### Run the same command with sudo
```bash
sudo !!
```


### Crontab
```bash
sudo crontab -e
```
then use `nano` to edit it and add new stuff there. like this one for reinstalling SSL every Monday and storing log there:
```bash
00 1 * * 1 /opt/letsencrypt/certbot-auto renew >> /var/log/letsencrypt-renewal.log
30 1 * * 1 /bin/systemctl reload nginx
```

### Sudo
Add sudo access to a user
```
sudo chown -R <your-username> folder/file
```


### Install VirtualBox (optional)

VirtualBox is a free and open-source hypervisor for x86 virtualization, allowing you to run multiple operating systems on your Mac.
https://download.virtualbox.org/virtualbox/7.1.12/VirtualBox-7.1.12-169651-macOSArm64.dmg

Create a Ubuntu linux server and open it.
Check the IP address of your server:


```bash
ip -br a
```

Allow network access to your server by opening the necessary ports in your firewall. You can use UFW (Uncomplicated Firewall) to manage your firewall rules.

```bash
sudo ufw allow ssh

sudo apt update
sudo apt install openssh-server
```


# Server Setup

If you want to set up a production ready Server, there are a few steps you should take.

This document goes through the list of steps that I personally take.


## 1. Create a New User with Sudo Permissions
```bash
# Log in as root
ssh root@IP_ADDRESS

# Create a new user
adduser test

# Add the user to the sudo group
usermod -aG sudo test

# Test the new user
su - test
sudo apt update
```
`-aG sudo` means:
Append the user test to the sudo group without removing them from any other groups they already belong to.


## 2. Set Up SSH Key Authentication

#### LOCAL MACHINE:
```bash
# generate an SSH key pair if you don’t already have one
ssh-keygen -t ed25519 -C "youremail@gmail.com" -f ~/.ssh/test_server_key

# Copy the SSH key to the new user on the server
ssh-copy-id -i ~/.ssh/test_server_key.pub test@IP_ADDRESS

# Test key-based login
ssh -i ~/.ssh/test_server_key test@IP_ADDRESS
```

After this we should be able to login without password requirement
