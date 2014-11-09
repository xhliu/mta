/*
 * 1) sample E2E delay under 2 conditions: new link delay or node delay arrives
 * 2) 
 		when selecting parent, exclude local queueing delay; used for RT satisfiability test bcoz parent is selected after packet reaches head of queue; nlq: no local queueing
 	  	when diffusion, include local queueing delay bcoz a pkt at me will experience local queueing at other nodes along the way
 * 3) DIRECT_SAMPLE does not differentiate MAC delay & link delay bcoz it only samples link delay as a whole
 * 4) outbound pkt time and link delay are both hybrid, beacon and data pkts
 */
static long isqrt(long num);
static uint32_t nthroot(uint32_t x, uint8_t n);
static uint32_t nodeDist(am_addr_t m, am_addr_t n);

/*
 * Interface RoutingTable
 */
//backup sync in case of pkt-level sync failure
//set neighbor's skew
command void RoutingTable.setNbTimeSkew(am_addr_t nb, int32_t skew) {
	uint8_t idx;
	routing_table_entry *ne;
	
	idx = routingTableFind(nb);
	if (idx == routingTableActive)
		return;
	ne = &routingTable[idx];
	ne->signed_skew = skew;
}

//convert neighbor time to local time
command uint32_t RoutingTable.nb2LocalTime(am_addr_t nb, uint32_t nb_local_time) {
	uint8_t idx;
	routing_table_entry *ne;
	
	idx = routingTableFind(nb);
	if (idx == routingTableActive)
		return MAX_UINT32;
	ne = &routingTable[idx];
	if (MAX_INT32 == ne->signed_skew)
		return MAX_UINT32;
	return (uint32_t)((int32_t)nb_local_time + ne->signed_skew);
}

/*
 * @param is_beacon: is data(inbound) or beacon(outbound) sample?
 * beacon is only used to jumpstart outbound delay, not sampled for inbound delay 
 * @param link_delay_sample: link delay including queueing and MAC delay
 * outlier detection: only absolute threshold
 * invalid samples, even very rare, do sneak in (e.g., bcoz of invalid timestamps)
 * and such sample can greatly increase mean and variance estiamtion and take a long time to subsidize
 * thus can cause e2e delays greatly overestimated and packets rejected falsely
 *
 * 
 */
//TODO: change mac_delay_sample to uint32_t
command error_t RoutingTable.sampleMacDelay(am_addr_t nb, bool is_beacon, uint16_t seqno, uint16_t mac_delay_sample, uint16_t link_delay_sample) {
    uint8_t i, idx;
#if !(defined(MAX) || defined(DIRECT_E2E_SAMPLE))
    uint32_t delay_mean, delay_var, tmp, delay_sample;
#endif
	routing_table_entry *ne;
	
	//absolute threshold
	if (mac_delay_sample > MAX_MAC_DELAY)
		return FAIL;
#if defined(ML) || defined(LD) || defined(ML_DAG) || defined(DIRECT_E2E_SAMPLE) || defined(MCMP) || defined(MMSPEED)
	//max link delay == max MAC delay * queue size
	if (link_delay_sample > (MAX_MAC_DELAY * QUEUE_SIZE))
		return FAIL;
#endif

	idx = routingTableFind(nb);
    if (idx == routingTableActive)
		//equivalent to the seq# already in cache; ignore it (seq#)
		return FAIL;
	ne = &routingTable[idx];
	if (!is_beacon && 18 == TOS_NODE_ID)
		dbg("TreeRouting", "%s: %u %u\n", __FUNCTION__, nb, link_delay_sample);
	//no duplicate check for beacon samples bcoz no retx
    if (!is_beacon) {
        //seen before
        for (i = 0; i < SEQNO_CACHE_SIZE; i++) {
            if (ne->seqno_cache[i] == seqno)
                return FAIL;
        }
        //new sample, overwrite the oldest
        ne->seqno_cache[ne->entry_idx] = seqno;
        ne->entry_idx = (ne->entry_idx + 1) % SEQNO_CACHE_SIZE;
    }

	//if (!is_beacon)
		//call UartLog.logTxRx(DBG_FLAG, DBG_LINK_DELAY_FLAG, 0, 0, 0, seqno, nb, mac_delay_sample, link_delay_sample);

//update link delay
#if defined(ML) || defined(LD) || defined(ML_DAG) || defined(MCMP) || defined(MMSPEED)
//TODO: optimize bcoz only MMSPEED-CD needs EWMV
	delay_sample = link_delay_sample;
	if (is_beacon) {
	    //first sample
	    if (MAX_UINT16 == ne->out_link_delay_mean) {
	        ne->out_link_delay_mean = delay_sample;
            ne->out_link_delay_var = 0;
            return SUCCESS;
        }
        delay_mean = ne->out_link_delay_mean;
        delay_var = ne->out_link_delay_var;
	} else {
	    //first sample
        if (MAX_UINT16 == ne->in_link_delay_mean) {
            ne->in_link_delay_mean = delay_sample;
            ne->in_link_delay_var = 0;
            return SUCCESS;
        }
        delay_mean = ne->in_link_delay_mean;
        delay_var = ne->in_link_delay_var;
	}
	//update link delay: EWMA & EWMV
	tmp = (delay_sample > delay_mean) ? (delay_sample - delay_mean) : (delay_mean - delay_sample);
	tmp *= tmp;
	tmp = tmp >> BITSHIFT_3;
	tmp += delay_var;
	delay_var = tmp - (tmp >> BITSHIFT_3);
	delay_mean = delay_mean - (delay_mean >> BITSHIFT_3) + (delay_sample >> BITSHIFT_3);

    if (is_beacon)	{
        ne->out_link_delay_mean = delay_mean;
        ne->out_link_delay_var = delay_var;
    } else {
        ne->in_link_delay_mean = delay_mean;
        ne->in_link_delay_var = delay_var;
    }
/*
	//just to jumpstart
    if (is_beacon) {
        tmp = ne->in_link_delay_mean;
	} else {
        tmp = ne->out_link_delay_mean;
	}
    //first sample
    if (MAX_UINT16 == tmp) {
        tmp = mac_delay_sample;
    } else {
        tmp = tmp - (tmp >> BITSHIFT_3) + (link_delay_sample >> BITSHIFT_3);
    }
    if (is_beacon) {
        ne->in_link_delay_mean = tmp;
	} else {
        ne->out_link_delay_mean = tmp;
	}
*/
	#if defined(ML) || defined(LD) || defined(MCMP) || defined(MMSPEED)
        //unnecessary to update MAC delay
        return SUCCESS;
	#endif
#elif defined(DIRECT_E2E_SAMPLE)
    //just to jumpstart
    if (is_beacon) {
	    //first sample only; otherwise can overwrite data-based outbound link delay
	    if (MAX_UINT16 == ne->out_link_delay_mean) {
	        ne->out_link_delay_mean = link_delay_sample;
	        //set 0 to be valid; otherwise RoutingTable.getNodeDelayEtxs discards the corresponding entry
	        //ne->out_mac_delay_var = 0;
        }
	} else {
	    //use latest sample
        ne->in_link_delay_mean = link_delay_sample;
	}
	//unnecessary to update MAC delay
	return SUCCESS;
#endif //ML

//update MAC delay
//TODO: #elif?
#if !(defined(DIRECT_E2E_SAMPLE) || defined(LD) || defined(ML) || defined(MCMP) || defined(MMSPEED))
#if defined(MAX)
	if (is_beacon) {
	    //first sample
	    if (MAX_UINT16 == ne->out_mac_delay_mean) {
	        ne->out_mac_delay_mean = mac_delay_sample;
	        //set 0 to be valid; otherwise RoutingTable.getNodeDelayEtxs discards the corresponding entry
	        ne->out_mac_delay_var = 0;
            return SUCCESS;
        }
        if (ne->out_mac_delay_mean < mac_delay_sample)
        	ne->out_mac_delay_mean = mac_delay_sample;
	} else {
	    //first sample
        if (MAX_UINT16 == ne->in_mac_delay_mean) {
            ne->in_mac_delay_mean = mac_delay_sample;
            ne->in_mac_delay_var = 0;
            return SUCCESS;
        }
        if (ne->in_mac_delay_mean < mac_delay_sample)
        	ne->in_mac_delay_mean = mac_delay_sample;
	}
	dbg("TreeRouting", "%s: MAX mac delay to/from %hu is <%u, %u> \n", __FUNCTION__, nb, ne->out_mac_delay_mean, ne->in_mac_delay_mean);
#else
	delay_sample = mac_delay_sample;
	if (is_beacon) {
	    //first sample
	    if (MAX_UINT16 == ne->out_mac_delay_mean) {
	        ne->out_mac_delay_mean = delay_sample;
            ne->out_mac_delay_var = 0;
            return SUCCESS;
        }
        delay_mean = ne->out_mac_delay_mean;
        delay_var = ne->out_mac_delay_var;
	} else {
	    //first sample
        if (MAX_UINT16 == ne->in_mac_delay_mean) {
            ne->in_mac_delay_mean = delay_sample;
            ne->in_mac_delay_var = 0;
            return SUCCESS;
        }
        delay_mean = ne->in_mac_delay_mean;
        delay_var = ne->in_mac_delay_var;
	}
	//update MAC delay: EWMA & EWMV
	tmp = (delay_sample > delay_mean) ? (delay_sample - delay_mean) : (delay_mean - delay_sample);
	tmp *= tmp;
	tmp = tmp >> BITSHIFT_3;
	tmp += delay_var;
	delay_var = tmp - (tmp >> BITSHIFT_3);
	delay_mean = delay_mean - (delay_mean >> BITSHIFT_3) + (delay_sample >> BITSHIFT_3);

    if (is_beacon)	{
        ne->out_mac_delay_mean = delay_mean;
        ne->out_mac_delay_var = delay_var;
    } else {
        ne->in_mac_delay_mean = delay_mean;
        ne->in_mac_delay_var = delay_var;
    }
	//call UartLog.logEntry(DBG_FLAG, DBG_ASYNC_FLAG, mac_delay_mean, mac_delay_var);
	if (0 == TOS_NODE_ID)
	//dbg("TreeRouting", "%s: beacon %hhu, sample # %u: %u, mac_delay_mean %d\n", __FUNCTION__, is_beacon, seqno, delay_sample, delay_mean);
	dbg_clear("TreeRouting", "1\t%u\n", delay_mean);
#endif  //MAX
#endif  //DIRECT_E2E_SAMPLE & ML & MCMP
	return SUCCESS;
}

