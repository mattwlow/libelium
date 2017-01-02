// This code is designed to read various values from sensors attached to a Libelium Waspmote sensor board and POST to a HTTP API through the Libelium's inbuilt 3G modem.
// The sensors are read and sent to API endpoint periodically. The Waspmote is in Deep Sleep between these reads.
// Written for Waspmote v12. Tested on Waspmote Plug & Sense.

// Load relevant libraries

#include "Wasp3G.h"
#include <WaspSensorCities.h>

// Initiate Variables

int8_t answer;
char body[200];
char request[512];
int counter;
int tempint; // internal temperature
int d1;      
float f2;
int d2;
int batt; // battery level (%)
int temp; // external tempoerature sensor
int humidity; 
int lux;
int ultrasound; 
int noise;
char sensorid[10];
unsigned long timestamp; ; // epoch time in utc

// Define API Endpoint

#define IP_ADDRESS    "things.xxxxx.com"
#define REMOTE_PORT   80
#define HTTP_METHOD   "POST"
#define URL           "/api/xxxxxxxxxxx" // Should include key if relevant.
// Run at power on.

void setup()
{    
  // Define Sensor ID
     
  sprintf(sensorid,"LIBE0001");
  
  // Set the 3G network settings
    _3G.set_APN("connect", "", ""); // (APN name, login, password) for 3G network (login and pass unlikely to be required). For Telstra, APN = internet.telstra; Optus, APN = connect;
    // And show them
    _3G.show_APN();
    USB.println(F("---******************************************************************************---"));
}

void loop()
{

    // Grabbing the battery, time and internal temperature levels:
    
    batt = PWR.getBatteryLevel();
    RTC.ON();
    tempint = RTC.getTemperature();
    timestamp = RTC.getEpochTime();
    RTC.OFF();
    
    // Unleash the sensors!

            SensorCities.ON();

            // Turn on the sensors attached to board and wait for stabilization and response time
            SensorCities.setSensorMode(SENS_ON, SENS_CITIES_TEMPERATURE);
            SensorCities.setSensorMode(SENS_ON, SENS_CITIES_AUDIO);
            SensorCities.setSensorMode(SENS_ON, SENS_CITIES_HUMIDITY);
            SensorCities.setSensorMode(SENS_ON, SENS_CITIES_LDR);
            
            delay(15000); //important for stabalisation, 15 seconds
            
            // Read the sensors 
            temp = SensorCities.readValue(SENS_CITIES_TEMPERATURE);
            noise = SensorCities.readValue(SENS_CITIES_AUDIO);
            humidity = SensorCities.readValue(SENS_CITIES_HUMIDITY);
            lux = SensorCities.readValue(SENS_CITIES_LDR);
            
            // Turn off the sensors
            SensorCities.setSensorMode(SENS_OFF, SENS_CITIES_TEMPERATURE);
            SensorCities.setSensorMode(SENS_OFF, SENS_CITIES_AUDIO);
            SensorCities.setSensorMode(SENS_OFF, SENS_CITIES_HUMIDITY);
            SensorCities.setSensorMode(SENS_OFF, SENS_CITIES_LDR);

    // Activating the 3G module:
    
    answer = _3G.ON();
    if ((answer == 1) || (answer == -3))
    {
      
      USB.println(F("3G module ready..."));

        // Waits for connection to the network
        answer = _3G.check(180);    
        if (answer == 1)
        { 
            USB.println(F("3G module connected to the network..."));
            USB.println(F("Getting URL with POST method..."));
           
           // Print some values... just to check on USB console.
 
            USB.println(F("---******************************************************************************---"));
            USB.print(F("Internal Sensor Temperature..."));
            USB.print(tempint);        
            USB.println(F(" ºC"));
            USB.print(F("External Temperature..."));
            USB.print(temp);
            USB.println(F("º C"));
            USB.println(F("Humidity..."));
            USB.println(humidity);
            USB.println(F("Light..."));
            USB.println(lux);
            USB.println(F("Noise..."));
            USB.println(noise);
            USB.println(F("Battery..."));
            USB.print(batt);
            USB.println(F("%"));
            USB.println(F("Epoch Time..."));
            USB.println(timestamp);
           
           
           // Setting up API POST content
            
           sprintf(body,"{\"ultrasound\":\"%d\",\"tempint\":\"%d\", \"humidity\":\"%d\",\"lux\":\"%d\",\"batt\":\"%d\",\"temp\":\"%d\",\"noise\":\"%d\",\"timestamp\":\"%lu\" } ", ultrasound, tempint, humidity, lux, batt, temp, noise, timestamp);
            
           
           sprintf(request,"%s %s HTTP/1.1\n"\ 
                          "Host: %s:%d\n"\                      
                         "Content-Type: application/json\n"\
                         "Accept: application/json\n"\
                         "charset: UTF-8\n"\
                          "Content-Length: %d\n"\
                          "\n"\
                          "%s",HTTP_METHOD,URL,IP_ADDRESS,REMOTE_PORT,strlen(body),body);
                   
            USB.println(F("---******************************************************************************---"));  
            USB.print(F("Attempting Request..."));
            
            // 6. gets URL from the solicited URL
            USB.println(request);
            answer = _3G.readURL(IP_ADDRESS, 80, request);
            
            // Checks the answer
            USB.print(F("Validating what comes back...")); 
            USB.print(answer); 
            if ( answer == 1)
            {
                USB.println(F("Success"));  
                USB.println(_3G.buffer_3G);
            }
            else if (answer < -14)
            {
                USB.print(F("Failed. Error code: "));
                USB.println(answer, DEC);
                USB.print(F("CME error code: "));
                USB.println(_3G.CME_CMS_code, DEC);
            }
            else 
            {
                USB.print(F("Failed. Error code: "));
                USB.println(answer, DEC);
            } 
        }
        else
        {
            USB.println(F("3G module cannot connect to the network..."));
        }  
    }
    else
    {
        // Problem with the communication with the 3G module
        USB.println(F("3G module not started"));
    }

    // 7. Powers off the 3G module
    _3G.OFF();

    USB.println(F("Sleeping..."));
    counter++;

    // 8. sleeps five min
    PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);

}
