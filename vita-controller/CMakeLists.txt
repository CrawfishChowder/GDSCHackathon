cmake_minimum_required(VERSION 3.16)
project(vita_lan_controller C)

if(NOT DEFINED ENV{VITASDK})
	message(FATAL_ERROR "Set VITASDK before configuring the Vita build")
endif()

include("$ENV{VITASDK}/share/vita.cmake" REQUIRED)

set(VITA_HOST_IP "10.42.0.1" CACHE STRING "IPv4 address of the PC running Red Alert")
set(VITA_TITLE_ID "VITACTRL1" CACHE STRING "Vita application title ID")

add_executable(vita_lan_controller
	src/main.c
	src/host_config.c
	src/protocol.c
)

target_compile_definitions(vita_lan_controller PRIVATE VITA_HOST_IP="${VITA_HOST_IP}")
target_compile_features(vita_lan_controller PRIVATE c_std_11)
target_compile_options(vita_lan_controller PRIVATE -Wall -Wextra)
target_link_libraries(vita_lan_controller
	vita2d
	SceCtrl_stub
	SceDisplay_stub
	SceGxm_stub
	SceNet_stub
	SceNetCtl_stub
	ScePgf_stub
	ScePvf_stub
	SceSysmodule_stub
	SceIofilemgr_stub
	SceCommonDialog_stub
	SceAppMgr_stub
	freetype
	png
	jpeg
	z
	m
)

vita_create_self(vita_lan_controller.self vita_lan_controller)
vita_create_vpk(vita_lan_controller.vpk ${VITA_TITLE_ID} vita_lan_controller.self
	VERSION 01.00
	NAME "Vita LAN Controller"
)
