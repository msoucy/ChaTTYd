module chatty.client;

import std.stdio;
import std.process;
import std.string;

import chatty.message;

import metus.dzmq.dzmq;
import metus.dzmq.devices;

class Client : Device {

	private {
		Socket receiver, sender;
		Context ctx;
		string topic;
	}

	this(Context ctx) {
		this.ctx=ctx;
	}

	void init(string server, string _topic, uint inport, uint outport) {
		server = "tcp://%s:%%s".format(server);
		if(!_topic.length) _topic="/";
		if(_topic[0] != '/') _topic = '/'~_topic;
		this.topic = _topic;
	
		this.sender = new Socket(ctx, Socket.Type.PUB);
		this.sender.connect(server.format(outport));

		this.receiver = new Socket(ctx, Socket.Type.SUB);
		this.receiver.connect(server.format(inport));
		this.receiver.subscribe(topic);
		writefln("Port: %s\nInport: %s\nServer: %s\nTopic: %s", outport, inport, server, topic);
	}

	void run() {
		auto msg = new Message(this.topic, getenv("USER"), null);
		while(1) {
			try {
				writef("> ");
				msg.msg = readln().strip();
				if(msg.msg=="/quit") {
					break;
				} else if(msg.msg.length) {
					this.sender.send_msg(msg);
				}
				Message rcv=null;
				while(1) {
					rcv = this.receiver.recv_msg(Socket.Flags.NOBLOCK);
					if(rcv is null) {
						break;
					}
					rcv.writeln();
				}
				
			} catch(ZMQException e) {
			}
		}
	}
}