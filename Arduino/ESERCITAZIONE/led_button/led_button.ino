# define pinButton 2
# define pinLed 13
void setup () 
{
  pinMode(pinButton,INPUT);
  pinMode(pinLed,OUTPUT);
}
void loop () 
{
  if (digitalRead(pinButton) == 1) 
  {
    digitalWrite (pinLed,HIGH);
    delay (2000); // milliseconds
    digitalWrite ( pinLed , LOW );
  }
}
