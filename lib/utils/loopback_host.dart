/// True when a request's Host header names this loopback server on [port].
///
/// The local web servers bind to 127.0.0.1 only, but a web page can still
/// reach them through DNS rebinding with its own hostname. Rejecting any
/// other Host value blocks that.
bool isLoopbackHost(String? hostHeader, int port) {
  final host = hostHeader?.toLowerCase();
  return host == '127.0.0.1:$port' || host == 'localhost:$port';
}
