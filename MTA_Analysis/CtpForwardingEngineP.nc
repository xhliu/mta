#include <CtpForwardingEngine.h>
#include <CtpDebugMsg.h>

/* 
 * MCMP: for one Send.send success, there can be multiple sendDone back, but it does not matter bcoz sendDone only unlocks the client
 *			it does not hurt to unlock more than once
 *
 * packet time: from the first time a packet is sent, to it is received by next hop
 * 1) for recipient, regard enqueue as the instant for reception to account for processing btw receive event and enqueue; one exception is root, which does not forward
 * 2) for non-recipient that overhears, regard receive event instant as reception
 
 * TODO: 
 * 1) consider dropped packets bcoz of MAX_RETRIES to avoid underestimation
 * 2) local clock overflow
 * 3) consider adaptive forwarding backoff in packet time
 */
generic module CtpForwardingEngineP() {
provides {
    interface Init;
    interface StdControl;
    interface RTSend as Send[uint8_t client];
    interface RTReceive as Receive[collection_id_t id];
    interface Receive as Snoop[collection_id_t id];
    interface RTIntercept as Intercept[collection_id_t id];
    interface Packet;
    interface CollectionPacket;
    interface CtpPacket;
    interface CtpCongestion;
    
    //
    interface DataPanel;
}
  uses {
    interface Receive as SubReceive;
    interface Receive as SubSnoop;
    interface Packet as SubPacket;
    interface UnicastNameFreeRouting;
    interface SplitControl as RadioControl;
#if defined(EDF)
    interface EDFQueue<fe_queue_entry_t*> as SendQueue;
#else
    interface Queue<fe_queue_entry_t*> as SendQueue;
#endif
    interface Pool<fe_queue_entry_t> as QEntryPool;
    interface Pool<message_t> as MessagePool;
    interface Timer<TMilli> as RetxmitTimer;

    interface LinkEstimator;

    // Counts down from the last time we heard from our parent; used
    // to expire local state about parent congestion.
    interface Timer<TMilli> as CongestionTimer;

    interface Cache<message_t*> as SentCache;
    interface CtpInfo;
    interface PacketAcknowledgements;
    interface Random;
    interface RootControl;
    interface CollectionId[uint8_t client];
    interface AMPacket;
    interface CollectionDebug;
    interface Leds;
    
    
    //XL
#if defined(TOSSIM)
    interface AMSend as SubSend;
#else
    interface TimeSyncPacket<TMilli,uint32_t>;
    interface TimeSyncAMSend<TMilli,uint32_t> as SubSend;
#endif    
    interface LocalTime<TMilli> as LocalTimeMilli;
    
    interface RoutingTable;
    interface UartLog;
    interface Utils;
  }
}
implementation {
  /* Helper functions to start the given timer with a random number
   * masked by the given mask and added to the given offset.
   */
  static void startRetxmitTimer(uint16_t mask, uint16_t offset);
  static void startCongestionTimer(uint16_t mask, uint16_t offset);

  /* Indicates whether our client is congested */
  bool clientCongested = FALSE;

  /* Tracks our parent's congestion state. */
  bool parentCongested = FALSE;

  /* Threshold for congestion */
  uint8_t congestionThreshold;
  uint8_t highlyCongestionThreshold;

  /* Keeps track of whether the routing layer is running; if not,
   * it will not send packets. */
  bool running = FALSE;

  /* Keeps track of whether the radio is on; no sense sending packets
   * if the radio is off. */
  bool radioOn = FALSE;

  /* Keeps track of whether an ack is pending on an outgoing packet,
   * so that the engine can work unreliably when the data-link layer
   * does not support acks. */
  bool ackPending = FALSE;

  /* Keeps track of whether the packet on the head of the queue
   * is being used, and control access to the data-link layer.*/
  bool sending = FALSE;

  /* Keep track of the last parent address we sent to, so that
     unacked packets to an old parent are not incorrectly attributed
     to a new parent. */
  am_addr_t lastParent;
  
	//XL
	//retx or not; only dequeue if first tx
	bool is_retx = FALSE;
    uint32_t tx_timestamp;
    uint32_t last_timestamp;
    uint32_t post_timestamp;
    uint32_t tx_pkt_time_mean = 0;
    uint32_t tx_pkt_time_var = 0;
    static void estPktTime();
    
    
    uint16_t local_seq;
    //forward #
    uint16_t local_ntw_seq;
    uint16_t send_cnts = 0;
    uint16_t sendDone_cnts = 0;
    
    uint32_t my_node_delay_mean = 0;
    uint32_t my_node_delay_var = 0;
  /* Network-level sequence number, so that receivers
   * can distinguish retransmissions from different packets. */
  //uint8_t seqno;
  uint16_t seqno;
  static void dequeue(fe_queue_entry_t *qe, error_t err);

  enum {
    CLIENT_COUNT = uniqueCount(UQ_CTP_CLIENT)
  };

  /* Each sending client has its own reserved queue entry.
     If the client has a packet pending, its queue entry is in the 
     queue, and its clientPtr is NULL. If the client is idle,
     its queue entry is pointed to by clientPtrs. */

  fe_queue_entry_t clientEntries[CLIENT_COUNT];
  fe_queue_entry_t* ONE_NOK clientPtrs[CLIENT_COUNT];
	
	//XL: current pkt being tranmitted in the queue
	fe_queue_entry_t *p_fqe = NULL;
  /* The loopback message is for when a collection roots calls
     Send.send. Since Send passes a pointer but Receive allows
     buffer swaps, the forwarder copies the sent packet into 
     the loopbackMsgPtr and performs a buffer swap with it.
     See sendTask(). */
     
  message_t loopbackMsg;
  message_t* ONE_NOK loopbackMsgPtr;

  command error_t Init.init() {
    int i;
    for (i = 0; i < CLIENT_COUNT; i++) {
      clientPtrs[i] = clientEntries + i;
      dbg("Forwarder", "clientPtrs[%hhu] = %p\n", i, clientPtrs[i]);
    }
    congestionThreshold = 14;
    highlyCongestionThreshold = 20;
    loopbackMsgPtr = &loopbackMsg;
    lastParent = call AMPacket.address();
    seqno = 0;
    local_ntw_seq = 0;
    local_seq = 0;
    dbg("Forwarder", "%u, %u\n", call SendQueue.size(), call QEntryPool.size());
    return SUCCESS;
  }

  command error_t StdControl.start() {
    running = TRUE;
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    running = FALSE;
    return SUCCESS;
  }

  /* sendTask is where the first phase of all send logic
   * exists (the second phase is in SubSend.sendDone()). */
    bool isGetNodeDelayEtxsTasksDone = TRUE;
    error_t postGetNodeDelayEtxsTasksResult;
    task void sendTask();
    inline void postSendTask() {
#if !(defined(CTP) || defined(MCMP) || defined(MMSPEED))
        if (!isGetNodeDelayEtxsTasksDone)
            return;
#endif
        //call RoutingTable.postGetNodeDelayEtxsTasks();
        if (SUCCESS == post sendTask())
        	post_timestamp = call LocalTimeMilli.get();
    }
  
  /* ForwardingEngine keeps track of whether the underlying
     radio is powered on. If not, it enqueues packets;
     when it turns on, it then starts sending packets. */ 
  event void RadioControl.startDone(error_t err) {
    if (err == SUCCESS) {
      radioOn = TRUE;
      if (!call SendQueue.empty()) {
        postSendTask();
      }
    }
  }
 
  /* 
   * If the ForwardingEngine has stopped sending packets because
   * these has been no route, then as soon as one is found, start
   * sending packets.
   */ 
  event void UnicastNameFreeRouting.routeFound() {
    postSendTask();
  }

  event void UnicastNameFreeRouting.noRoute() {
    // Depend on the sendTask to take care of this case;
    // if there is no route the component will just resume
    // operation on the routeFound event
  }
  
  event void RadioControl.stopDone(error_t err) {
    if (err == SUCCESS) {
      radioOn = FALSE;
    }
  }

  ctp_data_header_t* getHeader(message_t* m) {
    return (ctp_data_header_t*)call SubPacket.getPayload(m, sizeof(ctp_data_header_t));
  }

error_t forward(message_t* ONE m, uint8_t clientId, uint32_t abs_deadline_, uint32_t origin_gen_timestamp_, uint32_t arrival_timestamp, uint32_t last_hop_tx_timestamp); 
  /*
   * The send call from a client. Return EBUSY if the client is busy
   * (clientPtrs is NULL), otherwise configure its queue entry
   * and put it in the send queue. If the ForwardingEngine is not
   * already sending packets (the RetxmitTimer isn't running), post
   * sendTask. It could be that the engine is running and sendTask
   * has already been posted, but the post-once semantics make this
   * not matter.
   */
command error_t Send.send[uint8_t client](message_t* msg, uint8_t len, uint32_t relative_deadline, uint16_t e2e_pdr_req) {
    ctp_data_header_t* hdr;
#if !(defined(MCMP) || defined(MMSPEED))
    fe_queue_entry_t *qe;
    //uint32_t start_time;
#endif
    uint32_t abs_deadline;	

    uint32_t local_time = call LocalTimeMilli.get();
    last_timestamp = local_time;
    
    dbg("Forwarder", "%s: sending packet from client %hhu: %x, len %hhu\n", __FUNCTION__, client, msg, len);
    if (!running) {return EOFF;}
    if (len > call Send.maxPayloadLength[client]()) {return ESIZE;}

    call Packet.setPayloadLength(msg, len);
    hdr = getHeader(msg);
    hdr->origin = TOS_NODE_ID;
    hdr->originSeqNo = seqno++;

    hdr->type = call CollectionId.fetch[client]();
    hdr->thl = 0;
    abs_deadline = ((MAX_UINT32 - relative_deadline) > local_time) ? (local_time + relative_deadline) : MAX_UINT32;
#if !(defined(MCMP) || defined(MMSPEED))
    //XL
    hdr->localNtwSeq = local_ntw_seq++;
    //call UartLog.logTxRx(DBG_FLAG, DBG_TIMER_FLAG, sending, clientPtrs[client] == NULL, hdr->originSeqNo, 1, send_cnts, sendDone_cnts, 0);

    qe = clientPtrs[client];
    qe->msg = msg;
    qe->client = client;
    qe->retries = MAX_RETRIES;
    
    //XL
    qe->sender = call AMPacket.address();
    //qe->sender_seq = 0xFFFF;
    qe->sender_ntw_seq = 0xFFFF;
    qe->origin_gen_timestamp = local_time;
    dbg("Forwarder", "pkt %u generated @ %u\n", hdr->originSeqNo, local_time);
    //avoid overflow
    qe->abs_deadline = abs_deadline;
    qe->arrival_timestamp = local_time;
    dbg("Forwarder", "%s: queue entry for %hhu is %hhu deep\n", __FUNCTION__, client, call SendQueue.size());
#if defined(EDF)
    if (call SendQueue.enqueue(qe, qe->abs_deadline) == SUCCESS) {
#else
    if (call SendQueue.enqueue(qe) == SUCCESS) {
#endif
		uint8_t retries = 0;
		if (p_fqe != NULL && is_retx)
			retries = MAX_RETRIES - p_fqe->retries;
        call UartLog.logTxRx(DBG_FLAG, DBG_QUEUE_SIZE_FLAG, 0, 0, retries, is_retx, hdr->origin, hdr->originSeqNo, call SendQueue.size() + is_retx);
		last_timestamp = call LocalTimeMilli.get();
		//tx_timestamp = last_timestamp;
        dbg_clear("Forwarder", "3\t%u\n", call SendQueue.size() + is_retx);
    	if (radioOn && !call RetxmitTimer.isRunning()) {
        	postSendTask();
    	}
    	return SUCCESS;
    } else {
      	dbg("overflow", "%s: send failed as packet could not be enqueued.\n", __FUNCTION__);     
		// send a debug message to the uart
		call CollectionDebug.logEvent(NET_C_FE_SEND_QUEUE_FULL);
		call UartLog.logEntry(SW_FULL_FLAG, hdr->origin, hdr->originSeqNo, 0);
		// Return the pool entry, as it's not for me...
		return FAIL;
    }
#else	//MCMP
	hdr->e2e_pdr_req = e2e_pdr_req;
	//no copy accepted; timestamps are not all used, so fill in any
	if (forward(msg, client, abs_deadline, local_time, local_time, local_time) != SUCCESS) {
		dbg("Forwarder", "%s: send failed\n", __FUNCTION__);
		return FAIL;
	} else {
		return SUCCESS;
	}
#endif	//MCMP
}

  command error_t Send.cancel[uint8_t client](message_t* msg) {
    // cancel not implemented. will require being able
    // to pull entries out of the queue.
    return FAIL;
  }

  command uint8_t Send.maxPayloadLength[uint8_t client]() {
    return call Packet.maxPayloadLength();
  }

  command void* Send.getPayload[uint8_t client](message_t* msg, uint8_t len) {
    return call Packet.getPayload(msg, len);
  }

  /*
   * These is where all of the send logic is. When the ForwardingEngine
   * wants to send a packet, it posts this task. The send logic is
   * independent of whether it is a forwarded packet or a packet from
   * a send client. 
   *
   * The task first checks that there is a packet to send and that
   * there is a valid route. It then marshals the relevant arguments
   * and prepares the packet for sending. If the node is a collection
   * root, it signals Receive with the loopback message. Otherwise,
   * it sets the packet to be acknowledged and sends it. It does not
   * remove the packet from the send queue: while sending, the 
   * packet being sent is at the head of the queue; a packet is dequeued
   * in the sendDone handler, either due to retransmission failure
   * or to a successful send.
   */
#ifdef TOSSIM
    am_addr_t topology[10] = {0, 27, 42, 44, 59, 86, 113, 128, 154, 168}; //{0, 6, 12, 24};    //{15, 27, 6, 64, 79, 76};    //{0, 6, 12, 19, 24} TOSSIM
#else
    am_addr_t topology[] = {15, 11, 65, 62, 76};    //{15, 27, 6, 64, 79, 76};    //{0, 6, 12, 19, 24} TOSSIM
#endif
    bool inNetwork() {
        uint8_t i;
        for (i = 0; i < (sizeof(topology) / sizeof(topology[0])); i++)
            if (TOS_NODE_ID == topology[i])
                return TRUE;
        return FALSE;
    }
    
    am_addr_t getParent() {
        uint8_t i;
        for (i = 0; i < (sizeof(topology) / sizeof(topology[0])); i++)
            if (TOS_NODE_ID == topology[i]) {
                if (i > 0)
                    return topology[i - 1];
                else
                    return (INVALID_ADDR - 1);
            }
        return (INVALID_ADDR - 1);
    }

event void RoutingTable.getNodeDelayEtxsTasksDone() {
    isGetNodeDelayEtxsTasksDone = TRUE;
    sendDone_cnts++;
    postSendTask();
}

task void sendTask() {
#if !defined(CTP)
	bool all_parent_congested = FALSE;
	bool all_parent_highly_congested = FALSE;
	//relative deadline
	uint32_t rltv_dd;
#endif
    uint32_t start_time;
    ctp_data_header_t *hdr;
    
	dbg("Forwarder", "%s: Trying to send a packet. Queue size is %hhu.\n", __FUNCTION__, call SendQueue.size());
    //call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 1, call LocalTimeMilli.get() - post_timestamp);
    if (sending) {
		dbg("Forwarder", "%s: busy, don't send\n", __FUNCTION__);
		call CollectionDebug.logEvent(NET_C_FE_SEND_BUSY);
		return;
	//XL: queue can be empty but there is one packet pending retx already dequeued
    //} else if (call SendQueue.empty()) {
    } else if (!is_retx && call SendQueue.empty()) {
		dbg("Forwarder", "%s: queue empty, don't send\n", __FUNCTION__);
		call CollectionDebug.logEvent(NET_C_FE_SENDQUEUE_EMPTY);
		return;
#if defined(CTP)
    } else if (!call RootControl.isRoot() && !call UnicastNameFreeRouting.hasRoute()) {
      	dbg("Forwarder", "%s: no route, don't send, start retry timer\n", __FUNCTION__);
		//call UartLog.logEntry(DBG_FLAG, DBG_CONGEST_FLAG, 0, 0);
		call RetxmitTimer.startOneShot(10000);
		// send a debug message to the uart
		call CollectionDebug.logEvent(NET_C_FE_NO_ROUTE);		
		return;
#endif
    } else {
		error_t subsendResult;
		//XL
		//fe_queue_entry_t* qe = call SendQueue.head();
		fe_queue_entry_t* qe;
		uint8_t payloadLen;
#if defined(CTP)
		am_addr_t dest = call UnicastNameFreeRouting.nextHop();
#endif
		uint16_t gradient;
		//first time being tx
		if (!is_retx) {
			//dequeue
			qe = call SendQueue.dequeue();
			//remember which packet in queue
			p_fqe = qe;
			dbg("Forwarder", "%s: p_fqe changed to %hu\n", __FUNCTION__, getHeader(p_fqe->msg)->originSeqNo);
			is_retx = TRUE;
			//if MTA's variant
    #if !(defined(CTP) || defined(MCMP) || defined(MMSPEED))
			last_timestamp = call LocalTimeMilli.get();
		
    		tx_timestamp = call LocalTimeMilli.get();
			isGetNodeDelayEtxsTasksDone = FALSE;
			send_cnts++;
			postGetNodeDelayEtxsTasksResult = call RoutingTable.postGetNodeDelayEtxsTasks(FALSE, getHeader(p_fqe->msg)->origin, getHeader(p_fqe->msg)->originSeqNo);
			return;
    #endif
		} else {
			qe = p_fqe;
		}
		payloadLen = call SubPacket.payloadLength(qe->msg);
		hdr = getHeader(qe->msg);
	#if defined(CTP)
		if (call CtpInfo.isNeighborCongested(dest)) {
			//call UartLog.logEntry(DBG_FLAG, DBG_CONGEST_FLAG, 0, 1);
			// Our parent is congested. We should wait.
			// Don't repost the task, CongestionTimer will do the job
			if (! parentCongested ) {
				parentCongested = TRUE;
				call CollectionDebug.logEvent(NET_C_FE_CONGESTION_BEGIN);
			}
			if (! call CongestionTimer.isRunning()) {
				startCongestionTimer(CONGESTED_WAIT_WINDOW, CONGESTED_WAIT_OFFSET);
			} 
			dbg("Forwarder", "%s: sendTask deferring for congested parent\n", __FUNCTION__);
			//call CollectionDebug.logEvent(NET_C_FE_CONGESTION_SENDWAIT);
			return;
		} 
		if (parentCongested) {
			parentCongested = FALSE;
			call CollectionDebug.logEvent(NET_C_FE_CONGESTION_END);
		}
/*
	// Once we are here, we have decided to send the packet.
	if (call SentCache.lookup(qe->msg)) {
		call CollectionDebug.logEvent(NET_C_FE_DUPLICATE_CACHE_AT_SEND);
		call SendQueue.dequeue();
		if (call MessagePool.put(qe->msg) != SUCCESS)
			call CollectionDebug.logEvent(NET_C_FE_PUT_MSGPOOL_ERR);
		if (call QEntryPool.put(qe) != SUCCESS)
			call CollectionDebug.logEvent(NET_C_FE_PUT_QEPOOL_ERR);
		postSendTask();
		return;
	}
*/
      /* If our current parent is not the same as the last parent
         we sent do, then reset the count of unacked packets: don't
         penalize a new parent for the failures of a prior one.*/
        if (dest != lastParent) {
            qe->retries = MAX_RETRIES;
            lastParent = dest;
        }
    #endif	//CTP
    /* 
          dbg("Forwarder", "Sending queue entry %p\n", qe);
          if (call RootControl.isRoot()) {
            collection_id_t collectid = getHeader(qe->msg)->type;
            memcpy(loopbackMsgPtr, qe->msg, sizeof(message_t));
            ackPending = FALSE;
        
            dbg("Forwarder", "%s: I'm a root, so loopback and signal receive.\n", __FUNCTION__);
            loopbackMsgPtr = signal Receive.receive[collectid](loopbackMsgPtr,
                                   call Packet.getPayload(loopbackMsgPtr, call Packet.payloadLength(loopbackMsgPtr)), 
                                   call Packet.payloadLength(loopbackMsgPtr));
            signal SubSend.sendDone(qe->msg, SUCCESS);
            return;
          }
    */      
        // Loop-detection functionality:
        if (call CtpInfo.getEtx(&gradient) != SUCCESS) {
            // If we have no metric, set our gradient conservatively so
            // that other nodes don't automatically drop our packets.
            gradient = 0;
        }
        call CtpPacket.setEtx(qe->msg, gradient);
    
        ackPending = (call PacketAcknowledgements.requestAck(qe->msg) == SUCCESS);
    
        // Set or clear the congestion bit on *outgoing* packets.
        if (call CtpCongestion.isCongested())
            call CtpPacket.setOption(qe->msg, CTP_OPT_ECN);
        else
            call CtpPacket.clearOption(qe->msg, CTP_OPT_ECN);
    
        //XL
        if (call CtpCongestion.isHighlyCongested())
            call CtpPacket.setOption(qe->msg, CTP_OPT_HCN);
        else
            call CtpPacket.clearOption(qe->msg, CTP_OPT_HCN);
        
        hdr->localSeq = local_seq++;
        //time sender first starts to tx a packet; in its local time
        if (MAX_RETRIES == qe->retries) {
        	//TODO
        	//call RoutingTable.logDAG();
        #ifdef DIRECT_E2E_SAMPLE
            //root piggybacks fast-changing inbound link delay
            if (call RootControl.isRoot())
                qe->retries = 1;
        #endif
			//call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 3, call LocalTimeMilli.get() - last_timestamp);
			//tx_timestamp = call LocalTimeMilli.get();
            hdr->gen_tx_interval = tx_timestamp - qe->origin_gen_timestamp;
            hdr->tx_timestamp = tx_timestamp;
            dbg("Forwarder", "pkt %u transmitted @ %u\n", hdr->originSeqNo, tx_timestamp);
            hdr->arrival_tx_interval = tx_timestamp - qe->arrival_timestamp;

		start_time = call LocalTimeMilli.get();
	#ifdef CTP
		    qe->rt_parent = dest;
	#else
	 	#ifdef ML
	 		rltv_dd = MAX_UINT32;
	 	#else
			rltv_dd = (qe->abs_deadline > tx_timestamp) ? (qe->abs_deadline - tx_timestamp) : 0;
		#endif
			hdr->tx_deadline_interval = rltv_dd;
		#if !(defined(MCMP) || defined(MMSPEED))	//do not overwrite: parent already computed for MCMP; last statement necessary bcoz deadline is needed
			qe->rt_parent = call RoutingTable.getNodeDelayEtxs(FALSE, &hdr->node_delay_mean, hdr->node_delay_etxs, &all_parent_congested, &all_parent_highly_congested, rltv_dd);
			#ifdef LINE_TOPOLOGY
				qe->rt_parent = call Utils.getParent();
				my_node_delay_mean = hdr->node_delay_etxs[0].node_delay_mean;
				my_node_delay_var = hdr->node_delay_etxs[0].node_delay_var;
			#endif
		#endif	//MCMP
			//backpressure: a node is congested if all its parents are congested regardless of its own queueing
		    if (all_parent_congested)
		        call CtpPacket.setOption(qe->msg, CTP_OPT_ECN);
		    if (all_parent_highly_congested)
		        call CtpPacket.setOption(qe->msg, CTP_OPT_HCN);
			
			//for MCMP, rltv_dd of 0 also causes expiration since hdr->tx_deadline_interval should be negative but actually 0
			if (0 == rltv_dd || INVALID_ADDR == qe->rt_parent) {
				if (0 == rltv_dd) {
					//expire
				    call UartLog.logEntry(EXPIRE_FLAG, hdr->origin, hdr->originSeqNo, 0);
				    dbg("Forwarder", "%s: <%u, %u> expires.\n", __FUNCTION__, hdr->origin, hdr->originSeqNo);
				} else {
					//reject
				    call UartLog.logEntry(REJECT_FLAG, hdr->origin, hdr->originSeqNo, 0);
				    dbg("Forwarder", "%s: <%u, %u> is rejected.\n", __FUNCTION__, hdr->origin, hdr->originSeqNo);
				}
		        dequeue(qe, SUCCESS);
		        is_retx = FALSE;
		        postSendTask();
		        return;
		    }
	#endif	//CTP
        //call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 0, call LocalTimeMilli.get() - start_time);
        } // MAX_RETRIES
    start_time = call LocalTimeMilli.get();
	#if !defined(CTP)
        //piggyback inbound mac delays
        call RoutingTable.getMacDelays(hdr->mac_delays, sizeof(hdr->mac_delays) / sizeof(hdr->mac_delays[0]));
	#endif
	//call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 1, call LocalTimeMilli.get() - start_time);
    
#if defined(TOSSIM)
        subsendResult = call SubSend.send(qe->rt_parent, qe->msg, payloadLen);
#else
        subsendResult = call SubSend.send(qe->rt_parent, qe->msg, payloadLen, tx_timestamp);
        //subsendResult = call SubSend.send(getParent(), qe->msg, payloadLen, tx_timestamp);
#endif
        if (subsendResult == SUCCESS) {
            // Successfully submitted to the data-link layer.
            sending = TRUE;
            dbg("Forwarder", "%s: subsend <%u, %u> to %hu succeeded.\n", __FUNCTION__, hdr->origin, hdr->originSeqNo, qe->rt_parent);
            if (qe->client < CLIENT_COUNT) {
                dbg("Forwarder", "%s: client packet.\n", __FUNCTION__);
            } else {
                dbg("Forwarder", "%s: forwarded packet.\n", __FUNCTION__);
            }
            return;
        } else if (subsendResult == EOFF) {
            // The radio has been turned off underneath us. Assume that
            // this is for the best. When the radio is turned back on, we'll
            // handle a startDone event and resume sending.
            radioOn = FALSE;
            dbg("Forwarder", "%s: subsend failed from EOFF.\n", __FUNCTION__);
            // send a debug message to the uart
            call CollectionDebug.logEvent(NET_C_FE_SUBSEND_OFF);
        } else if (subsendResult == EBUSY) {
            // This shouldn't happen, as we sit on top of a client and
            // control our own output; it means we're trying to
            // double-send (bug). This means we expect a sendDone, so just
            // wait for that: when the sendDone comes in, // we'll try
            // sending this packet again.	
            dbg("Forwarder", "%s: subsend failed from EBUSY.\n", __FUNCTION__);
            // send a debug message to the uart
            //XL: append to CTP
            postSendTask();
            call CollectionDebug.logEvent(NET_C_FE_SUBSEND_BUSY);
        } else if (subsendResult == ESIZE) {
            dbg("Forwarder", "%s: subsend failed from ESIZE: truncate packet.\n", __FUNCTION__);
            call Packet.setPayloadLength(qe->msg, call Packet.maxPayloadLength());
            postSendTask();
            call CollectionDebug.logEvent(NET_C_FE_SUBSEND_SIZE);
        }
    }
}

  void sendDoneBug(uint8_t bug_idx) {
    // send a debug message to the uart
    call CollectionDebug.logEvent(NET_C_FE_BAD_SENDDONE);
    call UartLog.logEntry(DBG_FLAG, DBG_SENDDONE_BUG_FLAG, bug_idx, 0);
  }

  /*
   * The second phase of a send operation; based on whether the transmission was
   * successful, the ForwardingEngine either stops sending or starts the
   * RetxmitTimer with an interval based on what has occured. If the send was
   * successful or the maximum number of retransmissions has been reached, then
   * the ForwardingEngine dequeues the current packet. If the packet is from a
   * client it signals Send.sendDone(); if it is a forwarded packet it returns
   * the packet and queue entry to their respective pools.
   * 
   */

event void SubSend.sendDone(message_t* msg, error_t error) {
	//fe_queue_entry_t *qe = call SendQueue.head();
	fe_queue_entry_t *qe = p_fqe;
    //XL
    ctp_data_header_t *hdr = getHeader(qe->msg);
    if (error == SUCCESS) {
        dbg_clear("tx_cost", "9 %u %u %u %u\n", TOS_NODE_ID, hdr->origin, hdr->originSeqNo, call AMPacket.destination(msg));
	#ifdef LINE_TOPOLOGY        
        call UartLog.logTxRx(TX_FLAG, hdr->origin, hdr->originSeqNo, call SendQueue.size(), 0, my_node_delay_var >> 16, my_node_delay_var & 0xFFFF, my_node_delay_mean, call AMPacket.destination(msg));  
	#else
        call UartLog.logTxRx(TX_FLAG, hdr->origin, hdr->originSeqNo, call SendQueue.size(), qe->sender_ntw_seq, hdr->localSeq, hdr->localNtwSeq, call PacketAcknowledgements.wasAcked(msg), call AMPacket.destination(msg));
	#endif
    }
    dbg("Forwarder", "%s to %hu and %hhu\n", __FUNCTION__, call AMPacket.destination(msg), error);
    if (qe == NULL || qe->msg != msg) {
		dbg("Forwarder", "%s: BUG: not our packet (%p != %p)!\n", __FUNCTION__, msg, qe->msg);
		sendDoneBug(0);      // Not our packet, something is very wrong...
		call UartLog.logTxRx(DBG_FLAG, DBG_SENDDONE_BUG_FLAG, qe == NULL, qe->msg != msg, 0, 0, 0, 0, 1);
		return;
    } else if (error != SUCCESS) {
		// Immediate retransmission is the worst thing to do.
		dbg("Forwarder", "%s: send failed\n", __FUNCTION__);
		call CollectionDebug.logEventMsg(NET_C_FE_SENDDONE_FAIL, call CollectionPacket.getSequenceNumber(msg), call CollectionPacket.getOrigin(msg), call AMPacket.destination(msg));
		startRetxmitTimer(SENDDONE_FAIL_WINDOW, SENDDONE_FAIL_OFFSET);
    } else if (ackPending && !call PacketAcknowledgements.wasAcked(msg)) {
		// AckPending is for case when DL cannot support acks.
		call LinkEstimator.txNoAck(call AMPacket.destination(msg));
		call CtpInfo.recomputeRoutes();
		if (--qe->retries) { 
			dbg("Forwarder", "%s: not acked\n", __FUNCTION__);
			call CollectionDebug.logEventMsg(NET_C_FE_SENDDONE_WAITACK, call CollectionPacket.getSequenceNumber(msg), call CollectionPacket.getOrigin(msg), call AMPacket.destination(msg));
			startRetxmitTimer(SENDDONE_NOACK_WINDOW, SENDDONE_NOACK_OFFSET);
		} else {
			//max retries, dropping packets
			dequeue(qe, FAIL);
			//call SendQueue.dequeue();
			is_retx = FALSE;
			estPktTime();
			//sending = FALSE;
			startRetxmitTimer(SENDDONE_OK_WINDOW, SENDDONE_OK_OFFSET);
			//
			if (!call RootControl.isRoot())
				dbg("Forwarder", "%s: our packet for client gets lost in the air\n", __FUNCTION__);
			call UartLog.logEntry(DBG_FLAG, DBG_LOSS_IN_AIR_FLAG, hdr->origin, hdr->originSeqNo);
		}
    } else if (qe->client < CLIENT_COUNT) {
		//ctp_data_header_t* hdr;
		uint8_t client = qe->client;
		dbg("Forwarder", "%s: our packet for client %hhu, remove %p from queue\n", __FUNCTION__, client, qe);
		call CollectionDebug.logEventMsg(NET_C_FE_SENT_MSG, call CollectionPacket.getSequenceNumber(msg), call CollectionPacket.getOrigin(msg), call AMPacket.destination(msg));
		call LinkEstimator.txAck(call AMPacket.destination(msg));
#if defined(MCMP) || defined(MMSPEED)
		//local pkts share pool w/ forwarded ones
		if (call MessagePool.put(qe->msg) != SUCCESS)
			call CollectionDebug.logEvent(NET_C_FE_PUT_MSGPOOL_ERR);
		if (call QEntryPool.put(qe) != SUCCESS)
			call CollectionDebug.logEvent(NET_C_FE_PUT_QEPOOL_ERR);
#endif
		clientPtrs[client] = qe;
		//hdr = getHeader(qe->msg);
		//call SendQueue.dequeue();
		//call UartLog.logTxRx(DBG_FLAG, DBG_PKT_TIME_FLAG, 1, 0, 0, call AMPacket.destination(msg), hdr->origin, hdr->originSeqNo, call LocalTimeMilli.get() - tx_timestamp);
		is_retx = FALSE;
		estPktTime();
		signal Send.sendDone[client](msg, SUCCESS);
		//sending = FALSE;
		startRetxmitTimer(SENDDONE_OK_WINDOW, SENDDONE_OK_OFFSET);
    } else if (call MessagePool.size() < call MessagePool.maxSize()) {
		// A successfully forwarded packet.
		dbg("Forwarder,Route", "%s: successfully forwarded packet (client: %hhu), message pool is %hhu/%hhu.\n", __FUNCTION__, qe->client, call MessagePool.size(), call MessagePool.maxSize());
		call CollectionDebug.logEventMsg(NET_C_FE_FWD_MSG, call CollectionPacket.getSequenceNumber(msg), call CollectionPacket.getOrigin(msg), call AMPacket.destination(msg));
		call LinkEstimator.txAck(call AMPacket.destination(msg));
		call SentCache.insert(qe->msg);
		//call SendQueue.dequeue();
		//call UartLog.logTxRx(DBG_FLAG, DBG_PKT_TIME_FLAG, 0, 0, 0, call AMPacket.destination(msg), hdr->origin, hdr->originSeqNo, call LocalTimeMilli.get() - tx_timestamp);
		is_retx = FALSE;
		estPktTime();
		if (call MessagePool.put(qe->msg) != SUCCESS)
			call CollectionDebug.logEvent(NET_C_FE_PUT_MSGPOOL_ERR);
		if (call QEntryPool.put(qe) != SUCCESS)
			call CollectionDebug.logEvent(NET_C_FE_PUT_QEPOOL_ERR);
		//sending = FALSE;
		startRetxmitTimer(SENDDONE_OK_WINDOW, SENDDONE_OK_OFFSET);
    } else {
		dbg("Forwarder", "%s: BUG: we have a pool entry, but the pool is full, client is %hhu.\n", __FUNCTION__, qe->client);
		sendDoneBug(1);    // It's a forwarded packet, but there's no room the pool;
		// someone has double-stored a pointer somewhere and we have nowhere
		// to put this, so we have to leak it...
    }
}

  /*
   * Function for preparing a packet for forwarding. Performs
   * a buffer swap from the message pool. If there are no free
   * message in the pool, it returns the passed message and does not
   * put it on the send queue.
   */
error_t forward(message_t* ONE m, uint8_t clientId, uint32_t abs_deadline_, uint32_t origin_gen_timestamp_, uint32_t arrival_timestamp, uint32_t last_hop_tx_timestamp) {
    //XL
    error_t ret = FAIL;
    
    uint32_t enqueue_time;
#if defined(MCMP) || defined(MMSPEED)
	uint8_t i, parent_cnt;
	//message_t *ret_msg = NULL;
	am_addr_t parents[NEIGHBOR_TABLE_SIZE];
	uint16_t parent_e2e_pdr_reqs[NEIGHBOR_TABLE_SIZE];
	uint32_t relative_deadline;
#endif

    ctp_data_header_t *hdr = getHeader(m);
#if defined(MCMP) || defined(MMSPEED)
	uint32_t start_time = call LocalTimeMilli.get();
	if (abs_deadline_ > start_time) {
		relative_deadline =  abs_deadline_ - start_time;
	} else {
		call UartLog.logEntry(EXPIRE_FLAG, hdr->origin, hdr->originSeqNo, 1);
		return ret;
	}
	parent_cnt = call RoutingTable.getParents(relative_deadline, hdr->e2e_pdr_req, parents, parent_e2e_pdr_reqs);
	dbg("ForwarderDbg", "%s: %u parents: %hu\n", __FUNCTION__, parent_cnt, parents[0]);
	if (0 == parent_cnt) {
		dbg("Forwarder", "%s: no parent\n", __FUNCTION__);
		//reject bcoz of speed not reliability
	    call UartLog.logEntry(REJECT_FLAG, hdr->origin, hdr->originSeqNo, 1);
	}
for (i = 0; i < parent_cnt; i++) {
#endif    
    //call UartLog.logTxRx(DBG_FLAG, DBG_CONGEST_FLAG, call SendQueue.size(), postGetNodeDelayEtxsTasksResult, send_cnts, sendDone_cnts, local_seq, hdr->origin, hdr->originSeqNo);
    if (call MessagePool.empty()) {
		dbg("overflow", "%s %u, cannot forward (%u, %u), message pool empty w/ queue size %u.\n", __FUNCTION__, local_seq, hdr->origin, hdr->originSeqNo, call SendQueue.size());
		// send a debug message to the uart
		call CollectionDebug.logEvent(NET_C_FE_MSG_POOL_EMPTY);
		call UartLog.logTxRx(SW_FULL_FLAG, hdr->origin, hdr->originSeqNo, call SendQueue.size(), call MessagePool.size(), call QEntryPool.size(), 0, 0, 1);
    } else if (call QEntryPool.empty()) {
		dbg("overflow", "%s cannot forward, queue entry pool empty.\n", __FUNCTION__);
		// send a debug message to the uart
		call CollectionDebug.logEvent(NET_C_FE_QENTRY_POOL_EMPTY);
		call UartLog.logEntry(SW_FULL_FLAG, hdr->origin, hdr->originSeqNo, 2);
    } else {
		message_t* newMsg;
		fe_queue_entry_t *qe;
		uint16_t gradient;

		qe = call QEntryPool.get();
		if (qe == NULL) {
			call CollectionDebug.logEvent(NET_C_FE_GET_MSGPOOL_ERR);
			return ret;
		}

		newMsg = call MessagePool.get();
		if (newMsg == NULL) {
			call CollectionDebug.logEvent(NET_C_FE_GET_QEPOOL_ERR);
			return ret;
		}
		
		//XL
	#if defined(MCMP) || defined(MMSPEED)
		qe->rt_parent = parents[i];
		hdr->localNtwSeq = local_ntw_seq++;
		//load e2e_pdr_req for next hop
		hdr->e2e_pdr_req = parent_e2e_pdr_reqs[i];
	#endif
		
		qe->client = clientId;
/*		//no buffer swap, just copy the entire message		
		memset(newMsg, 0, sizeof(message_t));
		memset(m->metadata, 0, sizeof(message_metadata_t));
		qe->msg = m;
*/
		memcpy(newMsg, m, sizeof(message_t));
		memset(newMsg->metadata, 0, sizeof(message_metadata_t));

		qe->msg = newMsg;
		qe->retries = MAX_RETRIES;

		//hdr = getHeader(qe->msg);
		qe->sender = call AMPacket.source(qe->msg);
		//qe->sender_seq = hdr->localSeq;
		qe->sender_ntw_seq = hdr->localNtwSeq;
		qe->abs_deadline = abs_deadline_;
		qe->origin_gen_timestamp = origin_gen_timestamp_;
        qe->arrival_timestamp = arrival_timestamp;
    	//if load hdr here, won't work if the original message_t *m is copied instead of swapped (e.g., source in MCMP)
		//hdr->localNtwSeq = local_ntw_seq++;
    
	    //start_time = call LocalTimeMilli.get();
	#if defined(EDF)
		if (call SendQueue.enqueue(qe, qe->abs_deadline) == SUCCESS) {
	#else
		if (call SendQueue.enqueue(qe) == SUCCESS) {
	#endif
	        uint8_t retries = 0;
			if (p_fqe != NULL && is_retx)
				retries = MAX_RETRIES - p_fqe->retries;
		    call UartLog.logTxRx(DBG_FLAG, DBG_QUEUE_SIZE_FLAG, 1, 0, retries, is_retx, hdr->origin, hdr->originSeqNo, call SendQueue.size() + is_retx);
		    // Loop-detection code:
		    if (call CtpInfo.getEtx(&gradient) == SUCCESS) {
				// We only check for loops if we know our own metric
				if (call CtpPacket.getEtx(m) <= gradient) {
					// If our etx metric is less than or equal to the etx value
					// on the packet (etx of the previous hop node), then we believe
					// we are in a loop.
					// Trigger a route update and backoff.
					call CtpInfo.triggerImmediateRouteUpdate();
					startRetxmitTimer(LOOPY_WINDOW, LOOPY_OFFSET);
					call CollectionDebug.logEventMsg(NET_C_FE_LOOP_DETECTED, call CollectionPacket.getSequenceNumber(m), call CollectionPacket.getOrigin(m), call AMPacket.destination(m));
		      	}
		    }
			enqueue_time = call LocalTimeMilli.get();
		#if !(defined(CTP) || defined(ML) || defined(LD) || defined(ML_DAG) || defined(DIRECT_E2E_SAMPLE) || defined(MCMP) || defined(MMSPEED))
			//only for protocols using packet time, instead of link delay
			//packet time is sampled here, not receive event, to account for processing from receive event to here
			if (enqueue_time > last_hop_tx_timestamp) {
				uint32_t mac_delay_sample = enqueue_time - last_hop_tx_timestamp;
				uint32_t link_delay_sample = enqueue_time + hdr->arrival_tx_interval - last_hop_tx_timestamp;
				dbg("Forwarder", "%s: pkt %u mac delay %u\n", __FUNCTION__, hdr->originSeqNo, mac_delay_sample);
				//feed sample (in ms) into corresponding neighbor entry
				call RoutingTable.sampleMacDelay(call AMPacket.source(m), FALSE, hdr->localNtwSeq, mac_delay_sample, link_delay_sample);
			}
		#endif
			//call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 2, call LocalTimeMilli.get() - last_timestamp);

		    if (!call RetxmitTimer.isRunning()) {
				// sendTask is only immediately posted if we don't detect a
				// loop.
				postSendTask();
		    }
		    //successful if any one copy enqueued
		    ret = SUCCESS;
      	} else {
		    call UartLog.logEntry(SW_FULL_FLAG, hdr->origin, hdr->originSeqNo, 3);
		    dbg("overflow", "%s There was a problem enqueuing to the send queue.\n", __FUNCTION__);
		    // There was a problem enqueuing to the send queue.
		    if (call MessagePool.put(newMsg) != SUCCESS)
		      	call CollectionDebug.logEvent(NET_C_FE_PUT_MSGPOOL_ERR);
		    if (call QEntryPool.put(qe) != SUCCESS)
          		call CollectionDebug.logEvent(NET_C_FE_PUT_QEPOOL_ERR);
      	}
    }

    // NB: at this point, we have a resource acquistion problem.
    // Log the event, and drop the
    // packet on the floor.
    call CollectionDebug.logEvent(NET_C_FE_SEND_QUEUE_FULL);
#if defined(MCMP) || defined(MMSPEED)
}
#endif
    return ret;
}
 
  /*
   * Received a message to forward. Check whether it is a duplicate by
   * checking the packets currently in the queue as well as the 
   * send history cache (in case we recently forwarded this packet).
   * The cache is important as nodes immediately forward packets
   * but wait a period before retransmitting after an ack failure.
   * If this node is a root, signal receive.
   */ 
event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    collection_id_t collectid;
    bool duplicate = FALSE;
    fe_queue_entry_t* qe;
    uint8_t i, thl;

    //XL
    uint32_t start_time;
    uint32_t rx_timestamp;
    uint32_t local_tx_timestamp;
    uint32_t local_origin_gen_timestamp = 0;
    uint32_t local_abs_deadline = MAX_UINT32;
    ctp_data_header_t *hdr = getHeader(msg);
    am_addr_t from = call AMPacket.source(msg);

    start_time = call LocalTimeMilli.get();
#if !defined(CTP)
    //update outbound mac delays
    call RoutingTable.setMacDelays(from, hdr->mac_delays, sizeof(hdr->mac_delays) / sizeof(hdr->mac_delays[0]));
    call RoutingTable.setNodeDelayEtxs(from, hdr->node_delay_mean, hdr->node_delay_etxs);
#endif
    //call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 2, call LocalTimeMilli.get() - start_time);
	//dbg_clear("tx_cost", "10 %u %u %u %u\n", TOS_NODE_ID, hdr->origin, hdr->originSeqNo, from);
	dbg("Forwarder", "%s: receiving <%hu, %hu> from %hu 11\n", __FUNCTION__, hdr->origin, hdr->originSeqNo, from);
    
    collectid = call CtpPacket.getType(msg);

    // Update the THL here, since it has lived another hop, and so
    // that the root sees the correct THL.
    thl = call CtpPacket.getThl(msg);
    thl++;
    call CtpPacket.setThl(msg, thl);

    //call UartLog.logTxRx(RX_FLAG, hdr->origin, hdr->originSeqNo, hdr->localSeq, hdr->localNtwSeq, thl - 1, collectid, 0, from);
    call CollectionDebug.logEventMsg(NET_C_FE_RCV_MSG, call CollectionPacket.getSequenceNumber(msg), 
					 					call CollectionPacket.getOrigin(msg), thl - 1);
    if (len > call SubSend.maxPayloadLength()) {
      	return msg;
    }

    //See if we remember having seen this packet
    //We look in the sent cache ...
    if (call SentCache.lookup(msg)) {
        call CollectionDebug.logEvent(NET_C_FE_DUPLICATE_CACHE);
        return msg;
    }
	dbg("Forwarder", "%s: receiving <%hu, %hu> from %hu 121\n", __FUNCTION__, hdr->origin, hdr->originSeqNo, from);

    //... and in the queue for duplicates
   // if (call SendQueue.size() > 0) {
    	//XL: bug fix
      	//for (i = call SendQueue.size(); --i;) {
      	for (i = call SendQueue.size(); i > 0; i--) {
			qe = call SendQueue.element(i - 1);
			if (call CtpPacket.matchInstance(qe->msg, msg)) {
			  	duplicate = TRUE;
			  	break;
			}
      	}
    //}
    
    if (duplicate) {
        call CollectionDebug.logEvent(NET_C_FE_DUPLICATE_QUEUE);
        return msg;
    }
dbg("Forwarder", "%s: receiving <%hu, %hu> from %hu 122\n", __FUNCTION__, hdr->origin, hdr->originSeqNo, from);
 
    //XL: if the a retx packet arrives when the previously received copy is being tranmitted, it's neither in the queue nor the cache since it's dequeued; thus need to check the current transmitting packet also
    if (p_fqe != NULL)
    	if (call CtpPacket.matchInstance(p_fqe->msg, msg)) {
    		//ctp_data_header_t *phdr = getHeader(p_fqe->msg);
    		//dbg("Forwarder", "%s: receiving <%hu, %hu>  %hu %p %p 123\n", __FUNCTION__, hdr->origin, hdr->originSeqNo, phdr->originSeqNo, p_fqe->msg, msg);
    		return msg;
    	}
dbg("Forwarder", "%s: receiving <%hu, %hu> from %hu 12\n", __FUNCTION__, hdr->origin, hdr->originSeqNo, from);
    //first time arrival, sample MAC delay
    rx_timestamp = call LocalTimeMilli.get();
	last_timestamp = rx_timestamp;
    //get converted local tx time
#if !defined(TOSSIM)
    //valid samples only
    if (call TimeSyncPacket.isValid(msg)) {
#endif
#if defined(TOSSIM)
        local_tx_timestamp = hdr->tx_timestamp;
#else
        //convert tx timestamp into local time
        local_tx_timestamp = call TimeSyncPacket.eventTime(msg);
#endif
    start_time = call LocalTimeMilli.get();
#if !defined(CTP)
	#if !(defined(ML) || defined(LD) || defined(ML_DAG) || defined(DIRECT_E2E_SAMPLE) || defined(MCMP) || defined(MMSPEED))
	//to sample last hop delay bcoz root does not forward
	if (call RootControl.isRoot())
	#endif
        if (rx_timestamp > local_tx_timestamp) {
            //uint32_t lasthop_arrival_timestamp = local_tx_timestamp - hdr->arrival_tx_interval;
            //uint32_t mac_delay_sample = rx_timestamp - lasthop_arrival_timestamp;
            uint32_t mac_delay_sample = rx_timestamp - local_tx_timestamp;
            uint32_t link_delay_sample = rx_timestamp + hdr->arrival_tx_interval - local_tx_timestamp;
            dbg("Forwarder", "%s: pkt %u mac delay %u\n", __FUNCTION__, hdr->originSeqNo, mac_delay_sample);
            dbg("Forwarder", "pkt %u received @ %u\n", hdr->originSeqNo, rx_timestamp);
            //feed sample (in ms) into corresponding neighbor entry
            call RoutingTable.sampleMacDelay(from, FALSE, hdr->localNtwSeq, mac_delay_sample, link_delay_sample);
        }
#endif
    //call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 3, call LocalTimeMilli.get() - start_time);
#if !defined(TOSSIM)
    } else {
    	//timing invalid; try backup timing based on skew
    	local_tx_timestamp = call RoutingTable.nb2LocalTime(from, hdr->tx_timestamp);
		//have to drop if even backup fails
    	if (MAX_UINT32 == local_tx_timestamp) {
    		//call UartLog.logEntry(DBG_FLAG, DBG_ASYNC_FLAG, hdr->origin, hdr->originSeqNo);
    		return msg;
    	}
    }
    //call UartLog.logTxRx(DBG_FLAG, DBG_ASYNC_FLAG, hdr->originSeqNo, call TimeSyncPacket.isValid(msg), 0, 0, local_tx_timestamp >> 16, local_tx_timestamp, rx_timestamp);
#endif
    //convert other timing into local time
    local_origin_gen_timestamp = local_tx_timestamp - hdr->gen_tx_interval;
    local_abs_deadline = ((MAX_UINT32 - hdr->tx_deadline_interval) > local_tx_timestamp) ? (local_tx_timestamp + hdr->tx_deadline_interval) : MAX_UINT32;
            
    // If I'm the root, signal receive. 
    if (call RootControl.isRoot()) {
        message_t *m = signal Receive.receive[collectid](msg, call Packet.getPayload(msg, call Packet.payloadLength(msg)), call Packet.payloadLength(msg), call LocalTimeMilli.get() + hdr->gen_tx_interval - local_tx_timestamp);
        dbg("Forwarder", "pkt %u app received @ %u\n", hdr->originSeqNo, call LocalTimeMilli.get());
    #ifdef DIRECT_E2E_SAMPLE
        //root does send to piggyback bcoz link delay changes fast
        //TODO: assume upper layer dose not change msg (i.e., m == msg)
        forward(m, 255, local_abs_deadline, local_origin_gen_timestamp, rx_timestamp, local_tx_timestamp);
    #endif
		//root does NOT send to piggyback bcoz MAC delay changes slow
        return m;
    //I'm on the routing path and Intercept indicates that I
    //should not forward the packet.
    } else if (!signal Intercept.forward[collectid](msg, call Packet.getPayload(msg, call Packet.payloadLength(msg)), call Packet.payloadLength(msg), call LocalTimeMilli.get() + hdr->gen_tx_interval - local_tx_timestamp))
    	return msg;
    else {
      	dbg("Route", "Forwarding packet from %hu.\n", getHeader(msg)->origin);
      	dbg("Forwarder", "%s: receiving <%hu, %hu> from %hu 13\n", __FUNCTION__, hdr->origin, hdr->originSeqNo, from);
      	forward(msg, 255, local_abs_deadline, local_origin_gen_timestamp, rx_timestamp, local_tx_timestamp);
      	return msg;
    }
}

event message_t* SubSnoop.receive(message_t* msg, void *payload, uint8_t len) {
    //am_addr_t parent = call UnicastNameFreeRouting.nextHop();
    am_addr_t from = call AMPacket.source(msg);
#if !defined(CTP)
    //XL
    uint32_t start_time;
    uint32_t rx_timestamp;
    uint32_t local_tx_timestamp;
    ctp_data_header_t *hdr = getHeader(msg);
#ifdef LINE_TOPOLOGY
    if (call AMPacket.source(msg) != call Utils.getParent())
        return msg;
#endif
    //update outbound mac delays
    start_time = call LocalTimeMilli.get();
    call RoutingTable.setMacDelays(from, hdr->mac_delays, sizeof(hdr->mac_delays) / sizeof(hdr->mac_delays[0]));
    call RoutingTable.setNodeDelayEtxs(from, hdr->node_delay_mean, hdr->node_delay_etxs);
    //call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 2, call LocalTimeMilli.get() - start_time);
    start_time = call LocalTimeMilli.get();
    //first time arrival, sample MAC delay only; abs_deadline and origin_gen_timestamp is not of interest
#if !defined(TOSSIM)
    //valid samples only
    if (call TimeSyncPacket.isValid(msg)) {
#endif
        rx_timestamp = call LocalTimeMilli.get();
    #if defined(TOSSIM)
        local_tx_timestamp = hdr->tx_timestamp;
    #else
        //convert tx timestamp into local time
        local_tx_timestamp = call TimeSyncPacket.eventTime(msg);
    #endif
        if (rx_timestamp > local_tx_timestamp) {
            uint32_t mac_delay_sample = rx_timestamp - local_tx_timestamp;
            uint32_t link_delay_sample = rx_timestamp + hdr->arrival_tx_interval - local_tx_timestamp;
            dbg("Forwarder", "%s: mac delay sample %u for pkt %u\n", __FUNCTION__, mac_delay_sample, hdr->localNtwSeq);
            //feed sample (in ms) into corresponding neighbor entry
            call RoutingTable.sampleMacDelay(from, FALSE, hdr->localNtwSeq, mac_delay_sample, link_delay_sample);
        }
#if !defined(TOSSIM)
    }   //what if deadline invalid? just ignore the sample
#endif
    //call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 3, call LocalTimeMilli.get() - start_time);
#endif //CTP    
    // Check for the pull bit (P) [TEP123] and act accordingly.  This
    // check is made for all packets, not just ones addressed to us.
    if (call CtpPacket.option(msg, CTP_OPT_PULL)) {
      	call CtpInfo.triggerRouteUpdate();
    }
	//call UartLog.logEntry(DBG_FLAG, DBG_SNOOP_FLAG, from, call CtpPacket.option(msg, CTP_OPT_ECN));
    call CtpInfo.setNeighborCongested(from, call CtpPacket.option(msg, CTP_OPT_ECN), call CtpPacket.option(msg, CTP_OPT_HCN));
    return signal Snoop.receive[call CtpPacket.getType(msg)] (msg, payload + sizeof(ctp_data_header_t), 
       len - sizeof(ctp_data_header_t));
  }
  
  event void RetxmitTimer.fired() {
    sending = FALSE;
    postSendTask();
  }

  event void CongestionTimer.fired() {
    //parentCongested = FALSE;
    //call CollectionDebug.logEventSimple(NET_C_FE_CONGESTION_END, 0);
    postSendTask();
  }
  

  command bool CtpCongestion.isCongested() {
    // A simple predicate for now to determine congestion state of
    // this node.
    bool congested = (call SendQueue.size() > congestionThreshold) ? 
      TRUE : FALSE;
    return ((congested || clientCongested)?TRUE:FALSE);
  }
  
  command bool CtpCongestion.isHighlyCongested() {
    // A simple predicate for now to determine congestion state of
    // this node.
    bool congested = (call SendQueue.size() > highlyCongestionThreshold) ? 
      TRUE : FALSE;
    return ((congested || clientCongested)?TRUE:FALSE);
  }

  command void CtpCongestion.setClientCongested(bool congested) {
    bool wasCongested = call CtpCongestion.isCongested();
    clientCongested = congested;
    if (!wasCongested && congested) {
      call CtpInfo.triggerImmediateRouteUpdate();
    } else if (wasCongested && ! (call CtpCongestion.isCongested())) {
      call CtpInfo.triggerRouteUpdate();
    }
  }

  command void Packet.clear(message_t* msg) {
    call SubPacket.clear(msg);
  }
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return call SubPacket.payloadLength(msg) - sizeof(ctp_data_header_t);
  }

  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    call SubPacket.setPayloadLength(msg, len + sizeof(ctp_data_header_t));
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - sizeof(ctp_data_header_t);
  }

  command void* Packet.getPayload(message_t* msg, uint8_t len) {
    uint8_t* payload = call SubPacket.getPayload(msg, len + sizeof(ctp_data_header_t));
    if (payload != NULL) {
      payload += sizeof(ctp_data_header_t);
    }
    return payload;
  }

  command am_addr_t       CollectionPacket.getOrigin(message_t* msg) {return getHeader(msg)->origin;}

  command collection_id_t CollectionPacket.getType(message_t* msg) {return getHeader(msg)->type;}
  command uint8_t         CollectionPacket.getSequenceNumber(message_t* msg) {return getHeader(msg)->originSeqNo;}
  command void CollectionPacket.setOrigin(message_t* msg, am_addr_t addr) {getHeader(msg)->origin = addr;}
  command void CollectionPacket.setType(message_t* msg, collection_id_t id) {getHeader(msg)->type = id;}
  command void CollectionPacket.setSequenceNumber(message_t* msg, uint8_t _seqno) {getHeader(msg)->originSeqNo = _seqno;}

  
  //command ctp_options_t CtpPacket.getOptions(message_t* msg) {return getHeader(msg)->options;}

  command uint8_t       CtpPacket.getType(message_t* msg) {return getHeader(msg)->type;}
  command am_addr_t     CtpPacket.getOrigin(message_t* msg) {return getHeader(msg)->origin;}
  command uint16_t      CtpPacket.getEtx(message_t* msg) {return getHeader(msg)->etx;}
    //XL
  //command uint8_t       CtpPacket.getSequenceNumber(message_t* msg) {return getHeader(msg)->originSeqNo;}
  command uint16_t       CtpPacket.getSequenceNumber(message_t* msg) {return getHeader(msg)->originSeqNo;}
  command uint8_t       CtpPacket.getThl(message_t* msg) {return getHeader(msg)->thl;}
  
  command void CtpPacket.setThl(message_t* msg, uint8_t thl) {getHeader(msg)->thl = thl;}
  command void CtpPacket.setOrigin(message_t* msg, am_addr_t addr) {getHeader(msg)->origin = addr;}
  command void CtpPacket.setType(message_t* msg, uint8_t id) {getHeader(msg)->type = id;}

  command bool CtpPacket.option(message_t* msg, ctp_options_t opt) {
    return ((getHeader(msg)->options & opt) == opt) ? TRUE : FALSE;
  }

  command void CtpPacket.setOption(message_t* msg, ctp_options_t opt) {
    getHeader(msg)->options |= opt;
  }

  command void CtpPacket.clearOption(message_t* msg, ctp_options_t opt) {
    getHeader(msg)->options &= ~opt;
  }

  command void CtpPacket.setEtx(message_t* msg, uint16_t e) {getHeader(msg)->etx = e;}
  command void CtpPacket.setSequenceNumber(message_t* msg, uint16_t _seqno) {getHeader(msg)->originSeqNo = _seqno;}

  // A CTP packet ID is based on the origin and the THL field, to
  // implement duplicate suppression as described in TEP 123.

  command bool CtpPacket.matchInstance(message_t* m1, message_t* m2) {
    return (call CtpPacket.getOrigin(m1) == call CtpPacket.getOrigin(m2) &&
	    call CtpPacket.getSequenceNumber(m1) == call CtpPacket.getSequenceNumber(m2) &&
	    call CtpPacket.getThl(m1) == call CtpPacket.getThl(m2) &&
	    call CtpPacket.getType(m1) == call CtpPacket.getType(m2));
  }

  command bool CtpPacket.matchPacket(message_t* m1, message_t* m2) {
    return (call CtpPacket.getOrigin(m1) == call CtpPacket.getOrigin(m2) &&
	    call CtpPacket.getSequenceNumber(m1) == call CtpPacket.getSequenceNumber(m2) &&
	    call CtpPacket.getType(m1) == call CtpPacket.getType(m2));
  }

  default event void
  Send.sendDone[uint8_t client](message_t *msg, error_t error) {
  }

  default event bool
  Intercept.forward[collection_id_t collectid](message_t* msg, void* payload, 
                                               uint8_t len, uint32_t elapse_time) {
    call UartLog.logTxRx(DBG_DEFAULT_HANDLER_FLAG, getHeader(msg)->origin, getHeader(msg)->originSeqNo, collectid, 0, 0, 0, 0, elapse_time);
    return TRUE;
  }

  default event message_t * Receive.receive[collection_id_t collectid](message_t *msg, void *payload, uint8_t len, uint32_t elapse_time) {
  	call UartLog.logTxRx(DBG_DEFAULT_HANDLER_FLAG, getHeader(msg)->origin, getHeader(msg)->originSeqNo, collectid, 0, 0, 1, 1, elapse_time);
    return msg;
  }

  default event message_t *
  Snoop.receive[collection_id_t collectid](message_t *msg, void *payload,
                                           uint8_t len) {
    return msg;
  }

  default command collection_id_t CollectionId.fetch[uint8_t client]() {
    return 0;
  }
    //[window, window + offset], e.g., (15, 16)
    //mask is window
  static void startRetxmitTimer(uint16_t mask, uint16_t offset) {
    uint16_t r = call Random.rand16();
    r &= mask;
    r += offset;
    //TODO
    r = 0;
    call RetxmitTimer.startOneShot(r);
    dbg("Forwarder", "Rexmit timer will fire in %hu ms\n", r);
  }

  static void startCongestionTimer(uint16_t mask, uint16_t offset) {
    uint16_t r = call Random.rand16();
    r &= mask;
    r += offset;
    call CongestionTimer.startOneShot(r);
    dbg("Forwarder", "Congestion timer will fire in %hu ms\n", r);
  }

  /* signalled when this neighbor is evicted from the neighbor table */
  event void LinkEstimator.evicted(am_addr_t neighbor) {
  }


  /* Default implementations for CollectionDebug calls.
   * These allow CollectionDebug not to be wired to anything if debugging
   * is not desired. */

    default command error_t CollectionDebug.logEvent(uint8_t type) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventSimple(uint8_t type, uint16_t arg) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventMsg(uint8_t type, uint16_t msg, am_addr_t origin, am_addr_t node) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventRoute(uint8_t type, am_addr_t parent, uint8_t hopcount, uint16_t metric) {
        return SUCCESS;
    }
    
#include "CtpForwardingEngineP_.nc"
}

/* Rodrigo. This is an alternative
  event void CtpInfo.ParentCongested(bool congested) {
    if (congested) {
      // We've overheard our parent's ECN bit set.
      startCongestionTimer(CONGESTED_WAIT_WINDOW, CONGESTED_WAIT_OFFSET);
      parentCongested = TRUE;
      call CollectionDebug.logEvent(NET_C_FE_CONGESTION_BEGIN);
    } else {
      // We've overheard our parent's ECN bit cleared.
      call CongestionTimer.stop();
      parentCongested = FALSE;
      call CollectionDebug.logEventSimple(NET_C_FE_CONGESTION_END, 1);
      postSendTask();
    }
  }
*/

