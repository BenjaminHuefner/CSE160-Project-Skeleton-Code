#include "../../includes/packet.h"

module FloodP{

   provides interface Flood;

   uses interface SimpleSend;

   uses interface NeighborDiscovery;

   uses interface Packet;
   uses interface AMPacket;
   
}
implementation{
    pack floodPackage;
    uint16_t numNeighbor=0;
    uint16_t destination;
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }

   task void floodTask(){
      numNeighbor= call NeighborDiscovery.numNeighbors();
      
      dbg(GENERAL_CHANNEL, "Flood %d Neighbors\n", numNeighbor);
        call SimpleSend.send(floodPackage,destination);
   }

   command error_t Flood.flood(pack msg, uint16_t dest ){
    floodPackage=msg;
    destination = dest;
      post floodTask();
      return SUCCESS;
   }


}