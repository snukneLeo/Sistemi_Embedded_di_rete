 

#ifndef MYTASKCONTROLLER_HH
#define MYTASKCONTROLLER_HH

#include <systemc>
#include <scnsl.hh>
 
class MyTaskController:
    public Scnsl::Tlm::TlmTask_if_t
{
public:

    SC_HAS_PROCESS( MyTaskController );
 
    MyTaskController( const sc_core::sc_module_name modulename,
              const task_id_t id,
              Scnsl::Core::Node_t * n,
              const size_t proxies )
    throw ();

    /// @brief Virtual destructor.
    virtual
    ~MyTaskController()
    throw ();

    /// @name Inherited interface methods.
    //@{


    virtual
    void b_transport( tlm::tlm_generic_payload & p, sc_core::sc_time & t );

    //@}

private:

    /// @name Processes.
    //@{
  
    /// @brief Disabled copy constructor.
    MyTaskController( const MyTaskController & );

    /// @brief Disabled assignment operator.
    MyTaskController & operator = ( MyTaskController & );
};



#endif

