#include <Timer.h>
#include "TestMTA.h"

module TestMTAC {
uses {
    interface Boot;
    interface SplitControl as RadioControl;
    interface StdControl as RoutingControl;
    interface RTSend as Send;
    interface RTReceive as Receive;
    interface RTIntercept as Intercept;

    interface Leds;
    interface Timer<TMilli>;
    interface RootControl;

    interface GlobalTimer;
    interface UartLog;
    interface Random;
    interface Receive as SyncReceive;
    interface PacketTimeStamp<TMilli,uint32_t>;
    interface Packet as SubPacket;
#ifndef TOSSIM    
    //sync
    interface Receive as TimeSyncReceive;
    interface TimeSyncPacket<TMilli, uint32_t>;
    interface Packet;
#endif
    interface LocalTime<TMilli>;
    interface SplitControl as UartControl;
    interface Receive as UartReceive;
    //for analysis
    //interface RoutingTable;
}    
}
implementation {
	message_t packet;
	uint16_t seqNum;
	uint16_t timerFireTimes = 0;
	uint16_t send_cnts = 0;
	uint16_t sendDone_cnts = 0;
	bool sendBusy = FALSE;
	uint32_t period;
	uint32_t relative_deadline;

	//for event traffic
	//sync
	bool synced = FALSE;
	bool is_src = FALSE;
	//remember which stage is in and determine next interval to send
	uint8_t state = 0;
	uint32_t t0, t1, r;
	bool findEventTime(am_addr_t node_id, uint32_t *t0_, uint32_t *t1_);
	
	//send multiple pkts per UART command received
	uint8_t repeat_cnt = 0;


bool isSender(uint16_t nodeId) {
  	uint8_t i;
#if defined(TOSSIM)
  	uint16_t senderSet[] = {24};
#else
#ifndef INDRIYA
	#ifdef LINE_TOPOLOGY
		uint16_t senderSet[] = {76, 79, 60};
	#else
		//farthest 3 * 3
		uint16_t senderSet[] = {61, 62, 79, 80};	//{62, 76, 77, 79, 80, 81};
/*		{61, 62, 79, 80};
								{91, 92, 93,
			                    76, 77, 79,
			                    61, 62, 63, 64};
*/
	#endif
#else
	uint16_t senderSet[] = {1, 2, 3, 4};
#endif
#endif
    for (i = 0; i < sizeof(senderSet) / sizeof(senderSet[0]); i++) {
  		if (senderSet[i] == nodeId)
  			return TRUE;
  	}
  	return FALSE;
}
void testEDFQueue();
event void Boot.booted() {
    relative_deadline = RELATIVE_DEADLINE;
    dbg("MTAFoo", "%s: maxPayloadLength %hu and deadline %u %u\n", __FUNCTION__, call Send.maxPayloadLength(), relative_deadline);
    if (call Send.maxPayloadLength() < sizeof(EasyCollectionMsg)) {
        call Leds.led0On();
        return;
    }
    seqNum = 0;
#if defined(EVENT_TRAFFIC) & defined(INDRIYA)
	call UartControl.start();
#else	
    call RadioControl.start();
#endif
}

event void UartControl.startDone(error_t err) {
	if (err != SUCCESS)
		call UartControl.start();
	else
		call RadioControl.start();
}
  
event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS)
        call RadioControl.start();
    else {
#ifdef EVENT_TRAFFIC
		if (TOS_NODE_ID == ROOT_NODE_ID) {
            //after a node is set root; it will initialize all related metrics
            call RootControl.setRoot();
        }
        //turn on protocol
        call RoutingControl.start();
	#ifndef INDRIYA
        is_src = findEventTime(TOS_NODE_ID, &t0, &t1);
   	#endif
#else
        call Timer.startOneShot(NODES_BOOTUP_TIME);
#endif
    }
}

event void UartControl.stopDone(error_t err) {}
event void RadioControl.stopDone(error_t err) {}

