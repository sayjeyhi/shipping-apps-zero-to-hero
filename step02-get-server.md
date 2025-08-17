# Get and Secure Server

## Add a New User

If you want to set up a production ready Server, there are a few steps you should take.
This document goes through the list of steps that I personally take.

## 1. Create a New User with Sudo Permissions
```bash
# Log in as root
ssh root@IP_ADDRESS

# Create a new user
adduser workshop

# Add the user to the sudo group
usermod -aG sudo workshop

# Test the new user
su - workshop
sudo apt update
```
`-aG sudo` means:
Append the user `workshop` to the sudo group without removing them from any other groups they already belong to.


## 2. Set Up SSH Key Authentication

#### LOCAL MACHINE:
```bash
# generate an SSH key pair if you don’t already have one
ssh-keygen -t ed25519 -C "youremail@gmail.com" -f ~/.ssh/workshop_server_key

# Copy the SSH key to the new user on the server
ssh-copy-id -i ~/.ssh/workshop_server_key.pub workshop@IP_ADDRESS

# Test key-based login
ssh -i ~/.ssh/workshop_server_key workshop@IP_ADDRESS
```

After this we should be able to login without password requirement


## Use SSH 
SSH (Secure Shell) is a protocol for securely accessing remote computers. It encrypts the connection, ensuring that data transmitted over the network is secure.
Instead of using passwords, we will use SSH keys for authentication, which is more secure.
```bash
# AUTOMATICALLY COPY SSH KEY TO SERVER
# local machine (generate SSH key if you don't have one):
ssh-keygen -t ed25519 -C "your-email@example.com"
# Copy public key to server
ssh-copy-id root@YOUR_SERVER_IP
```

```bash
# OR MANUALLY
# local machine:
cat ~/.ssh/id_ed25519.pub
# copy the output and paste it into the server
mkdir -p ~/.ssh
echo "your-public-key-here" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

