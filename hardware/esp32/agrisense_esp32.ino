#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <DHT.h>

// Configure these values for the farm device.
const char* WIFI_SSID = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";
const char* IOT_INGEST_URL = "https://YOUR_PROJECT_REF.supabase.co/functions/v1/iot-ingest";
const char* DEVICE_KEY = "PASTE_DEVICE_KEY_FROM_AGRISENSE";

// Example hardware. Change pins to match your board/wiring.
#define DHT_PIN 4
#define DHT_TYPE DHT22
#define SOIL_PIN 34
#define WATER_TRIG_PIN 26
#define WATER_ECHO_PIN 27
#define PUMP_RELAY_PIN 25

DHT dht(DHT_PIN, DHT_TYPE);

void connectWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
  }
}

float readSoilMoisture() {
  // Calibrate these two values for the actual sensor.
  const int dryRaw = 4095;
  const int wetRaw = 1500;
  int raw = analogRead(SOIL_PIN);
  float percent = 100.0f * (dryRaw - raw) / (dryRaw - wetRaw);
  return constrain(percent, 0.0f, 100.0f);
}

float readWaterLevelPercent() {
  digitalWrite(WATER_TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(WATER_TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(WATER_TRIG_PIN, LOW);

  unsigned long duration = pulseIn(WATER_ECHO_PIN, HIGH, 30000UL);
  if (duration == 0) return NAN;

  // Example tank geometry. Change these for your tank.
  const float emptyDistanceCm = 150.0f;
  const float fullDistanceCm = 20.0f;
  float distance = duration * 0.0343f / 2.0f;
  float percent = 100.0f * (emptyDistanceCm - distance) /
      (emptyDistanceCm - fullDistanceCm);
  return constrain(percent, 0.0f, 100.0f);
}

void postReading() {
  if (WiFi.status() != WL_CONNECTED) connectWiFi();

  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  float soil = readSoilMoisture();
  float water = readWaterLevelPercent();
  bool pumpOn = digitalRead(PUMP_RELAY_PIN) == LOW;

  if (isnan(temperature) || isnan(humidity)) return;

  WiFiClientSecure client;
  client.setInsecure(); // For production, pin the Supabase CA certificate.

  HTTPClient http;
  if (!http.begin(client, IOT_INGEST_URL)) return;
  http.addHeader("Content-Type", "application/json");

  String payload = "{";
  payload += "\"device_key\":\"" + String(DEVICE_KEY) + "\",";
  payload += "\"soil_moisture\":" + String(soil, 1) + ",";
  payload += "\"temperature\":" + String(temperature, 1) + ",";
  payload += "\"humidity\":" + String(humidity, 1) + ",";
  if (isnan(water)) {
    payload += "\"water_level\":null,";
  } else {
    payload += "\"water_level\":" + String(water, 1) + ",";
  }
  payload += "\"pump_on\":" + String(pumpOn ? "true" : "false");
  payload += "}";

  int status = http.POST(payload);
  Serial.printf("AgriSense telemetry HTTP status: %d\n", status);
  http.end();
}

void setup() {
  Serial.begin(115200);
  pinMode(WATER_TRIG_PIN, OUTPUT);
  pinMode(WATER_ECHO_PIN, INPUT);
  pinMode(PUMP_RELAY_PIN, OUTPUT);
  digitalWrite(PUMP_RELAY_PIN, HIGH); // Relay OFF for active-low modules.
  dht.begin();
  connectWiFi();
}

void loop() {
  postReading();
  delay(30000); // Send telemetry every 30 seconds.
}
