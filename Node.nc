/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{
   uses interface Boot;
   
   uses interface NeighborDiscovery;
   uses interface Flood as Flooder;
   uses interface LinkRouting;
   uses interface IP;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;
}

implementation{
   pack sendPackage;
   uint16_t seqNum=0;
   uint16_t numNeighbors=0;
   uint8_t *emptyPayload=&seqNum;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();

      call NeighborDiscovery.broadcast(TOS_NODE_ID);

      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}
   event void Flooder.floodUpdated(uint8_t updated){}
   event void Flooder.messageRecieved(uint8_t* pay){}
   event void NeighborDiscovery.neighborUpdate(uint8_t updated){}
   event void LinkRouting.routingState(uint8_t updated){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         if(myMsg->TTL==0){
            dbg(GENERAL_CHANNEL,"TTL expired\n");
         }else{
            if(myMsg->protocol==8){
               call Flooder.flood(*myMsg, TOS_NODE_ID);
            }
            if(myMsg->protocol==6 || myMsg->protocol==7){
               call NeighborDiscovery.neighborFound(myMsg->src,myMsg->protocol);
            }
            if(myMsg->protocol==0 || myMsg->protocol==1){
               call IP.readPing(*myMsg, TOS_NODE_ID);
            }
         }
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT %d to %d\n",TOS_NODE_ID,destination);
      call IP.sendPing(TOS_NODE_ID, destination, payload);
   }

   event void CommandHandler.printNeighbors(){
      call NeighborDiscovery.dump();
   }

   event void CommandHandler.printRouteTable(){
      call LinkRouting.printTable();
   }

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      seqNum++;
      memcpy(Package->payload, payload, length);
   }
}
