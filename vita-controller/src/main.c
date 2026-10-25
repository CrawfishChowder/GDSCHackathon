#include <psp2/ctrl.h>
#include <psp2/kernel/processmgr.h>
#include <psp2/net/net.h>
#include <psp2/net/netctl.h>
#include <psp2/sysmodule.h>
#include <vita2d.h>

#include "protocol.h"

#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#ifndef VITA_HOST_IP
#define VITA_HOST_IP "10.42.0.1"
#endif

#define GAME_PORT 27300
#define SEND_INTERVAL_USEC 33333
#define DEADZONE 0.18f
#define NET_MEMORY_SIZE (1024 * 1024)

static unsigned char net_memory[NET_MEMORY_SIZE];
static vita2d_pgf *status_font;
static char vita_ip[16] = "unknown";
static int net_state = -1;
static int last_send_result = -1;
static int last_send_error = 0;

static void draw_status(bool connected) {
	vita2d_start_drawing();
	vita2d_clear_screen();
	if (status_font != NULL) {
		vita2d_pgf_draw_textf(status_font, 48, 64, RGBA8(238, 242, 236, 255), 1.0f, "VITA LAN CONTROLLER");
		vita2d_pgf_draw_textf(status_font, 48, 112, RGBA8(150, 166, 170, 255), 1.0f, "PC: %s:%d", VITA_HOST_IP, GAME_PORT);
		vita2d_pgf_draw_textf(status_font, 48, 148, RGBA8(150, 166, 170, 255), 1.0f, "VITA IP: %s  WIFI STATE: %d", vita_ip, net_state);
		vita2d_pgf_draw_textf(status_font, 48, 188, connected ? RGBA8(92, 224, 162, 255) : RGBA8(242, 174, 86, 255), 1.0f, "STATUS: %s", connected ? "CONNECTED" : "WAITING FOR GAME");
		if (last_send_result < 0) {
			vita2d_pgf_draw_textf(status_font, 48, 224, RGBA8(242, 128, 116, 255), 1.0f, "UDP SEND ERROR: 0x%08X", last_send_error);
		} else {
			vita2d_pgf_draw_textf(status_font, 48, 224, RGBA8(150, 166, 170, 255), 1.0f, "UDP SEND: OK (%d bytes)", last_send_result);
		}
		vita2d_pgf_draw_textf(status_font, 48, 292, RGBA8(208, 216, 211, 255), 1.0f, "Left stick  Move");
		vita2d_pgf_draw_textf(status_font, 48, 332, RGBA8(208, 216, 211, 255), 1.0f, "Right stick Look");
		vita2d_pgf_draw_textf(status_font, 48, 372, RGBA8(208, 216, 211, 255), 1.0f, "Cross Jump   Square / R Interact");
		vita2d_pgf_draw_textf(status_font, 48, 412, RGBA8(208, 216, 211, 255), 1.0f, "L Breathe    Start Pause");
		vita2d_pgf_draw_textf(status_font, 48, 476, RGBA8(150, 166, 170, 255), 1.0f, "Press HOME to exit");
	}
	vita2d_end_drawing();
	vita2d_swap_buffers();
}

static int initialize_network(void) {
	int result = sceSysmoduleLoadModule(SCE_SYSMODULE_NET);
	if (result < 0) {
		return result;
	}
	SceNetInitParam parameters;
	memset(&parameters, 0, sizeof(parameters));
	parameters.memory = net_memory;
	parameters.size = sizeof(net_memory);
	result = sceNetInit(&parameters);
	if (result < 0) {
		return result;
	}
	return sceNetCtlInit();
}

static int create_game_socket(SceNetSockaddrIn *destination) {
	memset(destination, 0, sizeof(*destination));
	destination->sin_len = sizeof(*destination);
	destination->sin_family = SCE_NET_AF_INET;
	destination->sin_port = sceNetHtons(GAME_PORT);
	if (sceNetInetPton(SCE_NET_AF_INET, VITA_HOST_IP, &destination->sin_addr) != 1) {
		return -1;
	}
	int socket = sceNetSocket("vita-controller", SCE_NET_AF_INET, SCE_NET_SOCK_DGRAM, 0);
	if (socket < 0) {
		return socket;
	}
	int nonblocking = 1;
	if (sceNetSetsockopt(socket, SCE_NET_SOL_SOCKET, SCE_NET_SO_NBIO, &nonblocking, sizeof(nonblocking)) < 0) {
		return -1;
	}
	return socket;
}

