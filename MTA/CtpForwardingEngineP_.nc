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

/*
 * Interface RoutingTable
 */
command uint8_t DataPanel.queueSize() {
	//plus the pkt being transmitted but dequeued
    return (call SendQueue.size());
}
