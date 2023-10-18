-- this code is based on src/tftp.lua from https://github.com/ldrumm/tufty
-- which is distributed under the MIT License
-- Starting upstream revision 3cb95c869e2fe74cc61ca303d88af6c5daad6734
--
-- Changes made since then are mostly to make it work better with
-- luasocket

--[[
    This package provides intefaces for handling TFTP requests as specified by
    rfc1350, rfc1782, rfc2347, rfc2348 and (partial support for rfc2349)
    It should work on Standard PC servers as well as small home routers running
    OpenWRT or similar.
]]

local tftp = {}
local TIMEOUT = 5
local ACK_RETRIES = 10
local TFTP_PORT = 69
local BLKSIZE = 512

local OP_RRQ = 1
local OP_WRQ = 2
local OP_DATA = 3
local OP_ACK = 4
local OP_ERR = 5
local OP_OACK = 6
local ACKSIZE = 4

local ERR_NOTFOUND = 1
local ERR_ACCESS = 2
local ERR_ALLOC = 3
local ERR_ILLEGAL_OP = 4
local ERR_UNKNOWN_ID = 5
local ERR_EXISTS = 6
local ERR_WHO = 7

--rfc2347 specifies the options extension.
--rfc2348 specifies the blksize extension
--rfc2349 specifies the timeout and tsize extensions
local SUPPORTED_OPTIONS = {blksize=true, timeout=true, tsize=true}

local luasocket = require("socket")

--Use penlight's prettyprinter if available
pcall(require, 'pl')
local log = pretty and pretty.dump or print

local time = (function()
      return require("socket").gettime
end)()

