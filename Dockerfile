FROM odoo:19.0

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt --break-system-packages

COPY ./custom_addons /mnt/extra-addons
COPY entrypoint.sh /entrypoint.sh

RUN chown -R odoo:odoo /mnt/extra-addons /var/lib/odoo && \
    chmod +x /entrypoint.sh

CMD /entrypoint.sh odoo \
         --db_host=$DB_HOST \
         --db_port=$DB_PORT \
         --db_user=$DB_USER \
         --db_password=$DB_PASSWORD \
         --database=$DB_NAME \
         --addons-path=/usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons \
         --http-port=8069 \
         --http-interface=0.0.0.0