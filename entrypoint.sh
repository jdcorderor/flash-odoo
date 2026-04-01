#!/bin/bash
set -e

mkdir -p /var/lib/odoo/sessions
chown -R odoo:odoo /var/lib/odoo

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

    # Forzar almacenamiento en BD para todos los attachments nuevos.
    cur.execute("""
        INSERT INTO ir_config_parameter (key, value, create_uid, write_uid, create_date, write_date)
        VALUES ('ir_attachment.location', 'db', 1, 1, NOW(), NOW())
        ON CONFLICT (key) DO UPDATE SET value = 'db', write_uid = 1, write_date = NOW()
    """)

    # Eliminar TODOS los asset bundles cacheados (CSS/JS/websocket worker) 
    # y cualquier registro que apunte al filestore efímero.
    cur.execute("""
        DELETE FROM ir_attachment
        WHERE (url LIKE '/web/assets/%' AND public = true)
           OR store_fname IS NOT NULL
    """)
    deleted = cur.rowcount

    conn.commit()
    conn.close()
    print(f"[entrypoint] ir_attachment.location=db configurado; {deleted} attachments stale eliminados")
except Exception as e:
    print(f"[entrypoint] Aviso: error en setup de BD: {e}", file=sys.stderr)
PYEOF

if [ "$1" = 'odoo' ]; then
    exec gosu odoo "$@"
fi

exec "$@"