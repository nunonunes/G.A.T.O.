#include <PololuQTRSensors.h>

/* Line sensors */
#define NUM_SENSORS   8     // number of sensors used
#define SENSORS_TIMEOUT       2500  // waits for 2500 us for sensor outputs to go low
#define EMITTER_PIN   0     // emitter is controlled by digital pin 0

// sensors 0 through 7 are connected to digital pins 2 through 10, (skipping 1 and 3 which are used by the motor) respectively
PololuQTRSensorsRC qtrrc(
(unsigned char[]) {
  2, 4, 5, 6, 7, 8, 9, 10}
,
NUM_SENSORS,
SENSORS_TIMEOUT,
EMITTER_PIN); 
unsigned int sensorValues[NUM_SENSORS];

/* Motor shield */
int pwm_a = 3;  //PWM control for motor outputs 1 and 2 is on digital pin 3
int pwm_b = 11;  //PWM control for motor outputs 3 and 4 is on digital pin 11
int dir_a = 12;  //direction control for motor outputs 1 and 2 is on digital pin 12
int dir_b = 13;  //direction control for motor outputs 3 and 4 is on digital pin 13

int currentDir_a;
int currentDir_b;
int currentSpeed_a;
int currentSpeed_b;

/* Other stuff */
byte DEBUG=0;
int cruisingSpeed = 125;
int turningSpeedInside = 50;
int turningSpeedOutside = 110;


void setup()
{
  if (DEBUG) Serial.begin(9600);

  /* Line sensors */
  delay(500);
  int i;
  pinMode(13, OUTPUT);
  digitalWrite(13, HIGH);    // turn on LED to indicate we are in calibration mode
  if (DEBUG) Serial.println("Calibrating line sensor");
  for (i = 0; i < 400; i++)  // make the calibration take about 10 seconds
  {
    qtrrc.calibrate();       // reads all sensors 10 times at 2500 us per read (i.e. ~25 ms per call)
  }
  digitalWrite(13, LOW);     // turn off LED to indicate we are through with calibration

  if (DEBUG) {
    // print the calibration minimum values measured when emitters were on
    Serial.println("Minimum values read");
    for (i = 0; i < NUM_SENSORS; i++)
    {
      Serial.print(qtrrc.calibratedMinimumOn[i]);
      Serial.print(' ');
    }
    Serial.println();

    // print the calibration maximum values measured when emitters were on
    Serial.println("Maximum values read");
    for (i = 0; i < NUM_SENSORS; i++)
    {
      Serial.print(qtrrc.calibratedMaximumOn[i]);
      Serial.print(' ');
    }
    Serial.println();
    Serial.println();
  }
  delay(1000);

  /* Motor shield */
  pinMode(pwm_a, OUTPUT);  //Set control pins to be outputs
  pinMode(pwm_b, OUTPUT);
  pinMode(dir_a, OUTPUT);
  pinMode(dir_b, OUTPUT);

  if (DEBUG) Serial.println("Setting direction of motor a - forward");
  currentDir_a = LOW;
  digitalWrite(dir_a, LOW);  //Set motor direction, 1 low, 2 high
  if (DEBUG) Serial.println("Setting direction of motor b - forward");
  currentDir_b = LOW;
  digitalWrite(dir_b, LOW);  //Set motor direction, 3 high, 4 low
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
    move_straight();
  }

}

void move_straight() {
  if (DEBUG) {
    Serial.println("Moving straight ahead");
  }
  currentSpeed_a = cruisingSpeed;
  analogWrite(pwm_a, cruisingSpeed);
  currentSpeed_b = cruisingSpeed;
  analogWrite(pwm_b, cruisingSpeed);
}

void turn_left() {
  if (DEBUG) {
    Serial.println("Turning left");
  }
  currentSpeed_a = turningSpeedInside;
  analogWrite(pwm_a, turningSpeedInside);
  currentSpeed_b = turningSpeedOutside;
  analogWrite(pwm_b, turningSpeedOutside);
}

void turn_right() {
  if (DEBUG) {
    Serial.println("Turning right");
  }
  currentSpeed_a = turningSpeedOutside;
  analogWrite(pwm_a, turningSpeedOutside);
  currentSpeed_b = turningSpeedInside;
  analogWrite(pwm_b, turningSpeedInside);
}
