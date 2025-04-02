#!/bin/bash

echo "🔐 Configurando seguridad avanzada en el servidor..."

# 1. Habilitar limitación de conexiones para evitar ataques por fuerza bruta
ufw limit ssh
ufw limit from 192.168.50.10 to any port 53 proto udp
ufw limit from 192.168.50.10 to any port 53 proto tcp

# 2. Crear scripts de horario
cat <<EOF > /usr/local/bin/bloquear_fuera_horario.sh
#!/bin/bash
ufw deny from 192.168.50.10 to any port 53
EOF

cat <<EOF > /usr/local/bin/permitir_en_horario.sh
#!/bin/bash
ufw delete deny from 192.168.50.10 to any port 53
ufw allow from 192.168.50.10 to any port 53
EOF

chmod +x /usr/local/bin/bloquear_fuera_horario.sh
chmod +x /usr/local/bin/permitir_en_horario.sh

# 3. Programar tareas con cron
(crontab -l 2>/dev/null; echo "0 8 * * 1-5 /usr/local/bin/permitir_en_horario.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 18 * * 1-5 /usr/local/bin/bloquear_fuera_horario.sh") | crontab -

# 4. Instalar y activar fail2ban
apt update
apt install fail2ban -y
systemctl enable fail2ban
systemctl restart fail2ban

# 5. Activar logging de UFW
ufw logging on

echo "✅ Configuración completada. Puedes verificar UFW con: sudo ufw status"
echo "📅 Las reglas DNS se gestionarán automáticamente entre 08:00 y 18:00 de lunes a viernes."
echo "🧾 Revisa los logs en /var/log/ufw.log y el estado de fail2ban con: sudo fail2ban-client status sshd"
