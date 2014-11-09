/*
 * @author: Xiaohui Liu (xiaohui@wayne.edu)
 * @date : 9/25/2011
 * @description: generate injection file according to lite-trace
 * for users two parameters to set: CONVERGE_TIME (when event starts) & MAX_ROUND (# of repetitions of lite-trace)
 */
 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum {
	MAX_LINE_LEN = 100,
	//NetEye 15, Indriya 7
	COLUMNS = 7,
	//to inc/dec traffic
	TRAFFIC_SCALAR = 32,
};

typedef struct {
	int id;
	int time;
} id_time_t;

typedef struct {
	int id;
	char ip_port[256];
} id_ip_port_t;

/*
 * node 1 is the origin
 * param@ x, y: coordinates in 7 by 7 subgrid (right half)
 */
static int coord2Id(int x, int y) {
	return (y * COLUMNS + x + 1);
}

//load id_ip_port table from "id_ip_port.txt"
id_ip_port_t idIPPort[1000];
int id_ip_port_cnts = 0;
void loadTable() {
	int i, id;
	char line[MAX_LINE_LEN];
	char *ip, *port;
	
	FILE *fp = fopen("id_ip_port.txt", "r");
	if (NULL == fp)
		return;
	while (fgets(line, sizeof(line), fp) != NULL) {
		id = atoi(strtok(line, " \t\n"));
		//printf("0 token %d \n", x);

		ip = strtok(NULL," \t\n");
		//printf("1 token %d \n", y);
					
		port = strtok(NULL," \t\n");
		//printf("2 token %s \n", token);
		
		idIPPort[id_ip_port_cnts].id = id;
		strcpy(idIPPort[id_ip_port_cnts].ip_port, ip);
		strcat(idIPPort[id_ip_port_cnts].ip_port, " ");
		strcat(idIPPort[id_ip_port_cnts].ip_port, port);
		id_ip_port_cnts++;
	}
	for (i = 0; i < id_ip_port_cnts; i++) {
		;//printf("%d %s", idIPPort[i].id, idIPPort[i].ip_port);
	}	
}
//find the ip_port of an id
char *lookup(int id) {
	int i;
	
	for (i = 0; i < id_ip_port_cnts; i++) {
		if (idIPPort[i].id == id) {
			//printf("%d %s", idIPPort[i].id, idIPPort[i].ip_port);
			return idIPPort[i].ip_port;
		}
	}
	return NULL;
}


int main() {
	char *token;
	int x, y;
	float t;
	char line[MAX_LINE_LEN];
	char file_name[] = "Trace.txt";
	FILE *fp = fopen(file_name, "r");
	
	id_time_t idTimes[1000];
	int id_time_cnts = 0;
	
	int i, j;
	id_time_t tmp;
	
	//loadTable();
	//lookup(15);
	//return 0;
	
	if (NULL == fp)
		return 1;
	
	while (fgets(line, sizeof(line), fp) != NULL) {
		token = strtok(line, " \t");
		x = token[1] - '0';
		//printf("0 token %d \n", x);

		token = strtok(NULL," \t");
		y = token[0] - '0';
		//printf("1 token %d \n", y);
					
		token = strtok(NULL," \t");
		//printf("2 token %s \n", token);
		
		token = strtok(NULL," \t");
		t = atof(token);
		//printf("3 token %f \n\n", t);
		
		//printf("%d %d %d %d\n", x, y, coord2Id(x, y), (int)t);
		
		idTimes[id_time_cnts].id = coord2Id(x, y);
		//inc traffic bcoz the original lite trace can be too light
		idTimes[id_time_cnts].time = (int)t / TRAFFIC_SCALAR;
		id_time_cnts++;
	}
	close(fp);
	
	//sort
	for (i = 1; i < id_time_cnts; i++) {
		tmp = idTimes[i];
		for (j = i - 1; j >= 0 && idTimes[j].time > tmp.time; j--) {
			idTimes[j + 1] = idTimes[j];
		}
		idTimes[j + 1] = tmp;
	}
/*	for (i = 0; i < id_time_cnts; i++) {*/
/*		printf("%d %d\n", idTimes[i].id, idTimes[i].time);*/
/*	}*/
	//return;
	//load id_ip_port table
	//loadTable();
	
	//look up table
	int round = 0;
	int ROUND_TIME = 15000 / TRAFFIC_SCALAR;
	int CONVERGE_TIME = 0;
	int MAX_ROUND = 300000 / ROUND_TIME;
for (round = 0; round < MAX_ROUND; round++) {
	for (i = 0; i < id_time_cnts; i++) {
		tmp = idTimes[i];
		//if (lookup(tmp.id) != NULL) {
			//NetEye
			//printf("%s %d %d\n", lookup(tmp.id), round, CONVERGE_TIME + tmp.time + round * ROUND_TIME);
			//Indriya
			printf("%d %d\n", tmp.id, CONVERGE_TIME + tmp.time + round * ROUND_TIME);
		//}
	}
}
	return 0;
}
