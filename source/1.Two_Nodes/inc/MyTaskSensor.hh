#ifndef MYTASKSENSOR_HH
#define MYTASKSENSOR_HH

#include <systemc>
#include <scnsl.hh>
 
class MyTaskSensor:
    public Scnsl::Tlm::TlmTask_if_t
{
public:

    SC_HAS_PROCESS( MyTaskSensor );
    MyTaskSensor( const sc_core::sc_module_name modulename,
              const task_id_t id,
              Scnsl::Core::Node_t * n,
              const size_t proxies )
    throw ();

    /// @brief Virtual destructor.
    virtual
    ~MyTaskSensor()
    throw ();

    /// @name Inherited interface methods.
    //@{


    virtual
    void b_transport( tlm::tlm_generic_payload & p, sc_core::sc_time & t );

    //@}

    unsigned int task_id;
private:

    /// @name Processes.
    //@{

    /// @brief Sender process.
    void _sendTemperature()
        throw ();
 


    /// @brief Disabled copy constructor.
    MyTaskSensor( const MyTaskSensor & );

    /// @brief Disabled assignment operator.
    MyTaskSensor & operator = ( MyTaskSensor & );
};



#endif

