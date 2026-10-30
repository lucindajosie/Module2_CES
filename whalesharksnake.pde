import processing.serial.*;

PImage sharkImage;
PImage sardineImage;
PImage shellImage;

PFont cinzelFont;

float sharkX = 400;
float sharkY = 300;

float velocityX = 0;
float velocityY = 0;

float maxSpeed = 4.0;
float acceleration = 0.08;
float friction = 0.96;

float angle = 0;
float turnSpeed = 0.08;

float sharkWidth = 110;
float sharkHeight;

float mouthDistance = 75;
float eatingRadius = 20;

float boostMultiplier = 1.7;
float boostEnergyDrain = 0.15;
boolean boosting = false;

boolean upPressed = false;
boolean downPressed = false;
boolean leftPressed = false;
boolean rightPressed = false;

boolean shallowerPressed = false;
boolean deeperPressed = false;


ArrayList<PVector> fish = new ArrayList<PVector>();

int maxFish = 10;

float fishWidth = 30;
float fishHeight;

int fishSinceClear = 0;
int schoolsCleared = 0;

float schoolEnergyBonus = 15;

float energy = 100;
float maxEnergy = 100;

int score = 0;

boolean gameOver = false;

float depth = 50;
float depthTolerance = 12;

Serial esp32;

float joystickX = 0;
float joystickY = 0;

int joystickButton = 1;
int lastGameButton = 1;

boolean gameButtonRequested = false;

int lastButtonTime = -1000;
int lastSerialTime = -1000;

float joystickCenterX = 2048;
float joystickCenterY = 2048;

boolean joystickCalibrated = false;

float joystickDeadzone = 0.15;

float xDirection = 1;
float yDirection = 1;

void setup(){

  size(800, 600);
  frameRate(60);

  sharkImage = loadImage("wholeWhaleShark.png");
  sardineImage = loadImage("sardine.png");
  shellImage = loadImage("replayShell.png");

  cinzelFont = createFont("Cinzel-VariableFont_wght.ttf", 36);

  sharkHeight = sharkWidth * ((float)sharkImage.height/sharkImage.width);

  fishHeight = fishWidth *((float) sardineImage.height/sardineImage.width);

  
  printArray(Serial.list());
  
  String portName = Serial.list()[1];
  println(portName);
  
  esp32 = new Serial(this, portName, 115200);
  esp32.clear();
  esp32.bufferUntil('\n');
}

void draw(){
  if (gameButtonRequested) {
    gameButtonRequested = false;
    handleGameButton();
  }

  drawOceanBackground();

  //for keyboard controls
  if(!gameOver){
    if(shallowerPressed){
      depth -= 0.5;
    }

    if(deeperPressed){
      depth += 0.5;
    }

    depth = constrain(depth, 0, 100);
  }

  if (!gameOver){
    float targetX = 0;
    float targetY = 0;

    //for keyboard controls
    if (upPressed) targetY -= 1;
    if (downPressed) targetY += 1;
    if (leftPressed) targetX -= 1;
    if (rightPressed) targetX += 1;

    boolean keyboardMoving = upPressed || downPressed || leftPressed || rightPressed;

    if (!keyboardMoving && millis() - lastSerialTime < 600){
      targetX = joystickX;
      targetY = joystickY;
    }

    float magnitude = sqrt(targetX * targetX + targetY * targetY);

    boosting = joystickButton == 0 && millis() - lastSerialTime < 600 && magnitude > 0.05 &&
      energy > 0;

    float currentMaxSpeed = maxSpeed;

    if(boosting){
      currentMaxSpeed *= boostMultiplier;
    }

    if(magnitude > 0){
      if(magnitude > 1){
        targetX /= magnitude;
        targetY /= magnitude;
      }
      velocityX = lerp(velocityX, targetX * currentMaxSpeed, acceleration);
      velocityY = lerp(velocityY,targetY * currentMaxSpeed, acceleration);
    }else{
      velocityX *= friction;
      velocityY *= friction;

      if(abs(velocityX) < 0.05){
        velocityX = 0;
      }

      if(abs(velocityY) < 0.05){
        velocityY = 0;
      }
    }

    sharkX += velocityX;
    sharkY += velocityY;

    sharkX = constrain(sharkX, 20, width - 20);

    sharkY = constrain(sharkY, 20, height - 20);

    if(magnitude > 0.05){
      float targetAngle = atan2(targetY, targetX);

      float difference = atan2(sin(targetAngle - angle), cos(targetAngle - angle));

      angle += difference * turnSpeed;
    }
  }

  if(!gameOver){

    float speed = sqrt(velocityX * velocityX + velocityY * velocityY);

    energy -= 0.03;
    energy -= speed * 0.04;

    if(boosting){
      energy -= boostEnergyDrain;
    }

    energy = constrain(energy, 0, maxEnergy);

    eatFish();

    if(energy <= 0){
      gameOver = true;
      boosting = false;

      velocityX = 0;
      velocityY = 0;
    }
  }

  imageMode(CENTER);

  for(PVector f : fish){
    float depthDifference = abs(depth - f.z);

    if(depthDifference <= depthTolerance){
      noTint();

      noStroke();
      fill(130, 255, 220, 65);

      ellipse(f.x, f.y, fishWidth + 18, fishHeight + 18);

      image(sardineImage, f.x, f.y, fishWidth, fishHeight);
    }else{
      float opacity = map(depthDifference, depthTolerance, 55, 110, 20);

      opacity = constrain(opacity, 20, 110);
      tint(255, opacity);
      image(sardineImage, f.x, f.y, fishWidth, fishHeight);
      noTint();
    }
  }

  drawWhaleShark();
  drawEnergyBar();
  drawDepthMeter();

  textFont(cinzelFont);

  fill(255);
  textSize(20);

  text("Score: " + score, 20, 85);

  textSize(18);

  text("Depth: " + int(depth) + "%", 20, 115);

  if(boosting){
    fill(255, 225, 145);
    textSize(16);
    text("BOOST!", 20, 150);
  }

  if(gameOver){
    drawGameOverScreen();
  }
}


