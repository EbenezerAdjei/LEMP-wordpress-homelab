# Setup Guide – LEMP + WordPress Homelab

This guide documents a manual production-style deployment of WordPress on a LEMP 
stack (Linux, nginx, MariaDB, PHP-FPM) on Ubuntu Server.

The environment was administered remotely via SSH from macOS.

**Environment**
- OS: Ubuntu Server 26.04 (Resolute)
- Access: SSH from macOS
- Web server: nginx
- Database: MariaDB
- PHP: PHP 8.3 + PHP-FPM
- Application: WordPress (manual installation)

---

## 1. Initial Server Setup

```bash
sudo apt update
sudo apt upgrade -y

sudo apt install -y curl wget git vim nano ufw software-properties-common 
net-tools htop unzip
'''bash

Set a nice hostname (optional but recommended)
sudo hostnamectl set-hostname <HOSTNAME>

ip a

Note the server IP address for later browser access and nginx configuration.


## 2. Install and Configure nginx

'''bash
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl status nginx


Firewall
'''bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
sudo ufw status

Verify the default nginx page is reachable at:
http://YOUR_SERVER_IP


##3. Install and Secure MariaDB

'''bash
sudo apt install -y mariadb-server mariadb-client
sudo systemctl enable mariadb
sudo systemctl status mariadb

Secure the installation:
'''bash
sudo mariadb-secure-installation

Recommended answers:

Enter current password for root → just press Enter (no password yet)
Switch to unix_socket authentication?  n
Set root password: Yes
Remove anonymous users: Yes
Disallow root login remotely: Yes
Remove test database: Yes
Reload privilege tables: Yes

Test login:
'''bash
sudo mariadb


##4. Install PHP and PHP-FPM
NB: Ondřej Surý has shifted from the Launchpad PPA to his primary site at 
packages.sury.org for newer Ubuntu releases like Resolute.

##Step 1: Add the Sury.org Repository for Ubuntu
Run the following commands to add the official key and repository list:
### 1. Install required helper packages
'''bash
sudo apt update
sudo apt install -y ca-certificates apt-transport-https lsb-release wget gnupg2

### 2. Add the Sury repository signing key
'''bash
sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg

### 3. Add the Sury PHP repository source
'''bash
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee 
/etc/apt/sources.list.d/php.list

### 4. Update package lists
'''bash
sudo apt update

##Step 2: Install PHP 8.3 & Extensions
Now that the package list updates cleanly, run your installation command:
'''bash
sudo apt install -y php8.3-fpm php8.3-mysql php8.3-cli php8.3-common php8.3-curl 
php8.3-mbstring php8.3-xml php8.3-zip php8.3-gd php8.3-bcmath php8.3-intl 
php8.3-soap

##Step 3: Verify Installation
Verify that PHP 8.3 and the FPM service are installed properly:
'''bash
php -v
sudo systemctl status php8.3-fpm

Make sure that “expose_php” in the /etc/php/7.2/fpm/php.ini file is set to Off, 
so the php version is not exposed, for security reasons.


##5. Create a Database and Database User
'''bash
sudo mariadb

Inside MariaDB, run these commands one by one (replace the password with a strong 
one):

CREATE DATABASE wordpress_db DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
GRANT ALL PRIVILEGES ON wordpress_db.* TO wordpress_user@localhost IDENTIFIED BY 
'YOUR_DB_PASSWORD';
FLUSH PRIVILEGES;
EXIT;


##6. Deploy WordPress
NB: To setup wordpress on the LEMP/LAMP server usually use these steps:
1. Download and install wordpress on the server
2. Setup and Connect the Database for wordpress
3. Tell Nginx that there is a new website to serve

'''bash
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

sudo mv wordpress /var/www/wordpress
sudo chown -R www-data:www-data /var/www/wordpress
sudo chmod -R 755 /var/www/wordpress


##7. Configure nginx Virtual Host
Create the site configuration and paste the example configuration:
'''bash
sudo nano /etc/nginx/sites-available/wordpress

server {
    listen 80;
    server_name YOUR_SERVER_IP;  # replace with your IP or domain

    root /var/www/wordpress;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.5-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}


Enable the site and reload nginx:
'''bash
sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx


##8. Complete WordPress Installation
Open in a browser:
http://YOUR_SERVER_IP

Use the following database settings in the WordPress installer:

Database name: <ENTER_YOUR_DATABASE_NAME>
Username: <ENTER_YOUR_DATABASE_USER>
Password: <DATABASE_PASSWORD>
Database host: localhost
Table prefix: wp_

Complete the installation and confirm admin login works.

OR you can copy the wp-config-sample.php file (at /var/www/wordpress/) to a new 
file named wp-config.php, open this “wp-config.php” file and modify (as setup in Mariadb) the database 
name, user, password, and generate the new salt.


##9. Harden File Permissions
'''bash
sudo chown -R www-data:www-data /var/www/wordpress
sudo find /var/www/wordpress -type d -exec chmod 755 {} \;
sudo find /var/www/wordpress -type f -exec chmod 644 {} \;
sudo chmod 600 /var/www/wordpress/wp-config.php

Why it matters
After downloading and extracting WordPress, files often have permissions that are 
too open. In a real hosting or production environment, that is a security 
problem. Hardening permissions applies the principle of least privilege: give 
only the access that is required.

Command,                    Purpose
chown -R www-data:www-data, Makes the web server the owner of the files so 
                            WordPress can run correctly

Directories 755,            Allows the server to enter folders and serve content, 
                            but prevents other users from writing to them

Files 644,                  Allows the server to read files, but prevents normal 
                            users from editing them

wp-config.php → 600        Restricts the most sensitive file (database password, 
                            keys) so only the owner can read it




##10. Final Verification
Confirm the expected versions are installed and available
'''bash
php -v
nginx -v
mariadb -v

Confirm all critical services are running right now.
'''bash
sudo systemctl is-active nginx php8.5-fpm mariadb

Confirms the web server is listening on port 80 and MariaDB on port 3306
'''bash
sudo ss -tulnp | grep -E ':80|:3306'




##Skills Demonstrated

Linux server administration via SSH
nginx installation and virtual host configuration
MariaDB database and user management
PHP-FPM integration with nginx
Manual WordPress deployment
Permission hardening and basic security practices
Service management with systemd
Firewall configuration with UFW
