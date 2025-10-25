#include "../../includes/am_types.h"
#include "../../includes/packet.h"

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
   components new TimerMilliC() as floodTimer;
   components RandomC as Random;

   //Timers
   FloodP.floodTimer -> floodTimer;
   FloodP.Random -> Random;
   FloodP.SimpleSend-> Sender;

   //Lists
   components new HashmapC(uint16_t, 20);
   FloodP.Hashmap -> HashmapC;
   components new QueueC(pack, 20);

   FloodP.Queue -> QueueC;
  

}
