#ifndef CHATMSG_H
#define CHATMSG_H


typedef struct chatMsg{
	uint8_t length;
	uint8_t complete;
	uint8_t msg[100];
}chatMsg;

#endif