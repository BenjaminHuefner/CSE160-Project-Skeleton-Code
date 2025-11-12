#include "../../includes/packet.h"
#include "../../includes/socket.h"

module TCPP{

   provides interface TCP;

   uses interface Timer<TMilli> as baseTimer;

   uses interface IP;
   uses interface Packet;
   
   uses interface Random;
   
}
implementation{
    uint16_t i[10];
    socket_t sockets[10];
    pack packet;

    void makePack(pack *Package, uint16_t srcport, uint16_t destport, uint16_t flags, uint16_t advWindow, uint16_t seq, uint8_t* byte){
      Package->src = srcport;
      Package->dest = destport;
      Package->TTL = flags;
      Package->seq = seq;
      Package->protocol = advWindow;
      memcpy(Package->payload, byte, 8);
   }



    command error_t TCP.testServer(uint8_t src, uint8_t port){
        dbg(GENERAL_CHANNEL, "TEST SERVER EVENT %d on port %d\n",TOS_NODE_ID,port);
    };

    command error_t TCP.testClient(uint8_t src, uint8_t srcport, uint8_t dest, uint8_t destport, uint16_t transfer){
        dbg(GENERAL_CHANNEL, "TEST CLIENT EVENT %d to %d:%d from port %d\n",src,dest,destport,srcport);
        i[srcport]=0;
        while(i[srcport]<transfer){
         if(transfer - i[srcport] >= 5){
         dbg(GENERAL_CHANNEL, "%d,%d,%d,%d,%d\n", i[srcport],i[srcport]+1,i[srcport]+2,i[srcport]+3,i[srcport]+4);
         i[srcport]+=5;
         } else {
         dbg(GENERAL_CHANNEL, "%d\n", i[srcport]);
         i[srcport]++;
         }
      }
    };

    event void baseTimer.fired(){};
    event void IP.sendState(uint8_t updated){};
    event void IP.tcpReceived(uint8_t* payload){};

}