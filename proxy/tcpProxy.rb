#!/usr/bin/env ruby

# HTTP/SSL proxy for api.steampoweered.com
#
# Modified from: https://github.com/applidium/Cracking-Siri/blob/master/tcpProxy.rb 
# Originally by: http://applidium.com


require "socket"
require "openssl"
require "thread"

Thread.new do

  listeningPort = 443

  server = TCPServer.new(listeningPort)
  sslContext = OpenSSL::SSL::SSLContext.new
  sslContext.key = OpenSSL::PKey::RSA.new(File.open("server.key").read)
  sslContext.cert = OpenSSL::X509::Certificate.new(File.open("server.crt").read)
  sslContext.verify_mode = OpenSSL::SSL::VERIFY_NONE
  sslServer = OpenSSL::SSL::SSLServer.new(server, sslContext)
  puts "Listening on port #{listeningPort}"

  bufferSize = 1

  loop do
    connection = sslServer.accept
    Thread.new do
      socket = TCPSocket.new('api.steampowered.com', 443)
      ssl = OpenSSL::SSL::SSLSocket.new(socket)
      ssl.sync_close = true
      ssl.connect
      Thread.new do
        begin
          while lineIn = ssl.readchar
            connection.write lineIn
            $stdout.putc lineIn
          end
        rescue
          $stderr.puts "Error in input loop: " + $!
        end
      end
 
      begin
        while (lineOut = connection.readchar)
          ssl.write lineOut
          $stdout.putc lineOut
        end
      rescue
        $stderr.puts "Error in ouput loop: " + $!
      end
    end
  end
end

listeningPort = 80
server = TCPServer.new(listeningPort)

loop do
  connection = server.accept
  Thread.new do
    socket = TCPSocket.new('api.steampowered.com', 80)
    Thread.new do
      begin
        while lineIn = socket.readchar
          connection.write lineIn
          $stdout.putc lineIn
        end
      rescue
        $stderr.puts "Error in input loop: " + $!
      end
    end
  
    begin
      while (lineOut = connection.readchar)
        socket.write lineOut
        $stdout.putc lineOut
      end
    rescue
      $stderr.puts "Error in ouput loop: " + $!
    end
  end
end

