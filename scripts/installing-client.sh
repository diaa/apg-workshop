#!/usr/bin/env bash
#
# Install PostgreSQL 18 client tools (psql, pgbench, pg_dump, pg_restore, pg_isready)
# on Rocky Linux 9 from the PGDG repository.
#
# Usage:  sudo bash installing-client.sh
#

set -euo pipefail

echo "==> Installing PGDG repository..."
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm

echo "==> Disabling AppStream PostgreSQL module (avoids PG 13 conflict)..."
dnf -qy module disable postgresql

echo "==> Installing postgresql18 and postgresql18-contrib..."
dnf install -y postgresql18 postgresql18-contrib

echo "==> Adding PG 18 to system-wide PATH..."
tee /etc/profile.d/postgres18.sh > /dev/null <<'EOF'
export PATH="/usr/pgsql-18/bin:$PATH"
EOF

echo "==> Creating /usr/bin symlinks for all users..."
ln -sf /usr/pgsql-18/bin/{psql,pgbench,pg_dump,pg_restore,pg_isready} /usr/bin/

echo "==> Verifying installation..."
/usr/pgsql-18/bin/psql --version
/usr/pgsql-18/bin/pgbench --version

echo "==> Done. Run 'hash -r' or open a new shell to pick up the new PATH."
