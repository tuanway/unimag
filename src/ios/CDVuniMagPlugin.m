
#import "CDVuniMagPlugin.h"
#import "uniMag.h"


#define PhoneGapLOG_INFO     @"[umPG] "
#define LOGI(...) (logEnabled_i ? NSLog(PhoneGapLOG_INFO    __VA_ARGS__) : (void)0)

@interface CDVuniMagPlugin () {
    uniMag   *uniReader;       //reference to native iOS uniMag SDK
}

@property (retain, nonatomic) NSString *callbackId_StateChange;  //callbackID used for StateChange notification
@property (retain, nonatomic) NSString *callbackId_CMD;  //callbackID used for CMD response notification
@property (retain, nonatomic) NSString *callbackId_Card;  //callbackID used for card data notification
@end

@implementation CDVuniMagPlugin
@synthesize callbackId_StateChange=_callbackId_StateChange;
@synthesize callbackId_CMD=_callbackId_CMD;
@synthesize callbackId_Card=_callbackId_Card;


static volatile BOOL logEnabled_i = YES;


////////////////////////////////////////////////////////////
-(void)getSDKVersion:(CDVInvokedUrlCommand *)command{
    NSString *tmp = [uniMag SDK_version];
    LOGI(@"SDK version: %@", tmp);
    CDVPluginResult *result=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: tmp];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    
}

-(void)enableLogging:(CDVInvokedUrlCommand *)command{
    BOOL tmp = NO;
    if (0 != command.arguments.count) {
        NSString* sourceType = [command.arguments objectAtIndex:0];
        NSString *str = [NSString stringWithFormat:@"%@", sourceType];
        LOGI(@"v->>%@",str);
        if ([str isEqualToString: @"1"]){
            tmp = YES;
        }
    }
    LOGI(@"enable Logging? %d", tmp);
    logEnabled_i = tmp;
    [uniMag enableLogging:tmp];
}

typedef enum {
    Notif_state,       //no err.
    Notif_connect_fail,
    Notif_swipe_fail,
    Notif_CMD_fail,
    Notif_systemMSG,
} UmNotifType;

-(void)notif_StateChange : (UmNotifType) type : (NSString*) msg{
    NSString* strFlag = @"";
    switch (type) {
        case Notif_state:
            strFlag = @"STATECH";
            break;
        case Notif_connect_fail:
            strFlag = @"CONNECT";
            break;
        case Notif_swipe_fail:
            strFlag = @"SWIPEER";
            break;
        case Notif_CMD_fail:
            strFlag = @"CMNDERR";
            break;
        case Notif_systemMSG:
            strFlag = @"SYSMESG";
            break;
            
        default:
            LOGI(@"-- notif_StateChange, err");
            return;
    }
    NSString * strFlagAllInfo = [NSString stringWithFormat: @"%@ %@", strFlag, msg];
    LOGI(@"-- %@", strFlagAllInfo);
    CDVPluginResult *result=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: strFlagAllInfo];
    [result setKeepCallbackAsBool: true];
    [self.commandDelegate sendPluginResult:result callbackId: self.callbackId_StateChange];
    
}

//called when uniMag is physically attached
- (void)umDevice_attachment:(NSNotification *)notification {
    LOGI(@"attach event");
    NSString * msg = @"attach";
    [self notif_StateChange: Notif_state : msg];
}

//called when uniMag is physically detached
- (void)umDevice_detachment:(NSNotification *)notification {
    LOGI(@"Dettach event");
    NSString * msg = @"detach";
    [self notif_StateChange: Notif_state : msg];
}
- (void)umConnection_InsufficientPower{
    LOGI(@"Connection InsufficientPower");
    NSString * msg = @"InsufficientPower";
    [self notif_StateChange: Notif_connect_fail : msg];
    
}
- (void)umConnection_MonoAudio{
    LOGI(@"Connection MonoAudio");
    NSString * msg = @"MonoAudio";
    [self notif_StateChange: Notif_connect_fail : msg];
    
}
- (void)umConnection_Powering{
    LOGI(@"Connection Powering");
    NSString * msg = @"powering";
    [self notif_StateChange: Notif_state : msg];
    
}


