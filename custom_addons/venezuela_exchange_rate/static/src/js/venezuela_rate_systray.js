/** @odoo-module **/

import { registry } from "@web/core/registry";
import { rpc } from "@web/core/network/rpc";
import { Component, useState, onWillStart, useRef, useExternalListener } from "@odoo/owl";

/**
 * Indicador de tasas de cambio venezolanas en el systray.
 * Muestra BCV USD, BCV EUR y Binance USDT.
 */
export class VenezuelaRateSystray extends Component {
    static template = "venezuela_exchange_rate.VenezuelaRateSystray";
    static props = {};

    setup() {
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
     * Formatea una fecha en zona horaria UTC-4 (Caracas).
     */
    _formatUtcMinus4(value) {
        if (!value) return "";

        let dateValue = String(value).trim().replace(" ", "T");
        if (!/[zZ]|[+-]\d{2}:\d{2}$/.test(dateValue)) {
            // Fechas sin zona horaria explícita se interpretan como UTC.
            dateValue += "Z";
        }

        const date = new Date(dateValue);
        if (Number.isNaN(date.getTime())) return "";

        return new Intl.DateTimeFormat("es-VE", {
            timeZone: "America/Caracas",
            year: "numeric",
            month: "2-digit",
            day: "2-digit",
            hour: "2-digit",
            minute: "2-digit",
            second: "2-digit",
            hour12: false,
        }).format(date);
    }

    /**
     * Obtiene las tasas almacenadas en base de datos (vía RPC).
     */
    async loadRates() {
        this.state.loading = true;
        this.state.error = "";
        try {
            const result = await rpc("/venezuela_exchange_rate/get_rates");
            this.state.bcv_usd = this._fmt(result.bcv_usd);
            this.state.bcv_eur = this._fmt(result.bcv_eur);
            this.state.binance_usdt = this._fmt(result.binance_usdt);
            this.state.date = this._formatUtcMinus4(result.date);
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
            const result = await rpc("/venezuela_exchange_rate/refresh_rates");
            if (result.success) {
                this.state.bcv_usd = this._fmt(result.bcv_usd);
                this.state.bcv_eur = this._fmt(result.bcv_eur);
                this.state.binance_usdt = this._fmt(result.binance_usdt);
                this.state.date = this._formatUtcMinus4(result.date);
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
