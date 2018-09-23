All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted (subject to 
the limitations in the disclaimer below) provided that the following conditions are met: 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following 
   disclaimer in the documentation and/or other materials provided with the distribution. 
 * Neither the name of Computer History Museum nor the names of its contributors may be used to endorse or promote products 
   derived from this software without specific prior written permission. 
NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE GRANTED BY THIS LICENSE. THIS SOFTWARE IS PROVIDED BY THE 
COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
DAMAGE. */

#include "tcp.h"
#define FILE_NUM 37
/* Copyright (c) 1990-1992 by the University of Illinois Board of Trustees */
/************************************************************************
 * functions for i/o over a pseudo-telnet MacTcp stream
 * these functions are oriented toward CONVENIENCE, not performance
 ************************************************************************/

#pragma segment TcpTrans

/************************************************************************
 * private functions
 ************************************************************************/
#define TcpTrouble(stream,which,err) TT(stream,which,err,FNAME_STRN+FILE_NUM,__LINE__)
int TT(TransStream stream,int which, int theErr, int file, int line);
uLong RandomAddr(uLong *addrs);
void NoteAddrGoodness(struct hostInfo *hip,uLong addr,short err);
pascal void BindDone(struct hostInfo *hostInfoPtr, char *userData);
pascal void TcpASR(StreamPtr tcpStream, unsigned short eventCode,UPtr userDataPtr, unsigned short terminReason, struct ICMPReport *icmpMsg);

/**********************************************************************
 * ConnectTransLo - connect to a host
 **********************************************************************/
OSErr ConnectTrans(TransStream stream, UPtr serverName, long port, Boolean silently,uLong timeout)
{
	Str255 realHost;
	
	PCopy(realHost,serverName);
	
	SplitPort(realHost,&amp;port);

	return ConnectTransLo(stream,realHost,port,silently,timeout);
}

/**********************************************************************
 * SplitPort - Split host:port into components
 *  returns true if port found
 **********************************************************************/
Boolean SplitPort(PStr host,long *port)
{
	UPtr colon;
	long localPort;
	
	if (colon=PIndex(host,':'))
	{
		*colon = *host - (colon-host);
		*host = colon-host-1;
		StringToNum(colon,&amp;localPort);
		ASSERT(localPort&gt;0);
		if (localPort&gt;0 &amp;&amp; port) *port = localPort;
		return true;
	}
	
	return false;
}

/**********************************************************************
 * RandomAddr - pick a random address out of a set of addresses
 **********************************************************************/
uLong RandomAddr(uLong *addrs)
{
	short count;
	if (!PrefIsSet(PREF_DNS_BALANCE)) return(addrs[0]);
	
	for (count=NUM_ALT_ADDRS;count;count--) if (addrs[count-1]) break;
	return(addrs[count&lt;2?0:TickCount()%count]);
}

/**********************************************************************
 * NoteAddrGoodness - remove an address or all except an address
 **********************************************************************/
void NoteAddrGoodness(struct hostInfo *hip,uLong addr,short err)
{
	short count,i;

	if (!PrefIsSet(PREF_DNS_BALANCE)) return;
	
	for (count=NUM_ALT_ADDRS;count;count--) if (hip-&gt;addr[count-1]==addr) break;

	if (err)
	{
		/* this addr didn't work.  remove it */
		for (i=count;i&lt;NUM_ALT_ADDRS;i++) hip-&gt;addr[i-1] = hip-&gt;addr[i];
		hip-&gt;addr[NUM_ALT_ADDRS-1] = 0;
		if (count==1) *hip-&gt;cname = 0;	/* if used last addr, kill the name to force another lookup */
	}
	else
	{
		/* mark the OTHERS as dead. */
		WriteZero(hip-&gt;addr,sizeof(uLong)*NUM_ALT_ADDRS);
		hip-&gt;addr[0] = addr;
	}
}

#pragma segment Main
/************************************************************************
 * BindDone - report that the resolver has done its duty
 ************************************************************************/
pascal void BindDone(struct hostInfo *hostInfoPtr, char *userData)
{
	*(short *)userData = hostInfoPtr-&gt;rtnCode;
	return;
}
#pragma segment TcpTrans

/************************************************************************
 * TcpTrouble - report an error with TCP and break the connection
 ************************************************************************/
int TT(TransStream stream, int which, int theErr, int file, int line)
{	
	if (stream==0 || (!stream-&gt;BeSilent &amp;&amp; (!CommandPeriod || stream-&gt;Opening&amp;&amp;!PrefIsSet(PREF_OFFLINE)&amp;&amp;!PrefIsSet(PREF_NO_OFF_OFFER))))
	{
		Str255 message;
		Str255 tcpMessage;
		Str63 debugStr;
		Str31 rawNumber;
		short realSettingsRef = SettingsRefN;

		NumToString(theErr,rawNumber);
		
		SettingsRefN = GetMainGlobalSettingsRefN();
		GetRString(message, which);
		if (-23000&gt;=theErr &amp;&amp; theErr &gt;=-23048)
			GetRString(tcpMessage,MACTCP_ERR_STRN-22999-theErr);
		else if (2&lt;=theErr &amp;&amp; theErr&lt;=9)
			GetRString(tcpMessage,MACTCP_ERR_STRN+theErr+(23048-23000));
		else
			*tcpMessage = 0;
		ComposeRString(debugStr,FILE_LINE_FMT,file,line);
		SettingsRefN = realSettingsRef;


		MyParamText(message,rawNumber,tcpMessage,debugStr);
		if (stream==0 || stream-&gt;Opening)
		{
			if (2==ReallyDoAnAlert(OPEN_ERR_ALRT,Caution))
				SetPref(PREF_OFFLINE,YesStr);
		}
		else ReallyDoAnAlert(BIG_OK_ALRT,Caution);
	}
	return(stream ? (stream-&gt;streamErr=theErr) : theErr);
}

/************************************************************************
 * TcpASR - asynchronous notification routine
 ************************************************************************/
pascal void TcpASR(StreamPtr tcpStream, unsigned short eventCode,
	UPtr userDataPtr, unsigned short terminReason, struct ICMPReport *icmpMsg)
{
//#pragma unused(userDataPtr)
	if (tcpStream==((TransStreamPtr)userDataPtr)-&gt;TcpStream)
	{
		if (eventCode==TCPDataArrival) ((TransStreamPtr)userDataPtr)-&gt;CharsAvail = 1;
		else if (eventCode==TCPICMPReceived)
		{
			ICMPAvail = 1;
			ICMPMessage = *icmpMsg;
		}
		else if (eventCode==TCPTerminate)
		{
			WhyTCPTerminated = terminReason;
		}
	}
}


#pragma segment TcpTrans
/*********************************************************************************
 * Eudora might should take advantage of native Open Transport TCP/IP when it's 
 * installed.  The following functions implement the same as the MacTCP ones above,
 * but employ OT.  There's also some PPP stuff here, too.
 *********************************************************************************/
 
OSErr pppErr = noErr;
MyOTPPPInfoStruct	MyOTPPPInfo;
unsigned long connectionSelection = kOtherSelected;
long oldDlogState = 0;
Boolean needPPPConnection = false;	//used to determine when PPP is down but should be up.
Boolean OTinitialized = false;
Boolean dialingThePhone = false;			//set to true after we've dialed the phone.
Boolean gUpdateTPWindow = false;	// set to true when the connection method changes to invalidate the TP window

//setup
Boolean HasOTInetLib(void);
Boolean OTSupported(void);
OSErr OpenOTInternetServices(MyOTInetSvcInfo *myOTInfo);
pascal void MyOTNotifyProc(MyOTInetSvcInfo *info, OTEventCode theEvent, OTResult theResult, void *theParam);
OSErr CreateOTStream(TransStream stream);
OSErr OTTCPOpen(TransStream stream, InetHost tryAddr, InetPort port,uLong timeout);
void EnqueueMyTStream(MyOTTCPStreamPtr myStream);
void DestroyMyTStream(MyOTTCPStreamPtr myStream);

//communication
OSErr OTGetHostByName(InetDomainName hostName, InetHostInfo *hostInfoPtr);
OSErr OTGetHostByAddr(InetHost addr, InetHostInfo *domainNamePtr);
InetHost OTRandomAddr(InetHostInfo *host);
OSErr OTGetDomainMX(InetDomainName hostName, InetMailExchange *MXPtr, short *numMX);
void GetPreferredMX(InetDomainName preferred, InetMailExchange *MXPtr, short numMX);
short OTWaitForChars(TransStream stream, long timeout, UPtr line, long *size, OTResult *otResult);
pascal void MyOTStreamNotifyProc (MyOTTCPStream *myStream, OTEventCode code, OTResult theResult, void *theParam);
short SpinOnWithConnectionCheck(short *rtnCodeAddr,long maxTicks,Boolean allowCancel,Boolean forever);

//error reporting
OSErr OTTE(TransStream stream, OSErr generalError, OSErr specficError, short file, short line);
#define OTTCPError(stream,generalError,specficError) OTTE(stream,generalError,specficError,FNAME_STRN+FILE_NUM,__LINE__)
#define IsMyOTError(x) (x &gt;= errOTInitFailed &amp;&amp; x &lt;= errMyLastOTErr)
#define IsOTPPPError(x) (x &lt;= kCCLErrorStart &amp;&amp; x &gt;= kCCLErrorEnd)

//PPP functions
OSErr OTVerifyOpen(TransStream stream);
OSErr OTPPPConnect(Boolean *attemptedConnection);
OSErr GetPPPConnectionState(EndpointRef endPoint, unsigned long *PPPState);
pascal void MyPPPEndpointNotifier(void *context, OTEventCode code, OTResult result, void *cookie);
OSErr TurnOnPPPConnectionDialog(EndpointRef endPoint, Boolean on);
OSErr ResetPPPConnectionDialog(EndpointRef endPoint);
OSErr WaitForOTPPPDisconnect(Boolean showStatus);
OTResult NewPPPControlEndpoint(void);
OSErr GetCurrentUInt32Option(EndpointRef endPoint, OTXTIName theOption, UInt32 *value);
OSErr SetCurrentUInt32Option(EndpointRef endPoint, OTXTIName theOption, UInt32 value);
OSErr OTPPPDialingInformation(Boolean *redial, unsigned long *numRedials, unsigned long *delay);
Boolean SearchDirectoryForFile(CInfoPBRec *info, long dirToSearch, OSType type, OSType creator);
void UpdateCachedConnectionMethodInfo(void);

/*********************************************************************************
 * OTInitOpenTransport - initialize open transport if present.
 *********************************************************************************/
void OTInitOpenTransport(void)
{	
	//if we have OT &amp;&amp; TCP, then try to initialize it
	if (OTIs)	
	{
		if (!HasOTInetLib())
		{
		 	gUseOT = false;
		 	
		 	// Only warn the user if we know OT works on this machine
		 	if (OTSupported()) OTTCPError(NULL,errOTInitFailed,errOTMissingLib);
		}
		else 
		{
			gUseOT = true;
		
			//Initialize if we haven't already.
			if (!OTinitialized)
			{	
				OSStatus osStatus;	
					
				if ((osStatus = InitOpenTransportInContext(kInitOTForApplicationMask,nil)) != kOTNoError)
				{
					gUseOT = false;
					OTTCPError(NULL,errOTInitFailed,osStatus);
				}
				else	//Open Transport is here.  
				{	
					//See if RemoteAcess/OT/PPP is present while we're here.
					long result;
					OSErr err = Gestalt(gestaltOpenTptRemoteAccess, &amp;result);
					
					if ((err == noErr) 
					 &amp;&amp; (result &amp; (1 &lt;&lt; gestaltOpenTptRemoteAccessPresent)) 
					 &amp;&amp; (result &amp; (1 &lt;&lt; gestaltOpenTptPPPPresent)))
					{
						gHasOTPPP = true;
					}
					else 
					{
						gHasOTPPP = false;
					}

#ifdef USE_NETWORK_SETUP	
					// check for the network setup library as well ...
					UseNetworkSetup();
#endif	//UseNetworkSetup

					
					OTinitialized = true;		//remember that we started OT.
				}
			}
		}
	}
}

/*********************************************************************************
 * HasOTInetLib - (CFM Only) returns true if the OpenTptInetLib functions are present.
 *********************************************************************************/
