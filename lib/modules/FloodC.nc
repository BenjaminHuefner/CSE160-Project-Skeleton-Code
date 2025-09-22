#include "../../includes/am_types.h"

configuration FloodC{
   provides interface Flood;
}

implementation{
  components FloodP;
   Flood = FloodP.Flood;

    components new SimpleSendC(AM_PACK) as Sender;

    components NeighborDiscoveryC;
    FloodP.NeighborDiscovery -> NeighborDiscoveryC;

   //Timers


   //Timers
   FloodP.SimpleSend-> Sender;

   //Lists
  

}
