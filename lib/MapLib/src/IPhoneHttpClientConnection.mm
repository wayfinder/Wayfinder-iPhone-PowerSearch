/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "IPhoneHttpClientConnection.h"

#define RECEIVING_TIMEOUT_MS 30*1000  //30 seconds in milliseconds

static BOOL showDebug = NO;

IPhoneHttpClientConnection::IPhoneHttpClientConnection(const char* host, unsigned int port,
                           HttpClientConnectionListener* listener,
                           TCPConnectionHandler* connectionHandler)
    : HttpClientConnection(host, port, listener, connectionHandler),
      connHandler(connectionHandler),
      jamTimer(0)
{
}


IPhoneHttpClientConnection::~IPhoneHttpClientConnection()
{
}


void IPhoneHttpClientConnection::writeDone(status_t status)
{
    HttpClientConnection::writeDone(status);
    
    if (status == TCPClientConnection::OK) {
        
        if (jamTimer) {
            connHandler->cancelTimer(jamTimer);
        }
        
        jamTimer = connHandler->requestTimer(RECEIVING_TIMEOUT_MS, this);
    }
}

   
void IPhoneHttpClientConnection::timerExpired(int timerID)
{
    HttpClientConnection::timerExpired(timerID);

    if (timerID == jamTimer) {
        
        if (showDebug) NSLog(@"jamTimer expired");

        jamTimer = 0;
    
        if (getNbrSent()) { //still waiting data from server
            if (showDebug) NSLog(@"Close and reconnect.");
            connectionClosed(TCPClientConnection::TIMEOUT);
            writeNextRequest();
        }
    }
}


void IPhoneHttpClientConnection::readDone(status_t status,
                                          const byte* bytes,
                                          int nbrBytes)
{
    HttpClientConnection::readDone(status, bytes, nbrBytes);
   
    if (!getNbrSent()) { 
        if (showDebug) NSLog(@"Everything arrived. Stop jamTimer."); 

        if (jamTimer) {
            connHandler->cancelTimer(jamTimer);
            jamTimer = 0;
        }
    }
}

