#include "host_config.h"

#include <stdio.h>
#include <string.h>

static int fail(const char *message) {
	fprintf(stderr, "FAIL: %s\n", message);
	return 1;
}

int main(void) {
	unsigned int octets[4];
	if (!host_config_parse_ipv4("192.168.0.138", octets)) {
		return fail("valid IPv4 address was rejected");
	}
	if (octets[0] != 192 || octets[1] != 168 || octets[2] != 0 || octets[3] != 138) {
		return fail("IPv4 octets were parsed incorrectly");
	}
	char formatted[16];
	if (!host_config_format_ipv4(octets, formatted, sizeof(formatted)) || strcmp(formatted, "192.168.0.138") != 0) {
		return fail("IPv4 address was formatted incorrectly");
	}
	const char *invalid_addresses[] = {
		"256.1.2.3", "1.2.3", "1.2.3.4.5", "1..2.3", "1.2.3.4x", "1234.0.0.0", ""
	};
	for (size_t index = 0; index < sizeof(invalid_addresses) / sizeof(invalid_addresses[0]); index++) {
		if (host_config_parse_ipv4(invalid_addresses[index], octets)) {
			return fail("invalid IPv4 address was accepted");
		}
	}
	octets[2] = 0;
	if (!host_config_adjust_octet(octets, 2, 10) || octets[2] != 10) {
		return fail("valid octet adjustment failed");
	}
	if (host_config_adjust_octet(octets, 2, 300) || octets[2] != 10) {
		return fail("out-of-range octet adjustment was accepted");
	}
	puts("PASS");
	return 0;
}