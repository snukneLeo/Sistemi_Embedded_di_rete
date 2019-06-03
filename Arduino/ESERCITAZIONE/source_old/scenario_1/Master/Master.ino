// Librerie per i moduli NRF24L01
#include <RF24.h>
#include <RF24_config.h>

#include <printf.h>

// Definisce il pin a cui sono attaccati i led
#define ledArancio 2
#define ledVerde 3

// Inizializzo il bottone al pin 4
int bottone = 4;

// = NETWORK PACKET ===========================================================
// Struttura per inviare i parametri.
struct Temp_temp{
	/// Temperatura rilevata.
	float temperatura;
	/// Tempo al momento dell'invio.
	unsigned long tempo;
} recReq;
// ----------------------------------------------------------------------------

// = RADIO ====================================================================
// Utilizzo pin 7 e 8 per il chip enable e chip select.
RF24 radio (7, 8);
// Indirizzi per la pipe.
const uint64_t addresses[2] = { 0xF0F0F0F0E1LL, 0xF0F0F0F0D2LL};
// ----------------------------------------------------------------------------


//varaibile per indicare che è il momento di ascoltare
bool mustlistenforanswer;

void setup() {
    // Faccio partire il monitor seriale
    Serial.begin(115200);
    delay(1000);

    // Inizializzare gli indirizzi di della pipe
    radio.begin();
    Serial.println("RF24 Master started\n");

    // Inizializzo il pin collegato ai led
    pinMode(ledArancio, OUTPUT);
    pinMode(ledVerde, OUTPUT);
    // Inizialmente i led sono spenti
    digitalWrite( ledArancio, LOW );
    digitalWrite( ledVerde, LOW );

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
    radio.openWritingPipe(addresses[1]);
    radio.openReadingPipe(1, addresses[0]);
    //radio.printDetails();
}

void loop() {

  // Interrompo l'ascolto
  radio.stopListening();
  mustlistenforanswer = true;
  // Guardo se viene premuto il bottone
  int leggiBottone = digitalRead(bottone);
  // Conteggio del millisecondi per vedere il ritardo
  unsigned long timeSent;

  // Controlla che il pacchetto sia stato inviato
  // Se non è stato inviato manda l'errore
  if ( leggiBottone == 0 )
  {
    return;
  }
  timeSent = micros();
  if (!radio.write( &timeSent, sizeof(unsigned long) ))
  {
    // Ho inviato quindi non devo ascoltare altrimenti
    // Rimane true e vuol dire he il turno di ascoltare
    mustlistenforanswer = false;
    //Serial.println("Failed on sending");
  }

  // Adesso è il turno di ascoltare la risposta
  if (mustlistenforanswer){
    // Inizio ad ascoltare la pipe di lettura
    radio.startListening();
    // Faccio partire il conteggio da quando ho fatto la richiesta
    unsigned long started_waiting_at = micros();
    boolean timeoutoccurred = false;

    // Variable che conterra il valore corrente del tempo.
    unsigned long timeNow;

    while ( !radio.available() ) {
      timeNow = micros();
      // Se passa troppo tempo fallisce la risposta e manda l'errore
      if (timeNow - started_waiting_at > 8000000 ) {
        timeoutoccurred = true;
        break;
      }
    }

    if ( timeoutoccurred ){
      Serial.print("Failed, response timed out (");
      Serial.print((timeNow - started_waiting_at)/1000);
      Serial.println(" ms)");
    }else{
      radio.read( &recReq, sizeof(recReq) );
      timeNow = micros();
      unsigned long timeReceived = recReq.tempo;
      Serial.print("Round-trip delay ");
      Serial.print((timeNow - timeReceived) / 1000);
      Serial.print(" milliseconds\t temperatura: ");
      Serial.println(recReq.temperatura);

      // Tra 20 e 24 ---> led verde acceso
      // Tra 24 e 28 ---> led arancione acceso
      if ( recReq.temperatura <= 24 && recReq.temperatura >= 20) {
        digitalWrite(ledVerde, HIGH);
        delay(1000);
        digitalWrite(ledVerde, LOW);
      } else if (recReq.temperatura <= 28 && recReq.temperatura >= 24) {
        digitalWrite(ledArancio, HIGH);
        delay(1000);
        digitalWrite(ledArancio, LOW);
      }
    }
  }
}
