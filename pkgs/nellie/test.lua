local nellie = require('nellie')
print('dfg')
local f = nellie.open()

print(string.byte(f:read(1000), 0, 60))
