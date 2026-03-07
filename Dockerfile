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