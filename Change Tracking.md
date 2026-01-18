**Change Tracking**

---

## 🔍 ¿Qué es Change Tracking?

Es una solución de **Azure Automation** (usando Log Analytics) que permite **detectar cambios en tiempo casi real** en:

- Archivos
    
- Registro de Windows
    
- Software instalado/desinstalado
    
- Servicios (nombre, estado, tipo de inicio)
    

---

## ✅ ¿Qué puedes hacer con máquinas Arc?

Change Tracking funciona con **servidores híbridos Arc** exactamente igual que con VMs de Azure, si cumples estos requisitos:

1. La VM Arc debe tener instalada la **extensión de Azure Monitor Agent**.
    
2. Debes habilitar la solución **Change Tracking & Inventory** sobre el Log Analytics Workspace asociado.
    
3. (Opcional) Puedes gestionar desde **Azure Automation** para integrarlo con actualizaciones o alertas.
    

---

## 🎯 Casos de uso típicos:

- Ver qué software se instala/desinstala en servidores on-prem.
    
- Detectar cambios sospechosos en servicios (ej.: estado de Defender apagado).
    
- Auditar cambios en archivos críticos (`hosts`, `sshd_config`, etc.).
    
- Detectar modificaciones en claves de registro sensibles.
    
- Generar alertas o automatizaciones si se detecta un cambio no autorizado.
    

---

## 🚫 Limitaciones:

- No es en tiempo real exacto: puede tener hasta **30 min de latencia**.
    
- No detecta cambios fuera de los **paths o claves registradas**.
    
- **No almacena el contenido cambiado**, solo que hubo un cambio (fecha, valor antes/después si es posible).
    

---

## 🧠 Pro tip:

Si el cliente ya tiene Arc + AMA + Log Analytics, solo necesita **vincular el workspace a la solución**:

```bash
az monitor log-analytics workspace linked-service create \
  --resource-group <rg> \
  --workspace-name <workspace> \
  --name "Automation" \
  --write-access-resource-id "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Automation/automationAccounts/<automation-account>"
```

Y después configurar desde Azure Portal → **Automation Account → Inventory/Change Tracking**.

---

¿Quieres que te muestre cómo automatizar la configuración en Arc con Terraform o desde PowerShell?