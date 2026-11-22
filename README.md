# AquaWatch-MS — Real-time Water Quality Monitoring

[![CI](https://github.com/Yasineert/AquaWatch-MS/actions/workflows/ci.yml/badge.svg)](https://github.com/Yasineert/AquaWatch-MS/actions/workflows/ci.yml)
![Microservices](https://img.shields.io/badge/architecture-microservices-0A66C2)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue)

Microservice platform that monitors water quality from IoT sensors and Sentinel-2 satellite data, predicts short-term changes with a spatio-temporal model, raises alerts when WHO thresholds are exceeded and shows the situation on an interactive map.

## Architecture

```
 IoT sensors ──MQTT──▶ service_capteurs ──┐
                       (Node.js, 8001)    │
 Sentinel-2 / ──────▶ service_satellite ──┼──▶ service_stmodel ──▶ service_alertes ──▶ e-mail
 Copernicus            (Python, 8002)     │    (Python ML, 8003)    (Node.js, 8004)
                                          │            │
                                          ▼            ▼
                     TimescaleDB · PostGIS · MongoDB · MinIO · Redis
                                          │
                                          ▼
                                 service_api_sig (Next.js, 8005)
                                 map, dashboards, reports
```

| Service | Role | Stack | Port |
|---|---|---|---|
| `service_capteurs` | Collects sensor readings (pH, turbidity, temperature) over MQTT, REST API | Node.js, Express, TimescaleDB | 8001 |
| `service_satellite` | Downloads and processes Sentinel-2 imagery (NDWI, chlorophyll) | Python, FastAPI, MinIO | 8002 |
| `service_stmodel` | Spatio-temporal prediction model and prediction API | Python, PyTorch, Redis | 8003 |
| `service_alertes` | Threshold monitoring, alert lifecycle, e-mail notifications | Node.js, Express, PostgreSQL | 8004 |
| `service_api_sig` | Web app: interactive map, sensors, predictions, alerts, reports | Next.js, TypeScript, PostGIS, GeoServer | 8005 |

Supporting infrastructure: TimescaleDB, PostGIS, MongoDB, MinIO, Redis, GeoServer, SonarQube and Jenkins, all defined in `docker-compose.yml`.

## Monitored parameters

| Parameter | WHO threshold | Source |
|---|---|---|
| pH | 6.5 – 8.5 | Sensors |
| Turbidity | < 4.0 NTU | Sensors, satellite |
| Temperature | < 25 °C | Sensors |
| Chlorophyll | variable | Satellite |
| NDWI | 0.0 – 1.0 | Satellite |

## Getting started

**Requirements:** Docker Desktop with Compose, Git. Node.js 20 and Python 3.12 only to run services outside Docker.

```bash
git clone https://github.com/Yasineert/AquaWatch-MS.git
cd AquaWatch-MS

cp .env.example .env
cp .env.alertes.example .env.alertes
cp .env.api_sig.example .env.api_sig
# edit the three files with your own credentials

docker compose up --build -d
```

| Endpoint | URL |
|---|---|
| Sensors API | http://localhost:8001/api |
| Satellite API | http://localhost:8002/api |
| Prediction API | http://localhost:8003/api |
| Alerts API | http://localhost:8004/api |
| Web app (map) | http://localhost:8005/map |
| MinIO console | http://localhost:9001 |

## Tests and quality

```bash
cd services/service_alertes && npm install && npx jest tests/alertService
```

- Unit tests for the alert service: identifier and default severity, alert payload, delivery status (`pending`, `sent`, `failed`) and error propagation, with the database and SMTP mocked.
- GitHub Actions runs the unit tests and a Gitleaks secret scan on every push.
- SonarCloud analyses code quality (`.github/workflows/sonarcloud.yml`); Jenkins pipelines are provided per service.

## Security

- All credentials come from Git-ignored `.env` files; only `*.example` templates are versioned.
- SMTP connections validate TLS certificates (`SMTP_TLS_INSECURE=true` only for local debugging).
- See [SECURITY.md](SECURITY.md) to report a vulnerability.

## Team

| Member | Scope |
|---|---|
| Hamza Aglagal | Prediction model, infrastructure |
| Bilal | Sensors and satellite services |
| Yassin | Alert service, GIS API and web app |

## License

[MIT](LICENSE)
