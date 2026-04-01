#!/bin/bash
set -e

# Prepara la BD antes de arrancar Odoo en contenedores efímeros (Railway):
#
# 1. Fuerza almacenamiento de attachments en BD (no en filestore del filesystem).
#    El parámetro real de Odoo es ir_attachment.location = 'db' en ir_config_parameter.
#    Sin esto, los bundles JS/CSS se guardan en /var/lib/odoo/filestore/ que se pierde
#    en cada redeploy, causando FileNotFoundError en /bus/websocket_worker_bundle etc.
#
# 2. Elimina cualquier attachment con store_fname que apunte al filestore antiguo
#    (registros de runs anteriores cuyos archivos ya no existen en disco).
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
    # Esto evita que los asset bundles (CSS/JS/websocket worker) se guarden
    # en el filesystem efímero y fallen al reiniciar el contenedor.
    cur.execute("""
        INSERT INTO ir_config_parameter (key, value)
        VALUES ('ir_attachment.location', 'db')
        ON CONFLICT (key) DO UPDATE SET value = 'db'
    """)

    # Limpiar attachments stale que apuntan a archivos del filestore anterior.
    cur.execute("DELETE FROM ir_attachment WHERE store_fname IS NOT NULL")
    deleted = cur.rowcount

    conn.commit()
    conn.close()
    print(f"[entrypoint] ir_attachment.location=db configurado; {deleted} attachments stale eliminados")
except Exception as e:
    print(f"[entrypoint] Aviso: error en setup de BD: {e}", file=sys.stderr)
PYEOF

exec "$@"
