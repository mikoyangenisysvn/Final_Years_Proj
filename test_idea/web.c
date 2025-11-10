#include <WiFi.h>
#include <Wire.h>
#include <WebServer.h>
#include <ArduinoJson.h>

//================ WiFi ===================
const char* ssid = "ESP32_PWM_SERVER";
const char* password = "12345678";

//================ I2C ===================
#define I2C_ADDR 0x20
#define SDA_PIN 21
#define SCL_PIN 22
#define CHANNELS 16

//================ Web Server =============
WebServer server(80);

//================ PWM 16 kênh =============
uint16_t period_val[CHANNELS];
uint16_t duty_val[CHANNELS];

//================ HTML giao diện ==========
const char html_page[] PROGMEM = R"rawliteral(
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Điều khiển 16 kênh PWM</title>
  <style>
    body { font-family: 'Segoe UI', sans-serif; background: #0f172a; color: #e2e8f0; margin: 0; padding: 0; }
    h1 { text-align: center; background: #0ea5e9; color: white; padding: 12px 0; margin: 0; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 16px; padding: 20px; }
    .channel { background: #1e293b; border-radius: 12px; padding: 16px; box-shadow: 0 0 10px #0ea5e980; }
    h3 { color: #38bdf8; margin-top: 0; }
    input[type=range] { width: 100%; }
    .value { color: #facc15; font-weight: bold; }
    button { background: #38bdf8; color: #0f172a; border: none; padding: 6px 12px; margin-top: 6px; border-radius: 6px; cursor: pointer; font-weight: bold; transition: 0.2s; }
    button:hover { background: #0ea5e9; }
    #sendAll { display: block; width: 200px; margin: 20px auto; font-size: 16px; }
  </style>
</head>
<body>
  <h1>⚙️ Điều khiển 16 Kênh PWM</h1>
  <div class="grid" id="channels"></div>
  <button id="sendAll" onclick="sendAll()">GỬI TOÀN BỘ 16 KÊNH</button>

  <script>
    const NUM_CHANNELS = 16;
    const channelsDiv = document.getElementById('channels');

    for (let i = 0; i < NUM_CHANNELS; i++) {
      channelsDiv.innerHTML += `
        <div class="channel" id="ch${i}">
          <h3>Kênh PWM ${i+1}</h3>
          <label>Period: <span class="value" id="pval${i}">20000</span></label><br>
          <input type="range" id="period${i}" min="1000" max="20000" step="100" value="20000" 
                 oninput="updateValue(${i}, 'p')"><br>
          <label>Duty: <span class="value" id="dval${i}">1500</span></label><br>
          <input type="range" id="duty${i}" min="0" max="20000" step="100" value="1500" 
                 oninput="updateValue(${i}, 'd')"><br>
          <button onclick="sendChannel(${i})">Gửi Kênh ${i+1}</button>
        </div>`;
    }

    function updateValue(i, type) {
      if (type === 'p') document.getElementById('pval' + i).innerText = document.getElementById('period' + i).value;
      else document.getElementById('dval' + i).innerText = document.getElementById('duty' + i).value;
    }

    function sendChannel(i) {
      const period = document.getElementById('period' + i).value;
      const duty   = document.getElementById('duty' + i).value;
      fetch(`/set_pwm?ch=${i}&period=${period}&duty=${duty}`)
        .then(r => r.text())
        .then(t => alert("Đã gửi: " + t))
        .catch(e => alert("Lỗi gửi: " + e));
    }

    function sendAll() {
      let payload = [];
      for (let i = 0; i < NUM_CHANNELS; i++) {
        payload.push({ ch: i, period: document.getElementById('period' + i).value, duty: document.getElementById('duty' + i).value });
      }
      fetch('/set_all', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      })
      .then(r => r.text())
      .then(t => alert("Đã gửi toàn bộ: " + t))
      .catch(e => alert("Lỗi gửi tất cả: " + e));
    }
  </script>
</body>
</html>
)rawliteral";

//================= Hàm gửi I2C ===========
void sendToTangNano(uint16_t addr, uint32_t data) {
  Wire.beginTransmission(I2C_ADDR);
  Wire.write((addr >> 8) & 0xFF);
  Wire.write(addr & 0xFF);
  Wire.write((data >> 24) & 0xFF);
  Wire.write((data >> 16) & 0xFF);
  Wire.write((data >> 8) & 0xFF);
  Wire.write(data & 0xFF);
  Wire.endTransmission();
}

//================= Gửi 1 kênh ===========
void sendChannel(int ch) {
  uint16_t period = period_val[ch];
  uint16_t duty   = duty_val[ch];
  uint16_t base_addr = 0x20 * ch;

  sendToTangNano(base_addr + 0x00, period); // PERIOD
  sendToTangNano(base_addr + 0x08, duty);   // CCR
  sendToTangNano(base_addr + 0x0C, 0x1);    // CONTROL = ENABLE
}

//================= Web Handlers ==========
void handleRoot() {
  server.send_P(200, "text/html", html_page);
}

void handleSetPWM() {
  if (server.hasArg("ch") && server.hasArg("period") && server.hasArg("duty")) {
    int ch = server.arg("ch").toInt();
    if (ch < 0 || ch >= CHANNELS) {
      server.send(400, "text/plain", "Kênh không hợp lệ");
      return;
    }
    period_val[ch] = server.arg("period").toInt();
    duty_val[ch]   = server.arg("duty").toInt();

    sendChannel(ch);
    server.send(200, "text/plain", "Đã gửi kênh " + String(ch));
  } else {
    server.send(400, "text/plain", "Thiếu tham số ch/period/duty");
  }
}

void handleSetAll() {
  if (!server.hasArg("plain")) {
    server.send(400, "text/plain", "Thiếu body JSON");
    return;
  }
  DynamicJsonDocument doc(4096);
  DeserializationError err = deserializeJson(doc, server.arg("plain"));
  if (err) {
    server.send(400, "text/plain", "Lỗi JSON");
    return;
  }

  for (int i = 0; i < CHANNELS; i++) {
    period_val[i] = doc[i]["period"];
    duty_val[i]   = doc[i]["duty"];
    sendChannel(i);
  }
  server.send(200, "text/plain", "Đã gửi toàn bộ 16 kênh");
}

//================= Setup ==================
void setup() {
  Serial.begin(115200);

  Wire.begin(SDA_PIN, SCL_PIN);
  WiFi.softAP(ssid, password);
  Serial.print("IP ESP32 AP: ");
  Serial.println(WiFi.softAPIP());

  server.on("/", handleRoot);
  server.on("/set_pwm", handleSetPWM);
  server.on("/set_all", HTTP_POST, handleSetAll);
  server.begin();

  Serial.println("Web server sẵn sàng");

  for (int i = 0; i < CHANNELS; i++) {
    period_val[i] = 20000;
    duty_val[i]   = 1500;
  }
}

//================= Loop ==================
void loop() {
  server.handleClient();
}