//piggyback inbound Mac delays to sender
//round robin since MAC delays from all senders cannot be accommodated in one pkt
uint8_t prev_routing_table_idx = 0;
//mac_delays_size: # of entries in mac_delays
/*
 * in case there are fewer than mac_delays_size entries, put multiple copies of a entry, does not hurt
 */
command void RoutingTable.getMacDelays(mac_delay_t mac_delays[], uint8_t mac_delays_size) {
    uint8_t i;
    uint8_t idx = 0;
    routing_table_entry *ne;
    
    //special case; no neighobr in routing table initially
    if (0 == routingTableActive) {
        for (i = 0; i < mac_delays_size; i++) {
            mac_delays[i].nb = INVALID_ADDR;
        }
        return;
    }
    
    for (i = 0; i < mac_delays_size; i++) {
        idx = (i + prev_routing_table_idx) % routingTableActive;
        ne = &routingTable[idx];
        
        mac_delays[i].nb = ne->neighbor;
        mac_delays[i].in_mac_delay_mean = ne->in_mac_delay_mean;
        if (0 == TOS_NODE_ID && 0 == i)
        	dbg("TreeRouting", "neighbor %hu inbound delay %u\n", ne->neighbor, mac_delays[i].in_mac_delay_mean);
        mac_delays[i].in_mac_delay_var = ne->in_mac_delay_var;
    //#if defined(ML) || defined(ML_DAG) || defined(DIRECT_E2E_SAMPLE) || defined(MCMP) || defined(MMSPEED)
        mac_delays[i].in_link_delay_mean = ne->in_link_delay_mean;
        mac_delays[i].in_link_delay_var = ne->in_link_delay_var;
    //#endif
        dbg("TreeRouting", "%s mac delay <%hu, %hu, %hu>\n", __FUNCTION__, mac_delays[i].nb, 
            mac_delays[i].in_mac_delay_mean, mac_delays[i].in_link_delay_mean);
    }
    prev_routing_table_idx = idx;
}

//the packet contains outbound mac delay for me
command void RoutingTable.setMacDelays(am_addr_t nb, mac_delay_t mac_delays[], uint8_t mac_delays_size) {
    uint8_t i, idx;
    routing_table_entry *ne;
#if defined(ML) || defined(LD) || defined(ML_DAG) || defined(DIRECT_E2E_SAMPLE) || defined(MCMP) || defined(MMSPEED)
    uint32_t link_delay;
#endif
#if defined(DIRECT_E2E_SAMPLE)
    uint8_t j;
    uint32_t e2e_delay_sample;
    #if !defined(DS_P2)
    uint32_t e2e_delay_mean, e2e_delay_var, tmp;
    #endif
#endif    

    idx = routingTableFind(nb);
    //nb not in my routing table	
    if (idx == routingTableActive)
        return;
    
    ne =&routingTable[idx];
    //outbound MAC delay    
    for (i = 0; i < mac_delays_size; i++) {
        //for me
        if (my_ll_addr == mac_delays[i].nb) {
        	//dbg("TreeRouting", "%s <%u, %u>\n", __FUNCTION__, mac_delays[i].in_link_delay_mean, mac_delays[i].in_link_delay_var);
            //found and update outbound MAC and/or link delay
            //only valid MAC delay can update outbound; otherwise it will incorrectly overwrite initially beacon-based MAC delays
            if (mac_delays[i].in_mac_delay_mean != MAX_UINT16 && mac_delays[i].in_mac_delay_var != MAX_UINT16) {
                ne->out_mac_delay_mean = mac_delays[i].in_mac_delay_mean;
                ne->out_mac_delay_var = mac_delays[i].in_mac_delay_var;
            }
    #if defined(ML) || defined(LD) || defined(ML_DAG) || defined(DIRECT_E2E_SAMPLE) || defined(MCMP) || defined(MMSPEED)
            link_delay = mac_delays[i].in_link_delay_mean;
            //validate; mean and var both valid or invalid, only check mean
            if (MAX_UINT16 == link_delay)
                break;
            ne->out_link_delay_mean = link_delay;
            ne->out_link_delay_var = mac_delays[i].in_link_delay_var;
        #ifdef DIRECT_E2E_SAMPLE
            for (j = 0; j < DELAY_ETX_LEVEL_CNTS; j++) {
            #ifdef DS_P2
            	e2e_delay_qtl_t *re;
            #endif
                e2e_delay_sample = ne->latest_node_delay[j] + link_delay;
                //invalid sample
                if (e2e_delay_sample >= MAX_UINT16)
                    continue;
                
            #ifndef DS_P2
                //first sample
                if (MAX_UINT16 == ne->node_delay_etxs[j].node_delay_mean || MAX_UINT16 == ne->node_delay_etxs[j].node_delay_var) {
                    ne->node_delay_etxs[j].node_delay_mean = e2e_delay_sample;
                    ne->node_delay_etxs[j].node_delay_var = 0;
                    continue;
                }
                //update e2e delay: EWMA & EWMV
                e2e_delay_mean = ne->node_delay_etxs[j].node_delay_mean;
                e2e_delay_var = ne->node_delay_etxs[j].node_delay_var;
        
				tmp = (e2e_delay_sample > e2e_delay_mean) ? (e2e_delay_sample - e2e_delay_mean) : (e2e_delay_mean - e2e_delay_sample);
				tmp *= tmp;
				tmp = tmp >> BITSHIFT_3;
				tmp += e2e_delay_var;
				e2e_delay_var = tmp - (tmp >> BITSHIFT_3);
				e2e_delay_mean = e2e_delay_mean - (e2e_delay_mean >> BITSHIFT_3) + (e2e_delay_sample >> BITSHIFT_3);
                
                ne->node_delay_etxs[j].node_delay_mean = e2e_delay_mean;
                ne->node_delay_etxs[j].node_delay_var = e2e_delay_var;
           	#else
           		re = &ne->e2e_delay_qtls[j];
                dbg("TreeRouting", "%s: %d-th sample %u\n", __FUNCTION__, j, e2e_delay_sample);
           		call Utils.extP2(re->height, re->pos, re->dd_pos, re->dd_pos_unit, e2e_delay_sample, MARKER_COUNTS, &re->sample_cnts);
           	#endif
            }
        #endif  //DIRECT_E2E_SAMPLE
    #endif
            dbg("TreeRouting", "%s mac delay <%hu, %hu, %hu> from %hu\n", __FUNCTION__, mac_delays[i].nb, 
            mac_delays[i].in_mac_delay_mean, mac_delays[i].in_link_delay_mean, nb);
        }
    }
}

