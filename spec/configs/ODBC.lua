#!/usr/bin/env lua

return { -- MySQL
	connect = {
		name = 'MySQL-test',
	},

	encoding_test = {
		{'unsigned',      12435212   },
		{'unsigned',      463769     },
		{'signed',        8574678    },
		{'signed',        -12435212  },
		{'unsigned',      0          },
		{'signed',        0          },
		{'signed',        9998212    },
		{'decimal(7,2)',  7653.25    },
		{'decimal',       7635236    },
		{'decimal(4,3)',  0.000      },
		{'decimal(7,2)',  -7653.25   },
		{'decimal(9,5)',  1636.94783 },
		{'char',          "string 1" },
		{'char(14)',      "another_string" },
		{'char',          "really long string with some escapable chars: #&*%#;@'" },
	},

	placeholder = '?',

	have_last_insert_id = false,
	have_typecasts = true,
	have_booleans = false,
	have_rowcount = true
}
