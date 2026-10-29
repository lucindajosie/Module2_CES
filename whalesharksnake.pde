
float sharkX = 400;
float sharkY = 300;

PImage sharkImage;
PImage sardineImage;

// Current swimming velocity
float velocityX = 0;
float velocityY = 0;

// Movement settings
float maxSpeed = 4.0;
float acceleration = 0.08;
float friction = 0.96;

// Direction the shark faces
float angle = 0;
float turnSpeed = 0.08;

// Keyboard controls
boolean upPressed = false;
boolean downPressed = false;
boolean leftPressed = false;
boolean rightPressed = false;

ArrayList <PVector> fish = new ArrayList<PVector>();

int maxFish = 10;

float energy = 100;
float maxEnergy = 100;

int score = 0;

boolean gameOver = false;

float sharkWidth = 110;
float sharkHeight;
float fishWidth = 30;
float fishHeight;

float mouthDistance = 75;
float eatingRadius = 20;

int fishSinceClear = 0;
int schoolsCleared = 0;

float depth = 50;

float depthTolerance = 12;

boolean shallowerPressed = false;
boolean deeperPressed = false;

PImage shellImage;

void setup() {
  size(800, 600);
  frameRate(60);
  
  sharkImage = loadImage("wholeWhaleShark.png");
  sardineImage = loadImage("sardine.png");
  shellImage = loadImage("replayShell.png");
  sharkHeight = sharkWidth * ((float) sharkImage.height / sharkImage.width);
  fishHeight = fishWidth * ((float) sardineImage.height/sardineImage.width);
}

void draw() {
  drawOceanBackground();
  if (!gameOver) {
    if (shallowerPressed) {
      depth -= 0.5;
    }
  
    if (deeperPressed) {
      depth += 0.5;
    }
  
    depth = constrain(depth, 0, 100);
  }

if(!gameOver){
  // Desired swimming direction
  float targetX = 0;
  float targetY = 0;

  if (upPressed) targetY -= 1;
  if (downPressed) targetY += 1;
  if (leftPressed) targetX -= 1;
  if (rightPressed) targetX += 1;

  // Calculate joystick-like input strength
  float magnitude = sqrt(targetX * targetX +
                         targetY * targetY);

  if (magnitude > 0) {

    // Normalize direction
    targetX /= magnitude;
    targetY /= magnitude;

    // Gradually accelerate toward desired velocity
    velocityX = lerp(velocityX,
                     targetX * maxSpeed,
                     acceleration);

    velocityY = lerp(velocityY,
                     targetY * maxSpeed,
                     acceleration);

  } else {

    // Gradually slow down when controls are released
    velocityX *= friction;
    velocityY *= friction;

    // Stop completely when moving very slowly
    if (abs(velocityX) < 0.05) velocityX = 0;
    if (abs(velocityY) < 0.05) velocityY = 0;
  }

  // Update position
  sharkX += velocityX;
  sharkY += velocityY;

  // Keep the shark inside the screen for now
  sharkX = constrain(sharkX, 20, width - 20);
  sharkY = constrain(sharkY, 20, height - 20);
  

  // Determine direction the shark should face
  if (abs(velocityX) + abs(velocityY) > 0.1) {
    float targetAngle = atan2(velocityY, velocityX);

    // Gradually rotate toward that direction
    float difference = atan2(
      sin(targetAngle - angle),
      cos(targetAngle - angle)
    );

    angle += difference * turnSpeed;
  }
}
  
  if(!gameOver){
    float speed = sqrt(velocityX * velocityX + velocityY * velocityY);
    
    energy -= 0.03;
    
    energy -= speed * 0.04;
    
    energy = constrain(energy, 0, maxEnergy);
    
    eatFish();
    
    if (energy <=0){
      gameOver = true;
      velocityX = 0;
      velocityY = 0;
    }
  }

  
  
  imageMode(CENTER);
  
  for (PVector f : fish) {
  
    float depthDifference = abs(depth - f.z);
  
    if (depthDifference <= depthTolerance) {
  
      // Fish at your depth are fully visible
      noTint();
  
      // Draw a glowing circle behind edible fish
      noStroke();
      fill(130, 255, 220, 65);
      ellipse(f.x, f.y, fishWidth + 18, fishHeight + 18);
  
      // Draw sardine normally
      image(sardineImage, f.x, f.y, fishWidth, fishHeight);
  
    } else {
  
      // Fish at other depths appear faded
      float opacity = map(depthDifference,
                          depthTolerance, 55,
                          110, 20);
  
      opacity = constrain(opacity, 20, 110);
  
      tint(255, opacity);
      image(sardineImage, f.x, f.y, fishWidth, fishHeight);
      noTint();
    }
  }


  drawWhaleShark();
  PVector mouth = getMouthPosition();

  noFill();
  stroke(255, 255, 0);
  strokeWeight(2);
  
  ellipse(mouth.x, mouth.y,
          eatingRadius * 2, eatingRadius * 2);
  drawEnergyBar();
  drawDepthMeter();
  
  fill(255);
  textSize(20);
  text("Score: " + score, 20, 75);
  textSize(18);
  text("Depth: " + int(depth) + "%", 20, 105);

  if (gameOver) {
    drawGameOverScreen();
  }
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) upPressed = true;
    if (keyCode == DOWN) downPressed = true;
    if (keyCode == LEFT) leftPressed = true;
    if (keyCode == RIGHT) rightPressed = true;
  }
  
  if (key == ' '){
    if(gameOver){
      restartGame();
    }else{
      spawnFish(int(random(1, 6)));
    }
    
    return;
  }
  if (key == '[') {
    shallowerPressed = true;
  }
  
  if (key == ']') {
    deeperPressed = true;
  }
}

