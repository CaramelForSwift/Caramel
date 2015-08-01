#include <fcntl.h>
#include <sys/ioctl.h>
#include <netinet/in.h>

int SocketUtils_fcntl(int fildes, int cmd, int val) {
	return fcntl(fildes, cmd, val);
}

int SocketUtils_ioctl(int fildes, unsigned long request, int *val) {
	return ioctl(fildes, request, val);
}

uint16_t SocketUtils_htons(uint16_t port) {
	return htons(port);
}