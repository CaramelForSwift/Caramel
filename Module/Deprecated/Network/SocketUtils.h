#include <sys/types.h>
#include "uv.h"

#ifndef SocketUtils_c
#define SocketUtils_c

int SocketUtils_fcntl(int fildes, int cmd, int val);
int SocketUtils_ioctl(int fildes, unsigned long request, int *val);
uint16_t SocketUtils_htons(uint16_t port);

#endif /* SocketUtils_c */
