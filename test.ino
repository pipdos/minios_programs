#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

Adafruit_SSD1306 display(128, 64, &Wire, -1);

int count = 0;
bool lastBtn = false;

void setup() {
  pinMode(0, INPUT_PULLUP);
  Wire.begin(21, 22);
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.clearDisplay();
  display.display();
}

void loop() {
  bool btn = (digitalRead(0) == LOW);

  // Нажали кнопку
  if (btn && !lastBtn) {
    count++;
    display.clearDisplay();
    display.setTextColor(WHITE);
    display.setTextSize(2);
    display.setCursor(10, 10);
    display.print("Count:");
    display.setTextSize(4);
    display.setCursor(30, 32);
    display.print(count);
    display.display();
  }

  lastBtn = btn;
  delay(50);
}
