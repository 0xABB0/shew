#include "server.h"

#include <stdio.h>

#define BUFFER_SIZE 4096

void send_response(socket_t client_fd, const char *status, const char *content_type, const char *body) {
    char response[BUFFER_SIZE];
    snprintf(response, sizeof(response),
             "HTTP/1.1 %s\r\n"
             "Content-Type: %s\r\n"
             "Content-Length: %zu\r\n"
             "Connection: close\r\n"
             "\r\n"
             "%s",
             status, content_type, strlen(body), body);

    #ifdef _WIN32
    send(client_fd, response, (int)strlen(response), 0);
    #else
    write(client_fd, response, strlen(response));
    #endif
}
