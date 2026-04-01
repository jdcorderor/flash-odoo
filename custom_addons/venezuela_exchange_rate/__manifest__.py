{
    'name': 'Tasas de Cambio Venezuela',
    'version': '19.0.1.0.0',
    'summary': 'Tasas de cambio venezolanas: BCV USD, BCV EUR y Binance USDT',
    'description': """
        Módulo para consultar y mostrar las tasas de cambio venezolanas:
        - Tasa BCV (Dólar)
        - Tasa BCV (Euro)
        - USDT Binance
        Las tasas se actualizan automáticamente cada hora mediante una acción programada.
        También se muestra un indicador en la barra superior (systray) con las tasas actuales.
    """,
    'author': 'Custom',
    'category': 'Accounting/Localizations',
    'website': '',
    'depends': ['base', 'web'],
    'data': [
        'security/ir.model.access.csv',
        'data/scheduled_action.xml',
        'views/venezuela_rate_views.xml',
        'views/venezuela_rate_menu.xml',
    ],
    'assets': {
        'web.assets_backend': [
            'venezuela_exchange_rate/static/src/xml/venezuela_rate_systray.xml',
            'venezuela_exchange_rate/static/src/css/venezuela_rate.css',
            'venezuela_exchange_rate/static/src/js/venezuela_rate_systray.js',
        ],
    },
    'installable': True,
    'auto_install': False,
    'application': False,
    'license': 'LGPL-3',
}
