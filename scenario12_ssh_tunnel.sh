#!/bin/bash
echo "================================================"
echo "  SCENARIO 12: SSH Tunnel for Remote DB Access"
echo "  Enterprise Troubleshooting Simulation"
echo "  Date: $(date)"
echo "================================================"

cat << 'STORY'
SITUATION:
  A field engineer working remotely needs to access a
  PostgreSQL database running on an internal server
  (db-prod, 10.0.50.30) at the manufacturing site.
  The database port (5432) is not exposed to the
  internet — only accessible from inside the network.
  The engineer has SSH access to the company jump server
  (jump.factory.com) which CAN reach the database server.

OBJECTIVE:
  Create an SSH tunnel through the jump server to reach
  the database securely. No VPN needed. No firewall
  changes. Just SSH.
STORY

echo ""
echo "--- THE NETWORK LAYOUT ---"
cat << 'DIAGRAM'

  Remote Site             Internet          Factory Network
  ┌─────────────┐       ┌────────┐       ┌──────────────────┐
  │  Field       │       │        │       │  jump.factory.com │
  │  Engineer    │──────>│Internet│──────>│  10.0.50.10       │
  │  Workstation │  SSH  │        │  :22  │  (SSH accessible) │
  └─────────────┘       └────────┘       └────────┬─────────┘
                                                   │ Internal
                                                   │ Network
                                          ┌────────┴─────────┐
                                          │  db-prod          │
                                          │  10.0.50.30       │
                                          │  PostgreSQL :5432  │
                                          │  (NOT internet    │
                                          │   accessible)     │
                                          └──────────────────┘
DIAGRAM

echo ""
echo "--- STEP 1: Verify SSH to jump server ---"
echo '  $ ssh -i ~/.ssh/factory_key admin@jump.factory.com'
cat << 'OUTPUT'
  Last login: Mon Jun 9 08:30:12 2026
  admin@jumpserver ~$
OUTPUT
echo '  $ exit'
echo ""
echo "  SSH to jump server works. Now build the tunnel."

echo ""
echo "--- STEP 2: Create the SSH tunnel ---"
echo '  $ ssh -L 5432:10.0.50.30:5432 -N -f admin@jump.factory.com'
echo ""
cat << 'OUTPUT'
  Flag breakdown:
    -L 5432:10.0.50.30:5432
       │     │            │
       │     │            └─ Remote port (PostgreSQL on db-prod)
       │     └────────────── Remote host (db-prod internal IP)
       └──────────────────── Local port (engineer workstation)

    -N    No remote command (tunnel only, no shell)
    -f    Run in background (fork after auth)

  Translation: anything sent to localhost:5432 on the
  engineer workstation travels through the SSH tunnel
  to the jump server, which forwards it to 10.0.50.30:5432.
OUTPUT

echo ""
echo "--- STEP 3: Connect to database through tunnel ---"
echo '  $ psql -h localhost -p 5432 -U dbadmin -d inventory'
cat << 'OUTPUT'
  Password for user dbadmin:
  psql (14.8)
  SSL connection (protocol: TLSv1.3)
  Type "help" for help.

  inventory=> SELECT count(*) FROM products;
   count
  -------
   48721
  (1 row)
OUTPUT
echo ""
echo "  Connected to the production database at the factory"
echo "  from a remote location. The connection is encrypted"
echo "  end-to-end through SSH."

echo ""
echo "--- STEP 4: Verify the tunnel is running ---"
echo '  $ ps aux | grep ssh | grep -v grep'
cat << 'OUTPUT'
  admin  23451  0.0  0.0  ssh -L 5432:10.0.50.30:5432 -N -f admin@jump.factory.com
OUTPUT
echo ""
echo '  $ lsof -i :5432'
cat << 'OUTPUT'
  COMMAND   PID  USER   FD   TYPE  DEVICE  NAME
  ssh     23451  admin   4u  IPv4  98234   localhost:5432 (LISTEN)
OUTPUT
echo ""
echo "  Tunnel is active and listening on local port 5432."

echo ""
echo "--- STEP 5: Close the tunnel when done ---"
echo '  $ kill 23451'
echo '  or'
echo '  $ pkill -f "ssh -L 5432"'

echo ""
echo "--- OTHER SSH TUNNEL TYPES ---"
cat << 'OUTPUT'
  LOCAL TUNNEL (-L): Forward local port to remote service
    Engineer -> Jump Server -> Internal Server
    ssh -L local_port:remote_host:remote_port jump_server
    Use case: Access internal DB, web app, or service

  REMOTE TUNNEL (-R): Expose local service to remote network
    Internal Server -> Jump Server -> Outside Users
    ssh -R remote_port:localhost:local_port jump_server
    Use case: Expose a dev server for external testing

  DYNAMIC TUNNEL (-D): SOCKS proxy through SSH
    ssh -D 1080 jump_server
    Use case: Route all browser traffic through remote network
    Configure browser to use SOCKS proxy localhost:1080
OUTPUT

echo ""
echo "--- SSH KEY MANAGEMENT REFERENCE ---"
cat << 'SUMMARY'
  Generate Keys:
    ssh-keygen -t ed25519 -C "comment"    Modern (recommended)
    ssh-keygen -t rsa -b 4096             RSA (compatible)

  Key Files:
    ~/.ssh/id_ed25519          Private key (NEVER share)
    ~/.ssh/id_ed25519.pub      Public key (share freely)
    ~/.ssh/authorized_keys     Public keys allowed to login
    ~/.ssh/known_hosts         Servers you have connected to
    ~/.ssh/config              Connection shortcuts

  Permissions (must be exact or SSH refuses):
    ~/.ssh/                    700 (drwx------)
    ~/.ssh/id_ed25519          600 (-rw-------)
    ~/.ssh/id_ed25519.pub      644 (-rw-r--r--)
    ~/.ssh/authorized_keys     600 (-rw-------)
    ~/.ssh/config              600 (-rw-------)

  SSH Config File (~/.ssh/config):
    Host factory-jump
        HostName jump.factory.com
        User admin
        IdentityFile ~/.ssh/factory_key

    Host factory-db
        HostName 10.0.50.30
        User dbadmin
        ProxyJump factory-jump

    Usage: ssh factory-db
    (Automatically jumps through factory-jump)

  SSH Hardening (/etc/ssh/sshd_config):
    PermitRootLogin no              Disable root SSH
    PasswordAuthentication no       Keys only
    PubkeyAuthentication yes        Enable key auth
    MaxAuthTries 3                  Limit attempts
    AllowUsers admin deployer       Whitelist users
    Port 2222                       Non-standard port
SUMMARY

echo ""
echo "Scenario 12 complete."
