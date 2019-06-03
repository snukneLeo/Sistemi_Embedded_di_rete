// Librerie per i moduli NRF24L01
#include <RF24.h>
#include <RF24_config.h>

// Librerie per sensore di temperatura
#include <OneWire.h>
#include <DallasTemperature.h>

// Definisco pin a cui il buzzer è collegato
#define BUZZER 3

// = NETWORK PACKET ===========================================================
// Struttura per inviare i parametri.
struct Temp_temp{
	/// Temperatura rilevata.
	float temperatura;
	/// Tempo al momento dell'invio.
	unsigned long tempo;
} sendReq;
// ----------------------------------------------------------------------------







// = RADIO ====================================================================
// Utilizzo pin 7 e 8 per il chip enable e chip select.
RF24 radio (7, 8);
// Indirizzi per la pipe.
const uint64_t addresses[2] = { 0xF0F0F0F0E1LL, 0xF0F0F0F0D2LL};
// ----------------------------------------------------------------------------

// = STDIO HELPER FUNCTION ====================================================
// Function that printf and related will use to print.
int serial_putchar(char c, FILE* f) {
   if (c == '\n') serial_putchar('\r', f);
   return Serial.write(c) == 1? 0 : 1;
}
FILE serial_stdout;
// ----------------------------------------------------------------------------

// = TEMPERATURA ==============================================================
// Inizializzazione delle variabili definisco il sensore collegato al pin 2
#define ONE_WIRE_BUS 2
// Imposta la comunicazione per un dispositivo compatibile.
OneWire oneWire(ONE_WIRE_BUS);
// Passa da OneWire a DallasTemperature.
DallasTemperature sensors(&oneWire);
// Valore per salvare la temperatura.
float temperature = 0.0;
// ----------------------------------------------------------------------------

void setup() {
	// Faccio partire il monitor seriale
	Serial.begin(115200);
	delay(1000);
	// Imposto il buzzer come output
	pinMode(BUZZER, OUTPUT);
	Serial.println("RF24 Slave started\n");

	// Faccio partire il sensore di temperature e il trasmettitore
	sensors.begin();
	radio.begin();

	// Inizializzo su quale canale invio/ricevo i dati (1-126)
	radio.setChannel(105);

	// Modifico grandezza del payload da 1 a 32 bytes
	radio.setPayloadSize(8);

	// Modifico potenza di trasmissione del segnale
	//  RF24_PA_MIN=-18dBm
	//  RF24_PA_LOW=-12dBm
	//  RF24_PA_MED=-6dBM
	//  RF24_PA_HIGH=0dBm
	radio.setPALevel(RF24_PA_HIGH);

	// Modifico velocità di trasmissione del segnale
	//  RF24_250KBPS per 250kbs
	//  RF24_1MBPS per 1Mbps
	//  RF24_2MBPS per 2Mbps
	radio.setDataRate( RF24_250KBPS );

	// Apro la pipe per la scrittura
	radio.openWritingPipe(addresses[0]);
	// Apro la read per la lettura
	radio.openReadingPipe(1, addresses[1]);

	//radio.setCRCLength(0);

	// Set up stdout
	fdev_setup_stream(&serial_stdout, serial_putchar, NULL, _FDEV_SETUP_WRITE);
	stdout = &serial_stdout;

	Serial.println("DEBUG_1");
	radio.printDetails();
}

void loop() {
	// Rilevo la temperatura.
	$FILL$

	// Restituisce la temperatura in gradi Celsius (var: temperature).
	$FILL$

	// Controllo se la temperature e' sotto il limite.
	if (temperature < 28) {

		radio.startListening();

		if (radio.available()) {
			// Ascolto e leggo
			while (radio.available()) {
				radio.read( &sendReq.tempo, sizeof(unsigned long) );
			}
			radio.stopListening();

			// Imposto la temperatura e il tempo di invio, prima di inviare i dati.
			sendReq.tempo = micros();
			sendReq.temperatura = temperature;

			// Invio della struttura dati 'sendReq', ma con controllo di
			//  avvenuto invio.
			if ($FILL$) {
				Serial.print("Sending temperature : ");
				Serial.print(sendReq.temperatura);
				Serial.println(" C");
			}
			else {
				Serial.println("Failed on sending the temperature.");
			}
		}
	} else {
		tone(BUZZER, 1000, 200);
	}
	// Ritardo.
	delay(2000);
}
