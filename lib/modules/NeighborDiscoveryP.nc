#include "../../includes/packet.h"

module NeighborDiscoveryP{

   provides interface NeighborDiscovery;

   uses interface SimpleSend;

   uses interface Timer<TMilli> as broadcastTimer;

   uses interface List<uint16_t>;

   uses interface Packet;
   uses interface AMPacket;
   uses interface AMSend;
   
   uses interface Random;
}
implementation{
   pack broadcastPackage;
   uint16_t numNeighbor=3;

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }

   void postBroadcastTask(){
      // If a task already exist, we don't want to overwrite the clock, so
      // we can ignore it.
      if(call broadcastTimer.isRunning() == FALSE){
          // A random element of delay is included to prevent congestion.
         call broadcastTimer.startOneShot( (call Random.rand16() %3000)+10000);
      }
   }

   task void broadcastTask(){
      dbg(GENERAL_CHANNEL, "Neighbor Discovery\n");
         //makePack(&broadcastPackage, TOS_NODE_ID, 0, 0, 0, 7, 0, PACKET_MAX_PAYLOAD_SIZE);
        //call SimpleSend.send(broadcastPackage,(AM_BROADCAST_ADDR));
   }

   event void broadcastTimer.fired(){
      post broadcastTask();
   }

   command error_t NeighborDiscovery.broadcast(){
      postBroadcastTask();
      return SUCCESS;
   }

   command error_t NeighborDiscovery.neighborFound(uint16_t src){
      dbg(NEIGHBOR_CHANNEL, "Neighbor to %d\n", src);
      numNeighbor++;
      return SUCCESS;
   }

   command uint16_t NeighborDiscovery.numNeighbors(){
      return numNeighbor;
   }

   command uint16_t NeighborDiscovery.NeighborNum(uint16_t ind){
      return call List.get(ind);
   }

   event void AMSend.sendDone(message_t* msg, error_t error){
     
      postBroadcastTask();
   }
}