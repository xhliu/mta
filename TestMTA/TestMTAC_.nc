#ifdef DEBUG
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

void convertLoc() {
	uint8_t i;
	
	for (i = 1; i < sizeof(locations) / sizeof(locations[0]); i++) {
		dbg_clear("DBG", "%d\t%d\t%d\n", locations[i].x, locations[i].y, locations[i].z);
	}
}
#else	//DEBUG
 
uint8_t sample_cnts;				//# of samples gathered; sort locally using height[]
uint32_t height[MARKER_COUNTS];
uint32_t pos[MARKER_COUNTS];
uint32_t dd_pos[MARKER_COUNTS];      //desired position
uint16_t dd_pos_unit[MARKER_COUNTS]; //unit increment of desired position

void initP2() {
	uint8_t i;
	//MD estimation
	sample_cnts = 0;
	//(0)
	dd_pos_unit[0] = 0;
	//(1)
	dd_pos_unit[1] = (MIN_QUANTILE >> 1);
	//(2, 3, 4, ..., MARKER_COUNTS - 3)
	for (i = 2; i < (MARKER_COUNTS - 2); i++) {
		//already scaled
		dd_pos_unit[i] = MIN_QUANTILE + (i - 2) * QUANTILE_GRANULARITY;
	}
	dd_pos_unit[MARKER_COUNTS - 2] = (((uint32_t)1 << POS_SCALAR_BITS) + MAX_QUANTILE) / 2;
	dd_pos_unit[MARKER_COUNTS - 1] = ((uint32_t)1 << POS_SCALAR_BITS);
	for (i = 0; i < MARKER_COUNTS; i++) {
		//height[i] = ((uint32_t)MEAN_LINK_DELAY - (MARKER_COUNTS >> 1) + i) * HEIGHT_SCALAR;
		height[i] = (uint32_t)MAX_UINT16 << HEIGHT_SCALAR_BITS;
		pos[i] = (i + 1) << POS_SCALAR_BITS;
		//dd_pos[i] = 2 * (NUM_OF_QUANTILES + 1) * dd_pos_unit[i] + (0x1 << POS_SCALAR_BITS);
		dd_pos[i] = (MARKER_COUNTS - 1) * dd_pos_unit[i] + (0x1 << POS_SCALAR_BITS);
	}
}
 
error_t extP2(uint32_t *height, uint32_t *pos, uint32_t *ds_pos, uint16_t *ds_pos_uint, delay_t delay, uint8_t marker_counts, uint8_t *sample_cnts_p) {
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
    return SUCCESS;
}

//compute distance between nodes
enum {
	COLUMNS = 15,
	ROWS = 7,
};

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

static uint32_t nodeDist(am_addr_t m, am_addr_t n) {
	pos_3d_t m_pos, n_pos;
	
	m_pos = locations[m];
	n_pos = locations[n];
	
	return ((uint32_t)isqrt((m_pos.x - n_pos.x) * (m_pos.x - n_pos.x) + (m_pos.y - n_pos.y) * (m_pos.y - n_pos.y) + (m_pos.z - n_pos.z) * (m_pos.z - n_pos.z)));
}


static uint32_t nodeDist(am_addr_t m, am_addr_t n) {
    uint32_t m_x, n_x, m_y, n_y;
    
    m--;
    n--;
    m_x = m % COLUMNS;
    n_x = n % COLUMNS;
    m_y = m / COLUMNS;
    n_y = n / COLUMNS;
    
    return ((uint32_t)isqrt((m_x - n_x) * (m_x - n_x) + (m_y - n_y) * (m_y - n_y)));
}


inline uint32_t ipow(uint32_t x, uint8_t n) {
	uint8_t i;
	uint32_t product = 1;
	
	for (i = 0; i < n; i++) {
		product *= x;
	}
	return product;
}

