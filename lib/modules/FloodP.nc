#include "../../includes/packet.h"

module FloodP{

   provides interface Flood;

   uses interface SimpleSend;

   uses interface NeighborDiscovery;

   uses interface Packet;
   uses interface AMPacket;

   uses interface Hashmap<uint16_t>;
   
}
implementation{
    pack floodPackage;
    uint16_t numNeighbor=0;
    uint16_t destination;
    uint16_t lastSrc;
    uint16_t currNeighbor;
    uint8_t old=0;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }

   task void floodTask(){
      if(call Hashmap.size()){
         if(call Hashmap.get(floodPackage.src)>=floodPackage.seq){
            old=1;
         }
      }
      if(!old){
         call Hashmap.insert(floodPackage.src,floodPackage.seq);
         numNeighbor= call NeighborDiscovery.numNeighbors();

         while(numNeighbor>0){
            currNeighbor= call NeighborDiscovery.NeighborNum(numNeighbor-1);
            if (currNeighbor==destination){
               numNeighbor=1;
               call SimpleSend.send(floodPackage,destination);
            }else{
               if(currNeighbor!=lastSrc){
                  call SimpleSend.send(floodPackage,currNeighbor);
               }
            }

            numNeighbor--;
         }
         
         
         dbg(FLOODING_CHANNEL, "Flood %d Neighbors\n", numNeighbor);
      }
      old=0;
   }

   command error_t Flood.flood(pack msg, uint16_t dest, uint16_t tempSrc){
      lastSrc=tempSrc;
      floodPackage=msg;
      destination = dest;
      post floodTask();
      return SUCCESS;
   }


}