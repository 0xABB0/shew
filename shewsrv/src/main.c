#include <string.h>

#include <server/server.h>
#include <utils/utils.h>
#include <db/db.h>
#include <app/collection/collection.h>
#include <string/string.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <stdbool.h>

#include <sqlite3.h>

#define MAX_THREADS 4
#define MAX_EVENTS 10
#define PORT 8080

typedef struct {
#ifdef _WIN32
    HANDLE iocp;
    HANDLE thread_handle;
#else
    int epoll_fd;
    pthread_t thread_id;
#endif
    sqlite3* db;
} ThreadData;

volatile bool server_running = true;

void signal_handler(int signum) {
    server_running = false;
}

#ifdef _WIN32
void init_winsock() {
    WSADATA wsaData;
    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        fprintf(stderr, "WSAStartup failed\n");
        exit(EXIT_FAILURE);
    }
}

void set_nonblocking(socket_t sock) {
    u_long mode = 1;
    ioctlsocket(sock, FIONBIO, &mode);
}
#else
void set_nonblocking(socket_t sock) {
    int flags = fcntl(sock, F_GETFL, 0);
    fcntl(sock, F_SETFL, flags | O_NONBLOCK);
}
#endif

char* get_query_param(const char* query, const char* param) {
    static char value[256];
    char* start;
    
    if (!query || !param) return NULL;
    
    start = strstr(query, param);
    if (!start) return NULL;
    
    start += strlen(param) + 1;  // +1 for '='
    int i = 0;
    while (start[i] && start[i] != '&' && start[i] != ' ') {
        value[i] = start[i];
        i++;
    }
    value[i] = '\0';
    
    return value;
}

char* last_index_of(const char* str, char c) {
    char* last = NULL;
    while (*str) {
        if (*str == c) {
            last = (char*)str;
        }
        str++;
    }
    return last;
}


void handle_connection(socket_t client_fd, sqlite3* db) {
    char buffer[BUFFER_SIZE];
    int bytes_read;

    #ifdef _WIN32
    bytes_read = recv(client_fd, buffer, sizeof(buffer) - 1, 0);
    #else
    bytes_read = read(client_fd, buffer, sizeof(buffer) - 1);
    #endif

    if (bytes_read <= 0) {
        CLOSE_SOCKET(client_fd);
        return;
    }

    buffer[bytes_read] = '\0';

    char method[16], path[128];
    sscanf_s(buffer, "%s %s", method, (unsigned)sizeof(method), path, (unsigned)sizeof(path));

    if (strcmp(path, "/") == 0) {
        const char *body = "{\"message\": \"Welcome to the REST server\"}";
        send_response(client_fd, "200 OK", "application/json", body);
    } else if (strcmp(path, "/health") == 0) {
        const char *body = "{\"status\": \"healthy\"}";
        send_response(client_fd, "200 OK", "application/json", body);
    } else if (strncmp(path, str_cc_len("/api/v0/collection")) == 0) {
        handle_collection(client_fd, method, path, db);
    } else {
        const char *body = "{\"error\": \"Not Found\"}";
        send_response(client_fd, "404 Not Found", "application/json", body);
    }

    CLOSE_SOCKET(client_fd);
}

#ifdef _WIN32
unsigned int WINAPI worker_thread(void *arg) {
    ThreadData *thread_data = (ThreadData *)arg;
    DWORD bytes_transferred;
    ULONG_PTR completion_key;
    LPOVERLAPPED overlapped;

    while (server_running) {
        BOOL result = GetQueuedCompletionStatus(
            thread_data->iocp,
            &bytes_transferred,
            &completion_key,
            &overlapped,
            1000  // 1 second timeout to check server_running
        );

        if (!result) {
            if (GetLastError() == WAIT_TIMEOUT) {
                continue;
            }
            break;
        }

        socket_t client_fd = (socket_t)completion_key;
        handle_connection(client_fd, thread_data->db);
    }

    return 0;
}
#else
void *worker_thread(void *arg) {
    ThreadData *thread_data = (ThreadData *)arg;
    struct epoll_event events[MAX_EVENTS];

    while (server_running) {
        int n = epoll_wait(thread_data->epoll_fd, events, MAX_EVENTS, -1);

        for (int i = 0; i < n; i++) {
            if (events[i].events & EPOLLIN) {
                socket_t client_fd = events[i].data.fd;
                handle_connection(client_fd);
                epoll_ctl(thread_data->epoll_fd, EPOLL_CTL_DEL, client_fd, NULL);
            }
        }
    }

    return NULL;
}
#endif

