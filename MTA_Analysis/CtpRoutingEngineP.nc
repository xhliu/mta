/*
 * Hybrid MAC delay sampling similar to ETX: data + beacon
 * for beacon-based
 * 1) no retx, so no need to check duplicate packet
 * 2) update outbound MAC delay of the sender directly, not inbound
 */
#include <Timer.h>
#include <TreeRouting.h>
#include <CollectionDebugMsg.h>

generic module CtpRoutingEngineP(uint8_t routingTableSize, uint32_t minInterval, uint32_t maxInterval) {
    provides {
        interface UnicastNameFreeRouting as Routing;
        interface RootControl;
        interface CtpInfo;
        interface StdControl;
        interface CtpRoutingPacket;
        interface Init;
        //
        interface RoutingTable;
    } 
    uses {
#if defined(TOSSIM)
        interface AMSend as BeaconSend;
#else
        interface TimeSyncPacket<TMilli, uint32_t>;
        interface TimeSyncAMSend<TMilli, uint32_t> as BeaconSend;
#endif        
        interface Receive as BeaconReceive;
        interface LinkEstimator;
        interface AMPacket;
        interface SplitControl as RadioControl;
        interface Timer<TMilli> as BeaconTimer;
        interface Timer<TMilli> as RouteTimer;
        interface Random;
        interface CollectionDebug;
        interface CtpCongestion;
	    interface CompareBit;
	    //
	    interface UartLog;
	    interface DataPanel;
	    interface LocalTime<TMilli> as LocalTimeMilli;
	//#ifdef DS_P2
	    interface Utils;
	//#endif
	#if defined(SDRCS) && !defined(TOSSIM)
		interface CC2420Packet;
	#endif
    }
}


