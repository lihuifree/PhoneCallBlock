//
//  CallHandler.m
//  PhoneCallBlock
//
//  Created by Hui Li on 12-5-11.
//  Copyright (c) 2012年 hust. All rights reserved.
//

#import "CallHandler.h"

@implementation CallHandler

extern NSString* const kCTSMSMessageReceivedNotification;
extern NSString* const kCTSMSMessageReplaceReceivedNotification;
extern NSString* const kCTSIMSupportSIMStatusNotInserted;
extern NSString* const kCTSIMSupportSIMStatusReady; 



typedef struct __CTCall CTCall;
extern NSString *CTCallCopyAddress(void*, CTCall *);
extern void CTCallDisconnect(CTCall*);

void* CTSMSMessageSend(id server,id msg);
typedef struct __CTSMSMessage CTSMSMessage;  
NSString *CTSMSMessageCopyAddress(void *, CTSMSMessage *);  
NSString *CTSMSMessageCopyText(void *, CTSMSMessage *);


int CTSMSMessageGetRecordIdentifier(void * msg);
NSString * CTSIMSupportGetSIMStatus();  
NSString * CTSIMSupportCopyMobileSubscriberIdentity(); 

id  CTSMSMessageCreate(void* unknow/*always 0*/,NSString* number,NSString* text);
void * CTSMSMessageCreateReply(void* unknow/*always 0*/,void * forwardTo,NSString* text);


id CTTelephonyCenterGetDefault(void);
void CTTelephonyCenterAddObserver(id,id,CFNotificationCallback,NSString*,void*,int);
void CTTelephonyCenterRemoveObserver(id,id,NSString*,void*);
int CTSMSMessageGetUnreadCount(void); 

static void callback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) 
{
    NSString *notifyname=(NSString *)name;

    if ([notifyname isEqualToString:@"kCTCallStatusChangeNotification"])//电话
    {
        NSDictionary *info = (NSDictionary*)userInfo;
        
        NSString *state=[[info objectForKey:@"kCTCallStatus"] stringValue];
        if ([state isEqualToString:@"5"])//disconnect
            NSLog(@"未接:%@",state);
        
    }
    else if ([notifyname isEqualToString:@"kCTCallIdentificationChangeNotification"])
    {
        NSDictionary *info = (NSDictionary *)userInfo;
        CTCall *call = (CTCall *)[info objectForKey:@"kCTCall"];
        NSString *caller = CTCallCopyAddress(NULL, call);
        NSLog(@"电话号码:%@",caller);
		if ([caller isEqualToString:@"18948745755"])
		{
			//disconnect this call
			NSLog(@"挂雷冰");
			CTCallDisconnect(call);
		}
        
    }
    else if ([notifyname isEqualToString:@"kCTMessageReceivedNotification"])//收到短信
    {
        /*
         kCTMessageIdKey = "-2147483636";
         kCTMessageTypeKey = 1; 
		 */
        
        NSDictionary *info = (NSDictionary *)userInfo;
        CFNumberRef msgID = (CFNumberRef)[info objectForKey:@"kCTMessageIdKey"];
        int result;
        CFNumberGetValue((CFNumberRef)msgID, kCFNumberSInt32Type, &result);
        
        
		 Class CTMessageCenter = NSClassFromString(@"CTMessageCenter");
		 id mc = [CTMessageCenter sharedMessageCenter];
		 id incMsg = [mc incomingMessageWithId: result];
		 
		 int msgType = (int)[incMsg messageType];
		 
		 if (msgType == 1) //experimentally detected number
		 {
		 id phonenumber = [incMsg sender];
		 
		 NSString *senderNumber = (NSString *)[phonenumber canonicalFormat];
		 id incMsgPart = [[incMsg items] objectAtIndex:0];
		 NSData *smsData = [incMsgPart data];
		 NSString *smsText = [[NSString alloc] initWithData:smsData encoding:NSUTF8StringEncoding];
		 
		 }
         	 
    }
    else if ([notifyname isEqualToString:@"kCTIndicatorsSignalStrengthNotification"])//信号
    {
        /*
		 kCTIndicatorsGradedSignalStrength = 2;
		 kCTIndicatorsRawSignalStrength = "-101";
		 kCTIndicatorsSignalStrength = 19;
		 */
        
    }
    else if ([notifyname isEqualToString:@"kCTRegistrationStatusChangedNotification"])//网络注册状态
    {
        /*
         kCTRegistrationInHomeCountry = 1;
         kCTRegistrationStatus = kCTRegistrationStatusRegisteredHome;
		 */
        
    }
    else if ([notifyname isEqualToString:@"kCTRegistrationDataStatusChangedNotification"])
    {
        /*
         kCTRegistrationDataActive = 1;
         kCTRegistrationDataAttached = 1;
         kCTRegistrationDataConnectionServices =     (
         kCTDataConnectionServiceTypeInternet,
         kCTDataConnectionServiceTypeWirelessModemTraffic,
         kCTDataConnectionServiceTypeWirelessModemAuthentication
         );
         kCTRegistrationDataContextID = 0;
         kCTRegistrationDataIndicator = kCTRegistrationDataIndicator3G;
         kCTRegistrationDataStatus = kCTRegistrationDataStatusAttachedAndActive;
         kCTRegistrationDataStatusInternationalRoaming = 1;
         kCTRegistrationRadioAccessTechnology = kCTRegistrationRadioAccessTechnologyUTRAN;
		 */ 
    }
    else if ([notifyname isEqualToString:@"kCTRegistrationCellChangedNotification"])
    {
        /*
         kCTRegistrationGsmCellId = 93204174;
         kCTRegistrationGsmLac = 55583;
         kCTRegistrationInHomeCountry = 1;
         kCTRegistrationRadioAccessTechnology = kCTRegistrationRadioAccessTechnologyUTRAN; 
		 */
    }
    else if ([notifyname isEqualToString:@"kCTIndicatorRadioTransmitNotification"])
    {
        /*
		 kCTRadioTransmitDCHStatus = 1;
		 */ 
    }
    //NSLog(@"名字:%@-详细:%@",notifyname,userInfo);
    
	
}

static void signalHandler(int sigraised)  
{  
    printf("\nInterrupted.\n");  
    exit(0);  
}

+ (void)start
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];  
	
    // Initialize listener by adding CT Center observer implicit  
    id ct = CTTelephonyCenterGetDefault();  
    CTTelephonyCenterAddObserver( ct, NULL, callback,NULL,NULL,  
                                 CFNotificationSuspensionBehaviorHold);  
	
    // Handle Interrupts  
    sig_t oldHandler = signal(SIGINT, signalHandler);  
    if (oldHandler == SIG_ERR)  
    {  
        printf("Could not establish new signal handler");  
        exit(1);  
    }  
	
    // Run loop lets me catch notifications  
    printf("Starting run loop and watching for notification.\n");  
    CFRunLoopRun();  
	
    // Shouldn't ever get here. Bzzzt  
    printf("Unexpectedly back from CFRunLoopRun()!\n");  
    [pool release]; 
}


@end
