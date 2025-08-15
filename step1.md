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