#if !defined(DIRECT_E2E_SAMPLE)
command error_t RoutingTable.setNodeDelayEtxs(am_addr_t nb, nx_uint16_t node_delay_mean, delay_etx_t node_delay_etxs[]) {
    uint8_t i, idx;
    
    idx = routingTableFind(nb);
    //nb not in my routing table
    if (idx == routingTableActive)
        return FAIL;
    
    //delay etx
    for (i = 0; i < DELAY_ETX_LEVEL_CNTS; i++) {
        routingTable[idx].node_delay_etxs[i] = node_delay_etxs[i];
    }
#if defined(ML) || defined(ML_DAG)
    routingTable[idx].node_delay_mean = node_delay_mean;
#endif
    return SUCCESS;
}
#else
//incoming packet's node_delay_etxs contains latest delay sample
//while routing table contains delay mean and var, latest_node_delay contains latest delay sample
command error_t RoutingTable.setNodeDelayEtxs(am_addr_t nb, nx_uint16_t node_delay_mean, delay_etx_t node_delay_etxs[]) {
    uint8_t i, idx;
    routing_table_entry *ne;
    //signed for numerical computation
#if !defined(DS_P2)
    uint32_t e2e_delay_mean, e2e_delay_var, tmp;
#endif
    uint32_t link_delay, e2e_delay_sample;
    
    idx = routingTableFind(nb);
    //nb not in my routing table
    if (idx == routingTableActive)
        return FAIL;
    
    ne = &routingTable[idx];
#if defined(ML) || defined(ML_DAG)
    ne->node_delay_mean = node_delay_mean;
#endif
    link_delay = ne->out_link_delay_mean;
    if (MAX_UINT16 == link_delay)
        return FAIL;
    
    for (i = 0; i < DELAY_ETX_LEVEL_CNTS; i++) {
    #ifdef DS_P2
    	e2e_delay_qtl_t *re;
    #endif
         //remember latest node delay and ETX; needed in diffusion
         //node_delay_mean contains latest delay for a path, not mean delay
        ne->latest_node_delay[i] = node_delay_etxs[i].node_delay_mean;
        ne->node_delay_etxs[i].node_delay_etx = node_delay_etxs[i].node_delay_etx;

        e2e_delay_sample = ne->latest_node_delay[i] + link_delay;
        //invalid sample
        if (e2e_delay_sample >= MAX_UINT16)
            continue;
	
	#ifndef DS_P2        
        //first sample
        if (MAX_UINT16 == ne->node_delay_etxs[i].node_delay_mean || MAX_UINT16 == ne->node_delay_etxs[i].node_delay_var) {
            ne->node_delay_etxs[i].node_delay_mean = e2e_delay_sample;
            ne->node_delay_etxs[i].node_delay_var = 0;
            continue;
        }
        //update e2e delay: EWMA & EWMV
        e2e_delay_mean = ne->node_delay_etxs[i].node_delay_mean;
        e2e_delay_var = ne->node_delay_etxs[i].node_delay_var;
/* 
        diff = (int32_t)e2e_delay_sample - e2e_delay_mean;
        incr = diff >> BITSHIFT_3;
        e2e_delay_mean += incr;
        signed_tmp = e2e_delay_var + diff * incr;
        e2e_delay_var = signed_tmp - (signed_tmp >> BITSHIFT_3);
 */     
        tmp = (e2e_delay_sample > e2e_delay_mean) ? (e2e_delay_sample - e2e_delay_mean) : (e2e_delay_mean - e2e_delay_sample);
        tmp *= tmp;
        tmp = tmp >> BITSHIFT_3;
        tmp += e2e_delay_var;
        e2e_delay_var = tmp - (tmp >> BITSHIFT_3);
        e2e_delay_mean = e2e_delay_mean - (e2e_delay_mean >> BITSHIFT_3) + (e2e_delay_sample >> BITSHIFT_3);
        
        ne->node_delay_etxs[i].node_delay_mean = e2e_delay_mean;
        ne->node_delay_etxs[i].node_delay_var = e2e_delay_var;        
   	#else
   		re = &ne->e2e_delay_qtls[i];
   		call Utils.extP2(re->height, re->pos, re->dd_pos, re->dd_pos_unit, e2e_delay_sample, MARKER_COUNTS, &re->sample_cnts);
   	#endif
    }
    return SUCCESS;
}
#endif // DIRECT_E2E_SAMPLE

/*
 * The following invariant must hold for the protocol to work
 * 1) call order: postGetNodeDelayEtxsTasks < getNodeDelayEtxsTasksDone < getNodeDelayEtxs
 * 2) every call is followed by one and only one following call
 *
 * compute my <delay etx> based on neighbors'
 * step (0): compute weighted node MAC delay, which is then used to compute link delay w/ queueing
 *          and determine congestion threshold
 * step (1): compute e2e <delay etx> through this neighbor, considering threshold

 * step (2): sort by delay quantile

 * step (3):
 			1) filter the entries so that path w/ higher delay qtl should have smaller ETX; i.e., for any delay_qtl_1 					< delay_qtl_2, etx_1 > etx_2 must hold, remove path of larger delay qtl and larger ETX
			2) select parent in the meantime, options:
 				<1> min ETX neighbor meeting deadline
 					1> MTA: satisfiability test w/ delay quantile
 					2> MTA_DAG_MD: w/ mean delay
 				<2> Min Delay Quantile
 					1> MDQ: no DAG
 					2> MDQ_DAG: w/ ETX DAG
 * step (4): aggregation
 * 
 * Divide all steps into tasklets bcoz otherwise encapsulating them into a single function whose execution
 * takes tens of ms, greatly inc tx cost due to ACK lateness among other potential issue
 */
//temporary storage of intermediate results
e2e_delay_etx_t e2eDelayEtxs[NEIGHBOR_TABLE_SIZE * DELAY_ETX_LEVEL_CNTS];
uint32_t min_e2e_delay_qtls[DELAY_ETX_LEVEL_CNTS];

//compute parent & distinguish beacon & data; clean unused variables
//compute my <delay etx> based on neighbors' and parent
//congestion is considered in both parent selection & diffusion
//return: the parent meeting the deadline and also having the smallest ETX
//the largest-qtl entry still meeting the deadline
uint8_t rej_cause_idx = 0;
uint16_t my_node_etx;
uint32_t shared_node_delay_mean, shared_node_delay_var;
//identify congestion threshold
bool any_not_congested = FALSE;
bool any_not_highly_congested = FALSE;
//debug rejection cause
bool any_pass_dag = FALSE;
bool any_pass_congest = FALSE;
bool any_pass_valid_delay = FALSE;

#if defined(ML) || defined(ML_DAG)
    bool any_smaller_node_delay = FALSE;
    bool any_smaller_node_etx = FALSE;
    uint32_t path_delay;
    uint32_t min_path_delay = MAX_UINT32;
    am_addr_t min_path_delay_parent = INVALID_ADDR;
#endif
//MCMP: for hop count
uint16_t min_hop_cnt;

//all the 5 steps should be serialized & atomic; otherwise interval states & final result can be erroneous 
bool task_locked = FALSE;
task void getNodeDelayEtxsSubTask0();
task void getNodeDelayEtxsSubTask1();
task void getNodeDelayEtxsSubTask2();

bool has_passed_signal = FALSE;
bool enter_from_beacon = FALSE;

bool is_router_called = FALSE;
bool is_forwarder_called = FALSE;
bool extra_signal_pending = FALSE;

am_addr_t src = 0;
uint16_t src_seqno = 0;

//this MUST be called before calling getNodeDelayEtxs()
//it essentially rank, but not filter, all e2e delay ETX entries
command error_t RoutingTable.postGetNodeDelayEtxsTasks(bool is_router_called_, am_addr_t src_, uint16_t src_seqno_) {
    if (is_router_called_) {
        is_router_called = TRUE;
    } else {
        is_forwarder_called = TRUE;
		//remember src and seqno; only for data
	   	src = src_;
	   	src_seqno = src_seqno_;
	}
		      	
    if (!task_locked) {
        task_locked = TRUE;
        extra_signal_pending = FALSE;
        has_passed_signal = FALSE;
        enter_from_beacon = is_router_called_;
        post getNodeDelayEtxsSubTask0();
        return SUCCESS;
    } else {
    	//TODO: does this really help to unstuck data panel? 
    	if (is_forwarder_called && enter_from_beacon && has_passed_signal)
    		extra_signal_pending = TRUE;
    	return FAIL;
    }
}

