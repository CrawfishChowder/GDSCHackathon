#ifndef HOST_CONFIG_H
#define HOST_CONFIG_H

#include <stdbool.h>
#include <stddef.h>

bool host_config_parse_ipv4(const char *text, unsigned int octets[4]);
bool host_config_format_ipv4(const unsigned int octets[4], char *buffer, size_t buffer_size);
bool host_config_adjust_octet(unsigned int octets[4], unsigned int selected, int delta);

#endif