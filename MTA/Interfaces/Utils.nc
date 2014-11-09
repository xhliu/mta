interface Utils {
    //function declarations
    command am_addr_t getParent();
    command am_addr_t getChild();
   
//    //extended P square algorithm to simultaneously estimate several quantiles
//    //ds_pos_uint: from uint8_t to uint32_t
    command error_t extP2(uint32_t *height, uint32_t *pos, uint32_t *ds_pos, uint16_t *ds_pos_uint, uint32_t delay, uint8_t marker_counts, uint8_t *);
//    
//    //compute node-pair distance                    
//    command uint32_t nodePairDist(am_addr_t x, am_addr_t y);
}
