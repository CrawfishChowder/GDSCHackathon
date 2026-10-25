#ifndef VITA_CONTROLLER_PROTOCOL_H
#define VITA_CONTROLLER_PROTOCOL_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define VITA_BUTTON_CROSS (1u << 0)
#define VITA_BUTTON_SQUARE (1u << 1)
#define VITA_BUTTON_L (1u << 2)
#define VITA_BUTTON_R (1u << 3)
#define VITA_BUTTON_START (1u << 4)

float vita_normalize_axis(uint8_t raw_value, float deadzone);
size_t vita_format_input_packet(
	char *buffer,
	size_t buffer_size,
	float left_x,
	float left_y,
	float right_x,
	float right_y,
	uint32_t buttons
);
bool vita_is_telemetry_packet(const char *packet);

#endif
