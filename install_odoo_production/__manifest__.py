# -*- coding: utf-8 -*-
# Copyright Pronexo (https://www.pronexo.com). License OPL-1.
{
    'name': 'Install Odoo Production',
    'summary': 'One script installs a production-ready Odoo 18 with a tuned '
               'PostgreSQL, Nginx and free SSL',
    'description': """
Install Odoo Production
=======================

A single shell script that turns a fresh Ubuntu 24.04 LTS server into a
production-ready Odoo 18 in about two minutes.

What it sets up
---------------
* Odoo 18 from the official source, inside a Python virtualenv.
* PostgreSQL 16, automatically tuned for the server: shared_buffers, cache,
  work_mem, connections and parallelism are sized from the machine's RAM and
  cores, conservatively, so Odoo and PostgreSQL share the box without fighting
  over memory (applied with ALTER SYSTEM, fully revertible).
* Odoo multi-processing tuned too: worker count and memory limits are computed
  from the same RAM and cores.
* A systemd service, so Odoo starts on boot and is managed like any service.
* An Nginx reverse proxy (gzip, static caching, proxy headers, longpolling).
* Certbot + Let's Encrypt, so a trusted SSL certificate is one command away.
* Everything under a single /opt folder, so moving to another server is a copy.
* Handy shell commands: start, stop, restart, status, log, econf, pconf,
  pgtune and workers.
* A weekly cron backup that zips the whole installation folder.

Works with Odoo Community out of the box; add your Enterprise addons to the
extra-addons folder to run Enterprise.

By Pronexo.
    """,
    'version': '18.0.1.0.0',
    'author': 'Pronexo',
    'maintainer': 'Pronexo',
    'website': 'https://www.pronexo.com',
    'support': 'soporte@pronexo.com',
    'license': 'OPL-1',
    'category': 'Extra Tools',
    'images': ['static/description/banner.gif'],
    'depends': ['base'],
    'price': 20.00,
    'currency': 'USD',
    'auto_install': False,
    'installable': True,
    'application': False,
}
