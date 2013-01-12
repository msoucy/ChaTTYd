#!/usr/bin/rdmd

module chatty.chatty;

import chatty.server;
import chatty.client;

import std.stdio;
import std.string;
import std.getopt;
import std.process;

import std.c.stdlib : exit;

import metus.dzmq.dzmq;
import metus.dzmq.devices;
import metus.dncurses.dncurses;

// Client-to-server connections
enum SERV_PORT = 5670;
// Server-to-client connections
enum CLNT_PORT = 5671;

void printHelp() {
	"Usage: ChaTTYd [-t topic] [-s server] [-p outport] [-i inport]".writeln();
}

/*
Architecture requires two PUB/SUB sockets
*/
void main(string[] argv) {
	
	uint outport=0;
	uint inport=0;
	string server="localhost";
	string topic="/main";
	string user=getenv("USER");
	bool isServer=false;
	bool verbose=false;
	getopt(argv,
			"topic|t", &topic,
			"server|s", &server,
			"port|p", &outport,
			"inport|i", &inport,
			"serve", &isServer,
			"user|u", &user,
			"verbose|v", &verbose);
	if(argv.length!=1) {
		printHelp();
		exit(-1);
	}

	auto ctx = new Context(1);

	if(isServer) {
		auto s = new Server(ctx);
		s.init(verbose, inport?inport:SERV_PORT, outport?outport:CLNT_PORT);
		s.run();
	} else {
		initscr();
		scope(exit) endwin();
		initColor();
		mode=Raw();
		echo=false;

		auto c = new Client(ctx);
		c.init(user, server, topic, inport?inport:CLNT_PORT, outport?outport:SERV_PORT);
		c.run();
	}
	
}
