#include <stdint.h>
#include <string.h>
#include <cbm.h>
#include "fujinet-io.h"
#include "fn_data.h"

uint8_t fn_io_mount_host_slot(uint8_t hs)
{
  memset(response, 0, sizeof(response));

  response[0] = FUJICMD_MOUNT_HOST;
  response[1] = hs;

  cbm_open(LFN, DEV, SAN, response);
  cbm_close(LFN);
  return 0; // TODO: is there an error code we can use here?
}
