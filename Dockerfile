FROM odoo:19.0

USER root

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt

RUN pip3 install -r /tmp/requirements.txt --break-system-packages

COPY ./custom_addons /mnt/extra-addons

USER odoo