void keyPressed(){

  if(key == CODED){

    if (keyCode == UP) upPressed = true;
    if (keyCode == DOWN) downPressed = true;
    if (keyCode == LEFT) leftPressed = true;
    if (keyCode == RIGHT) rightPressed = true;
  }

  if(key == ' '){
    handleGameButton();
    return;
  }

  if(key == '['){
    shallowerPressed = true;
  }

  if(key == ']'){
    deeperPressed = true;
  }
}

void keyReleased(){

  if(key == CODED){

    if (keyCode == UP) upPressed = false;
    if (keyCode == DOWN) downPressed = false;
    if (keyCode == LEFT) leftPressed = false;
    if (keyCode == RIGHT) rightPressed = false;
  }

  if(key == '['){
    shallowerPressed = false;
  }

  if(key == ']'){
    deeperPressed = false;
  }
}


void handleGameButton(){

  if(gameOver){
    restartGame();
  }else{
    spawnFish(int(random(1, 6)));
  }
}

void serialEvent(Serial port){

  String line = port.readStringUntil('\n');
  if (line == null) return;
  line = trim(line);
  String[] values = split(line, ',');
  if (values.length != 5) return;
  try{
    int rawX = Integer.parseInt(trim(values[0]));

    int rawY = Integer.parseInt(trim(values[1]));

    int rawJoyButton = Integer.parseInt(trim(values[2]));

    int rawGameButton = Integer.parseInt(trim(values[3]));
      
    int potValue = Integer.parseInt(trim(values[4]));

    if(!joystickCalibrated){
      joystickCenterX = rawX;
      joystickCenterY = rawY;
      joystickCalibrated = true;
      lastGameButton = rawGameButton;
    }

    joystickX = normalizeJoystick(rawX, joystickCenterX) * xDirection;
    joystickY = normalizeJoystick(rawY, joystickCenterY) * yDirection;
    joystickButton = rawJoyButton;
    lastSerialTime = millis();
    depth = map(potValue, 0, 4095, 0, 100);
    depth = constrain(depth, 0, 100);

    if(lastGameButton == 1 && rawGameButton == 0 && millis() - lastButtonTime > 180){
      gameButtonRequested = true;
      lastButtonTime = millis();
    }

    lastGameButton = rawGameButton;

    }catch(NumberFormatException e){
  }
}

float normalizeJoystick(float reading, float center){
   float result;
   if(reading >= center){
     result = (reading - center)/max(1.0, 4095.0 - center);
    }else{
     result = (reading - center) / max(1.0, center);
    }
    result = constrain(result, -1, 1);
  
    if(abs(result) < joystickDeadzone){
      return 0;
    }
  
    return (abs(result) - joystickDeadzone) / (1 - joystickDeadzone) * (result > 0 ? 1 : -1);
}


void drawWhaleShark(){
  pushMatrix();
  translate(sharkX, sharkY);
  rotate(angle + HALF_PI);
  imageMode(CENTER);
  noTint();
  image(sharkImage, 0, 0, sharkWidth, sharkHeight);
  popMatrix();
}


void spawnFish(int numFish){
  numFish = min(numFish, maxFish - fish.size());
  fishSinceClear += numFish;
  for(int i = 0; i < numFish; i++){
    float x = random(40, width - 40);
    float y = random(40, height - 40);
    float fishDepth = random(0, 100);
    fish.add(new PVector(x, y, fishDepth));
  }
}

void eatFish(){
  PVector mouth = getMouthPosition();
  for(int i = fish.size() - 1; i >= 0; i--){
    PVector f = fish.get(i);
    float distance = dist(mouth.x, mouth.y, f.x, f.y);
    float depthDifference = abs(depth - f.z);

    if(distance < eatingRadius && depthDifference <= depthTolerance){
      fish.remove(i);
      score++;
      energy += 20;
      energy = constrain(energy, 0, maxEnergy);
    }
  }

  if(fish.isEmpty() && fishSinceClear >= 3){
    schoolsCleared++;
    energy += schoolEnergyBonus;
    energy = constrain(energy, 0, maxEnergy);
    fishSinceClear = 0;
    println("School cleared! Total: " + schoolsCleared);
  }
}