//step 0): weighted node MAC delay
task void getNodeDelayEtxsSubTask0() {
    uint8_t i;
    uint32_t start_time;
    routing_table_entry *ne;
    //weighted mac delay to each neighbor by their forwarding frequency
    uint32_t weighted_mac_delay_mean = 0;
    uint32_t weighted_mac_delay_var = 0;
    uint32_t total_pkts_sent = 0;
    uint8_t queue_size;
    uint16_t path_hop_cnt;

    //initialize global variables
    rej_cause_idx = 0;
    any_not_congested = FALSE;
    any_not_highly_congested = FALSE;
    any_pass_dag = FALSE;
    any_pass_congest = FALSE;
    any_pass_valid_delay = FALSE;
#if defined(ML) || defined(ML_DAG)
    min_path_delay = MAX_UINT32;
    min_path_delay_parent = INVALID_ADDR;
#endif
	min_hop_cnt = MAX_UINT16;
    
    //DAG
    my_node_etx = routeInfo.etx + call LinkEstimator.getLinkQuality(routeInfo.parent) + 10;
    //my_node_etx = routeInfo.etx + call RoutingTable.getNbLinkEtx(routeInfo.parent);
    
    start_time = call LocalTimeMilli.get();
    for (i = 0; i < routingTableActive; i++) {
        ne = &routingTable[i];
        
        path_hop_cnt = (uint16_t)ne->hop_cnt + 1;
        if (min_hop_cnt > path_hop_cnt)
        	min_hop_cnt = path_hop_cnt;
#ifndef MDQ
    #ifndef ML_DAG
        //smaller ETX; exclude parent to avoid temporary inconsistency
        if (ne->neighbor != routeInfo.parent)
        	if (ne->info.etx >= my_node_etx)
        		continue;
    #endif
#endif
    #if defined(ML) || defined(ML_DAG)
        //any_smaller_node_etx = TRUE;
        //min path delay thru each predecessor
        dbg("TreeRouting", "%u-th neighbor %u outbound delay %u %u\n", i, ne->neighbor, ne->out_link_delay_mean, ne->node_delay_mean);
        if (MAX_UINT16 == ne->node_delay_mean || MAX_UINT16 == ne->out_link_delay_mean)
            continue;
        //any_smaller_node_delay = TRUE;
        path_delay = (uint32_t)ne->node_delay_mean + ne->out_link_delay_mean;
        if (min_path_delay > path_delay) {
            min_path_delay = path_delay;
            min_path_delay_parent = ne->neighbor;
        }
    #endif
    #if !defined(DIRECT_E2E_SAMPLE) && !defined(ML)
        //TODO: valid mac delay entries only
        //if (MAX_UINT16 == ne->out_mac_delay_mean || MAX_UINT16 == ne->out_mac_delay_var)
            //continue;
    #endif

        //congestion threshold
        if (!ne->info.congested)
            any_not_congested = TRUE;
        if(!ne->info.highlyCongested)
            any_not_highly_congested = TRUE;

        total_pkts_sent += ne->pkt_sent_cnts;
        weighted_mac_delay_mean += ne->out_mac_delay_mean * ne->pkt_sent_cnts;
        weighted_mac_delay_var += ne->out_mac_delay_var * ne->pkt_sent_cnts;
    }
#ifdef ML
    //return min_path_delay_parent;
   	//just to skip computation in the following tasks
    rej_cause_idx = 4;
    post getNodeDelayEtxsSubTask1();
    return;
#endif
    //can happen when routing just starts and no neighbor detected
    if (0 == total_pkts_sent) {
        rej_cause_idx = 1;
        post getNodeDelayEtxsSubTask1();
        return;
    }
/*
    if (!any_not_highly_congested) {
        rej_cause_idx = 3;
        post getNodeDelayEtxsSubTask1();
        return;
    }
*/
    weighted_mac_delay_mean /= total_pkts_sent;
    weighted_mac_delay_var /= total_pkts_sent;
    queue_size = call DataPanel.queueSize();
    shared_node_delay_mean = queue_size * weighted_mac_delay_mean;
    shared_node_delay_var = queue_size * weighted_mac_delay_var;
    dbg("TreeRouting","%s: weighted_mac_delay_mean %u, weighted_mac_delay_var %u, queue size %u\n", 
        __FUNCTION__, weighted_mac_delay_mean, weighted_mac_delay_var, queue_size);
    post getNodeDelayEtxsSubTask1();
    //call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 10, call LocalTimeMilli.get() - start_time);
}

