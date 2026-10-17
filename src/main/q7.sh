#!/bin/bash
# Connect with the supplied identity and pinned host key, then use SCP.
set -eu
input=${1:?Input directory required}
output=${2:?Output directory required}

mkdir -p -- "$output/received"
source "$input/remote.env"
umask 077
cat > "$output/ssh_config" <<EOF
Host aim-sentry
    HostName $HOST
    Port $PORT
    User $REMOTE_USER
    IdentityFile "$KEY_PATH"
    UserKnownHostsFile "$KNOWN_HOSTS"
    IdentitiesOnly yes
    IdentityAgent none
    StrictHostKeyChecking yes
    BatchMode yes
    ConnectTimeout 3
EOF
chmod 600 "$output/ssh_config"

ssh -F "$output/ssh_config" aim-sentry whoami > "$output/remote-user.txt"
scp -F "$output/ssh_config" "aim-sentry:$REMOTE_LOG" "$output/received/errors.log"
