#!/bin/bash
# Build the workspace without appending duplicate content on a second run.
set -eu
input=${1:?Input directory required}
output=${2:?Output directory required}

workspace="$output/sentry_ws"
mkdir -p -- "$workspace"/{scripts,config,logs,tmp}
: > "$workspace/logs/.keep"
: > "$workspace/tmp/scratch.txt"

cat > "$workspace/scripts/hello.sh" <<'EOF'
#!/bin/bash
echo "Hello, AIM Linux!"
EOF

cat > "$workspace/config/robot.conf" <<'EOF'
robot=sentry
mode=training
log_level=INFO
EOF
