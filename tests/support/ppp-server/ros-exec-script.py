#!/usr/bin/env python

import os,time,base64,json,socket,select,errno,sys
# FIXME: this script is adapted from
# https://wiki.mikrotik.com/wiki/Manual:CHR#Provisioning

# I don't know if it is freely usable/redistributable

class GuestAgent(object):
    '''
        Qemu guest agent interface
        runScript and runFile commands are tailored for ROS agent implementation
        Transport provided by derived classes (transact method)
    '''

    def __init__(self,**kwargs):
        # Due to file contents being passed as base64 inside json:
        #  - large chunk sizes may slow down guest-side parsing.
        #  - small chunk sizes result in additional message fragmentation overhead.
        # Default value is a guestimate.
        self.__chunkSize = kwargs.get('chunkSize', 4096)

    def _qmpError(self,cls,msg):
        ''' Generic callback to log qmp errors before (optionally) raising an exception '''
        print(cls)
        for line in msg.split('\n'):
            print(line)
        # raise RuntimeError()

    def _error(self,msg,*a):
        ''' Generic callback to misc errors before (optionally) raising an exception '''
        print(msg.format(*a))
        # raise RuntimeError()

    def _info(self,msg,*a):
        ''' Generic callback to log info '''
        print(msg.format(*a))

    def _monitorJob(self,pid):
        ''' Block untill script job completes, echo output. Returns None on failure '''
        ret = self.transact('guest-exec-status',{'pid':pid})
        if ret is None:
            return None

        while not bool(ret['exited']):
            time.sleep(1)
            ret = self.transact('guest-exec-status',{'pid':pid})
            if ret is None:
                return None

        # err-data is never sent
        out = []
        if 'out-data' in ret.keys():
            out = base64.b64decode(ret['out-data']).decode('utf-8').split('\n')
            if not out[-1]:
                out = out[:-1]

        exitcode = int(ret['exitcode'])
        return exitcode, out

    def putFile(self,src,dst):
        ''' Upload file '''
        src = os.path.expanduser(src)
        if not os.path.exists(src) or not os.path.isfile(src):
            self._error('File does not exist: \'{}\'', src)
            return None

        ret = self.transact('guest-file-open', {'path':dst,'mode':'w'})
        if ret is None:
            return None

        handle = int(ret)

        file = open(src, 'rb')
        for chunk in iter(lambda: file.read(self.__chunkSize), b''):
            count = len(chunk)
            chunk = base64.b64encode(chunk).decode('ascii')

            ret = self.transact('guest-file-write',{'handle':handle,'buf-b64':chunk,'count':count})
            if ret is None:
                return None
        self.transact('guest-file-flush',{'handle':handle})
        ret = self.transact('guest-file-close',{'handle':handle})
        return True

    def getFile(self,src,dst):
        ''' Download file '''
        dst = os.path.expanduser(dst)

        ret = self.transact('guest-file-open',{'path':src,'mode':'rb'})
        if ret is None:
            return None

        handle = int(ret)
        data = ''
        size = 0

        while True:
            ret = self.transact('guest-file-read',{'handle':handle,'count':self.__chunkSize})
            if ret is None:
                return None
            data += ret['buf-b64']
            size += int(ret['count'])
            if bool(ret['eof']):
                break

        ret = self.transact('guest-file-close',{'handle':handle})
        data = base64.b64decode(data.encode('ascii'))
        with open(dst,'wb') as f:
            f.write(data)
        return True

    def ping(self):
        ret = self.transact('guest-ping',{})
        if ret is None:
            return None
        return ret

    def runFile(self,fileName):
        ''' Execute file (on guest) as script '''
        ret = self.transact('guest-exec',{'path':fileName, 'capture-output':True})
        if ret is None:
            return None

        pid = ret['pid']
        return self._monitorJob(pid)

    def runSource(self,cmd):
        ''' Execute script '''
        if isinstance(cmd,list):
            cmd = '\n'.join(cmd)
        cmd += '\n'
        cmd = base64.b64encode(cmd.encode('utf-8')).decode('ascii')

        ret = self.transact('guest-exec',{'input-data':cmd, 'capture-output':True})
        if ret is None:
            return None

        pid = ret['pid']
        return self._monitorJob(pid)

    def shutdown(self,mode='powerdown'):
        '''
            Execut shutdown command
            mode == 'reboot' - reboot guest
            mode == 'shutdown' or mode == 'halt' - shutdown guest
         '''
        ret = self.transact('guest-shutdown',{'mode':mode})
        return ret

