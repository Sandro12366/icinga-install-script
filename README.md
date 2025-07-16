# Icinga2 Installations- und Automatisierungs-Script

Dieses Repository enthält ein vollautomatisiertes Installations- und Setup-Script für Icinga2, WebUI, Director, IcingaDB, Redis, Grafana sowie verteiltes Monitoring (Distributed Polling) mit Satelliten und Agenten.

## Features
- Interaktive, verständliche Installation für verschiedene Linux-Distributionen (Debian, Ubuntu, RHEL, CentOS, Rocky, AlmaLinux)
- Automatische Erkennung und Installation aller Abhängigkeiten
- Optionale Installation von WebUI, Director, Grafana, IcingaDB, Redis
- Automatische Passwort-Generierung und sichere Speicherung
- Unterstützung für Proxy-Umgebungen
- Optionale Einrichtung eines lokalen SSL-Proxys (nginx) für HTTPS-Zugriff
- Vollautomatisiertes Distributed Polling (Satelliten/Agenten) mit 1-Zeiler-Setup
- Skripte für Satelliten und Agenten mit automatischem Join zum Master

## Schnellstart (Master-Installation)

```bash
bash <(curl -s https://raw.githubusercontent.com/<dein-user>/<repo>/main/install_icinga2.sh)
```

Folge den interaktiven Fragen im Script. Nach Abschluss findest du alle Zugangsdaten in der Datei `icinga2_credentials.txt`.

## Distributed Polling (Satelliten/Agenten)

Nach der Master-Installation werden dir ein Join-Token und die Master-IP angezeigt. Satelliten und Agenten können dann mit folgendem 1-Zeiler angebunden werden:

```bash
bash <(curl -s https://raw.githubusercontent.com/<dein-user>/<repo>/main/setup_satellite.sh) <MASTER_IP> <JOIN_TOKEN>
```

```bash
bash <(curl -s https://raw.githubusercontent.com/<dein-user>/<repo>/main/setup_agent.sh) <MASTER_IP> <JOIN_TOKEN>
```

## Komponenten
- **Icinga2 Core**: Monitoring Engine
- **Icinga Web UI**: Weboberfläche (optional, mit/ohne Grafana-Integration)
- **Icinga Director**: Zentrale Konfigurationsverwaltung (optional)
- **IcingaDB & Redis**: Moderne Backend-Architektur (optional, empfohlen mit Grafana)
- **Grafana**: Visualisierung (optional, Integration in WebUI möglich)
- **nginx**: Lokaler SSL-Proxy für HTTPS (optional)
- **Distributed Polling**: Automatisierte Anbindung von Satelliten und Agenten

## Sicherheit
- Alle Passwörter werden zufällig generiert und in `icinga2_credentials.txt` gespeichert (nur für root lesbar)
- Datenbank- und API-User werden mit minimalen Rechten angelegt
- SSL-Zertifikate für nginx werden automatisch erstellt (self-signed)

## Hinweise
- Das Script ist für frische Server-Installationen gedacht
- Für produktive Umgebungen sollten die Passwörter und Zertifikate nachträglich angepasst werden
- Die Distributed-Polling-Skripte können beliebig oft für neue Satelliten/Agenten verwendet werden

## Support & Dokumentation
- Offizielle Icinga2 Doku: https://icinga.com/docs/icinga-2/latest/
- Fragen und Verbesserungen gerne als Issue oder Pull Request im Repo!
