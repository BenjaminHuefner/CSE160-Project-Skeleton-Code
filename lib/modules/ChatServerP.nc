#include "../../includes/socket.h"
#include "../../includes/chatMsg.h"

module ChatServerP{

   provides interface ChatServer;

   uses interface TCP;
   uses interface CommandHandler;
   uses interface Queue<chatMsg> as sendQueue;
   uses interface Queue<chatMsg> as rcvQueue;
   uses interface Timer<TMilli> as baseTimer;
   
   uses interface Random;
   
}
implementation{
    socket_store_t* serverSockets;
    socket_store_t* clientSocket;
    uint8_t connected[10]; //0 not connected, 1 connected, 2 confirmed
    uint8_t usernames[10][21];//first number of username is length
    chatMsg inProgress[10];
    uint8_t i=0;
    uint8_t j=0;
    uint8_t bad=0;
    uint8_t lasti=0;
    uint8_t availableLength=0;
    chatMsg message;
    chatMsg receivedMessage;
    uint8_t currentSocket=0;

    uint8_t tempport=0;
    uint8_t tempdest=0;
    uint8_t tempusername[20];
    uint8_t tempnamelength=0;
    uint8_t tempmsglength=0;
    uint8_t tempmsg[20];

    chatMsg tempmessage;


    event void CommandHandler.setChatServer(uint8_t port){
        // dbg(GENERAL_CHANNEL, "CHAT SERVER EVENT %d on port %d\n",TOS_NODE_ID,port);
        serverSockets=(socket_store_t*) call TCP.AppServer(TOS_NODE_ID, port);
    }
    event void CommandHandler.ChatConnect(uint8_t srcport, uint8_t dest, uint8_t destport, uint8_t namelength, uint8_t *username){
        // dbg(GENERAL_CHANNEL, "CHAT CONNECT EVENT %d to %d:%d from port %d with username %s\n",TOS_NODE_ID,dest,destport,srcport,username);
        // dbg(GENERAL_CHANNEL, "Name Length: %d\n",namelength);
    }
    event void CommandHandler.ChatBroadcast(uint8_t msglength,uint8_t *payload){
        // dbg(GENERAL_CHANNEL, "CHAT BROADCAST EVENT %d: %s\n",TOS_NODE_ID,payload);
        // dbg(GENERAL_CHANNEL, "Message Length: %d\n",msglength);
    }
    event void CommandHandler.ChatUnicast(uint8_t msglength, uint8_t namelength, uint8_t *username, uint8_t *msg){
        // dbg(GENERAL_CHANNEL, "CHAT UNICAST EVENT %d to %s: %s\n",TOS_NODE_ID,username,msg);
        // dbg(GENERAL_CHANNEL, "Lengths: msg %d, name %d\n",msglength, namelength);
    }
    event void CommandHandler.ChatList(){
        // dbg(GENERAL_CHANNEL, "CHAT LIST EVENT %d\n",TOS_NODE_ID);
    }
    task void writeMessage(){
        if(!call sendQueue.empty()){
            message= call sendQueue.head();
            // dbg(GENERAL_CHANNEL, "CHAT SENDING MESSAGE %d\n",TOS_NODE_ID);
            if(connected[message.msg[0]] !=0){
                clientSocket= &serverSockets[message.msg[0]];
                // dbg(GENERAL_CHANNEL, "CHAT SENDING MESSAGE to %d\n",message.msg[0]);
                // dbg(GENERAL_CHANNEL, "socket pointer: %p\n",clientSocket);
                if(clientSocket->lastWritten<clientSocket->lastAck){
                    availableLength=clientSocket->lastAck-clientSocket->lastWritten-1;
                    // dbg(GENERAL_CHANNEL, "Available Length: %d\n",availableLength);
                }else{
                    availableLength= 127 - clientSocket->lastWritten + clientSocket->lastAck;
                    // dbg(GENERAL_CHANNEL, "Available Length: %d\n",availableLength);
                }
                if(availableLength>=message.length-1){
                    for(i=1;i<message.length;i++){
                        if(clientSocket->lastWritten+1 >127){
                            clientSocket->lastWritten=0;
                        }else{
                            clientSocket->lastWritten=clientSocket->lastWritten+1;   
                        }
                        clientSocket->sendBuff[(clientSocket->lastWritten)]=message.msg[i];
                        // dbg(GENERAL_CHANNEL, "Char: %c\n",message.msg[i]);
                    }
                    // dbg(GENERAL_CHANNEL, "CHAT MESSAGE SENT %d: %s\n",TOS_NODE_ID,message.msg);
                    call sendQueue.dequeue();
                }
            }
        }
    }
    void readBuffer(){
        receivedMessage= inProgress[currentSocket];
        clientSocket= &serverSockets[currentSocket];
        // dbg(GENERAL_CHANNEL, "Current Socket: %d\n",currentSocket);
        // dbg(GENERAL_CHANNEL, "socket pointer: %p\n",clientSocket);
        if(connected[currentSocket]!=0 && receivedMessage.complete==0){
            // dbg(GENERAL_CHANNEL, "CHAT READING MESSAGE %d\n",TOS_NODE_ID);
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
                // dbg(GENERAL_CHANNEL, "Char: %c\n",receivedMessage.msg[receivedMessage.length]);
                receivedMessage.length=receivedMessage.length+1;
                if(receivedMessage.msg[receivedMessage.length-2]==(uint8_t)'\r' && receivedMessage.msg[receivedMessage.length-1]==(uint8_t)'\n'){
                    receivedMessage.complete=1;
                    // dbg(GENERAL_CHANNEL, "CHAT MESSAGE RECEIVED %d: %s\n",TOS_NODE_ID,receivedMessage.msg);
                    call rcvQueue.enqueue(receivedMessage);
                    receivedMessage.length=0;
                    for(i=0;i<100;i++){
                        receivedMessage.msg[i]=0;
                    }
                    receivedMessage.complete=0;
                }
                inProgress[currentSocket]=receivedMessage;
            }
            
        }
    
        currentSocket++;
        if(currentSocket>=10){
            currentSocket=0;
        }
        
    }
    task void readMessage(){
        if(!call rcvQueue.empty()){
            message= call rcvQueue.dequeue();
            switch(message.msg[0]){
                case 'h':
                    // dbg(GENERAL_CHANNEL, "CHAT HELLO %d\n",TOS_NODE_ID);
                    tempnamelength=0;
                    for(i=0;i<message.length;i++){
                        if(message.msg[i]==(uint8_t)' '){
                            lasti=i+1;
                            break;
                        }
                    }
                    for(i=lasti;i<message.length;i++){
                        if(message.msg[i]==(uint8_t)' '){
                            lasti=i+1;
                            break;
                        }
                        tempusername[i-lasti+1]=message.msg[i];
                        tempnamelength++;
                    }
                    // tempusername[0]=tempnamelength;
                    tempusername[0]=tempnamelength;
                    tempport=message.msg[lasti]-48;
                    // dbg(GENERAL_CHANNEL, "CHAT HELLO %d from %c with username %s\n",TOS_NODE_ID,tempport+48,tempusername);

                    for(i=0;i<21;i++){
                        usernames[tempport][i]=0;
                        if(i<tempnamelength+1){
                            usernames[tempport][i]=tempusername[i];
                        }
                    }
                    connected[tempport]=2;
                    for(i=0;i<21;i++){
                        tempusername[i]=0;
                    }

                    break;
                case 'm':
                    for(j=0;j<10;j++){
                        if(connected[j]==2 && j!=(message.msg[4]-48)){
                        // dbg(GENERAL_CHANNEL, "CHAT BROADCAST to %d\n",j);
                        for(i=0;i<message.length;i++){
                            if(message.msg[i]==(uint8_t)' '){
                                lasti=i+1;
                                break;
                            }
                        }
                        tempport=message.msg[lasti]-48;
                        lasti+=2;
                        for(i=0;i<100;i++){
                            tempmessage.msg[i]=0;
                        }
                        tempmessage.msg[0]=j;
                        tempmessage.msg[1]=(uint8_t)'m';
                        tempmessage.length=2;
                        for(i=0;i<21;i++){
                            tempusername[i]=usernames[tempport][i];
                        }
                        tempnamelength=tempusername[0];
                        for(i=1;i<tempnamelength+1;i++){
                            tempmessage.msg[tempmessage.length]=tempusername[i];
                            tempmessage.length++;
                        }
                        tempmessage.msg[tempmessage.length]= (uint8_t)':';
                        tempmessage.length++;
                        for(i=lasti;i<message.length;i++){
                            tempmessage.msg[tempmessage.length]=message.msg[i];
                            tempmessage.length++;
                        }
                        // dbg(GENERAL_CHANNEL, "CHAT BROADCAST MESSAGE %d: %s\n",TOS_NODE_ID,tempmessage.msg);
                        call sendQueue.enqueue(tempmessage);
                        }
                    }
                    break;
                case 'w':
                    // dbg(GENERAL_CHANNEL, "CHAT UNICAST %d\n",TOS_NODE_ID);
                    for(j=0;j<10;j++){
                        if(connected[j]==2 && j!=(message.msg[4]-48)){
                        for(i=0;i<message.length;i++){
                            if(message.msg[i]==(uint8_t)' '){
                                lasti=i+1;
                                break;
                            }
                        }
                        tempport=message.msg[lasti]-48;
                        lasti+=2;
                        bad=0;
                        for(i=lasti;i<message.length;i++){
                            // dbg(GENERAL_CHANNEL, "Comparing %c and %c\n",usernames[j][i-lasti+1],message.msg[i]);
                            if(usernames[j][i-lasti+1]!=0 && usernames[j][i-lasti+1]!=message.msg[i]){
                                bad=1;
                                break;
                            }
                            if(message.msg[i]==(uint8_t)' '){
                                lasti=i+1;
                                break;

                            }
                        }
                        if(bad==1){
                            continue;
                        }
                        for(i=0;i<100;i++){
                            tempmessage.msg[i]=0;
                        }
                        tempmessage.msg[0]=j;
                        tempmessage.msg[1]=(uint8_t)'w';
                        tempmessage.length=2;
                        for(i=0;i<21;i++){
                            tempusername[i]=usernames[tempport][i];
                        }
                        tempnamelength=tempusername[0];
                        for(i=1;i<tempnamelength+1;i++){
                            tempmessage.msg[tempmessage.length]=tempusername[i];
                            tempmessage.length++;
                        }
                        tempmessage.msg[tempmessage.length]= (uint8_t)':';
                        tempmessage.length++;
                        for(i=lasti;i<message.length;i++){
                            tempmessage.msg[tempmessage.length]=message.msg[i];
                            tempmessage.length++;
                        }
                        // dbg(GENERAL_CHANNEL, "CHAT UNICAST MESSAGE %d: %s\n",TOS_NODE_ID,tempmessage.msg);
                        call sendQueue.enqueue(tempmessage);
                        }
                    }
                    break;
                case 'l':
                    // dbg(GENERAL_CHANNEL, "CHAT LIST %d\n",TOS_NODE_ID);
                    for(i=0;i<message.length;i++){
                        if(message.msg[i]==(uint8_t)' '){
                            lasti=i+1;
                            break;
                        }
                        }
                        tempport=message.msg[lasti]-48;
                        for(i=0;i<100;i++){
                            tempmessage.msg[i]=0;
                        }
                        tempmessage.msg[0]=tempport;
                        tempmessage.msg[1]=(uint8_t)'l';
                        tempmessage.length=2;
                        for(i=0;i<10;i++){
                            if(connected[i]==2 && i!=tempport){
                                tempnamelength=usernames[i][0];
                                for(lasti=1;lasti<tempnamelength+1;lasti++){
                                    tempmessage.msg[tempmessage.length]=usernames[i][lasti];
                                    tempmessage.length++;
                                }
                                tempmessage.msg[tempmessage.length]= (uint8_t)',';
                                tempmessage.length++;
                            }
                        }
                        tempmessage.msg[tempmessage.length]= (uint8_t)'\r';
                        tempmessage.msg[tempmessage.length+1]= (uint8_t)'\n';
                        tempmessage.length+=2;
                        // dbg(GENERAL_CHANNEL, "CHAT LIST MESSAGE %d: %s\n",TOS_NODE_ID,tempmessage.msg);
                        call sendQueue.enqueue(tempmessage);

                    break;
                default:
                    // dbg(GENERAL_CHANNEL, "CHAT UNKNOWN MESSAGE %d: %s\n",TOS_NODE_ID,message.msg);
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
    event void TCP.serverConnected(uint8_t srcport, uint8_t destport){
        connected[srcport]=1;
        if(call baseTimer.isRunning() == FALSE){
            call baseTimer.startOneShot((call Random.rand16() %1000));
        }
    }
    event void TCP.clientConnected(uint8_t srcport, uint8_t destport){}
    event void CommandHandler.printLinkState(){}
    event void CommandHandler.printNeighbors(){}
    event void CommandHandler.setTestClient(uint16_t port, uint16_t dest, uint16_t destport, uint16_t transfer){}
    event void CommandHandler.printDistanceVector(){}
    event void CommandHandler.setTestServer(uint16_t port){}
    event void CommandHandler.printRouteTable(){}
    event void CommandHandler.closeClient(uint16_t port, uint16_t dest, uint16_t destport){}
    event void CommandHandler.ping(uint16_t destination, uint8_t *payload){}
    command void ChatServer.test(){}
}