#!/bin/sh
set -eu

resolve_dev_user() {
    if [ -n "${DEV_USER:-}" ] && id -u "${DEV_USER}" >/dev/null 2>&1; then
        printf '%s\n' "${DEV_USER}"
        return
    fi

    if [ -f /etc/default/devel-user ]; then
        saved_user=$(cat /etc/default/devel-user)
        if [ -n "${saved_user}" ] && id -u "${saved_user}" >/dev/null 2>&1; then
            printf '%s\n' "${saved_user}"
            return
        fi
    fi

    if [ -n "${DEV_UID:-}" ]; then
        uid_user=$(getent passwd "${DEV_UID}" | cut -d: -f1 || true)
        if [ -n "${uid_user}" ]; then
            printf '%s\n' "${uid_user}"
            return
        fi
    fi

    printf 'root\n'
}

dev_user=$(resolve_dev_user)
dev_gid=$(id -g "${dev_user}")
dev_home=$(getent passwd "${dev_user}" | cut -d: -f6)

mkdir -p /var/run/sshd

if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

if [ -n "${SSH_AUTHORIZED_KEYS:-}" ]; then
    mkdir -p "${dev_home}/.ssh"
    printf '%s\n' "${SSH_AUTHORIZED_KEYS}" > "${dev_home}/.ssh/authorized_keys"
    chown -R "${dev_user}:${dev_gid}" "${dev_home}/.ssh"
    chmod 700 "${dev_home}/.ssh"
    chmod 600 "${dev_home}/.ssh/authorized_keys"
fi

if [ -n "${SSH_PASSWORD:-}" ]; then
    echo "${dev_user}:${SSH_PASSWORD}" | chpasswd
    sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    printf 'Password authentication enabled for %s\n' "${dev_user}" >&2
fi

exec /usr/sbin/sshd -D -e