//called when SDK failed to handshake with reader in time. ie, the connection task has timed out
- (void)umConnection_timeout:(NSNotification *)notification {
    LOGI(@"Connect timeout");
    NSString * msg = @"timeout";
    [self notif_StateChange: Notif_connect_fail : msg];
}

//called when the connection task is successful. SDK's connection state changes to true
- (void)umConnection_connected:(NSNotification *)notification {
    LOGI(@"Connect OK, event");
    NSString * msg = @"connected";
    [self notif_StateChange: Notif_state : msg];
}

//called when SDK's connection state changes to false. This happens when reader becomes
// physically detached or when a disconnect API is called
- (void)umConnection_disconnected:(NSNotification *)notification {
    LOGI(@"disconn, event");
    NSString * msg = @"disconnect";
    [self notif_StateChange: Notif_state : msg];
}

- (void)umSwipe_Swipe {
    LOGI(@"Swipe can_Swipe");
    NSString * msg = @"swipe";
    [self notif_StateChange: Notif_state : msg];
}

- (void)umSwipe_timeout:(NSNotification *)notification {
    LOGI(@"Swipe timeout");
    NSString * msg = @"timeout";
    [self notif_StateChange: Notif_swipe_fail : msg];
}

- (void)umDataProcessing:(NSNotification *)notification {
    LOGI(@"card DataProcessing");
    if ([uniReader getRunningTask]!=UMTASK_SWIPE)
        return;
    NSString * msg = @"processing";
    [self notif_StateChange: Notif_state : msg];
}

//called when SDK failed to read a valid card swipe
- (void)umSwipe_invalid:(NSNotification *)notification {
    LOGI(@"Swipe invalid");
    NSString * msg = @"invalid";
    [self notif_StateChange: Notif_swipe_fail : msg];
}

//called when SDK received a swipe successfully
- (void)umSwipe_receivedSwipe:(NSNotification *)notification {
    LOGI(@"card data received");
    NSData *cardData = notification.object;
    LOGI(@"%@", cardData.description);
    CDVPluginResult *result=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer: cardData];
    [result setKeepCallbackAsBool: true];
    [self.commandDelegate sendPluginResult:result callbackId: self.callbackId_Card];
}

- (void)umCommand_Sending {
    LOGI(@"CMD Sending");
    NSString * msg = @"sending";
    [self notif_StateChange: Notif_state : msg];
}

- (void)umCommand_timeout:(NSNotification *)notification {
    LOGI(@"CMD timeout");
    NSString * msg = @"timeout";
    [self notif_StateChange: Notif_CMD_fail : msg];
}

- (void)umCommand_receivedResponse:(NSNotification *)notification {
    LOGI(@"got CMD Response");
    NSData *cmdResponse = notification.object;
    LOGI(@"%@", cmdResponse.description);
    CDVPluginResult *result=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer: cmdResponse];
    [result setKeepCallbackAsBool: true];
    [self.commandDelegate sendPluginResult:result callbackId: self.callbackId_CMD];
}

- (void)umCommand_SystemMessage:(NSNotification *)notification {
    LOGI(@"SDK SystemMessage");
    NSString * msg = notification.object;
    [self notif_StateChange: Notif_systemMSG : msg];
}


