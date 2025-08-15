## Shipping Apps - Zero to Hero
> Welcome to the Shipping Apps - Zero to Hero course!

If you are here, it means you are participating the `Shipping Apps - Zero to Hero` course, and you are following the steps to set up a production-ready server.


You can start by making sure you have required software installed on your local machine, and you have required accounts created.


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
