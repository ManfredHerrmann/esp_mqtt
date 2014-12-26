#include "ets_sys.h"
#include "driver/uart.h"
#include "osapi.h"
#include "mqtt.h"
#include "config.h"
#include "debug.h"
#include "gpio.h"
#include "user_interface.h"

void user_init(void)
{
	uart_init(BIT_RATE_115200, BIT_RATE_115200);
	os_delay_us(1000000);
	wifi_set_opmode(STATION_MODE);
	CFG_Load();
	MQTT_Start();
	INFO("\r\nSystem started ...\r\n");
}
