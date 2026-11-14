#import "RCTNativeShopBench.h"
#import <os/log.h>

@implementation RCTNativeShopBench

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeShopBenchSpecJSI>(params);
}

- (NSString *)getApiUrl
{
  NSString *value = [[NSProcessInfo processInfo] environment][@"SHOP_API_URL"];
  return value ?: @"";
}

- (void)markHomeReady
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    os_log(OS_LOG_DEFAULT, "SHOPBENCH home_ready");
  });
}

+ (NSString *)moduleName
{
  return @"NativeShopBench";
}

@end
