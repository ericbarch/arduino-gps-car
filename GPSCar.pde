/* GPS Car v0.1 by Eric Barch (ttjcrew.com) */

#include <nmea.h>
#include <Servo.h>
#undef abs
#undef round
int wpt = 0;
float dest_latitude;
float dest_longitude;
NMEA gps(GPRMC);  // GPS data connection to GPRMC sentence type



/* BEGIN EDITABLE CONSTANTS SECTION */

//These define the positions for your steering servo
#define CENTER_SERVO 95
#define MAX_LEFT_SERVO 85
#define MAX_RIGHT_SERVO 108

//When the car is within this range (meters), move to the next waypoint
#define WPT_IN_RANGE_M 12

//These pins are your h-bridge output. If the car is running in reverse, swap these
#define MOTOR_OUTPUT_ONE 3
#define MOTOR_OUTPUT_TWO 4

/* DEFINE GPS WPTS HERE - Create more cases as needed */
void trackWpts() {
  switch(wpt) {
    case 0:
      dest_latitude = 40.756054;
      dest_longitude = -73.986951;
      break;
    case 1:
      dest_latitude = 37.775206;
      dest_longitude = -122.419209;
      break;
    default:
      dest_latitude = 0;
      dest_longitude = 0;
      break;
  }
  if (gps.gprmc_distance_to(dest_latitude,dest_longitude,MTR) < WPT_IN_RANGE_M)
    wpt++;
}



/* END EDITABLE CONSTANTS SECTION */




Servo steering;
float dir;          // relative direction to destination
int servo_pos = CENTER_SERVO;

void setup() {
  Serial.begin(4800);
  pinMode(MOTOR_OUTPUT_ONE, OUTPUT);
  pinMode(MOTOR_OUTPUT_TWO, OUTPUT);
  steering.attach(9);
}

void loop() {
  trackWpts();
  trackGPS();
}

void trackGPS() {
  if (dest_latitude != 0 && dest_longitude != 0)
  {
    if (Serial.available() > 0 ) {
      char c = Serial.read();

      if (gps.decode(c)) {
          
        // check if GPS positioning was active
        if (gps.gprmc_status() == 'A') {
          // calculate relative direction to destination
          dir = gps.gprmc_course_to(dest_latitude, dest_longitude) - gps.gprmc_course();
          
          if (dir < 0)
            dir += 360;
          if (dir > 180)
            dir -= 360;
            
          if (dir < -75)
            hardLeft();
          else if (dir > 75)
            hardRight();
          else
            driveToTarget();
          
        }
        else //No GPS Fix...Wait for signal
          stop();
            
        }
      }
  }
  else
    stop();
}

void driveStraight() {
  steering.write(CENTER_SERVO);
  digitalWrite(MOTOR_OUTPUT_ONE, LOW);
  digitalWrite(MOTOR_OUTPUT_TWO, HIGH);
  Serial.println("Driving straight...");
}

void driveToTarget() {
  servo_pos = map(dir, -75, 75, MAX_LEFT_SERVO, MAX_RIGHT_SERVO);
  steering.write(servo_pos);
  digitalWrite(MOTOR_OUTPUT_ONE, LOW);
  digitalWrite(MOTOR_OUTPUT_TWO, HIGH);
  Serial.print("Driving at ");
  Serial.print(dir);
  Serial.print(". - ");
  Serial.print(gps.gprmc_distance_to(dest_latitude,dest_longitude,MTR));
  Serial.print("m to go");
  Serial.print("\n");
}

void hardLeft() {
  steering.write(MAX_LEFT_SERVO);
  digitalWrite(MOTOR_OUTPUT_ONE, LOW);
  digitalWrite(MOTOR_OUTPUT_TWO, HIGH);
  Serial.print("Driving hard left. - ");
  Serial.print(gps.gprmc_distance_to(dest_latitude,dest_longitude,MTR));
  Serial.print("m to go");
  Serial.print("\n");
}

void hardRight() {
  steering.write(MAX_RIGHT_SERVO);
  digitalWrite(MOTOR_OUTPUT_ONE, LOW);
  digitalWrite(MOTOR_OUTPUT_TWO, HIGH);
  Serial.print("Driving hard right. - ");
  Serial.print(gps.gprmc_distance_to(dest_latitude,dest_longitude,MTR));
  Serial.print("m to go");
  Serial.print("\n");
}

void stop() {
  steering.write(CENTER_SERVO);
  digitalWrite(MOTOR_OUTPUT_ONE, HIGH);
  digitalWrite(MOTOR_OUTPUT_TWO, HIGH);
  Serial.print("Stopped.");
  Serial.print("\n");
}
