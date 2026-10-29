const int JOYSTICK_X = 39;
const int JOYSTICK_Y = 32;
const int JOYSTICK_SW = 33;

const int BUTTON_PIN = 27;
const int POT_PIN = 36;

void setup() {
  Serial.begin(115200);
  pinMode(JOYSTICK_SW, INPUT_PULLUP);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
}

void loop() {
  int x = analogRead(JOYSTICK_X);
  int y = analogRead(JOYSTICK_Y);

  int joystickButton = digitalRead(JOYSTICK_SW);

  int gameButton = digitalRead(BUTTON_PIN);

  int potValue = analogRead(POT_PIN);

  Serial.print(x);
  Serial.print(",");

  Serial.print(y);
  Serial.print(",");

  Serial.print(joystickButton);
  Serial.print(",");

  Serial.print(gameButton);
  Serial.print(",");

  Serial.println(potValue);

  delay(20);
}
