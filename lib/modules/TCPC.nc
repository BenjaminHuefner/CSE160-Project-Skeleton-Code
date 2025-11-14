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

   components new QueueC(pack, 20);
   TCPP.Queue -> QueueC;
   components new QueueC(uint8_t, 20)as Queue2C;
    TCPP.Queue2 -> Queue2C;

   //Timers
   TCPP.baseTimer -> baseTimer;
   TCPP.Random -> Random;

   //Lists
  

}
