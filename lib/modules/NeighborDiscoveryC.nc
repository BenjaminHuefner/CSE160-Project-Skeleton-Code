#include "../../includes/am_types.h"

configuration NeighborDiscoveryC{
   provides interface NeighborDiscovery;
}

implementation{
   components NeighborDiscoveryP;
   NeighborDiscovery = NeighborDiscoveryP.NeighborDiscovery;

    components new SimpleSendC(AM_PACK) as Sender;

   components new TimerMilliC() as broadcastTimer;
   components RandomC as Random;

   //Timers
   NeighborDiscoveryP.broadcastTimer -> broadcastTimer;
   NeighborDiscoveryP.Random -> Random;
   NeighborDiscoveryP.SimpleSend-> Sender;

   //Lists
   components new ListC(uint16_t, 20);
   components new HashmapC(uint16_t, 20);

   NeighborDiscoveryP.List -> ListC;
   NeighborDiscoveryP.Hashmap -> HashmapC;
}
