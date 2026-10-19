# Run an agent-manager worktree's console locally against a remote full setup over SSH tunnels.

usage() {
  cat <<'EOF'
Usage: amp-console-remote [-H host] [-w worktree] [host] [worktree] [-- ssh-option...]

Runs <worktree>/console on http://localhost:3000, backed by the full setup on the
remote host through SSH tunnels. The runtime config is rendered from the remote
console container's env, so it follows whatever version the host is running.

  host           ssh destination: user@host or a ~/.ssh/config alias
                 (default: $AMP_REMOTE_HOST or lyuda@agent-runtime-2)
  worktree       agent-manager checkout (default: git root of the current dir);
                 a bare positional counts as a worktree if it is a directory or contains '/'
  -- ...         passed to every ssh call, e.g. -- -p 2222 -i ~/.ssh/key -J bastion

Examples:
  amp-console-remote jhivandb@shrewd-cachy-01
  amp-console-remote jhivandb@shrewd-cachy-01 ~/src/agent-manager -- -p 2222

Ctrl-C stops the console, closes the tunnels and restores config.js.
EOF
}

host=""
worktree_arg=""
ssh_opts=()
while (($#)); do
  case "$1" in
    -h | --help) usage; exit 0 ;;
    -H) host="${2:?-H needs a host}"; shift 2 ;;
    -w) worktree_arg="${2:?-w needs a path}"; shift 2 ;;
    --) shift; ssh_opts=("$@"); break ;;
    -*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [[ -d "$1" || "$1" == */* ]]; then
        [[ -z "$worktree_arg" ]] || { echo "more than one worktree given: $worktree_arg, $1" >&2; exit 2; }
        worktree_arg="$1"
      else
        [[ -z "$host" ]] || { echo "more than one host given: $host, $1" >&2; exit 2; }
        host="$1"
      fi
      shift
      ;;
  esac
done
host="${host:-${AMP_REMOTE_HOST:-lyuda@agent-runtime-2}}"

worktree="$(git -C "${worktree_arg:-.}" rev-parse --show-toplevel)"
console="$worktree/console"
template="$console/apps/web-ui/public/config.template.js"
config="$console/apps/web-ui/public/config.js"
[[ -f "$template" ]] || { echo "not an agent-manager worktree: $worktree" >&2; exit 1; }

# Thunder's discovery doc hardcodes :8080, so every port must map 1:1.
ports=(
  3000                                              # local console (checked, not forwarded)
  9000 9243                                         # AMS API, gateway control plane
  8080 8443 19080 19443                             # Thunder/ingress, gateway vhosts
  10081 10082 11080 11081 11082 11085 6550          # remaining k3d LB ports
  9098 8195                                         # observer, openchoreo-api (remote kubectl port-forwards)
)

busy=()
holders=()
for port in "${ports[@]}"; do
  if pids="$(lsof -t -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null)"; then
    busy+=("$port")
    mapfile -t port_pids <<<"$pids"
    holders+=("${port_pids[@]}")
  fi
done
if ((${#busy[@]})); then
  echo "local ports already in use: ${busy[*]}" >&2
  echo "held by:" >&2
  ps -o pid=,command= -p "$(printf '%s\n' "${holders[@]}" | sort -u | paste -sd, -)" | cut -c1-160 | sed 's/^/  /' >&2
  echo "a stray 'ssh -N' is a tunnel from an earlier run (kill <pid>); docker/k3d means a local cluster ('make teardown')" >&2
  exit 1
fi

echo "==> Reading console env from $host"
remote_env="$(ssh "${ssh_opts[@]}" "$host" docker exec agent-manager-console env)"

workdir="$(mktemp -d)"
cp "$config" "$workdir/config.js.orig"
tunnel_pid=""

cleanup() {
  trap - EXIT INT TERM HUP
  if [[ -n "$tunnel_pid" ]]; then
    # Grab the ssh child first: once the loop dies it is reparented and pkill -P misses it.
    mapfile -t tunnel_children < <(pgrep -P "$tunnel_pid" || true)
    kill "$tunnel_pid" 2>/dev/null || true
    if ((${#tunnel_children[@]})); then
      kill "${tunnel_children[@]}" 2>/dev/null || true
    fi
  fi
  cp "$workdir/config.js.orig" "$config"
  rm -rf "$workdir"
  echo "==> Tunnels closed, config.js restored"
}
trap cleanup EXIT INT TERM HUP

forwards=()
for port in "${ports[@]:1}"; do
  forwards+=(-L "$port:localhost:$port")
done
echo "==> Opening tunnels to $host"
# Reconnects after drops (sleep, network blips); the console keeps running meanwhile.
(
  while true; do
    ssh -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=3 \
      -o ConnectTimeout=10 "${ssh_opts[@]}" "${forwards[@]}" "$host" || true
    echo "==> Tunnel to $host dropped, reconnecting in 3s" >&2
    sleep 3
  done
) &
tunnel_pid=$!
for _ in $(seq 20); do
  curl -s -o /dev/null http://localhost:9000/ && break
  sleep 1
done

echo "==> Rendering config.js"
template_vars=" $(grep -oE '\$[A-Z_][A-Z0-9_]*' "$template" | tr -d '$' | sort -u | tr '\n' ' ') "
(
  # Only the template's vars, so the container's PATH/HOME never leak in.
  while IFS='=' read -r key value; do
    if [[ "$template_vars" == *" $key "* ]]; then
      export "$key=$value"
    fi
  done <<<"$remote_env"
  envsubst <"$template" >"$config"
)

# Corepack picks pnpm from the cwd's package.json, so run from console/ to get its pinned version.
cd "$console"
echo "==> Syncing console dependencies"
pnpm install --frozen-lockfile

if ! curl -s -o /dev/null http://localhost:9000/; then
  echo "warning: AMS is not answering on localhost:9000 through the tunnel" >&2
fi

echo "==> Console: http://localhost:3000  (backed by $host)"
pnpm run dev --host 127.0.0.1 --port 3000 --strictPort
