#include <Arduino.h>

#include <Wire.h>

#define EEPROM_ADDR 0x50  // Địa chỉ I2C của EEPROM (A0/A1/A2 = GND)

uint16_t reg = 0 ;
uint32_t valueWrite = 0;
uint32_t valueRead = 0;
uint32_t i_old = 0;
uint8_t shift=1;

uint32_t eepromRead(uint16_t regAddr);
void eepromWrite(uint16_t regAddr, uint32_t data);

uint8_t ror8(uint8_t val) {
    return (val >> 1) | (val << 7);
}

void setup() {
  Serial.begin(9600);    // Khởi tạo Serial ở tốc độ baud 9600 để in dữ liệu ra màn hình Serial Monitor

  // Khởi tạo giao tiếp I2C với chân D2 làm SDA (GPIO4) và D1 làm SCL (GPIO5) trên NodeMCU
  Wire.begin(D2, D1);

  // Thiết lập tốc độ clock I2C = 400kHz (Fast Mode)
 // Wire.setClock(400000);  
  
}


void loop() {
  eepromWrite(0, 0x1);
  eepromWrite(4, 0x64);
  eepromWrite(14, 270);

  for (uint32_t i = 0; i < 64; i++)
  {
    eepromWrite(8, i);
    eepromWrite(12, 64-i);
  }
  for (uint32_t i = 64; i > 0; i--)
  {
    eepromWrite(8, i);
    eepromWrite(12, 64-i);
  }
  

}


void eepromWrite(uint16_t regAddr, uint32_t data) {
  Wire.beginTransmission(EEPROM_ADDR);

  // Gửi 2 byte địa chỉ thanh ghi
  Wire.write((regAddr >> 8) & 0xFF);  // Byte cao
  Wire.write(regAddr & 0xFF);         // Byte thấp

  // Gửi 4 byte data (big-endian)
  Wire.write((data >> 24) & 0xFF);
  Wire.write((data >> 16) & 0xFF);
  Wire.write((data >> 8) & 0xFF);
  Wire.write(data & 0xFF);

  Wire.endTransmission();

  delay(5);  // EEPROM cần thời gian ghi (~5ms)
}

uint32_t eepromRead(uint16_t regAddr) {
  uint32_t data = 0;

  Wire.beginTransmission(EEPROM_ADDR);
  Wire.write((regAddr >> 8) & 0xFF);  // Byte cao
  Wire.write(regAddr & 0xFF);         // Byte thấp

  // Gửi repeated start thay vì stop
  Wire.endTransmission(false);  // false = giữ bus, SR

  Wire.requestFrom((uint8_t)EEPROM_ADDR, (uint8_t)4);

  if (Wire.available() == 4) {
    data |= ((uint32_t)Wire.read() << 24);
    data |= ((uint32_t)Wire.read() << 16);
    data |= ((uint32_t)Wire.read() << 8);
    data |= ((uint32_t)Wire.read());
  }

  return data;
}

/*
EXAMPLE
  // reg = 0; // Địa chỉ ô nhớ EEPROM = 0  
  // valueWrite = 0; // Gán giá trị sẽ ghi = 0
  

  // // In ra giá trị chuẩn bị ghi vào EEPROM
  // Serial.print("Write: 0x");
  // Serial.println(valueWrite, HEX);

  // // Ghi giá trị 0 vào địa chỉ 0 của EEPROM
  // eepromWrite(reg, valueWrite);

  // // Đọc lại giá trị vừa ghi từ EEPROM
  // valueRead = eepromRead(reg);

  // // In ra giá trị đọc được từ EEPROM để kiểm tra
  // Serial.print("Read: 0x");
  // Serial.println(valueRead, HEX);
*/