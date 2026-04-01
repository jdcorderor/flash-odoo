#!/bin/bash
set -e

# Limpia attachments stale del filesystem antes de arrancar Odoo.
# Con --attachment-db-max-size=0 todos los assets se guardan en BD,
# por lo que cualquier store_fname existente es un puntero roto.
python3 - <<'PYEOF'
import os, sys
try:
    import psycopg2
    conn = psycopg2.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        port=int(os.environ.get('DB_PORT', 5432)),
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        dbname=os.environ['DB_NAME']
    )
    cur = conn.cursor()
    cur.execute("DELETE FROM ir_attachment WHERE store_fname IS NOT NULL")
    deleted = cur.rowcount
    conn.commit()
    conn.close()
    print(f"[entrypoint] Limpiados {deleted} attachments con store_fname")
except Exception as e:
    print(f"[entrypoint] Aviso: no se pudieron limpiar attachments: {e}", file=sys.stderr)
PYEOF

exec "$@"
