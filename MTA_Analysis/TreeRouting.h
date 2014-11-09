#ifndef _TREE_ROUTING_H
#define _TREE_ROUTING_H

#include <Collection.h>
#include <AM.h>

#define UQ_CTP_CLIENT "CtpSenderC.CollectId"

enum {
    // AM types:
    AM_CTP_ROUTING = 0x70,
    AM_CTP_DATA    = 0x71,
    AM_CTP_DEBUG   = 0x72,

    // CTP Options:
    CTP_OPT_PULL = 0x80, // TEP 123: P field
    CTP_OPT_ECN = 0x40, // TEP 123: C field
    //XL: highly congested filed
    CTP_OPT_HCN = 0x20,
};
    
//needed in DSRCS: median of ground truth
#ifdef INDRIYA
	#define	RSSI_THRESHOLD -37
#else
	#define	RSSI_THRESHOLD -43
#endif

enum {
	CLIENT_COUNT = uniqueCount(UQ_CTP_CLIENT),
#if defined(DS_P2)
	FORWARD_COUNT = 23,
#elif defined(INDRIYA) && defined(MMSPEED) || defined(EVENT_TRAFFIC)
	FORWARD_COUNT = 25, //12,
#else
	FORWARD_COUNT = 27, //12,
#endif
	TREE_ROUTING_TABLE_SIZE = 10,
	QUEUE_SIZE = CLIENT_COUNT + FORWARD_COUNT,
	CACHE_SIZE = 4,
};

enum {
    AM_TREE_ROUTING_CONTROL = 0xCE,
    BEACON_INTERVAL = 10000,	//8192, 
    INVALID_ADDR  = TOS_BCAST_ADDR,
    ETX_THRESHOLD = 50,      // link quality=20% -> ETX=5 -> Metric=50 
    PARENT_SWITCH_THRESHOLD = 15,
    MAX_METRIC = 0xFFFF,
    
    INVALID_RVAL = 0xFF,
    SEQNO_CACHE_SIZE = 4,
    MAX_UINT16 = 0xFFFF,
    MAX_UINT32 = 0xFFFFFFFF,
    MAX_INT32 = 0x7FFFFFFF,
    BITSHIFT_3 = 3,
    //MUST be larger than 2
#ifndef DS_P2
    DELAY_ETX_LEVEL_CNTS = 6,
#else
    DELAY_ETX_LEVEL_CNTS = 3,
#endif
    //sqrt(qtl / (1 - qtl))
    CHEBYSHEV_SCALAR = 3,	//qtl 0.99
    //1 / (1 - qtl)
    MARKOV_SCALAR = 10,
	
	//TODO: inc
    MAX_MAC_DELAY = 500,
    
    //needed in MCMP and MMSPEED
    PDR_SCALAR = 1000,



	//qtl estimation
	HEIGHT_SCALAR_BITS = 7,
    POS_SCALAR_BITS = 8,
	//scale 256 times
	MIN_QUANTILE = 222,	//87%
	MAX_QUANTILE = 238,	//93%
	QUANTILE_GRANULARITY = 4,	//3
	NUM_OF_QUANTILES = ((MAX_QUANTILE - MIN_QUANTILE) / QUANTILE_GRANULARITY + 1),
	INVALID_QUANTILE = MAX_QUANTILE + 1,
	MARKER_COUNTS = NUM_OF_QUANTILES + 4, //2 * NUM_OF_QUANTILES + 3, including 0, min / 2, (max + 1)/ 2 and 1
	//HEIGHT_SCALAR_BITS = 7,
	HEIGHT_SCALAR = (1 << HEIGHT_SCALAR_BITS),	//scale 128 times
	POS_SCALAR = (1 << POS_SCALAR_BITS),
	
	INVALID_DELAY = MAX_UINT32,
};
typedef nx_uint8_t nx_ctp_options_t;
typedef uint8_t ctp_options_t;

typedef nx_struct {
	nx_am_addr_t nb;
	//TODO: overflow possible
	nx_uint16_t in_mac_delay_mean;
	nx_uint16_t in_mac_delay_var;
	nx_uint16_t in_link_delay_mean;
	nx_uint16_t in_link_delay_var;
} mac_delay_t;

typedef nx_struct {
	nx_uint16_t node_delay_mean;
	nx_uint16_t node_delay_var;
	//min ETX over all paths w/ the preceding delay (or smaller)
	nx_uint16_t node_delay_etx;
} delay_etx_t;

//intermediate result, use 32 bits
typedef struct {
	am_addr_t nb;
	//bool congested;
	//for DIRECT_E2E_SAMPLE, it's the latest e2e delay; for others it's mean e2e delay
	uint32_t e2e_delay_mean;
	uint32_t e2e_delay_var;
	//include local queueing delay; used for diffusion
	uint32_t e2e_delay_qtl;
	//exclude local queueing delay; used for RT satisfiability test bcoz parent is selected after packet reaches head of queue; nlq: no local queueing
	uint32_t nlq_e2e_delay_qtl;
	//min ETX over all paths w/ the preceding delay (or smaller)
	uint32_t e2e_delay_etx;
} e2e_delay_etx_t;

typedef struct {
	am_addr_t parent;
	uint16_t etx;
	bool haveHeard;
	bool congested;
	
	//XL
	bool highlyCongested;
} route_info_t;

