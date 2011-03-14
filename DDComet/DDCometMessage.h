
#import <Foundation/Foundation.h>


@interface DDCometMessage : NSObject {
}

@property (nonatomic, retain) NSString *channel;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSString *minimumVersion;
@property (nonatomic, retain) NSArray *supportedConnectionTypes;
@property (nonatomic, retain) NSString *clientID;
@property (nonatomic, retain) NSDictionary *advice;
@property (nonatomic, retain) NSString *connectionType;
@property (nonatomic, retain) NSString *ID;
@property (nonatomic, retain) NSDate *timestamp;
@property (nonatomic, retain) id data;
@property (nonatomic, retain) NSNumber *successful;
@property (nonatomic, retain) NSString *subscription;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) id ext;

+ (DDCometMessage *)messageWithChannel:(NSString *)channel;

@end

@interface DDCometMessage (JSON)

+ (DDCometMessage *)messageWithJson:(NSDictionary *)jsonData;
- (NSDictionary *)proxyForJson;

@end
