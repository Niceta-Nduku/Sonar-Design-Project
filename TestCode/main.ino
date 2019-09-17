#include<ADC_Module.h>
#include<ADC.h>
#include "chirp.h"

ADC *adc = new ADC();
int ARRAY_SIZE = 10000  //Array size to be received. (HTC's thought is to have it be 2-5 times the size of the chirp)

int Pin = A14;            //The pin that will read the incoming signal
int SyncPin = 27;         //Is this even in use?
int button_pin = 24;      //Button pin
int transmit_pin = 0      // This needs to be added
// int transmit_flag = 0;    //We don't really need this anymore because it's gonna happen straight after each other.
int resolution = 12;  


void setup() {
  Serial.begin(9600);
  
  analogWriteResolution(resolution);

  adc->setConversionSpeed(ADC_CONVERSION_SPEED::HIGH_SPEED,ADC_0);
  adc->setResolution(12);
  adc->setSamplingSpeed(ADC_SAMPLING_SPEED::HIGH_SPEED,ADC_0);

 
  pinMode(Pin,INPUT);
  pinMode(button_pin,INPUT_PULLUP);

}

void loop(){
    /*
      UPDATE: 
          We are not approaching it this way anymore. We will transmit then receive immidiatly afterwards.
      TODO: 
        research on threading so that we can transmit and receive simultaneuously
        transmit would be here in this case 
        would start a new thread that would start receiving the data from the pin 
    */
  
    //==========Transmission================
    for (int i = 0; i < CHIRP_ARRAY_LENGTH; i++){
        analogWrite(chirp_pulse[i], transmit_pin);
    }

  //========== This is just telling it to receive everything. ==========

  //HTC: I'm not too sure how the whole analogReadContinuous() thang works but from context this is what I thouught would work
  for (int conversions = 0; conversions < ARRAY_SIZE; ){
    bool adc_status = adc->startContinuous(Pin,ADC_0);
    if (adc_status == 1){
    int pinVal = adc->analogReadContinuous(Pin);
    Serial.println(pinVal);
    conversions++;
    }
  }

}
