#include <Wire.h>
#include <Adafruit_INA219.h>

// = CURRENT SENSOR ===========================================================
// Numero di campioni da acquisire.
#define SAMPLES 100
// Oggetto per l'interfacciamento con il sensore di corrente.
Adafruit_INA219 ina219;
// ----------------------------------------------------------------------------

void setup(void) 
{
	Serial.begin(115200);
	while (!Serial) {
		// will pause Zero, Leonardo, etc until serial console opens
		delay(1);
	}

	uint32_t currentFrequency;

	Serial.println("Hello!");

	// Initialize the INA219.
	// By default the initialization will use the largest range (32V, 2A).  However
	// you can call a setCalibration function to change this range (see comments).
	ina219.begin();
	// To use a slightly lower 32V, 1A range (higher precision on amps):
	//ina219.setCalibration_32V_1A();
	// Or to use a lower 16V, 400mA range (higher precision on volts and amps):
	//ina219.setCalibration_16V_400mA();

	Serial.println("Measuring voltage and current with INA219 ...");
}

void loop(void) 
{
	double I = 0;
#if 1
	for (int i = 0; i < SAMPLES; i++) {
		I += ina219.getCurrent_mA();
		delay(1);
	}
	I /= SAMPLES;
#else
	I = ina219.getCurrent_mA();
#endif

	Serial.println(I);
}
