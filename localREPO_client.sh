#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "You need to run this script as root."
    exit 1
fi

# Configuration for the local repository
local_repo_server="local_repo_server"  # Replace with the actual server hostname or IP
local_repo_path="/centos_repo"         # Adjust to the correct path on the server
gpg_key_path="/gpg_key.asc"            # Adjust to the correct path on the server

# Create .repo file for the local repository
cat > "/etc/yum.repos.d/local.repo" <<EOF
[local]
name=Local CentOS Repository
baseurl=http://$local_repo_server$local_repo_path
enabled=1
gpgcheck=1
gpgkey=http://$local_repo_server$gpg_key_path
EOF

# Import GPG Key
gpg_key_url="http://$local_repo_server$gpg_key_path"
gpg --import "$gpg_key_url"

# Update yum cache
yum clean all
yum makecache

echo "Client server is now configured to use the local repository for updates."