//integer nth root: the largest y s.t. y ^ n <= x
uint32_t inthRoot(uint32_t x, uint8_t n) {
	uint32_t lo, hi, mid;
	uint32_t result;
	
	if (0 == x || 1 == x)
		return x;
	
	//init
	lo = 1;
	hi = x;
	
	//binary search
	while (lo <= hi) {
		dbg("DEBUG", "[%u, %u]\n", lo, hi);
		mid = (lo + hi) / 2;
		result = ipow(mid, n);

		if (x == result) {
			//found
			return mid;
		} else if (x < result) {
			//search to left
			hi = mid - 1;
		} else {
			//search to right
			lo = mid + 1;
		}
	}
	//lo > hi if reach here
	return hi;
}

static void heapSort(e2e_delay_etx_t arr[], unsigned int N);

void diffuse() {
    uint8_t i;
    uint8_t idx = 0;
    
    uint8_t valid_entry_cnts = 0;
    uint8_t filtered_valid_entry_cnts = 0;
	
	bool beyond_deadline = FALSE;
	uint16_t rt_min_etx;
	am_addr_t parent = INVALID_ADDR;
	uint32_t rltv_deadline = 0;
	
    e2e_delay_etx_t s[] =  
                            {{1, 0, 0, 0, 1, 50},
                            {2, 0, 0, 0, 2, 40},
                            {3, 0, 0, 0, 3, 30},
                            {4, 0, 0, 0, 4, 20},
                            {5, 0, 0, 0, 50, 10},
                            {6, 0, 0, 0, 60, 9},};  
    valid_entry_cnts = sizeof(s) / sizeof(s[0]);
    //step 2): sort
    heapSort(s, valid_entry_cnts);
    for (i = 0; i < valid_entry_cnts; i++) {
        dbg("DIFFUSE", "%s 1: <%hu, %u, %u>\n", __FUNCTION__, s[i].nb, s[i].e2e_delay_qtl, s[i].e2e_delay_etx);
    }
	dbg("DIFFUSE", "\n");
    //step 3): filter: in place(s[0 .. valid_entry_cnts - 1]), no additional space required 
    //special case: min delay entry is directly admitted
    filtered_valid_entry_cnts = 1;
    rt_min_etx = MAX_UINT16;
    for (i = 1; i < valid_entry_cnts; i++) {
    	//only admit entries w/ larger delay and smaller etx
    	if (s[i].e2e_delay_qtl == s[filtered_valid_entry_cnts - 1].e2e_delay_qtl) {
    		//special case: if same delay, use one w/ smallest etx
    		if (s[i].e2e_delay_etx < s[filtered_valid_entry_cnts - 1].e2e_delay_etx)
    			//replace
    			s[filtered_valid_entry_cnts - 1] = s[i];
    	} else if (s[i].e2e_delay_etx < s[filtered_valid_entry_cnts - 1].e2e_delay_etx) {
    		//must have larger delay if reach here
    		//add
    		s[filtered_valid_entry_cnts++] = s[i];
    	}
    	if (!beyond_deadline)
			if (s[i].e2e_delay_qtl <= rltv_deadline) {
				if (rt_min_etx > s[i].e2e_delay_etx) {
					parent = s[i].nb;
					rt_min_etx = s[i].e2e_delay_etx;
				}
			} else
				//bcoz delay increases; entries afterwards also violate deadline, thus unnecessary to keep looking
				beyond_deadline = TRUE;
    }
    for (i = 0; i < filtered_valid_entry_cnts; i++) {
        dbg("DIFFUSE", "%s 2: <%hu, %u, %u>\n", __FUNCTION__, s[i].nb, s[i].e2e_delay_qtl, s[i].e2e_delay_etx);
    }
	dbg("DIFFUSE", "\n");
    
    //step 4): aggregate: s[0 .. filtered_valid_entry_cnts - 1]
    if (filtered_valid_entry_cnts <= DELAY_ETX_LEVEL_CNTS) {
		for (i = 0; i < filtered_valid_entry_cnts; i++) {
		    dbg("DIFFUSE", "%s 3: <%hu, %u, %u>\n", __FUNCTION__, s[i].nb, s[i].e2e_delay_qtl, s[i].e2e_delay_etx);
		}
		dbg("DIFFUSE", "\n");
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
         //store indices in filtered s table
         uint8_t idxs[DELAY_ETX_LEVEL_CNTS];
         uint8_t max_1_gap_idx, min_2_gap_idx, entry_1_gap_middle_idx;
         uint32_t max_entry_1_gap, min_entry_2_gap, entry_1_gap, entry_2_gap;
         //TODO
         uint32_t idx_interval = (filtered_valid_entry_cnts - 1) / (DELAY_ETX_LEVEL_CNTS - 1);
         
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
                //ASSERT(s is increasing)
                entry_1_gap = s[idxs[i + 1]].e2e_delay_qtl - s[idxs[i]].e2e_delay_qtl;
                if (max_entry_1_gap < entry_1_gap) {
                    max_entry_1_gap = entry_1_gap;
                    max_1_gap_idx = i;
                }
                if (i < (DELAY_ETX_LEVEL_CNTS - 2)) {
                    entry_2_gap = s[idxs[i + 2]].e2e_delay_qtl - s[idxs[i]].e2e_delay_qtl;
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
            if (idx >= filtered_valid_entry_cnts) {
                dbg("DIFFUSE", "%s: assetion error!\n", __FUNCTION__);
                continue;
            }
            dbg("DIFFUSE", "%s: <%hu, %u, %u>\n", __FUNCTION__, s[idx].nb, s[idx].e2e_delay_qtl, s[idx].e2e_delay_etx);
        }
    }
    dbg("DIFFUSE", "parent %hu\n", parent);
}