Boolean HasOTInetLib(void)
{
	Boolean HasOTInetLib = true;
	
#if TARGET_RT_MAC_CFM
  HasOTInetLib = (long)(&amp;OTInetGetInterfaceInfo) != kUnresolvedCFragSymbolAddress
  	&amp;&amp; (long)(&amp;OTInetStringToAddress) != kUnresolvedCFragSymbolAddress
  	&amp;&amp; (long)(&amp;OTInetAddressToName) != kUnresolvedCFragSymbolAddress
  	&amp;&amp; (long)(&amp;OTInetMailExchange) != kUnresolvedCFragSymbolAddress; 	
#endif	//TARGET_RT_MAC_CFM

	return(HasOTInetLib);
}

/*********************************************************************************
 * OTSupported - (CFM Only) returns true if OT can be used on this 68K machine
 *********************************************************************************/
Boolean OTSupported(void)
{
	Boolean OTSupported = true;
 	long result;

#if TARGET_RT_MAC_CFM
 	//	OT can't be used if this is a 68K machine AND an OT version less than 1.2 is installed.
 	OTSupported = false;
	if (Gestalt(gestaltOpenTptVersions, &amp;result) == noErr)
	{
		if ((result &amp; 0xFFFF0000) &gt;= 0x01200000) OTSupported = true;
	}
#endif	//TARGET_RT_MAC_CFM

	return(OTSupported);
}

/*********************************************************************************
 * OTCloseOpenTransport - cleanup after Open Transport has been used
 *********************************************************************************/
void OTCleanUpAfterOpenTransport(void)
{
	if (OTinitialized)
	{			
		//shut down OT/PPP if appropriate ...
		if (gHasOTPPP)
			if (MyOTPPPInfo.weConnectedPPP == true) 
				OTPPPDisconnect(false, true);
			
		CloseOpenTransportInContext(nil);
	}
}

/*********************************************************************************
 * OTTCPConnectTrans - connect to the remote host.	This version uses OT TCP.
 *********************************************************************************/
OSErr OTTCPConnectTrans(TransStream stream, UPtr serverName, long port,Boolean silently,uLong timeout)
{
	InetHostInfo		hostInfo;
	Str255				scratch;
	InetMailExchange 	MXRecords[NUM_MX];
	short				numMX = NUM_MX;
	InetDomainName		hostName;
	Boolean				useMX = PrefIsSet(PREF_IGNORE_MX) &amp;&amp; (port == GetRLong(SMTP_PORT)) &amp;&amp; GetOSVersion()&lt;0x1030;
	InetHost			tryAddr;
	long				receiveBufferSize = 0;
	OSErr				err = noErr;
							
#ifdef DEBUG
	if (BUG12) port += 10000;
#endif

	ASSERT(stream);
	ASSERT(stream-&gt;OTTCPStream == 0);
	
	stream-&gt;streamErr = noErr;
	stream-&gt;Opening = true;
	stream-&gt;BeSilent = silently;
	
	//allocate memory for a new connection
	stream-&gt;OTTCPStream = New(MyOTTCPStream);
	if (stream-&gt;OTTCPStream != 0)
	{	
		WriteZero(stream-&gt;OTTCPStream,sizeof(MyOTTCPStream));
	
		ProgressMessageR(kpSubTitle,WHO_AM_I);
		//Make sure TCP is up and going.  Connect with OTPPP or something at this point.
		if ((err=OTVerifyOpen(stream)) == noErr)
		{			
			gActiveConnections++;	// a TCP connection has been established
				
			PCat(GetRString(scratch, DNR_LOOKUP), serverName);
			ProgressMessage(kpSubTitle, scratch);
			
			strncpy(hostName,serverName+1,(*serverName &gt; kMaxHostNameLen? kMaxHostNameLen : *serverName));
			hostName[*serverName] = 0;
			
			//MX allows us to pick the best address to send mail to.
			if (useMX)
			{
				if ((err = OTGetDomainMX(hostName, MXRecords, &amp;numMX)) != noErr) useMX = false;
				else GetPreferredMX(hostName, MXRecords, numMX);
			}
		
			if (err != userCancelled)
			{
				//Lookup the host by its name
				if ((err = OTGetHostByName(hostName, &amp;hostInfo)) == noErr)
				{
					tryAddr = OTRandomAddr(&amp;hostInfo);
					
					//OTGetHostByName succeeded.  Create the myStream structure, and allocate a buffer
					ProgressMessageR(kpSubTitle,HOUSEKEEPING);
					if ((err = CreateOTStream(stream)) == noErr)
					{
						// allocate a buffer for tcp, and create the stream
						receiveBufferSize = GetRLong(RCV_BUFFER_SIZE);
						if ((stream-&gt;RcvBuffer=NuHTempOK(receiveBufferSize))!=nil)
						{
							//Create stream succeeded.  Now try opening the connection.
							ComposeRString(scratch,CNXN_OPENING,serverName,tryAddr);
							ProgressMessageR(kpSubTitle,PREPARING_CONNECTION);
							ProgressMessage(kpMessage,scratch);
							
							// log the connection we're about to make
							ComposeLogS(LOG_PROTO,nil,"\pConnecting to %i:%d",tryAddr,port);
								
							if ((err = OTTCPOpen(stream, tryAddr, port, timeout)) == noErr)
							{
								//open succeeded.
								stream-&gt;RcvSpot = -1;
								ComposeLogS(LOG_PROTO,nil,"\pConnected to %i:%d",tryAddr,port);
							}
							else if (err != userCancelled) 
							{
								OTTCPError(stream,errOpenStream, stream-&gt;streamErr);
								ComposeLogS(LOG_PROTO,nil,"\pConnection to %i:%d failed.  Error %d",tryAddr,port,err);
							}
						}
						else WarnUser(MEM_ERR, stream-&gt;streamErr);	  // Memory error while creating buffer
					}
					else if (err != userCancelled) OTTCPError(stream,errCreateStream, stream-&gt;streamErr=err);
				}
				else
				{
					if (err != userCancelled) OTTCPError(stream,errDNR,stream-&gt;streamErr=err);
//					else OTTCPError(stream,errUserCancelledConnection,stream-&gt;streamErr=err);

					// Log the DNS Error
					ComposeLogS(LOG_PROTO,nil,"\pConnection failed.  DNS error %d", err);
				}
			}
		}
		else 
		{
			if (stream-&gt;streamErr == -7109) stream-&gt;streamErr = userCancelled;
			if (stream-&gt;streamErr != userCancelled) OTTCPError(stream,errPPPConnect, stream-&gt;streamErr);	
		}		
	}
	else WarnUser(OT_CON_MEM_ERR, stream-&gt;streamErr);	
		
	stream-&gt;Opening = false;	
	return ((OSErr)stream-&gt;streamErr);
}

#define	SWING_THE_THING	60
/*********************************************************************************
 * OTTCPSendTrans - send some text to the remote host.	This version uses OT TCP.
 *********************************************************************************/
OSErr OTTCPSendTrans(TransStream stream, UPtr text,long size, ...)
{
	OTResult 	result = noErr;
	va_list 	extra_buffers;
	UPtr		curBuf;
	long		curSize = 0;
	long		last = TickCount();
	long		now = 0;
	Boolean slow = False;
	
	ASSERT(stream);
	ASSERT(stream-&gt;OTTCPStream);
	
	stream-&gt;streamErr = noErr;
	
	if (CommandPeriod) return(userCancelled);
			
	if (size==0) return(noErr); 	// allow vacuous sends
	
	va_start(extra_buffers,size);

	//We'll send the text buffer first.
	curBuf = text;
	curSize = size;
	do
	{	
		//send the current buffer.
		while (curSize &gt; 0)
		{		
			now = TickCount();
			result = OTSnd(stream-&gt;OTTCPStream-&gt;ref, curBuf, curSize, 0);
			if (result &gt;= 0) 
			{
				//log what we sent
				if (LogLevel&amp;LOG_TRANS &amp;&amp; !stream-&gt;streamErr &amp;&amp; result) CarefulLog(LOG_TRANS,LOG_SENT,curBuf,result);
				CycleBalls();
				curSize -= result;
				curBuf += result;
				last = now;
				if (IsSendAudit(stream)) stream-&gt;bytesTransferred += result;
			} 
			else 		//no data was sent
			{
				if (result != kOTFlowErr) 		//something happened to the connection.  Stop the transfer
				{
					if (stream-&gt;OTTCPStream-&gt;otherSideClosed)
					{
						stream-&gt;streamErr = result = errLostConnection;
					}
					else stream-&gt;streamErr = errMiscSend;
						
					break;
				}
				else													//just some flow control issue or something.  Swing the thing, and check for a command-.
				{
					// check to see if we need ppp, but the connection is down
					if (needPPPConnection &amp;&amp; MyOTPPPInfo.state != kPPPUp) return(stream-&gt;streamErr = result = errLostConnection);
				}
			}
		
			if (slow || (now - last) &gt; SWING_THE_THING)
			{
				if (slow) YieldTicks = 0;
				MiniEvents();
				if (CommandPeriod) return(stream-&gt;streamErr = userCancelled);
				if ((now - last) &gt; SWING_THE_THING)
				{
					slow = True;
					CyclePendulum();
					last = now - SWING_THE_THING/2;
				}
			}
		}

		//point to the next buffer to send
		if (!stream-&gt;streamErr)
		{
			curBuf = va_arg(extra_buffers,UPtr);
			curSize = va_arg(extra_buffers,long);
		}
		
	} while (!stream-&gt;streamErr &amp;&amp; curBuf);
	
	va_end(extra_buffers);
	
	if (stream-&gt;streamErr)
	{
		if (stream-&gt;streamErr!=commandTimeout &amp;&amp; stream-&gt;streamErr!=userCancelled)
			OTTCPError(stream,stream-&gt;streamErr,result);
	}
		
	return (stream-&gt;streamErr);
}

/*********************************************************************************
 * OTTCPRecvTrans - get some text from the remote host.  This version uses OT TCP.
 *********************************************************************************/
OSErr OTTCPRecvTrans(TransStream stream, UPtr line,long *size)
{
	OTResult result = noErr;
	Str31 scratch;
	long timeout = InAThread() ? GetRLong(THREAD_RECV_TIMEOUT) : GetRLong(RECV_TIMEOUT);
	
	ASSERT(stream);
	ASSERT(stream-&gt;OTTCPStream);
	
	stream-&gt;streamErr = noErr;
	
	// Spin until something comes in.
	do
	{
		// read characters from the network, or die trying.
		stream-&gt;streamErr = OTWaitForChars(stream, timeout, line, size, &amp;result);
		if (stream-&gt;streamErr == noErr)
		{				
			if (result &gt;= 0)								// got something
				*size = result;
			else if (stream-&gt;OTTCPStream-&gt;otherSideClosed)	// lost connection
				stream-&gt;streamErr = errLostConnection;
			else if (result == kOTNoDataErr)				// got nothing
				*size = 0; 
			else 											// got some other error
				stream-&gt;streamErr = errMiscRec;
		}
	}
	while (stream-&gt;streamErr == commandTimeout &amp;&amp;
				 AlertStr(TIMEOUT_ALRT,Caution,GetRString(scratch,InAThread() ? THREAD_RECV_TIMEOUT : RECV_TIMEOUT))==1);
	
	if (stream-&gt;streamErr)
	{
		if (stream-&gt;streamErr!=commandTimeout &amp;&amp; stream-&gt;streamErr!=userCancelled)
			OTTCPError(stream,stream-&gt;streamErr,(result &lt; 0 ? result : kOTNoDataErr));
			// Note: result could be 0 if OTWaitForChars fails.  We want a real error message displayed in that case, too.
	}
	else 
	{
		if (*size) ResetAlertStage();
		if (*size &amp;&amp; LogLevel&amp;LOG_TRANS) CarefulLog(LOG_TRANS,LOG_GOT,line,*size);	//log what we got ...
		if (*size &amp;&amp; IsRecAudit(stream)) stream-&gt;bytesTransferred += *size;
	}
			
	return (stream-&gt;streamErr);
}

/*********************************************************************************
 * TCPDisTrans - disconnect from the remote host.  This version uses OT TCP.
 *********************************************************************************/
