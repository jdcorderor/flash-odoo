/** @odoo-module **/

import { registry } from "@web/core/registry";
import { useService } from "@web/core/utils/hooks";
import { Component, useState, onWillStart, useRef, useExternalListener } from "@odoo/owl";

/**
 * Indicador de tasas de cambio venezolanas en el systray.
 * Muestra BCV USD, BCV EUR y Binance USDT.
 */
export class VenezuelaRateSystray extends Component {
    static template = "venezuela_exchange_rate.VenezuelaRateSystray";
    static props = {};

    setup() {
        this.rpc = useService("rpc");
        this.rootRef = useRef("root");

        this.state = useState({
            bcv_usd: "---",
            bcv_eur: "---",
            binance_usdt: "---",
            date: "",
            isOpen: false,
            loading: true,
            refreshing: false,
            error: "",
        });

        // Cargar tasas al iniciar
        onWillStart(() => this.loadRates());

        // Cerrar el dropdown al hacer clic fuera
        useExternalListener(document, "click", (event) => {
            if (this.rootRef.el && !this.rootRef.el.contains(event.target)) {
                this.state.isOpen = false;
            }
        });
    }

    /**
     * Formatea un número float como string con 2 decimales.
     */
    _fmt(value) {
        if (!value || value === 0) return "N/D";
        return Number(value).toFixed(2);
    }

    /**
     * Obtiene las tasas almacenadas en base de datos (vía RPC).
     */
    async loadRates() {
        this.state.loading = true;
        this.state.error = "";
        try {
            const result = await this.rpc("/venezuela_exchange_rate/get_rates");
            this.state.bcv_usd = this._fmt(result.bcv_usd);
            this.state.bcv_eur = this._fmt(result.bcv_eur);
            this.state.binance_usdt = this._fmt(result.binance_usdt);
            this.state.date = result.date
                ? new Date(result.date).toLocaleString("es-VE")
                : "";
        } catch (e) {
            this.state.bcv_usd = "Err";
            this.state.error = "No se pudo conectar al servidor.";
        } finally {
            this.state.loading = false;
        }
    }

    /**
     * Alterna la visibilidad del dropdown.
     */
    toggleDropdown() {
        this.state.isOpen = !this.state.isOpen;
        // Al abrir, refrescar los datos desde la BD
        if (this.state.isOpen) {
            this.loadRates();
        }
    }

    /**
     * Fuerza una actualización desde la API externa.
     */
    async refresh(event) {
        event.stopPropagation();
        this.state.refreshing = true;
        this.state.error = "";
        try {
            const result = await this.rpc("/venezuela_exchange_rate/refresh_rates");
            if (result.success) {
                this.state.bcv_usd = this._fmt(result.bcv_usd);
                this.state.bcv_eur = this._fmt(result.bcv_eur);
                this.state.binance_usdt = this._fmt(result.binance_usdt);
                this.state.date = result.date
                    ? new Date(result.date).toLocaleString("es-VE")
                    : "";
            } else {
                this.state.error = "No se pudieron obtener las tasas. Intente más tarde.";
            }
        } catch (e) {
            this.state.error = "Error al comunicarse con la API.";
        } finally {
            this.state.refreshing = false;
        }
    }
}

// Registrar el componente en el systray de Odoo
registry.category("systray").add("VenezuelaRateSystray", {
    Component: VenezuelaRateSystray,
    sequence: 10,
});
