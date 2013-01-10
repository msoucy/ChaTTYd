module chatty.client;

import std.stdio;

import chatty.message;

import metus.dzmq.dzmq;
import metus.dzmq.devices;

class Client : Device {

	private {
		Socket receiver, sender;
		Context ctx;
	}

	this(Context ctx) {
		this.ctx=ctx;
	}

	void init(string server, string topic, uint inport, uint outport) {
		server = "tcp://%s:%%s".format(server);
		if(!topic.length) topic="/";
		if(topic[0] != '/') topic = '/'~topic;
	
		this.sender = new Socket(ctx, Socket.Type.PUB);
		this.sender.connect(server.format(outport));

		this.receiver = new Socket(ctx, Socket.Type.SUB);
		this.receiver.connect(server.format(inport));
		this.receiver.subscribe(topic);
		writefln("Port: %s\nInport: %s\nServer: %s\nTopic: %s", outport, inport, server, topic);
	}

	void run() {

		while(1) {
			try {
				writef("> ");
				this.sender.send(["/", readln()[0..$-1]]);
				this.receiver.recv_multipart().writeln();
			} catch(ZMQException e) {
			}
		}
	}
}