# 🚀 Deployment Guide

This guide covers how to set up your production (or staging) server on AWS EC2 and configure automated deployments via GitHub Actions.

## 1. Sever Prerequisites (AWS EC2)

Launch an EC2 instance (Ubuntu 22.04/24.04 recommended) and open the following ports in your Security Group:

- **80** (HTTP)
- **443** (HTTPS)
- **22** (SSH)

### 2. server Setup Script

SSH into your server and run the following commands to install Docker, Docker Compose, and Make.

```bash
# Update and install Docker
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg make git

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine & Compose
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Setup Permissions (avoid using sudo for docker)
sudo usermod -aG docker $USER
# NOTE: You must LOG OUT and log back in for this to take effect!
exit
```

### 3. Initial Project Setup

Log back into your server.

```bash
# Clone the repository
sudo mkdir -p /var/www/laravel
sudo chown -R $USER:$USER /var/www/laravel
cd /var/www/laravel
git clone git@github.com:zubair-sh/laravel.git .
# Or HTTPS: git clone https://github.com/zubair-sh/laravel.git .

# First time setup
make init ENV=production
```

---

## 2. GitHub Actions Secrets

To enable automated deployment, go to your GitHub Repo **Settings** > **Secrets and variables** > **Actions** and add:

### Production Environment

| Secret Name      | Value                                           |
| ---------------- | ----------------------------------------------- |
| `PROD_HOST`      | Public IP of your EC2 instance                  |
| `PROD_USER`      | `ubuntu` (or your user)                         |
| `PROD_SSH_KEY`   | Content of your `.pem` private key              |
| `ENV_PRODUCTION` | **Full content** of your `.env.production` file |

### Staging Environment (Optional)

If you use the `develop` branch:
| Secret Name | Value |
|-------------|-------|
| `STAGING_HOST` | Public IP of Staging EC2 |
| `STAGING_USER` | `ubuntu` |
| `STAGING_SSH_KEY` | Private SSH Key |
| `ENV_STAGING` | **Full content** of `.env.staging` |

---

## 3. How Deployment Works

### Automated (CD)

1.  Push code to **`main`**.
2.  GitHub Action runs tests.
3.  If tests pass:
    - Connects to EC2 via SSH.
    - Updates `.env.production` from Secret.
    - Pulls latest code.
    - Runs `make deploy ENV=production`.

### Manual Deployment

If you need to deploy manually from your machine (requires SSH access configured in config):

```bash
# SSH into server
ssh ubuntu@your-ip

# Go to folder
cd /var/www/laravel

# Deploy
make deploy ENV=production
```

## 4. Troubleshooting

**Logs**

```bash
make logs ENV=production
```

**Database Access**

```bash
make mysql ENV=production
```

**Health Check**

```bash
curl http://localhost/health
```
