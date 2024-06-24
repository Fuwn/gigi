#define _GNU_SOURCE
/* #define GIGI_DYNAMIC */

#include <asm-generic/socket.h>
#include <bits/types/FILE.h>
#include <netinet/in.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

enum {
  MAXIMUM_COMMAND_LENGTH = 256,
  MAXIMUM_DATA_SIZE = 512,
  FINGER_PORT = 79,
  MAXIMUM_CONNECTIONS = 5
};

#ifdef GIGI_DYNAMIC
/* This is a proof of concept. Please do not actually use `gigi_do`, as it is
 * clearly susceptible to command injection. */
void gigi_do(int connection_file_descriptor, const char *arguments);
#else
void gigi_show(int connection_file_descriptor, const char *arguments);
#endif

int main(void) {
  int server_socket_file_descriptor;
  int client_socket_file_descriptor;
  struct sockaddr_in server_address;
  struct sockaddr_in client_address;
  char client_message_buffer[MAXIMUM_COMMAND_LENGTH];
  socklen_t client_address_length;
  int reuse_address_option = 1;
  ssize_t client_socket_bytes_read;

  server_socket_file_descriptor = socket(AF_INET, SOCK_STREAM, 0);

  if (server_socket_file_descriptor < 0) {
    perror("error: could not create server socket\n");

    return 1;
  }

  memset(&server_address, 0, sizeof(server_address));

  server_address.sin_family = AF_INET;
  server_address.sin_addr.s_addr = htonl(INADDR_ANY);
  server_address.sin_port = htons(FINGER_PORT);

  if (setsockopt(server_socket_file_descriptor, SOL_SOCKET, SO_REUSEADDR,
                 &reuse_address_option, sizeof(reuse_address_option)) < 0) {
    perror("error: could not set server socket option\n");

    return 1;
  }

  if (bind(server_socket_file_descriptor, (struct sockaddr *)&server_address,
           sizeof(server_address)) < 0) {
    perror("error: could not bind server socket\n");

    return 1;
  }

  if (listen(server_socket_file_descriptor, MAXIMUM_CONNECTIONS) < 0) {
    perror("error: could not listen on server socket\n");

    return 1;
  }

  client_address_length = sizeof(client_address);

  for (;;) {
    client_socket_file_descriptor =
        accept(server_socket_file_descriptor,
               (struct sockaddr *)&client_address, &client_address_length);

    if (client_socket_file_descriptor < 0) {
      perror("error: could not accept on client socket\n");

      return 1;
    }

    memset(client_message_buffer, 0, sizeof(client_message_buffer));

    client_socket_bytes_read =
        read(client_socket_file_descriptor, client_message_buffer,
             sizeof(client_message_buffer) - 1);

    if (client_socket_bytes_read < 0) {
      perror("error: could not read from client socket\n");

      return 1;
    }

    client_message_buffer[client_socket_bytes_read] = '\0';

#ifdef GIGI_DYNAMIC
    gigi_do(client_socket_file_descriptor, client_message_buffer);
#else
    gigi_show(client_socket_file_descriptor, client_message_buffer);
#endif

    if (close(client_socket_file_descriptor) < 0) {
      perror("error: could not close client socket\n");

      return 1;
    }
  }

  /* if (close(server_socket_file_descriptor) < 0) {
    perror("error: could not close server socket\n");

    return 1;
  }

  return 0; */
}

#ifdef GIGI_DYNAMIC
void gigi_do(int connection_file_descriptor, const char *arguments) {
  FILE *gigi_do_file;
  char gigi_do_command[MAXIMUM_COMMAND_LENGTH];
  char gigi_do_message[MAXIMUM_DATA_SIZE];

  snprintf(gigi_do_command, MAXIMUM_COMMAND_LENGTH, "./.gigi/do %s", arguments);

  gigi_do_file = (FILE *)popen(gigi_do_command, "r");

  if (!gigi_do_file) {
    perror("error: could not open gigi do file pipe\n");
    return;
  }

  while (fgets(gigi_do_message, MAXIMUM_DATA_SIZE, gigi_do_file) != NULL) {
    if (write(connection_file_descriptor, gigi_do_message,
              strlen(gigi_do_message)) < 0) {
      perror("error: could not write to client socket\n");
    }
  }

  if (pclose(gigi_do_file) != 0) {
    perror("error: could not close gigi do file pipe\n");
  }
}
#endif

#ifndef GIGI_DYNAMIC
void gigi_show(int connection_file_descriptor, const char *arguments) {
  FILE *gigi_show_file;
  char gigi_show_message[MAXIMUM_DATA_SIZE];

  gigi_show_file = fopen("./.gigi/show", "r");

  if (arguments[0] != '\0') {
    char gigi_show_command[MAXIMUM_COMMAND_LENGTH];
    char gigi_show_arguments[MAXIMUM_COMMAND_LENGTH];
    size_t gigi_show_arguments_index;

    snprintf(gigi_show_arguments, MAXIMUM_COMMAND_LENGTH, "%s", arguments);

    for (gigi_show_arguments_index = 0;
         gigi_show_arguments_index < strlen(gigi_show_arguments);
         ++gigi_show_arguments_index) {
      if (gigi_show_arguments[gigi_show_arguments_index] == '\n' ||
          gigi_show_arguments[gigi_show_arguments_index] == '\r') {
        gigi_show_arguments[gigi_show_arguments_index] = '\0';
      }
    }

    if (gigi_show_arguments[0] == '\0') {
      snprintf(gigi_show_arguments, MAXIMUM_COMMAND_LENGTH, "default");
    }

    snprintf(gigi_show_command, MAXIMUM_COMMAND_LENGTH, "./.gigi/%s",
             gigi_show_arguments);
    printf("ok: %s\n", gigi_show_command);

    gigi_show_file = fopen(gigi_show_command, "r");
  }

  if (!gigi_show_file) {
    perror("error: could not open gigi show file\n");

    return;
  }

  while (fgets(gigi_show_message, MAXIMUM_DATA_SIZE, gigi_show_file) != NULL) {
    if (write(connection_file_descriptor, gigi_show_message,
              strlen(gigi_show_message)) < 0) {
      perror("error: could not write to client socket\n");
    }
  }

  if (fclose(gigi_show_file) != 0) {
    perror("error: could not close gigi show file\n");
  }
}
#endif
