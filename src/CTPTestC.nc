/**
 Copyright (C),2014-2015, YTC, www.bjfulinux.cn
 Copyright (C),2014-2015, ENS Group, ens.bjfu.edu.cn
 Created on  2015-05-08 14:49
 
 @author: ytc recessburton@gmail.com
 @version: 1.0
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>
 **/

#include <Timer.h>
module CTPTestC{
	uses{
		interface Boot;
		interface SplitControl as RadioControl;
		interface StdControl as RoutingControl;
		interface Send;
		interface Leds;
		interface Timer<TMilli>;
		interface RootControl;
		interface Receive;
	}
}
implementation{
	
	message_t packet;
	
	volatile bool sendBusy = FALSE;
	
	typedef nx_struct CTPMsg{
		nx_int16_t data;
	}CTPMsg;
	
	event void Boot.booted(){
		call RadioControl.start();	
	}
	
	event void RadioControl.startDone(error_t err){
		if(err != SUCCESS){
			call RadioControl.start();
		}else{
			call RoutingControl.start();
			if(TOS_NODE_ID == 1)
				call RootControl.setRoot();
			else
				call Timer.startPeriodic(2000);	
		}
	}
	
	event void RadioControl.stopDone(error_t err){	
	}
	
	void sendMessage(){
		CTPMsg* msg = (CTPMsg*)call Send.getPayload(&packet, sizeof(CTPMsg));
		msg -> data = 0xAAAA;
		if(call Send.send(&packet, sizeof(CTPMsg)) != SUCCESS)
			call Leds.led0On();
		else
			sendBusy = TRUE;	
	}
	
	event void Timer.fired(){
		call Leds.led2Toggle();
		if( !sendBusy)
			sendMessage();
	}
	
	event void Send.sendDone(message_t* m, error_t err){
		if(err != SUCCESS)
			call Leds.led0On();
		sendBusy = FALSE;	
	}
	
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		call Leds.led1Toggle();
		return msg;	
	}
	
}