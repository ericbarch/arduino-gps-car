#include <nmea.h>
#include <Servo.h>
#undef abs
#undef round

NMEA gps(GPRMC);  // GPS data connection to GPRMC sentence type
Servo steering;
float dir;          // relative direction to destination
int wpt = 0;
int servo_pos = 95;
char last_status = 'V';

// destination coordinates in degrees-decimal
float dest_latitude;
float dest_longitude;

void setup() {
  Serial.begin(4800);
  pinMode(4, OUTPUT);
  pinMode(5, OUTPUT);
  steering.attach(9);
}

void loop() {
  trackWpts();
  trackGPS();
}

void trackWpts() {
  switch(wpt) {
    case 0:
      dest_latitude = 42.916457;
      dest_longitude = -82.504556;
      break;
    case 1:
      dest_latitude = 42.916398;
      dest_longitude = -82.503408;
      break;
    case 2:
      dest_latitude = 42.913472;
      dest_longitude = -82.503349;
      break;
    case 3:
      dest_latitude = 42.913495;
      dest_longitude = -82.504513;
      break;
    case 4:
      dest_latitude = 42.915538;
      dest_longitude = -82.504523;
      break;
    default:
      dest_latitude = 0;
      dest_longitude = 0;
      break;
  }
  if (gps.gprmc_distance_to(dest_latitude,dest_longitude,MTR) < 12)
    wpt++;
}

void trackGPS() {
  if (dest_latitude != 0 && dest_longitude != 0)
  {
    if (Serial.available() > 0 ) {
      char c = Serial.read();

      if (gps.decode(c)) {
        
        //We just got signal, we need to drive straight to get our current heading
        /*if (gps.gprmc_status() == 'A' && last_status == 'V')
          signalBack();*/
          
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
            
        last_status = gps.gprmc_status();
        }
      }
  }
  else
    stop();
}

void driveStraight() {
  steering.write(95);
  digitalWrite(4, LOW);
  digitalWrite(5, HIGH);
  Serial.println("Driving straight...");
}

void driveToTarget() {
  servo_pos = map(dir, -75, 75, 84, 108);
  steering.write(servo_pos);
  digitalWrite(4, LOW);
  digitalWrite(5, HIGH);
  Serial.print("Driving at ");
  Serial.print(dir);
  Serial.print(". - ");
  Serial.print(gps.gprmc_distance_to(dest_latitude,dest_longitude,MTR));
  Serial.print("m to go");
  Serial.print("\n");
}

void hardLeft() {
  steering.write(85);
  digitalWrite(4, LOW);
  digitalWrite(5, HIGH);
  Serial.print("Driving hard left. - ");
  Serial.print(gps.gprmc_distance_to(dest_latitude,dest_longitude,MTR));
  Serial.print("m to go");
  Serial.print("\n");
}

void hardRight() {
  steering.write(108);
  digitalWrite(4, LOW);
  digitalWrite(5, HIGH);
  Serial.print("Driving hard right. - ");
  Serial.print(gps.gprmc_distance_to(dest_latitude,dest_longitude,MTR));
  Serial.print("m to go");
  Serial.print("\n");
}

void stop() {
  steering.write(95);
  digitalWrite(4, HIGH);
  digitalWrite(5, HIGH);
  Serial.print("Stopped.");
  Serial.print("\n");
}

void signalBack() {
  driveStraight();
  delay(3000);
}