int main() {
    sqlite3* db;
    int result = sqlite3_open("shew.db", &db);
    if (result != SQLITE_OK) {
        fprintf(stderr, "Failed to open database: %s\n", sqlite3_errmsg(db));
        return EXIT_FAILURE;
    }

    if (init_collection_table(db) != 0) {
        sqlite3_close(db);
        return EXIT_FAILURE;
    }

    #ifdef _WIN32
    init_winsock();
    #endif

    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    socket_t server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (SOCKET_ERROR_VAL(server_fd)) {
        fprintf(stderr, "Socket creation failed\n");
        exit(EXIT_FAILURE);
    }

    #ifdef _WIN32
    char opt = 1;
    #else
    int opt = 1;
    #endif

    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt))) {
        fprintf(stderr, "setsockopt failed\n");
        exit(EXIT_FAILURE);
    }

    struct sockaddr_in address;
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    if (SOCKET_ERROR_VAL(bind(server_fd, (struct sockaddr *)&address, sizeof(address)))) {
        fprintf(stderr, "Bind failed\n");
        exit(EXIT_FAILURE);
    }

    if (SOCKET_ERROR_VAL(listen(server_fd, SOMAXCONN))) {
        fprintf(stderr, "Listen failed\n");
        exit(EXIT_FAILURE);
    }

    set_nonblocking(server_fd);

    ThreadData thread_data[MAX_THREADS];
    for (int i = 0; i < MAX_THREADS; i++) {
        thread_data[i].db = db;
    }

    #ifdef _WIN32
    HANDLE iocp = CreateIoCompletionPort(INVALID_HANDLE_VALUE, NULL, 0, 0);
    if (iocp == NULL) {
        fprintf(stderr, "CreateIoCompletionPort failed\n");
        exit(EXIT_FAILURE);
    }

    CreateIoCompletionPort((HANDLE)server_fd, iocp, (ULONG_PTR)server_fd, 0);

    for (int i = 0; i < MAX_THREADS; i++) {
        thread_data[i].iocp = iocp;
        thread_data[i].thread_handle = (HANDLE)_beginthreadex(NULL, 0, worker_thread, &thread_data[i], 0, NULL);
        if (thread_data[i].thread_handle == NULL) {
            fprintf(stderr, "Thread creation failed\n");
            exit(EXIT_FAILURE);
        }
    }
    #else
    for (int i = 0; i < MAX_THREADS; i++) {
        thread_data[i].epoll_fd = epoll_create1(0);
        if (thread_data[i].epoll_fd == -1) {
            perror("epoll_create1 failed");
            exit(EXIT_FAILURE);
        }

        if (pthread_create(&thread_data[i].thread_id, NULL, worker_thread, &thread_data[i]) != 0) {
            perror("pthread_create failed");
            exit(EXIT_FAILURE);
        }
    }
    #endif

    printf("Server started on port %d\n", PORT);

    int current_thread = 0;
    while (server_running) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);

        socket_t client_fd = accept(server_fd, (struct sockaddr *)&client_addr, &client_len);
        
        #ifdef _WIN32
        if (client_fd == INVALID_SOCKET) {
        #else
        if (client_fd < 0) {
        #endif
            if (WSAGetLastError() == WSAEWOULDBLOCK) {
                Sleep(1);  // Small delay to prevent busy waiting
                continue;
            }
            fprintf(stderr, "Accept failed\n");
            continue;
        }

        set_nonblocking(client_fd);

        #ifdef _WIN32
        CreateIoCompletionPort((HANDLE)client_fd, iocp, (ULONG_PTR)client_fd, 0);
        PostQueuedCompletionStatus(iocp, 0, (ULONG_PTR)client_fd, NULL);
        #else
        struct epoll_event event;
        event.events = EPOLLIN | EPOLLET;
        event.data.fd = client_fd;

        if (epoll_ctl(thread_data[current_thread].epoll_fd, EPOLL_CTL_ADD, client_fd, &event) < 0) {
            fprintf(stderr, "epoll_ctl failed\n");
            CLOSE_SOCKET(client_fd);
            continue;
        }

        current_thread = (current_thread + 1) % MAX_THREADS;
        #endif
    }

    // Cleanup
    #ifdef _WIN32
    // Wait for all threads to complete
    for (int i = 0; i < MAX_THREADS; i++) {
        WaitForSingleObject(thread_data[i].thread_handle, INFINITE);
        CloseHandle(thread_data[i].thread_handle);
    }
    CloseHandle(iocp);
    WSACleanup();
    #else
    for (int i = 0; i < MAX_THREADS; i++) {
        pthread_join(thread_data[i].thread_id, NULL);
        close(thread_data[i].epoll_fd);
    }
    #endif

    CLOSE_SOCKET(server_fd);

    sqlite3_close(db);
    return 0;
}