void sendMessage() {
	//error_t ret;
	//uint32_t delay_mean, delay_var;
    //error_t is_synced;
    //uint32_t globalTime;
    EasyCollectionMsg* msg = (EasyCollectionMsg*)call Send.getPayload(&packet, sizeof(EasyCollectionMsg));
#if defined(EVENT_TRAFFIC) && defined(INDRIYA)
	if (repeat_cnt++ >= REPEAT_CNT)
		return;
#endif
    msg->nodeId = TOS_NODE_ID;
    msg->seq = seqNum++;
    //msg->timestamp = call GlobalTimer.getGlobalTime();
    //is_synced = call GlobalTimer.getGlobalTime(&globalTime);
    //get current e2e delay
    //ret = call RoutingTable.getPathDelay(&delay_mean, &delay_var);
#if defined(MCMP) || defined(MMSPEED) || defined(DS_P2)
    if (call Send.send(&packet, sizeof(EasyCollectionMsg), relative_deadline, PDR_REQ) != SUCCESS)  {
#else
    if (call Send.send(&packet, sizeof(EasyCollectionMsg), relative_deadline, PDR_REQ) != SUCCESS)  {
#endif
        call Leds.led0On();
        call UartLog.logTxRx(SEND_FAIL_FLAG, msg->nodeId, msg->seq, 0, 0, r, timerFireTimes, period, relative_deadline);
        dbg("MTA", "%s: packet %u failed vs %u from %u of period %u w/ deadline %u\n", __FUNCTION__, msg->seq, timerFireTimes, msg->nodeId, period, relative_deadline);
    } else {
        sendBusy = TRUE;
        //call UartLog.logTxRx(SEND_FLAG, msg->nodeId, msg->seq, 0, 0, 0, ret, delay_mean, delay_var);
       //dbg("MTA", "%s: pkt <%u, %u>, delay <%u, %u>\n", __FUNCTION__, msg->nodeId, msg->seq, delay_mean, delay_var);
        dbg_clear("MTA", "1\t%u\n", delay_mean);
        call UartLog.logTxRx(SEND_FLAG, msg->nodeId, msg->seq, 0, repeat_cnt, r, timerFireTimes, period, relative_deadline);
        //dbg("MTA", "%s: packet %u sent vs %u from %u\n", __FUNCTION__, msg->seq, timerFireTimes, msg->nodeId);
        dbg("MTAFoo", "%s: packet %u sent vs %u from %u of period %u w/ deadline %u\n", __FUNCTION__, msg->seq, timerFireTimes, msg->nodeId, period, relative_deadline);
    }
}
//event void RoutingTable.getNodeDelayEtxsTasksDone() {}

void convertLoc();
#ifndef EVENT_TRAFFIC
	event void Timer.fired() {
	#ifdef DEBUG
	if (24 == TOS_NODE_ID) {
		convertLoc();
	}
	#else
	//uint16_t r;
	switch (timerFireTimes) {
		case 0:	
		    if (TOS_NODE_ID == ROOT_NODE_ID) {
		        //after a node is set root; it will initialize all related metrics
		        call RootControl.setRoot();
		        dbg("MTAFoo", "%d is root \n", ROOT_NODE_ID);
		    } else {
		        if (isSender(TOS_NODE_ID))
		        //if (TOS_NODE_ID % 2 == 0)
		            call Timer.startOneShot(CONVERGE_TIME);
		    }
		    //turn on protocol
		    call RoutingControl.start();
		    break;
		case 1:
		    period = SRC_PERIOD;
		    call Timer.startOneShot(period);
		    break;
		default:
		   if (seqNum < PKT_NUM) {
		    	//TODO
		    	if (!sendBusy)
		            sendMessage();
		        call Timer.startOneShot(period);
		    }
	}
	timerFireTimes++;
	#endif
	}
#else	//EVENT_TRAFFIC
	event void Timer.fired() {
		//uint32_t r;

		if (!sendBusy)
            sendMessage();

		switch (state) {
			case 0:
				r = t0; break;
			case 1:
				r = t1; break;
			case 2:
				r = EVENT_PERIOD - t1; break;
			default:
				r = 0;	//this should not happen
		}
		state = (state + 1) % 3;
        call Timer.startOneShot(r / 4);
	}
#endif	//EVENT_TRAFFIC
  
event void Send.sendDone(message_t* m, error_t err) {
    if (err != SUCCESS)
      call Leds.led0On();
    sendBusy = FALSE;
#if defined(EVENT_TRAFFIC) && defined(INDRIYA)
	sendMessage();
#endif
}

event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len, uint32_t elapse_time) {
    EasyCollectionMsg* m = (EasyCollectionMsg*)call Send.getPayload(msg, sizeof(EasyCollectionMsg));
    //dbg("MTA", "%s: packet %u received from %u after %u ms\n", __FUNCTION__, m->seq, m->nodeId, elapse_time);
    //dbg_clear("MTA", "0\t%u\n", elapse_time);
    //if (24 == m->nodeId)
    //dbg_clear("receive", "%u %u %u\n", m->nodeId, m->seq, elapse_time);
    call UartLog.logEntry(RECEIVE_FLAG, m->nodeId, m->seq, elapse_time);
    return msg;
}

event bool Intercept.forward(message_t *msg, void *payload, uint8_t len, uint32_t elapse_time) {
  	//EasyCollectionMsg* m = (EasyCollectionMsg*)call Send.getPayload(msg, sizeof(EasyCollectionMsg));
  	//dbg("MTAFoo", "%s: packet %u intercepted from %u after %u ms\n", __FUNCTION__, m->seq, m->nodeId, elapse_time);
    //call UartLog.logEntry(INTERCEPT_FLAG, m->nodeId, m->seq, elapse_time);
    return TRUE;
}