OSErr OTTCPDisTrans(TransStream stream)
{
	if (stream &amp;&amp; stream-&gt;OTTCPStream)
	{	
		stream-&gt;streamErr = noErr;
		
		//We're going to do an orderly disconnect on this stream.
		stream-&gt;OTTCPStream-&gt;weAreClosing = true;
			
		if ((stream-&gt;OTTCPStream-&gt;ref) &amp;&amp; (!stream-&gt;OTTCPStream-&gt;ourSideClosed))
		{
			//close our end if the other side has aborted.
			if (stream-&gt;OTTCPStream-&gt;otherSideClosed) 
			{
				OTSndDisconnect(stream-&gt;OTTCPStream-&gt;ref, nil);
				stream-&gt;OTTCPStream-&gt;ourSideClosed = true;
				stream-&gt;OTTCPStream-&gt;releaseMe = true;				//we can destroy this connection completely.
			}
			else
			{
				if (OTSndOrderlyDisconnect(stream-&gt;OTTCPStream-&gt;ref)!=noErr) stream-&gt;OTTCPStream-&gt;releaseMe = true;
				stream-&gt;OTTCPStream-&gt;ourSideClosed = true;
				stream-&gt;OTTCPStream-&gt;age = TickCount();
			}
		}
		
		return (stream-&gt;streamErr);
	}
	else return (noErr);
}

/*********************************************************************************
 * OTTCPDestroyTrans - destroy the connection.  This version uses OT TCP
 *********************************************************************************/
OSErr OTTCPDestroyTrans(TransStream stream)
{
	OSStatus status = noErr;
		
	if ((stream == 0) || (stream-&gt;OTTCPStream == 0)) return (noErr);
	
	//We are destroying the stream without disconnecting it.  An error occured, or the the user cancelled.
	//Do an abortive disconnect.
	if (!stream-&gt;OTTCPStream-&gt;weAreClosing)
	{	
		DestroyMyTStream(stream-&gt;OTTCPStream);
		ZapPtr(stream-&gt;OTTCPStream);
	}
	else	//otherwise, queue up the stream for an orderly disconnect.
	{
		if (stream-&gt;OTTCPStream)
		{	
 			//if both sides are closed, throw out this connection immediately
 			if (stream-&gt;OTTCPStream-&gt;ourSideClosed &amp;&amp; stream-&gt;OTTCPStream-&gt;otherSideClosed) stream-&gt;OTTCPStream-&gt;releaseMe = true;
 			
 			if (!stream-&gt;OTTCPStream-&gt;releaseMe) 			
			{
				//Queue it up in our queue of MyTStreams waiting to hear an orderly disconnect
				EnqueueMyTStream(stream-&gt;OTTCPStream);
				stream-&gt;OTTCPStream = 0;
			}
			else
			{
				//an error occurred disconnecting our stream.  Just kill it.
				DestroyMyTStream(stream-&gt;OTTCPStream);
				ZapPtr(stream-&gt;OTTCPStream);
			}
		}
	}
	
	//dispose our receive buffer.
	if (stream-&gt;RcvBuffer) ZapHandle(stream-&gt;RcvBuffer);
	
	return (stream-&gt;streamErr);
}
		
		
/*********************************************************************************
 * OTTCPTransError - report our most recent error
 *********************************************************************************/
OSErr OTTCPTransError(TransStream stream)
{
	ASSERT(stream);
	ASSERT(stream-&gt;OTTCPStream);
	
	return (stream-&gt;streamErr);
}

/*********************************************************************************
 * OTTCPSilenceTrans - turn off error reports from ot tcp routines
 *********************************************************************************/
void  OTTCPSilenceTrans(TransStream stream, Boolean silence)
{
	ASSERT(stream);
	
	stream-&gt;BeSilent = silence;
}

/********************************************************************************
 * OTTCPWhoAmI - return the mac's tcp name.  This version uses OT TCP.
 ********************************************************************************/
UPtr  OTTCPWhoAmI(TransStream stream, Uptr who)
{
#pragma unused(stream)

	InetInterfaceInfo localInfo;
	MyOTInetSvcInfo	myOTInfo;
	short	len;
	OSErr whoAmIErr = noErr;
	
	if (!*MyHostname)
	{
		whoAmIErr = OTInetGetInterfaceInfo(&amp;localInfo, kDefaultInetInterface);
		if (whoAmIErr == kOTNotFoundErr)	//OT hasn't been loaded yet ...
		{
			if (whoAmIErr = OpenOTInternetServices(&amp;myOTInfo)) 
				return (who);
			whoAmIErr = OTInetGetInterfaceInfo(&amp;localInfo, kDefaultInetInterface);
			OTCloseProvider(myOTInfo.ref);
			myOTInfo.ref = 0;
		}
		if (whoAmIErr != noErr) 
			return (who);
		ComposeRString(who,TCP_ME,localInfo.fAddress);
		SetPref(PREF_LASTHOST,who);
		PCopy(MyHostname,who);
	}
	PCopy(who,MyHostname);
	
	//remove the '.' from the end of who, if there is one.
	len = strlen(who);
	if (who[len-1]=='.') who[len-1]=0;	
	
	return(who);
}

/********************************************************************************
 * DNSHostid - return the mac's dns server hostid.  This version uses OT TCP.
 ********************************************************************************/
OSErr  DNSHostid(uLong *dnsAddr)
{
	InetInterfaceInfo localInfo;
	MyOTInetSvcInfo	myOTInfo;
	OSErr dnsHostidErr = noErr;

	dnsHostidErr = OTInetGetInterfaceInfo(&amp;localInfo, kDefaultInetInterface);
	if (dnsHostidErr == kOTNotFoundErr)	//OT hasn't been loaded yet ...
	{
		if (!(dnsHostidErr = OpenOTInternetServices(&amp;myOTInfo)))
		{ 
			dnsHostidErr = OTInetGetInterfaceInfo(&amp;localInfo, kDefaultInetInterface);
			OTCloseProvider(myOTInfo.ref);
			myOTInfo.ref = 0;
		}
	}

	if (!dnsHostidErr) *dnsAddr = *(long*)&amp;localInfo.fDNSAddr;

	return(dnsHostidErr);
}

/********************************************************************************
 * OTMyHostid - return the mac's hostid.  This version uses OT TCP.
 ********************************************************************************/
OSErr  OTMyHostid(uLong *myAddr,uLong *myMask)
{
	InetInterfaceInfo localInfo;
	MyOTInetSvcInfo	myOTInfo;
	OSErr myHostidErr=noErr;
	
	myHostidErr = OTInetGetInterfaceInfo(&amp;localInfo, kDefaultInetInterface);
	if (myHostidErr == kOTNotFoundErr)	//OT hasn't been loaded yet ...
	{
		if (!(myHostidErr = OpenOTInternetServices(&amp;myOTInfo)))
		{ 
			myHostidErr = OTInetGetInterfaceInfo(&amp;localInfo, kDefaultInetInterface);
			OTCloseProvider(myOTInfo.ref);
			myOTInfo.ref = 0;
		}
	}

	if (!myHostidErr)
	{
		*myAddr = *(long*)&amp;localInfo.fAddress;
		*myMask = *(long*)&amp;localInfo.fNetmask;
	}
	
	return(myHostidErr);
}

/********************************************************************************
 * OTMyHostid - return the mac's hostid.  This version uses OT TCP.
 ********************************************************************************/
OSErr GetMyHostid(uLong *addr,uLong *mask)
{
		return(OTMyHostid(addr,mask));
}

/************************************************************************
 * OTGetHostByName - get host information, given a hostname
 * this routine maintains a small, unflushable cache.
 ************************************************************************/
OSErr OTGetHostByName(InetDomainName hostName, InetHostInfo *hostInfoPtr)
{
	MyOTInetSvcInfo	myOTInfo;
	OSErr nameErr = noErr;
				
	if (nameErr = OpenOTInternetServices(&amp;myOTInfo)) 
		return (nameErr);
	myOTInfo.status = inProgress;
	nameErr = OTInetStringToAddress(myOTInfo.ref,hostName,hostInfoPtr);
	if (nameErr == noErr) nameErr = SpinOnWithConnectionCheck(&amp;(myOTInfo.status),0,True,False);
	if (nameErr == noErr) nameErr = myOTInfo.result; 
	OTCloseProvider(myOTInfo.ref);
	myOTInfo.ref = 0;	
	//return without changing the name of the server we wish to look up.
	if (nameErr == noErr) strcpy(hostInfoPtr-&gt;name,hostName);	
	
	// log the result of the name lookup. Be careful not to overrun buffers.
	if (LogLevel&amp;LOG_PROTO)
	{
		short count;
		Str63 logHostName;
		
		MakePStr(logHostName,hostName,strlen(hostName));
		ComposeLogS(LOG_PROTO,nil,"\pDNS Lookup of \"%p\"",logHostName);
		if (nameErr == noErr)
		{
			for (count=0;count&lt;kMaxHostAddrs;count++)
				if (hostInfoPtr-&gt;addrs[count])
					ComposeLogS(LOG_PROTO,nil,"\p    %i (%d)",hostInfoPtr-&gt;addrs[count],count+1);
		}
		else ComposeLogS(LOG_PROTO,nil,"\pLookup failed (error %d)",nameErr);
	}
			
	return (nameErr);
}

/*********************************************************************************
 * OTGetHostByAddr - get host information, given an address.  This version uses OT
 * this routine maintains a small, unflushable cache.
 *********************************************************************************/
OSErr OTGetHostByAddr(InetHost addr, InetHostInfo *domainNamePtr)
{
	MyOTInetSvcInfo	myOTInfo;
	short len = 0;
	OSErr addrErr = noErr;
				
	domainNamePtr-&gt;addrs[0] = addr;	
	if (addrErr = OpenOTInternetServices(&amp;myOTInfo)) 
		return (addrErr);
	myOTInfo.status = inProgress;
	addrErr = OTInetAddressToName(myOTInfo.ref,domainNamePtr-&gt;addrs[0],domainNamePtr-&gt;name);
	if (addrErr == noErr) addrErr = SpinOnWithConnectionCheck(&amp;(myOTInfo.status),0,True,False);
	if (addrErr == noErr) addrErr = myOTInfo.result; 
	OTCloseProvider(myOTInfo.ref);
	myOTInfo.ref = 0;
	
	//remove the '.' from the end of name, if there is one.
	if (addrErr == noErr)
	{	
		len = strlen(domainNamePtr-&gt;name);
		if (domainNamePtr-&gt;name[len-1]=='.') domainNamePtr-&gt;name[len-1]=0;	
	}		
	
	return (addrErr);
}

/**********************************************************************
 * OTRandomAddr - pick a random address out of a set of addresses we
 * got from our OT DNR lookip.
 **********************************************************************/
InetHost OTRandomAddr(InetHostInfo *host)
{
	short count;
	
	if (!PrefIsSet(PREF_DNS_BALANCE)) 
		return (host-&gt;addrs[0]);
	
	for (count=kMaxHostAddrs;count;count--) if (host-&gt;addrs[count-1]) break;
	return (host-&gt;addrs[count&lt;2?0:TickCount()%count]);
}

/************************************************************************
 * OTGetDomainMX - Get the mail exchange info for a particular host.
 ************************************************************************/
OSErr OTGetDomainMX(InetDomainName hostName, InetMailExchange *MXPtr, short *numMX)
{
	OSErr err = noErr;
	MyOTInetSvcInfo	myOTInfo;
	short i;
	
	if (MXPtr == 0 		// must have a place to store the MX records
	 || numMX == 0 		// must have an idea of how many records will fit there
	 || *numMX &lt;= 0) 	// and must have allocated room for at least one
		return (paramErr);
	
	//clear out the MXPtr
	for (i = 0; i &lt; *numMX; i++) 
		(MXPtr[i]).exchange[0] = (MXPtr[i]).preference = 0;
	
	//do the MX lookup
	if ((err = OpenOTInternetServices(&amp;myOTInfo)) == noErr)
	{
		myOTInfo.status = inProgress;
		err = OTInetMailExchange(myOTInfo.ref, hostName, numMX, MXPtr);
		if (err == noErr) err = SpinOnWithConnectionCheck(&amp;(myOTInfo.status),0,True,False);
		OTCloseProvider(myOTInfo.ref);
		myOTInfo.ref = 0;
		
		if (err == noErr)
			if (MXPtr-&gt;exchange[0] == 0) return (errNoMXRecords);			
	}
	
	return (err);
}

/**********************************************************************
 * GetPreferredMX - return the preferred host to send mail to.
 **********************************************************************/