static void heapSort(e2e_delay_etx_t arr[], unsigned int N) {
    e2e_delay_etx_t tmp; /* the temporary value */
    unsigned int n = N, parent = N/2, idx, child; /* heap indexes */
    /* loop until array is sorted */
    while (1) { 
        if (parent > 0) { 
            /* first stage - Sorting the heap */
            tmp = arr[--parent];  /* save old value to tmp */
        } else {
            /* second stage - Extracting elements in-place */
            n--;                /* make the heap smaller */
            if (n == 0) {
                return; /* When the heap is empty, we are done */
            }
            tmp = arr[n];         /* save lost heap entry to temporary */
            arr[n] = arr[0];    /* save root entry beyond heap */
        }
        /* insert operation - pushing tmp down the heap to replace the parent */
        idx = parent; /* start at the parent index */
        child = idx * 2 + 1; /* get its left child index */
        while (child < n) {
            /* choose the largest child */
            if (child + 1 < n  &&  arr[child + 1].e2e_delay_qtl > arr[child].e2e_delay_qtl) {
                child++; /* right child exists and is bigger */
            }
            /* is the largest child larger than the entry? */
            if (arr[child].e2e_delay_qtl > tmp.e2e_delay_qtl) {
                arr[idx] = arr[child]; /* overwrite entry with child */
                idx = child; /* move index to the child */
                child = idx * 2 + 1; /* get the left child and go around again */
            } else {
                break; /* tmp's place is found */
            }
        }
        /* store the temporary value at its new location */
        arr[idx] = tmp; 
    }
}


typedef struct {
	uint8_t key;
	uint8_t value;
} key_value_t;
typedef struct {
	am_addr_t nb;
	bool congested;
	uint16_t e2e_delay_mean;
	uint16_t e2e_delay_var;
	uint16_t e2e_delay_qtl;
	//min ETX over all paths w/ the preceding delay (or smaller)
	uint16_t e2e_delay_etx;
} e2e_delay_etx_t;
e2e_delay_etx_t s[] =  {{1, 0, 0, 0, 5, 0},
						{2, 0, 0, 0, 1, 0},
						{3, 0, 0, 0, 3, 0},
						{4, 0, 0, 0, 2, 0}};
