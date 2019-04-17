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

		Scnsl::Utils::DefaultEnvironment_t::createInstance();

		// Nodes creation:

		Scnsl::Core::Node_t * n0 = sim->createNode();  
       	Scnsl::Core::Node_t * n1 = sim->createNode();
       	Scnsl::Core::Node_t * n2 = sim->createNode();
 
		// Channels setup and creation:

        CoreChannelSetup_t ccs0;

        ccs0.extensionId = "core";
        ccs0.channel_type = CoreChannelSetup_t::SHARED;
        ccs0.name = "Ch";
        ccs0.alpha = 0.1;
        ccs0.delay = sc_core::sc_time( 1.0, sc_core::SC_US );
        ccs0.nodes_number = 3;
        Scnsl::Core::Channel_if_t * Ch = sim->createChannel( ccs0 );

		// Tasks creation:

		MyTaskSensor Sensor( "Sensor" , 0 , n0 , 1 );				
		std::cout<<"Task Sensor (ID: 0) is created"<< std::endl;

		MyTaskCollector Router( "Router" , 1 , n1 , 2 );			
		std::cout<<"Task Router (ID: 1) is created"<< std::endl;
		
		MyTaskCollector Collector( "Collector" , 2 , n2 , 1 );		
		std::cout<<"Task Collector (ID: 2) is created"<< std::endl;

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

		Scnsl::Core::Communicator_if_t * mac2;
      	ccoms.name = "Mac2";
      	ccoms.node = n2;
      	mac2 = sim->createCommunicator( ccoms ); 

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
		bsb0.bindIdentifier = "Sensor_Router";
        bsb0.destinationNode = n1;
        bsb0.node_binding.x = 0;
        bsb0.node_binding.y = 0;
        bsb0.node_binding.z = 0;
        bsb0.node_binding.bitrate = Scnsl::Protocols::Mac_802_15_4::BITRATE;
        bsb0.node_binding.transmission_power = 100; //12
        bsb0.node_binding.receiving_threshold = 10;

        sim->bind( n0 , Ch , bsb0 );

        sim->bind( & Sensor , & Router , Ch , bsb0 , mac0 );

		BindSetup_base_t bsb1;
        bsb1.extensionId = "core";
		bsb1.bindIdentifier = "Router_Collector";
        bsb1.destinationNode = n2;
        bsb1.node_binding.x = 1;
        bsb1.node_binding.y = 1;
        bsb1.node_binding.z = 1;
        bsb1.node_binding.bitrate = Scnsl::Protocols::Mac_802_15_4::BITRATE;
        bsb1.node_binding.transmission_power = 10; //1000
        bsb1.node_binding.receiving_threshold = 10;

		sim->bind( n1 , Ch , bsb1 );

		sim->bind( & Router , & Collector , Ch , bsb1 , mac1 );

		bsb1.bindIdentifier = "";

        sim->bind( & Router , & Sensor , Ch , bsb1 , mac1 );		

		BindSetup_base_t bsb2;
        bsb2.extensionId = "core";
		bsb2.bindIdentifier = "";
        bsb2.destinationNode = NULL;
        bsb2.node_binding.x = 2;
        bsb2.node_binding.y = 2;
        bsb2.node_binding.z = 2;
        bsb2.node_binding.bitrate = Scnsl::Protocols::Mac_802_15_4::BITRATE;
        bsb2.node_binding.transmission_power = 1000;
        bsb2.node_binding.receiving_threshold = 10;

		sim->bind( n2 , Ch , bsb2 );

        sim->bind( & Collector , NULL , Ch , bsb2 , mac2 );

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
