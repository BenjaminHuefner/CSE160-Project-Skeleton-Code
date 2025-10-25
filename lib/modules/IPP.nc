#include "../../includes/packet.h"

module IPP{

   provides interface IP;

   uses interface SimpleSend;
   uses interface Queue<pack>;
   uses interface Timer<TMilli> as IPTimer;

   uses interface LinkRouting;

   uses interface Packet;
   uses interface AMPacket;

   
   uses interface Random;
   
}
implementation{
    pack IPPackage;
    pack linkPackage;
    uint8_t seqNum=0;
    uint8_t nextDest;
    uint8_t nodeID;
    uint8_t routingState=0;
    uint8_t *temp=&IPPackage;
    uint8_t routing[256]={0};

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      seqNum++;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }

   task sendTask(){
    if(!call Queue.empty()){
         if(routingState){
            // dbg(GENERAL_CHANNEL,"test\n");
            linkPackage= call Queue.head();
            call Queue.dequeue();
            SimpleSend.send(linkPackage,linkPackage.dest)
            if(call IPTimer.isRunning() == FALSE){
               call IPTimer.startOneShot( (call Random.rand16() %300));
            }
         }
      }
   }

   event void IPTimer.fired(){
      post sendTask();
   }
   
    task pingTask(){
        nextDest=call LinkRouting.routingTable(IPPackage.dest);
        linkPackage.dest=nextDest;
    }
   

   error_t sendPing(uint8_t src, uint8_t dest, uint8_t* payload){
    nodeID=src;
    makePack(&IPPackage, src, dest, 1, 0, seqNum, payload, PACKET_MAX_PAYLOAD_SIZE);
      temp= &IPPackage;
      seqNum--;
      makePack(&linkPackage,src,dest,20,0,seqNum, temp,PACKET_MAX_PAYLOAD_SIZE);
      post pingTask();
    return SUCCESS;

   }
   error_t readPing(pack msg, uint8_t ownID){
    nodeID=ownID;
    return SUCCESS;

   }

}