static uint32_t read_buttons(const SceCtrlData *controller) {
	uint32_t buttons = 0;
	if (controller->buttons & SCE_CTRL_CROSS) {
		buttons |= VITA_BUTTON_CROSS;
	}
	if (controller->buttons & SCE_CTRL_SQUARE) {
		buttons |= VITA_BUTTON_SQUARE;
	}
	if (controller->buttons & SCE_CTRL_LTRIGGER) {
		buttons |= VITA_BUTTON_L;
	}
	if (controller->buttons & SCE_CTRL_RTRIGGER) {
		buttons |= VITA_BUTTON_R;
	}
	if (controller->buttons & SCE_CTRL_START) {
		buttons |= VITA_BUTTON_START;
	}
	return buttons;
}

static int send_json(int socket, const SceNetSockaddrIn *destination, const char *packet, size_t length) {
	return sceNetSendto(
		socket,
		packet,
		(unsigned int)length,
		0,
		(const SceNetSockaddr *)destination,
		sizeof(*destination)
	);
}

int main(void) {
	vita2d_init();
	status_font = vita2d_load_default_pgf();
	draw_status(false);

	int result = initialize_network();
	if (result < 0) {
		draw_status(false);
		sceKernelDelayThread(5 * 1000 * 1000);
		return 1;
	}

	sceCtrlSetSamplingMode(SCE_CTRL_MODE_ANALOG);
	SceNetSockaddrIn destination;
	int socket = create_game_socket(&destination);
	if (socket < 0) {
		draw_status(false);
		sceKernelDelayThread(5 * 1000 * 1000);
		return 1;
	}

	bool connected = false;
	char receive_buffer[512];
	char send_buffer[256];
	unsigned int last_telemetry_ms = 0;
	unsigned int last_status_ms = 0;
	while (true) {
		unsigned int now_ms = sceKernelGetProcessTimeLow() / 1000;
		if (sceNetCtlInetGetState(&net_state) == 0 && net_state == SCE_NETCTL_STATE_CONNECTED) {
			SceNetCtlInfo info;
			if (sceNetCtlInetGetInfo(SCE_NETCTL_INFO_GET_IP_ADDRESS, &info) == 0) {
				snprintf(vita_ip, sizeof(vita_ip), "%s", info.ip_address);
			}
		}
		if (connected && now_ms - last_telemetry_ms > 1500) {
			connected = false;
		}

		SceCtrlData controller;
		memset(&controller, 0, sizeof(controller));
		sceCtrlPeekBufferPositive(0, &controller, 1);

		if (connected) {
			float left_x = vita_normalize_axis(controller.lx, DEADZONE);
			float left_y = vita_normalize_axis(controller.ly, DEADZONE);
			float right_x = vita_normalize_axis(controller.rx, DEADZONE);
			float right_y = vita_normalize_axis(controller.ry, DEADZONE);
			size_t packet_length = vita_format_input_packet(
				send_buffer,
				sizeof(send_buffer),
				left_x,
				left_y,
				right_x,
				right_y,
				read_buttons(&controller)
			);
			if (packet_length > 0) {
				last_send_result = send_json(socket, &destination, send_buffer, packet_length);
				last_send_error = last_send_result < 0 ? *sceNetErrnoLoc() : 0;
			}
		} else {
			static const char hello[] = "{\"type\":\"hello\",\"protocol\":1}";
			last_send_result = send_json(socket, &destination, hello, sizeof(hello) - 1);
			last_send_error = last_send_result < 0 ? *sceNetErrnoLoc() : 0;
		}

		int received = sceNetRecvfrom(socket, receive_buffer, sizeof(receive_buffer) - 1, 0, NULL, NULL);
		if (received > 0) {
			receive_buffer[received] = '\0';
			if (vita_is_telemetry_packet(receive_buffer)) {
				connected = true;
				last_telemetry_ms = now_ms;
			}
		}

		if (now_ms - last_status_ms >= 500) {
			last_status_ms = now_ms;
			draw_status(connected);
		}
		sceKernelDelayThread(SEND_INTERVAL_USEC);
	}

	vita2d_free_pgf(status_font);
	vita2d_fini();
	return 0;
}
