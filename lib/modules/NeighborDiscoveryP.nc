#include "../../includes/packet.h"

module NeighborDiscoveryP{

   provides interface NeighborDiscovery;

   uses interface SimpleSend;

   uses interface Timer<TMilli> as broadcastTimer;

   uses interface List<uint8_t>;
   uses interface Hashmap<uint8_t>;

   uses interface Packet;
   uses interface AMPacket;
   uses interface AMSend;
   
   uses interface Random;
}
implementation{
   pack broadcastPackage;
   uint16_t nodeID=0;
   uint8_t *payload=&nodeID;
   uint16_t count=0;
   uint8_t temp=0;
   uint8_t source;
   uint16_t prot;
   uint8_t i;

   void delete(uint16_t src);

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
      count++;
      makePack(&broadcastPackage, nodeID, (AM_BROADCAST_ADDR), 1, 6, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      if(count==3){
         // dbg(GENERAL_CHANNEL,"test\n");
         signal NeighborDiscovery.neighborUpdate(nodeID);
      }
      call SimpleSend.send(broadcastPackage,(AM_BROADCAST_ADDR));
      
      if(call broadcastTimer.isRunning() == FALSE){
          // A random element of delay is included to prevent congestion.
         call broadcastTimer.startOneShot( (call Random.rand16() %30000)+1000);
      }
   }
   void updateTable(){
      dbg(NEIGHBOR_CHANNEL,"updating %d table\n",nodeID);
      i=call List.size();
      while (i>0){
         i--;
         temp =call Hashmap.get(call List.get(i));
         dbg(NEIGHBOR_CHANNEL, "Last seqNum from this neighbor %d\n", temp);
         if(count-temp>3){
            delete(call List.get(i));
            if(count>=3){
            // dbg(GENERAL_CHANNEL,"test\n");
               signal NeighborDiscovery.neighborUpdate(nodeID);
            }
         }
      }
      dbg(NEIGHBOR_CHANNEL,"updated\n");
      
   }

   task void broadcastTask(){  
      call broadcastTimer.startOneShot( (call Random.rand16() %3000)+10000);
      updateTable();
      postBroadcastTask();
   }

   event void broadcastTimer.fired(){
      post broadcastTask();
   }

   command error_t NeighborDiscovery.broadcast(uint8_t src){
      nodeID=src;
      postBroadcastTask();
      return SUCCESS;
   }

   void delete(uint16_t src){
      dbg(NEIGHBOR_CHANNEL, "deleting neighbor %d from %d\n",src,nodeID );
      call Hashmap.remove(src);
      temp=call List.popback();
      while(temp != src){  
         call List.pushfront(temp);
         temp= call List.popback();
      }
      dbg(NEIGHBOR_CHANNEL,"success\n");
      
   }

   task void newNeighbor(){
      
      if(prot==6){
         makePack(&broadcastPackage, nodeID, (AM_BROADCAST_ADDR), 1, 7, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
         call SimpleSend.send(broadcastPackage,(AM_BROADCAST_ADDR));
      }
   }

   command error_t NeighborDiscovery.neighborFound(uint8_t src, uint8_t protocol){
      source=src;
      prot=protocol;dbg(NEIGHBOR_CHANNEL, "%d Neighbor to %d\n", nodeID,source);
      if(!call Hashmap.contains(source)){ 
         dbg(NEIGHBOR_CHANNEL, "%d Neighbor %d not in table\n", nodeID,source);

         call Hashmap.insert(source,count);
         if(call List.size()==20){
            temp = call List.popback();
         }
         call List.pushfront(source);
         if(count>=3){
            // dbg(GENERAL_CHANNEL,"test\n");
            signal NeighborDiscovery.neighborUpdate(nodeID);
         }
      }else{
         dbg(NEIGHBOR_CHANNEL, "%d Neighbor %d in table\n", nodeID,source);
         //testing delete
         //if(src!=2) {call Hashmap.insert(src,count);}
         call Hashmap.insert(source,count);
      }
      post newNeighbor();
      return SUCCESS;
   }

   command uint16_t NeighborDiscovery.numNeighbors(){
      return call List.size();
   }

   command uint16_t NeighborDiscovery.NeighborNum(uint8_t ind){
      return call List.get(ind);
   }

   command error_t NeighborDiscovery.dump(){
      i=call List.size();
      dbg(GENERAL_CHANNEL, "Node %d has %d neighbor(s)\n",nodeID,i);
      while(i>0){
         i--;
         dbg(GENERAL_CHANNEL, "Node %d has neighbor: %d\n",nodeID,call List.get(i));
      }
      return SUCCESS;
   }

   event void AMSend.sendDone(message_t* msg, error_t error){
     
   }
}