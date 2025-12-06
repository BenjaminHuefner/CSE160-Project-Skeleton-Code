#include "../../includes/packet.h"
#include "../../includes/socket.h"

module TCPP{

   provides interface TCP;

   uses interface Timer<TMilli> as baseTimer;
   uses interface Queue<pack>;
   uses interface Queue<uint8_t> as Queue2;

   uses interface IP;
   uses interface Packet;
   
   uses interface Random;
   
}
implementation{
    uint16_t i[10];
    uint8_t nodeID;
    uint8_t state=0;
    uint8_t finSeq=0;
    uint8_t activeSocket=0;
    uint16_t temp;
    uint8_t byteSent;
    uint8_t* dummy= &nodeID;
    socket_store_t sockets[10];
    socket_store_t* currentSocket;
    pack sendPacket;
    pack recvPacket;

    uint32_t time;

    // flag 0 = nothing
    // flag 1 = SYN
    // flag 2 = ACK
    // flag 3 = SYN-ACK
    // flag 4 = FIN
    // flag 5 = FIN-ACK

    void makePack(pack *Package, uint16_t srcport, uint16_t destport, uint16_t flags, uint8_t seq, uint8_t advWindow, uint8_t* byte){
      Package->src = srcport;
      Package->dest = destport;
      Package->TTL = flags;
      Package->seq = seq;
      Package->protocol = advWindow;
      memcpy(Package->payload, byte, 8);
   }

   void sendSyn(uint8_t dest, uint16_t destport, uint16_t srcport){
    // dbg(GENERAL_CHANNEL, "%d\n",temp);
    
    dbg(GENERAL_CHANNEL,"starting Syn index %d\n",temp);
    // dbg(GENERAL_CHANNEL, "%d\n",temp);
    sockets[srcport].lastSent = (uint8_t) temp;
    sockets[srcport].lastAck= (uint8_t) temp;
    if(sockets[srcport].lastAck>127){sockets[srcport].lastAck=127;}
    sockets[srcport].lastWritten= (uint8_t) temp;
    sockets[srcport].updatable = 1;
    sockets[srcport].lastTypeSent= 1;
    sockets[srcport].lastTimeSent= call baseTimer.getNow();
      makePack(&sendPacket, srcport, destport, 1,temp, sockets[srcport].advWin, dummy);
      call IP.sendTCP(nodeID, dest, &sendPacket);

       dbg(GENERAL_CHANNEL, "SYN Sent from %d:%d to %d:%d\n",TOS_NODE_ID,srcport ,dest,destport);

   }

    void sendAck(uint8_t dest, uint16_t destport, uint16_t srcport){
        byteSent=sockets[srcport].nextExpected;
        
        // sockets[srcport].updatable = 1;
        // sockets[srcport].lastTypeSent= 2;
        // sockets[srcport].lastTimeSent= call baseTimer.getNow();
      makePack(&sendPacket, srcport, destport, 2,0, sockets[srcport].advWin, &byteSent);
      call IP.sendTCP(nodeID, dest, &sendPacket); 
       dbg(GENERAL_CHANNEL, "ACK Sent from %d:%d to %d:%d acknowledging byte %d\n",TOS_NODE_ID,srcport ,dest,destport,byteSent);
    }

    void sendSynAck(uint8_t dest, uint16_t destport, uint16_t srcport){
        byteSent=sockets[srcport].nextExpected;
    // dbg(GENERAL_CHANNEL, "%d\n",temp);
        dbg(GENERAL_CHANNEL,"starting SynAck index %d\n",temp);
        // dbg(GENERAL_CHANNEL, "%d\n",temp);
        sockets[srcport].lastSent = (uint8_t) temp;
        sockets[srcport].lastAck= (uint8_t) temp-1;
    if(sockets[srcport].lastAck>127){sockets[srcport].lastAck=127;}
        sockets[srcport].lastWritten= (uint8_t) temp;
    sockets[srcport].updatable = 1;
        sockets[srcport].lastTypeSent= 3;
        sockets[srcport].lastTimeSent= call baseTimer.getNow();
        makePack(&sendPacket, srcport, destport, 3,temp, sockets[srcport].advWin, &byteSent);
        call IP.sendTCP(nodeID, dest, &sendPacket);
        
        dbg(GENERAL_CHANNEL, "SYN-ACK Sent from %d:%d to %d:%d\n",TOS_NODE_ID,srcport ,dest,destport);
    }

    void sendFin(uint8_t dest, uint16_t destport, uint16_t srcport){
        finSeq = sockets[srcport].lastWritten +1;
        
    sockets[srcport].updatable = 1;
        sockets[srcport].lastTypeSent= 4;
        sockets[srcport].lastTimeSent= call baseTimer.getNow();
      makePack(&sendPacket, srcport, destport, 4,finSeq, 0, dummy);
      call IP.sendTCP(nodeID, dest, &sendPacket); 
       dbg(GENERAL_CHANNEL, "FIN Sent from %d:%d to %d:%d\n",TOS_NODE_ID,srcport ,dest,destport);
    }

    void sendFinAck(uint8_t dest, uint16_t destport, uint16_t srcport){
        finSeq = sockets[srcport].lastWritten +1;
        byteSent=sockets[srcport].nextExpected;
    sockets[srcport].updatable = 1;
        sockets[srcport].lastTypeSent= 5;
        sockets[srcport].lastTimeSent= call baseTimer.getNow();
      makePack(&sendPacket, srcport, destport, 5,finSeq, 0, &byteSent);
      call IP.sendTCP(nodeID, dest, &sendPacket); 
       dbg(GENERAL_CHANNEL, "FIN-ACK Sent from %d:%d to %d:%d\n",TOS_NODE_ID,srcport ,dest,destport);
    }


    command error_t TCP.testServer(uint8_t src, uint8_t port){
        dbg(GENERAL_CHANNEL, "TEST SERVER EVENT %d on port %d\n",TOS_NODE_ID,port);
        temp=call Random.rand16();
        temp=temp>>9;
        nodeID=src;
        sockets[port].state = LISTEN;
        sockets[port].socketState = 0; // Server Socket
        sockets[port].advWin=128;
        sockets[port].RTT=70000;
        return SUCCESS;
    }

    command error_t TCP.testClient(uint8_t src, uint8_t srcport, uint8_t dest, uint8_t destport, uint16_t transfer){
        dbg(GENERAL_CHANNEL, "TEST CLIENT EVENT %d to %d:%d from port %d\n",src,dest,destport,srcport);
        nodeID=src;
        temp=call Random.rand16();
        temp=temp>>9;
        sendSyn(dest, destport, srcport);
        sockets[srcport].nodeDest = dest;
        sockets[srcport].nodeDestPort = destport;
        sockets[srcport].nodeSrcPort = srcport;
        sockets[srcport].dest.port = destport;
        sockets[srcport].state = SYN_SENT;
        sockets[srcport].testTransferFin = transfer;
        sockets[srcport].testTransferCurr = 0;
        sockets[srcport].socketState = 1; // Client Socket
        sockets[srcport].advWin=128;
        sockets[srcport].RTT=70000;
        if(call baseTimer.isRunning() == FALSE){
            call baseTimer.startOneShot((call Random.rand16() %1000));
        }

        // i[srcport]=0;
        // while(i[srcport]<transfer){
        //  if(transfer - i[srcport] >= 5){
        //  dbg(GENERAL_CHANNEL, "%d,%d,%d,%d,%d\n", i[srcport],i[srcport]+1,i[srcport]+2,i[srcport]+3,i[srcport]+4);
        //  i[srcport]+=5;
        //  } else {
        //  dbg(GENERAL_CHANNEL, "%d\n", i[srcport]);
        //  i[srcport]++;
        //  }

        return SUCCESS;
      
    }
    void updateRTT(){
        if(currentSocket->RTTupdatable){
            currentSocket->RTT= ((8*currentSocket->RTT) + (call baseTimer.getNow() - currentSocket->lastTimeSent)*8)/10;
            dbg(GENERAL_CHANNEL, "RTT updated to: %d\n",currentSocket->RTT);
        }
        currentSocket->RTTupdatable=1;
    }   

    task void processData(){
        if(!call Queue.empty()){
            pack p = call Queue.dequeue();
            uint8_t orgSrc = call Queue2.dequeue();
            // dbg(GENERAL_CHANNEL, "Processing Data at %d\n",TOS_NODE_ID);
            // dbg(GENERAL_CHANNEL, "From %d to %d\n",p.src,p.dest);
            // dbg(GENERAL_CHANNEL, "Flags: %d Seq: %d AdvWindow: %d\n",p.TTL,p.seq,p.protocol);
            currentSocket=&sockets[p.dest];
            switch(p.TTL){
                case 0: //DATA
                    // Handle Data Packet
                        // dbg(GENERAL_CHANNEL, "DATA Received at %d from %d:%d with payload: %d\n",TOS_NODE_ID,orgSrc,p.src, *(p.payload));
                    if(currentSocket->lastRcvd+1 != sockets[activeSocket].lastRead){
                        if(p.seq==currentSocket->nextExpected){
                        if(currentSocket->lastRcvd+1 >127 ){
                            currentSocket->lastRcvd=0;
                        }else{
                            currentSocket->lastRcvd=currentSocket->lastRcvd+1;   
                        }
                        if(currentSocket->advWin !=0){
                            currentSocket->advWin--;
                        }
                        // dbg(GENERAL_CHANNEL, "last received %d\n", currentSocket->lastRcvd);
                        currentSocket->rcvdBuff[currentSocket->lastRcvd]=*(p.payload);
                        currentSocket->nextExpected= p.seq+1;
                                if(currentSocket->nextExpected>127){currentSocket->nextExpected=0;}
                        }
                        sendAck(orgSrc, p.src, p.dest);
                    }
                    break;
                case 1: //SYN
                    // Handle SYN Packet
                    switch(currentSocket->state){
                        case LISTEN:
                            dbg(GENERAL_CHANNEL, "SYN Received at %d from listening \n",TOS_NODE_ID);
                            currentSocket->nodeDest = orgSrc;
                            currentSocket->nodeSrcPort = p.dest;
                            currentSocket->nodeDestPort = p.src;
                            currentSocket->state = SYN_RCVD;
                            currentSocket->nextExpected= p.seq+1;
                            if(currentSocket->nextExpected>127){currentSocket->nextExpected=0;}
                            updateRTT();
                            sendSynAck(orgSrc, p.src, p.dest);
                            break;
                        case SYN_SENT:
                            dbg(GENERAL_CHANNEL, "SYN Received at %d from syn_sent \n",TOS_NODE_ID);
                            currentSocket->nodeDest = orgSrc;
                            currentSocket->nodeSrcPort = p.dest;
                            currentSocket->nodeDestPort = p.src;
                            currentSocket->state = SYN_RCVD;
                            currentSocket->nextExpected= p.seq+1;
                            if(currentSocket->nextExpected>127){currentSocket->nextExpected=0;}
                            updateRTT();
                            sendSynAck(orgSrc, p.src, p.dest);
                            break;
                    }
                    break;
                case 2: //ACK
                    // Handle ACK Packet
                    switch(currentSocket->state){
        
                        case SYN_RCVD:
                            // dbg(GENERAL_CHANNEL, "payload: %d, last Sent +1: %d\n",*(p.payload),currentSocket->lastSent + 1);
                            // if(*(p.payload) == currentSocket->lastSent + 1){
                                currentSocket->state = ESTABLISHED;
                                currentSocket->nodeDest = orgSrc;
                                currentSocket->nodeSrcPort = p.dest;
                                currentSocket->nodeDestPort = p.src;
                                currentSocket->dest.port = p.src;
                                currentSocket->updatable = 0;
                                currentSocket->effectiveWindow=p.protocol;
                                // dbg(GENERAL_CHANNEL, "test\n");
                                updateRTT();
                                dbg(GENERAL_CHANNEL, "Connection Established at %d, port %d\n",TOS_NODE_ID,p.dest);
                            // }
                            break;
                        case ESTABLISHED:
                            // Handle Data Acknowledgment
                            currentSocket->lastAck=*(p.payload)-1;
                            currentSocket->effectiveWindow=p.protocol;
                            if(currentSocket->lastAck>127){currentSocket->lastAck=127;}
                            // dbg(GENERAL_CHANNEL, "last Ack %d, lastSeqSent %d\n",currentSocket->lastAck,currentSocket->lastSeqSent);
                            if(currentSocket->lastTypeSent!=0 || currentSocket->lastAck== currentSocket->lastSeqSent){
                                // dbg(GENERAL_CHANNEL, "test2\n");
                                if(currentSocket->RTTupdatable){
                                    updateRTT();
                                }
                                currentSocket->seqUpdatable=1;
                            }
                            break;

                        case LAST_ACK:
                            // if(*(p.payload) == currentSocket->lastAck + 1){
                                currentSocket->state = CLOSED;
                                dbg(GENERAL_CHANNEL, "Connection Closed at %d\n",TOS_NODE_ID);
                            // }
                            break;
                    }
                    break;
                case 3: //SYN-ACK
                    // Handle SYN-ACK Packet
                    switch(currentSocket->state){
                        case SYN_SENT:
                        // dbg(GENERAL_CHANNEL, "test\n");
                        
                        // dbg(GENERAL_CHANNEL, "payload: %d, lastSent +1: %d\n",*(p.payload),currentSocket->lastSent + 1);
                        // if(*(p.payload) == currentSocket->lastSent + 1){
                            // dbg(GENERAL_CHANNEL, "test2\n");
                            currentSocket->state = ESTABLISHED;
                                currentSocket->nodeDest = orgSrc;
                            currentSocket->nodeSrcPort = p.dest;
                            currentSocket->nodeDestPort = p.src;
                                currentSocket->dest.port = p.src;
                            currentSocket->nextExpected= p.seq+1;
                            currentSocket->effectiveWindow=p.protocol;
                            if(currentSocket->nextExpected>127){currentSocket->nextExpected=0;}
                            updateRTT();
                            sendAck(orgSrc, p.src, p.dest);
                            dbg(GENERAL_CHANNEL, "Connection Established at %d, port %d\n",TOS_NODE_ID,p.dest);
                            // currentSocket->state = ESTABLISHED;
                            // sendAck(p.src, p.src, p.dest);
                            // dbg(GENERAL_CHANNEL, "Connection Established at %d\n",TOS_NODE_ID);
                            break;
                        // }
                        case ESTABLISHED:
                            sendAck(orgSrc, p.src, p.dest);
                            break;
                    }
                    break;
                case 4: //FIN
                    // Handle FIN Packet
                    switch(currentSocket->state){
                        case ESTABLISHED:
                            currentSocket->state = LAST_ACK;
                            currentSocket->seqUpdatable=0;
                            updateRTT();
                            sendFinAck(orgSrc, p.src, p.dest);
                            break;
                        case LAST_ACK:
                            sendFinAck(orgSrc, p.src, p.dest);
                            break;
                    }
                    break;
                case 5: //FIN-ACK
                    // Handle FIN-ACK Packet
                    if(currentSocket->state == FIN_WAIT1){
                        // currentSocket->state = TIME_WAIT;
                        // if(p.seq == currentSocket->lastWritten + 1){
                            currentSocket->state = CLOSED;
                            updateRTT();
                            currentSocket->seqUpdatable=0;
                            sendAck(orgSrc, p.src, p.dest);
                            dbg(GENERAL_CHANNEL, "Connection Closed at %d\n",TOS_NODE_ID);
                            dbg(GENERAL_CHANNEL, "last byte written %d\n", currentSocket->sendBuff[currentSocket->lastWritten]);
                        // }
                    }
                    break;

                
            }   
        }
        if(call baseTimer.isRunning() == FALSE){
                call baseTimer.startOneShot((call Random.rand16() %1000));
            }
   }
    void update(uint8_t index){
        time=call baseTimer.getNow();
        // dbg(GENERAL_CHANNEL,"timeUpdate %d\n",time);
        if(time-sockets[index].lastTimeSent>sockets[index].RTT && sockets[index].updatable == 1){
            // dbg(GENERAL_CHANNEL,"last time %d, RTT %d\n",sockets[index].lastTimeSent,sockets[index].RTT);
            sockets[index].RTTupdatable=0;
            switch(sockets[index].lastTypeSent){
                case 0: //DATA
                    // Handle Data Packet
                    sockets[index].lastSent=sockets[index].lastAck;
                    // dbg(GENERAL_CHANNEL,"test\n");
                    break;
                case 1: //SYN
                    // Handle SYN Packet
                    if(sockets[index].state != ESTABLISHED){
                    sendSyn(sockets[index].nodeDest,sockets[index].nodeDestPort,sockets[index].nodeSrcPort);
                    }
                    break;
                case 2: //ACK
                    // Handle ACK Packet
                    // sendAck(sockets[index].nodeDest,sockets[index].dest.port,sockets[index].src);
                    break;
                case 3: //SYN-ACK
                    // Handle SYN-ACK Packet
                    sendSynAck(sockets[index].nodeDest,sockets[index].nodeDestPort,sockets[index].nodeSrcPort);
                    break;
                case 4: //FIN
                    // Handle FIN Packet
                    sendFin(sockets[index].nodeDest,sockets[index].nodeDestPort,sockets[index].nodeSrcPort);
                    break;
                case 5: //FIN-ACK
                    // Handle FIN-ACK Packet
                    sendFinAck(sockets[index].nodeDest,sockets[index].nodeDestPort,sockets[index].nodeSrcPort);
                    break;
            }
        }

    }
   task void sendTestData(){
    if(sockets[activeSocket].state != CLOSED){
        // dbg(GENERAL_CHANNEL,"test\n");
        update(activeSocket);
    }
    if(sockets[activeSocket].state == ESTABLISHED && sockets[activeSocket].socketState == 1){
        // dbg(GENERAL_CHANNEL,"this socket state:%d, this socket socketState:%d\n",sockets[activeSocket].state,sockets[activeSocket].socketState);
        // dbg(GENERAL_CHANNEL,"activesocket=%d\n",activeSocket);
        // Send Data Packet
        if(sockets[activeSocket].testTransferCurr < sockets[activeSocket].testTransferFin && sockets[activeSocket].lastWritten+1 !=sockets[activeSocket].lastAck){
            // dbg(GENERAL_CHANNEL, "lastWritten before: %d\n",sockets[activeSocket].lastWritten);
            // dbg(GENERAL_CHANNEL, "lastWritten +1: %d\n",sockets[activeSocket].lastWritten+1);
            if(sockets[activeSocket].lastWritten+1 >127){
                sockets[activeSocket].lastWritten=0;
            }else{
                sockets[activeSocket].lastWritten=sockets[activeSocket].lastWritten+1;   
            }
            sockets[activeSocket].sendBuff[sockets[activeSocket].lastWritten] = sockets[activeSocket].testTransferCurr;
            // dbg(GENERAL_CHANNEL, "lastWritten: %d\n",sockets[activeSocket].lastWritten);
            // dbg(GENERAL_CHANNEL, "Data at index %d: %d\n",sockets[activeSocket].lastWritten,sockets[activeSocket].sendBuff[sockets[activeSocket].lastWritten]);
            sockets[activeSocket].testTransferCurr++;
            // dbg(GENERAL_CHANNEL, "testTransferCurr: %d\n",sockets[activeSocket].testTransferCurr);
        }
        // dbg(GENERAL_CHANNEL, "lastSent before: %d\n",sockets[activeSocket].lastSent);
        // dbg(GENERAL_CHANNEL, "lastSent +1: %d\n",sockets[activeSocket].lastSent+1);
        if(sockets[activeSocket].lastSent != sockets[activeSocket].lastWritten && sockets[activeSocket].sendBuff[sockets[activeSocket].lastAck] !=
        sockets[activeSocket].testTransferFin){
            // All data sent
        // dbg(GENERAL_CHANNEL, "lastSent before: %d\n",sockets[activeSocket].lastSent);
        
        if(((sockets[activeSocket].lastSent <= sockets[activeSocket].lastWritten && sockets[activeSocket].lastAck <= sockets[activeSocket].lastWritten) ||
           (sockets[activeSocket].lastSent >= sockets[activeSocket].lastWritten && sockets[activeSocket].lastAck >= sockets[activeSocket].lastWritten))){
            // dbg(GENERAL_CHANNEL,"lastSent %d lastAck %d effective window %d\n",sockets[activeSocket].lastSent,sockets[activeSocket].lastAck,sockets[activeSocket].effectiveWindow);
           if((sockets[activeSocket].lastSent>=sockets[activeSocket].lastAck && sockets[activeSocket].lastSent-sockets[activeSocket].lastAck<sockets[activeSocket].effectiveWindow)||
           (sockets[activeSocket].lastSent<sockets[activeSocket].lastAck && sockets[activeSocket].lastAck-sockets[activeSocket].lastSent<sockets[activeSocket].effectiveWindow)){
            
            // dbg(GENERAL_CHANNEL, "Last sent after %d\n",sockets[activeSocket].lastSent);
            if(sockets[activeSocket].lastSent+1 >127 ){
                sockets[activeSocket].lastSent=0;
            }else{
                sockets[activeSocket].lastSent=sockets[activeSocket].lastSent+1;   
            }

            if(sockets[activeSocket].seqUpdatable){
                sockets[activeSocket].lastTypeSent= 0;
                sockets[activeSocket].lastSeqSent= sockets[activeSocket].lastSent;
                sockets[activeSocket].lastTimeSent= call baseTimer.getNow();
                sockets[activeSocket].seqUpdatable=0;
            }

            makePack(&sendPacket, activeSocket, sockets[activeSocket].dest.port, 0,sockets[activeSocket].lastSent, 0, &sockets[activeSocket].sendBuff[sockets[activeSocket].lastSent]);
            call IP.sendTCP(nodeID, sockets[activeSocket].nodeDest, &sendPacket);
            // dbg(GENERAL_CHANNEL, "DATA Sent from %d:%d to %d:%d\n",TOS_NODE_ID,activeSocket ,sockets[activeSocket].nodeDest,sockets[activeSocket].dest.port);
            // if(sockets[activeSocket].lastAck+1 >127 ){
            //     sockets[activeSocket].lastAck=0;
            // }else{
            //     sockets[activeSocket].lastAck=sockets[activeSocket].lastAck+1;   
            // }
           }
        }
        }
    }else{
        if(sockets[activeSocket].state == ESTABLISHED && sockets[activeSocket].socketState == 0){
            if(sockets[activeSocket].lastRead != sockets[activeSocket].lastRcvd ){
                // dbg(GENERAL_CHANNEL, "last read %d\n",sockets[activeSocket].lastRead);
                // dbg(GENERAL_CHANNEL, "last rcvd %d\n",sockets[activeSocket].lastRcvd);
                if(sockets[activeSocket].lastRead+1 >127 ){
                    sockets[activeSocket].lastRead=0;
                }else{
                    sockets[activeSocket].lastRead=sockets[activeSocket].lastRead+1;   
                }
                if(sockets[activeSocket].advWin != 128 ){
                    sockets[activeSocket].advWin++;
                }
                dbg(GENERAL_CHANNEL, "DATA Read %d\n",sockets[activeSocket].rcvdBuff[sockets[activeSocket].lastRead]);
            }
        }

    }

    activeSocket++;
    if(activeSocket>9){
        activeSocket=0;
    }
   }

   event void baseTimer.fired(){
    // dbg(GENERAL_CHANNEL, "Base Timer Fired at %d\n",TOS_NODE_ID);
      post processData();
      post sendTestData();
   }

    command error_t TCP.closeClient(uint8_t src, uint16_t port, uint8_t dest, uint16_t destport){
        nodeID=src;
        dbg(GENERAL_CHANNEL, "CLOSE CLIENT EVENT %d to %d:%d from port %d\n",nodeID,dest,destport,port);
        switch(sockets[port].state){
          case LISTEN:
            sockets[port].state = CLOSED;
            currentSocket->seqUpdatable=0;
            dbg(GENERAL_CHANNEL, "Socket Closed at %d from Listen\n",TOS_NODE_ID);
            break;
            case SYN_SENT:
            sockets[port].state = CLOSED;
            currentSocket->seqUpdatable=0;
            dbg(GENERAL_CHANNEL, "Socket Closed at %d from Syn_Sent\n",TOS_NODE_ID);
            break;
            case SYN_RCVD:
            sockets[port].state = FIN_WAIT1;
            currentSocket->seqUpdatable=0;
            sendFin(dest, destport, port);
            break;
            case ESTABLISHED:
            sockets[port].state = FIN_WAIT1;
            currentSocket->seqUpdatable=0;
            sendFin(dest, destport, port);
            break;
        }
        // sockets[port].state = CLOSED;
    };

    event void IP.sendState(uint8_t updated){};
    event void IP.tcpReceived(uint8_t src, uint8_t* payload){
        recvPacket= *(pack*)payload;
        call Queue.enqueue(recvPacket);
        call Queue2.enqueue(src);
        post processData();
        // dbg(GENERAL_CHANNEL, "TCP Received Event at %d\n",TOS_NODE_ID);
        // dbg(GENERAL_CHANNEL, "From %d:%d to %d:%d\n",src,recvPacket.src,nodeID,recvPacket.dest);
        // dbg(GENERAL_CHANNEL, "Flags: %d Seq: %d AdvWindow: %d\n",recvPacket.TTL,recvPacket.seq,recvPacket.protocol);

    };

}