//key_value_t s[] = {{2, 1}, {4, 5}, {3, 6}, {7, 3}, {3, 8}};
static void heapSort(e2e_delay_etx_t arr[], unsigned int N);

	enum {
		DSN_CACHE_SIZE = 4,
		INVALID_TIMESTAMP = 0xFFFFFFFF,
	};

	
	typedef struct {
		nxle_uint8_t dsn;
		uint32_t timestamp;
	} pkt_timestamp_t;
	
	uint8_t cache_head = 0;
	uint8_t cache_size = 0;
	pkt_timestamp_t cache[DSN_CACHE_SIZE];
	
	static uint32_t lookup(nxle_uint8_t dsn) {
		uint8_t i, pos;
		
		for (i = 0; i < cache_size; i++) {
			pos = (cache_head + i) % DSN_CACHE_SIZE;
			if (cache[pos].dsn == dsn)
				return cache[pos].timestamp;
		}
		return INVALID_TIMESTAMP;
	}
	static void insert(nxle_uint8_t dsn, uint32_t timestamp) {
		uint8_t i;
		uint8_t pos = (cache_head + cache_size) % DSN_CACHE_SIZE;
		
		cache[pos].dsn = dsn;
		cache[pos].timestamp = timestamp;
		if (DSN_CACHE_SIZE == cache_size) {
			//full; override the oldest element
			cache_head = (cache_head + 1) % DSN_CACHE_SIZE;
		} else
			cache_size++;
		
		dbg_clear("cache", "cache: ");
		for (i = 0; i < cache_size; i++) {
			pos = (cache_head + i) % DSN_CACHE_SIZE;
			dbg_clear("cache", "(%u, %u), ", cache[pos].timestamp, cache[pos].timestamp);
		}
		dbg_clear("cache", "\n");
	}
void testEDFQueue() {
    uint8_t i;
    for (i = 0; i < (DSN_CACHE_SIZE * 2); i++)
        insert(i, i * 100);
    dbg("cache", "%u\n", lookup(DSN_CACHE_SIZE * 2 - 1));
    dbg("cache", "%u\n", lookup(DSN_CACHE_SIZE * 2));
    dbg("cache", "%u\n", lookup(0));
/*
    uint8_t i;
    uint32_t deadline = 0;
    uint16_t a, b;
    //enqueue
    for (i = 0; i < EDF_QUEUE_SIZE; i++) {
        //deadline = call Random.rand16() % 255;
        deadline = i;
        call Queue.enqueue(i, deadline, &a, &b);
        dbg("EDFQueueDbg", "element <%u, %u> in\n", i, deadline);
    }
    //dequeue
    for (i = 0; i < EDF_QUEUE_SIZE; i++) {
        dbg("EDFQueueDbg", "element %u out\n", call Queue.dequeue());
    }
    uint8_t i;
    uint32_t start_time;
    for (i = 0; i < EDF_QUEUE_SIZE; i++) {
        start_time = call Timer.getNow();
        call Queue.enqueue(i, 0);
        call UartLog.logEntry(DBG_FLAG, DBG_EDF_FLAG, i, call Timer.getNow() - start_time);
    }
    uint16_t a, b;
    call Queue.enqueue(1, 4, &a, &b);
    call Queue.enqueue(2, 3, &a, &b);
    call Queue.enqueue(3, 2, &a, &b);
    call Queue.enqueue(4, 1, &a, &b);
    dbg("EDFQueueDbg", "element %u out\n", call Queue.dequeue());
    dbg("EDFQueueDbg", "element %u out\n", call Queue.dequeue());
    dbg("EDFQueueDbg", "element %u out\n", call Queue.dequeue());
    dbg("EDFQueueDbg", "element %u out\n", call Queue.dequeue());    
*/
}
#endif
