#!/bin/bash

# This script sets up additional YUM/DNF repositories on your system.
# Be cautious when enabling third-party repositories as they might contain packages that can conflict with the system or introduce security risks.

# WARNING: Only add repositories from trusted sources.
# WARNING: Enabling incompatible repositories can lead to system instability or unexpected behavior.
# WARNING: Regularly update and maintain your repositories to ensure software security.

# Function to provide repository descriptions and warnings
show_repo_description() {
    case "$1" in
        "epel")
            echo "EPEL (Extra Packages for Enterprise Linux) Repository:"
            echo "Description: Provides additional software packages not available in the standard CentOS repositories."
            echo "Warning: Be cautious with packages from EPEL, as they may not be officially supported."
            ;;
        "remi")
            echo "REMI Repository:"
            echo "Description: Offers updated versions of popular software, including PHP."
            echo "Warning: Be aware of compatibility and potential conflicts when using REMI packages."
            ;;
        "rpmfusion")
            echo "RPMFusion Repository:"
            echo "Description: Provides a collection of additional software not available in the standard repositories."
            echo "Warning: Use RPMFusion packages carefully, as they may not be tested with CentOS."
            ;;
        "elrepo")
            echo "ELRepo Repository:"
            echo "Description: Offers additional hardware support, drivers, and software for Enterprise Linux."
            echo "Warning: Use ELRepo packages specifically for hardware support and avoid conflicts."
            ;;
        "nux-dextop")
            echo "NUX-dextop Repository:"
            echo "Description: Focuses on multimedia software and libraries."
            echo "Warning: Use NUX-dextop for multimedia needs, but be cautious with other software."
            ;;
        "ghettoforge")
            echo "GhettoForge Repository:"
            echo "Description: Provides various software packages not available in CentOS."
            echo "Warning: GhettoForge may have less strict quality control, use with caution."
            ;;
        "psychotic-ninja")
            echo "Psychotic Ninja Repository:"
            echo "Description: Offers software packages with specific optimizations and additional features."
            echo "Warning: Use Psychotic Ninja packages if you require specialized optimizations."
            ;;
        "ius-community")
            echo "IUS Community Repository:"
            echo "Description: Offers updated versions of various software packages, including Python, MySQL, and more."
            echo "Warning: Be cautious with IUS packages, especially if they conflict with standard CentOS packages."
            ;;
        "webtatic")
            echo "Webtatic Repository:"
            echo "Description: Provides updated versions of PHP, MySQL, and other web-related software."
            echo "Warning: Use Webtatic if you need updated web-related packages but be aware of potential conflicts."
            ;;
        *)
            echo "Invalid repository option. Exiting."
            exit 1
            ;;
    esac
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "You need to run this script as root."
    exit 1
fi

# Detect package manager
if command -v dnf &>/dev/null; then
    package_manager="dnf"
elif command -v yum &>/dev/null; then
    package_manager="yum"
else
    echo "This script requires either 'dnf' or 'yum' package manager."
    exit 1
fi

# Function to add a custom repo
add_custom_repo() {
    read -p "Enter the base URL of the custom repository: " custom_baseurl
    read -p "Enter the GPG key URL for the custom repository: " custom_gpgkey
    repo_name="Custom"
    baseurl=$custom_baseurl
    gpgkey=$custom_gpgkey
}

