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
byte ip[]  = { 172, 18, 20, 242 };
char server[] = "temp.transfashion.id";

#define API_KEY "wlksdnfUBDlkndfjbdjfSDJBmdflmdf"

const uint8_t celsius[] = {
  SEG_A | SEG_B | SEG_F | SEG_G,
  SEG_A | SEG_D | SEG_E | SEG_F
};

void setup() {
  Serial.begin(9600);

  display.setBrightness(5);
  display.clear();

  Ethernet.begin(mac, ip);
  dht.begin();

  pinMode(LED_BUILTIN, OUTPUT);

  Serial.println("System ready");
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

  if (client.connect(server, 80)) {
    Serial.println("Connected to server");

    client.print("GET /data.php?key=");
    client.print(API_KEY);
    client.print("&temp=");
    client.print(temp);
    client.print("&hum=");
    client.println(hum);

    client.println("Host: temp.transfashion.id");
    client.println("Connection: close");
    client.println();

    digitalWrite(LED_BUILTIN, HIGH);
    delay(100);
    digitalWrite(LED_BUILTIN, LOW);

    client.stop();
    Serial.println("Data sent");
  } else {
    Serial.println("Connection failed");
  }

  delay(300000);
}