-(void) umsdk_registerAllNotif:(BOOL) reg {
    
    //list of notifications and their corresponding selector
    const struct {__unsafe_unretained NSString *n; SEL s;} noteAndSel[] = {
        //
        {uniMagAttachmentNotification       , @selector(umDevice_attachment:)},
        {uniMagDetachmentNotification       , @selector(umDevice_detachment:)},
        //
        {uniMagInsufficientPowerNotification, @selector(umConnection_InsufficientPower)},
        {uniMagMonoAudioErrorNotification,    @selector(umConnection_MonoAudio)},
        {uniMagPoweringNotification,          @selector(umConnection_Powering)},
        
        {uniMagTimeoutNotification          , @selector(umConnection_timeout:)},
        {uniMagDidConnectNotification       , @selector(umConnection_connected:)},
        {uniMagDidDisconnectNotification    , @selector(umConnection_disconnected:)},
        //
        {uniMagSwipeNotification,             @selector(umSwipe_Swipe)},
        {uniMagTimeoutSwipeNotification     , @selector(umSwipe_timeout:)},
        {uniMagDataProcessingNotification   , @selector(umDataProcessing:)},
        {uniMagInvalidSwipeNotification     , @selector(umSwipe_invalid:)},
        {uniMagDidReceiveDataNotification   , @selector(umSwipe_receivedSwipe:)},
        //
        {uniMagCmdSendingNotification       , @selector(umCommand_Sending)},
        {uniMagCommandTimeoutNotification   , @selector(umCommand_timeout:)},
        {uniMagDidReceiveCmdNotification    , @selector(umCommand_receivedResponse:)},
        {uniMagSystemMessageNotification    , @selector(umCommand_SystemMessage:)},
        
        {nil, nil},
    };
    
    //register or unregister
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    for (int i=0; noteAndSel[i].s != nil ;i++) {
        if (reg)
        [nc addObserver:self selector:noteAndSel[i].s name:noteAndSel[i].n object:nil];
        else
        [nc removeObserver:self name:noteAndSel[i].n object:nil];
    }
}

-(void)initUniMagObj:(CDVInvokedUrlCommand *)command{
    if (!uniReader) {
        [self umsdk_registerAllNotif: YES];
        uniReader = [[uniMag alloc] init];
    }
}
-(void)destroyUniMagObj:(CDVInvokedUrlCommand *)command{
    if (uniReader) {
        [self umsdk_registerAllNotif: NO];
        uniReader = NULL;
    }
}

-(void)register_stateChange_Notification:(CDVInvokedUrlCommand *)command{
    self.callbackId_StateChange = [[NSString alloc] initWithString:command.callbackId];
    LOGI(@"stateChange event: %@", self.callbackId_StateChange);
    //CDVPluginResult *result=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    //[self.commandDelegate sendPluginResult:result callbackId: self.callbackId_StateChange];
}


-(void)register_CMD_response_Notification:(CDVInvokedUrlCommand *)command{
    self.callbackId_CMD = [[NSString alloc] initWithString:command.callbackId];
    LOGI(@"CMD response event: %@", self.callbackId_CMD);
    //CDVPluginResult *result=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    //[self.commandDelegate sendPluginResult:result callbackId: self.callbackId_CMD];
}

-(void)register_card_data_Notification:(CDVInvokedUrlCommand *)command{
    self.callbackId_Card = [[NSString alloc] initWithString:command.callbackId];
    LOGI(@"Card data event: %@", self.callbackId_Card);
    //CDVPluginResult *result=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    //[self.commandDelegate sendPluginResult:result callbackId: self.callbackId_Card];
}

-(void)isReaderAttached:(CDVInvokedUrlCommand *)command{
    BOOL b = [uniReader isReaderAttached];
    LOGI(@"isReaderAttached, %d", b);
    CDVPluginResult *result=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool: b];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}
-(void)getConnectionStatus:(CDVInvokedUrlCommand *)command{
    BOOL b = [uniReader getConnectionStatus];
    LOGI(@"ConnectionStatus, %d", b);
    CDVPluginResult *result=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool: b];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}


