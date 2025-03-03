#include <stdint.h>
#include <string.h>

#include "fujinet-io.h"
#include "fujinet-network-apple2.h"

// do status call to FN with code 0xe8, payload[0] = 0
void fn_io_get_adapter_config(AdapterConfig *ac)
{
	int8_t err = 0;
	err = sp_find_fuji();
	if (err <= 0) {
		return;
	}

	err = sp_status(sp_fuji_id, 0xE8);
	if (err != 0) {
		return;
	}

	memcpy(ac, &sp_payload[0], sizeof(AdapterConfig));
}
