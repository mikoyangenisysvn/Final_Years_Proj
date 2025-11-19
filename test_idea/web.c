#include <WiFi.h>
#include <Wire.h>
#include <WebServer.h>
#include <ArduinoJson.h>

//========= WiFi Router ==========
const char* ssid     = "Mobifone Cau Xeo";
const char* password = "22081595";

//========= I2C Settings =========
#define I2C_ADDR 0x20
#define SDA_PIN 21
#define SCL_PIN 22

//========= PWM Settings =========
#define CHANNELS 8
uint16_t period_val = 20000;       // PERIOD chung
uint8_t  duty_percent[CHANNELS];   // Duty tính theo %
                                    // FPGA = (period * duty%) / 100

//========= Web Server ==========
WebServer server(80);

//========= Web UI (HTML) =========
const char html_page[] PROGMEM = R"rawliteral(
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<title>Điều khiển 8 kênh PWM</title>
<style>
  body { font-family: Segoe UI; background:#0f172a; color:#e2e8f0; text-align:center; padding:20px; }
  .card { background:#1e293b; margin:auto; width:320px; padding:20px;
          border-radius:12px; box-shadow:0 0 10px #38bdf880; margin-bottom:20px; }
  input[type=range] { width:100%; }
  .val { color:#facc15; font-weight:bold; }
  button { padding:8px 20px; background:#38bdf8; color:#0f172a;
           border-radius:8px; border:none; cursor:pointer; margin-top:10px; }
</style>
</head>
<body>

<h1>⚙️ Điều khiển 8 kênh PWM</h1>

<div class="card">
  <h3>PERIOD chung</h3>
  <span class="val" id="pval">20000</span> µs<br>
  <input type="range" id="period" min="1000" max="20000" value="20000" step="100"
         oninput="document.getElementById('pval').innerText = this.value;">
</div>

<div id="channels"></div>

<button onclick="sendAll()">GỬI TOÀN BỘ</button>

<script>
  const CH = 8;
  const box = document.getElementById('channels');

  for (let i=0;i<CH;i++){
    box.innerHTML += `
      <div class="card">
        <h3>Kênh ${i+1}</h3>
        Duty: <span class="val" id="d${i}">50</span>%<br>
        <input type="range" id="r${i}" min="0" max="100" value="50"
               oninput="document.getElementById('d${i}').innerText=this.value;">
      </div>`;
  }

  function sendAll(){
    let data = {
      period: document.getElementById("period").value,
      duty: []
    };
    for (let i=0;i<CH;i++){
      data.duty.push( document.getElementById("r"+i).value );
    }

    fetch("/set_all", {
      method:"POST",
      headers:{ "Content-Type": "application/json"},
      body: JSON.stringify(data)
    })
    .then(r=>r.text())
    .then(t=>alert(t))
    .catch(e=>alert("Lỗi: "+e));
  }
</script>

</body>
</html>
)rawliteral";

//============= I2C helper (16-bit) =============
void i2cWrite16(uint16_t addr, uint16_t data){
  Wire.beginTransmission(I2C_ADDR);
  Wire.write(addr >> 8);
  Wire.write(addr & 0xFF);
  Wire.write(data >> 8);
  Wire.write(data & 0xFF);
  Wire.endTransmission();
}

//============= Gửi 1 channel =============
void sendChannel(uint8_t ch){
  uint16_t duty_raw = (period_val * duty_percent[ch]) / 100;

  uint16_t base = 0x20 * ch;

  i2cWrite16(base + 0x00, period_val);
  i2cWrite16(base + 0x08, duty_raw);
  i2cWrite16(base + 0x0C, 1);   // enable
}

//============= Web handle =============
void handleRoot(){
  server.send_P(200, "text/html", html_page);
}

void handleSetAll(){
  if (!server.hasArg("plain")) {
    server.send(400, "text/plain", "Thiếu JSON");
    return;
  }

  DynamicJsonDocument doc(2048);
  if (deserializeJson(doc, server.arg("plain"))) {
    server.send(400, "text/plain", "JSON lỗi");
    return;
  }

  period_val = doc["period"];

  for (int i=0;i<CHANNELS;i++){
    duty_percent[i] = doc["duty"][i];
    sendChannel(i);
  }

  server.send(200, "text/plain", "Đã gửi toàn bộ 8 kênh");
}

//============= Setup =============
void setup(){
  Serial.begin(115200);

  // WiFi STA mode
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.print("Đang kết nối WiFi");

  while (WiFi.status() != WL_CONNECTED){
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nĐã kết nối!");
  Serial.print("IP ESP32: ");
  Serial.println(WiFi.localIP());

  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(400000); // 400kHz nhanh hơn

  server.on("/", handleRoot);
  server.on("/set_all", HTTP_POST, handleSetAll);
  server.begin();

  for (int i=0;i<CHANNELS;i++) duty_percent[i] = 50;
}

//============= Loop =============
void loop(){
  server.handleClient();
}