void drawEnergyBar(){
  float barX = 20;
  float barY = 30;
  float barW = 200;
  float barH = 20;
  stroke(255);
  strokeWeight(1);
  noFill();
  rect(barX, barY, barW, barH);
  noStroke();
  fill(80, 220, 120);
  rect(barX, barY, map(energy, 0, maxEnergy, 0, barW), barH);
  textFont(cinzelFont);
  fill(255);
  textSize(16);
  text("Energy", barX, barY - 8);
}

PVector getMouthPosition(){
  float mouthX = sharkX + cos(angle) * mouthDistance;
  float mouthY = sharkY + sin(angle) * mouthDistance;
  return new PVector(mouthX, mouthY);
}


void restartGame(){
  sharkX = width / 2;
  sharkY = height / 2;
  velocityX = 0;
  velocityY = 0;
  angle = 0;
  boosting = false;
  upPressed = false;
  downPressed = false;
  leftPressed = false;
  rightPressed = false;
  shallowerPressed = false;
  deeperPressed = false;
  fishSinceClear = 0;
  schoolsCleared = 0;
  energy = maxEnergy;
  score = 0;
  fish.clear();
  gameOver = false;
  depth = 50;
}

void drawOceanBackground(){
  color shallowTop = color(28, 145, 175);
  color shallowBottom = color(7, 65, 105);

  color deepTop = color(5, 34, 75);
  color deepBottom = color(2, 12, 38);

  float d = depth / 100.0;

  color topColor = lerpColor(shallowTop, deepTop, d);
  color bottomColor = lerpColor(shallowBottom, deepBottom, d);

  strokeWeight(1);

  for(int y = 0; y < height; y++){
    float t = (float)y / height;
    stroke(lerpColor(topColor, bottomColor, t));
    line(0, y, width, y);
  }
}


void drawDepthMeter(){
  float barX = width - 50;
  float barY = 90;
  float barW = 15;
  float barH = 400;

  noStroke();
  fill(20, 70, 110);
  rect(barX, barY, barW, barH, 7);

  for(PVector f : fish){
    float fishY = map(f.z, 0, 100, barY, barY + barH);

    if(abs(depth - f.z) <= depthTolerance){
      fill(150, 255, 190);
    }else{
      fill(255, 200, 120);
    }

    noStroke();
    ellipse(barX + barW / 2, fishY, 10, 10);
  }

  float sharkDepthY = map(depth, 0, 100, barY, barY + barH);

  stroke(255);
  strokeWeight(3);
  line(barX - 10, sharkDepthY, barX + barW + 10, sharkDepthY);
  textFont(cinzelFont);
  fill(255);
  textSize(13);
  textAlign(CENTER, BASELINE);

  text("SURFACE", barX + barW / 2, barY - 15);
  text("DEEP", barX + barW / 2, barY + barH + 25);
  text("DEPTH", barX + barW / 2, 40);
  
  text(int(depth) + "%", barX + barW / 2, 58);
  textAlign(LEFT, BASELINE);
  noStroke();
}


void drawGameOverScreen(){
  noStroke();
  fill(3, 19, 37, 210);
  rect(0, 0, width, height);

  float panelX = 170;
  float panelY = 55;
  float panelW = 460;
  float panelH = 490;

  fill(12, 53, 73, 245);
  stroke(114, 183, 186, 130);
  strokeWeight(2);

  rect(panelX, panelY, panelW, panelH, 24);

  textFont(cinzelFont);
  textAlign(CENTER, CENTER);

  fill(255, 235, 207);
  textSize(38);

  text("YOUR SWIM ENDS", width / 2, 123);

  fill(173, 214, 220);
  textSize(16);
  text("You ran out of energy", width / 2, 161);

  stroke(100, 174, 185);
  strokeWeight(1);
  line(245, 192, 555, 192);
  noStroke();

  fill(171, 215, 218);
  textSize(15);

  text("SARDINES EATEN", 300, 229);

  text("SCHOOLS CLEARED", 500, 229);

  fill(255);
  textSize(30);
  text(score, 300, 267);
  text(schoolsCleared, 500, 267);
  imageMode(CENTER);

  float shellW = 140 + 5 * sin(frameCount * 0.06);

  float shellH = shellW * ((float)shellImage.height / shellImage.width);
  noTint();

  image(shellImage, width / 2, 382, shellW, shellH);

  fill(255, 232, 191);
  textSize(17);

  text("PRESS BUTTON TO DIVE AGAIN", width / 2, 466);

  fill(173, 214, 220);
  textSize(13);

  text("BUTTON to replay", width / 2, 499);

  textAlign(LEFT, BASELINE);
  imageMode(CENTER);
  noStroke();
}
