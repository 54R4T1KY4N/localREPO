#!/bin/bash

# Function to add repository configuration for CentOS/RHEL/Fedora
add_rpm_repo() {
    local repo_url="$1"
    local repo_file="/etc/yum.repos.d/local_repo.repo"
    echo "[local_repo]" > "$repo_file"
    echo "name=Local Repository" >> "$repo_file"
    echo "baseurl=$repo_url" >> "$repo_file"
    echo "enabled=1" >> "$repo_file"
    echo "gpgcheck=0" >> "$repo_file"
}

# Function to add repository configuration for Ubuntu/Debian
add_deb_repo() {
    local repo_url="$1"
    local repo_file="/etc/apt/sources.list.d/local_repo.list"
    echo "deb $repo_url /" > "$repo_file"
}

# Function to add repository configuration for openSUSE
add_rpm_repo_opensuse() {
    local repo_url="$1"
    local repo_file="/etc/zypp/repos.d/local_repo.repo"
    echo "[local_repo]" > "$repo_file"
    echo "name=Local Repository" >> "$repo_file"
    echo "baseurl=$repo_url" >> "$repo_file"
    echo "enabled=1" >> "$repo_file"
    echo "gpgcheck=0" >> "$repo_file"
}

# Function to add repository configuration for Amazon Linux
add_rpm_repo_amazon_linux() {
    local repo_url="$1"
    local repo_file="/etc/yum.repos.d/local_repo.repo"
    echo "[local_repo]" > "$repo_file"
    echo "name=Local Repository" >> "$repo_file"
    echo "baseurl=$repo_url" >> "$repo_file"
    echo "enabled=1" >> "$repo_file"
    echo "gpgcheck=0" >> "$repo_file"
}

# Function to detect distribution and add repository configuration accordingly
configure_repo() {
    local server_ip="$1"
    local distro=$(grep -E "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    case "$distro" in
        "centos" | "rhel" | "fedora")
            add_rpm_repo "http://$server_ip/local_repo/$distro/"
            ;;
        "ubuntu" | "debian")
            add_deb_repo "http://$server_ip/local_repo/$distro/"
            ;;
        "opensuse")
            add_rpm_repo_opensuse "http://$server_ip/local_repo/$distro/"
            ;;
        "amzn")
            add_rpm_repo_amazon_linux "http://$server_ip/local_repo/$distro/"
            ;;
        *)
            echo "Unsupported distribution. Exiting."
            exit 1
            ;;
    esac
}

# Main function
main() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        echo "You need to run this script as root."
        exit 1
    fi

    # Prompt user for the Local Repository server's IP address or domain name
    read -p "Enter the IP address or domain name of the Local Repository server: " server_address
    
    # Configure repository for the client system
    configure_repo "$server_address"
    
    # Update package manager cache
    if command -v apt-get &>/dev/null; then
        apt-get update
    elif command -v yum &>/dev/null; then
        yum makecache
    elif command -v zypper &>/dev/null; then
        zypper --gpg-auto-import-keys refresh
    else
        echo "Unsupported package manager. Exiting."
        exit 1
    fi

    echo "Local Repository configuration is complete. You can now install/update packages from the Local Repository."
}

# Call main function
main
