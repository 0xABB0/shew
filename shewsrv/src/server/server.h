#ifndef SHESRV_SERVER_SERVER_H
#define SHESRV_SERVER_SERVER_H

#ifdef _WIN32
#define _WIN32_WINNT 0x0600
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <mswsock.h>
#include <process.h>
#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "mswsock.lib")
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/epoll.h>
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>
#endif

#ifdef _WIN32
#define SOCKET_ERROR_VAL(x) ((x) == SOCKET_ERROR)
#define CLOSE_SOCKET(x) closesocket(x)
typedef SOCKET socket_t;
typedef int socklen_t;
#else
#define SOCKET_ERROR_VAL(x) ((x) < 0)
#define CLOSE_SOCKET(x) close(x)
typedef int socket_t;
#endif

void send_header(socket_t client_fd, const char *status, const char *content_type);
void send_response(socket_t client_fd, const char *status, const char *content_type, const char *body);

#endif //SHESRV_SERVER_SERVER_H