uint8_t valid_entry_cnts = 0;
//further decompose SubTask1
uint8_t task1_routing_table_idx = 0;
uint8_t TASK1_STEP_SIZE = 1;
//step 1): precompute e2e <delay etx> and store
task void getNodeDelayEtxsSubTask1() {
    uint8_t i, j;
    routing_table_entry *ne;
    uint32_t start_time;
#ifndef DIRECT_E2E_SAMPLE
    uint32_t link_delay_mean, link_delay_var;
#endif
    uint32_t link_etx;
    //include local queueing delay; used for diffusion
    uint32_t e2e_delay_mean, e2e_delay_var, e2e_delay_qtl, e2e_delay_etx;
    //exclude local queueing delay; used for RT satisfiability test bcoz parent is selected after packet reaches head of queue; nlq: no local queueing
    uint32_t nlq_e2e_delay_mean, nlq_e2e_delay_var, nlq_e2e_delay_qtl;
#if !(defined(NORMAL) || defined(EXP) || defined(MAX))
    uint32_t tmp;
#endif
    bool passCongestionThreshold;
    
    start_time = call LocalTimeMilli.get();

    if (0 == task1_routing_table_idx) {
        valid_entry_cnts = 0;
        //proceed only if step 0 succeeds
        if (rej_cause_idx != 0) {
            post getNodeDelayEtxsSubTask2();
            return;
        }
        //get a more recent copy
        my_node_etx = routeInfo.etx + call LinkEstimator.getLinkQuality(routeInfo.parent) + 10;
    } else if (task1_routing_table_idx >= routingTableActive) {
        task1_routing_table_idx = 0;
        //no valid entry found
        if (0 == valid_entry_cnts) {
            rej_cause_idx = 2;
            //goto END;
        }
        post getNodeDelayEtxsSubTask2();
        return;
    }
    
    //find valid entries: pass DAG & delay & congestion (in order) check to be valid
    for (i = task1_routing_table_idx; i < (task1_routing_table_idx + TASK1_STEP_SIZE) && i < routingTableActive; i++) {
        ne = &routingTable[i];
#ifndef MDQ
    #ifndef ML_DAG
        //smaller ETX; exclude parent to avoid temporary inconsistency
        if (ne->neighbor != routeInfo.parent)
        	if (ne->info.etx >= my_node_etx)
        		continue;
    #else
        if (MAX_UINT16 == ne->node_delay_mean || MAX_UINT16 == ne->out_link_delay_mean)
            continue;
        //smaller ML
        if (ne->node_delay_mean >= min_path_delay)
            continue;
        //any_smaller_node_delay = TRUE;
    #endif
#endif //MDQ
    	any_pass_dag = TRUE;
    #ifndef DIRECT_E2E_SAMPLE
        //TODO: valid mac delay entries only
        //if (MAX_UINT16 == ne->out_mac_delay_mean || MAX_UINT16 == ne->out_mac_delay_var)
            //continue;
        
        #ifdef LD
        	//use link delay directly w/o decomposition
        	link_delay_mean = ne->out_link_delay_mean;
        	link_delay_var = ne->out_link_delay_var;
        	if (24 == TOS_NODE_ID)
		 		dbg("TreeRoutingDbg", "neighbor %hu: link delay <%u, %u>\n", ne->neighbor, ne->out_link_delay_mean, ne->out_link_delay_var);
        #else
		    //queued pkts delay + imaginary pkt delay
		    link_delay_mean = shared_node_delay_mean + ne->out_mac_delay_mean;
		    link_delay_var = shared_node_delay_var + ne->out_mac_delay_var;
        #endif
    #endif
        //if there is any not congested, threshold is congested
        //else if there is any not highly congested, threshold is highly congested
        //else no threshold
        passCongestionThreshold = TRUE;
        if (any_not_congested) {
            passCongestionThreshold = !ne->info.congested;
        } else if (any_not_highly_congested)
            passCongestionThreshold = !ne->info.highlyCongested;
        
        if (!passCongestionThreshold)
            continue;
        any_pass_congest = TRUE;    

        //keep a redundant copy of link etx at routing table to save computation
        link_etx = call LinkEstimator.getLinkQuality(ne->neighbor) + 10;
        //link_etx = ne->link_etx;
        
        //each <delay etx> level
        for (j = 0; j < DELAY_ETX_LEVEL_CNTS; j++) {
        #ifdef DS_P2
        	e2e_delay_qtl_t *re = &ne->e2e_delay_qtls[j];
        #endif
            delay_etx_t *de = &ne->node_delay_etxs[j];
            //TODO: valid entries only
            if (j > 0 && (MAX_UINT16 == de->node_delay_mean || MAX_UINT16 == de->node_delay_var))
                //can break bcoz entries are increasingly ordered
                //continue;
                break;
           	any_pass_valid_delay = TRUE; 
        #if defined(DIRECT_E2E_SAMPLE)
        	//DIRECT_E2E_SAMPLE only measures link delay, cannot differentiate MAC and queueing delay
        	//thus the best it can do is regard as no queueing
            #ifndef DS_P2
		        e2e_delay_mean = de->node_delay_mean;   
		        e2e_delay_var =  de->node_delay_var;
		        nlq_e2e_delay_mean = de->node_delay_mean;   
		        nlq_e2e_delay_var =  de->node_delay_var;
            #else
            	//indirection: place quantile into mean and make var 0; later mean + ALPHA * delta is quantile
            	e2e_delay_mean = re->height[NUM_OF_QUANTILES / 2] >> HEIGHT_SCALAR_BITS;   
		        e2e_delay_var =  0;
		        nlq_e2e_delay_mean = e2e_delay_mean;   
		        nlq_e2e_delay_var =  0;
            #endif
        #else
            e2e_delay_mean = link_delay_mean + de->node_delay_mean;   
            e2e_delay_var = link_delay_var + de->node_delay_var;
            nlq_e2e_delay_mean = ne->out_mac_delay_mean + de->node_delay_mean;   
            nlq_e2e_delay_var = ne->out_mac_delay_var + de->node_delay_var;
        #endif

            //approximating or bounding quantile
        #if defined(MAX)
        	//e2e_delay_qtl is actually max e2e delay in this case
        	e2e_delay_qtl = e2e_delay_mean;
        	nlq_e2e_delay_qtl = nlq_e2e_delay_mean;
        	dbg("TreeRouting", "%s: neighbor %hu, link delay %hu, node delay %hu\n", __FUNCTION__, ne->neighbor, link_delay_mean, de->node_delay_mean);
        #elif defined(NORMAL)
	        //normal bound for 90% quantile: mean + std * 1.28
            e2e_delay_qtl = e2e_delay_mean + (isqrt(e2e_delay_var) << 7) / 100;
            nlq_e2e_delay_qtl = nlq_e2e_delay_mean + (isqrt(nlq_e2e_delay_var) << 7) / 100;
        #elif defined(EXP)
        	//normal bound for 90% quantile: mean * 2.3
        	e2e_delay_qtl = e2e_delay_mean * 23 / 10;
        	nlq_e2e_delay_qtl = nlq_e2e_delay_mean * 23 / 10;
        #else
            //Chebyshev bound for quantile: min{mean + std * sqrt(qtl / (1 - qtl)), mean / (1 - qtl)}
            tmp = e2e_delay_mean + isqrt(e2e_delay_var) * CHEBYSHEV_SCALAR;	//(VP) 18559 / 10000;
            //for diffusion
            e2e_delay_qtl = (tmp < (MARKOV_SCALAR * e2e_delay_mean)) ? tmp : (MARKOV_SCALAR * e2e_delay_mean);
		    #if defined(MTA_MEAN_DELAY)
		    	//use mean delay, not delay quantile for satisfiability test
		    	nlq_e2e_delay_qtl = nlq_e2e_delay_mean;
		    #else
		        tmp = nlq_e2e_delay_mean + isqrt(nlq_e2e_delay_var) * CHEBYSHEV_SCALAR;
		        //for parent selection
		        nlq_e2e_delay_qtl = (tmp < (MARKOV_SCALAR * nlq_e2e_delay_mean)) ? tmp : (MARKOV_SCALAR * nlq_e2e_delay_mean);
		    #endif
		#endif
		    //TODO: overflow
            e2e_delay_etx = link_etx + de->node_delay_etx;
            
            if (valid_entry_cnts < sizeof(e2eDelayEtxs) / sizeof(e2eDelayEtxs[0])) {
                e2eDelayEtxs[valid_entry_cnts].nb = ne->neighbor;
                //e2eDelayEtxs[valid_entry_cnts].congested = ne->info.congested;
            #if defined(DIRECT_E2E_DELAY)
                e2eDelayEtxs[valid_entry_cnts].e2e_delay_mean = (uint32_t)ne->latest_node_delay[j] + ne->out_link_delay_mean;
            #else
                e2eDelayEtxs[valid_entry_cnts].e2e_delay_mean = e2e_delay_mean;
            #endif
                e2eDelayEtxs[valid_entry_cnts].e2e_delay_var = e2e_delay_var;
                e2eDelayEtxs[valid_entry_cnts].e2e_delay_qtl = e2e_delay_qtl;
                e2eDelayEtxs[valid_entry_cnts].nlq_e2e_delay_qtl = nlq_e2e_delay_qtl;
                e2eDelayEtxs[valid_entry_cnts].e2e_delay_etx = e2e_delay_etx;
                //line topology
                if (0 == valid_entry_cnts) {
	                //call UartLog.logTxRx(DBG_FLAG, DBG_ESTIMATE_ERR_FLAG, 0, 0, src, src_seqno, e2e_delay_mean, e2e_delay_qtl, e2e_delay_var);
	                if (24 == TOS_NODE_ID)
		                //dbg("TreeRouting","%s: %hu pkt <%u, %u> path <%u, %u, %u>\n", __FUNCTION__, ne->neighbor, src, src_seqno, e2e_delay_mean, e2e_delay_var, e2e_delay_qtl);
		                dbg_clear("TreeRouting","1\t%u\n", e2e_delay_mean);
	            }
                valid_entry_cnts++;
            }
        }
    }
//REPOST:
    task1_routing_table_idx += TASK1_STEP_SIZE;
    post getNodeDelayEtxsSubTask1();
    //call UartLog.logTxRx(DBG_FLAG, DBG_EXEC_TIME_FLAG, 11, valid_entry_cnts, routingTableActive, task1_routing_table_idx, 0, 0, call LocalTimeMilli.get() - start_time);
}

uint8_t task2_sort_idx = 1;
uint8_t TASK2_STEP_SIZE = 1;
//e2eDelayEtxs[0.. valid_entry_cnts - 1] contains neighbors ordered by delay after all getNodeDelayEtxsSubTask2() done
task void getNodeDelayEtxsSubTask2() {
    int i, j;
    e2e_delay_etx_t value;
    uint32_t start_time;
    start_time = call LocalTimeMilli.get();
    
    if ((1 == task2_sort_idx && 0 != rej_cause_idx) || (task2_sort_idx >= valid_entry_cnts)) {
        task2_sort_idx = 1;
        //getNodeDelayEtxs() can be called now
        if (is_forwarder_called)
        	signal RoutingTable.getNodeDelayEtxsTasksDone();
        if (is_router_called)
            post sendBeaconTask();
        //reset
        is_router_called = FALSE;
        is_forwarder_called = FALSE;
        has_passed_signal = TRUE;
    } else {
        //proceed only if step 1 & 2 succeeds
        //if (0 == rej_cause_idx) {
            //step 2): sort
            for (i = task2_sort_idx; i < (task2_sort_idx + TASK2_STEP_SIZE) && i < valid_entry_cnts; i++) {
                value = e2eDelayEtxs[i];
                for (j = i - 1; j >= 0 && e2eDelayEtxs[j].e2e_delay_qtl > value.e2e_delay_qtl; j--) {
                    e2eDelayEtxs[j + 1] = e2eDelayEtxs[j];
                }
                e2eDelayEtxs[j + 1] = value;
            }
            //repost
            task2_sort_idx += TASK2_STEP_SIZE;
            post getNodeDelayEtxsSubTask2();
        //}
    }
    //call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 12, call LocalTimeMilli.get() - start_time);
}

