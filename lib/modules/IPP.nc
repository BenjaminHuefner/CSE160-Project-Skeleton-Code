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
    uint8_t *pay=&nodeID;
    // uint8_t routing[256]={0};

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      seqNum++;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }

   task void sendTask(){
    if(!call Queue.empty()){
        // dbg(GENERAL_CHANNEL,"IP Send Task\n");
         if(routingState){
            // dbg(GENERAL_CHANNEL,"test\n");
            linkPackage= call Queue.head();
            call Queue.dequeue();
            IPPackage= *(pack*) linkPackage.payload;
            nextDest=call LinkRouting.routingTable(IPPackage.dest);
            linkPackage.dest=nextDest;
            call SimpleSend.send(linkPackage,linkPackage.dest);
            // dbg(GENERAL_CHANNEL, "%d IP Sending to %d\n",nodeID,linkPackage.dest);
            if(call IPTimer.isRunning() == FALSE){
               call IPTimer.startOneShot( (call Random.rand16() %300));
            }
         }
      }
   }

   event void IPTimer.fired(){
      post sendTask();
   }
   
    task void pingTask(){
        if(IPPackage.dest==nodeID){
            if(IPPackage.protocol==0){
                dbg(GENERAL_CHANNEL, "Ping Packet Received from %d\n",IPPackage.src);
                dbg(GENERAL_CHANNEL, "Package Payload: %s\n", IPPackage.payload);
                nextDest=IPPackage.src;
                dbg(GENERAL_CHANNEL, "PING REPLY EVENT %d to %d\n",TOS_NODE_ID,IPPackage.src);
                makePack(&IPPackage, nodeID, nextDest, 1, 1, seqNum, pay, PACKET_MAX_PAYLOAD_SIZE);
                nextDest=call LinkRouting.routingTable(IPPackage.dest);
                makePack(&linkPackage,nodeID,nextDest,20,1,seqNum, &IPPackage,PACKET_MAX_PAYLOAD_SIZE);
                call Queue.enqueue(linkPackage);
                post sendTask();
            }else{
                dbg(GENERAL_CHANNEL, "Ping Reply Received from %d\n",IPPackage.src);
                return;
            }
            
        }else{
            
            linkPackage.src=nodeID;
            call Queue.enqueue(linkPackage);
            post sendTask();
        }

        
        return;
    }
   
   event void LinkRouting.routingState(uint8_t updated){
    signal IP.sendState(updated);
        if(updated){
            routingState=1;
            post sendTask();
        }else{
            routingState=0;
        }
   }

   command error_t IP.sendPing(uint8_t src, uint8_t dest, uint8_t* payload){
    nodeID=src;
    makePack(&IPPackage, src, dest, 1, 0, seqNum, payload, PACKET_MAX_PAYLOAD_SIZE);
      temp= &IPPackage;
      seqNum--;
      makePack(&linkPackage,src,dest,20,0,seqNum, temp,PACKET_MAX_PAYLOAD_SIZE);
      post pingTask();
    return SUCCESS;

   }
   command error_t IP.readPing(pack msg, uint8_t ownID){
    nodeID=ownID;
    linkPackage=msg;
    temp=msg.payload;
    IPPackage= *(pack*) temp;
    post pingTask();
      
    return SUCCESS;

   }

   command error_t IP.sendTCP(uint8_t src , uint16_t dest, uint8_t* payload){
    nodeID=src;
    makePack(&IPPackage, src, dest, 5, 4, seqNum, payload, PACKET_MAX_PAYLOAD_SIZE);
      temp= &IPPackage;
      seqNum--;
      makePack(&linkPackage,src,dest,20,4,seqNum, temp,PACKET_MAX_PAYLOAD_SIZE);
      call Queue.enqueue(linkPackage);
      post sendTask();
    return SUCCESS;
   }

   command error_t IP.readTCP(pack msg, uint8_t ownID){
    // dbg(GENERAL_CHANNEL, "IP Read TCP Called \n");
    nodeID=ownID;
    linkPackage=msg;
    temp=msg.payload;
    IPPackage= *(pack*) temp;
    if(IPPackage.dest!=nodeID){
        linkPackage.src=nodeID;
        call Queue.enqueue(linkPackage);
        post sendTask();
        return SUCCESS;
    }
    signal IP.tcpReceived(IPPackage.src, IPPackage.payload);
    // dbg(GENERAL_CHANNEL, "TCP Packet Received from %d\n",IPPackage.src);
    // dbg(GENERAL_CHANNEL, "Package Payload: %s\n", IPPackage.payload);
    return SUCCESS;
   }

}