-(void)getRunningTask:(CDVInvokedUrlCommand *)command{
    LOGI(@"RunningTask?");
    
    NSString *task=@"none";
    UmTask umtask =  [uniReader getRunningTask];
    switch (umtask) {
        case UMTASK_NONE     : task=@"none"          ;
            break;
        case UMTASK_CONNECT  : task=@"connect"       ;
            break;
        case UMTASK_SWIPE    : task=@"swipe"         ;
            break;
        case UMTASK_CMD      : task=@"sendCommand"   ;
            break;
        case UMTASK_FW_UPDATE: task=@"updateFirmware";
            break;
    }
    
    LOGI(@"Task? %@", task);
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: task];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)getVolumeLevel:(CDVInvokedUrlCommand *)command{
    double fv = [uniReader getVolumeLevel];
    LOGI(@"VolumeLevel? %f", fv);
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble: fv];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
-(void)getReaderType:(CDVInvokedUrlCommand *)command{
   
    UmReader rP = uniReader.readerType;
    LOGI(@"getReaderType? %D", rP);
    NSString *tp= UmReader_lookup(rP);
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: tp];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
-(void)setReaderType:(CDVInvokedUrlCommand *)command{
    LOGI(@"setReaderType?");
    
    UmReader tmp_readerType = UMREADER_UNKNOWN;
    if (0 != command.arguments.count) {
        NSString* sourceType = [command.arguments objectAtIndex:0];
        LOGI(@"v->>%@",sourceType);
        
        /*
         switch (c) {
         case UMREADER_UNKNOWN        : return @"Unknown";
         case UMREADER_UNIMAG_ORIGINAL: return @"UniMag (original)";
         case UMREADER_UNIMAG_PRO     : return @"UniMag Pro";
         case UMREADER_UNIMAG_II      : return @"UniMag II";
         case UMREADER_SHUTTLE        : return @"Shuttle";
         default: return @"<unknown code>";
         }
         */
        
        if ([sourceType isEqualToString: @"UniMag (original)"]){
            tmp_readerType = UMREADER_UNIMAG_ORIGINAL;
        }
        else if ([sourceType isEqualToString: @"UniMag Pro"]){
            tmp_readerType = UMREADER_UNIMAG_PRO;
        }
        else if ([sourceType isEqualToString: @"UniMag II"]){
            tmp_readerType = UMREADER_UNIMAG_II;
        }
        else if ([sourceType isEqualToString: @"Shuttle"]){
            tmp_readerType = UMREADER_SHUTTLE;
        }
        
    }
    LOGI(@"Type? %d", tmp_readerType);
    uniReader.readerType = tmp_readerType;
}

-(void)setAutoConnect:(CDVInvokedUrlCommand *)command{
    LOGI(@"setAutoConnect?");
    
    BOOL tmp = NO;
    if (0 != command.arguments.count) {
        NSString* sourceType = [command.arguments objectAtIndex:0];
        NSString *str = [NSString stringWithFormat:@"%@", sourceType];
        LOGI(@"v->>%@",str);
        if ([str isEqualToString: @"1"]){
            tmp = YES;
        }
    }
    LOGI(@"setAutoConnect? %d", tmp);
    [uniReader setAutoConnect:tmp];
    
}
-(void)setSwipeTimeoutDuration:(CDVInvokedUrlCommand *)command{
    LOGI(@"setSwipeTimeoutDuration?");
    
    int tmp = 20;
    if (0 != command.arguments.count) {
        NSNumber *sourceType = [command.arguments objectAtIndex:0];
        LOGI(@"v->>%@",sourceType);
        tmp = (int)sourceType.longValue;
    }
    bool b = [uniReader setSwipeTimeoutDuration: tmp];
    LOGI(@"set OK? %d", b);
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool: b];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

