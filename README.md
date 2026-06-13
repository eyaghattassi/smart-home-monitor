# 🏠 Smart Home Monitor

An end-to-end IoT system that combines **environmental sensing**, **MQTT communication**, **power management**, and a **mobile app** — built as a hands-on project to apply embedded systems and IoT concepts learned during my studies.

## Overview

The ESP32 reads temperature and humidity from a DHT22 sensor, publishes the readings to an MQTT broker (HiveMQ Cloud), and goes into deep sleep to save power between readings. A Node.js server subscribes to the MQTT topics, stores a short history of readings, and exposes a REST API consumed by both a web dashboard and a Flutter mobile app. The mobile app can also send commands back to control a relay (e.g. a lamp or fan).

```
ESP32 + DHT22 ── MQTT ──► HiveMQ Cloud Broker
   (deep sleep)                  │
                                  ▼
                          Node.js server (Express)
                           │              │
                           ▼              ▼
                     Web dashboard   Flutter mobile app
                     (live charts)   (sensor view + relay control)
```

## Features

- **Sensor reading** — temperature and humidity via DHT22 on ESP32
- **MQTT communication** — publish/subscribe over TLS using HiveMQ Cloud
- **Deep sleep** — ESP32 sleeps between readings to reduce power consumption
- **Remote control** — relay/device can be toggled from the mobile app via MQTT
- **Web dashboard** — live readings and historical charts (Chart.js)
- **Flutter app** — cross-platform mobile interface for monitoring and control

## Tech stack

| Layer | Technology |
|---|---|
| Firmware | C++ (Arduino framework), ESP32, DHT22, PubSubClient |
| Communication | MQTT over TLS (HiveMQ Cloud) |
| Backend | Node.js, Express |
| Web frontend | HTML/CSS/JS, Chart.js |
| Mobile app | Flutter (Dart) |

## Project structure

```
smart-home-monitor/
├── sketch.ino          # ESP32 firmware (sensor + MQTT + deep sleep)
├── diagram.json         # Wokwi circuit simulation
├── server.js            # Node.js/Express backend
├── public/
│   └── index.html       # Web dashboard with live charts
└── smart_home_app/       # Flutter mobile app
    └── lib/main.dart
```

## Getting started

### 1. Firmware (ESP32)
Open `sketch.ino` in Arduino IDE or run the project on [Wokwi](https://wokwi.com) using `diagram.json`. Set your WiFi and HiveMQ credentials at the top of the file.

### 2. Backend
```bash
npm install
node server.js
```
The server runs at `http://localhost:3000` and exposes:
- `GET /api/sensor` — latest temperature/humidity/relay state
- `GET /api/history` — last readings for charts
- `POST /api/relay` — toggle relay (`{ "state": "ON" | "OFF" }`)

### 3. Mobile app
```bash
cd smart_home_app
flutter pub get
flutter run
```
Update the `serverUrl` constant in `lib/main.dart` to point to your server's local IP.

## What I learned

- Reading sensors and publishing data over MQTT from an ESP32
- Power optimization with deep sleep
- Building a Node.js API as a bridge between hardware, web, and mobile
- Cross-platform UI development with Flutter consuming a REST API

## Status

Currently developed and tested in simulation (Wokwi). Hardware deployment with a real ESP32 + DHT22 is in progress.

## Author

**Eya Ghattassi** — 2nd year Embedded Systems & IoT student at ISTIC
[github.com/eyaghattassi](https://github.com/eyaghattassi)
