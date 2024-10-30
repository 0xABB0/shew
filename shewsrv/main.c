#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <ctype.h>

#define PORT 8080
#define BUFFER_SIZE 4096
#define MAX_SONGS 10

// Mock data structures
typedef struct {
    char songId[50];
    char songName[100];
} Song;

typedef struct {
    char songId[50];
    char images[10][200];  // Up to 10 image URLs per song
    int imageCount;
} SongDetails;

// Global mock data
Song mockSongs[MAX_SONGS] = {
    {"song1", "Moonlight Sonata"},
    {"song2", "Für Elise"},
    {"song3", "Turkish March"},
    {"song4", "Claire de Lune"},
    {"song5", "Nocturne Op. 9 No. 2"}
};

SongDetails mockSongDetails[MAX_SONGS] = {
    {"song1", {
        "https://erikmcclure.com/img/avatar.th.png",
        "http://example.com/moonlight/page2.jpg",
        "http://example.com/moonlight/page3.jpg"
    }, 3},
    {"song2", {
        "http://example.com/furelise/page1.jpg",
        "http://example.com/furelise/page2.jpg"
    }, 2},
    {"song3", {
        "http://example.com/turkish/page1.jpg",
        "http://example.com/turkish/page2.jpg",
        "http://example.com/turkish/page3.jpg",
        "http://example.com/turkish/page4.jpg"
    }, 4},
    {"song4", {
        "http://example.com/claire/page1.jpg",
        "http://example.com/claire/page2.jpg"
    }, 2},
    {"song5", {
        "http://example.com/nocturne/page1.jpg",
        "http://example.com/nocturne/page2.jpg",
        "http://example.com/nocturne/page3.jpg"
    }, 3}
};

// Function to extract query parameters
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

// Function to generate collection JSON response
void generate_collection_response(char* response) {
    strcpy(response, "[");
    for (int i = 0; i < 5; i++) {  // Using 5 mock songs
        char song[200];
        snprintf(song, sizeof(song), 
                "%s{\"songId\":\"%s\",\"songName\":\"%s\"}",
                i == 0 ? "" : ",",
                mockSongs[i].songId,
                mockSongs[i].songName);
        strcat(response, song);
    }
    strcat(response, "]");
}

// Function to generate song details JSON response
void generate_song_details_response(const char* songId, char* response) {
    SongDetails* details = NULL;
    
    // Find the matching song details
    for (int i = 0; i < MAX_SONGS; i++) {
        if (strcmp(mockSongDetails[i].songId, songId) == 0) {
            details = &mockSongDetails[i];
            break;
        }
    }
    
    if (details) {
        strcpy(response, "{\"image\":[");
        for (int i = 0; i < details->imageCount; i++) {
            char image[300];
            snprintf(image, sizeof(image),
                    "%s\"%s\"",
                    i == 0 ? "" : ",",
                    details->images[i]);
            strcat(response, image);
        }
        strcat(response, "]}");
    } else {
        strcpy(response, "{\"error\":\"Song not found\"}");
    }
}

// Function to handle HTTP request and generate response
void handle_request(const char* request, char* response) {
    // Parse request path
    char path[100] = {0};
    sscanf(request, "GET %s", path);
    
    // Set response headers
    char headers[] = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\n\r\n";
    strcpy(response, headers);
    
    // Handle different endpoints
    if (strstr(path, "/v0/collection")) {
        generate_collection_response(response + strlen(headers));
    } 
    else if (strstr(path, "/v0/song")) {
        char* songId = get_query_param(path, "id");
        if (songId) {
            generate_song_details_response(songId, response + strlen(headers));
        } else {
            strcat(response + strlen(headers), "{\"error\":\"Missing song ID\"}");
        }
    }
    else {
        // Handle unknown endpoint
        strcpy(response + strlen(headers), "{\"error\":\"Unknown endpoint\"}");
    }
}

int main() {
    int server_fd, client_fd;
    struct sockaddr_in server_addr, client_addr;
    int addrlen = sizeof(client_addr);
    char buffer[BUFFER_SIZE] = {0};
    char response[BUFFER_SIZE] = {0};
    
    // Create socket
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }
    
    // Set socket options
    int opt = 1;
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt))) {
        perror("Setsockopt failed");
        exit(EXIT_FAILURE);
    }
    
    // Configure server address
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);
    
    // Bind socket
    if (bind(server_fd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        perror("Bind failed");
        exit(EXIT_FAILURE);
    }
    
    // Listen for connections
    if (listen(server_fd, 3) < 0) {
        perror("Listen failed");
        exit(EXIT_FAILURE);
    }
    
    printf("Server running on port %d...\n", PORT);
    
    while (1) {
        // Accept connection
        if ((client_fd = accept(server_fd, (struct sockaddr *)&client_addr, (socklen_t*)&addrlen)) < 0) {
            perror("Accept failed");
            continue;
        }
        
        // Read request
        read(client_fd, buffer, BUFFER_SIZE);
        printf("Received request: %s\n", buffer);
        
        // Handle request and generate response
        memset(response, 0, BUFFER_SIZE);
        handle_request(buffer, response);
        
        // Send response
        write(client_fd, response, strlen(response));
        printf("Sent response: %s\n", response);
        
        // Close connection
        close(client_fd);
        memset(buffer, 0, BUFFER_SIZE);
    }
    
    return 0;
}