//receive sync time
event message_t* SyncReceive.receive(message_t* msg, void* payload, uint8_t len) {
    uint32_t local_rx_timestamp = call PacketTimeStamp.timestamp(msg);
    uint32_t global_rx_timestamp = local_rx_timestamp;
    error_t is_synced = call GlobalTimer.local2Global(&global_rx_timestamp);
    sync_header_t *hdr = (sync_header_t*) call SubPacket.getPayload(msg, sizeof(sync_header_t));
    call UartLog.logTxRx(255, 18, call PacketTimeStamp.isValid(msg), hdr->seqno, is_synced, 0, 0, 0, global_rx_timestamp);
    return msg;
}

#ifndef TOSSIM
//listen to commander
event message_t* TimeSyncReceive.receive(message_t *msg, void *payload, uint8_t len) {
	//only for source
	if (!is_src)
		return msg;
	
	//already sync
	if (synced)
		return msg;
	
	if (call TimeSyncPacket.isValid(msg)) {
		//remaining time to the first global sync
		uint32_t global_start_interval;
		uint32_t local_time = call LocalTime.get();
		uint32_t local_event_time = call TimeSyncPacket.eventTime(msg);
		sync_header_t *hdr = (sync_header_t *) call Packet.getPayload(msg, sizeof(sync_header_t));
		synced = TRUE;
		/*
		 * diff = local_event_time - hdr->globalTime;
		 * CONVERGE_TIME - (local_time - diff)
		 * CONVERGE_TIME is in commander's clock, has to be larger than clock skew among all nodes
		 */
		global_start_interval = CONVERGE_TIME + local_event_time - local_time - hdr->globalTime;
		call Timer.startOneShot(global_start_interval);
		call UartLog.logEntry(DBG_FLAG, DBG_SYNC_FLAG, hdr->seqno, global_start_interval);
	}
	return msg;
}
#endif
typedef struct {
	am_addr_t id;
	uint16_t time;
} id_time_t;

id_time_t idTimes[] = {
{16, 0},
{4, 780},
{20, 840},
{2, 930},
{5, 1014},
{32, 1079},
{17, 1195},
{3, 1217},
{7, 1306},
{19, 1334},
{6, 1447},
{33, 1472},
{31, 1669},
{35, 1793},
{50, 1794},
{18, 1837},
{21, 1843},
{77, 1871},
{62, 1921},
{47, 1956},
{46, 2057},
{34, 2059},
{63, 2115},
{51, 2118},
{36, 2119},
{48, 2202},
{22, 2224},
{64, 2263},
{49, 2361},
{37, 2376},
{78, 2380},
{65, 2518},
{96, 2730},
{61, 2754},
{76, 2754},
{94, 2910},
{52, 2954},
{91, 2966},
{79, 3034},
{81, 3039},
{95, 3093},
{66, 3098},
{92, 3101},
{67, 3127},
{80, 3210},
{93, 3270},
{97, 3343},
{16, 5532},
{22, 6114},
{66, 6425},
{31, 6432},
{5, 6490},
{18, 6549},
{17, 6725},
{21, 6756},
{7, 6782},
{46, 6869},
{6, 6872},
{37, 7035},
{52, 7048},
{61, 7055},
{67, 7120},
{4, 7178},
{2, 7228},
{76, 7258},
{36, 7290},
{35, 7322},
{32, 7429},
{51, 7596},
{91, 7675},
{47, 7745},
{80, 7766},
{65, 7792},
{79, 7794},
{63, 7798},
{92, 7810},
{93, 7927},
{19, 7937},
{62, 7962},
{48, 7988},
{20, 8058},
{34, 8098},
{81, 8107},
{97, 8257},
{3, 8285},
{78, 8419},
{96, 8515},
{50, 8551},
{95, 8674},
{33, 8847},
{77, 8984},
{49, 9219},
{82, 9352},
{64, 9428},
{94, 9514},
{82, 14420},
};
/*
 * find the event time for the corresponding node
 * @param t0 & t1: for event 0 and 1 of node_id to occur
 * return FALSE if not found
 */
bool findEventTime(am_addr_t node_id, uint32_t *t0_, uint32_t *t1_) {
	uint8_t i;
	bool found0 = FALSE;
	bool found1 = FALSE;
	
	for (i = 0; i < sizeof(idTimes) / sizeof(idTimes[0]); i++) {
		if (idTimes[i].id == node_id) {
			if (!found0) {
				//find t0
				found0 = TRUE;
				*t0_ = idTimes[i].time;
			} else {
				//find t1
				found1 = TRUE;
				*t1_ = idTimes[i].time;
				break;
			}
		}
	}
	return found1;
}
#ifdef DEBUG
#include "TestMTAC_.nc"
#endif

//receive command from UART; for event traffic generation
event message_t* UartReceive.receive(message_t *msg, void *payload, uint8_t len) {
	//call UartLog.logEntry(DBG_FLAG, DBG_INJECTION_FLAG, seqNum, *((uint8_t *)payload));
	if (!sendBusy) {
		repeat_cnt = 0;
        sendMessage();
    }
    return msg;
}
}
