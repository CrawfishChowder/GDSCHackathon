#include "host_config.h"

#include <stdio.h>

bool host_config_parse_ipv4(const char *text, unsigned int octets[4]) {
	if (text == NULL || octets == NULL) {
		return false;
	}
	const char *cursor = text;
	for (unsigned int index = 0; index < 4; index++) {
		if (*cursor < '0' || *cursor > '9') {
			return false;
		}
		unsigned int value = 0;
		unsigned int digits = 0;
		while (*cursor >= '0' && *cursor <= '9') {
			value = value * 10 + (unsigned int)(*cursor - '0');
			cursor++;
			digits++;
			if (value > 255 || digits > 3) {
				return false;
			}
		}
		octets[index] = value;
		if (index < 3) {
			if (*cursor != '.') {
				return false;
			}
			cursor++;
		} else if (*cursor != '\0') {
			return false;
		}
	}
	return true;
}

bool host_config_format_ipv4(const unsigned int octets[4], char *buffer, size_t buffer_size) {
	if (octets == NULL || buffer == NULL || buffer_size == 0) {
		return false;
	}
	for (unsigned int index = 0; index < 4; index++) {
		if (octets[index] > 255) {
			return false;
		}
	}
	int length = snprintf(buffer, buffer_size, "%u.%u.%u.%u", octets[0], octets[1], octets[2], octets[3]);
	return length >= 0 && (size_t)length < buffer_size;
}

bool host_config_adjust_octet(unsigned int octets[4], unsigned int selected, int delta) {
	if (octets == NULL || selected >= 4) {
		return false;
	}
	int updated = (int)octets[selected] + delta;
	if (updated < 0 || updated > 255) {
		return false;
	}
	octets[selected] = (unsigned int)updated;
	return true;
}