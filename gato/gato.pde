#include <PololuQTRSensors.h>
#include <PID_v1.h>


// ##################################
// Assorted user-serviceable stuff

// DEBUG=0 => no debug
// DEBUG=1 => write debug info
// DEBUG=2 => write debug info, slow down main loop, do not turn on motors
#define DEBUG 2

#define LED1 8
#define LED2 9
#define LED3 10

int cruisingSpeed = 125;
int turningSpeedInside = 50;
int turningSpeedOutside = 110;


// ##################################
// Line sensor (QTR-8RC) stuff
#define NUM_SENSORS     8    // number of sensors used
#define SENSORS_TIMEOUT 2500 // waits for 2500 us for sensor outputs to go low
#define EMITTER_PIN     2    // emitter pin

// which pins are the sensor's data lines connected to
PololuQTRSensorsRC qtrrc((unsigned char[]) {
  4,5,6,7,14,15,16,17}
,NUM_SENSORS,SENSORS_TIMEOUT,EMITTER_PIN); 

unsigned int sensorValues[NUM_SENSORS];


// ##################################
// Motor shield - ArduMoto
int pwm_a = 3;  //PWM control for motor outputs 1 and 2
int pwm_b = 11;  //PWM control for motor outputs 3 and 4
int dir_a = 12;  //direction control for motor outputs 1 and 2
int dir_b = 13;  //direction control for motor outputs 3 and 4

int currentDir_a;
int currentDir_b;
int currentSpeed_a;
int currentSpeed_b;




void setup()
{
  if (DEBUG) Serial.begin(9600);

  // Initialize LED pins
  pinMode(LED1, OUTPUT);
  pinMode(LED2, OUTPUT);
  pinMode(LED3, OUTPUT);

  // Motor shield
  pinMode(pwm_a, OUTPUT);  //Set control pins to be outputs
  pinMode(pwm_b, OUTPUT);
  pinMode(dir_a, OUTPUT);
  pinMode(dir_b, OUTPUT);

  // Line sensors
  int i;
  // turn on LEDs to indicate we are in calibration mode
  digitalWrite(LED1, HIGH);
  digitalWrite(LED2, HIGH);
  digitalWrite(LED3, HIGH);
  delay(500);

  if (DEBUG) Serial.println("Calibrating line sensor");
  for (i = 0; i < 400; i++)  // make the calibration take about 10 seconds
  {
    qtrrc.calibrate();       // reads all sensors 10 times at 2500 us per read (i.e. ~25 ms per call)
  }
  
  if (DEBUG) {
    Serial.println("Line sensor calibration results");
    Serial.println();
    Serial.println("Sensor \t Min \t Max");
    for (i = 0; i < NUM_SENSORS; i++)
    {
      Serial.print(i);
      Serial.print("\t");
      Serial.print(qtrrc.calibratedMinimumOn[i]);
      Serial.print("\t");
      Serial.print(qtrrc.calibratedMaximumOn[i]);
      Serial.println();
    }
  }


  for (i = 0; i < 3; i++)  // make the calibration take about 10 seconds
  {
    digitalWrite(LED1, LOW);
    digitalWrite(LED2, LOW);
    digitalWrite(LED3, LOW);
    delay(500);
    digitalWrite(LED1, HIGH);
    digitalWrite(LED2, HIGH);
    digitalWrite(LED3, HIGH);
    delay(500);
  }

  if(DEBUG) {
    Serial.println("Initialization concluded");  
  }
  // turn off LEDs to indicate we are done with calibration mode
  digitalWrite(LED1, LOW);
  digitalWrite(LED2, LOW);
  digitalWrite(LED3, LOW);
}


void loop()
{
  // read calibrated sensor values and obtain a measure of the line position
  // from 0 to 7000, where 0 means directly under sensor 0 or the line was lost
  // past sensor 0, 1000 means directly under sensor 1, 2000 means directly under sensor 2, etc.
  // Note: the values returned will be incorrect if the sensors have not been properly
  // calibrated during the calibration phase.  To get raw sensor values, call:
  //  qtra.read(sensorValues);
  // 0 => the line is to the right of the robot
  // 3500 => the line is smack in the middle of the robot
  // 7000 => the line is to the left of the robot

  unsigned int position = qtrrc.readLine(sensorValues);

  if (DEBUG) {
    // print the sensor values as numbers from 0 to 9, where 0 means maximum reflectance and
    // 9 means minimum reflectance, followed by the line position
    unsigned char i;
    for (i = 0; i < NUM_SENSORS; i++)
    {
      Serial.print(sensorValues[i] * 10 / 1001);
      Serial.print(' ');
    }
    Serial.print("    ");
    Serial.println(position);
  }


  if (position <= 3000) {
    // Turn right
    turn_right();
  }
  else if (position >= 4000) {
    // Turn left
    turn_left();
  }
  else {
    // Steady as she goes
    move_forward();
  }

  if(DEBUG>1) delay(1000);
}

void move_forward() {
  if (DEBUG) {
    Serial.println("Moving forward");
    digitalWrite(LED1, LOW);
    digitalWrite(LED2, HIGH);
    digitalWrite(LED3, LOW);
    
    if (DEBUG>1) return;
  }
  currentSpeed_a = cruisingSpeed;
  analogWrite(pwm_a, cruisingSpeed);
  currentSpeed_b = cruisingSpeed;
  analogWrite(pwm_b, cruisingSpeed);
}

void turn_left() {
  if (DEBUG) {
    Serial.println("Turning left");
    digitalWrite(LED1, HIGH);
    digitalWrite(LED2, LOW);
    digitalWrite(LED3, LOW);

    if (DEBUG>1) return;
  }
  currentSpeed_a = turningSpeedInside;
  analogWrite(pwm_a, turningSpeedInside);
  currentSpeed_b = turningSpeedOutside;
  analogWrite(pwm_b, turningSpeedOutside);
}

void turn_right() {
  if (DEBUG) {
    Serial.println("Turning right");
    digitalWrite(LED1, LOW);
    digitalWrite(LED2, LOW);
    digitalWrite(LED3, HIGH);
    if (DEBUG>1) return;
  }
  currentSpeed_a = turningSpeedOutside;
  analogWrite(pwm_a, turningSpeedOutside);
  currentSpeed_b = turningSpeedInside;
  analogWrite(pwm_b, turningSpeedInside);
}