void keyReleased() {
  if (key == CODED) {
    if (keyCode == UP) upPressed = false;
    if (keyCode == DOWN) downPressed = false;
    if (keyCode == LEFT) leftPressed = false;
    if (keyCode == RIGHT) rightPressed = false;
  }
  if (key == '[') {
    shallowerPressed = false;
  }
  
  if (key == ']') {
    deeperPressed = false;
  }
}

void drawWhaleShark(){
  pushMatrix();
  
  translate(sharkX, sharkY);
  
  rotate(angle + HALF_PI);
  
  imageMode(CENTER);
  
  image(sharkImage, 0, 0, sharkWidth, sharkHeight);
  popMatrix();
  
}

void spawnFish(int numFish){
  numFish = min(numFish, maxFish - fish.size());
  fishSinceClear += numFish;
  for (int i = 0; i < numFish; i++){
    float x = random(40, width - 40);
    float y = random(40, height - 40);
    float fishDepth = random(0, 100);
    fish.add(new PVector(x, y, fishDepth));
  }
}


void eatFish() {

  PVector mouth = getMouthPosition();

  for (int i = fish.size() - 1; i >= 0; i--) {

    PVector f = fish.get(i);

    // Distance between the mouth and the sardine
    float distance = dist(mouth.x, mouth.y, f.x, f.y);

    // Difference in ocean depth
    float depthDifference = abs(depth - f.z);

    // Both conditions must be true to eat the sardine
    if (distance < eatingRadius &&
        depthDifference <= depthTolerance) {

      fish.remove(i);
      score++;

      energy += 20;
      energy = constrain(energy, 0, maxEnergy);
    }
  }
}


void drawEnergyBar() {
  float barX = 20;
  float barY = 20;
  float barW = 200;
  float barH = 20;

  stroke(255);
  noFill();
  rect(barX, barY, barW, barH);

  noStroke();
  fill(80, 220, 120);
  rect(barX, barY, map(energy, 0, maxEnergy, 0, barW), barH);

  fill(255);
  textSize(16);
  text("Energy", barX, barY - 8);
}


PVector getMouthPosition() {

  float mouthX = sharkX + cos(angle) * mouthDistance;
  float mouthY = sharkY + sin(angle) * mouthDistance;

  return new PVector(mouthX, mouthY);
}