class SocketAgent(GuestAgent):
    '''
        GuestAgent using unix/tcp sockets for communication.
    '''
    def __init__(self):
        GuestAgent.__init__(self,chunkSize= 32 * 65536)

    @staticmethod
    def unix(dev):
        ''' Connect using unix socket '''
        self = SocketAgent()
        self.__af = socket.AF_UNIX
        self.__args = dev
        self.__wait = True
        return self

    @staticmethod
    def tcp(ip,port,wait = True):
        ''' Connect using tcp socket '''
        self = SocketAgent()
        self.__af = socket.AF_INET
        self.__args = (ip,port)
        self.__wait = wait
        return self

    def __enter__(self):
        self._sock = socket.socket(self.__af, socket.SOCK_STREAM)
        if self.__wait:
            self._info('Waiting for guest ...')
            # Wait for hyper to create channel
            while True:
                try:
                    self._sock.connect(self.__args)
                    break
                except socket.error as e:
                    print("error connecting", e)
                    if e.errno == errno.EHOSTUNREACH or e.errno == errno.ECONNREFUSED:
                        time.sleep(1)
                    else:
                        self._sock.close()
                        raise

            #Wait for guest agent to initialize and sync
            while True:
                import random
                key = random.randint(0, 0xffffffff)
                msg = json.dumps({'execute':'guest-sync-delimited','arguments':{'id':key}},separators=(',',':'),sort_keys=True)
                self._sock.send(msg.encode('ascii'))

                self._sock.setblocking(0)
                response = b''
                if (select.select([self._sock],[],[])[0]):
                    response += self._sock.recv(65536)
                else:
                    raise RuntimeError()
                self._sock.setblocking(1)

                sentinel = b'\xff'
                response = response.split(sentinel)[-1]
                if not response:
                    time.sleep(3)
                    continue
                response = json.loads(response.decode('utf-8').strip())
                if 'return' in response.keys():
                    if int(response['return']) == key:
                        break
                time.sleep(3)
        else:
            self._sock.connect(self.__args)

        return self

    def __exit__(self,*a):
        self._sock.close()

    def transact(self,cmd,args={}):
        ''' Exchange a single command with guest agent '''
        timeout = 2
        msg = json.dumps({'execute':cmd,'arguments':args},separators=(',',':'),sort_keys=True)
        self._sock.send(msg.encode('ascii'))
        self._sock.setblocking(0)
        response = b''
        if (select.select([self._sock],[],[],timeout)[0]):
            response += self._sock.recv(65536)
        self._sock.setblocking(1)
        if not response:
            response = None
        else:
            if response[0] == 255: # sync
                response = response[1:]
            print(response.decode('utf-8').strip())
            response = json.loads(response.decode('utf-8').strip())
            if 'error' in response.keys():
                self._qmpError(response['error']['class'],response['error']['desc'])
                response = None
            elif 'return' in response:
                response = response['return']
        return response

#-------------------------------------------------------------------------------

if __name__ == '__main__':
    socketpath,filename=sys.argv[1:]
    script = open(filename,"r").readlines()

    with SocketAgent.unix(socketpath) as agent:
        ret,out = agent.runSource(script)
        print('ret = {}'.format(ret))
        for line in out:
            print(line)
