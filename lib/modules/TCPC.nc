#include "../../includes/packet.h"
#include "../../includes/socket.h"

configuration TCPC{
   provides interface TCP;
}

implementation{
  components TCPP;
   TCP = TCPP.TCP;


    components IPC;
    TCPP.IP -> IPC;

   //Timers
   components new TimerMilliC() as baseTimer;
   components RandomC as Random;

   //Timers
   TCPP.baseTimer -> baseTimer;
   TCPP.Random -> Random;

   //Lists
  

}
