#ifndef TEST_MTA_H
#define TEST_MTA_H

//choose testbeds
//#define INDRIYA

/*
 * event traffic
 * use commander to sync for NetEye: start to send traffic @ CONVERGE_TIME
 * use injection to sync for Indriya
 */
//#define EVENT_TRAFFIC


//L-ML
//#define ML

/*
 * For NetEye, SPEED only works if no node outside the 15 by 7 grid is chosen bcoz location if the grid is easily determined by node id
 */
//SPEED: largest speed
//MMSPEED: 	1) reliability requirement;	2) multipath;	3) deadline: speed larger than required;	4) EDF
#define MMSPEED

//MMSPEED must be enabled to enable MMSPEED-CD; i.e., MMSPEED & MMSPEED_CD both defined to enable MMSPEED-CD
#define MMSPEED_CD

//a service-differentiated real-time communication scheme
//MMSPEED must be enabled to enable SDRCS!!! only difference is that SDRCS uses RSSI-based hop cnt as distance
//#define SDRCS	// MMSPEED must be enabled

//MCMP: 	1) reliability requirement; 2) multipath; 	3) deadline: hop speed
//#define MCMP

//min delay quantile: choose min delay quantile neighbor as parent and w/o DAG
//#define MDQ
//min delay quantile but w/ ETX DAG; should NOT work w/ ML_DAG; does not consider deadline now
//#define MDQ_DAG

//same w/ MTA but use mean delay for satisfiability test, not delay quantile
//#define MTA_MEAN_DELAY

//sample e2e delay directly as previously done immediately after Chicago trip
//use e2e delay sample to estimate its mean & variance
//#define DIRECT_E2E_SAMPLE
//DIRECT_E2E_SAMPLE must be defined to enable DS_P2
//use e2e delay sample to estimate its quantile directly
//have to reduce neighbor table size and queue size to accommodate P2
//#define DS_P2

//use link delay directly, do not further decompose into pkt time & queue size
//#define LD

//DAG based on ML, not ETX
//#define ML_DAG

//this option will disable all protocols but CTP
//#define CTP

//no deadline in L-ML & CTP
#if !(defined(ML) || defined(CTP) || defined(MCMP))
//EDF or FIFO queue; CTP only uses FIFO
#define EDF
#endif

//fix packet timestamping issue of the default radio stack
#define RX_TIMESTAMP

//parametric: only can be selected at a time; MTA of Chebysheve if none selected
//#define NORMAL
//#define EXP
//#define MAX

//to measure estimation error
//#define LINE_TOPOLOGY

//#define DEBUG

enum {
	RELATIVE_DEADLINE = 4000,	//0xEFFFFFFF,	//caution: not 8 F here
	PDR_REQ = 900U,	//e2e reliability requirement of a packet; scaled by PDR_SCALAR
#if !defined(TOSSIM)
	SRC_PERIOD = 100,		//75, 400, 1000 for NetEye; 200, 600, 1000 for Indriya
	EVENT_PERIOD = 15000,	//period to repeat lite-trace events
	CONVERGE_TIME = 180000U,	//1200000
	MAX_BEACON_PERIOD = 4000U,	//60000
	PKT_NUM = 65535U,
	#ifndef INDRIYA
	    ROOT_NODE_ID = 15, //Neteye	15
	#else
		ROOT_NODE_ID = 100,	//caution: 105 not programmable,
	#endif
	//# of pkts to send per UART cmd received; for indriya event only
	REPEAT_CNT = 2,
	
	COLUMNS = 15,
	ROWS = 7,
#else
	SRC_PERIOD = 1000,
	CONVERGE_TIME = 600000U,
	PKT_NUM = 65535U,
	MAX_BEACON_PERIOD = 60000U,	//5000
	ROOT_NODE_ID = 0,
	
	COLUMNS = 5,
	ROWS = 5,
#endif

	SEND_FLAG = 1,
	SEND_FAIL_FLAG = 0,
	INTERCEPT_FLAG = 2,
	RECEIVE_FLAG = 3,
	SW_FULL_FLAG = 5,
	REJECT_FLAG = 6,
	EXPIRE_FLAG = 11,

	TX_FLAG = 9,
	RX_FLAG = 10,
	
