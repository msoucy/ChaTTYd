module chatty.server;

import std.stdio;

import chatty.message;

import metus.dzmq.dzmq;
import metus.dzmq.devices;

class Server : Device {

	private {
		Socket receiver, sender;
		Context ctx;
		bool verbose;
	}

	this(Context ctx) {
		this.ctx=ctx;
	}

	void init(bool _verbose, uint inport, uint outport) {
		this.verbose = _verbose;

		// Socket to read from clients
		this.receiver = new Socket(ctx, Socket.Type.SUB);
		this.receiver.bind("tcp://*:%s".format(inport));
		this.receiver.subscribe(""); // Subscribe to everything
		
		// Socket to talk to clients
		this.sender = new Socket(ctx, Socket.Type.PUB);
		this.sender.bind("tcp://*:%s".format(outport));
	}

	void run() {
		if(verbose) {
			while(1) {
				auto msg = this.receiver.recv_msg();
				writeln(msg);
				if(msg.msg.length) {
					this.sender.send_msg(msg);
				}
			}
		} else {
			auto dev = new ForwarderDevice(this.receiver, this.sender);
			dev.run();
		}
	}

}