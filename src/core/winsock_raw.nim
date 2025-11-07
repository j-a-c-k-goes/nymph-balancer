# winsock_raw: raw windows socket implementation for nymph-balancer

import std/winlean

type
  WinSocket* = cuint                        # windows socket handle
  
  WSAData* = object
    wVersion*: cushort                      # winsock version
    wHighVersion*: cushort                  # highest winsock version
    szDescription*: array[257, char]        # implementation description
    szSystemStatus*: array[129, char]       # system status
    iMaxSockets*: cushort                   # max sockets (obsolete)
    iMaxUdpDg*: cushort                     # max udp datagram size
    lpVendorInfo*: pointer                  # vendor info pointer

  SockAddrIn* = object
    family*: cushort                        # address family (AF_INET)
    port*: cushort                          # port number (network byte order)
    address*: cuint                         # ip address (network byte order)
    zero*: array[8, char]                   # padding to match sockaddr size
  
  FdSet* = object
    fd_count*: cuint                        # number of sockets in set
    fd_array*: array[FD_SETSIZE, WinSocket] # array of socket handles
  
  TimeVal* = object
    tv_sec*: clong                          # seconds
    tv_usec*: clong                         # microseconds

const
  AF_INET* = 2                              # ipv4 address family
  SOCK_STREAM* = 1                          # tcp socket type
  IPPROTO_TCP* = 6                          # tcp protocol
  SOL_SOCKET* = 0xFFFF                      # socket level options
  SO_REUSEADDR* = 0x0004                    # allow address reuse
  TCP_NODELAY* = 0x0001                     # disable nagle algorithm
  INADDR_ANY* = 0                           # bind to all interfaces
  INVALID_SOCKET* = WinSocket(not 0)        # invalid socket handle
  SOCKET_ERROR* = -1                        # socket operation error
  FIONBIO = 0x8004667E                      # set non-blocking mode
  FD_SETSIZE* = 64                          # max sockets in fd_set

proc WSAStartup*(wVersionRequired: cushort, lpWSAData: ptr WSAData): cint {.stdcall, dynlib: "ws2_32", importc.}
proc WSACleanup*(): cint {.stdcall, dynlib: "ws2_32", importc.}
proc socket*(af, socktype, protocol: cint): WinSocket {.stdcall, dynlib: "ws2_32", importc.}
proc bindSocket*(s: WinSocket, name: ptr SockAddrIn, namelen: cint): cint {.stdcall, dynlib: "ws2_32", importc: "bind".}
proc listenSocket*(s: WinSocket, backlog: cint): cint {.stdcall, dynlib: "ws2_32", importc: "listen".}
proc acceptSocket*(s: WinSocket, address: ptr SockAddrIn, addrlen: ptr cint): WinSocket {.stdcall, dynlib: "ws2_32", importc: "accept".}
proc recv*(s: WinSocket, buf: pointer, len: cint, flags: cint): cint {.stdcall, dynlib: "ws2_32", importc.}
proc send*(s: WinSocket, buf: pointer, len: cint, flags: cint): cint {.stdcall, dynlib: "ws2_32", importc.}
proc closesocket*(s: WinSocket): cint {.stdcall, dynlib: "ws2_32", importc.}
proc setsockopt*(s: WinSocket, level, optname: cint, optval: pointer, optlen: cint): cint {.stdcall, dynlib: "ws2_32", importc.}
proc connect*(s: WinSocket, name: ptr SockAddrIn, namelen: cint): cint {.stdcall, dynlib: "ws2_32", importc.}
proc htons*(hostshort: cushort): cushort {.stdcall, dynlib: "ws2_32", importc.}
proc inet_addr*(cp: cstring): cuint {.stdcall, dynlib: "ws2_32", importc.}
proc ioctlsocket*(s: WinSocket, cmd: clong, argp: ptr culong): cint {.stdcall, dynlib: "ws2_32", importc.}
proc selectSocket*(nfds: cint, readfds, writefds, exceptfds: pointer, timeout: pointer): cint {.stdcall, dynlib: "ws2_32", importc: "select".}

proc init_winsock*(): bool =
  ## initialize winsock library
  var wsaData: WSAData
  let wsaResult = WSAStartup(0x0202, addr wsaData)
  return wsaResult == 0

proc cleanup_winsock*() =
  ## cleanup winsock library resources
  discard WSACleanup()

proc fd_zero*(set: var FdSet) =
  set.fd_count = 0

proc fd_set*(fd: WinSocket, set: var FdSet) =
  if set.fd_count < FD_SETSIZE:
    set.fd_array[set.fd_count] = fd
    set.fd_count += 1

proc fd_isset*(fd: WinSocket, set: var FdSet): bool =
  for i in 0..<set.fd_count:
    if set.fd_array[i] == fd:
      return true
  return false

proc set_nonblocking*(sock: WinSocket) =
  ## set socket to non-blocking mode
  var nonBlocking: culong = 1
  discard ioctlsocket(sock, cast[clong](FIONBIO), addr nonBlocking)

proc create_server_socket*(port: int): WinSocket =
  ## create optimized server socket
  let sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
  if sock == INVALID_SOCKET:
    raise newException(OSError, "failed to create socket")
  
  # enable address reuse
  var optval: cint = 1
  if setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, addr optval, sizeof(optval).cint) == SOCKET_ERROR:
    discard closesocket(sock)
    raise newException(OSError, "failed to set SO_REUSEADDR")
  
  # disable Nagle's algorithm
  if setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, addr optval, sizeof(optval).cint) == SOCKET_ERROR:
    discard closesocket(sock)
    raise newException(OSError, "failed to set TCP_NODELAY")
  
  # bind to port
  var serverAddr = SockAddrIn(
    family: AF_INET.cushort,
    port: htons(port.cushort),
    address: INADDR_ANY.cuint
  )
  
  if bindSocket(sock, addr serverAddr, sizeof(SockAddrIn).cint) == SOCKET_ERROR:
    discard closesocket(sock)
    raise newException(OSError, "failed to bind to port " & $port)
  
  # listen with large backlog
  if listenSocket(sock, 511) == SOCKET_ERROR:
    discard closesocket(sock)
    raise newException(OSError, "failed to listen on socket")
  
  return sock

proc accept_connection*(serverSocket: WinSocket): WinSocket =
  ## accept incoming connection
  var clientAddr: SockAddrIn
  var addrLen      = sizeof(SockAddrIn).cint
  let clientSocket = acceptSocket(serverSocket, addr clientAddr, addr addrLen)
  if clientSocket != INVALID_SOCKET:
    var optval: cint = 1
    discard setsockopt(clientSocket, IPPROTO_TCP, TCP_NODELAY, addr optval, sizeof(optval).cint)
  return clientSocket

proc shutdown*(sock: WinSocket, how: cint): cint {.stdcall, dynlib: "ws2_32", importc.}

proc connect_to_backend*(host: string, port: int): WinSocket =
  ## connect to backend server
  let sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
  if sock == INVALID_SOCKET:
    return INVALID_SOCKET
  var optval: cint = 1
  discard setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, addr optval, sizeof(optval).cint)
  var backendAddr = SockAddrIn(
    family:  AF_INET.cushort,
    port:    htons(port.cushort),
    address: inet_addr(host.cstring)
  )
  if connect(sock, addr backendAddr, sizeof(SockAddrIn).cint) == SOCKET_ERROR:
    discard closesocket(sock)
    return INVALID_SOCKET
  return sock