typedef struct {
	//path delay distribution thru this neighbor
	uint8_t sample_cnts;				//# of samples gathered; sort locally using height[]
    uint32_t height[MARKER_COUNTS];
    uint32_t pos[MARKER_COUNTS];
    uint32_t dd_pos[MARKER_COUNTS];      //desired position
    uint16_t dd_pos_unit[MARKER_COUNTS]; //unit increment of desired position
} e2e_delay_qtl_t;

typedef uint32_t delay_t;

typedef struct {
	am_addr_t neighbor;
	route_info_t info;
	
	//link ETX to this neighbor; a copy of the 4bitle ETX; save time to retrive
	//uint16_t link_etx;
	//pass RSSI threshold; for SDRCS
	bool pass_rssi;
	//hop count is based on RSSI threshold in SDRCS; otherwise it's based on connectivity
	uint8_t hop_cnt;
	//clock skew (mine - neighor's)
	int32_t signed_skew;
	//to differentiate received first copy and retx, especially when snoop
	uint8_t entry_idx;
	uint16_t seqno_cache[SEQNO_CACHE_SIZE];
	//MAC delay
	//in MAX_DELAY_MTA, mac_delay_mean stores max mac delay, mac_delay_var is 0
	//inbound
	uint16_t in_mac_delay_mean;
	uint16_t in_mac_delay_var;
	//outbound
	uint16_t out_mac_delay_mean;
	uint16_t out_mac_delay_var;
//#if defined(ML) || defined(ML_DAG)
	//link delay
	//in DIRECT_E2E_SAMPLE,  it's the latest link delay, including queueing
	//otherwise it's mean link delay
	//inbound
	uint16_t in_link_delay_mean;
	uint16_t in_link_delay_var;
	//outbound
	uint16_t out_link_delay_mean;
	//for MMSPEED-CD only
	uint16_t out_link_delay_var;
	//node delay
	uint16_t node_delay_mean;
//#endif
	//# of packets destinated from me to this neighbor so far
	//to compute weighted node MAC delay
	//maintain forwarding frequency to each neighbor
    uint32_t pkt_sent_cnts;
	//path delay and ETX from the neighbor, excluding local
	//in DIRECT_E2E_SAMPLE, include local
	delay_etx_t node_delay_etxs[DELAY_ETX_LEVEL_CNTS];
#ifdef DS_P2
	e2e_delay_qtl_t e2e_delay_qtls[DELAY_ETX_LEVEL_CNTS];
#endif
	//#ifdef DIRECT_E2E_SAMPLE
	uint16_t latest_node_delay[DELAY_ETX_LEVEL_CNTS];
} routing_table_entry;

/*
 * place all node_delay_etxs and only part of mac_delays into one packet
 * bcoz the former is supposed to change faster than the latter
 */
typedef nx_struct {
	nx_ctp_options_t    options;
	nx_uint8_t          thl;
	nx_uint16_t         etx;
	nx_am_addr_t        origin;
	
	//XL
	//6 Byte upto here
	nx_uint16_t e2e_pdr_req;
	//causes of being dropped
	//nx_uint8_t dropped;
	//nx_uint8_t originSeqNo;
	nx_uint16_t originSeqNo;  	
	//forwarding #
	nx_uint16_t localNtwSeq;
	//sequence # for each packet transmitted
	nx_uint16_t localSeq;
	//act as standard time which all other timestamps base on
	nx_uint32_t tx_timestamp;
//#if defined(DIRECT_E2E_SAMPLE) || defined(ML) || defined(ML_DAG)
	nx_uint32_t arrival_tx_interval;
	nx_uint16_t node_delay_mean;
//#endif
	//tx timestamp acts as benchmark; other timings (e.g., generating time, deadline) are represented using their interval w/ it
	//interval between generation and tx instant
	nx_uint32_t gen_tx_interval;
	//interval btw tx instant and deadline
	nx_uint32_t tx_deadline_interval;
	//32 Byte upto here
	//local; converted to local time whenever jumping from a sender to the receiver
	//nx_uint32_t abs_deadline;
	mac_delay_t mac_delays[NEIGHBOR_TABLE_SIZE / 3];	//10 Byte each: 30
	//path delay and ETX from the neighbor
	//in DIRECT_E2E_SAMPLE, mean node delay is the latest node delay sample, var is 0
	delay_etx_t node_delay_etxs[DELAY_ETX_LEVEL_CNTS];	//6 Byte each: 30
	
	nx_collection_id_t  type;
	nx_uint8_t (COUNT(0) data)[0]; // Deputy place-holder, field will probably be removed when we Deputize Ctp
} ctp_data_header_t;

typedef nx_struct {
	nx_ctp_options_t    options;
	nx_am_addr_t        parent;
	nx_uint16_t         etx;
	
	//only diffuse hop count in beacon bcoz it does not change fast
	nx_uint8_t hop_cnt;
	
	nx_uint32_t tx_timestamp;
	//nx_uint32_t abs_deadline;
	nx_uint16_t node_delay_mean;
	
	mac_delay_t mac_delays[NEIGHBOR_TABLE_SIZE / 3];
	//path delay and ETX from the neighbor
	delay_etx_t node_delay_etxs[DELAY_ETX_LEVEL_CNTS];
	
	nx_uint8_t (COUNT(0) data)[0]; // Deputy place-holder, field will probably be removed when we Deputize Ctp
} ctp_routing_header_t;


inline void routeInfoInit(route_info_t *ri) {
    ri->parent = INVALID_ADDR;
    ri->etx = 0;
    ri->haveHeard = 0;
    ri->congested = FALSE;
    ri->highlyCongested = FALSE;
}
#endif
