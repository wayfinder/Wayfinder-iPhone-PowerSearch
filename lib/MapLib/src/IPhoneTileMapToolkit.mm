/*
  Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the name of the Vodafone Group Services Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "IPhoneTileMapToolkit.h"

typedef vector<pair<uint32, TileMapIdleListener*> > idleListeners_vect_t;
typedef vector<pair<TileMapTimerListener*, NSTimer*> > timerListeners_vect_t;

/******************************************************************************
 *
 * Idle observer Objective-C class
 *
 *****************************************************************************/
@interface WFIdleObserver : NSObject 
{
@private
    bool running;
    uint32 currentID;
    NSNotificationCenter *ncenter;
    NSNotificationQueue *nqueue;
	idleListeners_vect_t *idleListeners;
}

- (uint32)addListener:(TileMapIdleListener *)listener;
- (bool)removeListener:(TileMapIdleListener *)listener listenerId:(uint32)listenerId;
- (void)idleCallback:(id)notification;
@end

@implementation WFIdleObserver

- (id)init
{
    if (self = [super init]) {
        running = NO;
        currentID = 0;
        ncenter = [NSNotificationCenter defaultCenter];
        nqueue = [NSNotificationQueue defaultQueue];
        idleListeners = new idleListeners_vect_t;

        [ncenter addObserver:self selector:@selector(idleCallback:)
                        name:@"idleNotification" object:nil];
    }
    return self;
}


- (void)dealloc
{
    [ncenter removeObserver:self];
    delete idleListeners;
    [super dealloc];
}


- (uint32)addListener:(TileMapIdleListener *)listener
{
    if (++currentID == 0)
        currentID = 1;

    idleListeners->push_back(make_pair(currentID, listener));

    if (!running) {
        NSNotification *notification = [NSNotification
            notificationWithName:@"idleNotification" object:self];
        [nqueue enqueueNotification:notification postingStyle:NSPostWhenIdle];
        running = true;
    }
    return currentID;
}


- (bool)removeListener:(TileMapIdleListener *)listener listenerId:(uint32)listenerId
{
	idleListeners_vect_t::iterator it = idleListeners->begin();
	while (it != idleListeners->end()) {
		if ((*it).first == listenerId && (*it).second == listener) {
			idleListeners->erase(it);
            return true;
		}
        ++it;
	}
    return false;
}


- (void)idleCallback:(id)notification
{
    running = false;

    /* Make a copy of the listener list so that we can be sure that the list is
     * not mutated while we're traversing it */
    idleListeners_vect_t listeners = *idleListeners;
    idleListeners->clear();

    idleListeners_vect_t::iterator it = listeners.begin();
    while (it != listeners.end()) {
        (*it).second->runIdleTask((*it).first);
        ++it;
    }
}

@end

/******************************************************************************
 *
 * Periodic timer Objective-C class
 *
 *****************************************************************************/
@interface PeriodicTimer : NSObject
{
@private
	NSTimer *ptimer;
	uint32 timerID;
	TileMapTimerListener *listener;
}
@property (nonatomic,readonly) uint32 timerID;

- (void)start:(uint32)period;
- (void)stop;
- (void)timerCallback:(NSTimer*)timer;
- (bool)isValid;
@end

@implementation PeriodicTimer

@synthesize timerID;

- (id)initWithListener:(TileMapTimerListener *)aListener timerID:(uint32)aTimerID
{
    if (self = [super init])
    {
        listener = aListener;
        timerID = aTimerID;
    }
    return self;
}


- (void)start:(uint32)period
{
    [self stop];
    ptimer = [NSTimer
        scheduledTimerWithTimeInterval:(double)period/1000.0 target:self
                              selector:@selector(timerCallback:) userInfo:nil
                               repeats:YES];
}

	
- (void)stop
{
    [ptimer invalidate];
}


- (bool)isValid
{
	return [ptimer isValid];
}


- (void)timerCallback:(NSTimer*)timer
{
	listener->timerExpired(timerID); 
}


- (void)dealloc 
{
    [self stop];
	[super dealloc];	
}

@end


/******************************************************************************
 *
 * Periodic timer C++ class
 *
 *****************************************************************************/
class IPhoneTileMapPeriodicTimer : public TileMapPeriodicTimer
{
public:
	IPhoneTileMapPeriodicTimer(TileMapTimerListener* listener, uint32 timerId);
	virtual ~IPhoneTileMapPeriodicTimer();

	void start(uint32 period_millis);
	void stop();
	bool active();

	void timerExpired(NSTimer* timer);

    uint32 timerID() { return periodicTimer.timerID; }

private:
	PeriodicTimer *periodicTimer;
};


IPhoneTileMapPeriodicTimer::IPhoneTileMapPeriodicTimer(TileMapTimerListener* listener, uint32 timerId)
	: TileMapPeriodicTimer(listener, timerId)
{
    periodicTimer = [[PeriodicTimer alloc] initWithListener:listener timerID:timerId];
}


IPhoneTileMapPeriodicTimer::~IPhoneTileMapPeriodicTimer()
{
	[periodicTimer release];
}


