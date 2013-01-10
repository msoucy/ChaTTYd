module chatty.server;

import std.stdio;

import chatty.message;

import metus.dzmq.dzmq;
import metus.dzmq.devices;

class Server : Device {

	private {
		Socket receiver, sender;
		Context ctx;
	}

	this(Context ctx) {
		this.ctx=ctx;
	}

	void init(uint inport, uint outport) {
		// Socket to talk to clients
		this.receiver = new Socket(ctx, Socket.Type.SUB);
		this.receiver.bind("tcp://*:%s".format(inport));
		this.receiver.subscribe(""); // Subscribe to everything
		
		this.sender = new Socket(ctx, Socket.Type.PUB);
		this.sender.bind("tcp://*:%s".format(outport));
		writefln("Port: %s\nInport: %s", outport, inport);
	}

	void run() {
		auto dev = new ForwarderDevice(this.receiver, this.sender);
		dev.run();
	}

}