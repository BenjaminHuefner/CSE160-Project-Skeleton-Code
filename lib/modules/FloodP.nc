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
    pack linkPackage;
    uint16_t numNeighbor=0;
    uint16_t seqNum=0;
    uint16_t nodeID;
    uint16_t currNeighbor;
    uint8_t old=0;
    uint16_t destination=0;
    uint8_t *pay=&seqNum;
    uint8_t *temp=&floodPackage;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seqNum;
      seqNum++;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }

   task void floodTask(){
      
      
      if(call Hashmap.contains(floodPackage.src)){
         if(call Hashmap.get(floodPackage.src)>=floodPackage.seq){
            old=1;
         }
      }
      if(!old){
         
         call Hashmap.insert(floodPackage.src,floodPackage.seq);
         numNeighbor= call NeighborDiscovery.numNeighbors();
         linkPackage.TTL--;
         
         while(numNeighbor>0){
            currNeighbor= call NeighborDiscovery.NeighborNum(numNeighbor-1);
            if (currNeighbor!=linkPackage.src){
               linkPackage.src= nodeID;
               linkPackage.dest=currNeighbor;
               call SimpleSend.send(linkPackage,linkPackage.dest);
            }

            numNeighbor--;
         }
         if(floodPackage.dest==nodeID){
            if(!call Hashmap.get(floodPackage.src)>=floodPackage.seq){
               if(linkPackage.protocol==0){
                  dbg(GENERAL_CHANNEL, "Ping Packet Received from %d\n",floodPackage.src);
                  dbg(GENERAL_CHANNEL, "Package Payload: %s\n", floodPackage.payload);

                  destination=floodPackage.src;
                  dbg(GENERAL_CHANNEL, "PING REPLY EVENT %d to %d\n",TOS_NODE_ID,floodPackage.src);
                  makePack(&floodPackage, nodeID, destination, 1, 1, seqNum, pay, PACKET_MAX_PAYLOAD_SIZE);
                  makePack(&linkPackage,nodeID,destination,20,1,seqNum, &floodPackage,PACKET_MAX_PAYLOAD_SIZE);

                  old=0;
                  post floodTask();
                  return;
               }else{
                  if(linkPackage.protocol==1){
                     dbg(GENERAL_CHANNEL, "Ping Reply Received from %d\n",floodPackage.src);
                     return;
                  }

               }
            }
            
         }
         
         
         dbg(FLOODING_CHANNEL, "Flood %d Neighbors\n", numNeighbor);
      }
      old=0;
   }

   command error_t Flood.flood(pack msg,uint16_t ID){
      //lastSrc=tempSrc;
      nodeID=ID;
      linkPackage=msg;
      temp=msg.payload;
      floodPackage= *(pack*) temp;
      
      post floodTask();
      
      return SUCCESS;
   }

   command error_t Flood.startFlood(uint16_t src, uint16_t dest, uint8_t *payload){
      nodeID=src;
      makePack(&floodPackage, src, dest, 1, 0, seqNum, payload, PACKET_MAX_PAYLOAD_SIZE);
      temp= &floodPackage;
      makePack(&linkPackage,src,dest,20,0,seqNum, temp,PACKET_MAX_PAYLOAD_SIZE);
      post floodTask();
   }


}