local poll = (function()
    --[[
    ``poll`` is expected to accept a table of sockets keyed by
    backend file descriptor formatted as follows: {
        [low level socket lib file descriptor]{
            fd=(low level socket lib fd)
            wantread=(bool)
            wantwrite=(bool)
            ...arbitrary ignored extra fields
        },
        ...
    }
    it returns a list of fds formatted as follows
        {
             [low level socket lib file descriptor]{
                fd= [low level socket lib file descriptor],
                readable=(bool),
                writable=(bool)
            }
        ...
        }
    ]]

    return function(fds, timeout)
        local wantread = {}
        local wantwrite = {}
        for _, fd  in pairs(fds) do
            fd.readable=false
            fd.writeable=false
            if fd.wantwrite then wantwrite[#wantwrite + 1] = fd.fd end
            if fd.wantread then wantread[#wantread + 1] = fd.fd end
        end
        local readable, writeable, timedout = luasocket.select(wantread, wantwrite, timeout)
        if timedout then return nil end
        local ready = {}
        for _, fd in ipairs(readable) do
	   ready[fd] = ready[fd] or { fd = fd }
	   ready[fd].readable = true
        end
        for _, fd in ipairs(writeable) do
	   ready[fd] = ready[fd] or { fd = fd }
	   ready[fd].writeable = true
        end
        return ready
    end
end)()

local function UDPSocket()
    --[[ We want to support the basic functionality required for TFTP operation over
        UDP.
        This wraps only the required functionality and in no way represents a
        complete UDP socket implementation.
        see http://w3.impa.br/~diego/software/luasocket/udp.html for the luasocket UDP API
    ]]

   return {
      fd = luasocket.udp(),
      bind = function(self, address, port)
	 return self.fd:setsockname(address, port)
      end,
      sendto = function(self, data, address, port)
	 return self.fd:sendto(data, address, port)
      end,
      recvfrom = function(self, length)
	 return self.fd:receivefrom(length)
      end,
      close = function(self)
	 return self.fd:close()
      end
   }
end

local function is_netascii(s)
    --[[Check whether a string contains only characters from the RFC764 ascii
    subset. see https://tools.ietf.org/html/rfc764#page-11
    ]]
    local ctrls = {[0]=1, [10]=1, [13]=1, [7]=1, [8]=1, [9]=1, [11]=1, [12]=1}
    for i=1, #s do
        local byte = s:sub(i, i):byte()
        if (byte < 31 and ctrls[byte] == nil) or byte > 127 then
            return false
        end
    end
    return true
end

local function create_opcode(val)
    if val < 0 or val > 2^16-1 then error("opcodes must fit into a 16bit integer") end
    local high = math.floor(val / 256)
    -- RFC1350 doesn't mention byte order.  Assume network order (big-endian).
    return string.char(high, val - (high * 256))
end

local function parse_opcode(packet)
    local opcode = string.byte(packet:sub(2, 2)) --assume big endian
    return ({"RRQ", "WRQ", "DATA", "ACK", "ERROR", "OACK"})[opcode]
end

function tftp:handle_RRQ(socket, host, port, source, options)
    local blksize = options and tonumber(options.blksize) or BLKSIZE
    local timeout_secs = options and tonumber(options.timeout) or TIMEOUT --rfc2349 timout option
    local length = options and tonumber(options.length)
    local tid = 1
    local time = time
    local started = time()
    local err = self.ERROR
    local done = false
    local error, success = error, error -- to terminate the coroutine immediately, we raise an error
    local yield = coroutine.yield

    return coroutine.create(function()
        if options then
        --[[The handler coroutine should not start running until we know the client is ready.
         This depends on whether the client has requested rfc2347 options and responded to an OACK.
         Without the options extension request, the client can be responded to immediately.]]
            local acked, timeout = false, time() + timeout_secs
            assert(socket:sendto(self.OACK(options), host, port))
            log(("sent OACK to %s:%d"):format(host, port))
            repeat
                yield(true, false)
                local msg, port, host = socket:recvfrom(ACKSIZE)
                if self.parse_ACK(msg) == 0 then acked = true end
                timedout = time() > timeout
            until acked or timedout
            if timedout then error("Request timed out waiting for OACK response") end
        end
        log(("coroutine started on %s:%s/"):format(host, port))
        while not done do
            if tid >= 2^16 then
                socket:sendto(err("File too big."), host, port)
                error("File too big.")
            end
            local okay, continue, data = pcall(source, blksize)
            if not okay then
                packet = socket:sendto(err("An unknown error occurred"), host, port)
                error("generator failure")
            end
            if data == nil and not continue then
                done = true
            end
            if data == nil and continue then
                --[[The generator ``source`` can be async and return `true, nil`
                    if no data is ready, but things are going well.
                ]]
                yield(false, true)
            end

            local acked
            local retried = 0
            local timeout = time() + timeout_secs
            local timedout = false
            repeat
                socket:sendto(self.DATA(data, tid), host, port)
                --[[  Now check for an ACK.
                   RFC1350 requires that for every packet sent, an ACK is received
                   before the next packet can be sent.
                ]]
                yield(true, false) -- we need to wait until the socket is readable again
                local ack, ackhost, ackport = socket:recvfrom(ACKSIZE)
                local ack_sequence = self.parse_ACK(ack)

                if ackhost ~= host or ackport ~= port then
                   --[[https://tools.ietf.org/html/rfc1350#page-5
                       "If a source TID does not match, the packet should be
                       discarded as erroneously sent from somewhere else.
                       An error packet should be sent to the source of the
                       incorrect packet, while not disturbing the transfer."
                   ]]
                   socket:sendto(err(ERR_UNKNOWN_ID), ackhost, ackport)
                   yield(true, false)
		elseif ack_sequence ~= tid then
		   -- this looks confusing, but the local variable
		   -- "tid" here is actually block number (aka
		   -- sequence number), not tid at all.
		   log(("ack received for old block %d (expecting %d)"):format(ack_sequence, tid))
		   acked = false
		else
		   acked = true
		end

		if not acked then log("resending") end
                retried = retried + 1
                timedout = time() > timeout
            until acked or retried > ACK_RETRIES
            if retried > ACK_RETRIES then
                --There doesn't seem to be a standard error for timeout.
                socket:sendto(err("Ack timeout"), host, port)
                error("Timeout waiting for ACK")
            end
            --Okay, we've been acked in reasonable time.
            tid = tid + 1
            if done then success() end
            yield(true, true)
        end
    end)
end

function tftp:handle_WRQ(socket, host, port, sink)
    error"Not Implemented"
end

function tftp:listen(rrq_generator_callback, wrq_generator_callback, hosts, port, logfile)
--[[--
    Listen for TFTP requests on UDP ```bind``:`port`` (0.0.0.0:69 by default)
    and get data from / send data to user-generated source/sink functions.
    Data is generated/received by functions returned by the the user-supplied
    ``rrq_generator_callback``/``wrq_generator_callback`` factory functions.
    For each resource requested, the generator function will be called
    with three arguments:
       - the requested resource as a C-style string (no embedded NUL chars)
       - the ip address of the peer, as a dotted-quad string ("1.2.3.4")
       - the port number of the peer
    It should return a source or sink function that will be called repeatedly
    until the data transfer is complete:
        (SOURCE) will be called once for each block of data : it takes a
         single argument of the requested data length in bytes
         and returns the next block of data. It must return as follows
                `true, data` on success
                `true, nil` on wouldblock but should retry next round,
                `false` on finished
        (SINK) takes two arguments
            ``data`` to write
            ``done`` (truthy), whether all data has been received and backends can cleanup.

    The (SOURCE) model therefore supports both blocking and non-blocking behaviour.
    If the given function blocks, however, it will block the whole process as Lua
    is single threaded. That may or may not be acceptable depending on your needs.
    If the requested resource is invalid or other termination conditions are met,
    (SOURCE) and (SINK) functions should raise an error.
    @return This method never returns unless interrupted.
]]

    local function create_handler(callbacks, request, requestsocket, host, port)
         --[[ Given a parsed request, instantiate the generator function from the given callbacks,
            and create a new coroutine to be called when the state of the handler's
            new socket changes to available.
            On success, returns a table of the form:
            ```{
                handler=coroutine to call,
                socket= new socket on a random port on which all new communication will happen,
                fd=socket.fd as above fd
                host=remote host,
                port = remote port,
                request = the original parsed request, including accepted options, if any.
            }```
            On error, responds to the client with an ERROR packet, and returns nil.
        ]]
        local okay, generator, tsize = pcall(callbacks[request.opcode], request.filename, host, port)
        if not okay then
            requestsocket:sendto(self.ERROR(ERR_NOTFOUND), host, port)
            return nil
        else
            if request.options then
                request.options.tsize = request.options.tsize and tostring(tsize)
                for k, v in pairs(request.options) do
                    if not SUPPORTED_OPTIONS[k] then request.options[k] = nil end
                end
            else
                --RFC1350 requires WRQ requests to be responded to with a zero TID before transfer commences,
                --but when responding to an options request, it is dropped.
                if request.opcode == 'WRQ' then requestsocket:sendto(self.ACK(0), host, port) end
            end
            local handlersocket = UDPSocket()
	    handlersocket:bind("*", 0)
            local handler = self['handle_' .. request.opcode](self, handlersocket, host, port, generator, request.options)
            return {
                handler=handler,
                socket=handlersocket,
                fd=handlersocket.fd,
                host=host,
                port=port,
                request=request,
                wantread=false,
                wantwrite=true,
            }
        end
    end

    local function accept(socket)
        --[[ Read an incoming request from ``socket``, parse, and ACK as appropriate.
            If the request is invalid, responds to the client with error and returns `nil`
            otherwise returns the parsed request.
        ]]
        local msg, host, port = socket:recvfrom()
        if msg ~= false then
            local okay, xRQ = pcall(self.parse_XRQ, msg)
            if not okay then
                return nil
            else
                return host, port, xRQ
            end
        end
    end

    local socket = UDPSocket()
    local user_generator_callbacks = {RRQ=rrq_generator_callback, WRQ=wrq_generator_callback}
    local port = port or TFTP_PORT
    local logfile = logfile or io.stderr
    --listen on all given addresses, default to localhost if not given
    for i, address in pairs((type(hosts) == 'table' and hosts) or (hosts ~= nil and{hosts}) or {'127.0.0.1'}) do
       local ok, err = socket:bind(address, port)
       if not ok then error(err .. " binding to " .. address .. ":" .. port) end
    end

    --[[The main event loop does two things:
        1. Accepts new connections.
        2. Handles events occurring on all sockets by dispatching to a handler coroutine.
        3. Removes finished requests from the queue and destroys the sockets.
    ]]
    local handlers = {[socket.fd]={fd=socket.fd, socket=socket, listener=true, wantread=true}}
    while true do
        ready_fds = poll(handlers)
        do
            local n = 0
            for _ in pairs(ready_fds) do
                n = n + 1
            end
--            log(('There are %d sockets ready'):format(n))
        end
        for fd, status in pairs(ready_fds) do
--            pretty.dump(ready_fds)
--            log(('There are %d sockets ready'):format(#ready_fds))
            ready = handlers[fd]
            if ready.listener and status.readable then
                --we've got a listener and should accept a new connection
                local host, port, request = accept(ready.socket)
                if host ~= nil then
                    log(("accepted new %s request - %s:%s/%s"):format(request.opcode, host, port, request.filename))
                    local handler = create_handler(
                        user_generator_callbacks,
                        request,
                        ready.socket,
                        host,
                        port
                    )
                    if handler then handlers[handler.socket.fd] = handler end
                end
            elseif (status.readable or status.writeable) and ready.handler then
            --We've received an event on a socket associated with an existing handler coroutine.
                local co_state = coroutine.status(ready.handler)
                local okay, wantread, wantwrite
                if co_state ~= 'dead' then
                    if (ready.wantread and status.readable) or (ready.wantwrite and status.writeable) then
                        okay, wantread, wantwrite = coroutine.resume(ready.handler)
                        ready.wantread = wantread
                        ready.wantwrite = wantwrite
                    end
                end
                if (not okay) or co_state == 'dead' then
                    --- the handler is finished; cleanup
                    ready.socket:close()
                    handlers[ready.fd] = nil
                    ready.fd = nil
                    ready = nil
                end
            end
        end
    end
end


--[[ RRQ/ZRQ read/write request packets
    https://tools.ietf.org/html/rfc1350
    2 bytes     string    1 byte     string   1 byte
    ------------------------------------------------
   | Opcode |  Filename  |   0  |    Mode    |   0  |
    ------------------------------------------------
           Figure 5-1: RRQ/WRQ packet
]]
function tftp.RRQ(filename)
--  RFC1350:"The mail mode is obsolete and should not be implemented or used."
--  We don't support netascii, which leaves 'octet' mode only
    return table.concat({create_opcode(OP_RRQ), filename, '\0', "octet", '\0'}, '')
end

function tftp.parse_XRQ(request)
    local opcode = assert(parse_opcode(request), "Invalid opcode")
    assert(({RRQ=true, XRQ=true})[opcode], "Not an xRQ")
    assert(request:sub(#request) == '\0', "Invalid request: expected ASCII NUL terminated request")

    local cstrings = {}
    function zero_iter(s)
        local pos = 1
        return function()
            --This is ugly. Lua 5.2 handles embedded NUL bytes in string.gmatch,
            --but vanilla Lua5.1 doesn't match correctly and luajit can't seem to parse them
            for i=pos, #s do
                if s:byte(i) == 0 then
                    local sub = s:sub(pos, i-1)
                    pos = i+1
                    return sub
                end
            end
        end
    end
    for s in zero_iter(request:sub(3)) do
        cstrings[#cstrings+1] = s
    end
    assert(#cstrings >= 2)
    local filename = assert(is_netascii(cstrings[1]) and cstrings[1], "Requested filename must be netascii")
    local mode = assert(({netascii='netascii', octet='octet'})[cstrings[2]])
    local options
    if #cstrings > 2 then
        options = {}
        assert(#cstrings % 2 == 0)
        for i=3, #cstrings, 2 do
            --[[ RFC1782, and 3247 require case insensitive comparisons.
                We normalize them to lowercase with the consequence that
                duplicate keys are replaced which are forbidden by the standard anyway.
            ]]
            options[cstrings[i]:lower()] = cstrings[i+1]:lower()
        end
    end

    return {opcode=opcode, filename=filename, mode=mode, options=options}
end

--[[ ACK functions
     2 bytes     2 bytes
     ---------------------
    | Opcode |   Block #  |
     ---------------------
     Figure 5-3: ACK packet
]]
function tftp.parse_ACK(ack)
    --get the sequence number from an ACK or raise a error if not valid
    assert(#ack == ACKSIZE, "invalid ack")
    assert(parse_opcode(ack) == 'ACK', "invalid ack")

    -- extract the low and high order bytes and convert to an integer
    local high, low = ack:byte(3, 4)
    return (high * 256) + low
end

--[[
      +-------+---~~---+---+---~~---+---+---~~---+---+---~~---+---+
      |  opc  |  opt1  | 0 | value1 | 0 |  optN  | 0 | valueN | 0 |
      +-------+---~~---+---+---~~---+---+---~~---+---+---~~---+---+
]]
function tftp.OACK(options)
    local stropts = {}
    for k, v in pairs(options) do
        assert(is_netascii(k))
        stropts[#stropts+1] =  k .. '\0' .. v .. '\0'
    end
    return create_opcode(OP_OACK) .. table.concat(stropts, '')
end

function tftp.ACK(tid)
    return table.concat({create_opcode(OP_ACK), create_opcode(tid)}, '')
end


--[[ DATA functions
   2 bytes     2 bytes      n bytes
   ----------------------------------
  | Opcode |   Block #  |   Data     |
   ----------------------------------
        Figure 5-2: DATA packet
]]
function tftp.DATA(data, tid)
    local opcode = create_opcode(OP_DATA)
    local block = create_opcode(tid)
    return table.concat({opcode, block, data}, '')
end

function tftp.parse_DATA(data)
    assert(#data <= 512, "tftp data packets must be 512 bytes or less")
    assert(parse_opcode(data) == OP_DATA, "Invalid opcode")
    return {tid=parse_opcode(data:sub(3, 4)), data=data:sub(5)}
end

--[[ ERROR Functions
    2 bytes     2 bytes      string    1 byte
    -----------------------------------------
    | Opcode |  ErrorCode |   ErrMsg   |   0  |
    -----------------------------------------
        Figure 5-4: ERROR packet
]]
function tftp.ERROR(err)
    local defined_errors = {
        --https://tools.ietf.org/html/rfc1350#page-10
        [0] = type(err) == 'string' and err or "Not defined",
        "File not found.",
        "Access violation.",
        "Disk full or allocation exceeded.",
        "Illegal TFTP operation.",
        "Unknown transfer ID.",
        "File already exists.",
        "No such user.",
    }

    local errno = type(err) == 'string' and 0 or err
    return table.concat({
        create_opcode(OP_ERR),
        create_opcode(errno),
        defined_errors[errno],
        '\0'
    }, '')
end

function tftp.parse_ERROR(err)
    assert(parse_opcode(err) == OP_ERR)
    local error_code = parse_opcode(err:sub(3, 4))
    return {errcode=error_code, errmsg=err:sub(5, #err-1)}
end

return tftp
