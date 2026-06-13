#include <DHT.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <WiFiClientSecure.h>  

const char* ssid     = "Wokwi-GUEST";
const char* password = "";

const char* mqtt_server = "a075096d9fa34b7a8b48c0caf3b42ee6.s1.eu.hivemq.cloud";
const int   mqtt_port   = 8883;
const char* mqtt_user   = "eya-ghattassii";   // ← your Access Management username
const char* mqtt_pass   = "55664789123mlK";   // ← your Access Management password

// ── MQTT topics ───────────────────────
const char* topic_temp     = "home/sensor/temperature";
const char* topic_humidity = "home/sensor/humidity";
const char* topic_control  = "home/control/relay";
const char* topic_status   = "home/status";
// ─────────────────────────────────────

#define DHTPIN  4
#define DHTTYPE DHT22
#define RELAY_PIN 26

// deep sleep duration — 30 seconds
#define SLEEP_SECONDS 30

DHT dht(DHTPIN, DHTTYPE);
WiFiClientSecure espClient;
PubSubClient client(espClient);

// called when a message arrives on subscribed topic
void onMessage(char* topic, byte* payload, unsigned int length) {
  String msg = "";
  for (int i = 0; i < length; i++) msg += (char)payload[i];

  Serial.println("Command received: " + msg);

  if (String(topic) == topic_control) {
    if (msg == "ON") {
      digitalWrite(RELAY_PIN, HIGH);
      Serial.println("Relay ON");
    } else if (msg == "OFF") {
      digitalWrite(RELAY_PIN, LOW);
      Serial.println("Relay OFF");
    }
  }
}

void connectWiFi() {
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println(" Connected! IP: " + WiFi.localIP().toString());
}

void connectMQTT() {
  espClient.setInsecure();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(onMessage);

  while (!client.connected()) {
    Serial.print("Connecting to MQTT...");
    String clientId = "ESP32-" + String(random(0xffff), HEX);

    if (client.connect(clientId.c_str(), mqtt_user, mqtt_pass)) {
      Serial.println(" Connected!");
      // subscribe to relay control topic
      client.subscribe(topic_control);
      client.publish(topic_status, "awake");
    } else {
      Serial.print(" Failed rc=");
      Serial.println(client.state());
      delay(3000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  dht.begin();

  connectWiFi();
  connectMQTT();

  // read sensor
  delay(2000);
  float temperature = dht.readTemperature();
  float humidity    = dht.readHumidity();

  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("Failed to read DHT22!");
  } else {
    // publish to MQTT
    String tempStr = String(temperature, 1);
    String humStr  = String(humidity, 1);

    client.publish(topic_temp,     tempStr.c_str());
    client.publish(topic_humidity, humStr.c_str());

    Serial.println("Published temperature: " + tempStr);
    Serial.println("Published humidity   : " + humStr);
  }

  // wait a moment for messages to arrive
  for (int i = 0; i < 10; i++) {
    client.loop();
    delay(100);
  }

  // announce going to sleep
  client.publish(topic_status, "sleeping");
  Serial.println("Going to deep sleep for " + String(SLEEP_SECONDS) + " seconds...");

  // deep sleep
  esp_deep_sleep(SLEEP_SECONDS * 1000000ULL);
}

void loop() {
  // empty — everything runs in setup() before deep sleep
}