void restartGame(){
  sharkX = width/2;
  sharkY = height/2;
  
  velocityX = 0;
  velocityY = 0;
  angle = 0;
  
  upPressed = false;
  downPressed = false;
  leftPressed = false;
  rightPressed = false;
  
  fishSinceClear = 0;
  schoolsCleared = 0;
  
  energy = maxEnergy;
  score = 0;
  
  fish.clear();
  
  gameOver = false;
  
  depth = 50;
  shallowerPressed = false;
  deeperPressed = false;
}

void drawOceanBackground() {
  color shallowTop = color(28, 145, 175);
  color shallowBottom = color(7, 65, 105);

  color deepTop = color(5, 34, 75);
  color deepBottom = color(2, 12, 38);

  float d = depth/100.0;
  color topColor = lerpColor(shallowTop, deepTop, d);
  color bottomColor = lerpColor(shallowBottom, deepBottom, d);

  strokeWeight(1);

  for (int y = 0; y < height; y++) {
    float t = (float)y / height;
    stroke(lerpColor(topColor, bottomColor, t));
    line(0, y, width, y);
  }
}


void drawDepthMeter() {

  float barX = width - 50;
  float barY = 90;
  float barW = 15;
  float barH = 400;

  // Draw background of the depth meter
  noStroke();
  fill(20, 70, 110);
  rect(barX, barY, barW, barH, 7);

  // Draw markers for each sardine
  for (PVector f : fish) {

    float fishY = map(f.z, 0, 100,
                      barY, barY + barH);

    if (abs(depth - f.z) <= depthTolerance) {
      fill(150, 255, 190);
    } else {
      fill(255, 200, 120);
    }

    noStroke();
    ellipse(barX + barW / 2, fishY, 10, 10);
  }

  // Position of the whale shark's depth
  float sharkDepthY = map(depth, 0, 100,
                          barY, barY + barH);

  // Draw a white marker for the shark
  stroke(255);
  strokeWeight(3);
  line(barX - 10, sharkDepthY,
       barX + barW + 10, sharkDepthY);

  // Labels
  fill(255);
  textSize(13);

  textAlign(CENTER, BASELINE);
  text("SURFACE", barX + barW / 2, barY - 25);
  text("DEEP", barX + barW / 2, barY + barH + 25);

  text("DEPTH", barX + barW / 2, 40);
  text(int(depth) + "%", barX + barW / 2, 58);

  // Reset drawing settings
  textAlign(LEFT, BASELINE);
  noStroke();
}


void drawGameOverScreen() {

  // Darken the underwater background
  noStroke();
  fill(3, 19, 37, 210);
  rect(0, 0, width, height);

  // Main panel
  float panelX = 170;
  float panelY = 55;
  float panelW = 460;
  float panelH = 490;

  fill(12, 53, 73, 245);
  stroke(114, 183, 186, 130);
  strokeWeight(2);
  rect(panelX, panelY, panelW, panelH, 24);

  // Title
  textAlign(CENTER, CENTER);
  fill(255, 235, 207);
  textSize(34);
  text("YOUR JOURNEY ENDS", width / 2, 123);

  // Subtitle
  fill(173, 214, 220);
  textSize(16);
  text("Even the ocean needs a moment of rest.",
       width / 2, 161);

  // Decorative divider
  stroke(100, 174, 185);
  strokeWeight(1);
  line(245, 192, 555, 192);

  // Final score
  noStroke();
  fill(171, 215, 218);
  textSize(15);
  text("SARDINES EATEN", 300, 229);
  text("SCHOOLS CLEARED", 500, 229);

  fill(255);
  textSize(30);
  text(score, 300, 267);
  text(schoolsCleared, 500, 267);

  // Replay shell
  imageMode(CENTER);

  float shellW = 140 + 5 * sin(frameCount * 0.06);
  float shellH = shellW *
    ((float)shellImage.height / shellImage.width);

  image(shellImage, width / 2, 382, shellW, shellH);

  // Replay instruction
  fill(255, 232, 191);
  textSize(19);
  text("PRESS BUTTON TO DIVE AGAIN",
       width / 2, 466);

  fill(173, 214, 220);
  textSize(13);
  text("SPACE to replay", width / 2, 499);

  // Restore standard drawing settings
  textAlign(LEFT, BASELINE);
  imageMode(CENTER);
  noStroke();
}
