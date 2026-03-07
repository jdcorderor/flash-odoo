FROM odoo:19.0

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt --break-system-packages

COPY ./custom_addons /mnt/extra-addons

RUN chown -R odoo:odoo /mnt/extra-addons /var/lib/odoo

USER odoo

ENTRYPOINT ["odoo"]
CMD ["--db_host=sosckwwwgoks40k40048w08k", "--db_port=5432", "--db_user=postgres", "--db_password=1rrAxh2EsujSesl0iLzlpaH7MgS1QScVixjaxiaNxw9knVrkYWlhy6Jcw80n9aHM", "--addons-path=/mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons", "--http-port=8069"]