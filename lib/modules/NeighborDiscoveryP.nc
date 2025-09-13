#include "../../includes/packet.h"

generic module NeighborDiscoveryP{

    provides interface NeighborDiscovery;

    uses interface SimpleSend;
}
implementation{
    pack broadcastPackage
    void postBroadcastTask(){
      // If a task already exist, we don't want to overwrite the clock, so
      // we can ignore it.
      if(call broadcastTimer.isRunning() == FALSE){
          // A random element of delay is included to prevent congestion.
         call broadcastTimer.startOneShot( (call Random.rand16() %3000)+10000);
      }
   }

   task void broadcastTask(){
        call SimpleSend.send()

        postBroadcastTask();
   }

   event void broadcastTimer.fired(){
      post broadcastTask();
   }


}