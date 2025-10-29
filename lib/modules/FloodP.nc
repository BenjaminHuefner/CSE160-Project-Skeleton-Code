#include "../../includes/packet.h"

module FloodP{

   provides interface Flood;

   uses interface SimpleSend;
   uses interface Queue<pack>;
   uses interface Queue<pack> as Queue2;
   uses interface Timer<TMilli> as floodTimer;

   uses interface NeighborDiscovery;

   uses interface Packet;
   uses interface AMPacket;

   uses interface Hashmap<uint16_t>;
   
   uses interface Random;
   
}
implementation{
    pack floodPackage;
    pack linkPackage;
    uint16_t numNeighbor=0;
    uint16_t seqNum=1;
    uint16_t nodeID;
    uint16_t currNeighbor;
    uint8_t prevNeighbor;
    uint8_t old=0;
    uint16_t destination=0;
    uint8_t *pay=&seqNum;
    uint8_t *temp=&floodPackage;
    uint8_t neighborState=0;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seqNum;
      seqNum++;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }

   task void sendFlood(){
      
      if(!call Queue.empty()){
         if(neighborState){
            // dbg(GENERAL_CHANNEL,"test\n");
            linkPackage= call Queue.head();
            call Queue.dequeue();
            floodPackage= *(pack*) linkPackage.payload;
            numNeighbor= call NeighborDiscovery.numNeighbors();
            prevNeighbor=linkPackage.src;
            while(numNeighbor>0){
               currNeighbor= call NeighborDiscovery.NeighborNum(numNeighbor-1);
               
               if (currNeighbor!=prevNeighbor){
                  linkPackage.src= nodeID;
                  linkPackage.dest=currNeighbor;
                  
                  // dbg(FLOODING_CHANNEL, "%d Flood Neighbor %d\n", nodeID,currNeighbor);
                  // if(floodPackage.src==2){
                  // dbg(FLOODING_CHANNEL, "Node %d flooding to %d packet originally from %d with seq %d\n",nodeID, currNeighbor,floodPackage.src,floodPackage.seq);

                  // }
                  call SimpleSend.send(linkPackage,linkPackage.dest);
               }

               numNeighbor--;
            }
            if(call floodTimer.isRunning() == FALSE){
               call floodTimer.startOneShot( (call Random.rand16() %3000)+1000);
            }
         }
      }
   }
   event void floodTimer.fired(){
      post sendFlood();
   }
   task void floodTask(){
      linkPackage= call Queue2.head();
      call Queue2.dequeue();
      floodPackage= *(pack*) linkPackage.payload;
      
      if(call Hashmap.contains(floodPackage.src)){
         if(call Hashmap.get(floodPackage.src)>=floodPackage.seq){
            // dbg(FLOODING_CHANNEL,"Old Packet from %d with seq %d\n",floodPackage.src,floodPackage.seq);
            old=1;
         }
      }
      if(!old){
         
         call Hashmap.insert(floodPackage.src,floodPackage.seq);
         // numNeighbor= call NeighborDiscovery.numNeighbors();
         linkPackage.TTL--;
         call Queue.enqueue(linkPackage);
         if(call floodTimer.isRunning() == FALSE){
               call floodTimer.startOneShot( (call Random.rand16() %3000)+1000);
            }
         // post sendFlood();
         // while(numNeighbor>0){
         //    currNeighbor= call NeighborDiscovery.NeighborNum(numNeighbor-1);
         //    if (currNeighbor!=linkPackage.src){
         //       linkPackage.src= nodeID;
         //       linkPackage.dest=currNeighbor;
         //       call SimpleSend.send(linkPackage,linkPackage.dest);
         //    }

         //    numNeighbor--;
         // }
         //if(floodPackage.dest==nodeID){
            // if(!call Hashmap.get(floodPackage.src)>=floodPackage.seq){
               // dbg(GENERAL_CHANNEL,"test\n");
               if(floodPackage.protocol==2){
                  signal Flood.messageRecieved(floodPackage.payload);
                  
                  return;
               }//else{
                  // if(linkPackage.protocol==1){
                  //    dbg(GENERAL_CHANNEL, "Ping Reply Received from %d\n",floodPackage.src);
                  //    return;
                  // }

               // }
         //   }
            
         // }
         
         
         
      }
      old=0;
   }

   event void NeighborDiscovery.neighborUpdate(uint8_t updated){
      if(updated==0){
         neighborState=0;
      }else{
         nodeID=updated;
         neighborState=1;
         // dbg(GENERAL_CHANNEL,"test\n");
         post sendFlood();
      }
      signal Flood.floodUpdated(updated);
   }

   command error_t Flood.flood(pack msg,uint8_t ID){
      //lastSrc=tempSrc;
      nodeID=ID;
      linkPackage=msg;
      temp=msg.payload;
      floodPackage= *(pack*) temp;
      call Queue2.enqueue(linkPackage);
      post floodTask();
      
      return SUCCESS;
   }

   command error_t Flood.startFlood(uint8_t src, uint8_t dest, uint8_t *payload){
      nodeID=src;
      // dbg(GENERAL_CHANNEL, "Node %d starting flood to %d\n",src,dest);
      makePack(&floodPackage, src, dest, 1, 2, seqNum, payload, PACKET_MAX_PAYLOAD_SIZE);
      temp= &floodPackage;
      makePack(&linkPackage,src,dest,20,8,seqNum, temp,PACKET_MAX_PAYLOAD_SIZE);
      call Queue2.enqueue(linkPackage);
      post floodTask();
   }


}