	MIN_BEACON_PERIOD = 128U,
#ifndef DS_P2
	NEIGHBOR_TABLE_SIZE = 10,
#else
	NEIGHBOR_TABLE_SIZE = 6,
#endif	
	NODES_BOOTUP_TIME = 6000,
	DBG_FLAG = 255,
	DBG_HEARTBEAT_FLAG = 1,
	DBG_EXEC_TIME_FLAG = DBG_HEARTBEAT_FLAG + 1,
	DBG_ASYNC_FLAG = DBG_EXEC_TIME_FLAG + 1,
	DBG_BEACON_FLAG = DBG_ASYNC_FLAG + 1,
	DBG_LOSS_IN_AIR_FLAG = DBG_BEACON_FLAG + 1,		//5
	DBG_SENDDONE_BUG_FLAG = DBG_LOSS_IN_AIR_FLAG + 1,
	DBG_CONGEST_FLAG = DBG_SENDDONE_BUG_FLAG + 1,
	DBG_SNOOP_FLAG = DBG_CONGEST_FLAG + 1,
	DBG_DEFAULT_HANDLER_FLAG = DBG_SNOOP_FLAG + 1,
	DBG_EDF_FLAG = DBG_DEFAULT_HANDLER_FLAG + 1,	//10
	DBG_REJ_CAUSE_FLAG = DBG_EDF_FLAG + 1,
	DBG_TIMEOUT_FLAG = DBG_REJ_CAUSE_FLAG + 1,
	DBG_SYNC_FLAG = DBG_TIMEOUT_FLAG + 1,
	DBG_MAC_DELAY_FLAG = DBG_SYNC_FLAG + 1,
	DBG_INJECTION_FLAG = DBG_MAC_DELAY_FLAG + 1,	//15
	DBG_ESTIMATE_ERR_FLAG = DBG_INJECTION_FLAG + 1,
	DBG_LINK_DELAY_FLAG = DBG_ESTIMATE_ERR_FLAG + 1,
	DBG_QUEUE_SIZE_FLAG = DBG_LINK_DELAY_FLAG + 1,
	DBG_PKT_TIME_FLAG = DBG_QUEUE_SIZE_FLAG + 1,
	DBG_RSSI_FLAG = DBG_PKT_TIME_FLAG + 1,			//20
	DBG_DAG_FLAG = DBG_RSSI_FLAG + 1,
	DBG_ESTIMATE_ERR_2_FLAG = DBG_DAG_FLAG + 1,
	
	AM_INDRIYA_SERIAL = 100,
	SERIAL_AM_TYPE = 9,

	//to receive sync packets
	AM_TYPE_SYNC = 12,
};

typedef nx_struct EasyCollectionMsg {
	nx_uint8_t nodeId;
	//nx_uint8_t place_holders[MAX_PAYLOAD_SIZE - 3];
	nx_uint16_t seq;
	//nx_uint32_t timestamp;
} EasyCollectionMsg;


//FTSP accuracy
typedef nx_struct {
	nx_uint16_t seqno;
	nx_uint32_t globalTime;
} sync_header_t;


#ifdef INDRIYA
//for Motelab/Indriya use only
typedef nx_struct {
	nx_uint8_t type;

	nx_uint8_t nodeId;
	//source of the packet
	nx_uint8_t sourceId;

	//source seq#
	nx_uint16_t seq;
	//sender of this packet
	//nx_uint16_t from;

	nx_uint8_t last_hop;

	//ntw seq#
	nx_uint16_t last_hop_ntw_seq;
	//MAC seq#
	nx_uint16_t last_hop_seq;	
	//ntw seq#
	nx_uint16_t local_ntw_seq;
	//MAC seq#
	nx_uint16_t local_seq;

	nx_uint32_t timestamp;
	nx_uint32_t seqno;
} log_msg_t;	//22 Bytes
 
 typedef nx_struct indriya_serial {
 	//log_msg_t log[4];	//114 / 22 = 5
 	log_msg_t m0;
 	log_msg_t m1;
 	log_msg_t m2;
 	log_msg_t m3;
 	log_msg_t m4;
 } indriya_serial_t;
#endif
 
#endif
