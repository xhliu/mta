#include <stdio.h>
#include <sys/types.h>
#include <dirent.h>
#include <string.h>

enum {
	ID_COLUMN = 10,
};

/*
 * input: a file
 * output: <node id, ip, port>
 */
void file2IdIPPort(char *file_name) {
	int i;
	unsigned int id;
	char *ip, *port;
	char dst[256] = "/Users/xiaohui/Downloads/Jobs/4951/";
	FILE *fp = fopen(strcat(dst, file_name), "r");
	
//	printf("%s\n", dst);
	//node id
	if (fp != NULL) {
		for (i = 0; i < ID_COLUMN; i++) {
			fscanf(fp, "%x", &id);
		}
		
		printf("%d\t", id);
	
	}
	//ip + port: e.g., Job4936-10.0.0.1-11.txt
	//remove .txt
	char *end;
	//this assumes 't' is in "txt"
	end = strchr(file_name, 't');
	if (end)
		*(end - 1) = '\0';
	//printf("%s\n", file_name);
	//return;
	strtok(file_name, "-");
	ip = strtok(NULL, "-");
	printf("%s\t", ip);
	port = strtok(NULL, "-");
	//printf("%d\n", port[0] - '0');
	printf("%d\n", atoi(port));
	
	fclose(fp);
}

int main(void)
{
    DIR *mydir = opendir("/Users/xiaohui/Downloads/Jobs/4951/");

    struct dirent *entry = NULL;
    
    while((entry = readdir(mydir))) /* If we get EOF, the expression is 0 and
                                     * the loop stops. */
    {
        if (0 == strcmp(entry->d_name, ".") || 0 == strcmp(entry->d_name, ".."))
        	continue;
        //printf("%s\n", entry->d_name);
        file2IdIPPort(entry->d_name);
    }

    closedir(mydir);

    return 0;
}
