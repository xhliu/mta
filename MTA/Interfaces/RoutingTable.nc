/*  Provides an interface to access neighbor table
 *  @author Xiaohui Liu
 *  @created: 2010/02/24 $
 */
 #include "LinkEstimator.h"
 
interface RoutingTable {
    //cache seq# of the latest received packets
    //command bool lookupCache(am_addr_t nb, uint16_t seq);
    //command error_t insertCache(am_addr_t nb, uint16_t seq);
    
    //command error_t sampleMacDelay(am_addr_t nb, bool inbound, uint16_t seqno, uint16_t mac_delay_sample);
    command error_t sampleMacDelay(am_addr_t nb, bool inbound, uint16_t seqno, uint16_t mac_delay_sample, uint16_t link_delay_sample);
    //sample pkt time at sender side
    //command error_t sampleTxMacDelay(am_addr_t nb, uint16_t tx_mac_delay_sample);
    //piggyback inbound Mac delays to sender
    command void getMacDelays(mac_delay_t in_mac_delays[], uint8_t);
    command void setMacDelays(am_addr_t nb, mac_delay_t out_mac_delays[], uint8_t);
    
    //
    command uint8_t getParents(uint32_t relative_deadline, uint16_t e2e_pdr_req, am_addr_t parents[], uint16_t parent_e2e_pdr_reqs[]);
    //diffusion
    //command error_t setNodeDelayEtxs(am_addr_t nb, delay_etx_t node_delay_etxs[]);
    command error_t postGetNodeDelayEtxsTasks(bool is_router_called_, am_addr_t src, uint16_t src_seqno);
    event void getNodeDelayEtxsTasksDone();
    command error_t setNodeDelayEtxs(am_addr_t nb, nx_uint16_t node_delay_mean, delay_etx_t node_delay_etxs[]);
    //diffusion + parent selection
    command am_addr_t getNodeDelayEtxs(bool is_beacon, nx_uint16_t *node_delay_mean, delay_etx_t my_node_delay_etxs[], bool *, bool *, uint32_t relative_deadline);
    
//    command uint16_t getNbLinkEtx(am_addr_t neighbor);
//    command void setNbLinkEtx(am_addr_t neighbor, uint16_t link_etx);
    //sync
    //set neighbor's skew
    command void setNbTimeSkew(am_addr_t nb, int32_t skew);
    //convert neighbor time to local time
    command uint32_t nb2LocalTime(am_addr_t nb, uint32_t nb_local_time);
    
    command void logDAG();
}
