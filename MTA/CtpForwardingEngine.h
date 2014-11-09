#ifndef FORWARDING_ENGINE_H
#define FORWARDING_ENGINE_H

#include <AM.h>
#include <message.h>

/**
 * Author: Philip Levis
 * Author: Kyle Jamieson 
 * Author: Omprakash Gnawali
 * Author: Rodrigo Fonseca
 */

/* 
 * These timings are in milliseconds, and are used by
 * ForwardingEngineP. Each pair of values represents a range of
 * [OFFSET - (OFFSET + WINDOW)]. The ForwardingEngine uses these
 * values to determine when to send the next packet after an
 * event. FAIL refers to a send fail (an error from the radio below),
 * NOACK refers to the previous packet not being acknowledged,
 * OK refers to an acknowledged packet, and LOOPY refers to when
 * a loop is detected.
 *
 * These timings are defined in terms of packet times. Currently,
 * two values are defined: for CC2420-based platforms (4ms) and
 * all other platfoms (32ms). 
 */

enum {
#if PLATFORM_MICAZ || PLATFORM_TELOSA || PLATFORM_TELOSB || PLATFORM_TMOTE || PLATFORM_INTELMOTE2
  FORWARD_PACKET_TIME = 4,
#else
  FORWARD_PACKET_TIME = 32,
#endif
};

enum {
  SENDDONE_FAIL_OFFSET      =                       512,
  SENDDONE_NOACK_OFFSET     = FORWARD_PACKET_TIME  << 2,
  SENDDONE_OK_OFFSET        = FORWARD_PACKET_TIME  << 2,	//16
  LOOPY_OFFSET              = FORWARD_PACKET_TIME  << 4,
  SENDDONE_FAIL_WINDOW      = SENDDONE_FAIL_OFFSET  - 1,
  LOOPY_WINDOW              = LOOPY_OFFSET          - 1,
  SENDDONE_NOACK_WINDOW     = SENDDONE_NOACK_OFFSET - 1,
  SENDDONE_OK_WINDOW        = SENDDONE_OK_OFFSET    - 1,	//15
  CONGESTED_WAIT_OFFSET     = FORWARD_PACKET_TIME  << 2,
  CONGESTED_WAIT_WINDOW     = CONGESTED_WAIT_OFFSET - 1,
};


/* 
 * The number of times the ForwardingEngine will try to 
 * transmit a packet before giving up if the link layer
 * supports acknowledgments. If the link layer does
 * not support acknowledgments it sends the packet once.
 */
enum {
  MAX_RETRIES = 30,
};

/*
 * The network header that the ForwardingEngine introduces.
 * This header will change for the TinyOS 2.0 full release 
 * (it needs several optimizations).
 */
// typedef nx_struct {
//   nx_uint8_t control;
//   nx_am_addr_t origin;
//   nx_uint8_t seqno;
//   nx_uint8_t collectid;
//   nx_uint16_t gradient;
// } network_header_t;

/*
 * An element in the ForwardingEngine send queue.
 * The client field keeps track of which send client 
 * submitted the packet or if the packet is being forwarded
 * from another node (client == 255). Retries keeps track
 * of how many times the packet has been transmitted.
 */
typedef struct {
	message_t * ONE_NOK msg;
	uint8_t client;
	uint8_t retries;
	//parent under RT constraint
	am_addr_t rt_parent;
	//local; converted to local time whenever jumping from a sender to the receiver
	uint32_t origin_gen_timestamp;
	uint32_t abs_deadline;
	//for locally generated packet, generation time; for forwarded packet, first reception event time
  	uint32_t arrival_timestamp;
  	//local sender; cannot get from msg coz the packet may already start tx
	am_addr_t sender;
	//local tx # from the sender of this packet
	//uint16_t sender_seq;
	//local forward #
	uint16_t sender_ntw_seq;
} fe_queue_entry_t;

#endif