-(void)setAutoAdjustVolume:(CDVInvokedUrlCommand *)command{
    LOGI(@"setAutoAdjustVolume?");
    
    BOOL tmp = NO;
    if (0 != command.arguments.count) {
        NSString* sourceType = [command.arguments objectAtIndex:0];
        NSString *str = [NSString stringWithFormat:@"%@", sourceType];
        LOGI(@"v->>%@",str);
        if ([str isEqualToString: @"1"]){
            tmp = YES;
        }
    }
    LOGI(@"Auto Vol? %d", tmp);
    [uniReader setAutoAdjustVolume: tmp];
    
}
-(void)setDeferredActivateAudioSession:(CDVInvokedUrlCommand *)command{
    LOGI(@"setDeferredActivateAudioSession?");
    BOOL tmp = NO;
    if (0 != command.arguments.count) {
        NSString* sourceType = [command.arguments objectAtIndex:0];
        NSString *str = [NSString stringWithFormat:@"%@", sourceType];
        LOGI(@"v->>%@",str);
        if ([str isEqualToString: @"1"]){
            tmp = YES;
        }
    }
    LOGI(@"Deferred? %d", tmp);
    [uniReader setDeferredActivateAudioSession: tmp];
    
}

-(void)cancelTask:(CDVInvokedUrlCommand *)command{
    LOGI(@"cancelTask");
    [uniReader cancelTask];
    
}

//-1: can't get;
//0xXX: FlagByte;
-(void)getFlagByte:(CDVInvokedUrlCommand *)command{
    LOGI(@"getFlagByte?");
    NSData *dt = [uniReader getFlagByte];
    int tmp= -1;
    if (dt.length>0) {
        Byte * byT = (Byte*)dt.bytes;
        tmp = byT[0];
    }
    LOGI(@"FlagByte? %d", tmp);
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt: tmp];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
//connect area
-(void)startUniMag:(CDVInvokedUrlCommand *)command{
    LOGI(@"startUniMag?");
    BOOL tmp = NO;
    if (0 != command.arguments.count) {
        NSString* sourceType = [command.arguments objectAtIndex:0];
        NSString *str = [NSString stringWithFormat:@"%@", sourceType];
        LOGI(@"v->>%@",str);
        if ([str isEqualToString: @"1"]){
            tmp = YES;
        }
    }
    LOGI(@"start? %d", tmp);
    UmRet rt = [uniReader startUniMag: tmp];
    if (UMRET_SUCCESS!=rt) {
        NSString *st = UmRet_lookup(rt);
        LOGI(@"failed: %@", st);
        [self notif_StateChange: Notif_connect_fail : st];
    }
}
//swipe area
-(void)requestSwipe:(CDVInvokedUrlCommand *)command{
    LOGI(@"requestSwipe?");
    UmRet rt = [uniReader requestSwipe];
    if (UMRET_SUCCESS!=rt) {
        NSString *st = UmRet_lookup(rt);
        LOGI(@"failed: %@", st);
        [self notif_StateChange: Notif_swipe_fail : st];
    }
}

//CMD area
//For failed CMD, send failed Notification
-(void)checkCMDFail : (UmRet )rt : (CDVInvokedUrlCommand *)command{
    if (UMRET_SUCCESS!=rt) {
        NSString *st = UmRet_lookup(rt);
        LOGI(@"failed: %@", st);
        [self notif_StateChange: Notif_CMD_fail : st];
    }
}

