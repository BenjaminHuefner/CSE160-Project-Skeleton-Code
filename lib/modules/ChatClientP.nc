#include "../../includes/socket.h"
#include "../../includes/chatMsg.h"

module ChatClientP{

   provides interface ChatClient;

   uses interface TCP;
   uses interface CommandHandler;
   uses interface Queue<chatMsg> as sendQueue;
   uses interface Queue<chatMsg> as rcvQueue;
   uses interface Timer<TMilli> as baseTimer;
   
   uses interface Random;
   
}
implementation{

    event void CommandHandler.setChatServer(uint8_t port){
        dbg(GENERAL_CHANNEL, "CHAT SERVER EVENT %d on port %d\n",TOS_NODE_ID,port);
    }
    event void CommandHandler.ChatConnect(uint8_t srcport, uint8_t dest, uint8_t destport, uint8_t namelength, uint8_t *username){
        dbg(GENERAL_CHANNEL, "CHAT CONNECT EVENT %d to %d:%d from port %d with username %s\n",TOS_NODE_ID,dest,destport,srcport,username);
        dbg(GENERAL_CHANNEL, "Name Length: %d\n",namelength);
    }
    event void CommandHandler.ChatBroadcast(uint8_t msglength,uint8_t *payload){
        dbg(GENERAL_CHANNEL, "CHAT BROADCAST EVENT %d: %s\n",TOS_NODE_ID,payload);
        dbg(GENERAL_CHANNEL, "Message Length: %d\n",msglength);
    }
    event void CommandHandler.ChatUnicast(uint8_t msglength, uint8_t namelength, uint8_t *username, uint8_t *msg){
        dbg(GENERAL_CHANNEL, "CHAT UNICAST EVENT %d to %s: %s\n",TOS_NODE_ID,username,msg);
        dbg(GENERAL_CHANNEL, "Lengths: msg %d, name %d\n",msglength, namelength);
    }
    event void CommandHandler.ChatList(){
        dbg(GENERAL_CHANNEL, "CHAT LIST EVENT %d\n",TOS_NODE_ID);
    }
    event void baseTimer.fired(){}
    event void TCP.serverConnected(uint8_t port){}
    event void TCP.clientConnected(uint8_t port){}
    event void CommandHandler.printLinkState(){}
    event void CommandHandler.printNeighbors(){}
    event void CommandHandler.setTestClient(uint16_t port, uint16_t dest, uint16_t destport, uint16_t transfer){}
    event void CommandHandler.printDistanceVector(){}
    event void CommandHandler.setTestServer(uint16_t port){}
    event void CommandHandler.printRouteTable(){}
    event void CommandHandler.closeClient(uint16_t port, uint16_t dest, uint16_t destport){}
    event void CommandHandler.ping(uint16_t destination, uint8_t *payload){}
    command void ChatClient.test(){}
}