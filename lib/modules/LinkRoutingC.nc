#include "../../includes/am_types.h"

configuration LinkRoutingC{
   provides interface LinkRouting;
}

implementation{
   components LinkRoutingP;
   LinkRouting = LinkRoutingP.LinkRouting;

   components new TimerMilliC() as sendTimer;
   components RandomC as Random;
   components NeighborDiscoveryC;
    LinkRoutingP.NeighborDiscovery -> NeighborDiscoveryC;
    components FloodC;
    LinkRoutingP.Flood->FloodC;
    

   //Timers
   LinkRoutingP.sendTimer -> sendTimer;
   LinkRoutingP.Random -> Random;


}
