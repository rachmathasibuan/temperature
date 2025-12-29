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

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
const char server[] = "temp.transbrowser.com";  // <<< GANTI dengan domain server Anda
const int serverPort = 80;                // Port HTTP standar

#define API_KEY "wlksdnfUBDlkndfjbdjfSDJBmdflmdf"
#define MAX_RETRY       3
#define CLIENT_TIMEOUT  5000
#define SEND_INTERVAL   300000  // 5 menit

const uint8_t celsius[] = {
  SEG_A | SEG_B | SEG_F | SEG_G,
  SEG_A | SEG_D | SEG_E | SEG_F
};

void setup() {
  Serial.begin(9600);

  display.setBrightness(5);
  display.clear();

  Serial.println(F("Init Ethernet (DHCP)..."));

  if (Ethernet.begin(mac) == 0) {
    Serial.println(F("DHCP FAILED"));
    Serial.println(F("Check cable / router / DHCP server"));
    while (true); // STOP
  }

  delay(1000);

  Serial.println(F("NETWORK INFO"));
  Serial.print(F("IP Address  : "));
  Serial.println(Ethernet.localIP());
  Serial.print(F("Subnet Mask : "));
  Serial.println(Ethernet.subnetMask());
  Serial.print(F("Gateway     : "));
  Serial.println(Ethernet.gatewayIP());
  Serial.print(F("DNS Server  : "));
  Serial.println(Ethernet.dnsServerIP());

  dht.begin();
  pinMode(LED_BUILTIN, OUTPUT);

  Serial.println(F("System ready"));
}

bool sendData(float temp, float hum) {
  for (int attempt = 1; attempt <= MAX_RETRY; attempt++) {
    Serial.print(F("Connecting (try "));
    Serial.print(attempt);
    Serial.println(F(")..."));

    if (client.connect(server, serverPort)) {  // connect ke domain + port 80
      client.setTimeout(CLIENT_TIMEOUT);

      char body[40];
      char tStr[10], hStr[10];
      dtostrf(temp, 0, 2, tStr);
      dtostrf(hum, 0, 2, hStr);
      sprintf(body, "temp=%s&hum=%s", tStr, hStr);

      client.println(F("POST /data.php HTTP/1.1"));
      client.print(F("Host: "));
      client.println(server);  // Host harus domain, port 80 tidak perlu tulis
      client.println(F("Content-Type: application/x-www-form-urlencoded"));
      client.print(F("X-API-KEY: "));
      client.println(API_KEY);
      client.print(F("Content-Length: "));
      client.println(strlen(body));
      client.println(F("Connection: close"));
      client.println();
      client.print(body);

      unsigned long start = millis();
      while (client.connected() && millis() - start < CLIENT_TIMEOUT) {
        while (client.available()) {
          client.read();
        }
      }

      client.stop();
      Serial.println(F("Data sent OK"));
      return true;
    }

    client.stop();
    delay(1000);
  }

  Serial.println(F("Send failed"));
  return false;
}

void loop() {
  float hum  = dht.readHumidity();
  float temp = dht.readTemperature();

  if (isnan(hum) || isnan(temp)) {
    Serial.println(F("Sensor error"));
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
