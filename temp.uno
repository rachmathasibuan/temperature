#include <TM1637Display.h>
#include <SPI.h>
#include <Ethernet.h>
#include "DHT.h"

#define CLK 8
#define DIO 9
#define DHTPIN 2
#define DHTTYPE DHT11

TM1637Display display(CLK, DIO);
DHT dht(DHTPIN, DHTTYPE);
EthernetClient client;

byte mac[]     = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[]      = { 172, 18, 20, 242 };
byte subnet[]  = { 255, 255, 255, 0 };
byte gateway[] = { 172, 18, 20, 1 };
byte dns[]     = { 1, 1, 1, 1 };
byte server[]  = { 172, 18, 10, 111 };
const int serverPort = 8086;


#define API_KEY "wlksdnfUBDlkndfjbdjfSDJBmdflmdf"

#define MAX_RETRY     3
#define CLIENT_TIMEOUT 5000   // ms
#define SEND_INTERVAL 300000  // 5 menit

const uint8_t celsius[] = {
  SEG_A | SEG_B | SEG_F | SEG_G,
  SEG_A | SEG_D | SEG_E | SEG_F
};

void setup() {
  Serial.begin(9600);

  display.setBrightness(5);
  display.clear();

  // --- Ethernet init: DHCP fallback ---
  Serial.println("Init Ethernet...");
  if (Ethernet.begin(mac) == 0) {
    Serial.println("DHCP failed, using static IP");
    Ethernet.begin(mac, ip, dns, gateway, subnet);
  }

  delay(1000);

  Serial.println("=== NETWORK INFO ===");
  Serial.print("IP      : "); Serial.println(Ethernet.localIP());
  Serial.print("Gateway : "); Serial.println(Ethernet.gatewayIP());
  Serial.print("DNS     : "); Serial.println(Ethernet.dnsServerIP());

  dht.begin();
  pinMode(LED_BUILTIN, OUTPUT);

  Serial.println("System ready");
}

bool sendData(float temp, float hum) {
  for (int attempt = 1; attempt <= MAX_RETRY; attempt++) {
    Serial.print("Connecting (try ");
    Serial.print(attempt);
    Serial.println(")...");

    if (client.connect(server, serverPort)) {
      client.setTimeout(CLIENT_TIMEOUT);

      client.println("POST / HTTP/1.1");
      client.println("Host: 172.18.10.111:8086");
      client.println("Content-Type: application/x-www-form-urlencoded");
      client.print("X-API-KEY: ");
      client.println(API_KEY);

      String body = "temp=" + String(temp) + "&hum=" + String(hum);
      client.print("Content-Length: ");
      client.println(body.length());
      client.println();
      client.print(body);

      unsigned long start = millis();
      while (client.connected() && millis() - start < CLIENT_TIMEOUT) {
        if (client.available()) {
          client.read();
        }
      }

      client.stop();
      Serial.println("Data sent OK");
      return true;
    }

    client.stop();
    delay(1000);
  }

  Serial.println("Send failed after retries");
  return false;
}

void loop() {
  float hum  = dht.readHumidity();
  float temp = dht.readTemperature();

  if (isnan(hum) || isnan(temp)) {
    Serial.println("Sensor error");
    delay(5000);
    return;
  }

  display.showNumberDec((int)temp, false, 2, 0);
  display.setSegments(celsius, 2, 2);

  if (sendData(temp, hum)) {
    digitalWrite(LED_BUILTIN, HIGH);
    delay(100);
    digitalWrite(LED_BUILTIN, LOW);
  }

  delay(SEND_INTERVAL);
}
