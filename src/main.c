#include <zephyr/kernel.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/sys/printk.h>

#define LED0_NODE DT_ALIAS(led0)

#if !DT_NODE_HAS_STATUS(LED0_NODE, okay)
#error "led0 alias is not defined in devicetree"
#endif

static const struct gpio_dt_spec led = GPIO_DT_SPEC_GET(LED0_NODE, gpios);

static int led_init(void)
{
	if (!gpio_is_ready_dt(&led)) {
		printk("LED device is not ready\n");
		return -1;
	}

	return gpio_pin_configure_dt(&led, GPIO_OUTPUT_INACTIVE);
}

int main(void)
{
	if (led_init() < 0) {
		printk("LED init failed\n");
	}

	printk("Hello from app VERSION 1.0.1 UART1 OTA\n");

	while (1) {
		gpio_pin_toggle_dt(&led);
		printk("App running...\n");
		k_msleep(1000);
	}

	return 0;
}