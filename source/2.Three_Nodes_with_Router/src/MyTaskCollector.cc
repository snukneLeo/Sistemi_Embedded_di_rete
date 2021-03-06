#include <sstream>
#include "../inc/MyTaskCollector.hh"

// ////////////////////////////////////////////////////////////////
// Constructor and destructor.
// ////////////////////////////////////////////////////////////////

int rx_temperature = 0;
unsigned int task_id;
double tx_time = 0;
double rx_time = 0;

struct Payload_t
{
  unsigned int sender_id;			
  double sender_time;      
  int temperature;			 
};

MyTaskCollector::MyTaskCollector( const sc_core::sc_module_name modulename,
                	  const task_id_t id,
                      Scnsl::Core::Node_t * n,
                      const size_t proxies )
    throw ():
    // Parents:
    Scnsl::Tlm::TlmTask_if_t( modulename, id, n, proxies ),
	// Fields:
	_packetArrivedEvent()
{
	if (id == 1)
	{
		SC_THREAD( _sendTemperature ); 
		task_id = id; 
    }
}


MyTaskCollector::~MyTaskCollector()
    throw ()
{
    // Nothing to do.
}

// ////////////////////////////////////////////////////////////////
// Inherited interface methods.
// ////////////////////////////////////////////////////////////////

void MyTaskCollector::b_transport( tlm::tlm_generic_payload & p, sc_core::sc_time & t )
{
	Payload_t *temp = NULL; 
	bool c;

	if( p.get_command() == Scnsl::Tlm::PACKET_COMMAND )
	{
		temp = reinterpret_cast<Payload_t *>( p.get_data_ptr() );

       	tx_time = (temp->sender_time);
      	rx_time = sc_core::sc_time_stamp().to_double();
		
		std::cout << sc_core::sc_time_stamp().to_double()*1e-9 << "\tms - Task \"" << name() << "\" RECEIVE data from Task with ID = " << 
        temp->sender_id << " : Temperature = " << temp->temperature << "\u2103\t (delay = " << (rx_time-tx_time)*1e-9 + 0.01<< " ms)" << std::endl;
		
		rx_temperature = temp->temperature;

		_packetArrivedEvent.notify();
	}
	else if( p.get_command() == Scnsl::Tlm::CARRIER_COMMAND )
	{
		c = * reinterpret_cast< char * >( p.get_data_ptr() );
#if (SCNSL_LOG >= 1)
        std::stringstream ss;
        ss << "carrier: " << c << ".";
        SCNSL_TRACE_LOG( 1, ss.str().c_str() );
#endif

	}
    else
    {
        // ERROR.
        SCNSL_TRACE_ERROR( 1, "Invalid PACKET_COMMAND." );

        // Just to avoid compiler warnings:
        t = sc_core::sc_time_stamp();
    }
}

void MyTaskCollector::_sendTemperature()
    throw ()
{
    const char * tp = "Router_Collector";

  	Payload_t *p=static_cast<Payload_t *>(malloc(sizeof(Payload_t)*sizeof(p)));
 
    while ( true )
    {
		wait(_packetArrivedEvent);

		p->temperature = rx_temperature;
        p->sender_id = task_id;

        std::cout << sc_core::sc_time_stamp().to_double()*1e-9 << "\tms - Task \"" << name() << "\" SEND data : Temperature = " << p->temperature << "\u2103 \t" << std::endl;

   		p->sender_time = tx_time;

     	TlmTask_if_t::send( tp, reinterpret_cast<byte_t *>(p), sizeof(Payload_t));

        wait(10,sc_core::SC_MS);
    }
}

//SENSORE_COLLECTOR //////////////////////
void MyTaskCollector::_sendTemperature()
    throw ()
{

}
/////////////////////////
 
