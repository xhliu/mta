//#include "SharedTypes.h"

module UtilsC {
	provides {
		interface Utils;
//		interface GlobalTimer;
	}

//	uses {
//        interface UartLog;
//        interface Timer<TMilli> as LocalTimer;
        //interface Alarm<T32khz, uint32_t> as LocalTimer;
//    }
}

implementation{
#ifndef TOSSIM
    //am_addr_t topology[] = {15, 41, 100, 79, 76};
    am_addr_t topology[] = {15, 42, 60, 79, 76};
#else
    am_addr_t topology[] = {0, 1, 2, 8, 18, 24};
#endif

    command am_addr_t Utils.getParent() {
        uint8_t i;
        for (i = 0; i < (sizeof(topology) / sizeof(topology[0])); i++)
            if (TOS_NODE_ID == topology[i]) {
                if (i > 0)
                    return topology[i - 1];
                else
                    return INVALID_ADDR;
            }
        return INVALID_ADDR;
    }
    
    command am_addr_t Utils.getChild() {
        uint8_t i;
        for (i = 0; i < (sizeof(topology) / sizeof(topology[0])); i++)
            if (TOS_NODE_ID == topology[i]) {
                if (i < (sizeof(topology) / sizeof(topology[0]) - 1))
                    return topology[i + 1];
                else
                    return INVALID_ADDR;
            }
        return INVALID_ADDR;
    }
    
    //extended P square algorithm to simultaneously estimate several quantiles
    //height, pos, ds_pos, ds_pos_uint: pointer to variables for estimating the quantiles of a metric 
    //marker_counts: # of markers [0, marker_counts - 1]
    //sample: latest sample
    //caution: sample better not exceeding 2048 (2 ^ 11)    
command error_t Utils.extP2(uint32_t *height, uint32_t *pos, uint32_t *ds_pos, uint16_t *ds_pos_uint, 
                        	delay_t delay, uint8_t marker_counts, uint8_t *sample_cnts_p) {
    int8_t i, k;
    delay_t sample;
    uint8_t sample_cnts = *sample_cnts_p;
    //bool in_order;
    
    if (sample_cnts < marker_counts) {
        sample = (delay << HEIGHT_SCALAR_BITS);
        //find the right slot
        for (i = 0; i < sample_cnts; i++) {
            if (sample < height[i])
                break;
        }
        //adjust larger items
        for (k = sample_cnts - 1; k >= i; k--)
            height[k + 1] = height[k];
        //place the iterm
        height[i] = sample;
        *sample_cnts_p = ++sample_cnts;
    } else {
        int32_t pos_unit = (0x1 << POS_SCALAR_BITS);
        //bool valid = (delay > ((0x1 << (32 - scalar_bits)) - 1));
        bool valid = (delay > ((uint32_t)INVALID_DELAY / HEIGHT_SCALAR));
        //uint8_t marker_counts = 2 * qtl_counts + 3;
        if (NULL == height || NULL == pos || NULL == ds_pos || NULL == ds_pos_uint || valid) {
            //call UartLog.log(FAIL_FLAG_1, valid, valid2);
            return FAIL;
        }
        //scale sample
        sample = (delay << HEIGHT_SCALAR_BITS);
        //udpate upon arrival of each new sample
        //find the cell [height(k), height(k + 1)) new sample falls in 
        //k in [0, marker_counts - 2]
        if (sample < height[0]) {
            height[0] = sample;
            k = 0;
        } else if (sample >= height[marker_counts - 1]) {
            height[marker_counts - 1] = sample;
            k = marker_counts - 2;
        } else {
            for (k = 0; k < (marker_counts - 1); k++) {
                if (sample < height[k + 1])
                    break;
            }
        }
        
        // increment positions of markers (k + 1) through marker_counts and desired positions for all markers
        for (i = 0; i < marker_counts; i++) {
            if (i >= (k + 1)) {
                pos[i] += pos_unit;
            }
            ds_pos[i] += ds_pos_uint[i];
        }
        
        //adjust middle markers [1 , marker_counts - 2] if necessary, excluding boundary markers
        for (i = 1; i < (marker_counts - 1); i++) {
            int32_t d = (int32_t)ds_pos[i] - (int32_t)pos[i];
            int32_t lower_d = (int32_t)pos[i] - (int32_t)pos[i - 1];
            int32_t upper_d = (int32_t)pos[i + 1] - (int32_t)pos[i];
            
            if ((0 == lower_d) || (0 == upper_d) || (0 == (lower_d + upper_d))) {
                //call UartLog.log(FAIL_FLAG_2, lower_d, upper_d);
                return FAIL;
            }
            if (((d >= pos_unit) && (upper_d > pos_unit)) || ((d <= (-pos_unit)) && (lower_d > pos_unit))) {
                uint32_t new_height;
                int32_t sign = (d > 0) ? 1 : -1;
                int32_t scaled_sign = (sign << POS_SCALAR_BITS);
                //parabolic interpolation
                //XL: consider (height[i + 1] - height[i]) if memory has to be reduced
                new_height = (int32_t)height[i] +  sign
                            * (((lower_d + scaled_sign) * ((int32_t)height[i + 1] - (int32_t)height[i]) / upper_d 
                            + (upper_d - scaled_sign) * ((int32_t)height[i] - (int32_t)height[i - 1]) / lower_d) 
                            << POS_SCALAR_BITS) / (lower_d + upper_d);
                    
                //if markers still in order
                if ((new_height > height[i - 1]) && (new_height < height[i + 1])) {
                    height[i] = new_height;
                } else {
                    //linear interpolation
                    //height[i] += scaled_sign * ((int32_t)height[i + sign] - (int32_t)height[i]) / ((int32_t)pos[i + sign] - (int32_t)pos[i]);
                    height[i] = (int32_t)height[i] + sign * (((int32_t)height[i + sign] - (int32_t)height[i]) << POS_SCALAR_BITS) / ((int32_t)pos[i + sign] - (int32_t)pos[i]);
                }
                
                pos[i] = (int32_t)pos[i] + scaled_sign;
            }
        }
    }
    //sanity check
//     in_order = TRUE;
//     for (i = 0; i < (marker_counts - 1); i++) {
//         if (height[i] > height[i + 1]) {
//             in_order = FALSE;
//             break;
//         }
//     }
    //if (!in_order)
    //call UartLog.logEntry(DEBUG_FLAG, DBG_OPMD_ORDER, in_order, height[marker_counts - 1] >> HEIGHT_SCALAR_BITS);
    return SUCCESS;
}
///*    
//    command error_t Utils.extP2(uint32_t *height, uint32_t *pos, uint32_t *ds_pos, uint16_t *ds_pos_uint, 
//                        delay_t delay, uint8_t marker_counts) {
//        uint8_t i, k;
//        delay_t sample;
//        int32_t pos_unit = (0x1 << POS_SCALAR_BITS);
//        //bool valid = (delay > ((0x1 << (32 - scalar_bits)) - 1));
//        bool valid = (delay > ((uint32_t)INVALID_DELAY >> HEIGHT_SCALAR_BITS));
//        //uint8_t marker_counts = 2 * qtl_counts + 3;
//        if (NULL == height || NULL == pos || NULL == ds_pos || NULL == ds_pos_uint || valid) {
//            //call UartLog.log(FAIL_FLAG_1, valid, valid2);
//            return FAIL;
//        }
//        //scale sample
//        sample = (delay << HEIGHT_SCALAR_BITS);
//        //udpate upon arrival of each new sample
//        //find the cell [height(k), height(k + 1)) new sample falls in 
//        //k in [0, marker_counts - 2]
//        if (sample < height[0]) {
//            height[0] = sample;
//            k = 0;
//        } else if (sample >= height[marker_counts - 1]) {
//            height[marker_counts - 1] = sample;
//            k = marker_counts - 2;
//        } else {
//            for (k = 0; k < (marker_counts - 1); k++) {
//                if (sample < height[k + 1])
//                    break;
//            }
//        }
//        
//        // increment positions of markers (k + 1) through marker_counts and desired positions for all markers
//        for (i = 0; i < marker_counts; i++) {
//            if (i >= (k + 1)) {
//                pos[i] += pos_unit;
//            }
//            ds_pos[i] += ds_pos_uint[i];
//        }
//        
//        //adjust middle markers [1 , marker_counts - 2] if necessary, excluding boundary markers
//        for (i = 1; i < (marker_counts - 1); i++) {
//            int32_t d = (int32_t)ds_pos[i] - (int32_t)pos[i];
//            int32_t lower_d = (int32_t)pos[i] - (int32_t)pos[i - 1];
//            int32_t upper_d = (int32_t)pos[i + 1] - (int32_t)pos[i];
//            
//            if ((0 == lower_d) || (0 == upper_d) || (0 == (lower_d + upper_d))) {
//                //call UartLog.log(FAIL_FLAG_2, lower_d, upper_d);
//                return FAIL;
//            }
//            if (((d >= pos_unit) && (upper_d > pos_unit)) || ((d <= (-pos_unit)) && (lower_d > pos_unit))) {
//                uint32_t new_height;
//                int32_t sign = (d > 0) ? 1 : -1;
//                int32_t scaled_sign = (sign << POS_SCALAR_BITS);
//                //parabolic interpolation
//                //XL: consider (height[i + 1] - height[i]) if memory has to be reduced
//                new_height = (int32_t)height[i] +  sign
//                            * (((lower_d + scaled_sign) * ((int32_t)height[i + 1] - (int32_t)height[i]) / upper_d 
//                            + (upper_d - scaled_sign) * ((int32_t)height[i] - (int32_t)height[i - 1]) / lower_d) 
//                            << POS_SCALAR_BITS) / (lower_d + upper_d);
//                    
//                //if markers still in order
//                if ((new_height > height[i - 1]) && (new_height < height[i + 1])) {
//                    height[i] = new_height;
//                } else {
//                    //linear interpolation
//                    //height[i] += scaled_sign * ((int32_t)height[i + sign] - (int32_t)height[i]) / ((int32_t)pos[i + sign] - (int32_t)pos[i]);
//                    height[i] = (int32_t)height[i] + sign * (((int32_t)height[i + sign] - (int32_t)height[i]) << POS_SCALAR_BITS) / ((int32_t)pos[i + sign] - (int32_t)pos[i]);
//                }
//                
//                pos[i] = (int32_t)pos[i] + scaled_sign;
//            }
//        }
//        return SUCCESS;
//    }
//*/    
//    //compute node-pair distance                    
//    command uint32_t Utils.nodePairDist(am_addr_t m, am_addr_t n) {
//        uint32_t m_x, n_x, m_y, n_y;
//        m--;
//        n--;
//        m_x = m % COLUMNS;
//        n_x = n % COLUMNS;
//        m_y = m / COLUMNS;
//        n_y = n / COLUMNS;
//        
//        return ((uint32_t)isqrt((m_x - n_x) * (m_x - n_x) + (m_y - n_y) * (m_y - n_y)));
//    }
}