//@param is_beacon: beacon of data, some actions can be avoided for beacon, e.g., forwarding frquency update
//@param all_congested, all_highly_congested: all parent candidates are congested
command am_addr_t RoutingTable.getNodeDelayEtxs(bool is_beacon, nx_uint16_t *node_delay_mean, delay_etx_t my_node_delay_etxs[], bool *all_congested, bool *all_highly_congested, uint32_t relative_deadline) {
    uint8_t i;
    uint8_t my_delay_etx_idx = 0;
    uint8_t idx = 0;

    uint8_t filtered_valid_entry_cnts = 0;    

	am_addr_t parent = INVALID_ADDR;
	am_addr_t min_etx_nb = INVALID_ADDR;
#if !(defined(MDQ) || defined(MDQ_DAG))
	uint32_t rt_min_etx = MAX_UINT32;
#endif
    
    uint32_t tmp;

    uint32_t start_time;
    *all_congested = FALSE;
    *all_highly_congested = FALSE;
    
    //special case for root
    if (state_is_root) {
        *all_congested = FALSE;
        *all_highly_congested = FALSE;
        for (i = 0; i < DELAY_ETX_LEVEL_CNTS; i++) {
            my_node_delay_etxs[i].node_delay_mean = 0;
            my_node_delay_etxs[i].node_delay_var = 0;
            my_node_delay_etxs[i].node_delay_etx = 0;
        }
        //root tx to piggyback inbound MAC delay
        //not INVALID_ADDR bcoz it's AM_BROADCAST_ADDR
        task_locked = FALSE;
        return (INVALID_ADDR - 1);
    }
    
    //preceding steps fail
    if (rej_cause_idx != 0)
        goto END;
    
    start_time = call LocalTimeMilli.get();
    //step 3): filter: in place(e2eDelayEtxs[0 .. valid_entry_cnts - 1]), no additional space required 
    //special case: min delay entry is directly admitted
    filtered_valid_entry_cnts = 1;
    for (i = 0; i < valid_entry_cnts; i++) {
        //skip min delay entry
        if (i > 0) {
            //only admit entries w/ larger delay and smaller etx
            if (e2eDelayEtxs[i].e2e_delay_qtl == e2eDelayEtxs[filtered_valid_entry_cnts - 1].e2e_delay_qtl) {
                //special case: if same delay, use one w/ smallest etx
                if (e2eDelayEtxs[i].e2e_delay_etx < e2eDelayEtxs[filtered_valid_entry_cnts - 1].e2e_delay_etx)
                    //replace
                    e2eDelayEtxs[filtered_valid_entry_cnts - 1] = e2eDelayEtxs[i];
            } else if (e2eDelayEtxs[i].e2e_delay_etx < e2eDelayEtxs[filtered_valid_entry_cnts - 1].e2e_delay_etx) {
                //must have larger delay if reach here
                //add
                e2eDelayEtxs[filtered_valid_entry_cnts++] = e2eDelayEtxs[i];
            }
    	}
    	
    	//look for parent
    	//for data packet only
    	if (is_beacon)
    		continue;
#if defined(MDQ) || defined(MDQ_DAG)
    #ifdef MDQ_DAG
    if (e2eDelayEtxs[i].nlq_e2e_delay_qtl <= relative_deadline)
    #endif
    	//min delay quantile neighbor is parent
    	if (0 == i)
    		parent = e2eDelayEtxs[i].nb;
#else
    	//min ETX neighbor meeting deadline; use nlq_e2e_delay_qtl, not e2e_delay_qtl
		if (e2eDelayEtxs[i].nlq_e2e_delay_qtl <= relative_deadline) {
            if (rt_min_etx > e2eDelayEtxs[i].e2e_delay_etx) {
                parent = e2eDelayEtxs[i].nb;
                rt_min_etx = e2eDelayEtxs[i].e2e_delay_etx;
            }
        }
#endif
    }
    if (!is_beacon)
        //update forward frequency
        if (parent != INVALID_ADDR) {
            idx = routingTableFind(parent);
            if (idx != routingTableActive)
                //TODO: consider overflow if protocol runs infinitely
                if (routingTable[idx].pkt_sent_cnts < MAX_UINT32)
                    routingTable[idx].pkt_sent_cnts++;
        }
    
    //call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 13, call LocalTimeMilli.get() - start_time);
    start_time = call LocalTimeMilli.get();
    //step 4): aggregate: e2eDelayEtxs[0 .. filtered_valid_entry_cnts - 1]
    if (filtered_valid_entry_cnts <= DELAY_ETX_LEVEL_CNTS) {
        for (i = 0; i < filtered_valid_entry_cnts; i++) {
            tmp = e2eDelayEtxs[i].e2e_delay_etx;
            my_node_delay_etxs[i].node_delay_etx = (tmp < MAX_UINT16) ? tmp : MAX_UINT16;
            tmp = e2eDelayEtxs[i].e2e_delay_mean;
            my_node_delay_etxs[i].node_delay_mean = (tmp < MAX_UINT16) ? tmp : MAX_UINT16;
            tmp = e2eDelayEtxs[i].e2e_delay_var;
            my_node_delay_etxs[i].node_delay_var = (tmp < MAX_UINT16) ? tmp : MAX_UINT16;
        }
        my_delay_etx_idx = filtered_valid_entry_cnts;
    } else {
        //more than enough entries; need to aggregate
        /* Algorithm
         * 1) select evenly (min & max entry MUST be included)
         * 2) repeat 
         *      select the largest 1-gap and smallest 2-gap
         *      if the former is much larger than the latter (say, 3x)
         *          replace central entry in the 2-gap w/ a central entry in 1-gap if any
         *    till no such case exists or MAX times reached
         */
         //the entries chosen (only indices are stored)
         uint8_t rounds;
         //store indices in filtered e2eDelayEtxs table
         uint8_t idxs[DELAY_ETX_LEVEL_CNTS];
         uint8_t max_1_gap_idx, min_2_gap_idx, entry_1_gap_middle_idx;
         uint32_t max_entry_1_gap, min_entry_2_gap, entry_1_gap, entry_2_gap;
         uint32_t idx_interval;
         //ASSERT
         if (1 == DELAY_ETX_LEVEL_CNTS) {
            rej_cause_idx = 3;
            goto END;
         }
         idx_interval = (filtered_valid_entry_cnts - 1) / (DELAY_ETX_LEVEL_CNTS - 1);
         
         //initialize the entries chosen
         for (i = 0; i < (DELAY_ETX_LEVEL_CNTS - 1); i++) {
            idxs[i] = idx_interval * i;
         }
         //max delay special
         idxs[DELAY_ETX_LEVEL_CNTS - 1] = filtered_valid_entry_cnts - 1;
         
         //avoid infinite loops
         for (rounds = 0; rounds < 3; rounds++) {
            max_entry_1_gap = 0;
            max_1_gap_idx = INVALID_RVAL;
            min_entry_2_gap = MAX_UINT32;
            min_2_gap_idx = INVALID_RVAL;
            
            for (i = 0; i < (DELAY_ETX_LEVEL_CNTS - 1); i++) {
                //ASSERT(e2eDelayEtxs is increasing)
                entry_1_gap = e2eDelayEtxs[idxs[i + 1]].e2e_delay_qtl - e2eDelayEtxs[idxs[i]].e2e_delay_qtl;
                if (max_entry_1_gap < entry_1_gap) {
                    max_entry_1_gap = entry_1_gap;
                    max_1_gap_idx = i;
                }
                if (i < (DELAY_ETX_LEVEL_CNTS - 2)) {
                    entry_2_gap = e2eDelayEtxs[idxs[i + 2]].e2e_delay_qtl - e2eDelayEtxs[idxs[i]].e2e_delay_qtl;
                    if (min_entry_2_gap > entry_2_gap) {
                        min_entry_2_gap = entry_2_gap;
                        min_2_gap_idx = i;
                    }
                }
            }
            //not found
            if (INVALID_RVAL == max_1_gap_idx || INVALID_RVAL == min_2_gap_idx)
                break;
            //ASSERT(idxs is increasing)
            //if no entry in the middle in 1-gap
            if ((idxs[max_1_gap_idx + 1] - idxs[max_1_gap_idx]) <= 1)
                break;
            
            if (max_entry_1_gap >= (3 * min_entry_2_gap)) {
                //replace
                entry_1_gap_middle_idx = (idxs[max_1_gap_idx] + idxs[max_1_gap_idx + 1]) / 2;
                if (min_2_gap_idx > max_1_gap_idx) {
                    //shift right
                    for (i = min_2_gap_idx; i > max_1_gap_idx; i--) {
                        idxs[i + 1] = idxs[i];
                    }
                    idxs[max_1_gap_idx + 1] = entry_1_gap_middle_idx;
                } else if (min_2_gap_idx < max_1_gap_idx) {
                    //shift left
                    for (i = min_2_gap_idx + 1; i < max_1_gap_idx; i++)
                        idxs[i] = idxs[i + 1];
                    idxs[max_1_gap_idx] = entry_1_gap_middle_idx;
                }                
            } else {
                //not found
                break;
            }
        }
        //now idxs contain all entries to fill in
        for (i = 0; i < DELAY_ETX_LEVEL_CNTS; i++) {
            idx = idxs[i];
            //ASSERT
            if (idx >= filtered_valid_entry_cnts)
                continue;
            tmp = e2eDelayEtxs[idx].e2e_delay_etx;
            my_node_delay_etxs[my_delay_etx_idx].node_delay_etx = (tmp < MAX_UINT16) ? tmp : MAX_UINT16;
            tmp = e2eDelayEtxs[idx].e2e_delay_mean;
            my_node_delay_etxs[my_delay_etx_idx].node_delay_mean = (tmp < MAX_UINT16) ? tmp : MAX_UINT16;
            tmp = e2eDelayEtxs[idx].e2e_delay_var;
            my_node_delay_etxs[my_delay_etx_idx].node_delay_var = (tmp < MAX_UINT16) ? tmp : MAX_UINT16;
            my_delay_etx_idx++;
        }
    }
    //call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 14, call LocalTimeMilli.get() - start_time);
END:
    *all_congested = !any_not_congested;
    *all_highly_congested = !any_not_highly_congested;
#if defined(ML) || defined(ML_DAG)
    *node_delay_mean = (min_path_delay < MAX_UINT16) ? min_path_delay : MAX_UINT16;
#endif
#ifdef ML
	parent = min_path_delay_parent;
#endif
    start_time = call LocalTimeMilli.get();
    //insufficient entries to select top DELAY_ETX_LEVEL_CNTS
    for (i = my_delay_etx_idx; i < DELAY_ETX_LEVEL_CNTS; i++) {
        my_node_delay_etxs[i].node_delay_etx = MAX_UINT16;
        my_node_delay_etxs[i].node_delay_mean = MAX_UINT16;
        my_node_delay_etxs[i].node_delay_var = MAX_UINT16;
    }
    if (filtered_valid_entry_cnts >= 1)
    	min_etx_nb = e2eDelayEtxs[filtered_valid_entry_cnts - 1].nb;
#if defined(TOSSIM)
	//ASSERT
    if (!is_beacon) {
    	if (min_etx_nb != parent)
    		dbg("TreeRouting", "%s: parent %hu vs min_etx neighbor %hu\n", __FUNCTION__, parent, min_etx_nb);
    }
#endif
    dbg("TreeRouting", "%s: valid entries # %hu, neighobr # %u, relative_deadline %u\n", __FUNCTION__, my_delay_etx_idx, routingTableActive, relative_deadline);
    if (!is_beacon && INVALID_ADDR == parent) {
        //call UartLog.logTxRx(DBG_FLAG, DBG_EXEC_TIME_FLAG, rej_cause_idx, filtered_valid_entry_cnts, my_delay_etx_idx, e2eDelayEtxs[i].e2e_delay_qtl, e2eDelayEtxs[i].e2e_delay_etx, relative_deadline);
        call UartLog.logTxRx(DBG_FLAG, DBG_REJ_CAUSE_FLAG, rej_cause_idx, any_pass_dag, any_pass_congest, any_pass_valid_delay, routingTableActive, valid_entry_cnts, filtered_valid_entry_cnts);
        dbg("TreeRouting", "%s: rejection cause %u\n", __FUNCTION__, rej_cause_idx);
    }
    //call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 15, call LocalTimeMilli.get() - start_time);
    if (extra_signal_pending) {
    	signal RoutingTable.getNodeDelayEtxsTasksDone();
    	call UartLog.logEntry(DBG_FLAG, DBG_CONGEST_FLAG, 0xFFFF, 0xFFFFFFFF);
    }
    task_locked = FALSE;
    return parent;
}

