#include<ADC_Module.h>
//#include<Audio.h>
//#include<SPI.h>
#include<ADC.h>

#define SAMPLE_RATE 80000                   // see below maximum values
#define SAMPLE_AVERAGING 0                  // 0, 4, 8, 16 or 32
#define SAMPLING_GAIN 1                     // 1, 2, 4, 8, 16, 32 or 64
#define SAMPLE_RESOLUTION 12                // 8, 10, 12 or 16 

const int readPin0             = A14;
ADC *adc = new ADC();

uint32_t                    freq     = SAMPLE_RATE;
uint8_t                     aver     = SAMPLE_AVERAGING;
uint8_t                      res     = SAMPLE_RESOLUTION;
uint8_t                    sgain     = SAMPLING_GAIN;
float                       Vmax     = 3.3;
ADC_REFERENCE               Vref     = ADC_REFERENCE::REF_3V3;
ADC_SAMPLING_SPEED    samp_speed     = ADC_SAMPLING_SPEED::VERY_HIGH_SPEED;
ADC_CONVERSION_SPEED  conv_speed     = ADC_CONVERSION_SPEED::VERY_HIGH_SPEED;


void setup() {
  Serial.begin(9600);
  
  adc->setReference(Vref, ADC_0);
  adc->setAveraging(aver); 
  adc->setResolution(res); 
  if (((Vref == ADC_REFERENCE::REF_3V3) && (Vmax > 3.29)) || ((Vref == ADC_REFERENCE::REF_1V2) && (Vmax > 1.19))) { 
    adc->disableCompare(ADC_0);
  } else if (Vref == ADC_REFERENCE::REF_3V3) {
    adc->enableCompare(Vmax/3.3*adc->getMaxValue(ADC_0), 0, ADC_0);
  } else if (Vref == ADC_REFERENCE::REF_1V2) {
    adc->enableCompare(Vmax/1.2*adc->getMaxValue(ADC_0), 0, ADC_0);    
  }
  //adc->enableCompareRange(1.0*adc->getMaxValue(ADC_1)/3.3, 2.0*adc->getMaxValue(ADC_1)/3.3, 1, 1, ADC_1); // ready if value lies out of [1.0,2.0] V
  adc->setConversionSpeed(conv_speed, ADC_0);
  adc->setSamplingSpeed(samp_speed, ADC_0);

}

void loop(){
  
  Serial.println("Starting sampling");
  while (1){
    
    //Serial.println("Starting");
    bool adc_status = adc->startContinuous(readPin0,ADC_0);
    
    if (adc_status == 1){
      int pinVal = adc->analogReadContinuous(readPin0);
      Serial.println(pinVal);
    }
    else{
      continue;
    }
  }
}
