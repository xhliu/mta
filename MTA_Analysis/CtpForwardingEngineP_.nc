//TODO: replace dequeue in task void sendDone() w/ this function as well besides expiration and rejection
static void dequeue(fe_queue_entry_t *qe, error_t err) {
    //max retries, dropping packet
    if (qe->client < CLIENT_COUNT) {
        clientPtrs[qe->client] = qe;
        signal Send.sendDone[qe->client](qe->msg, FAIL);
#if defined(MCMP) || defined(MMSPEED)
		//in multipath, pool is shared by both generated and forwarded packets
        if (call MessagePool.put(qe->msg) != SUCCESS)
            call CollectionDebug.logEvent(NET_C_FE_PUT_MSGPOOL_ERR);
        if (call QEntryPool.put(qe) != SUCCESS)
            call CollectionDebug.logEvent(NET_C_FE_PUT_QEPOOL_ERR);
#endif
    } else {
    	//treat expired and rejected packets as sent packets for duplicate detection
    	if (SUCCESS == err)
    		call SentCache.insert(qe->msg);
        if (call MessagePool.put(qe->msg) != SUCCESS)
            call CollectionDebug.logEvent(NET_C_FE_PUT_MSGPOOL_ERR);
        if (call QEntryPool.put(qe) != SUCCESS)
            call CollectionDebug.logEvent(NET_C_FE_PUT_QEPOOL_ERR);
    }
    //call SendQueue.dequeue();
}

//estimate pkt time
static void estPktTime() {
	uint32_t tmp, delay_mean, delay_var;
	uint32_t delay_sample = call LocalTimeMilli.get() - tx_timestamp;
	
	//first time
	if (0 == tx_pkt_time_mean) {
		tx_pkt_time_mean = delay_sample;
		tx_pkt_time_var = 0;
		return;
	}
	
	delay_mean = tx_pkt_time_mean;
	delay_var = tx_pkt_time_var;
	
	tmp = (delay_sample > delay_mean) ? (delay_sample - delay_mean) : (delay_mean - delay_sample);
	tmp *= tmp;
	tmp = tmp >> BITSHIFT_3;
	tmp += delay_var;
	delay_var = tmp - (tmp >> BITSHIFT_3);
	delay_mean = delay_mean - (delay_mean >> BITSHIFT_3) + (delay_sample >> BITSHIFT_3);
	
	tx_pkt_time_mean = delay_mean;
	tx_pkt_time_var = delay_var;
}

/*
 * Interface DataPanel
 */
command uint8_t DataPanel.queueSize(uint8_t *pending) {
	//TODO: plus the pkt being transmitted but dequeued
	*pending = is_retx;
    return (call SendQueue.size() + is_retx);
}

//get sender-based pkt time mean & var
command void DataPanel.getTxPktTime(uint32_t *mean, uint32_t *var) {
	*mean = tx_pkt_time_mean;
	*var = tx_pkt_time_var;
}
