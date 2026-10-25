#include "../src/protocol.h"

#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <string.h>

int main(void) {
	char packet[256];
	assert(vita_normalize_axis(128, 0.18f) == 0.0f);
	assert(vita_normalize_axis(135, 0.18f) == 0.0f);
	assert(fabsf(vita_normalize_axis(255, 0.0f) - 1.0f) < 0.001f);
	assert(fabsf(vita_normalize_axis(0, 0.0f) + 1.0f) < 0.001f);

	size_t length = vita_format_input_packet(
		packet,
		sizeof(packet),
		1.2f,
		-1.0f,
		0.0f,
		-0.5f,
		VITA_BUTTON_CROSS | VITA_BUTTON_R
	);
	assert(length > 0 && length < sizeof(packet));
	assert(strcmp(packet,
		"{\"type\":\"input\",\"axes\":{\"left_x\":1.000,\"left_y\":-1.000,\"right_x\":0.000,\"right_y\":-0.500},\"buttons\":[\"cross\",\"r\"]}") == 0);
	assert(!vita_is_telemetry_packet(packet));
	assert(!vita_is_telemetry_packet("{\"message\":\"telemetry\"}"));
	assert(vita_is_telemetry_packet("{\"type\":\"telemetry\",\"protocol\":1}"));
	assert(vita_format_input_packet(packet, 8, 0, 0, 0, 0, 0) == 0);

	puts("PASS");
	return 0;
}