void IPhoneTileMapPeriodicTimer::start(uint32 period_millis)
{
	[periodicTimer start:period_millis];
}

	
void IPhoneTileMapPeriodicTimer::stop()
{
	[periodicTimer stop];
}


bool IPhoneTileMapPeriodicTimer::active()
{
	return [periodicTimer isValid];
}


/******************************************************************************
 *
 * One-shot timer Objective-C class
 *
 *****************************************************************************/
@interface WFTimer : NSObject
{
@private
    NSTimer *timer;
    TileMapTimerListener *listener;
	uint32 timerID;
    IPhoneTileMapToolkit *toolkit;
}

@property (nonatomic, readonly) uint32 timerID;
@property (nonatomic, readonly) TileMapTimerListener *listener;

- (id)initWithListener:(TileMapTimerListener *)listener
               timeout:(uint32)timeout
               timerID:(uint32)timerID
                parent:(IPhoneTileMapToolkit *)parent;
- (void)timerCallback:(NSTimer*)timer;
@end

@implementation WFTimer
@synthesize timerID, listener;

- (id)initWithListener:(TileMapTimerListener *)aListener
               timeout:(uint32)timeout
               timerID:(uint32)aTimerID
                parent:(IPhoneTileMapToolkit *)parent
{
    if (self = [super init])
    {
        listener = aListener;
        timerID = aTimerID;
        toolkit = parent;

        timer = [NSTimer
            scheduledTimerWithTimeInterval:(double)(timeout / 1000.0)
                                    target:self
                                  selector:@selector(timerCallback:)
                                  userInfo:nil
                                   repeats:NO];
    }
    return self;
}


- (void)dealloc 
{
    [timer invalidate];
	[super dealloc];
}

 
- (void)timerCallback:(NSTimer*)aTimer
{
    listener->timerExpired(timerID);
    toolkit->cancelTimer(listener, timerID);
    timer = nil;
}

@end


/******************************************************************************
 *
 * The TileMapToolkit class.
 *
 *****************************************************************************/
IPhoneTileMapToolkit::IPhoneTileMapToolkit(id parent) :
    timerID(0)
{
    m_idleObserver = [[WFIdleObserver alloc] init];
    m_timers = [[NSMutableArray alloc] init];
}


IPhoneTileMapToolkit::~IPhoneTileMapToolkit()
{
    [m_idleObserver release];
    [m_timers release];
}


/// Creates a new periodic timer. 
TileMapPeriodicTimer*
IPhoneTileMapToolkit::createPeriodicTimer(TileMapTimerListener* listener,
                                          priority_t prio)
{
	if (++timerID == 0)
        timerID = 1;
	return new IPhoneTileMapPeriodicTimer(listener, timerID);
}


/**
 *   Requests a timer from the system. When the timer
 *   expires client->timerExpired(id) should be called.
 *   @param client  Requester to be called when it is done.
 *   @param timeoutMS Timeout in milliseconds.
 *   @return The id of the timer.
 */
uint32 IPhoneTileMapToolkit::requestTimer(TileMapTimerListener* client,
											uint32 timeout,
											priority_t prio)
{
    if (++timerID == 0)
        timerID = 1;
    WFTimer *newTimer = [[WFTimer alloc] initWithListener:client
                                                  timeout:timeout
                                                  timerID:timerID
                                                   parent:this];
    [m_timers addObject:newTimer];
    [newTimer release];
    return timerID;
}


/**
 *   Requests that the client should not be called.
 */
bool IPhoneTileMapToolkit::cancelTimer(TileMapTimerListener* client, uint32 timerID)
{
    for (WFTimer *timer in m_timers) {
        if (timer.listener == client && timer.timerID == timerID) {
            [m_timers removeObject:timer];
            return true;
        }
    }
    return false;
}


/**
 *   Requests to be notified once when the system is idle.
 *   0 should not be returned.
 *   @param client The client to be called.
 *   @return An id which will be used when calling the client
 */
uint32 IPhoneTileMapToolkit::requestIdle(TileMapIdleListener* client)
{
    return [m_idleObserver addListener:client];	
}


/**
 *   Request not to be called when the system is idle for the 
 *   supplied client and id. 
 */
bool IPhoneTileMapToolkit::cancelIdle(TileMapIdleListener* client, uint32 clientId)
{
    return [m_idleObserver removeListener:client listenerId:clientId];
}


/**
 *   Returns the available memory and the biggest block.
 */
uint32 IPhoneTileMapToolkit::availableMemory(uint32& biggestBlock) const
{
	return 0;
}


/**
 *   Returns if availableMemory() is implemented and working 
 *   on the current platform.
 */
bool IPhoneTileMapToolkit::trustAvailableMemory() const
{
	return false;
}


/**
 *   Returns an id string containing info about the client
 *   which will be used when requesting the TileMapFormatDesc
 *   from the server. Max 20 chars.
 */
const char* IPhoneTileMapToolkit::getIDString() const
{
	return "ps1-iphone";
}
