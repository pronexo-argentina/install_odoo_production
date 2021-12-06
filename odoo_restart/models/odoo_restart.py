# -*- coding: utf-8 -*-

from odoo import models, fields, api, tools, _
import logging
from pexpect import pxssh
from odoo.exceptions import UserError
_logger = logging.getLogger(__name__)


class ServerAction(models.Model):
    _name = 'odoo.restart'
    _description = 'Odoo Restart'

    name = fields.Char('Name', required=True)
    server = fields.Char('Server URL', required=True)
    port = fields.Char('Server Port', required=True)
    username = fields.Char('Username', required=True)
    password = fields.Char('Password', required=True)
    description = fields.Text('Instruction')
    start_command = fields.Char('Start Command', required=True)
    stop_command = fields.Char('Stop Command', required=True)
    restart_command = fields.Char('Restart Command', required=True)
    history_ids = fields.One2many(
        'odoo.restart.history', 'server_id', 'Server History')
    # Server url must be unique
    _sql_constraints = [(
        'server_unique', 'unique(server)',
        'Server must be unique'
    )]

    def test_connection(self):
        """For test server connection"""
        try:
            ser = pxssh.pxssh()
            # Trim white space from password
            password = self.password.strip()
            _logger.info("test jm 1")
            ser.login(self.server, self.username, password, port=self.port)
            ser.logout()
            return self.env['warning_box'].info(title='Éxito',
                                                message="Prueba de conexión\
                                                ¡Tuvo éxito! Todo parece\
                                                configurado correctamente!")
        except Exception:
            _logger.info("No se pudo conectar a %s.", self.name, exc_info=True)
            raise UserError(
                _("Prueba de conexión fallida! \nPor favor revise y corrija\
                 la Credencial para %s.") % self.name)

    def action_start(self):
        """To start server action"""
        try:
            ser = pxssh.pxssh()
            # Trim white space from password
            password = self.password.strip()
            ser.login(self.server, self.username, password, port=self.port)
            ser.sendline(self.start_command)
            ser.prompt()
            ser.before.decode('utf-8')
            ser.logout()
        except Exception as e:
            _logger.info("No se pudo conectar a %s.", self.name, exc_info=True)
            raise UserError(_("La conexión falló: %s") % tools.ustr(e))

        self.env['odoo.restart.history'].create(
            {'server_id': self.id, 'state': 'start'})
        return self.env['warning_box'].info(title='Éxito',
                                            message="Conexión con " +
                                            self.name + " inicio exitosamente!")

    def action_stop(self):
        """To stop server action"""
        try:
            ser = pxssh.pxssh()
            # Trim white space from password
            password = self.password.strip()
            ser.login(self.server, self.username, password, port=self.port)
            ser.sendline(self.stop_command)
            ser.prompt()
            ser.before.decode('utf-8')
            ser.logout()
        except Exception as e:
            _logger.info("No se pudo conectar a %s.", self.name, exc_info=True)
            raise UserError(_("La conexión falló: %s") % tools.ustr(e))
        self.env['odoo.restart.history'].create(
            {'server_id': self.id, 'state': 'stop'})
        return self.env['warning_box'].info(title='Éxito',
                                            message="Conexión con " +
                                            self.name + " detenido con éxito!")

    def action_restart(self):
        """To restart server action"""
        try:
            ser = pxssh.pxssh()
            # Trim white space from password
            password = self.password.strip()
            ser.login(self.server, self.username, password, port=self.port)
            ser.sendline(self.restart_command)
            ser.prompt()
            ser.before.decode('utf-8')
            ser.logout()
        except Exception as e:
            _logger.info("No se pudo conectar a %s.", self.name, exc_info=True)
            raise UserError(_("La conexión falló: %s") % tools.ustr(e))
        self.env['odoo.restart.history'].create(
            {'server_id': self.id, 'state': 'restart'})
        return self.env['warning_box'].info(title='Éxito',
                                            message="Conexión con " +
                                            self.name +
                                            " reiniciado exitosamente!")


class ServerActionHistory(models.Model):
    _name = 'odoo.restart.history'
    _description = 'Server Action History'
    _rec_name = 'server_id'

    server_id = fields.Many2one('odoo.restart', 'Server')
    state = fields.Selection(
        [('start', 'Started'), ('stop', 'Stopped'),
         ('restart', 'Restarted')], string='Status')
