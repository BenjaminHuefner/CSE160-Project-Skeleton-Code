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
    uint8_t connected=0;
    uint8_t dest=0;
    uint8_t thisUsername[20];  
    uint8_t usernameLength=0;
    uint8_t i=0;
    uint8_t availableLength=0;
    chatMsg message;
    chatMsg receivedMessage;
    chatMsg tempmessage;
    socket_store_t* clientSocket;

    event void CommandHandler.setChatServer(uint8_t port){
        // dbg(GENERAL_CHANNEL, "CHAT SERVER EVENT %d on port %d\n",TOS_NODE_ID,port);
    }
    event void CommandHandler.ChatConnect(uint8_t srcport, uint8_t dest, uint8_t destport, uint8_t namelength, uint8_t *username){
        dbg(GENERAL_CHANNEL, "CHAT CONNECT EVENT %d to %d:%d from port %d with username %s\n",TOS_NODE_ID,dest,destport,srcport,username);
        // dbg(GENERAL_CHANNEL, "Name Length: %d\n",namelength);
        usernameLength=namelength;
        for(i=0;i<namelength-1;i++){
            thisUsername[i]=username[i];
        }
        
        clientSocket=(socket_store_t*) call TCP.AppClient(TOS_NODE_ID, srcport, dest, destport);
        
        if(call baseTimer.isRunning() == FALSE){
            call baseTimer.startOneShot((call Random.rand16() %1000));
        }
        // dbg(GENERAL_CHANNEL, "CHAT CONNECT MESSAGE SENT %d: %s\n",TOS_NODE_ID,message.msg);
        // dbg(GENERAL_CHANNEL, "Message Length: %d\n",message.length);
        // dbg(GENERAL_CHANNEL, "Source Port: %d\n",message.msg[6+namelength]);
    }
    event void CommandHandler.ChatBroadcast(uint8_t msglength,uint8_t *payload){
        if(connected==0){
            return;
        }
        dbg(GENERAL_CHANNEL, "CHAT BROADCAST EVENT %d: %s\n",TOS_NODE_ID,payload);
        // dbg(GENERAL_CHANNEL, "Message Length: %d\n",msglength);
        for(i=0;i<100;i++){
            message.msg[i]=0;
        }   
        message.length= msglength+7;
        message.msg[0]=(uint8_t)'m';
        message.msg[1]=(uint8_t)'s';
        message.msg[2]=(uint8_t)'g';
        message.msg[3]=(uint8_t)' ';
        message.msg[4]=dest+48;
        message.msg[5]=(uint8_t)' ';
        for(i=0;i<msglength-1;i++){
            message.msg[6+i]=payload[i];
        }
        message.msg[6+msglength-1]=(uint8_t)'\r';
        message.msg[6+msglength]=(uint8_t)'\n';
        message.complete=1;
        call sendQueue.enqueue(message);
        // dbg(GENERAL_CHANNEL, "CHAT BROADCAST MESSAGE SENT %d: %s\n",TOS_NODE_ID,message.msg);
        // dbg(GENERAL_CHANNEL, "Message Length: %d\n",message.length);
    }
    event void CommandHandler.ChatUnicast(uint8_t msglength, uint8_t namelength, uint8_t *username, uint8_t *msg){
        if(connected==0){
            return;
        }
        dbg(GENERAL_CHANNEL, "CHAT UNICAST EVENT %d to %s: %s\n",TOS_NODE_ID,username,msg);
        // dbg(GENERAL_CHANNEL, "Lengths: msg %d, name %d\n",msglength, namelength);
        message.length= msglength+11+namelength;
        
        for(i=0;i<100;i++){
            message.msg[i]=0;
        }   
        message.msg[0]=(uint8_t)'w';
        message.msg[1]=(uint8_t)'h';
        message.msg[2]=(uint8_t)'i';
        message.msg[3]=(uint8_t)'s';
        message.msg[4]=(uint8_t)'p';
        message.msg[5]=(uint8_t)'e';
        message.msg[6]=(uint8_t)'r';
        message.msg[7]=(uint8_t)' ';
        message.msg[8]=dest+48;
        message.msg[9]=(uint8_t)' ';
        for(i=0;i<namelength-1;i++){
            message.msg[10+i]=username[i];
        }
        message.msg[10+namelength-1]=(uint8_t)' ';
        for(i=0;i<msglength-1;i++){
            message.msg[10+namelength+i]=msg[i];
        }
        message.msg[10+namelength+msglength-1]=(uint8_t)'\r';
        message.msg[10+namelength+msglength]=(uint8_t)'\n';
        message.complete=1;
        call sendQueue.enqueue(message);
        // dbg(GENERAL_CHANNEL, "CHAT UNICAST MESSAGE SENT %d: %s\n",TOS_NODE_ID,message.msg);
        // dbg(GENERAL_CHANNEL, "Message Length: %d\n",message.length);
    }
    event void CommandHandler.ChatList(){
        if(connected==0){
            return;
        }
        dbg(GENERAL_CHANNEL, "CHAT LIST EVENT %d\n",TOS_NODE_ID);
        message.length= 11;
        for(i=0;i<100;i++){
            message.msg[i]=0;
        }   
        message.msg[0]=(uint8_t)'l';
        message.msg[1]=(uint8_t)'i';
        message.msg[2]=(uint8_t)'s';
        message.msg[3]=(uint8_t)'t';
        message.msg[4]=(uint8_t)'u';
        message.msg[5]=(uint8_t)'s';
        message.msg[6]=(uint8_t)'r';
        message.msg[7]=(uint8_t)' ';
        message.msg[8]=dest+48;
        message.msg[9]=(uint8_t)'\r';
        message.msg[10]=(uint8_t)'\n';
        message.complete=1;
        call sendQueue.enqueue(message);
        // dbg(GENERAL_CHANNEL, "CHAT LIST MESSAGE SENT %d: %s\n",TOS_NODE_ID,message.msg);
    }
    task void writeMessage(){
        if(connected==1 && !call sendQueue.empty()){
            // dbg(GENERAL_CHANNEL, "CHAT SENDING MESSAGE %d\n",TOS_NODE_ID);
            message= call sendQueue.head();
            // dbg(GENERAL_CHANNEL, "socket pointer: %p\n",clientSocket);
            if(clientSocket->lastWritten<clientSocket->lastAck){
                availableLength=clientSocket->lastAck-clientSocket->lastWritten-1;
                // dbg(GENERAL_CHANNEL, "Available Length: %d\n",availableLength);
            }else{
                availableLength= 127 - clientSocket->lastWritten + clientSocket->lastAck;
                // dbg(GENERAL_CHANNEL, "Available Length: %d\n",availableLength);
            }
            if(availableLength>=message.length){
                for(i=0;i<message.length;i++){
                    if(clientSocket->lastWritten+1 >127){
                        clientSocket->lastWritten=0;
                    }else{
                        clientSocket->lastWritten=clientSocket->lastWritten+1;   
                    }
                    clientSocket->sendBuff[(clientSocket->lastWritten)]=message.msg[i];
                    // dbg(GENERAL_CHANNEL, "Sending: %c\n",clientSocket->sendBuff[clientSocket->lastWritten]);

                }
                // dbg(GENERAL_CHANNEL, "CHAT MESSAGE SENT %d: %s\n",TOS_NODE_ID,message.msg);
                call sendQueue.dequeue();
        }
        }
    }
    void readBuffer(){
        if(connected==1 && receivedMessage.complete==0){
                // if(clientSocket->lastRcvd){dbg(GENERAL_CHANNEL, "lastRcvd: %d\n",clientSocket->lastRcvd);}
            if(clientSocket->lastRead != clientSocket->lastRcvd){
                if(clientSocket->lastRead+1 >127){
                    clientSocket->lastRead=0;
                }else{
                    clientSocket->lastRead=clientSocket->lastRead+1;   
                }
                if(clientSocket->advWin != 128 ){
                    clientSocket->advWin++;
                }
                receivedMessage.msg[receivedMessage.length]=clientSocket->rcvdBuff[clientSocket->lastRead];
                receivedMessage.length=receivedMessage.length+1;
                // dbg(GENERAL_CHANNEL, "Received: %c\n",receivedMessage.msg[receivedMessage.length-1]);
                // dbg(GENERAL_CHANNEL, "lastRead: %d\n",clientSocket->lastRead);
                if(receivedMessage.msg[receivedMessage.length-2]==(uint8_t)'\r' && receivedMessage.msg[receivedMessage.length-1]==(uint8_t)'\n'){
                    receivedMessage.complete=1;
                    // dbg(GENERAL_CHANNEL, "CHAT MESSAGE RECEIVED %d: %s\n",TOS_NODE_ID,receivedMessage.msg);
                    call rcvQueue.enqueue(receivedMessage);
                    for(i=0;i<100;i++){
                        receivedMessage.msg[i]=0;
                    }
                    receivedMessage.length=0;
                    receivedMessage.complete=0;
                }
            }
            
        }
        
    }
    task void readMessage(){
        if(!call rcvQueue.empty()){
            message= call rcvQueue.dequeue();
            switch(message.msg[0]){
                case 'm':
                    // dbg(GENERAL_CHANNEL, "CHAT BROADCAST MESSAGE %d: %s\n",TOS_NODE_ID,message.msg);
                    for(i=0;i<100;i++){
                        tempmessage.msg[i]=0;
                    }   
                    tempmessage.length= message.length-1;
                    for(i=1;i<message.length-1;i++){
                        tempmessage.msg[i-1]=message.msg[i];
                    }
                    dbg(CHAT_CHANNEL, "%s\n",tempmessage.msg);
                    break;
                case 'w':
                    // dbg(GENERAL_CHANNEL, "CHAT UNICAST MESSAGE %d: %s\n",TOS_NODE_ID,message.msg);
                    for(i=0;i<100;i++){
                        tempmessage.msg[i]=0;
                    }   
                    tempmessage.length= message.length-1;
                    tempmessage.msg[0]=(uint8_t)'[';
                    tempmessage.msg[1]=(uint8_t)'W';
                    tempmessage.msg[2]=(uint8_t)'H';
                    tempmessage.msg[3]=(uint8_t)'I';
                    tempmessage.msg[4]=(uint8_t)'S';
                    tempmessage.msg[5]=(uint8_t)'P';
                    tempmessage.msg[6]=(uint8_t)'E';
                    tempmessage.msg[7]=(uint8_t)'R';
                    tempmessage.msg[8]=(uint8_t)']';
                    tempmessage.msg[9]=(uint8_t)' ';  
                    for(i=1;i<message.length-1;i++){
                        tempmessage.msg[i+9]=message.msg[i];
                    }
                    dbg(CHAT_CHANNEL, "%s\n",tempmessage.msg);
                    break;
                case 'l':
                    // dbg(GENERAL_CHANNEL, "CHAT LIST MESSAGE %d: %s\n",TOS_NODE_ID,message.msg);
                    for(i=0;i<100;i++){
                        tempmessage.msg[i]=0;
                    }   
                    tempmessage.length= message.length-1;
                    for(i=1;i<message.length-1;i++){
                        tempmessage.msg[i-1]=message.msg[i];
                    }
                    dbg(CHAT_CHANNEL, "%s\n",tempmessage.msg);
                    break;
                default:
                    dbg(CHAT_CHANNEL, "CHAT UNKNOWN MESSAGE %d: %s\n",TOS_NODE_ID,message.msg);
                    break;
            }
            // dbg(GENERAL_CHANNEL, "CHAT MESSAGE PROCESSED %d: %s\n",TOS_NODE_ID,message.msg);
        }
    }
    event void baseTimer.fired(){
        post writeMessage();
        readBuffer();
        post readMessage();
        if(call baseTimer.isRunning() == FALSE){
            call baseTimer.startOneShot((call Random.rand16() %1000));
        }
    }
    event void TCP.serverConnected(uint8_t srcport,uint8_t destport){}
    event void TCP.clientConnected(uint8_t srcport,uint8_t destport){
        connected=1;
        dest=destport;
        message.length= usernameLength+10;
        for(i=0;i<100;i++){
            message.msg[i]=0;
        }   
        message.msg[0]=(uint8_t)'h';
        message.msg[1]=(uint8_t)'e';
        message.msg[2]=(uint8_t)'l';
        message.msg[3]=(uint8_t)'l';
        message.msg[4]=(uint8_t)'o';
        message.msg[5]=(uint8_t)' ';
        for(i=0;i<usernameLength-1;i++){
            message.msg[6+i]=thisUsername[i];
        }
        message.msg[6+usernameLength-1]=(uint8_t)' ';
        message.msg[6+usernameLength]=destport+48;
        message.msg[6+usernameLength+1]=(uint8_t)' ';
        message.msg[6+usernameLength+2]=(uint8_t)'\r';
        message.msg[6+usernameLength+3]=(uint8_t)'\n';
        message.complete=1;
        
        call sendQueue.enqueue(message);
    }
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