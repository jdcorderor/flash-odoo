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
    # ir_config_parameter requiere create_uid/write_uid/create_date/write_date (NOT NULL).
    cur.execute("""
        INSERT INTO ir_config_parameter (key, value, create_uid, write_uid, create_date, write_date)
        VALUES ('ir_attachment.location', 'db', 1, 1, NOW(), NOW())
        ON CONFLICT (key) DO UPDATE SET value = 'db', write_uid = 1, write_date = NOW()
    """)

    # Eliminar TODOS los asset bundles cacheados (CSS/JS/websocket worker).
    # Esto incluye bus.websocket_worker_assets y cualquier bundle del run anterior
    # que apunte a archivos del filestore efímero que ya no existen en disco.
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

exec "$@"
