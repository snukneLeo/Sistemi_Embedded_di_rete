 

#ifndef MYTASKCOLLECTOR_HH
#define MYTASKCOLLECTOR_HH

#include <systemc>
#include <scnsl.hh>
 
class MyTaskCollector:
    public Scnsl::Tlm::TlmTask_if_t
{
public:

    SC_HAS_PROCESS( MyTaskCollector );
 
    MyTaskCollector( const sc_core::sc_module_name modulename,
              const task_id_t id,
              Scnsl::Core::Node_t * n,
              const size_t proxies )
    throw ();

    /// @brief Virtual destructor.
    virtual
    ~MyTaskCollector()
    throw ();

    /// @name Inherited interface methods.
    //@{


    virtual
    void b_transport( tlm::tlm_generic_payload & p, sc_core::sc_time & t );

    //@}

	/// @brief Signals when a packet is arrived.
    sc_core::sc_event _packetArrivedEvent;

private:

    /// @name Processes.
    //@{

	/// @brief Sender process.
    void _sendTemperature()
        throw ();
  
    /// @brief Disabled copy constructor.
    MyTaskCollector( const MyTaskCollector & );

    /// @brief Disabled assignment operator.
    MyTaskCollector & operator = ( MyTaskCollector & );
};



#endif

