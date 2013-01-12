module chatty.client;

import std.stdio;
import std.string;
import std.ascii;
import std.math;

import chatty.message;

import metus.dzmq.dzmq;
import metus.dzmq.devices;
import metus.dncurses.dncurses;

enum use_ncurses=true;

class Client : Device {

	private {
		Socket receiver, sender;
		Context ctx;

		string topic;
		string currMsg="";
		string user;
		long msgPos=0;

		Window inWin, outWin, topicWin;
		enum QUIT_STR = "/quit";
	}

	this(Context ctx) {
		this.ctx=ctx;
	}

	void init(string _user, string server, string _topic, uint inport, uint outport) {
		this.user = _user;
		server = "tcp://%s:%%s".format(server);
		if(!_topic.length) _topic="/main";
		if(!_topic.startsWith('/')) _topic = '/'~_topic;
		this.topic = _topic;
	
		this.sender = new Socket(ctx, Socket.Type.PUB);
		this.sender.connect(server.format(outport));

		this.receiver = new Socket(ctx, Socket.Type.SUB);
		this.receiver.connect(server.format(inport));
		this.receiver.subscribe(topic);

		inWin = new Window(stdwin, 1, stdwin.max.x+1, stdwin.max.y, 0);
		inWin.timeout=250;
		inWin.keypad=true;
		inWin.meta=true;
		inWin.bkgd(bg(Color.BLUE));
		inWin.clear();

		topicWin = new Window(stdwin, 1, stdwin.max.x+1, stdwin.max.y-1, 0);
		topicWin.bkgd(bg(Color.GREEN));
		topicWin.clear();
		
		outWin = new Window(stdwin, stdwin.max.y-1, stdwin.max.x+1, 0, 0);
		outWin.scrollok=true;
		outWin.clear();

		stdwin.refresh();
		outWin.refresh();
		topicWin.refresh();
		inWin.refresh();
	}

	private void printMsg(Message msg) {
		outWin.put(bold,
			fg(Color.RED),'[',msg.topic,"] ",
			fg(Color.BLUE), msg.user,
			nobold, nofg,
			": ", msg.msg, '\n');
	}

	private string read() {
		string ret = null;

		auto c = inWin.getch();
		if(c == -1) {
			// Timeout
			return ret;

		} else if(c=='\n' || c==Key.Enter) {
			// Enter
			msgPos = 0;
			ret = currMsg;
			currMsg = "";

		} else if(c==0x04 || c==0x03) {
			// ^C, ^D
			ret=QUIT_STR;

		} else if(c==Key.Left) {
			// Move left once
			msgPos=msgPos>0?msgPos-1:0;

		} else if(c==Key.Right) {
			// Move right once
			msgPos=msgPos+1<currMsg.length?msgPos+1:currMsg.length;

		} else if(c==Key.Home) {
			// Move all the way left
			msgPos=0;

		} else if(c==Key.End) {
			// Move all the way right
			msgPos=currMsg.length;

		} else if(c==Key.Backspace) {
			// Backspace
			if(msgPos != 0) {
				currMsg=currMsg[0..msgPos-1]~currMsg[msgPos..$];
				msgPos--;
			}

		} else if(c==Key.DC) {
			// Delete
			if(msgPos != currMsg.length) {
				currMsg=currMsg[0..msgPos]~currMsg[msgPos+1..$];
			}

		} else if(c.isPrintable()) {
			// Printable character
			currMsg = currMsg[0..msgPos]~(c&0xFF)~currMsg[msgPos..$];
			msgPos++;
		}

		inWin.clear();
		auto ldelta = (inWin.max.x)*3/4;
		auto rdelta = (inWin.max.x)-ldelta;
		if(msgPos >= ldelta) {
			inWin.put(currMsg[((msgPos-ldelta >= 0)?msgPos-ldelta:0) .. ((msgPos+rdelta < $)?msgPos+rdelta-1:$)]);
			inWin.cursor(0, ldelta);
		} else {
			inWin.put(currMsg[0..(inWin.max.x>$?$:inWin.max.x)]);
			inWin.cursor(0, msgPos.to!int());
		}

		inWin.refresh();
		return ret;
	}

	void run() {

		topicWin.put(
			"User: ", this.user,
			"\t",
			"Topic: [", bold, this.topic, nobold, "]",
		);
		topicWin.refresh();

		auto msg = new Message(this.topic, this.user, null);
		while(1) {
			try {
				msg.msg = read();
				if(msg.msg==QUIT_STR) {
					break;
				} else if(msg.msg !is null && msg.msg.length != 0) {
					this.sender.send_msg(msg);
					currMsg.length=0;
				}
				Message rcv=null;
				while(1) {
					rcv = this.receiver.recv_msg(Socket.Flags.NOBLOCK);
					if(rcv is null) {
						break;
					} else {
						printMsg(rcv);
					}
				}
				outWin.refresh();
				inWin.refresh();
				
			} catch(ZMQException e) {
				outWin.put("Communication error: ", e.msg, '\n');
			}
		}
		
	}
}
