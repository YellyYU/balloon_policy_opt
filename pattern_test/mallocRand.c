#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <errno.h>
#include <limits.h>
#include <signal.h>
#include <time.h>

time_t timer;
char time_buffer[26];
struct tm* tm_info;
long count=0;
void sigint(int dunno){
   time(&timer);
   tm_info = localtime(&timer);
   strftime(time_buffer, 26, "%Y-%m-%d %H:%M:%S", tm_info);
   printf("%s Done work:%ld\n", time_buffer, count); 
   exit(1);
}

int main(int argc,char **argv[])
{

	int real_size = 0;
	volatile int * ptr;
    signal(SIGINT, sigint);
	if(argc == 1)
		printf("Usage : ./mallocBomb <[infinite] -i>  or ./mallocBomb <itterations>");
	else
	{
		int i=0,k=0,j,t;

		{
			ptr=NULL;
			k =atoi((const char *)argv[1]);
			ptr=(int *)calloc(k,1024);
			if(ptr != NULL)
			{
				if(errno == EAGAIN)
				{
					printf("WARNING EAGAIN: Limit on the total number of processes has been reached\n");
				}
				else if(errno == ENOMEM)
				{
					printf("WARNING ENOMEM: There is not enough swamp space\n");
				}
				else{
					for (j=0;j<100;j++){
						for(i=0; i < k; i++)
						{
							int index=rand()%k;
			                                count++;
							*(ptr+256*index) = index;
						}
					}
    					printf("all work done\n");
				}
			}else{
				printf("Opps, calloc return NULLd\n");
			}
		}
	}
    //force the program killed by the tester
    sleep(10000);
    printf("[Warn] mallocRam should not reach here!!\n");
	return 0;
}