/*
 * find parents for multipath
 * not rej bcoz reliability req cannot be fulfilled
 * @param e2e_pdr_req: 	E2E reliability requirement assigned to this node
 * @param parent_e2e_pdr_reqs: updated E2E reliability requirement assigned to each next hop
 * return: # of parents found
 */
command uint8_t RoutingTable.getParents(uint32_t relative_deadline, uint16_t e2e_pdr_req, am_addr_t parents[], uint16_t parent_e2e_pdr_reqs[]) {
	uint8_t i, j;
	routing_table_entry *ne;
	
	uint8_t my_hop_cnt, remaining_hop_cnt;
	
	uint8_t parent_cnt = 0;
	
	uint32_t total_pdr = 0;
	uint32_t pdr_req, link_pdr, nb_pdr, link_etx, tmp;
#ifdef MCMP
	uint32_t link_deadline;
#elif defined(MMSPEED)
	//include local hop
	uint8_t nb_hop_cnt;
	uint32_t my_dist, nb_dist, my_nb_dist, speed_req, link_delay, link_speed;
#endif

	my_hop_cnt = myHopCnt();
	//reliability requirement
#ifdef MCMP
	//local for MCMP
	pdr_req = nthroot(e2e_pdr_req, my_hop_cnt);
#elif defined(MMSPEED)
	//e2e for MMSPEED
	pdr_req = e2e_pdr_req;
	#ifdef SDRCS
		my_dist = myHopCnt();
	#else
		my_dist = nodeDist(TOS_NODE_ID, ROOT_NODE_ID);
	#endif
	//speed requirement
	if (0 == relative_deadline)
		return 0;
	
	//scale up speed
	speed_req = my_dist * 1000000 / relative_deadline;
#endif

	for (i = 0; i < routingTableActive; i++) {
		ne = &routingTable[i];
		/*
		 * DAG: loop avoidance
		 * timing domain
		 */
		if (24 == TOS_NODE_ID)
		 	dbg("TreeRoutingDbg", "neighbor %hu: link delay %u\n", ne->neighbor, ne->out_link_delay_mean);
#ifdef MCMP
		//hop count DAG
		if (ne->hop_cnt >= my_hop_cnt)
			continue;
		
		link_deadline = relative_deadline / (ne->hop_cnt + 1);
		//meet local deadline
		if (ne->out_link_delay_mean > link_deadline)
			continue;
#elif defined(MMSPEED)
		#ifdef SDRCS
			nb_dist = ne->hop_cnt;
		#else
			//closer; geographical DAG
			nb_dist = nodeDist(ne->neighbor, ROOT_NODE_ID);
		#endif
		dbg("TreeRouting", "node %u: %u vs %u\n", ne->neighbor, nb_dist, my_dist);
		if (nb_dist >= my_dist)
			continue;
		my_nb_dist = my_dist - nb_dist;
	#ifdef MMSPEED_CD
		link_delay = (uint32_t)ne->out_link_delay_mean + CHEBYSHEV_SCALAR * isqrt(ne->out_link_delay_var);
	#else
		link_delay = ne->out_link_delay_mean;
	#endif
		link_speed = my_nb_dist * 1000000 / link_delay;
		//locally meet speed requirement
		if (link_speed < speed_req) {
			dbg("TreeRouting", "%s: %u-th neighbor %u, %u, %u\n", __FUNCTION__, i, ne->out_link_delay_mean, link_speed, speed_req);
			continue;
		}
#endif
		/*
		 * reliability domain
		 * 0) does NOT minimize # of parents chosen; rank neighbors according to link reliability is one approach
		 * 1) strictly speaking, the last admitted next hop is conservative
		 * 		adding it can make total_pdr larger than pdr_req
		 */
		//admit if not meeting reliability requirement yet
		//at least one parent; when links are lossy and hops are many, the assigned pdr_req can be 0, no parent
		if (total_pdr >= pdr_req && parent_cnt > 0)
			break;

		link_etx = call LinkEstimator.getLinkQuality(ne->neighbor) + 10;
		//pdr = 1 / etx
		link_pdr = (uint32_t)10 * PDR_SCALAR / link_etx;
	#ifdef MCMP
		nb_pdr = link_pdr;
		remaining_hop_cnt = my_hop_cnt - 1;
	#elif defined(MMSPEED)
		//nb_dist / my_nb_dist (hops from neighbor to root) + 1 (local)
		nb_hop_cnt = nb_dist / my_nb_dist + 1;
		//ceiling
		if ((nb_dist % my_nb_dist) != 0)
			nb_hop_cnt++;
		//path reliability thru this neighbor: link_pdr ^ nb_hop_cnt
		tmp = PDR_SCALAR;
		for (j = 0; j < nb_hop_cnt; j++)
			tmp = tmp * link_pdr / PDR_SCALAR;
		nb_pdr = tmp;
		remaining_hop_cnt = nb_hop_cnt - 1;
	#endif
		//pdr = 1 - (1 - pdr) * (1 - pdr')
		total_pdr = PDR_SCALAR - (PDR_SCALAR - total_pdr) * (PDR_SCALAR - nb_pdr) / PDR_SCALAR;
		//assign reliability requirement to next hop
		//next hop pdr_req = link_pdr ^ remaining_hop_cnt (from next hop neighbor to root)
		tmp = PDR_SCALAR;
		for (j = 0; j < remaining_hop_cnt; j++)
			tmp = tmp * link_pdr / PDR_SCALAR;
		parent_e2e_pdr_reqs[parent_cnt] = tmp;
		parents[parent_cnt] = ne->neighbor;
		parent_cnt++;
	}
	#ifdef SDRCS
		// single path
		return (parent_cnt < 1) ? parent_cnt : 1;
	#else
		// multi path
		return parent_cnt;
	#endif
}