void GetPreferredMX(InetDomainName preferredName, InetMailExchange *MXPtr, short numMX)
{
	short lowestPref, preferredHost;
	short count = numMX - 1;
	short len;
	
	preferredHost = count;
	lowestPref = MXPtr[count].preference;
	for (count; count &gt;= 0; count--)
	{
		if (MXPtr[count].preference &lt; lowestPref) 
		{
			lowestPref = MXPtr[count].preference;
			preferredHost = count;
		}
	}
	strcpy(preferredName, MXPtr[preferredHost].exchange);
	
	//remove the '.' from the end of preferredName, if there is one.
	len = strlen(preferredName);
	if (preferredName[len-1]=='.') preferredName[len-1]=0;	
}

#pragma segment Main
/*********************************************************************************
 * MyOTNotifyProc - This callback handles the results of all asynch OT calls.
 *********************************************************************************/
pascal void MyOTNotifyProc(MyOTInetSvcInfo *info, OTEventCode theEvent, OTResult theResult, void *theParam)
{
	switch (theEvent)
	{
		case T_OPENCOMPLETE:							// The OTAsyncOpenInternetServices function has completed
		case T_DNRSTRINGTOADDRCOMPLETE:		// The OTInetStringToAddress function has finished	
		case T_DNRADDRTONAMECOMPLETE:			// The OTInetAddressToName function has finished
		case T_DNRMAILEXCHANGECOMPLETE:		// The OTInetMailExchange function has finished
			info-&gt;status = 0;
			info-&gt;result = theResult;
			info-&gt;cookie = theParam;
			break;
				
		default:													// All other network events can be ignored
			break;
	}
}
#pragma segment TcpTrans

/*********************************************************************************
 * OpenOTInternetServices - Open up the internet service provider OT gives us.
 *********************************************************************************/
OSErr OpenOTInternetServices(MyOTInetSvcInfo *myOTInfo)
{
	OSErr err = noErr;
	DECLARE_UPP(MyOTNotifyProc,OTNotify);
	
	INIT_UPP(MyOTNotifyProc,OTNotify);
	myOTInfo-&gt;status = inProgress;
	if ((err = OTAsyncOpenInternetServicesInContext(kDefaultInternetServicesPath, 0, MyOTNotifyProcUPP, myOTInfo,NULL)) == noErr) 
		if ((err = SpinOnWithConnectionCheck(&amp;(myOTInfo-&gt;status),0,True,False)) == noErr) 
		{
			myOTInfo-&gt;ref = myOTInfo-&gt;cookie;
		}
	
	if (err != noErr &amp;&amp; err != userCancelled) err = errOTInetSvcs;
			
	return (err);
}

#pragma segment Main
/*********************************************************************************
 *	MyOTStreamNotifyProc - my OT notifier proc for TCP streams.
 *********************************************************************************/
pascal void MyOTStreamNotifyProc (MyOTTCPStream *myStream, OTEventCode code, OTResult theResult, void *cookie)
{
	OSStatus err;
	
	switch (code) 
	{
		case T_DISCONNECT:								// Other side has aborted
			myStream-&gt;otherSideClosed = true;
			myStream-&gt;status = 0;
			break;
			
		case T_ORDREL:									// Other side has closed in an orderly fashion
			myStream-&gt;otherSideClosed = true;
			myStream-&gt;status = 0;
			err = OTRcvOrderlyDisconnect(myStream-&gt;ref);
			if (!myStream-&gt;ourSideClosed)
			{
				err = OTSndOrderlyDisconnect(myStream-&gt;ref);
				myStream-&gt;ourSideClosed = true;
			}
			myStream-&gt;releaseMe = true;					// we don't need this stream anymore.
			break;
			
		case T_OPENCOMPLETE:							// OTOpenAsyncEndpoint has finished
		case T_BINDCOMPLETE:							// OTBind has finished
		case T_UNBINDCOMPLETE:							// OTUnbind has finished
		case T_CONNECT:									// OTConnect has finished
		case T_PASSCON:									// state is now T_DATAXFER
			myStream-&gt;status = 0;
			myStream-&gt;code = code;
			myStream-&gt;result = theResult;
			myStream-&gt;cookie = cookie;
			break;
	}
}
#pragma segment TcpTrans

/*********************************************************************************
 *	CreateOTStream - create a MyOTTCPStreamPtr
 *********************************************************************************/
OSErr CreateOTStream(TransStream stream)
{
	OSStatus	OTErr = noErr;
	DECLARE_UPP(MyOTStreamNotifyProc,OTNotify);
	
	INIT_UPP(MyOTStreamNotifyProc,OTNotify);
	ASSERT(stream);
	
	stream-&gt;streamErr = noErr;
	
	//Open a TCP endpoint asynchronously
	stream-&gt;OTTCPStream-&gt;status = inProgress;
	stream-&gt;streamErr = OTAsyncOpenEndpointInContext(OTCreateConfiguration(kTCPName),0,0,MyOTStreamNotifyProcUPP,stream-&gt;OTTCPStream,nil);
	if (stream-&gt;streamErr == noErr) stream-&gt;streamErr = SpinOnWithConnectionCheck(&amp;(stream-&gt;OTTCPStream-&gt;status),0,True,False);
	if ((stream-&gt;streamErr == noErr) || ((stream-&gt;streamErr = stream-&gt;OTTCPStream-&gt;result) == noErr)) 
	{
		if (stream-&gt;OTTCPStream-&gt;code != T_OPENCOMPLETE) 
			return (stream-&gt;streamErr = errOpenStream);
		stream-&gt;OTTCPStream-&gt;ref = stream-&gt;OTTCPStream-&gt;cookie;
		if (stream-&gt;OTTCPStream-&gt;ref == kOTInvalidEndpointRef)
			return (stream-&gt;streamErr = errOpenStream);

		//Initialize the MyOTTCPStreamPtr flags
		stream-&gt;OTTCPStream-&gt;weAreClosing = false;
		stream-&gt;OTTCPStream-&gt;otherSideClosed = false;
		stream-&gt;OTTCPStream-&gt;ourSideClosed = false;
		stream-&gt;OTTCPStream-&gt;releaseMe = false;
	}

	if (stream-&gt;streamErr != noErr)
	{
		if (stream-&gt;OTTCPStream-&gt;ref) OTCloseProvider(stream-&gt;OTTCPStream-&gt;ref);
		stream-&gt;OTTCPStream-&gt;ref = 0;
	}
	return (stream-&gt;streamErr);
} 

/*********************************************************************************
 *	OTTCPOpen - actually open a connection
 *	
 *	3/18/99 no longer using OT memory allocation routines.
 *********************************************************************************/
OSErr OTTCPOpen(TransStream stream, InetHost tryAddr, InetPort port,uLong timeout)
{
	InetAddress connectAddr;
	TCall sndCall;
	
	ASSERT(stream);
	ASSERT(stream-&gt;OTTCPStream);
	
	stream-&gt;streamErr = noErr;
	stream-&gt;OTTCPStream-&gt;status = inProgress;
	if (stream-&gt;streamErr = OTBind(stream-&gt;OTTCPStream-&gt;ref, 0, 0)) 	// OTBind doesn't need any parameters.  This is an outgoing connection.  jdboyd 04/11/02
		return (stream-&gt;streamErr);
	if (stream-&gt;streamErr = SpinOnWithConnectionCheck(&amp;(stream-&gt;OTTCPStream-&gt;status),60*timeout,True,False)) 
		return (stream-&gt;streamErr);
	if (stream-&gt;OTTCPStream-&gt;code != T_BINDCOMPLETE) 
	{
		stream-&gt;streamErr = stream-&gt;OTTCPStream-&gt;result;
		return (errOpenStream);
	}
	
	// set up the TCall structure needed to connect to tryAddr		
	OTInitInetAddress(&amp;connectAddr, port, tryAddr);
	WriteZero(&amp;sndCall, sizeof(TCall));
	sndCall.addr.len = sizeof(InetAddress);				
	sndCall.addr.buf = (unsigned char*) &amp;connectAddr;
	
	// now connect to the address asynchronously
	stream-&gt;OTTCPStream-&gt;status = inProgress;	
	stream-&gt;streamErr = OTConnect(stream-&gt;OTTCPStream-&gt;ref, &amp;sndCall, 0);
	if (stream-&gt;streamErr != noErr &amp;&amp; stream-&gt;streamErr != kOTNoDataErr) 
		return (stream-&gt;OTTCPStream-&gt;otherSideClosed ? errLostConnection : stream-&gt;streamErr);
	if (stream-&gt;streamErr = SpinOnWithConnectionCheck(&amp;(stream-&gt;OTTCPStream-&gt;status),60*timeout,True,False))
		return (stream-&gt;OTTCPStream-&gt;otherSideClosed ? errLostConnection : stream-&gt;streamErr);
	
	// did we connect?
	if (stream-&gt;OTTCPStream-&gt;code != T_CONNECT) 		
	{
		stream-&gt;streamErr = errLostConnection;
		return (errOpenStream);
	}
	if (stream-&gt;streamErr = OTRcvConnect(stream-&gt;OTTCPStream-&gt;ref, 0)) 
		return (stream-&gt;streamErr);
	
	return (stream-&gt;streamErr);
}

/*********************************************************************************
 * OTWaitForChars - spin, giving everybody else time, until chars available
 *********************************************************************************/
short OTWaitForChars(TransStream stream, long timeout, UPtr line, long *size, OTResult *otResult)
{
	EventRecord event;
	long ticks=TickCount();
	static long waitTicks=0;
	long tookTicks;
	Boolean result = false;
	long timeoutTicks = ticks + 60*timeout;
	Boolean slow = False;
	OTFlags junkFlags = 0;
	
	ASSERT(stream);
	ASSERT(stream-&gt;OTTCPStream);
	
	if (!InBG) waitTicks = 0;
	
	// spin until we see data on the network ...
	do
	{
		// check to see if our connection is still up.  Only care if remote end has closed.
		if (stream-&gt;OTTCPStream-&gt;otherSideClosed) return(errLostConnection);			

		// check to see if we need ppp, but the connection is down
		if (needPPPConnection &amp;&amp; MyOTPPPInfo.state != kPPPUp) return(errLostConnection);
		
		//check to see if cmd-. has been pressed.
		if (CommandPeriod) return (userCancelled);
									
		if (TickCount()-ticks  &gt; 10)
		{
			slow = True;
			CyclePendulum();
			ticks=TickCount();
			if (ticks &gt;timeoutTicks) return(commandTimeout);
		}

		// receive size bytes and put it in line.  We expect some data, so wait around until we see it.
		*otResult = OTRcv(stream-&gt;OTTCPStream-&gt;ref, line, *size, &amp;junkFlags);
		
		// we'll spin until we see data or an error.
		if (*otResult == kOTNoDataErr) *otResult = 0;
		
		if (slow) YieldTicks = 0;
		
		//	To speed up threaded xfers when app is in bg, don't call WaitNextEvent as often
		// also speeded up typing by changing NEED_YIELD -- it checks Typing when in a thread. (though I'm not quite sure how thread gets time when Typing is true)
		if (NEED_YIELD || ((*otResult == 0) &amp;&amp; !stream-&gt;DontWait))
		{	
			tookTicks = TickCount();

// 11-13-97 change to fix cmd period bug when in main thread
			result = WNE(MINI_MASK|keyDownMask,&amp;event,waitTicks);
			if (CommandPeriod) return(userCancelled);
//was:
//		result = WNE(MINI_MASK,&amp;event,waitTicks);
			
			tookTicks = TickCount()-tookTicks;
			if (InBG)
				if (tookTicks &gt; waitTicks+1)
					waitTicks = MIN(120,tookTicks);
				else
					waitTicks = waitTicks&gt;&gt;1;
			else
				waitTicks = 1;
			if (result) (void) MiniMainLoop(&amp;event);
		}
	}
	while ((*otResult == 0) &amp;&amp; !stream-&gt;DontWait);
	stream-&gt;CharsAvail = 0;
	return(0);
}


/*********************************************************************************
 *	OTFlushInput - dump all chars that arrive on a stream, until there are no
 *   chars for a given period of time
 *********************************************************************************/
void OTFlushInput(TransStream stream,uLong timeout)
{
	Str255 junk;
	OTResult result;
	long got;

	do
	{
		got = sizeof(junk);
		if (OTWaitForChars(stream, timeout, junk, &amp;got, &amp;result)) break;
		if (LogLevel&amp;LOG_TRANS &amp;&amp; !stream-&gt;streamErr &amp;&amp; result&gt;0) CarefulLog(LOG_TRANS,LOG_FLUSHED,junk,result);
	}
	while (result&gt;0);
}

