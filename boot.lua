
function send_command(s, timeout)
--   print("sending " .. string.gsub(s, "([^%g])", function(s) return string.format("{%02x}", string.byte(s)) end) .. "\r\n")
   local s =  s .. "\r"
   while write(s) < #s do
      print("partioal write")
      s = string.sub(#s + 1)
   end
   
   local l, matched
   local total=0
   local count = 0
   
   repeat 
      l, matched = read(1,1000)
      if matched and matched:match("BusyBox") then
         return false
      end
      total = total + l
      if l == 0  then
         -- print(string.format("reached idle after %d bytes for for %10q\r\n", total, s))
         return true
      end
   until false
   
   return true
end

function send_script(f)
  for line in f:lines() do
    if not send_command(line) then return end
  end
end

send_command("version")
local f = io.open("result/boot.scr")
send_script(f)
f:close()


