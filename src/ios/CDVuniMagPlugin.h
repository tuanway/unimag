
#import <Cordova/CDV.h>

@interface CDVuniMagPlugin : CDVPlugin

//common area
-(void)enableLogging:(CDVInvokedUrlCommand *)command;
-(void)getSDKVersion:(CDVInvokedUrlCommand *)command;

-(void)register_stateChange_Notification:(CDVInvokedUrlCommand *)command;
-(void)register_CMD_response_Notification:(CDVInvokedUrlCommand *)command;
-(void)register_card_data_Notification:(CDVInvokedUrlCommand *)command;

-(void)initUniMagObj:(CDVInvokedUrlCommand *)command;
-(void)destroyUniMagObj:(CDVInvokedUrlCommand *)command;

-(void)isReaderAttached:(CDVInvokedUrlCommand *)command;
-(void)getConnectionStatus:(CDVInvokedUrlCommand *)command;
-(void)getRunningTask:(CDVInvokedUrlCommand *)command;
-(void)getVolumeLevel:(CDVInvokedUrlCommand *)command;
-(void)getReaderType:(CDVInvokedUrlCommand *)command;
-(void)setReaderType:(CDVInvokedUrlCommand *)command;
-(void)setAutoConnect:(CDVInvokedUrlCommand *)command;
-(void)setSwipeTimeoutDuration:(CDVInvokedUrlCommand *)command;
-(void)setAutoAdjustVolume:(CDVInvokedUrlCommand *)command;
-(void)setDeferredActivateAudioSession:(CDVInvokedUrlCommand *)command;
-(void)cancelTask:(CDVInvokedUrlCommand *)command;
-(void)getFlagByte:(CDVInvokedUrlCommand *)command;
//connect area
-(void)startUniMag:(CDVInvokedUrlCommand *)command;
//swipe area
-(void)requestSwipe:(CDVInvokedUrlCommand *)command;

//CMD area
-(void)sendCommandGetVersion:(CDVInvokedUrlCommand *)command;
-(void)sendCommandGetSettings:(CDVInvokedUrlCommand *)command;
-(void)sendCommandEnableTDES:(CDVInvokedUrlCommand *)command;
-(void)sendCommandEnableAES:(CDVInvokedUrlCommand *)command;
-(void)sendCommandDefaultGeneralSettings:(CDVInvokedUrlCommand *)command;
-(void)sendCommandGetSerialNumber:(CDVInvokedUrlCommand *)command;
-(void)sendCommandGetNextKSN:(CDVInvokedUrlCommand *)command;
-(void)sendCommandEnableErrNotification:(CDVInvokedUrlCommand *)command;
-(void)sendCommandDisableErrNotification:(CDVInvokedUrlCommand *)command;

-(void)sendCommandEnableExpDate:(CDVInvokedUrlCommand *)command;
-(void)sendCommandDisableExpDate:(CDVInvokedUrlCommand *)command;
-(void)sendCommandEnableForceEncryption:(CDVInvokedUrlCommand *)command;
-(void)sendCommandDisableForceEncryption:(CDVInvokedUrlCommand *)command;

-(void)sendCommandSetPrePAN:(CDVInvokedUrlCommand *)command;
-(void)sendCommandClearBuffer:(CDVInvokedUrlCommand *)command;
-(void)sendCommandResetBaudRate:(CDVInvokedUrlCommand *)command;
-(void)sendCommandCustom:(CDVInvokedUrlCommand *)command;

@end
