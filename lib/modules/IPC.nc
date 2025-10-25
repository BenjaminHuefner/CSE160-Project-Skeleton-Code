#include "../../includes/am_types.h"
#include "../../includes/packet.h"

configuration IPC{
   provides interface IP;
}

implementation{
  components IPP;
   IP = IPP.IP;

    components new SimpleSendC(AM_PACK) as Sender;

    components LinkRoutingC;
    IPP.LinkRouting -> LinkRoutingC;

   //Timers
   components new TimerMilliC() as IPTimer;
   components RandomC as Random;

   //Timers
   IPP.IPTimer -> IPPTimer;
   IPP.Random -> Random;
   IPP.SimpleSend-> Sender;

   //Lists
   components new QueueC(pack, 20);

   IPP.Queue -> QueueC;
  

}
