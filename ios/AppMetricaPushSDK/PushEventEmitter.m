#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(PushEventEmitter, RCTEventEmitter)
RCT_EXTERN_METHOD(addListener:(NSString *)eventName)
RCT_EXTERN_METHOD(removeListeners:(double)count)
@end