# Function to add a known repo
add_known_repo() {
    case "$1" in
        "epel")
            baseurl="https://mirror.centos.org/centos/\$releasever/epel/\$basearch/"
            gpgkey="https://mirror.centos.org/centos/RPM-GPG-KEY-EPEL-7"
            repo_name="EPEL"
            show_repo_description "epel"
            ;;
        "remi")
            baseurl="http://rpms.remirepo.net/enterprise/\$releasever/remi/\$basearch/"
            gpgkey="http://rpms.remirepo.net/RPM-GPG-KEY-remi"
            repo_name="REMI"
            show_repo_description "remi"
            ;;
        "rpmfusion")
            baseurl="https://download1.rpmfusion.org/free/el/\$releasever/\$basearch/"
            gpgkey="https://download1.rpmfusion.org/RPM-GPG-KEY-rpmfusion-free-el"
            repo_name="RPMFusion"
            show_repo_description "rpmfusion"
            ;;
        "elrepo")
            baseurl="https://elrepo.org/linux/\$releasever/\$basearch/"
            gpgkey="https://elrepo.org/RPM-GPG-KEY-elrepo.org"
            repo_name="ELRepo"
            show_repo_description "elrepo"
            ;;
        "nux-dextop")
            baseurl="http://li.nux.ro/download/nux/dextop/el\$releasever/\$basearch/"
            gpgkey="http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro"
            repo_name="NUX-dextop"
            show_repo_description "nux-dextop"
            ;;
        "ghettoforge")
            baseurl="http://mirror.symnds.com/distributions/gf/el/\$releasever/\$basearch/"
            gpgkey="http://mirror.symnds.com/distributions/gf/RPM-GPG-KEY-gf"
            repo_name="GhettoForge"
            show_repo_description "ghettoforge"
            ;;
        "psychotic-ninja")
            baseurl="https://packages.psychotic.ninja/7/base/\$basearch/"
            gpgkey="https://packages.psychotic.ninja/RPM-GPG-KEY-psychotic"
            repo_name="Psychotic Ninja"
            show_repo_description "psychotic-ninja"
            ;;
        "ius-community")
            baseurl="https://repo.ius.io/7/\$basearch/"
            gpgkey="https://repo.ius.io/RPM-GPG-KEY-IUS-7"
            repo_name="IUS Community"
            show_repo_description "ius-community"
            ;;
        "webtatic")
            baseurl="https://mirror.webtatic.com/yum/el7/\$basearch/"
            gpgkey="https://mirror.webtatic.com/yum/RPM-GPG-KEY-webtatic-el7"
            repo_name="Webtatic"
            show_repo_description "webtatic"
            ;;
        "custom")
            add_custom_repo
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
}

# Prompt user to choose a known repository
echo "Choose one known repository (or 'custom' to add a custom repository):"
echo "1) EPEL (Extra Packages for Enterprise Linux)"
echo "2) REMI Repository"
echo "3) RPMFusion Repository"
echo "4) ELRepo Repository"
echo "5) NUX-dextop Repository"
echo "6) GhettoForge Repository"
echo "7) Psychotic Ninja Repository"
echo "8) IUS Community Repository"
echo "9) Webtatic Repository"
read -p "Enter your choice (1-9 or 'custom'): " repo_choice

case "$repo_choice" in
    1)
        add_known_repo "epel"
        ;;
    2)
        add_known_repo "remi"
        ;;
    3)
        add_known_repo "rpmfusion"
        ;;
    4)
        add_known_repo "elrepo"
        ;;
    5)
        add_known_repo "nux-dextop"
        ;;
    6)
        add_known_repo "ghettoforge"
        ;;
    7)
        add_known_repo "psychotic-ninja"
        ;;
    8)
        add_known_repo "ius-community"
        ;;
    9)
        add_known_repo "webtatic"
        ;;
    "custom")
        add_custom_repo
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Example commands using the chosen package manager ($package_manager)
echo "Adding packages from the chosen repository ($repo_name)..."
$package_manager install -y httpd createrepo yum-utils gnupg

# Create repository directory
repo_dir="/var/www/html/local_repo"
mkdir -p "$repo_dir"

# Download CentOS Packages and Updates
reposync -g -l -d -m --repoid=base --repoid=updates --download_path="$repo_dir"

# Generate repository metadata
createrepo "$repo_dir"

# Generate GPG key for signing
gpg_key_name="LocalRepo Key"
gpg_key_email="localrepo@example.com"
gpg_key_passphrase="preferred_passphrase"

gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 2048
Name-Real: $gpg_key_name
Name-Email: $gpg_key_email
Expire-Date: 0
Passphrase: $gpg_key_passphrase
EOF

gpg_key_id=$(gpg --list-keys "$gpg_key_email" | grep -E -o -m 1 '[0-9A-F]{8}')

# Configure GPG key for the repository
cat > "/etc/yum.repos.d/local.repo" <<EOF
[local]
name=Local Repository
baseurl=file://$repo_dir
enabled=1
gpgcheck=1
gpgkey=file://$repo_dir/gpg_key.asc
EOF

# Export GPG key to the repository directory
gpg --export -a $gpg_key_id > "$repo_dir/gpg_key.asc"

# Configure Apache to serve the GPG key
cat > "/etc/httpd/conf.d/gpg_key.conf" <<EOF
Alias /gpg_key.asc "$repo_dir/gpg_key.asc"

<Directory "$repo_dir">
    Options Indexes FollowSymLinks
    Require all granted
</Directory>
EOF

# Restart Apache
systemctl restart httpd

# Update yum cache
$package_manager clean all
$package_manager makecache

echo "Repository setup is complete. You can now use the local repository by running 'yum update' or 'dnf update' depending on your system."
