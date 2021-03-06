#!/bin/bash
# Usage: (verify debconf preseed answers) ./app-preinstall.sh
# Update the debconf preseed questions at the bootom of the 
# script and the location of the app deb package to install
set -e

if [ -r /lib/lsb/init-functions ]; then
    if [ "$( lsb_release -is )" = "Debian" ]; then
        distro="$( lsb_release -c )"
    else
        distro="$( lsb_release -c | cut -f 2 )"
    fi
fi

add_tor_repo() {

    # Check for and add the tor signing key source and packages
    TOR_KEY_ID="886DDD89"
    TOR_KEY_FPR="A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89"

    if [ ! "$(gpg -q --list-key $TOR_KEY_ID 2> /dev/null)" ]; then
        gpg -q --keyserver keys.gnupg.net --recv $TOR_KEY_ID
        gpg -q --export $TOR_KEY_FPR | apt-key add -
    fi

    # Add the tor repo to the sources list and update the system
    if [ ! -f /etc/apt/sources.list.d/tor.list ]; then
        echo "deb     http://deb.torproject.org/torproject.org $distro main" > /etc/apt/sources.list.d/tor.list
    fi
}

add_tor_repo

apt-get update
apt-get install gdebi -y

# Sample app server debconf preseed questions/answers for vagrant dev environment
debconf-set-selections << EOF
securedrop-app-interfaces-0.2.1-amd64.deb securedrop-app-interfaces/prod_dev boolean false
securedrop-app-interfaces-0.2.1-amd64.deb securedrop-app-interfaces/source_deb string /vagrant/source-0.2.1-amd64.deb
securedrop-app-interfaces-0.2.1-amd64.deb securedrop-app-interfaces/document_deb string /vagrant/document-0.2.1-amd64.deb
securedrop-app-interfaces-0.2.1-amd64.deb securedrop-app-interfaces/find_key_path string /vagrant/securedrop/test_journalist_key.pub
securedrop-app-interfaces-0.2.1-amd64.deb securedrop-app-interfaces/verify_fingerprint boolean true
securedrop-app-interfaces-0.2.1-amd64.deb securedrop-app-interfaces/journalist_user string journo1
securedrop-app-interfaces-0.2.1-amd64.deb securedrop-app-interfaces/use_custom_header_image boolean false
securedrop-app-hardening-0.2.1-amd64.deb securedrop-app-hardening/admin_user string vagrant
securedrop-app-ossec-0.2.1-amd64.deb securedrop-app-ossec/monitor_ip string CHANGEME
EOF

gdebi --non-interactive /vagrant/app-interfaces-0.2.1-amd64.deb
gdebi --non-interactive /vagrant/app-hardening-0.2.1-amd64.deb
gdebi --non-interactive /vagrant/app-ossec-0.2.1-amd64.deb
