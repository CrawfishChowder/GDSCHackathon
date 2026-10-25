#include "protocol.h"

#include <math.h>
#include <stdio.h>
#include <string.h>

static float clamp_axis(float value) {
	if (value < -1.0f) {
		return -1.0f;
	}
	if (value > 1.0f) {
		return 1.0f;
	}
	return value;
}

float vita_normalize_axis(uint8_t raw_value, float deadzone) {
	float value = raw_value < 128
		? ((float)raw_value - 128.0f) / 128.0f
		: ((float)raw_value - 128.0f) / 127.0f;
	float magnitude = fabsf(value);

	if (deadzone < 0.0f) {
		deadzone = 0.0f;
	} else if (deadzone > 0.95f) {
		deadzone = 0.95f;
	}
	if (magnitude <= deadzone) {
		return 0.0f;
	}
	return copysignf((magnitude - deadzone) / (1.0f - deadzone), value);
}

static bool append_button(
	char *buffer,
	size_t buffer_size,
	size_t *length,
	bool *has_button,
	const char *name
) {
	int written = snprintf(
		buffer + *length,
		buffer_size - *length,
		"%s\"%s\"",
		*has_button ? "," : "",
		name
	);
	if (written < 0 || (size_t)written >= buffer_size - *length) {
		return false;
	}
	*length += (size_t)written;
	*has_button = true;
	return true;
}

size_t vita_format_input_packet(
	char *buffer,
	size_t buffer_size,
	float left_x,
	float left_y,
	float right_x,
	float right_y,
	uint32_t buttons
) {
	char button_list[64] = {0};
	size_t button_length = 0;
	bool has_button = false;

	if ((buttons & VITA_BUTTON_CROSS) && !append_button(button_list, sizeof(button_list), &button_length, &has_button, "cross")) {
		return 0;
	}
	if ((buttons & VITA_BUTTON_SQUARE) && !append_button(button_list, sizeof(button_list), &button_length, &has_button, "square")) {
		return 0;
	}
	if ((buttons & VITA_BUTTON_L) && !append_button(button_list, sizeof(button_list), &button_length, &has_button, "l")) {
		return 0;
	}
	if ((buttons & VITA_BUTTON_R) && !append_button(button_list, sizeof(button_list), &button_length, &has_button, "r")) {
		return 0;
	}
	if ((buttons & VITA_BUTTON_START) && !append_button(button_list, sizeof(button_list), &button_length, &has_button, "start")) {
		return 0;
	}

	int written = snprintf(
		buffer,
		buffer_size,
		"{\"type\":\"input\",\"axes\":{\"left_x\":%.3f,\"left_y\":%.3f,\"right_x\":%.3f,\"right_y\":%.3f},\"buttons\":[%s]}",
		clamp_axis(left_x),
		clamp_axis(left_y),
		clamp_axis(right_x),
		clamp_axis(right_y),
		button_list
	);
	if (written < 0 || (size_t)written >= buffer_size) {
		return 0;
	}
	return (size_t)written;
}

bool vita_is_telemetry_packet(const char *packet) {
	return packet != NULL && strstr(packet, "\"type\":\"telemetry\"") != NULL;
}
