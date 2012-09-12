#include <nmea.h>
#undef abs
#undef round

NMEA gps(GPRMC);  // GPS data connection to GPRMC sentence type
float dir;          // relative direction to destination
int wpt = 0;

// destination coordinates in degrees-decimal
float dest_latitude;
float dest_longitude;

void setup() {
  Serial.begin(4800);
  driveStraight();
  delay(4);
}

void loop() {
  trackWpts();
  
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
          
          if (dir < -15)
            driveLeft();
          else if (dir > 15)
            driveRight();
          else
            driveStraight();
          }
          else //No GPS Fix...Wait for signal
            stop();
        }
      }
  }
  else
    stop();
}

void trackWpts() {
  switch(wpt) {
    case 0:
      //Go Home!
      dest_latitude = 42.796975;
      dest_longitude = -83.340809;
      break;
    default:
      dest_latitude = 0;
      dest_longitude = 0;
      break;
  }
  if (gps.gprmc_distance_to(dest_latitude,dest_longitude,MTR) < 20)
    wpt++;
}

void driveStraight() {
  Serial.print("Driving straight. - ");
  Serial.print(gps.gprmc_distance_to(dest_latitude,dest_longitude,MTR));
  Serial.print("m to go");
  Serial.print("\n");
}

void driveLeft() {
  Serial.print("Driving left. - ");
  Serial.print(gps.gprmc_distance_to(dest_latitude,dest_longitude,MTR));
  Serial.print("m to go");
  Serial.print("\n");
}

void driveRight() {
  Serial.print("Driving right. - ");
  Serial.print(gps.gprmc_distance_to(dest_latitude,dest_longitude,MTR));
  Serial.print("m to go");
  Serial.print("\n");
}

void stop() {
  Serial.print("Stopped.");
  Serial.print("\n");
}
