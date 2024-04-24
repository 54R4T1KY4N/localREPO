#!/bin/bash

# Function to install necessary packages
install_packages() {
    local distro="$1"
    case "$distro" in
        "centos" | "rhel" | "amazon_linux")
            yum install -y httpd createrepo yum-utils firewalld openssl || { echo "Error: Failed to install packages. Exiting."; exit 1; }
            systemctl enable --now httpd firewalld || { echo "Error: Failed to start services. Exiting."; exit 1; }
            ;;
        "ubuntu" | "debian")
            apt-get update
            apt-get install -y apache2 createrepo firewalld openssl || { echo "Error: Failed to install packages. Exiting."; exit 1; }
            systemctl enable --now apache2 ufw || { echo "Error: Failed to start services. Exiting."; exit 1; }
            ;;
        "opensuse" | "fedora")
            zypper install -y apache2 createrepo firewalld openssl || { echo "Error: Failed to install packages. Exiting."; exit 1; }
            systemctl enable --now apache2 firewalld || { echo "Error: Failed to start services. Exiting."; exit 1; }
            ;;
        *)
            echo "Unsupported distribution. Exiting."
            exit 1
            ;;
    esac
}

# Function to configure firewall
configure_firewall() {
    local distro="$1"
    case "$distro" in
        "centos" | "rhel" | "amazon_linux")
            firewall-cmd --zone=public --add-service=http --permanent || { echo "Error: Failed to configure firewall. Exiting."; exit 1; }
            firewall-cmd --reload || { echo "Error: Failed to reload firewall rules. Exiting."; exit 1; }
            ;;
        "ubuntu" | "debian" | "opensuse" | "fedora")
            ufw allow "Apache Full" || { echo "Error: Failed to configure firewall. Exiting."; exit 1; }
            ufw reload || { echo "Error: Failed to reload firewall rules. Exiting."; exit 1; }
            ;;
    esac
}

# Function to sync repository
sync_repo() {
    local distro="$1"
    local repo_dir="$2"
    local repos_to_sync=("$3")
    case "$distro" in
        "centos" | "rhel" | "amazon_linux" | "fedora")
            for repo in "${repos_to_sync[@]}"; do
                reposync -g -l -d -m --repoid="$repo" --download_path="$repo_dir" || { echo "Error: Failed to sync repository. Exiting."; exit 1; }
            done
            ;;
        "ubuntu" | "debian")
            for repo in "${repos_to_sync[@]}"; do
                apt-mirror
                mv "/var/spool/apt-mirror/mirror/archive.yourdomain.com/$repo/" "$repo_dir" || { echo "Error: Failed to sync repository. Exiting."; exit 1; }
            done
            ;;
        "opensuse")
            for repo in "${repos_to_sync[@]}"; do
                zypper --non-interactive mirror -c -L -d "$repo_dir" -r "http://download.opensuse.org/distribution/leap/$(lsb_release -sr)/repo/$repo/" || { echo "Error: Failed to sync repository. Exiting."; exit 1; }
            done
            ;;
    esac
}

# Function to configure Apache
configure_apache() {
    local repo_dir="$1"
    local port="$2"
    local ssl_enabled="$3"
    if [ "$ssl_enabled" = true ]; then
        cat > "/etc/apache2/conf-available/local_repo.conf" <<EOF
Listen $port
<VirtualHost *:$port>
    ServerAdmin webmaster@localhost
    DocumentRoot "$repo_dir"

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

    <Directory "$repo_dir">
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
    else
        cat > "/etc/apache2/conf-available/local_repo.conf" <<EOF
Listen $port
<VirtualHost *:$port>
    ServerAdmin webmaster@localhost
    DocumentRoot "$repo_dir"

    <Directory "$repo_dir">
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
    fi
    a2enconf local_repo || { echo "Error: Failed to configure Apache. Exiting."; exit 1; }
    systemctl restart apache2 || { echo "Error: Failed to restart Apache. Exiting."; exit 1; }
}

# Function to generate self-signed SSL certificate
generate_ssl_certificate() {
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/ssl-cert-snakeoil.key -out /etc/ssl/certs/ssl-cert-snakeoil.pem || { echo "Error: Failed to generate SSL certificate. Exiting."; exit 1; }
}

# Function to add a custom repository
add_custom_repo() {
    read -p "Enter the name of the custom repository: " custom_repo_name
    read -p "Enter the base URL of the custom repository: " custom_baseurl
    read -p "Enter the GPG key URL for the custom repository: " custom_gpgkey
    repo_name="$custom_repo_name"
    baseurl="$custom_baseurl"
    gpgkey="$custom_gpgkey"
}

# Main function
main() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        echo "You need to run this script as root."
        exit 1
    fi

    # Prompt user for server IP address or domain name
    read -p "Enter the server's IP address or domain name (e.g., 192.168.1.100 or repo.example.com): " server_address
    
    # List of supported distributions and their repositories
    declare -A distros=(
        ["centos"]="base updates extras epel"
        ["rhel"]="base updates extras"
        ["fedora"]="updates"
        ["ubuntu"]="main universe restricted multiverse"
        ["debian"]="main contrib non-free"
        ["opensuse"]="oss non-oss update"
        ["amazon_linux"]="base updates extras epel"
    )

    # Prompt user for distributions
    chosen_distros=()
    for distro in "${!distros[@]}"; do
        read -p "Do you want to sync repositories for $distro? (yes/no): " choice
        [ "$choice" == "yes" ] && chosen_distros+=("$distro")
    done
    
    # Prompt user for Apache port number
    read -p "Enter the port number for Apache (default is 80): " apache_port
    apache_port=${apache_port:-80}

    # Prompt user for SSL configuration
    read -p "Do you want to enable HTTPS for serving repositories? (yes/no): " enable_https
    if [ "$enable_https" == "yes" ]; then
        ssl_enabled=true
        generate_ssl_certificate
    else
        ssl_enabled=false
    fi

    # Sync repositories for chosen distributions
    for distro in "${chosen_distros[@]}"; do
        repos_to_sync="${distros[$distro]}"
        repo_dir="/var/www/html/local_repo/$distro"
        mkdir -p "$repo_dir"
        
        # Install necessary packages
        echo "Installing necessary packages for $distro..."
        install_packages "$distro"
        
        # Sync repository
        echo "Syncing repositories for $distro..."
        sync_repo "$distro" "$repo_dir" "$repos_to_sync"
        
        # Generate repository metadata
        echo "Generating repository metadata for $distro..."
        createrepo "$repo_dir" || { echo "Error: Failed to generate repository metadata. Exiting."; exit 1; }
        
        # Configure Apache
        echo "Configuring Apache to serve repositories for $distro..."
        configure_apache "$repo_dir" "$apache_port" "$ssl_enabled"
    done

    # Configure firewall
    echo "Configuring firewall to allow HTTP$([ "$ssl_enabled" = true ] && echo "S") traffic..."
    configure_firewall "$distro"

    # Prompt user to add custom repositories
    read -p "Do you want to add custom repositories? (yes/no): " add_custom
    if [ "$add_custom" == "yes" ]; then
        add_custom_repo
        echo "Custom repository '$repo_name' added successfully."
        echo "Base URL: $baseurl"
        echo "GPG Key URL: $gpgkey"
    fi
    
    echo "Local repository setup is complete. You can access it at http$([ "$ssl_enabled" = true ] && echo "s")://$server_address:$apache_port/local_repo."
}

# Call main function
main
