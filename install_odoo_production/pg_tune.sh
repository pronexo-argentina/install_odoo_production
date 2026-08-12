#!/bin/bash
# v.20260806 pronexo.com
#
# PostgreSQL production tuner for an Odoo co-hosted server.
#
# Sizes the main PostgreSQL memory / parallelism parameters from THIS machine's
# RAM and CPU cores. It is deliberately conservative: Odoo runs on the SAME box,
# so PostgreSQL never claims all the RAM (unlike a generic pgtune, which assumes
# a dedicated database server). Settings are applied with ALTER SYSTEM, i.e.
# written to postgresql.auto.conf and fully revertible with
#   sudo -u postgres psql -c "ALTER SYSTEM RESET ALL;"  &&  restart.
#
# Usage:
#   pg_tune.sh            Print the recommended settings (changes nothing).
#   pg_tune.sh --apply    Apply them (ALTER SYSTEM) and restart PostgreSQL.
#   pg_tune.sh -s N       shared_buffers = N% of RAM (default 20; co-host safe).
#   pg_tune.sh -h         Help.

PG_VERSION=16
CMD_APPLY=0
CMD_H=0
CMD_S=20   # shared_buffers as a % of total RAM (conservative: Odoo shares the box)

clamp() { local v=$1 lo=$2 hi=$3; [ "$v" -lt "$lo" ] && v=$lo; [ "$v" -gt "$hi" ] && v=$hi; echo "$v"; }

# --- parse args ----------------------------------------------------------
for ((i=1;i<=$#;i++)); do
  case "${!i}" in
    '--apply') CMD_APPLY=1 ;;
    '-s') ((i++)); if [ "${!i}" -ge 5 ] 2>/dev/null && [ "${!i}" -le 40 ]; then CMD_S=${!i}; fi ;;
    '-h'|'--help') CMD_H=1 ;;
  esac
done

if [ "$CMD_H" -eq 1 ]; then
  grep '^#' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

# --- machine facts -------------------------------------------------------
RAM_MB=$(( $(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 ))
CORES=$(nproc)

# --- computed settings (MB unless noted) ---------------------------------
SHARED_BUFFERS=$(clamp $(( RAM_MB * CMD_S / 100 )) 128 16384)
EFFECTIVE_CACHE=$(clamp $(( RAM_MB * 50 / 100 )) 256 49152)
MAINT_WORK_MEM=$(clamp $(( RAM_MB / 16 )) 64 1024)
MAX_CONN=$(clamp $(( CORES * 20 )) 100 300)
WORK_MEM=$(clamp $(( RAM_MB / 5 / MAX_CONN )) 4 32)     # per sort op, kept small on purpose
PAR_GATHER=$(clamp $(( CORES / 2 )) 1 4)
PAR_MAINT=$(clamp $(( CORES / 2 )) 1 4)

SQL=$(cat <<SQL
ALTER SYSTEM SET shared_buffers = '${SHARED_BUFFERS}MB';
ALTER SYSTEM SET effective_cache_size = '${EFFECTIVE_CACHE}MB';
ALTER SYSTEM SET maintenance_work_mem = '${MAINT_WORK_MEM}MB';
ALTER SYSTEM SET work_mem = '${WORK_MEM}MB';
ALTER SYSTEM SET max_connections = ${MAX_CONN};
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET min_wal_size = '1GB';
ALTER SYSTEM SET max_wal_size = '4GB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;
ALTER SYSTEM SET max_worker_processes = ${CORES};
ALTER SYSTEM SET max_parallel_workers = ${CORES};
ALTER SYSTEM SET max_parallel_workers_per_gather = ${PAR_GATHER};
ALTER SYSTEM SET max_parallel_maintenance_workers = ${PAR_MAINT};
SQL
)

echo "# PostgreSQL ${PG_VERSION} tuning for RAM=${RAM_MB}MB, CORES=${CORES}"
echo "# Profile: Odoo co-hosted (shared_buffers ${CMD_S}% of RAM). SSD-oriented."
echo "$SQL"

if [ "$CMD_APPLY" -eq 1 ]; then
  echo "$SQL" | sudo -u postgres psql -q
  # shared_buffers and max_connections need a full restart to take effect.
  sudo systemctl restart postgresql
  echo "# PostgreSQL tuned and restarted."
fi

exit 0
