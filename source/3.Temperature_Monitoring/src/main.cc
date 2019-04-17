#include <systemc>
#include <tlm.h>
#include <exception>

#include <scnsl.hh>
#include "../inc/MyTaskSensor.hh"
#include "../inc/MyTaskController.hh" 

using namespace Scnsl::Setup;
using namespace Scnsl::BuiltinPlugin;

int sc_main( int argc, char * argv[] )
{
	try
	{ 
		unsigned int ROOMS=0;
        if ( argc == 2 )
        {
            std::stringstream ss;
            ss << argv[ 1 ];
            ss >> ROOMS;

			if (ROOMS < 2)
			{
				std::cout << "usage:" << std::endl << "\t<NUMBER_OF_ROOMS> must be greater than 1" << std::endl << std::endl;
				return 1;
			}				
        }
		else
		{
			std::cout << "usage:" << std::endl << "\tTemperature_Monitoring <NUMBER_OF_ROOMS>" << std::endl << std::endl;
			return 1;
		}

		// SCNSL Simulator creation:

        Scnsl::Setup::Scnsl_t * sim = Scnsl::Setup::Scnsl_t::get_instance();

		// Environment creation:

		Scnsl::Utils::DefaultEnvironment_t::createInstance();

		// Nodes creation:

		Scnsl::Core::Node_t * n[ROOMS];   
        
		for(unsigned int i=0; i<ROOMS; i++)
        {
        	n[i] = sim->createNode();  									std::cout << "Create NODE n" << i << std::endl;
        }
 
		// Channels setup and creation:

        CoreChannelSetup_t ccs[ROOMS-1];
		Scnsl::Core::Channel_if_t * ch[ROOMS-1];

		for(unsigned int i=0; i<ROOMS-1; i++)
        {
			ccs[i].extensionId = "core";
		    ccs[i].channel_type = CoreChannelSetup_t::SHARED;

			std::string name = "ch";			
			std::stringstream ss;
			ss << i;
			name.append(ss.str());
			
		    ccs[i].name = name;
		    ccs[i].alpha = 0.1;
		    ccs[i].delay = sc_core::sc_time( 1.0, sc_core::SC_US );
		    ccs[i].nodes_number = 2;

		    ch[i] = sim->createChannel( ccs[i] );						std::cout << "Create CHANNEL ch" << i << std::endl;
		}

		// Tasks creation:

		MyTaskController c( "Collector", 0, n[0], ROOMS-1 );			std::cout<<"Create TASK Collector (ID: 0)"<< std::endl;
		MyTaskSensor * s[ROOMS];

		for(unsigned int i=0; i<ROOMS-1; i++)
        {
			std::string name = "Sensor";			
			std::stringstream ss;
			ss << i;
			name.append(ss.str());

			s[i] = new MyTaskSensor(name.c_str(), i+1, n[i+1], 1);		std::cout<<"Create TASK Sensor" << i << " (ID: " << i+1 << ")"<< std::endl;
		}		

		// Communicator creation (Protocol 802.15.4):

        CoreCommunicatorSetup_t ccoms;
        ccoms.extensionId = "core";
        ccoms.ack_required = true;
        ccoms.short_addresses = true;
        ccoms.type = CoreCommunicatorSetup_t::MAC_802_15_4;
           
		Scnsl::Core::Communicator_if_t * mac[ROOMS];
        
		for(unsigned int i=0; i<ROOMS; i++)
        {
			std::string name = "Mac";			
			std::stringstream ss;
			ss << i;
			name.append(ss.str());

			ccoms.name = name;
        	ccoms.node = n[i];
        	mac[i] = sim->createCommunicator( ccoms ); 
		}

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

        tracer->addOutput( & std::cout );

		// Node's properties setup and bindings:

  		BindSetup_base_t bsb[ROOMS];

		bsb[0].extensionId = "core";
		bsb[0].bindIdentifier = "";
	    bsb[0].destinationNode = NULL;
	    bsb[0].node_binding.x = 0;
	    bsb[0].node_binding.y = 0;
	    bsb[0].node_binding.z = 0;
	    bsb[0].node_binding.bitrate = Scnsl::Protocols::Mac_802_15_4::BITRATE;
	    bsb[0].node_binding.transmission_power = 100;
	    bsb[0].node_binding.receiving_threshold = 10;

		for(unsigned int i=0; i<ROOMS-1; i++)
        {
			sim->bind( n[0], ch[i], bsb[0] );

			sim->bind( & c, NULL, ch[i], bsb[0], mac[0] );
		}

		for(unsigned int i=1; i<ROOMS; i++)
        {
			std::string bindId = "s";			
			std::stringstream ss;
			ss << i-1;
			bindId.append(ss.str());
			bindId.append("_c");

			bsb[i].extensionId = "core";
			bsb[i].bindIdentifier = bindId;
		    bsb[i].destinationNode = n[0];
		    bsb[i].node_binding.x = 1*i;
		    bsb[i].node_binding.y = 0;
		    bsb[i].node_binding.z = 0;
		    bsb[i].node_binding.bitrate = Scnsl::Protocols::Mac_802_15_4::BITRATE;
		    bsb[i].node_binding.transmission_power = 100;
		    bsb[i].node_binding.receiving_threshold = 10;

			sim->bind( n[i], ch[i-1], bsb[i] );

        	sim->bind( s[i-1], & c, ch[i-1], bsb[i], mac[i] );
		}


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
