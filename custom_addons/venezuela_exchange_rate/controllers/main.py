from odoo import http
from odoo.http import request


class VenezuelaRateController(http.Controller):

    @http.route('/venezuela_exchange_rate/get_rates', type='jsonrpc', auth='user')
    def get_rates(self):
        """Retorna las tasas más recientes almacenadas en BD."""
        rates = request.env['venezuela.exchange.rate'].get_current_rates()
        return rates

    @http.route('/venezuela_exchange_rate/refresh_rates', type='jsonrpc', auth='user')
    def refresh_rates(self):
        """Fuerza una actualización de las tasas desde la API."""
        env = request.env['venezuela.exchange.rate']
        record = env.fetch_and_save_rates()
        if record:
            return {
                'success': True,
                'bcv_usd': record.bcv_usd,
                'bcv_eur': record.bcv_eur,
                'binance_usdt': record.binance_usdt,
                'date': record.date.isoformat() if record.date else None,
            }
        return {'success': False}
