import logging
import requests

from odoo import api, fields, models

_logger = logging.getLogger(__name__)

VE_DOLAR_API_BASE = 'https://ve.dolarapi.com/v1'


class VenezuelaExchangeRate(models.Model):
    _name = 'venezuela.exchange.rate'
    _description = 'Tasas de Cambio Venezolanas'
    _order = 'date desc'
    _rec_name = 'date'

    date = fields.Datetime(string='Fecha', required=True, default=fields.Datetime.now)
    bcv_usd = fields.Float(string='BCV USD (Bs/$)', digits=(16, 4))
    bcv_eur = fields.Float(string='BCV EUR (Bs/€)', digits=(16, 4))
    binance_usdt = fields.Float(string='Binance USDT (Bs/USDT)', digits=(16, 4))
    bcv_usd_updated = fields.Char(string='BCV USD Actualizado')
    bcv_eur_updated = fields.Char(string='BCV EUR Actualizado')
    binance_updated = fields.Char(string='Binance Actualizado')

    @api.model
    def fetch_and_save_rates(self):
        """Obtiene las tasas desde la API y guarda un nuevo registro."""
        rates_data = self._fetch_rates_from_api()
        if rates_data:
            record = self.create(rates_data)
            _logger.info(
                'Tasas venezolanas actualizadas: BCV USD=%s, BCV EUR=%s, Binance USDT=%s',
                rates_data.get('bcv_usd'),
                rates_data.get('bcv_eur'),
                rates_data.get('binance_usdt'),
            )
            return record
        _logger.warning('No se pudieron obtener las tasas venezolanas desde la API.')
        return False

    @api.model
    def _fetch_rates_from_api(self):
        """Consulta ve.dolarapi.com y retorna un dict con las tasas."""
        result = {
            'date': fields.Datetime.now(),
            'bcv_usd': 0.0,
            'bcv_eur': 0.0,
            'binance_usdt': 0.0,
            'bcv_usd_updated': '',
            'bcv_eur_updated': '',
            'binance_updated': '',
        }

        # --- Tasas en USD (BCV y Binance) ---
        try:
            resp = requests.get(f'{VE_DOLAR_API_BASE}/dolares', timeout=10)
            resp.raise_for_status()
            dolares = resp.json()
            for item in dolares:
                fuente = (item.get('fuente') or '').lower()
                promedio = float(item.get('promedio') or 0)
                fecha = item.get('fechaActualizacion', '')
                if fuente == 'bcv' and not result['bcv_usd']:
                    result['bcv_usd'] = promedio
                    result['bcv_usd_updated'] = fecha
                elif fuente == 'binance' and not result['binance_usdt']:
                    result['binance_usdt'] = promedio
                    result['binance_updated'] = fecha
        except Exception as e:
            _logger.error('Error al obtener tasas USD: %s', e)

        # --- Tasa EUR (BCV) ---
        # Intentamos dos endpoints posibles
        for eur_url in [
            f'{VE_DOLAR_API_BASE}/dolares/euro',
            f'{VE_DOLAR_API_BASE}/euro',
        ]:
            try:
                eur_resp = requests.get(eur_url, timeout=10)
                eur_resp.raise_for_status()
                eur_data = eur_resp.json()

                if isinstance(eur_data, list):
                    # Preferir la fuente BCV; si no hay, tomar el primero
                    bcv_item = next(
                        (i for i in eur_data if (i.get('fuente') or '').lower() == 'bcv'),
                        eur_data[0] if eur_data else None,
                    )
                    if bcv_item:
                        result['bcv_eur'] = float(bcv_item.get('promedio') or 0)
                        result['bcv_eur_updated'] = bcv_item.get('fechaActualizacion', '')
                elif isinstance(eur_data, dict):
                    result['bcv_eur'] = float(eur_data.get('promedio') or 0)
                    result['bcv_eur_updated'] = eur_data.get('fechaActualizacion', '')

                if result['bcv_eur']:
                    break
            except Exception as e:
                _logger.debug('Error en %s: %s', eur_url, e)

        if not result['bcv_eur']:
            _logger.warning('No se pudo obtener la tasa BCV EUR.')

        # Retornar None si no se obtuvo ningún dato útil
        if not any([result['bcv_usd'], result['bcv_eur'], result['binance_usdt']]):
            return None

        return result

    @api.model
    def get_current_rates(self):
        """Retorna el registro más reciente para mostrar en el systray/vista."""
        latest = self.search([], limit=1)
        if latest:
            return {
                'bcv_usd': latest.bcv_usd,
                'bcv_eur': latest.bcv_eur,
                'binance_usdt': latest.binance_usdt,
                'date': fields.Datetime.to_string(latest.date),
                'bcv_usd_updated': latest.bcv_usd_updated,
                'bcv_eur_updated': latest.bcv_eur_updated,
                'binance_updated': latest.binance_updated,
            }
        # Sin datos: intentar una primera carga
        record = self.fetch_and_save_rates()
        if record:
            return {
                'bcv_usd': record.bcv_usd,
                'bcv_eur': record.bcv_eur,
                'binance_usdt': record.binance_usdt,
                'date': fields.Datetime.to_string(record.date),
                'bcv_usd_updated': record.bcv_usd_updated,
                'bcv_eur_updated': record.bcv_eur_updated,
                'binance_updated': record.binance_updated,
            }
        return {
            'bcv_usd': 0.0,
            'bcv_eur': 0.0,
            'binance_usdt': 0.0,
            'date': None,
            'bcv_usd_updated': '',
            'bcv_eur_updated': '',
            'binance_updated': '',
        }
