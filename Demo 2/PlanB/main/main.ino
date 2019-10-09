#include "main.h"

unsigned long lastInAvail;       //
unsigned long lastDisplay;       //
unsigned long lastBlink;         //
unsigned long currentTime;       //
unsigned long func_timer; // <<<<<<<<<<< Time execution of different functions
bool          STREAM  = false;
bool          VERBOSE = true;
bool          BINARY = true;
int           TRANSMIT = 0;

//ADC & DMA Config
ADC *adc = new ADC(); //adc object
DMAChannel dma0;
// Variables for ADC0
DMAMEM static uint16_t buf_a[BUFFER_SIZE]; // buffer a
DMAMEM static uint16_t buf_b[BUFFER_SIZE]; // buffer b
volatile uint8_t          aorb_busy  = 0;      //
volatile uint8_t          a_full     = 0;      //
volatile uint8_t          b_full     = 0;      //
uint32_t                    freq     = SAMPLE_RATE;
uint8_t                     aver     = SAMPLE_AVERAGING;
uint8_t                      res     = SAMPLE_RESOLUTION;
uint8_t                    sgain     = SAMPLING_GAIN;
float                       Vmax     = 3.3;
ADC_REFERENCE               Vref     = ADC_REFERENCE::REF_3V3;
ADC_SAMPLING_SPEED    samp_speed     = ADC_SAMPLING_SPEED::VERY_HIGH_SPEED;
ADC_CONVERSION_SPEED  conv_speed     = ADC_CONVERSION_SPEED::VERY_HIGH_SPEED;

//==========Button Declaration ========


// Processing Buffer
uint16_t processed_buf[BUFFER_SIZE]; // processed data buffer

void setup() { // =====================================================
  analogWriteResolution(12);
  pinMode(LED_BUILTIN, OUTPUT);
  
  pinMode(readPin0, INPUT); // single ended
  pinMode(readPin1, INPUT); // single ended
  
  pinMode(transmit_LED, OUTPUT);
  pinMode(start_receive, INPUT_PULLDOWN);

  TRANSMIT = digitalRead(start_receive);
  // Setup monitor pin
  pinMode(ledPin, OUTPUT);
  digitalWriteFast(ledPin, LOW); // LED low, setup start

  while (!Serial && millis() < 3000) ;
  Serial.begin(Serial.baud());
  Serial.println("ADC Server (Minimal)");
  Serial.println("c to start conversion, p to print buffer");
  
  // clear buffers
  memset((void*)buf_a, 0, sizeof(buf_a));
  memset((void*)buf_b, 0, sizeof(buf_b));
  memset((void*)processed_buf, 0, sizeof(buf_b));
  
  // LED on, setup complete
  digitalWriteFast(ledPin, HIGH);
  

} // setup =========================================================

int          inByte   = 0;
String inNumberString = "";
long         inNumber = -1;
boolean   chunk1_sent = false;
boolean   chunk2_sent = false;
boolean   chunk3_sent = false;


void loop() { // ===================================================
  
  // Keep track of loop time
  currentTime = micros();
  // Commands:
  // c initiate single conversion
  // p print buffer
  
  if ((currentTime-lastInAvail) >= CHECKINPUT_INTERVAL) {
    lastInAvail = currentTime;
    if (Serial.available()) {
      inByte=Serial.read();

      if (inByte == 'c') { // single block conversion

          if ((aorb_busy == 1) || (aorb_busy == 2)) { stop_ADC(); }
          setup_ADC_single();
          for (int i = 0; i < 19532;i++){
            analogWrite(A21,chirp_pulse[i]);
          }        
          start_ADC(readPin0);
          wait_ADC_single();
          stop_ADC();
          adc->printError();
          adc->resetError();
      
          
      } 
      if (inByte == 'd') { // single block conversion

          if ((aorb_busy == 1) || (aorb_busy == 2)) { stop_ADC(); }
          setup_ADC_single();
          for (int i = 0; i < 19532;i++){
            analogWrite(A21,chirp_pulse[i]);
          }        
          start_ADC(readPin1);
          wait_ADC_single();
          stop_ADC();
          adc->printError();
          adc->resetError();          
      } 
      
      else if (inByte == 'p') { // print buffer
          printBuffer(buf_a, 0, BUFFER_SIZE-1);
      }
    } // end if serial input available
  } // end check serial in time interval
    
  if ((currentTime-lastDisplay) >= DISPLAY_INTERVAL) {
    lastDisplay = currentTime;
    adc->printError();
    adc->resetError();
  } 
    
  

} // end loop ======================================================


