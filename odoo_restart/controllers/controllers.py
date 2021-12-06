# -*- coding: utf-8 -*-
# from odoo import http


# class OdooRestart(http.Controller):
#     @http.route('/odoo_restart/odoo_restart/', auth='public')
#     def index(self, **kw):
#         return "Hello, world"

#     @http.route('/odoo_restart/odoo_restart/objects/', auth='public')
#     def list(self, **kw):
#         return http.request.render('odoo_restart.listing', {
#             'root': '/odoo_restart/odoo_restart',
#             'objects': http.request.env['odoo_restart.odoo_restart'].search([]),
#         })

#     @http.route('/odoo_restart/odoo_restart/objects/<model("odoo_restart.odoo_restart"):obj>/', auth='public')
#     def object(self, obj, **kw):
#         return http.request.render('odoo_restart.object', {
#             'object': obj
#         })
