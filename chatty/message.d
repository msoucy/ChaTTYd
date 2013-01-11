module chatty.message;

import std.exception;

import metus.dzmq.dzmq;
import metus.dzmq.devices;

/**
 * Store and parse a CHaTTY message
 * 
 * @brief BigBrother message wrapper
 * @author Matthew Soucy <msoucy@csh.rit.edu>
 */
class Message {
	/// Topic of the message
	string topic;
	/// List of all hubs that the message has visited
	string user;
	/// Message body
	string msg;

	/**
	 * Constructor
	 * Any of the arguments can be null
	 */
	this(string t, string u, string m) {
		topic=t;
		user=u;
		msg=m;
	}

	/**
	 * Convert to a string: Testing stuff
	 */
	override string toString() {
		return "[%s] %s: %s".format(topic, user, msg);
	}
}


/**
 * Receive a CHaTTY message via a socket
 * 
 * Receives and forms a Message from the provided socket.
 * Designed with UFCS in mind.
 * 
 * @param sock The socket to receive a Message from
 * @param flags The socket flags to use
 * @returns The Message received
 * 
 * @brief CHaTTY message receiver
 * @authors Matthew Soucy <msoucy@csh.rit.edu>
 */
Message recv_msg(Socket sock, int flags=0) {
	string[] raw = sock.recv_multipart(flags);
	if(raw is null) return null;
	// We can verify this, since the CHaTTY protocol requires it
	enforce(raw.length == 3, "Invalid CHaTTY packet");
	return new Message(raw[0], raw[1], raw[2]);
}

/**
 * Send a CHaTTY message via a socket
 * 
 * Sends an already created Message via the Socket
 * Designed with UFCS in mind.
 * 
 * @param sock The socket to send a Message with
 * @param msg The message to send
 * @param flags The socket flags to use
 * 
 * @brief CHaTTY message sender
 * @author Matthew Soucy <msoucy@csh.rit.edu>
 */
void send_msg(Socket sock, const Message msg, int flags=0) {
	sock.send([msg.topic, msg.user, msg.msg], flags);
}