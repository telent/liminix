local nellie = require('nellie')
print('dfg')
local f = nellie.open(2)

print(string.byte(f:read(1000), 0, 60))
print("CLOSED", f:close())