//record DAG
command void RoutingTable.logDAG() {
	uint8_t i;
	routing_table_entry *ne;
	
	uint32_t delay, min_delay = MAX_UINT32;
	uint16_t my_etx;
	
	am_addr_t etx_preds[NEIGHBOR_TABLE_SIZE];
	am_addr_t ml_preds[NEIGHBOR_TABLE_SIZE];
	uint8_t etx_idx = 0;
	uint8_t ml_idx = 0;
	
	for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
		etx_preds[i] = 0;
		ml_preds[i] = 0;
	}
	
	//min delay
	for (i = 0; i < routingTableActive; i++) {
		ne = &routingTable[i];
	    
        //min path delay thru each predecessor
        dbg("TreeRouting", "%u-th neighbor %u outbound delay %u %u\n", i, ne->neighbor, ne->out_link_delay_mean, ne->node_delay_mean);
        if (MAX_UINT16 == ne->node_delay_mean || MAX_UINT16 == ne->out_link_delay_mean)
            continue;
        //any_smaller_node_delay = TRUE;
        delay = (uint32_t)ne->node_delay_mean + ne->out_link_delay_mean;
        if (min_delay > delay) {
            min_delay = delay;
        }
	}
	
	my_etx = routeInfo.etx + call LinkEstimator.getLinkQuality(routeInfo.parent) + 10;
	for (i = 0; i < routingTableActive; i++) {
		ne = &routingTable[i];
        
        //smaller ETX; exclude parent to avoid temporary inconsistency
        if (ne->neighbor == routeInfo.parent || ne->info.etx < my_etx)
        	etx_preds[etx_idx++] = ne->neighbor;
		
		if (ne->node_delay_mean != MAX_UINT16 && ne->node_delay_mean < min_delay)
            ml_preds[ml_idx++] = ne->neighbor;
	}
	
	call UartLog.logTxRx(DBG_FLAG, DBG_DAG_FLAG, etx_idx, 0, (etx_preds[0] << 8) | etx_preds[1], (etx_preds[2] << 8) | etx_preds[3], (etx_preds[4] << 8) | etx_preds[5], (etx_preds[6] << 8) | etx_preds[7], (etx_preds[8] << 8) | etx_preds[9]);
	call UartLog.logTxRx(DBG_FLAG, DBG_DAG_FLAG, ml_idx, 1, (ml_preds[0] << 8) | ml_preds[1], (ml_preds[2] << 8) | ml_preds[3], (ml_preds[4] << 8) | ml_preds[5], (ml_preds[6] << 8) | ml_preds[7], (ml_preds[8] << 8) | ml_preds[9]);
}

//compute my own hop count
static uint8_t myHopCnt() {
	uint8_t i;
	routing_table_entry *ne;
	uint16_t my_hop_cnt = MAX_UINT16;
	uint16_t path_hop_cnt;

	if (state_is_root)
		return 0;
	
	//compute my hop cnt
	for (i = 0; i < routingTableActive; i++) {
		ne = &routingTable[i];
		
		#ifdef SDRCS
			//hop count based on RSSI
			if (!ne->pass_rssi)
				continue;
		#endif
			
		path_hop_cnt = (uint16_t)ne->hop_cnt + 1;
		if (my_hop_cnt > path_hop_cnt)
			my_hop_cnt = path_hop_cnt;
	}
	return (my_hop_cnt < 255) ? my_hop_cnt : 255;
}

//n-th root: x ^ (1 / n)
static uint32_t nthroot(uint32_t x, uint8_t n) {
	//TODO
	return x;
}


static long isqrt(long num) {
    long op = num;
    long res = 0;
    long one = 1L<<30; // The second-to-top bit is set: 1 << 14 for short
    //uint32_t start_time = call LocalTimeMilli.get();
    
    // "one" starts at the highest power of four <= the argument.
    while (one > op) {
        dbg("LoopDetection", "%s \n", __FUNCTION__);
        one >>= 2;
    }

    while (one != 0) {
        dbg("LoopDetection", "%s \n", __FUNCTION__);
        if (op >= res + one) {
            op -= res + one;
            res = (res >> 1) + one;
        }
        else
          res >>= 1;
        one >>= 2;
    }
    //call UartLog.logEntry(DBG_FLAG, DBG_EXEC_TIME_FLAG, 16, call LocalTimeMilli.get() - start_time);
    return res;
}

//compute distance between nodes
#ifndef INDRIYA
static uint32_t nodeDist(am_addr_t m, am_addr_t n) {
    uint32_t m_x, n_x, m_y, n_y;
#ifndef TOSSIM
    //tossim starts w/ 0, neteye w/ 1
    m--;
    n--;
#endif
    m_x = m % COLUMNS;
    n_x = n % COLUMNS;
    m_y = m / COLUMNS;
    n_y = n / COLUMNS;
    
    return ((uint32_t)isqrt((m_x - n_x) * (m_x - n_x) + (m_y - n_y) * (m_y - n_y)));
}

#else	//indriya

typedef struct {
	uint8_t x;
	uint8_t y;
	uint8_t z;
} pos_3d_t;

pos_3d_t locations[] = {
{0,0,10}, //na
{102,25,10},//1
{111,26,10},//2
{112,33,10},//3
{94,25,10},//4
{94,40,10},//5
{87,38,10},//6
{122,23,10},//7
{99,14,10},//8
{122,32,10},//9
{80,48,10},//10
{113,8,10},//11
{112,14,10},//12
{100,8,10},//13
{140,32,10},//14
{120,25,10},//15
{79,30,10},//16
{76,45,10},//17
{74,28,10},//18
{123,14,10},//19
{78,25,10},//20
{126,6,10},//21
{132,25,10},//22
{23,36,10},//23
{42,30,10},//24
{17,25,10},//25
{42,42,10},//26
{32,55,10},//27
{20,28,10},//28
{3,32,10},//29
{5,49,10},//30
{2,21,10},//31
{49,32,10},//32
{35,25,10},//33
{38,25,10},//34
{49,47,10},//35
{52,42,10},//36
{52,50,10},//level 1 37
{76,38,20},//38
{69,34,20},//39
{79,33,20},//40
{76,28,20},//41
{85,32,20},//42
{72,32,20},//43
{72,43,20},//44
{90,33,20},//45
{84,22,20},//46
{90,37,20},//47
{65,26,20},//48
{69,39,20},//49
{68,25,20},//50
{65,44,20},//51
{96,33,20},//52
{72,48,20},//53
{68,16,20},//54
{85,16,20},//55
{90,28,20},//56
{73,10,20},//57
{60,16,20},//58
{85,10,20},//59
{115,35,20},//60
{118,30,20},//61
{116,25,20},//62
{120,28,20},//63
{117,28,20},//64
{123,32,20},//65
{121,25,20},//66
{105,17,20},//67
{112,41,20},//68
{108,31,20},//69
{128,32,20},//70
{136,22,20},//71
{128,23,20},//72
{122,17,20},//73
{100,22,20},//74
{103,44,20},//75
{133,26,20},//76
{129,13,20},//77
{134,37,20},//78
{118,10,20},//79
{134,17,20},//80
{144,37,20},//81
{40,28,20},//level2 82
{51,20,30},//83
{56,26,30},//84
{47,25,30},//85
{41,19,30},//86
{45,21,30},//87
{57,88,30},//88
{55,20,30},//89
{62,21,30},//90
{52,16,30},//91
{51,29,30},//92
{44,29,30},//93
{43,16,30},//94
{67,20,30},//95
{60,32,30},//96
{57,23,30},//97
{62,16,30},//98
{68,29,30},//99
{47,35,30},//100
{38,19,30},//101
{38,16,30},//102
{66,11,30},//103
{55,40,30},//104
{36,29,30},//105
{40,34,30},//106
{40,38,30},//107
{92,19,30},//108
{85,22,30},//109
{87,17,30},//110
{87,14,30},//111
{95,18,30},//112
{92,15,30},//113
{86,28,30},//114
{78,17,30},//115
{83,25,30},//116
{85,25,30},//117
{80,21,30},//118
{78,14,30},//119
{82,9,30},//120
{76,32,30},//121
{88,30,30},//122
{72,9,30},//123
{71,15,30},//124
{87,9,30},//125
{96,9,30},//126
{70,9,30}//127
};
static uint32_t nodeDist(am_addr_t m, am_addr_t n) {
	pos_3d_t m_pos, n_pos;
	
	m_pos = locations[m];
	n_pos = locations[n];
	
	return ((uint32_t)isqrt((m_pos.x - n_pos.x) * (m_pos.x - n_pos.x) + (m_pos.y - n_pos.y) * (m_pos.y - n_pos.y) + (m_pos.z - n_pos.z) * (m_pos.z - n_pos.z)));
}
#endif