static short errorMessages[errMyLastOTErr-errOTInitFailed] = 
	{ 
		OT_INIT_ERR,	//errOTInitFailed,
		OT_INIT_ERR,	//errOTInetSvcs, 
		BIND_ERR,	//errDNR,
		0,	//errNoMXRecords,
		TCP_TROUBLE,	//errCreateStream,
		NO_SMTP_SERVER,	//errOpenStream,
		TCP_TROUBLE,	//errLostConnection,
		TCP_TROUBLE,	//errMiscRec,
		TCP_TROUBLE,	//errMiscSend
		OT_DIALUP_CONNECT_ERR,//errPPPConnect
		0,	//errPPPPrefNotFound
		0,	//errPPPStateUnknown
		OT_MISSING_LIBRARY	//errOTMissingLib:
	};



static void OTTELo ( OSErr generalError, OSErr specificError, StringPtr message ) {
	if (IsMyOTError(generalError))
		GetRString(message, errorMessages[generalError - errOTInitFailed]);
	else
		GetRString(message, TCP_TROUBLE);
	}

/*********************************************************************************
 *	OTTE - give the user some helpful information if an error occurs.
 *		generalError contains a general description of the error, set by me.
 *		specificError contains the actual error returned by the failed call
 *********************************************************************************/
OSErr OTTE(TransStream stream, OSErr generalError, OSErr specificError, short file, short line)
{
	short	errorString = 0;
	OSErr	MacTCPErr = noErr;
	
	if ((generalError != noErr)
		&amp;&amp; (stream==0 || !stream-&gt;BeSilent) 
		&amp;&amp; !AmQuitting
		&amp;&amp; (!CommandPeriod || stream==0 || stream-&gt;Opening &amp;&amp; !PrefIsSet(PREF_OFFLINE) &amp;&amp; !PrefIsSet(PREF_NO_OFF_OFFER)))
	{
		Str255 message;
		Str255 tcpMessage;
		Str63 debugStr;
		Str31 rawNumber;
		short realSettingsRef = SettingsRefN;

		tcpMessage[0] = 0;
		
		NumToString(specificError,rawNumber);
		
		SettingsRefN = GetMainGlobalSettingsRefN();		
		OTErrorToString(specificError, tcpMessage);
		OTTELo ( generalError, specificError, message );
		ComposeRString(debugStr,FILE_LINE_FMT,file,line);
		SettingsRefN = realSettingsRef;

		
		MyParamText(message,rawNumber,tcpMessage,debugStr);
		if (stream==0 || stream-&gt;Opening)
		{
			if (2==ReallyDoAnAlert(OPEN_ERR_ALRT,Caution))
				SetPref(PREF_OFFLINE,YesStr);
		}
		else ReallyDoAnAlert(BIG_OK_ALRT,Caution);

	}
		
	return (generalError);
}

/*********************************************************************************
 *	OTErrorToString - pick an error string that best describes the
 *	specific error.
 *********************************************************************************/
void OTErrorToString(short specificError, Str255 tcpMessage)
{	
	short errorString = 0;
	tcpMessage[0] = 0;

	//Was this some error that I defined?
	if (IsMyOTError(specificError))
	{
		switch (specificError)
		{
			case errOTInetSvcs:
				errorString = OT_INET_SVCS_ERR;
				break;
			
			case errLostConnection:
				specificError = TCPRemoteAbort;
				break;
			
			case errPPPStateUnknown:
				errorString = OT_PPP_STATE_ERR;
				break;
					
			case errPPPPrefNotFound:
				errorString = OT_TCPIP_PREF_ERR;
				break;
			
			case errOTMissingLib:
				errorString = OT_MISSING_LIBRARY;
				break;
				
			default:
				errorString = OT_UNKNOWN_ERR;
				break;
		}
	}
	
	if (errorString!=0) GetRString(tcpMessage,errorString);
	else
	{	
		if (IsXTIError(specificError))
			GetRString(tcpMessage,OTTCP_ERR_STRN + XTI2OSStatus(specificError));
		else if (IsOTPPPError(specificError))							// was this an OT/PPP related error?
			GetRString(tcpMessage,OTPPP_ERR_STRN - specificError + kCCLErrorBaseCode - 1);
		else if (-23000&gt;=specificError &amp;&amp; specificError &gt;=-23048)		// was this a MacTCP error code?
			GetRString(tcpMessage,MACTCP_ERR_STRN-22999-specificError);	
		else if (2&lt;=specificError &amp;&amp; specificError&lt;=9)
			GetRString(tcpMessage,MACTCP_ERR_STRN+specificError+(23048-23000));
		else
			tcpMessage = 0;
	}
}


/*********************************************************************************
 * DestroyMyTStream - deallocate everything a MyStream grabs for itself.
 *********************************************************************************/
void DestroyMyTStream(MyOTTCPStreamPtr myStream)
{
	OSErr destroyErr = noErr;
	
	if (myStream)
	{		
		//clean up after the myStream
		if (myStream-&gt;ref != 0)
		{
			//make sure the connection is closed.
			if (!myStream-&gt;otherSideClosed || !myStream-&gt;ourSideClosed) OTSndDisconnect(myStream-&gt;ref, nil);
			
			//unbind the endpoint
			myStream-&gt;status = inProgress;
			destroyErr = OTUnbind(myStream-&gt;ref);
			if (destroyErr == noErr) destroyErr = SpinOnWithConnectionCheck(&amp;(myStream-&gt;status),0,True,False);
	
			// remove the endpoint's notifier.  We won't be needing it anymore.
			OTRemoveNotifier(myStream-&gt;ref);
			
			// now we can kill the endpoint.
			destroyErr = OTCloseProvider(myStream-&gt;ref);	
			myStream-&gt;ref = 0;
		}
		
		if (gActiveConnections) gActiveConnections--;
	}
}

/*********************************************************************************
 * EnqueueMyTStream - put myStream in the queue of streams waiting to close.
 *********************************************************************************/
void EnqueueMyTStream(MyOTTCPStreamPtr myStream)
{
	MyOTTCPStreamPtr queueScan = 0;
	OSStatus status = noErr;
	
	ASSERT(myStream);
	
	if (pendingCloses == 0)		//this is the only stream in the queue
	{
		pendingCloses = myStream;
		myStream-&gt;next = 0;
		myStream-&gt;prev = 0;
	}	
	else						//there are some other streams waiting to close
	{
		queueScan = pendingCloses;
		while (queueScan-&gt;next != 0) queueScan = queueScan-&gt;next;
		queueScan-&gt;next = myStream;
		myStream-&gt;prev = queueScan;
		myStream-&gt;next = 0;
	}
}

/*********************************************************************************
 * KillDeadMyTStreams - deallocate memory and TStreams that have received an
 * orderly disconnect.  destroy determines whether to kill all the streams, or
 * only the ones that have been disconnected in an orderly fashion.
 *********************************************************************************/
 void KillDeadMyTStreams(Boolean destroy)
 {
 	MyOTTCPStreamPtr queueScan = pendingCloses;
 	MyOTTCPStreamPtr releaseThisOne = 0;
 	
 	//loop through and find stream that can be released.
 	while (queueScan != 0)
 	{
 		OSStatus queueScanStatus;
 		
 		if (queueScan-&gt;ref == 0) queueScan-&gt;releaseMe = true;	//this should never happen ...
 		else
 		{
	 		queueScanStatus = OTLook(queueScan-&gt;ref);
	 		
	 		//if this endpoint has some data waiting to be read, read it.
			if (queueScanStatus == T_DATA || queueScanStatus == T_EXDATA)	
			{
				do {
					queueScanStatus = OTRcv(queueScan-&gt;ref, queueScan-&gt;dummyBuffer, sizeof(queueScan-&gt;dummyBuffer), nil);
				} while (queueScanStatus &gt;= 0);
				
				queueScan-&gt;age = TickCount();	//this stream made a noise, earning it a new minute.
			}
				
			if ((TickCount() - queueScan-&gt;age) &gt; 3600) 
				queueScan-&gt;releaseMe = true;	//keep silent connections around for 1 minute.
		}
 		
 		//the MyOTStream callback will set releaseMe once this stream can die quietly
 		if (destroy || queueScan-&gt;releaseMe)
 		{	
 			releaseThisOne = queueScan;
 			queueScan = queueScan-&gt;next;
 			
 			if (releaseThisOne == pendingCloses) pendingCloses = releaseThisOne-&gt;next;
 			
 			if (releaseThisOne-&gt;prev) (releaseThisOne-&gt;prev)-&gt;next = releaseThisOne-&gt;next;
 			if (releaseThisOne-&gt;next) (releaseThisOne-&gt;next)-&gt;prev = releaseThisOne-&gt;prev;
 			DestroyMyTStream(releaseThisOne);
 			ZapPtr(releaseThisOne);
 		}
 		else
 			queueScan = queueScan-&gt;next;
 	}
}
 
 
/*********************************************************************************
 * OTVerifyOpen - Make sure OT TCP is ready to go.  May have to conenct with PPP
 * or SLIP, depending on what is selected in the TCP/IP control panel
 *********************************************************************************/
OSErr OTVerifyOpen(TransStream stream)
{
	Boolean weAttemptedPPP = false;
	
	stream-&gt;streamErr = noErr;

	//signal everyone else that, no, PPP is not needed for the connection	
	needPPPConnection = false;
	gPPPConnectFailed = false;
		
	if (!PrefIsSet(PREF_IGNORE_PPP))	//this pref lets us ignore MacSLIP/PPP if we want
	{	
		if ((stream-&gt;streamErr = SelectedConnectionMode(&amp;connectionSelection, true)) == noErr)
		{
			if (dialingThePhone)
			{
				//sit and wait for a connection.
				if (connectionSelection == kPPPSelected)
				{
					ProgressMessageR(kpSubTitle,OT_PPP_WAIT);
					do
					{
						MiniEvents();
						if (CommandPeriod) 	return (stream-&gt;streamErr = userCancelled);
					}
					while (dialingThePhone);
					if (PPPDown()) return(stream-&gt;streamErr = errPPPConnect);
				}
			}
			else if (connectionSelection == kPPPSelected)
			{
				dialingThePhone = true;
				needPPPConnection = true;	//let everyone know the connection is being made over PPP.
				gConnecting = true;			//likewise, tell the world we're dialing the phone.
				if (stream-&gt;streamErr = OTPPPConnect(&amp;weAttemptedPPP))
				{
					gPPPConnectFailed = true;	//flag to tell the world that our PPP connection attempt failed.
					
					// Holy crap, Batman! This has been broken all these years.  Only force clase the connection
					// if we were the fools to think we could connect it to begin with. -JDB 12/16/98
					OTPPPDisconnect(weAttemptedPPP, true);
				}
				gConnecting = false;
				dialingThePhone = false;
			}
		}
	}
	return (stream-&gt;streamErr);
}

/*********************************************************************************
 * OTPPPConnect - Cause an OTPPP connection to happen.  I will create one single
 * OTPPP control endpoint, and keep it around.  Apple says there's a bug with the
 * current OT/PPP that causes OTCloseProvider() to crash when closing a PPP control
 * endpoint.
 *
 *	6/18/97	This routine can be called from multiple threads.  The first call
 *		will initiate the PPP connection.  Subsequent calls will wait for the PPP
 *		connection.
 *
 *	12/16/98 Added attemotedConnection paramter to let caller know whether we make
 *		the connection attempt or not.  There might be one underway, in which case
 *		we wait for it.
 *
 *	May, 1999 Added a delay after (a) the connection is made, or (b) the connection
 *		we were waiting for finishes.  We delat for &lt;x-eudora-setting:13102&gt; seconds
 *		to allow ARA to actually connect.
 *********************************************************************************/ 
