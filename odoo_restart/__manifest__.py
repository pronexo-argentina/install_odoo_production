# -*- coding: utf-8 -*-
{
    'name': "Odoo Restart",

    'summary': """
        Iniciar, detener y reiniciar el servidor odoo a través de la interfaz odoo""",

    'description': """
-> Administrar los detalles del servidor con su URL, nombre de usuario, contraseña y comandos
-> Iniciar, detener y reiniciar el servidor odoo a través de la interfaz odoo
-> Mantener el historial para administrar quién realiza la acción del servidor y cuándo
    """,

    'author': "Pronexo",
    'website': "https://www.pronexo.com",
    'category': 'Extra Tools',
    'license': 'AGPL-3',
    'price': 15,
    'version': '16.0.1.0.0',
    'depends': ['base'],
    'external_dependencies': {'python' : ["pexpect"]},
    'data': [
        'security/ir.model.access.csv',
        'security/odoo_restart_security.xml',
        'views/odoo_restart.xml',
        'views/warning_box.xml',

    ],
    'demo': [
        'demo/demo.xml',
    ],
    'images': [
        'static/description/odoo_restart_home.png'

    ],
}