implementation {
	//XL
    bool ECNOff = FALSE;

    /* Keeps track of whether the radio is on. No sense updating or sending
     * beacons if radio is off */
    bool radioOn = FALSE;
    /* Controls whether the node's periodic timer will fire. The node will not
     * send any beacon, and will not update the route. Start and stop control this. */
    bool running = FALSE;
    /* Guards the beacon buffer: only one beacon being sent at a time */
    bool sending = FALSE;

    /* Tells updateNeighbor that the parent was just evicted.*/ 
    bool justEvicted = FALSE;

    route_info_t routeInfo;
    bool state_is_root;
    am_addr_t my_ll_addr;

    message_t beaconMsgBuffer;
    ctp_routing_header_t* beaconMsg;

    /* routing table -- routing info about neighbors */
    routing_table_entry routingTable[routingTableSize];
    uint8_t routingTableActive;

    /* statistics */
    uint32_t parentChanges;
    //XL
    uint32_t heartbeat_cnts = 0;
    //get my own hop count
    static uint8_t myHopCnt();
    /* end statistics */

    uint32_t routeUpdateTimerCount;

    // Maximimum it takes to hear four beacons
//     enum {
//       DEATH_TEST_INTERVAL = (maxInterval * 4) / (BEACON_INTERVAL / 1024),
//     };
    
    // forward declarations
    void routingTableInit();
    uint8_t routingTableFind(am_addr_t);
    error_t routingTableUpdateEntry(am_addr_t, am_addr_t , uint16_t, uint8_t, bool);
    error_t routingTableEvict(am_addr_t neighbor);

    uint32_t currentInterval = minInterval;
    uint32_t t; 
    bool tHasPassed;

    void chooseAdvertiseTime() {
       t = currentInterval;
       t /= 2;
       t += call Random.rand32() % t;
       tHasPassed = FALSE;
       call BeaconTimer.stop();
       call BeaconTimer.startOneShot(t);
    }

    void resetInterval() {
      currentInterval = minInterval;
      chooseAdvertiseTime();
    }

    void decayInterval() {
        currentInterval *= 2;
        if (currentInterval > maxInterval) {
          currentInterval = maxInterval;
        }
      chooseAdvertiseTime();
    }

    void remainingInterval() {
       uint32_t remaining = currentInterval;
       remaining -= t;
       tHasPassed = TRUE;
       call BeaconTimer.startOneShot(remaining);
    }

    command error_t Init.init() {
        uint8_t maxLength;
        routeUpdateTimerCount = 0;
        radioOn = FALSE;
        running = FALSE;
        parentChanges = 0;
        state_is_root = 0;
        routeInfoInit(&routeInfo);
        routingTableInit();
        my_ll_addr = call AMPacket.address();
        beaconMsg = call BeaconSend.getPayload(&beaconMsgBuffer, call BeaconSend.maxPayloadLength());
        maxLength = call BeaconSend.maxPayloadLength();
        dbg("TreeRoutingCtl","TreeRouting initialized. (used payload:%d max payload:%d!\n", 
              sizeof(beaconMsg), maxLength);
        return SUCCESS;
    }

    command error_t StdControl.start() {
      //start will (re)start the sending of messages
      if (!running) {
	running = TRUE;
	resetInterval();
	call RouteTimer.startPeriodic(BEACON_INTERVAL);
	dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
      }     
      return SUCCESS;
    }

    command error_t StdControl.stop() {
        running = FALSE;
        dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
        return SUCCESS;
    } 

    event void RadioControl.startDone(error_t error) {
        radioOn = TRUE;
        dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
        if (running) {
            uint16_t nextInt;
            nextInt = call Random.rand16() % BEACON_INTERVAL;
            nextInt += BEACON_INTERVAL >> 1;
            call BeaconTimer.startOneShot(nextInt);
        }
    } 

    event void RadioControl.stopDone(error_t error) {
        radioOn = FALSE;
        dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
    }

    /* Is this quality measure better than the minimum threshold? */
    // Implemented assuming quality is EETX
    bool passLinkEtxThreshold(uint16_t etx) {
	return TRUE;
        return (etx < ETX_THRESHOLD);
    }

    /* Converts the output of the link estimator to path metric
     * units, that can be *added* to form path metric measures */
    uint16_t evaluateEtx(uint16_t quality) {
        //dbg("TreeRouting","%s %d -> %d\n",__FUNCTION__,quality, quality+10);
        return (quality + 10);
    }

    /* updates the routing information, using the info that has been received
     * from neighbor beacons. Two things can cause this info to change: 
     * neighbor beacons, changes in link estimates, including neighbor eviction */
    task void updateRouteTask() {
        uint8_t i;
        routing_table_entry* entry;
        routing_table_entry* best;
        uint16_t minEtx;
        uint16_t currentEtx;
        uint16_t linkEtx, pathEtx;

        if (state_is_root)
            return;
       
        best = NULL;
        /* Minimum etx found among neighbors, initially infinity */
        minEtx = MAX_METRIC;
        /* Metric through current parent, initially infinity */
        currentEtx = MAX_METRIC;

        /* Find best path in table, other than our current */
        for (i = 0; i < routingTableActive; i++) {
            entry = &routingTable[i];

            // Avoid bad entries and 1-hop loops
            if (entry->info.parent == INVALID_ADDR || entry->info.parent == my_ll_addr) {
              dbg("TreeRouting", "routingTable[%d]: neighbor: [id: %d parent: %d  etx: NO ROUTE]\n",  
                  i, entry->neighbor, entry->info.parent);
              continue;
            }
            /* Compute this neighbor's path metric */
            linkEtx = evaluateEtx(call LinkEstimator.getLinkQuality(entry->neighbor));

            dbg("TreeRouting", "routingTable[%d]: neighbor: [id: %d parent: %d etx: %d]\n",  
                i, entry->neighbor, entry->info.parent, linkEtx);
            pathEtx = linkEtx + entry->info.etx;
            /* Operations specific to the current parent */
            if (entry->neighbor == routeInfo.parent) {
                dbg("TreeRouting", "   already parent.\n");
                currentEtx = pathEtx;
                /* update routeInfo with parent's current info */
                atomic {
                    routeInfo.etx = entry->info.etx;
                    routeInfo.congested = entry->info.congested;
                }
                continue;
            }
            /* Ignore links that are congested */
            if (entry->info.congested)
                continue;
            /* Ignore links that are bad */
            if (!passLinkEtxThreshold(linkEtx)) {
              dbg("TreeRouting", "   did not pass threshold.\n");
              continue;
            }
            
            if (pathEtx < minEtx) {
                minEtx = pathEtx;
                best = entry;
            }  
        }

        //call CollectionDebug.logEventDbg(NET_C_DBG_3, routeInfo.parent, currentEtx, minEtx);  

        /* Now choose between the current parent and the best neighbor */
        /* Requires that: 
            1. at least another neighbor was found with ok quality and not congested
            2. the current parent is congested and the other best route is at least as good
            3. or the current parent is not congested and the neighbor quality is better by 
               the PARENT_SWITCH_THRESHOLD.
          Note: if our parent is congested, in order to avoid forming loops, we try to select
                a node which is not a descendent of our parent. routeInfo.ext is our parent's
                etx. Any descendent will be at least that + 10 (1 hop), so we restrict the 
                selection to be less than that.
        */
        if (minEtx != MAX_METRIC) {
            if (currentEtx == MAX_METRIC ||
                (routeInfo.congested && (minEtx < (routeInfo.etx + 10))) ||
                minEtx + PARENT_SWITCH_THRESHOLD < currentEtx) {
                // routeInfo.metric will not store the composed metric.
                // since the linkMetric may change, we will compose whenever
                // we need it: i. when choosing a parent (here); 
                //            ii. when choosing a next hop
                parentChanges++;

                dbg("TreeRouting","Changed parent. from %d to %d\n", routeInfo.parent, best->neighbor);
                call CollectionDebug.logEventDbg(NET_C_TREE_NEW_PARENT, best->neighbor, best->info.etx, minEtx);
                call LinkEstimator.unpinNeighbor(routeInfo.parent);
                call LinkEstimator.pinNeighbor(best->neighbor);
                call LinkEstimator.clearDLQ(best->neighbor);
                atomic {
                    routeInfo.parent = best->neighbor;
                    routeInfo.etx = best->info.etx;
                    routeInfo.congested = best->info.congested;
                }
            }
        }    

        /* Finally, tell people what happened:  */
        /* We can only loose a route to a parent if it has been evicted. If it hasn't 
         * been just evicted then we already did not have a route */
        if (justEvicted && routeInfo.parent == INVALID_ADDR) 
            signal Routing.noRoute();
        /* On the other hand, if we didn't have a parent (no currentEtx) and now we
         * do, then we signal route found. The exception is if we just evicted the 
         * parent and immediately found a replacement route: we don't signal in this 
         * case */
        else if (!justEvicted && currentEtx == MAX_METRIC && minEtx != MAX_METRIC)
            signal Routing.routeFound();
        justEvicted = FALSE;
    }

    

    /* send a beacon advertising this node's routeInfo */
    // only posted if running and radioOn
    task void sendBeaconTask() {
        error_t eval;
#if !defined(CTP)
        bool all_parent_congested, all_parent_highly_congested;
#endif        
        uint8_t entry_cnts;
        uint32_t tx_timestamp;
        
        if (sending) {
            return;
        }

        beaconMsg->options = 0;

        /* Congestion notification: am I congested? */
        if (call CtpCongestion.isCongested()) {
            beaconMsg->options |= CTP_OPT_ECN;
            //dbg("overflow", "%: congested from beacon\n", __FUNCTION__);
        }
        //XL
        if (call CtpCongestion.isHighlyCongested()) {
            beaconMsg->options |= CTP_OPT_HCN;
        }
        
        beaconMsg->parent = routeInfo.parent;
        if (state_is_root) {
            beaconMsg->etx = routeInfo.etx;
        }
        else if (routeInfo.parent == INVALID_ADDR) {
            beaconMsg->etx = routeInfo.etx;
            beaconMsg->options |= CTP_OPT_PULL;
        } else {
            beaconMsg->etx = routeInfo.etx +
                                evaluateEtx(call LinkEstimator.getLinkQuality(routeInfo.parent));
        }
        //XL: load MAC delays of neighbors
        tx_timestamp = call LocalTimeMilli.get();
#if !defined(CTP)
        beaconMsg->tx_timestamp = tx_timestamp;
        call RoutingTable.getMacDelays(beaconMsg->mac_delays, sizeof(beaconMsg->mac_delays) / sizeof(beaconMsg->mac_delays[0]));
        //infinite deadline
        call RoutingTable.getNodeDelayEtxs(TRUE, &beaconMsg->node_delay_mean, beaconMsg->node_delay_etxs, &all_parent_congested, &all_parent_highly_congested, MAX_UINT32);
        beaconMsg->hop_cnt = myHopCnt();
        //backpressure: a node is congested if all its parents are congested regardless of its own queueing
        if (all_parent_congested)
            beaconMsg->options |= CTP_OPT_ECN;
        if (all_parent_highly_congested)
            beaconMsg->options |= CTP_OPT_HCN;
#endif
        entry_cnts = sizeof(beaconMsg->node_delay_etxs) / sizeof(beaconMsg->node_delay_etxs[0]);
		//call UartLog.logEntry(DBG_FLAG, DBG_RSSI_FLAG, 0, beaconMsg->hop_cnt);
        call CollectionDebug.logEventRoute(NET_C_TREE_SENT_BEACON, beaconMsg->parent, 0, beaconMsg->etx);
		if (24 == TOS_NODE_ID)
		    dbg("TreeRoutingDbg", "%s parent: %d <%u, %u> %u\n", __FUNCTION__, beaconMsg->parent, beaconMsg->node_delay_etxs[0].node_delay_mean, beaconMsg->node_delay_etxs[0].node_delay_var, beaconMsg->node_delay_mean);
#if defined(TOSSIM)
        eval = call BeaconSend.send(AM_BROADCAST_ADDR, &beaconMsgBuffer, sizeof(ctp_routing_header_t));
#else
        eval = call BeaconSend.send(AM_BROADCAST_ADDR, &beaconMsgBuffer, sizeof(ctp_routing_header_t), tx_timestamp);
#endif
        if (eval == SUCCESS) {
            sending = TRUE;
        } else if (eval == EOFF) {
            radioOn = FALSE;
            dbg("TreeRouting","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
        }
    }

    event void BeaconSend.sendDone(message_t* msg, error_t error) {
        if ((msg != &beaconMsgBuffer) || !sending) {
            //something smells bad around here
            return;
        }
        sending = FALSE;
    }

    event void RouteTimer.fired() {
      if (radioOn && running) {
         post updateRouteTask();
         call UartLog.logEntry(DBG_FLAG, DBG_HEARTBEAT_FLAG, 0, heartbeat_cnts++);
      }
    }
      
    event void BeaconTimer.fired() {
      if (radioOn && running) {
        if (!tHasPassed) {
          post updateRouteTask(); //always send the most up to date info
          //XL
    #ifndef CTP
          call RoutingTable.postGetNodeDelayEtxsTasks(TRUE, 0, 0);
    #else
          post sendBeaconTask();
    #endif
          dbg("RoutingTimer", "Beacon timer fired at %s\n", sim_time_string());
          remainingInterval();
        }
        else {
          decayInterval();
        }
      }
    }


    ctp_routing_header_t* getHeader(message_t* ONE m) {
      return (ctp_routing_header_t*)call BeaconSend.getPayload(m, call BeaconSend.maxPayloadLength());
    }
    
    
    /* Handle the receiving of beacon messages from the neighbors. We update the
     * table, but wait for the next route update to choose a new parent */
    event message_t* BeaconReceive.receive(message_t* msg, void* payload, uint8_t len) {
        am_addr_t from;
        ctp_routing_header_t* rcvBeacon;
        bool congested, highlyCongested;
#if !defined(CTP)
        uint32_t local_tx_timestamp, rx_timestamp;
#endif
        // Received a beacon, but it's not from us.
        if (len != sizeof(ctp_routing_header_t)) {
          dbg("LITest", "%s, received beacon of size %hhu, expected %i\n",
                     __FUNCTION__, 
                     len,
                     (int)sizeof(ctp_routing_header_t));
              
          return msg;
        }
        
        //need to get the am_addr_t of the source
        from = call AMPacket.source(msg);
		//call UartLog.logEntry(DBG_FLAG, DBG_RSSI_FLAG, from, call CC2420Packet.getRssi(msg) >= RSSI_THRESHOLD);
        rcvBeacon = (ctp_routing_header_t*)payload;
#if !defined(CTP)
        //XL: beacon-based MAC delay sampling
    #if !defined(TOSSIM)
        //valid samples only
        if (call TimeSyncPacket.isValid(msg)) {
    #endif
            rx_timestamp = call LocalTimeMilli.get();
        #if defined(TOSSIM)
            local_tx_timestamp = rcvBeacon->tx_timestamp;
        #else
            //convert tx timestamp into local time
            local_tx_timestamp = call TimeSyncPacket.eventTime(msg);
        #endif
        	//update skew
        	call RoutingTable.setNbTimeSkew(from, (int32_t)local_tx_timestamp - (int32_t)rcvBeacon->tx_timestamp);
            if (rx_timestamp > local_tx_timestamp) {
                uint32_t mac_delay_sample = rx_timestamp - local_tx_timestamp;
                dbg("TreeRouting", "%s: mac delay sample %u from %u\n", __FUNCTION__, mac_delay_sample, from);
                //link delay of beacon is quite different from data packets, MAC delay similar; to jumpstart
                //feed sample (in ms) into corresponding neighbor entry
                call RoutingTable.sampleMacDelay(from, TRUE, 0, mac_delay_sample, mac_delay_sample);
            }
    #if !defined(TOSSIM)
        }
    #endif
#endif
        congested = call CtpRoutingPacket.getOption(msg, CTP_OPT_ECN);
        highlyCongested = call CtpRoutingPacket.getOption(msg, CTP_OPT_HCN);
        dbg("TreeRouting","%s from: %d  [parent: %d etx: %d] congested %u\n", __FUNCTION__, from, 
            rcvBeacon->parent, rcvBeacon->etx, congested);

        //update neighbor table
        if (rcvBeacon->parent != INVALID_ADDR) {

            /* If this node is a root, request a forced insert in the link
             * estimator table and pin the node. */
            if (rcvBeacon->etx == 0) {
                dbg("TreeRouting","from a root, inserting if not in table\n");
                call LinkEstimator.insertNeighbor(from);
                call LinkEstimator.pinNeighbor(from);
            }
            //TODO: also, if better than my current parent's path etx, insert

			//see if RSSI passes threshold
#if defined(SDRCS) && !defined(TOSSIM)
            routingTableUpdateEntry(from, rcvBeacon->parent, rcvBeacon->etx, rcvBeacon->hop_cnt, call CC2420Packet.getRssi(msg) >= RSSI_THRESHOLD);
#else
            routingTableUpdateEntry(from, rcvBeacon->parent, rcvBeacon->etx, rcvBeacon->hop_cnt, TRUE);
#endif
            call CtpInfo.setNeighborCongested(from, congested, highlyCongested);
#if !defined(CTP)      
            //XL: update outbound MAC delay if such delay available from the packet
            call RoutingTable.setMacDelays(from, rcvBeacon->mac_delays, sizeof(rcvBeacon->mac_delays) / sizeof(rcvBeacon->mac_delays[0]));
            call RoutingTable.setNodeDelayEtxs(from, rcvBeacon->node_delay_mean, rcvBeacon->node_delay_etxs);
#endif
        }

        if (call CtpRoutingPacket.getOption(msg, CTP_OPT_PULL)) {
              resetInterval();
        }
        return msg;
    }


    /* Signals that a neighbor is no longer reachable. need special care if
     * that neighbor is our parent */
    event void LinkEstimator.evicted(am_addr_t neighbor) {
        routingTableEvict(neighbor);
        dbg("TreeRouting","%s\n",__FUNCTION__);
        if (routeInfo.parent == neighbor) {
            routeInfoInit(&routeInfo);
            justEvicted = TRUE;
            post updateRouteTask();
        }
    }

    /* Interface UnicastNameFreeRouting */
    /* Simple implementation: return the current routeInfo */
    command am_addr_t Routing.nextHop() {
        return routeInfo.parent;    
    }
    command bool Routing.hasRoute() {
        return (routeInfo.parent != INVALID_ADDR);
    }
   
    /* CtpInfo interface */
    command error_t CtpInfo.getParent(am_addr_t* parent) {
        if (parent == NULL) 
            return FAIL;
        if (routeInfo.parent == INVALID_ADDR)    
            return FAIL;
        *parent = routeInfo.parent;
        return SUCCESS;
    }

    command error_t CtpInfo.getEtx(uint16_t* etx) {
        if (etx == NULL) 
            return FAIL;
        if (routeInfo.parent == INVALID_ADDR)    
            return FAIL;
	if (state_is_root == 1) {
	  *etx = 0;
	} else {
	  // path etx = etx(parent) + etx(link to the parent)
	  *etx = routeInfo.etx + evaluateEtx(call LinkEstimator.getLinkQuality(routeInfo.parent));
	}
        return SUCCESS;
    }

    command void CtpInfo.recomputeRoutes() {
      post updateRouteTask();
    }

    command void CtpInfo.triggerRouteUpdate() {
      resetInterval();
     }

    command void CtpInfo.triggerImmediateRouteUpdate() {
      resetInterval();
    }

    command void CtpInfo.setNeighborCongested(am_addr_t n, bool congested, bool highlyCongested) {
        uint8_t idx;    
        if (ECNOff)
            return;
        idx = routingTableFind(n);
        if (idx < routingTableActive) {
            routingTable[idx].info.congested = congested;
            routingTable[idx].info.highlyCongested = highlyCongested;
        }
        if (routeInfo.congested && !congested) 
            post updateRouteTask();
        else if (routeInfo.parent == n && congested) 
            post updateRouteTask();
    }

    command bool CtpInfo.isNeighborCongested(am_addr_t n) {
        uint8_t idx;    

        if (ECNOff) 
            return FALSE;

        idx = routingTableFind(n);
        if (idx < routingTableActive) {
            return routingTable[idx].info.congested;
        }
        return FALSE;
    }
    
    /* RootControl interface */
    /** sets the current node as a root, if not already a root */
    /*  returns FAIL if it's not possible for some reason      */
    command error_t RootControl.setRoot() {
        bool route_found = FALSE;
        route_found = (routeInfo.parent == INVALID_ADDR);
        atomic {
            state_is_root = 1;
            routeInfo.parent = my_ll_addr; //myself
            routeInfo.etx = 0;
        }
        if (route_found) 
            signal Routing.routeFound();
        dbg("TreeRouting","%s I'm a root now!\n",__FUNCTION__);
        call CollectionDebug.logEventRoute(NET_C_TREE_NEW_PARENT, routeInfo.parent, 0, routeInfo.etx);
        return SUCCESS;
    }

    command error_t RootControl.unsetRoot() {
        atomic {
            state_is_root = 0;
            routeInfoInit(&routeInfo);
        }
        dbg("TreeRouting","%s I'm not a root now!\n",__FUNCTION__);
        post updateRouteTask();
        return SUCCESS;
    }

    command bool RootControl.isRoot() {
        return state_is_root;
    }

    default event void Routing.noRoute() {
    }
    
    default event void Routing.routeFound() {
    }


  /* This should see if the node should be inserted in the table.
   * If the white_bit is set, this means the LL believes this is a good
   * first hop link. 
   * The link will be recommended for insertion if it is better* than some
   * link in the routing table that is not our parent.
   * We are comparing the path quality up to the node, and ignoring the link
   * quality from us to the node. This is because of a couple of things:
   *   1. because of the white bit, we assume that the 1-hop to the candidate
   *      link is good (say, etx=1)
   *   2. we are being optimistic to the nodes in the table, by ignoring the
   *      1-hop quality to them (which means we are assuming it's 1 as well)
   *      This actually sets the bar a little higher for replacement
   *   3. this is faster
   *   4. it doesn't require the link estimator to have stabilized on a link
   */
    event bool CompareBit.shouldInsert(message_t *msg, void* payload, uint8_t len, bool white_bit) {
        
        bool found = FALSE;
        uint16_t pathEtx;
        //uint16_t linkEtx = evaluateEtx(0);
        uint16_t neighEtx;
        int i;
        routing_table_entry* entry;
        ctp_routing_header_t* rcvBeacon;

        if ((call AMPacket.type(msg) != AM_CTP_ROUTING) ||
            (len != sizeof(ctp_routing_header_t))) 
            return FALSE;

        /* 1.determine this packet's path quality */
        rcvBeacon = (ctp_routing_header_t*)payload;

        if (rcvBeacon->parent == INVALID_ADDR)
            return FALSE;
        /* the node is a root, recommend insertion! */
        if (rcvBeacon->etx == 0) {
            return TRUE;
        }
    
        pathEtx = rcvBeacon->etx; // + linkEtx;

        /* 2. see if we find some neighbor that is worse */
        for (i = 0; i < routingTableActive && !found; i++) {
            entry = &routingTable[i];
            //ignore parent, since we can't replace it
            if (entry->neighbor == routeInfo.parent)
                continue;
            neighEtx = entry->info.etx;
            //neighEtx = evaluateEtx(call LinkEstimator.getLinkQuality(entry->neighbor));
            found |= (pathEtx < neighEtx); 
        }
        return found;
    }


    /************************************************************/
    /* Routing Table Functions                                  */

    /* The routing table keeps info about neighbor's route_info,
     * and is used when choosing a parent.
     * The table is simple: 
     *   - not fragmented (all entries in 0..routingTableActive)
     *   - not ordered
     *   - no replacement: eviction follows the LinkEstimator table
     */

    void routingTableInit() {
        routingTableActive = 0;
    }

    /* Returns the index of parent in the table or
     * routingTableActive if not found */
    uint8_t routingTableFind(am_addr_t neighbor) {
        uint8_t i;
        if (neighbor == INVALID_ADDR)
            return routingTableActive;
        for (i = 0; i < routingTableActive; i++) {
            if (routingTable[i].neighbor == neighbor)
                break;
        }
        return i;
    }


    error_t routingTableUpdateEntry(am_addr_t from, am_addr_t parent, uint16_t etx, uint8_t hop_cnt, bool pass_rssi)    {
#if !defined(CTP)
        uint8_t i;
#endif
        uint8_t idx;
        uint16_t  linkEtx;
        routing_table_entry *ne;
        
        linkEtx = evaluateEtx(call LinkEstimator.getLinkQuality(from));

        idx = routingTableFind(from);
        if (idx == routingTableSize) {
            //not found and table is full
            //if (passLinkEtxThreshold(linkEtx))
                //TODO: add replacement here, replace the worst
            //}
            dbg("TreeRouting", "%s FAIL, table full\n", __FUNCTION__);
            return FAIL;
        }
        else if (idx == routingTableActive) {
            //not found and there is space
            if (passLinkEtxThreshold(linkEtx)) {
                ne = &routingTable[idx];
                //atomic {
                ne->neighbor = from;
                ne->info.parent = parent;
                ne->info.etx = etx;
                ne->info.haveHeard = 1;
                ne->info.congested = FALSE;
                ne->info.highlyCongested = FALSE;
                routingTableActive++;
#if !defined(CTP)
                //XL
                //ne->link_etx = 10;
                ne->signed_skew = MAX_INT32;
                ne->entry_idx = 0;
                for (i = 0; i < SEQNO_CACHE_SIZE; i++)
                    ne->seqno_cache[i] = MAX_UINT16;
                ne->in_mac_delay_mean = MAX_UINT16;
                ne->in_mac_delay_var = MAX_UINT16;
                ne->out_mac_delay_mean = MAX_UINT16;
                ne->out_mac_delay_var = MAX_UINT16;
			#if defined(ML) || defined(ML_DAG) || defined(DIRECT_E2E_SAMPLE) || defined(MCMP) || defined(MMSPEED)
                ne->in_link_delay_mean = MAX_UINT16;
                ne->in_link_delay_var = MAX_UINT16;
                ne->out_link_delay_mean = MAX_UINT16;
                ne->out_link_delay_var = MAX_UINT16;
                ne->node_delay_mean = MAX_UINT16;
           	#endif
                //not 0; otherwise total pkts sent is 0 initially, no good for weighted MAC delay
                ne->pkt_sent_cnts = 1;
                for (i = 0; i < DELAY_ETX_LEVEL_CNTS; i++) {
                #ifdef DS_P2
                	e2e_delay_qtl_t *re;
                #endif
                    ne->node_delay_etxs[i].node_delay_mean = MAX_UINT16;
                    ne->node_delay_etxs[i].node_delay_var = MAX_UINT16;
                    ne->node_delay_etxs[i].node_delay_etx = MAX_UINT16;
                #ifdef DIRECT_E2E_SAMPLE
                    ne->latest_node_delay[i] = MAX_UINT16;
                #endif
                #ifdef DS_P2
                	re = &ne->e2e_delay_qtls[i];
					//MD estimation
					re->sample_cnts = 0;
					//(0)
					re->dd_pos_unit[0] = 0;
					//(1)
					re->dd_pos_unit[1] = (MIN_QUANTILE >> 1);
					//(2, 3, 4, ..., MARKER_COUNTS - 3)
					for (i = 2; i < (MARKER_COUNTS - 2); i++) {
						//already scaled
						re->dd_pos_unit[i] = MIN_QUANTILE + (i - 2) * QUANTILE_GRANULARITY;
					}
					re->dd_pos_unit[MARKER_COUNTS - 2] = (((uint32_t)1 << POS_SCALAR_BITS) + MAX_QUANTILE) / 2;
					re->dd_pos_unit[MARKER_COUNTS - 1] = ((uint32_t)1 << POS_SCALAR_BITS);
					for (i = 0; i < MARKER_COUNTS; i++) {
						//height[i] = ((uint32_t)MEAN_LINK_DELAY - (MARKER_COUNTS >> 1) + i) * HEIGHT_SCALAR;
						re->height[i] = (uint32_t)MAX_UINT16 << HEIGHT_SCALAR_BITS;
						re->pos[i] = (i + 1) << POS_SCALAR_BITS;
						//dd_pos[i] = 2 * (NUM_OF_QUANTILES + 1) * dd_pos_unit[i] + (0x1 << POS_SCALAR_BITS);
						re->dd_pos[i] = (MARKER_COUNTS - 1) * re->dd_pos_unit[i] + (0x1 << POS_SCALAR_BITS);
					}
                #endif
                }
                ne->pass_rssi = pass_rssi;
                ne->hop_cnt = hop_cnt;
              //}
#endif
                dbg("TreeRouting", "%s OK, new entry\n", __FUNCTION__);
            } else {
                dbg("TreeRouting", "%s Fail, link quality (%hu) below threshold\n", __FUNCTION__, linkEtx);
            }
        } else {
            //found, just update
            ne = &routingTable[idx];
            //atomic {
                ne->neighbor = from;
                ne->info.parent = parent;
                ne->info.etx = etx;
		        ne->info.haveHeard = 1;
		        
		        ne->pass_rssi = pass_rssi;
		        ne->hop_cnt = hop_cnt;
            //}
            dbg("TreeRouting", "%s OK, updated entry\n", __FUNCTION__);
        }
        return SUCCESS;
    }

    /* if this gets expensive, introduce indirection through an array of pointers */
    error_t routingTableEvict(am_addr_t neighbor) {
        uint8_t idx,i;
        idx = routingTableFind(neighbor);
        if (idx == routingTableActive) 
            return FAIL;
        routingTableActive--;
        for (i = idx; i < routingTableActive; i++) {
            routingTable[i] = routingTable[i+1];    
        } 
        return SUCCESS; 
    }
    /*********** end routing table functions ***************/

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
    default command error_t CollectionDebug.logEventRoute(uint8_t type, am_addr_t parent, uint8_t hopcount, uint16_t etx) {
        return SUCCESS;
    }

    command bool CtpRoutingPacket.getOption(message_t* msg, ctp_options_t opt) {
      return ((getHeader(msg)->options & opt) == opt) ? TRUE : FALSE;
    }

    command void CtpRoutingPacket.setOption(message_t* msg, ctp_options_t opt) {
      getHeader(msg)->options |= opt;
    }

    command void CtpRoutingPacket.clearOption(message_t* msg, ctp_options_t opt) {
      getHeader(msg)->options &= ~opt;
    }

    command void CtpRoutingPacket.clearOptions(message_t* msg) {
      getHeader(msg)->options = 0;
    }

    
    command am_addr_t     CtpRoutingPacket.getParent(message_t* msg) {
      return getHeader(msg)->parent;
    }
    command void          CtpRoutingPacket.setParent(message_t* msg, am_addr_t addr) {
      getHeader(msg)->parent = addr;
    }
    
    command uint16_t      CtpRoutingPacket.getEtx(message_t* msg) {
      return getHeader(msg)->etx;
    }
    command void          CtpRoutingPacket.setEtx(message_t* msg, uint8_t etx) {
      getHeader(msg)->etx = etx;
    }

    command uint8_t CtpInfo.numNeighbors() {
      return routingTableActive;
    }
    command uint16_t CtpInfo.getNeighborLinkQuality(uint8_t n) {
      return (n < routingTableActive)? call LinkEstimator.getLinkQuality(routingTable[n].neighbor):0xffff;
    }
    command uint16_t CtpInfo.getNeighborRouteQuality(uint8_t n) {
      return (n < routingTableActive)? call LinkEstimator.getLinkQuality(routingTable[n].neighbor) + routingTable[n].info.etx:0xfffff;
    }
    command am_addr_t CtpInfo.getNeighborAddr(uint8_t n) {
      return (n < routingTableActive)? routingTable[n].neighbor:AM_BROADCAST_ADDR;
    }

#include "CtpRoutingEngineP_.nc"    
} 