OSErr OTPPPConnect(Boolean *attemptedConnection)
{					
	OSErr err = noErr;
	OTResult result = kOTNoError;
	unsigned long PPPState = 0;
	Boolean PPPInForeGround = PrefIsSet(PREF_PPP_FOREGROUND);
	Str255 scratch;
	Boolean redial = false;
	long numRedials = 0;
	long delay = 0;
	long dialCount = 0;
	Boolean doDelay = false;	// do we need to delay for stupid ARA?
	
#ifdef	DEBUG
	ASSERT(attemptedConnection);	// must have this parameter
#endif
					
	pppErr = noErr;
	*attemptedConnection = false;
					
	//Make a new PPP endpoint.  We're only going to keep one around.
	if (MyOTPPPInfo.ref == 0) result = NewPPPControlEndpoint();
	
	if ((result == kOTNoError) &amp;&amp; (MyOTPPPInfo.ref != kOTInvalidEndpointRef))
	{	
		// Check the current state of the PPP connection.  
		err = GetPPPConnectionState(MyOTPPPInfo.ref, &amp;PPPState);
		if (err == noErr)
		{		
			// have we already connected PPP at some point in the past?
			if (MyOTPPPInfo.weConnectedPPP==true &amp;&amp; MyOTPPPInfo.state==kPPPUp &amp;&amp; PPPState==kPPPStateOpened) return noErr;
			
			//If we don't already have an open connection, open one.
			if ((PPPState != kPPPStateOpened &amp;&amp; PPPState != kPPPStateOpening) || MyOTPPPInfo.state == kPPPClosing)
			{
				// remember that we're the one starting this connection
				*attemptedConnection = true;
				
				// we'll have to delay for ARA
				doDelay = true;
				
				// Get the redial information
				if (!PPPInForeGround)
				{
					err = OTPPPDialingInformation(&amp;redial, &amp;numRedials, &amp;delay);
					if (err != noErr || numRedials &lt; 1) redial = false;	// couldn't get redial data.  Ignore it.							
				
					dialCount = redial ? numRedials + 1 : 1;
				}
				else dialCount = 1;		//redials are handled in the PPP connection dialog already.
				
				// Establish a new connection		
				TurnOnPPPConnectionDialog(MyOTPPPInfo.ref, PPPInForeGround);
				
				// force the current connection to close if it hasn't been to to already
				if (PPPState == kPPPStateOpened || PPPState == kPPPStateOpening)
				{					
					OTPPPDisconnect(true, false);
					if (pppErr = WaitForOTPPPDisconnect(true)) return (pppErr);
					MyOTPPPInfo.state = kPPPDown;
				}
		
				MyOTPPPInfo.result = noErr;
				ProgressMessageR(kpSubTitle,OT_PPP_CONNECT);				
				if (!PPPInForeGround) 				
				{
					GetRString(scratch, OT_PPP_CONNECT_MESSAGE);
					ProgressMessage(kpMessage,scratch);
				}

				// Actually connect OT/PPP
				MyOTPPPInfo.code = 0;	
				MyOTPPPInfo.state = kPPPOpening;
				result = kCCLErrorLineBusyErr;
				pppErr = OTIoctl(MyOTPPPInfo.ref, I_OTConnect, NULL);			
				
				// Bug 1648 - if we're connecting PPP with the connection dialog, we should sit and spin until it finishes dialig the phone.
				if (PPPInForeGround)
				{
					MyOTPPPInfo.status = inProgress;
					if (pppErr == noErr) pppErr = SpinOn(&amp;(MyOTPPPInfo.status),0,True,False);
				}
				
				// Spin until we can do TCP/IP over the connection
				while (dialCount &gt; 0 &amp;&amp; result == kCCLErrorLineBusyErr &amp;&amp; !PPPInForeGround &amp;&amp; pppErr == noErr)
				{
					while (true)
					{
						MyOTPPPInfo.event = 0;
						MyOTPPPInfo.result = noErr;
						MyOTPPPInfo.status = inProgress;
						if (pppErr == noErr) pppErr = SpinOn(&amp;(MyOTPPPInfo.status),0,True,False);
						
						result = MyOTPPPInfo.result;
						if (MyOTPPPInfo.state == kPPPUp || MyOTPPPInfo.state == kPPPDown || pppErr != noErr || MyOTPPPInfo.result &lt; 0) break;
							
						// Update the progress dialog.
						GetRString(scratch, MyOTPPPInfo.event);
						ProgressMessage(kpMessage,scratch);
					}
					dialCount--;
					if (redial &amp;&amp; result == kCCLErrorLineBusyErr) ProgressMessageR(kpSubTitle,OT_PPP_REDIALING);
				}
			}
			else
			{	
				//there's a connection current trying to open
				if (PPPState == kPPPStateOpening)
				{
					// do the ARA delay ...
					doDelay = true;
					
					//Spin until we can talk TCP over the connection
					ProgressMessageR(kpSubTitle,OT_PPP_CONNECT);				
					GetRString(scratch, OT_PPP_CONNECT_MESSAGE);
					ProgressMessage(kpMessage,scratch);
					
					MyOTPPPInfo.state = kPPPOpening;
					while (true)
					{
						MyOTPPPInfo.event = 0;
						MyOTPPPInfo.result = noErr;
						MyOTPPPInfo.status = inProgress;
						err = SpinOn(&amp;(MyOTPPPInfo.status),0,True,False);
					
						result = MyOTPPPInfo.result;
						if (MyOTPPPInfo.state == kPPPUp || MyOTPPPInfo.state == kPPPDown || err != noErr || MyOTPPPInfo.result &lt; 0) break;
							
						// Update the progress dialog.
						GetRString(scratch, MyOTPPPInfo.event);
						ProgressMessage(kpMessage,scratch);
					}
					
					if (err == noErr) err = MyOTPPPInfo.result;
				}
				
				if (err == noErr)
				{
					MyOTPPPInfo.state = kPPPUp;
					*attemptedConnection = false;	// PPP is up, but we didn't connect it.
					pppErr = noErr;
				}
				else return (pppErr = err);
			}
		}
		else	//could not determine the state of the PPP connection
		{
			return (pppErr = errPPPStateUnknown);		
		}
	}				
	else
		return (pppErr = result);
	
	// The connection is up because we connected it, or someone else did
	if (pppErr == noErr)
	{
		if (MyOTPPPInfo.state == kPPPUp) 
		{
			// must we delay for ARA?
			if (doDelay)
			{
				// 	PPP Race Condition Hack.  
				//
				//	Since ARA and PPP have been combined, it's now possible to get the kPPPConnectCompletedEvent
				//	*before* ARA does.  This will cause the first network operation to fail.  So, let's Pause
				//	for a while, and let ARA know about it's successful connection.
				long delay = GetRLong(OT_PPP_RACE_HACK);
				Str255 delayStr;
				
				if (delay &gt; 0) 
				{
					NumToString(delay, delayStr);
					ComposeRString(scratch,OT_PPP_SMART_ASS,delayStr);
					ProgressMessage(kpMessage,scratch);
					
					Pause(60*delay);
				}
			}			
			
			MyOTPPPInfo.weConnectedPPP = *attemptedConnection;	// remember if we started the connections ourselves or not.	
		}
		else
		{
			if (!PPPInForeGround) pppErr = MyOTPPPInfo.result ? MyOTPPPInfo.result : kCCLErrorGeneric;	//return some sort of error
			else pppErr = userCancelled;	//errors are handled in the PPP connection dialog
		}
	}
					
	return (pppErr);
}

/*********************************************************************************
 * NewPPPControlEndpoint - Set up the global PPP enpoint we use to control PPP.
 *********************************************************************************/
OTResult NewPPPControlEndpoint(void)
{
	OTResult	result = kOTNoError;
	TEndpointInfo epInfo;
	short oldResFile = CurResFile();
	DECLARE_UPP(MyPPPEndpointNotifier,OTNotify);
	
	INIT_UPP(MyPPPEndpointNotifier,OTNotify);

	MyOTPPPInfo.ref = OTOpenEndpointInContext(OTCreateConfiguration(kPPPControlName),0, &amp;epInfo, &amp;result,nil);
	UseResFile(oldResFile);	// bug in Modem control panel resets curresfile SD 8/5/98
	
	if((result == kOTNoError) &amp;&amp; (MyOTPPPInfo.ref != kOTInvalidEndpointRef))
	{
		result = OTInstallNotifier(MyOTPPPInfo.ref, MyPPPEndpointNotifierUPP, (void *)NULL);
		if(result == kOTNoError)
		{
			if ((result = OTIoctl(MyOTPPPInfo.ref, I_OTGetMiscellaneousEvents, (void*)1)) == kOTNoError ) 
			{
				MyOTPPPInfo.state = kPPPDown;		//kPPPDown means PPP has not been touched by us yet.
			}
			OTSetAsynchronous(MyOTPPPInfo.ref);
		}
	}

	//if some error occurred, return 0, but don't close the endpoint.
	if (result != kOTNoError) MyOTPPPInfo.ref = kOTInvalidEndpointRef;

	return (result);
}
	
	
/*********************************************************************************
 * TurnOnPPPConnectionDialog - make the PPP connection a modal event
 *
 * If on is true, then we will turn the connection dialog ON.  If on is false,
 * we will restore the conenction dialog to its previous state.
 *********************************************************************************/
OSErr TurnOnPPPConnectionDialog(EndpointRef endPoint, Boolean on)
{
	OSErr err = noErr;
	long dlogState = 0;

	err = GetCurrentUInt32Option(endPoint, OPT_ALERTENABLE, &amp;dlogState);
	if (err == noErr)
	{
		if (oldDlogState == 0) oldDlogState = dlogState;
		
		if (on)		//set the kPPPConnectionStatusDialogsFlag
			dlogState = dlogState | kPPPConnectionStatusDialogsFlag;
		else 		//turn the kPPPConnectionStatusDialogsFlag off.
			dlogState = dlogState &amp; (kPPPAllAlertsEnabledFlag - kPPPConnectionStatusDialogsFlag);
		
		if (dlogState != oldDlogState)
			err = SetCurrentUInt32Option(endPoint, OPT_ALERTENABLE, dlogState);
	}
	
	return (err);
}

/*********************************************************************************
 * ResetPPPConnectionDialog - rest the statusDialogFlag to what it was before we
 * started messing with it.
 *********************************************************************************/
OSErr ResetPPPConnectionDialog(EndpointRef endPoint)
{
	OSErr err = noErr;
	long dlogState = 0;

	err = GetCurrentUInt32Option(endPoint, OPT_ALERTENABLE, &amp;dlogState);
	if (err == noErr)
	{	
		if (dlogState != oldDlogState)	
		{
			if (!(oldDlogState&amp;kPPPConnectionStatusDialogsFlag))	//if it was off to begin with, turn it off to reset
				dlogState = dlogState &amp; (kPPPAllAlertsEnabledFlag - kPPPConnectionStatusDialogsFlag);
			else 	//if it was on before, turn it back on to reset.
				dlogState = dlogState | kPPPConnectionStatusDialogsFlag;
			
			err = SetCurrentUInt32Option(endPoint, OPT_ALERTENABLE, dlogState);
		}
		oldDlogState = 0;
	}
	
	return (err);
}

/*********************************************************************************
 * GetPPPConnectionState - determine the state of PPP
 *********************************************************************************/
OSErr GetPPPConnectionState(EndpointRef endPoint, unsigned long *PPPState)
{
	OSErr			err = noErr;

	err = GetCurrentUInt32Option(endPoint, PPP_OPT_GETCURRENTSTATE, PPPState);
	
	if (err != noErr) *PPPState = kPPPStateInitial;
		
	return (err);
}

/*********************************************************************************
 * GetCurrentUInt32Option - gets a UInt32 option from a PPP control point.
 *********************************************************************************/
OSErr GetCurrentUInt32Option(EndpointRef endPoint, OTXTIName theOption, UInt32 *value)
{
	OSErr err = noErr;
	unsigned char buf[sizeof(TOption)];
	TOption *option;
	TOptMgmt command;

	*value = 0;
	
	command.opt.buf = buf;
	command.opt.len = sizeof(TOption);
	command.opt.maxlen = sizeof(TOption);
	command.flags = T_CURRENT;
	
	option = (TOption *)buf;
	option-&gt;len = sizeof(TOption);
	option-&gt;level = COM_PPP;
	option-&gt;name = theOption;
	option-&gt;status = 0;
	option-&gt;value[0] = 0;
	
	//get the current alert flags
	err = OTOptionManagement(endPoint, &amp;command, &amp;command);
	
	if ((err != noErr) || (option-&gt;status == T_FAILURE) || (option-&gt;status == T_NOTSUPPORT))
		*value = 0L;
	else
		*value = option-&gt;value[0];
		
	return (err);
}

/*********************************************************************************
 * SetCurrentUInt32Option - sets a UInt32 option for PPP control point options.
 *********************************************************************************/
OSErr SetCurrentUInt32Option(EndpointRef endPoint, OTXTIName theOption, UInt32 value)
{
	OSErr err = noErr;
	unsigned char buf[sizeof(TOption)];
	TOption *option;
	TOptMgmt command;
	
	command.opt.buf = buf;
	command.opt.len = sizeof(TOption);
	command.opt.maxlen = sizeof(TOption);
	command.flags = T_NEGOTIATE;
	
	option = (TOption *)buf;
	option-&gt;len = sizeof(TOption);
	option-&gt;level = COM_PPP;
	option-&gt;name = theOption;
	option-&gt;status = 0;
	option-&gt;value[0] = value;
	
	//get the current alert flags
	err = OTOptionManagement(endPoint, &amp;command, &amp;command);
	
	return (err);
}