// ADC
void setup_ADC_single(void) {
  // clear buffers
  memset((void*)buf_a, 0, sizeof(buf_a));
  // Initialize the ADC
  if (sgain >1) { adc->enablePGA(sgain, ADC_0); }  else { adc->disablePGA(ADC_0); }         
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

  // Initialize dma
  dma0.source((volatile uint16_t&)ADC0_RA);
  dma0.destinationBuffer(buf_a, sizeof(buf_a));
  dma0.triggerAtHardwareEvent(DMAMUX_SOURCE_ADC0);
  dma0.interruptAtCompletion();
  //dma0.disableOnCompletion();
  dma0.attachInterrupt(&dma0_isr_single);
}

void start_ADC(int pin) {
    // Start adc
    aorb_busy  = 1;
    a_full    = 0;
    b_full    = 0;
    adc->adc0->startSingleRead(pin);
    // frequency, hardware trigger and dma
    adc->adc0->startPDB(freq); // set ADC_SC2_ADTRG
    adc->enableDMA(ADC_0); // set ADC_SC2_DMAEN
    dma0.enable();
}

void stop_ADC(void) {
    PDB0_CH0C1 = 0; // diasble ADC0 pre triggers    
    dma0.disable();
    adc->disableDMA(ADC_0);
    adc->adc0->stopPDB();
    aorb_busy = 0;
}

void wait_ADC_single(void) {
  
  uint32_t   end_time = micros();
  uint32_t start_time = micros();
  while (!a_full) {
    end_time = micros();
    if ((end_time - start_time) > 1100000) {
      Serial.printf("Timeout %d %d\n", a_full, aorb_busy);
      break;
    }
  }
  Serial.printf("Conversion complete in %d us\n", end_time-start_time);
}

void dma0_isr_single(void) {
  aorb_busy = 0;
     a_full = 1;
  dma0.clearInterrupt(); // takes more than 0.5 micro seconds
  dma0.clearComplete(); // takes about ? micro seconds
}


void printBuffer(uint16_t *buffer, size_t start, size_t end) {
  size_t i;
  if (VERBOSE) {
    for (i = start; i <= end; i++) { Serial.println(buffer[i]); }
  } else {
    for (i = start; i <= end; i++) {
      serial16Print(buffer[i]);
      Serial.println(); }
  }
}

// CONVERT 16BITS TO HEX AND SEND OVER SERIAL PORT
void serial16Print(uint16_t u) {
  byte * b = (byte *) &u;
  for(int i=1; i>=0; i--) {
    
    byte b1 = (b[i] >> 4) & 0x0f;
    byte b2 = (b[i] & 0x0f);
    
    char c1 = (b1 < 10) ? ('0' + b1) : 'A' + b1 - 10;
    char c2 = (b2 < 10) ? ('0' + b2) : 'A' + b2 - 10;
    
    Serial.print(c1);
    Serial.print(c2);
  }
}


typedef struct  __attribute__((packed, aligned(4))) {
  uint32_t SADDR;
  int16_t SOFF;
  uint16_t ATTR;
  uint32_t NBYTES;
  int32_t SLAST;
  uint32_t DADDR;
  int16_t DOFF;
  uint16_t CITER;
  int32_t DLASTSGA;
  uint16_t CSR;
  uint16_t BITER;
} TCD_DEBUG;
