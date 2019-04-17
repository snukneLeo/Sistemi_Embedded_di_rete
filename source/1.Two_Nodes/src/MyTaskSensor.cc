#include <sstream>
#include "../inc/MyTaskSensor.hh"

// ////////////////////////////////////////////////////////////////
// Constructor and destructor.
// ////////////////////////////////////////////////////////////////

struct Payload_t
{
	unsigned int sender_id;			
	double sender_time;        
   	int temperature;			 
};

MyTaskSensor::MyTaskSensor( const sc_core::sc_module_name modulename,
                    const task_id_t id,
                    Scnsl::Core::Node_t * n,
                    const size_t proxies )
    throw ():
    // Parents:
    Scnsl::Tlm::TlmTask_if_t( modulename, id, n, proxies ),
    // Fields:
	task_id()
{  
	task_id = id;

    SC_THREAD( _sendTemperature );
}

MyTaskSensor::~MyTaskSensor()
    throw ()
{
    // Nothing to do.
}

// ////////////////////////////////////////////////////////////////
// Inherited interface methods.
// ////////////////////////////////////////////////////////////////


void MyTaskSensor::b_transport( tlm::tlm_generic_payload & p, sc_core::sc_time & t )
{
	bool c;
	
	if( p.get_command() == Scnsl::Tlm::CARRIER_COMMAND )
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


// ////////////////////////////////////////////////////////////////
// Processes.
// ////////////////////////////////////////////////////////////////


void MyTaskSensor::_sendTemperature()
    throw ()
{
    const char * tp = "Sensor_Collector";

  	Payload_t *p=static_cast<Payload_t *>(malloc(sizeof(Payload_t)*sizeof(p)));
 
    while ( true )
    {
        p->temperature = (rand()%25 + 25 );
        p->sender_id = task_id;

        std::cout << sc_core::sc_time_stamp().to_double()*1e-9 << "\tms - Task \"" << name() << "\" SEND data : Temperature = " << p->temperature << "\u2103 \t" << std::endl;

   		p->sender_time = sc_core::sc_time_stamp().to_double();

     	TlmTask_if_t::send( tp, reinterpret_cast<byte_t *>(p), sizeof(Payload_t));

        wait(1000,sc_core::SC_MS);
    }
 
}

  
