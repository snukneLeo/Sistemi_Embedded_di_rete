#include <systemc>
#include <tlm.h>
#include <exception>

#include <scnsl.hh>
#include "../inc/MyTaskSensor.hh"
#include "../inc/MyTaskCollector.hh" 

using namespace Scnsl::Setup;
using namespace Scnsl::BuiltinPlugin;

int sc_main( int /*argc*/, char * /*argv*/[] )
{
	try
	{ 
		// SCNSL Simulator creation:

        Scnsl::Setup::Scnsl_t * sim = Scnsl::Setup::Scnsl_t::get_instance();

		// Environment creation:

		Scnsl::Utils::DefaultEnvironment_t::createInstance(0.1);

		// Nodes creation:

		Scnsl::Core::Node_t * n0 = sim->createNode();  
       	Scnsl::Core::Node_t * n1 = sim->createNode();
 
		// Channels setup and creation:

        CoreChannelSetup_t ccs0;

        ccs0.extensionId = "core";
        ccs0.channel_type = CoreChannelSetup_t::SHARED;
        ccs0.name = "Ch";
        ccs0.alpha = 0.1;
        ccs0.delay = sc_core::sc_time( 1.0, sc_core::SC_US );
        ccs0.nodes_number = 2;
        Scnsl::Core::Channel_if_t * Ch = sim->createChannel( ccs0 );

		// Tasks creation:

		MyTaskSensor Sensor( "Sensor" , 0 , n0 , 1 );				std::cout<<"Task Sensor (ID: 0) is created"<< std::endl;
		MyTaskCollector Collector( "Collector" , 1 , n1 , 1 );		std::cout<<"Task Collector (ID: 1) is created"<< std::endl;

		// Communicator creation (Protocol 802.15.4):

        CoreCommunicatorSetup_t ccoms;
        ccoms.extensionId = "core";
        ccoms.ack_required = true;
        ccoms.short_addresses = true;
        ccoms.type = CoreCommunicatorSetup_t::MAC_802_15_4;
           
		Scnsl::Core::Communicator_if_t * mac0;
         
    	ccoms.name = "Mac0";
        ccoms.node = n0;
        mac0 = sim->createCommunicator( ccoms ); 
          
      	Scnsl::Core::Communicator_if_t * mac1;
      	ccoms.name = "Mac1";
      	ccoms.node = n1;
      	mac1 = sim->createCommunicator( ccoms ); 

		// Tracing features setup:

		CoreTracingSetup_t cts;
		cts.extensionId = "core";
		cts.formatterExtensionId = "core";
		cts.filterExtensionId = "core";
		cts.formatterName = "basic";
		cts.filterName = "basic";
		cts.info = 0;
		cts.debug = 0;
		cts.log = 0;
		cts.error = 0;
		cts.warning = 0;
		cts.fatal = 0;
		cts.print_trace_type = true;
		Scnsl_t::Tracer_t * tracer = sim->createTracer( cts );
 
		// tracer->trace( & c);
		// tracer->trace( & s0);
		// tracer->trace( & s1);
		// tracer->trace( & ch0);
		// tracer->trace( & ch1);

        tracer->addOutput( & std::cout );
 
		// Node's properties setup and bindings:

  		BindSetup_base_t bsb0;
        bsb0.extensionId = "core";
		bsb0.bindIdentifier = "Sensor_Collector";
        bsb0.destinationNode = n1;
        bsb0.node_binding.x = 0;
        bsb0.node_binding.y = 0;
        bsb0.node_binding.z = 0;
        bsb0.node_binding.bitrate = Scnsl::Protocols::Mac_802_15_4::BITRATE;
        bsb0.node_binding.transmission_power = 12;
        bsb0.node_binding.receiving_threshold = 10;

        sim->bind( n0 , Ch , bsb0 );

        sim->bind( & Sensor , & Collector , Ch , bsb0 , mac0 );

		BindSetup_base_t bsb1;
        bsb1.extensionId = "core";
		bsb1.bindIdentifier = "";
        bsb1.destinationNode = NULL;
        bsb1.node_binding.x = 10;
        bsb1.node_binding.y = 1;
        bsb1.node_binding.z = 1;
        bsb1.node_binding.bitrate = Scnsl::Protocols::Mac_802_15_4::BITRATE;
        bsb1.node_binding.transmission_power = 60;
        bsb1.node_binding.receiving_threshold = 10;

		sim->bind( n1 , Ch , bsb1 );

        sim->bind( & Collector , NULL , Ch , bsb1 , mac1 );

        sc_core::sc_start( sc_core::sc_time( 5000, sc_core::SC_MS ) );
        sc_core::sc_stop();
    }
    catch ( std::exception & e)
    {
        std::cerr << "Exception in sc_main(): " << e.what() << std::endl;
        return 1;
    }
	return 0;
}