/*********************************************************************************
 * OTPPPDisconnect - disconnect OTPPP if Eudora connected it in the first place.
 * if (forceDisconnect) then we disconnect no matter who connected PPP
 * if (endConnectionAttempt) then we reset the PPP connection dialog.
 *********************************************************************************/
OSErr OTPPPDisconnect(Boolean forceDisconnect, Boolean endConnectionAttempt)
{
	OSErr err = noErr;
	
	if ((gHasOTPPP == true) 
		&amp;&amp; ((MyOTPPPInfo.ref &amp;&amp; PrefIsSet(PREF_PPP_DISC) &amp;&amp; MyOTPPPInfo.weConnectedPPP) || forceDisconnect))
	{						
		err = OTIoctl(MyOTPPPInfo.ref, I_OTDisconnect, 0);
		
		if (endConnectionAttempt) 
		{
			ResetPPPConnectionDialog(MyOTPPPInfo.ref);
		}
		
		MyOTPPPInfo.weConnectedPPP = false;
		MyOTPPPInfo.status = MyOTPPPInfo.result = 0;
	}
	
	return (err);
}

/*********************************************************************************
 * OTPPPConnectForLink - connect OT/PPP to follow a link.  Ignore the fact that
 *	we connected it, so we don't go try to close the connection later.
 *********************************************************************************/
OSErr OTConnectForLink(void)
{
	OSErr err = userCanceledErr;
	unsigned long conMethod = 0;
	Boolean weAttemptedPPP = false;
	
	// Only makes sense to do this when OT is present
	if (gUseOT)
	{
		// How are we connecting to the internet? Read from the preference files or NS database
		err = SelectedConnectionMode(&amp;conMethod,true);
			
		// do we have PPP?
		if (gHasOTPPP)
		{
			// Is OT/PPP the mode of connection?
			if (conMethod == kPPPSelected)
			{
				dialingThePhone = true;
				needPPPConnection = true;	
				gConnecting = true;	
				if (err = OTPPPConnect(&amp;weAttemptedPPP))
				{					
					OTPPPDisconnect(weAttemptedPPP, true);
				}
				gConnecting = false;
				dialingThePhone = false;
				
				// Forget about the fact that we connected OT/PPP.
				MyOTPPPInfo.weConnectedPPP = false;
			}
		}
	}
		
	return (err);
}
			
/*********************************************************************************
 * SelectedConnectionMode - determine the connection mode set in the TCP/IP control
 * panel.
 *
 *	12-16-98 JDB
 *	 Added the forceRead paramter to read from the TCP file, even if cache time
 *	has not yet run out.  We really want to know the state of TCP/IP at each
 *	connection attempt.  We don't care as much at idle time for things like
 *	the next check menu item.
 *
 *	5-19-99 JDB
 *	 Added calls to the Network Setup library.  This should prevent breakage.
 *
 *	7-16-99 JDB
 *	 Use the cached connection method unless told not to
 *
 *	12-3-99 JDB
 *	 Use the cached connection method if we just read the preferences
 *********************************************************************************/
OSErr SelectedConnectionMode(unsigned long *connectionSelection, Boolean forceRead)
{
	OSErr err = noErr;
	char currentPortName[kMaxProviderNameSize];
	char junk[kMaxProviderNameSize];
	Boolean enabled;
	static uLong method;
	static uLong lastRead = 0;

	if (HaveOSX()) 
	{
		// there's no way to tell if we're dialed up or not under OS X.
		*connectionSelection = kOtherSelected;
		return (noErr);
	}
	
	// do NOT call this unless OT is installed
	if (OTIs == false) return (fnfErr);
			
	// did we just read the preferences recently?
	if (!forceRead &amp;&amp; (lastRead&gt;0) &amp;&amp; ((TickCount()-lastRead) &lt; GetRLong(TCP_PREF_REUSE_INTERVAL)))
	{
		*connectionSelection = method;
		return (noErr);
	}

	// are we falling asleep?  Then return value from the last time, no matter what.
	if (UserIdle(TICKS2MINS) &amp;&amp; (lastRead&gt;0))
	{
		*connectionSelection = method;
		return (noErr);
	}

#ifdef	DEBUG
	Log(LOG_TRANS,"\pReading TCP/IP preferences from the disk now.");
#endif

#ifdef	USE_NETWORK_SETUP
	if (UseNetworkSetup()) 
	{
		if (IsNetworkSetupAvailable())
		{
			err = GetConnectionModeFromDatabase(connectionSelection);

			lastRead = TickCount();
			method = *connectionSelection;
		}
		else
		{
			// we have to use the Network Setup Library, but it's not available.  
			// Assume non-PPP and non-MacSLIP connection.
			lastRead = TickCount();
			method = *connectionSelection = kOtherSelected;
		}
	}
	else
	{
#endif	
		*connectionSelection = kOtherSelected;
		
		// read the port name from the TCP/IP preference file
		err = GetCurrentPortNameFromFile(currentPortName, junk, &amp;enabled);
		if (err == noErr)
		{
			if (StringSame(currentPortName,PPP_NAME))	
				*connectionSelection = kPPPSelected;
		}
		
		if (!err)
		{
			lastRead = TickCount();
			method = *connectionSelection;
		}
#ifdef	USE_NETWORK_SETUP
	}
#endif
		
	return (err);
}

/*******************************************************************************
 * UserIdle - see if the user has been idle.
 *******************************************************************************/
Boolean UserIdle(uLong ticks)
{
	Boolean result = false;
#ifdef	HAVE_GETLASTACTIVITY	
	static uLong idleTicks;
	ActivityInfo info;
	OSErr err = noErr;

	if (((GestaltBits(gestaltPowerMgrAttr)&amp;(1&lt;&lt;gestaltPMgrDispatchExists))!=0))
	{
		info.ActivityTime = 0;
		info.ActivityType = UsrActivity;
		if (!(err=GetLastActivity(&amp;info)))
		idleTicks = TickCount()-info.ActivityTime;
		
		if (idleTicks &gt; ticks)
			result = true;	
	}
#endif

	return (result);
}

/*******************************************************************************
 * CanCheckPPPState - is it possible for us to check PPP's state?
 *******************************************************************************/
Boolean CanCheckPPPState(void)
{
	return !PrefIsSet(PREF_IGNORE_PPP) &amp;&amp; (HaveTheDiseaseCalledOSX()||!gMissingNSLib);
}

/*******************************************************************************
 * CanChangePPPState - is it possible for us to change PPP's state?
 *******************************************************************************/
Boolean CanChangePPPState(void)
{
	return !PrefIsSet(PREF_IGNORE_PPP) &amp;&amp; !gMissingNSLib &amp;&amp; !HaveTheDiseaseCalledOSX();
}

/*******************************************************************************
 * PPPDown - is PPP installed, the selected mode of connection &amp; disconnected?
 *******************************************************************************/
Boolean PPPDown(void)
{
	unsigned long con = 0;
	static Boolean ret = false;
	static uLong lastCheck;

	ASSERT(!PrefIsSet(PREF_IGNORE_PPP));
	
	if (HaveTheDiseaseCalledOSX())
	{
		if (TickCount()-lastCheck &gt; GetRLong(TCP_PREF_REUSE_INTERVAL)/10+1)
		{
			Str255 host;
			
			// grab a specific host to check; if there
			// isn't one, use the mailhost
			if (!*GetRString(host,PPP_REACHABLE_HOST))
				GetPOPInfo(nil,host);
			
			// check it
			if (*host &amp;&amp; CHostUnreachableByPPP(host+1)) ret = true;
			else ret = false;
			
			lastCheck = TickCount();
		}
	}
	else if (gHasOTPPP)
	{
		SelectedConnectionMode(&amp;con,false);
		if (con == kPPPSelected)
		{
			if (MyOTPPPInfo.ref == 0) NewPPPControlEndpoint();
			GetPPPConnectionState(MyOTPPPInfo.ref, &amp;con);
			if (con != kPPPStateOpened) ret = true;
		}
	}
	
	return (ret);
}

#pragma segment Main
/*********************************************************************************
 * MyPPPEndpointNotifier - notifier function for PPP endpoint events.  It directly
 * modifies the MyOTPPPInfo global structure.
 *********************************************************************************/
pascal void MyPPPEndpointNotifier(void *context, OTEventCode code, OTResult result, void *cookie)
{		
	if (code &gt; kPPPEvent &amp;&amp; code &lt;= kPPPDCECallFinishedEvent) 
	{
		MyOTPPPInfo.status = 0;
		MyOTPPPInfo.result = (OTResult)cookie;
		
		if ((code == kPPPConnectCompleteEvent) &amp;&amp; (MyOTPPPInfo.result != kOTNoError))			
			MyOTPPPInfo.event = OTPPP_MSG_STRN + (kPPPDCECallFinishedEvent + 1) - kPPPEvent + 1;
		else
			MyOTPPPInfo.event = OTPPP_MSG_STRN + code - kPPPEvent + 1;
	}
	
	if (code == kPPPDisconnectCompleteEvent)	// Disconnect has completed.
		MyOTPPPInfo.state = MyOTPPPInfo.result ? kPPPClosing : kPPPDown;
	if (code == kPPPLowerLayerDownEvent)	//remote server isn't responding	added this 11-21-97
		MyOTPPPInfo.state = kPPPDown;
	else if ((code == kPPPConnectCompleteEvent) &amp;&amp; (MyOTPPPInfo.result == kOTNoError))			
		MyOTPPPInfo.state = kPPPUp;
}
#pragma segment TcpTrans

/*********************************************************************************
 * WaitForOTPPPDisconnect - sit and spin until the PPP state is kPPPStateInitial
 *********************************************************************************/
OSErr WaitForOTPPPDisconnect(Boolean showStatus)
{
	OSErr 			err = noErr;
	long 			ticks=TickCount();
	long 			startTicks=ticks+120;
	long 			now;
	Str255 			scratch;
	unsigned long 	PPPState;
	
	//wait for the connection to close before we start another
	if (showStatus)
	{
		GetRString(scratch, OT_PPP_DISCONNECT);
		ProgressMessage(kpMessage,scratch);
	}
	
	do
	{
		now = TickCount();
		if (now&gt;startTicks &amp;&amp; now-ticks&gt;10) 
		{
			CyclePendulum();
			ticks=now;
		}
		MiniEvents();
		if (CommandPeriod) return(pppErr = userCancelled);
		err = GetPPPConnectionState(MyOTPPPInfo.ref, &amp;PPPState);
	}
	while ((PPPState != kPPPStateInitial) &amp;&amp; (err == noErr));
	
	if (err != noErr &amp;&amp; err != userCancelled) err = errPPPStateUnknown;
	
	return (err);
}


/*********************************************************************************
 * OTPPPDialingInformation - retrieve the redial options from the PPP settings file.
 *
 * 	- Look in Preferences folder for lzcn/rmot, the Remote Access Connections file
 *	- Open the resource fork
 *	- Fetch 'cdia' id 128, which contains the info we need.
 *	
 *		the fourth long in this resource contains 3 or 4 if we are to redial.
 *		the fifth long contains the number of redials to do before giving up.
 *		the sixth long contains 1000*number of seconds to delay.
 *
 * If any of this fails, we continue on as if nothing happened.  Redialing just won't
 * happen.
 *
 * The spec locating the rmot preference file is cached.  This way, we can check
 * the preference file periodically, and make sure the setting hasn't changed.
 *
 * This will break in a future OT. 
 *	
 *	5-19-99 JDB
 *	 Added calls to the Network Setup library.  This should prevent breakage.
 *********************************************************************************/