-(void)sendCommandGetVersion:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD GetVersion?");
    UmRet rt = [uniReader sendCommandGetVersion];
    [self checkCMDFail: rt : command];
}
-(void)sendCommandGetSettings:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD GetSettings?");
    UmRet rt = [uniReader sendCommandGetSettings];
    [self checkCMDFail: rt : command];
    
}
-(void)sendCommandEnableTDES:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD EnableTDES?");
    UmRet rt = [uniReader sendCommandEnableTDES];
    [self checkCMDFail: rt : command];

}
-(void)sendCommandEnableAES:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD EnableAES?");
    UmRet rt = [uniReader sendCommandEnableAES];
    [self checkCMDFail: rt : command];
    
}
-(void)sendCommandDefaultGeneralSettings:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD DefaultGeneralSettings?");
    UmRet rt = [uniReader sendCommandDefaultGeneralSettings];
    [self checkCMDFail: rt : command];
    
}
-(void)sendCommandGetSerialNumber:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD GetSerialNumber?");
    UmRet rt = [uniReader sendCommandGetSerialNumber];
    [self checkCMDFail: rt : command];
    
}
-(void)sendCommandGetNextKSN:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD GetNextKSN?");
    UmRet rt = [uniReader sendCommandGetNextKSN];
    [self checkCMDFail: rt : command];
    
}
-(void)sendCommandEnableErrNotification:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD EnableErrNotification?");
    UmRet rt = [uniReader sendCommandEnableErrNotification];
    [self checkCMDFail: rt : command];
    
}
-(void)sendCommandDisableErrNotification:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD DisableErrNotification?");
    UmRet rt = [uniReader sendCommandDisableErrNotification];
    [self checkCMDFail: rt : command];
    
}
-(void)sendCommandEnableExpDate:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD EnableExpDate?");
    UmRet rt = [uniReader sendCommandEnableExpDate];
    [self checkCMDFail: rt : command];
    
}
-(void)sendCommandDisableExpDate:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD DisableExpDate?");
    UmRet rt = [uniReader sendCommandDisableExpDate];
    [self checkCMDFail: rt : command];
    
}
-(void)sendCommandEnableForceEncryption:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD EnableForceEncryption?");
    UmRet rt = [uniReader sendCommandEnableForceEncryption];
    [self checkCMDFail: rt : command];
    
}
-(void)sendCommandDisableForceEncryption:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD DisableForceEncryption?");
    UmRet rt = [uniReader sendCommandDisableForceEncryption];
    [self checkCMDFail: rt : command];
    
}

-(void)sendCommandSetPrePAN:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD SetPrePAN?");
    if (0 != command.arguments.count) {
        NSNumber *sourceType = [command.arguments objectAtIndex:0];
        LOGI(@"v->>%@",sourceType);
        int tmp = (int)sourceType.longValue;
        LOGI(@"PrePAN? %d", tmp);
        UmRet rt = [uniReader sendCommandSetPrePAN: tmp];
        [self checkCMDFail: rt : command];
    }
    
}

-(void)sendCommandClearBuffer:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD ClearBuffer?");
    UmRet rt = [uniReader sendCommandClearBuffer];
    [self checkCMDFail: rt : command];
    
}
-(void)sendCommandResetBaudRate:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD ResetBaudRate?");
    UmRet rt = [uniReader sendCommandResetBaudRate];
    [self checkCMDFail: rt : command];
    
}

static int char2hex(unichar c) {
    switch (c) {
        case '0' ... '9': return c - '0';
        case 'a' ... 'f': return c - 'a' + 10;
        case 'A' ... 'F': return c - 'A' + 10;
        default: return -1;
    }
}

static NSData* unhexlify(NSString* hexStr) {
    if (hexStr == nil || hexStr.length%2 != 0)
        return nil;
    
    NSMutableData* ret = [NSMutableData data];
    int nibH, nibL;
    Byte b;
    for (int i=0; i<hexStr.length; i+=2) {
        nibH = char2hex([hexStr characterAtIndex:i]);
        nibL = char2hex([hexStr characterAtIndex:i+1]);
        if (nibH < 0 || nibL <0)
            return nil;
        b = (nibH<<4) + nibL;
        [ret appendBytes: &b length:1];
    }
    return ret;
}

-(void)sendCommandCustom:(CDVInvokedUrlCommand *)command{
    LOGI(@"CMD CustomCMD?");
    if (0 != command.arguments.count) {
        NSString *source = [command.arguments objectAtIndex:0];
        LOGI(@"v->>%@",source);
        NSData* dt = unhexlify(source);
        LOGI(@"v->>%@",dt.description);
        UmRet rt = [uniReader sendCommandCustom: dt];
        [self checkCMDFail: rt : command];
    }
    
}


@end
