#include "../../includes/am_types.h"

configuration LinkRoutingC{
   provides interface LinkRouting;
}

implementation{
   components LinkRoutingP;
   LinkRouting = LinkRoutingP.SimpleSend;

   components new TimerMilliC() as sendTimer;
   components RandomC as Random;

   //Timers
   LinkRoutingP.sendTimer -> sendTimer;
   LinkRoutingP.Random -> Random;


   //Lists
   components new QueueC(sendInfo*, 20);

   LinkRoutingP.Queue -> QueueC;
}