OSErr OTPPPDialingInformation(Boolean *redial, unsigned long *numRedials, unsigned long *delay)
{
	OSErr err = noErr;
	short vRef = 0;
	long dirId = 0;
	CInfoPBRec hfi;
	Str31 name;
	short refNum = 0;
	Handle probe = 0;
	short oldRes;
	
	oldRes = CurResFile();
	
	//do NOT call this unless OT/PPP is installed and being used
	if (gHasOTPPP == false) return (fnfErr);
	
	*numRedials = *delay = 0;
	*redial = false;

#ifdef	USE_NETWORK_SETUP
	// grok the settings from the TCP/IP preference file using the Network Setup Library.
	if (UseNetworkSetup()) 
	{
		err = GetPPPDialingInformationFromDatabase(redial, numRedials, delay);
		return (err);
	}
#endif
		
	if (PPPprefFileSpec.name[0] == 0)	//have we not yet already located the PPP pref file?
	{
		/* Locate the PPP preferences file */
				
		//find the active Preferences folder
		err = FindFolder(kOnSystemDisk,kPreferencesFolderType,False,&amp;vRef,&amp;dirId);
		if (err == noErr)
		{
			hfi.hFileInfo.ioNamePtr = name;
			hfi.hFileInfo.ioVRefNum = vRef;
			SearchDirectoryForFile(&amp;hfi, dirId, PPP_PREF_FILE_TYPE, PPP_PREF_FILE_CREATOR);
		}
	}
		
	if (PPPprefFileSpec.name[0] != 0)	//have we located the PPP pref file?
	{
		refNum = FSpOpenResFile(&amp;PPPprefFileSpec,fsRdPerm);
		err = ResError();
		if (err == noErr &amp;&amp; refNum &gt;= 0)
		{	
			//this could breka in future versions of OT
			probe = Get1Resource(DIAL_RESOURCE,DIAL_RESOURCE_ID);
			err = ResError();
			if (err == noErr &amp;&amp; probe != 0)
			{
				//this is agonna break in future versions ot fer sure
				if (((long *)*probe)[3] == 2)
				{
					*redial = false;
					*numRedials = *delay = 0;
				}
				else
				{
					*redial = true;
					*numRedials = ((long *)*probe)[4];
					*delay = ((long *)*probe)[5]/1000;
				}
			}
		}
		CloseResFile(refNum);
	}
		
	if ((err != noErr) || (PPPprefFileSpec.name[0] == 0)) err = errPPPPrefNotFound;
	
	UseResFile(oldRes);
	
	return (err);
}

/*********************************************************************************
 * SearchDirectoryForFile - Recursively search a directory for a file with a
 * given creator and file type.  This is an expensive function to call.
 *********************************************************************************/
Boolean SearchDirectoryForFile(CInfoPBRec *info, long dirToSearch, OSType type, OSType creator)
{
	short index = 1;
	OSErr err = noErr;
	Boolean static foundIt;
	
	foundIt = false;
	
	do
	{
		info-&gt;hFileInfo.ioFDirIndex = index;
		info-&gt;hFileInfo.ioDirID = dirToSearch;
		
		err = PBGetCatInfoSync(info);
		
		if (err == noErr)
		{
			//found a directory
			if ((info-&gt;hFileInfo.ioFlAttrib &amp; ioDirMask)	!= 0)
			{
				SearchDirectoryForFile(info, info-&gt;hFileInfo.ioDirID, type, creator);
				err = noErr;
			}
			else	//found a file
			{
				if ((info-&gt;hFileInfo.ioFlFndrInfo.fdType == type &amp;&amp;
						info-&gt;hFileInfo.ioFlFndrInfo.fdCreator == creator))
				{
					// Found it.  Stop the search!
					foundIt = true;
					FSMakeFSSpec(info-&gt;hFileInfo.ioVRefNum, info-&gt;hFileInfo.ioFlParID, info-&gt;hFileInfo.ioNamePtr, &amp;PPPprefFileSpec);
				}
			}
			++index;
		}
	} while (err == noErr &amp;&amp; !foundIt);
	
	return (foundIt);
}

/*********************************************************************************
 * SpinOnWithConnectionCheck - spin until a return code is not inProgress.  Check 
 * connection while spinning.
 *********************************************************************************/
short SpinOnWithConnectionCheck(short *rtnCodeAddr,long maxTicks,Boolean allowCancel,Boolean forever)
{
	long ticks=TickCount();
	long startTicks=ticks+120;
	long now;
#ifdef CTB
	extern ConnHandle CnH;
#endif
	Boolean oldCommandPeriod = CommandPeriod;
	Boolean slow = False;
	static short slowThresh;
	
	if (!slowThresh) slowThresh = GetRLong(SPIN_LENGTH);
	
	if (allowCancel) YieldTicks = 0;
	if (allowCancel || *rtnCodeAddr==inProgress)
	{
		CommandPeriod = False;
		do
		{
			// check to see if we need ppp, but the connection is down
			if (needPPPConnection &amp;&amp; MyOTPPPInfo.state != kPPPUp) return(errLostConnection);
					
			now = TickCount();
			if (now&gt;startTicks &amp;&amp; now-ticks&gt;slowThresh) {slow = True;if (!InAThread()) CyclePendulum(); else MyYieldToAnyThread();ticks=now;}
			MiniEvents();
			if (CommandPeriod  &amp;&amp; !forever) return(userCancelled);
			if (maxTicks &amp;&amp; startTicks+maxTicks &lt; now+120) break;
		}
		while (*rtnCodeAddr == inProgress);
		if (CommandPeriod) return(userCancelled);
		CommandPeriod = oldCommandPeriod;
	}
	return(*rtnCodeAddr);
}

//Some sticky stuff

/*********************************************************************************
 * GetHostByAddr - Call either TCPGetHostByAddr or OTGetHostByAddr, depending on
 * whether OT is installed or not.
 *********************************************************************************/
OSErr GetHostByAddr(struct hostInfo *hostInfoPtr,long addr)
{
	// Do we have a NAT?
	if (0x0A000000 == (addr&amp;0xff000000) ||
			0xAC100000 == (addr&amp;0xfff00000) ||
			0xC0A80000 == (addr&amp;0xffff0000))
	{
		Str31 literal;
		ComposeRString(literal,NAT_FMT,addr);
		literal[*literal+1] = 0;
		strcpy(hostInfoPtr-&gt;cname,literal+1);
		hostInfoPtr-&gt;addr[1] = addr;
		hostInfoPtr-&gt;rtnCode = 0;
		return noErr;
	}
	
	if (gUseOT == true)		// OT is installed
	{
		InetHostInfo domainName;
		OSErr err = OTGetHostByAddr(addr, &amp;domainName);
		
		if (err == noErr)	// our caller expects the hostInfoPtr to point a hostInfo struct.
		{
			short count;
			
			strcpy(hostInfoPtr-&gt;cname,domainName.name);		
			for (count = 0; count &lt; MIN(NUM_ALT_ADDRS,kMaxHostAddrs); count ++)
				hostInfoPtr-&gt;addr[count] = domainName.addrs[count];
			hostInfoPtr-&gt;rtnCode = 0;
		}
		return (err);
	}
	ASSERT ( false );
	return unimpErr;	/* unreachable, I think */
}


/*********************************************************************************
 * GetHostByName - Call either TCPGetHostByName or OTGetHostByName, depending on
 * whether OT is installed or not.
 *
 * The caller expects hostInfoPtr to be pointing to a TCP hostInfo struct.  So
 * if we do the OT thing, point hostInfoPtr at a hostInfo struct we fill with
 * the results of the OTGetHostByName call.
 *********************************************************************************/
int GetHostByName(UPtr name, struct hostInfo **hostInfoPtr)
{
	static struct hostInfo trickCaller;
	
	if (gUseOT == true)	// OT is installed
	{
		InetHostInfo domainName;
		int err = noErr;
		short count;
		InetDomainName hostName;
		
		PtoCcpy(hostName,name);
		
		err = OTGetHostByName(hostName, &amp;domainName);
		
		if (err == noErr)	// our caller expects the hostInfoPtr to point a hostInfo struct.
		{					
			*hostInfoPtr = &amp;trickCaller;
			
			strcpy(trickCaller.cname,domainName.name);
			for (count = 0; count &lt; MIN(NUM_ALT_ADDRS,kMaxHostAddrs); count ++)
				trickCaller.addr[count] = domainName.addrs[count];
			trickCaller.rtnCode = 0;
		}
		return (err);
	}
	ASSERT ( false );
	return unimpErr;	/* unreachable, I think */
}

/*********************************************************************************
 * PPPIsMostDefinitelyUpAndRunning - return true if we're connected with PPP, or
 *	it's not an issue.
 *********************************************************************************/
Boolean PPPIsMostDefinitelyUpAndRunning(void)
{
	Boolean connected = true;
	unsigned long con = 0;
	
	if (gHasOTPPP)
	{
		SelectedConnectionMode(&amp;con,false);
		if ((con == kPPPSelected) &amp;&amp; (MyOTPPPInfo.state != kPPPUp)) connected = false;
	}
	
	return (connected);
}

/*********************************************************************************
 * UpdateCachedTCPIPPrefInfo - read from the preference files or NS Library now
 *********************************************************************************/
void UpdateCachedConnectionMethodInfo(void)
{
	unsigned long con = 0;
	static uLong method;
	
	if (SelectedConnectionMode(&amp;con, true)==noErr)
	{
		// return true if the method has changed
		if (con != method)
		{
			method = con;
			gUpdateTPWindow = true;	// update the TP window
		}
	}
}

/*********************************************************************************
 * NeedToUpdateTP - do we need to adjust the next check time in the TP window?
 *********************************************************************************/
Boolean NeedToUpdateTP(void)
{
	Boolean updateIt = false;
	
	if (gUpdateTPWindow)
	{
		updateIt = true;
		gUpdateTPWindow = false;
	}
	
	return (updateIt);
}

/*********************************************************************************
 * AutoCheckOKWithDBRead - read from the preference files or NS Library and see
 *	if an autocheck is appropriate.
 *********************************************************************************/
Boolean AutoCheckOKWithDBRead(Boolean updatePers)
{
	Boolean result = false;
	OSErr err = noErr;
	
	// are we set up to not check when not connected?
	if (gUseOT &amp;&amp; !PrefIsSet(PREF_IGNORE_PPP) &amp;&amp; PrefIsSet(PREF_PPP_NOAUTO))
	{
		// make sure we're really, truly connected
		UpdateCachedConnectionMethodInfo();
		result = AutoCheckOK();
		
		// we're not.  Tell this personality to cram it.
		if (!result &amp;&amp; updatePers) 
		{
			PersSkipNextCheck();
			gUpdateTPWindow = true;
		}
	}
	else
	{
		// not set to not check when not connected.  Do the normal thing.
		result = AutoCheckOK();
	}	
	
	return (result);
}

#ifdef ESSL
// Declare the routine to set up the TransVector for doing SSL
TransVector ESSLSetupVector(TransVector theTrans);
#endif

TransVector GetTCPTrans()
{
	TransVector theTrans;
	
	theTrans = OTTCPTrans;
#ifdef ESSL
	return ESSLSetupVector(theTrans);
#else
	return theTrans;
#endif
}

/************************************************************************
 * TcpFastFlush - run through the queue, killing off defunct streams
 * Call KillDeadKyTStreams if we happen to be using open transport.
 ************************************************************************/
void TcpFastFlush(Boolean destroy)
{
	static Boolean flushing = false;
	
	// are we already flushing streams from somewhere?
	if (flushing) return;
	
	// kill defunct streams
	flushing = true;
	
	if (gUseOT) 
		KillDeadMyTStreams(destroy);
	
	// we're done flushing streams for now.
	flushing = false;
}


/**********************************************************************
 * CheckConnectionSettings - Attempt to connect to a host/port pair.
 **********************************************************************/
OSErr CheckConnectionSettings ( UPtr host, long port, StringPtr errorMessage ) {
	OSErr err = noErr;
	TransStream stream = NULL;
	Boolean oldPref = PrefIsSet(PREF_IGNORE_PPP);

	
//	Init the TransStream
	if ( noErr == ( err = NewTransStream ( &amp;stream ))) {
	
	//	See if the host is there....
		SetPref(PREF_IGNORE_PPP,YesStr);
		err = ConnectTrans ( stream, host, port, true, GetRLong(SHORT_OPEN_TIMEOUT));
		SetPref(PREF_IGNORE_PPP,oldPref ? YesStr : NoStr);

	//	Grab an error message if we failed
		if ( noErr != err &amp;&amp; errorMessage != NULL ) {
			short realSettingsRef = SettingsRefN;

			SettingsRefN = GetMainGlobalSettingsRefN();		
			OTTELo ( errOpenStream, stream-&gt;streamErr, errorMessage );
			SettingsRefN = realSettingsRef;
			}
			
	//	That's all we wanted.  Cleanup.
		if ( noErr == err )
			DestroyTrans(stream);
		ZapTransStream ( &amp;stream );
		}
	
	return err;
	}

