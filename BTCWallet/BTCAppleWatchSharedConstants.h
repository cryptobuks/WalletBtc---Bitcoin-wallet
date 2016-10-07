//
//  Created by Admin on 9/8/16.
//

#import "BTCAppleWatchData.h"

#define AW_SESSION_RESPONSE_KEY @"AW_SESSION_RESPONSE_KEY"
#define AW_SESSION_REQUEST_TYPE @"AW_SESSION_REQUEST_TYPE"
#define AW_SESSION_QR_CODE_BITS_KEY @"AW_QR_CODE_BITS_KEY"

#define AW_SESSION_REQUEST_DATA_TYPE_KEY @"AW_SESSION_REQUEST_DATA_TYPE_KEY"

#define AW_APPLICATION_CONTEXT_KEY @"AW_APPLICATION_CONTEXT_KEY"
#define AW_QR_CODE_BITS_KEY @"AW_QR_CODE_BITS_KEY"

#define AW_PHONE_NOTIFICATION_KEY @"AW_PHONE_NOTIFICATION_KEY"
#define AW_PHONE_NOTIFICATION_TYPE_KEY @"AW_PHONE_NOTIFICATION_TYPE_KEY"

typedef enum {
    AWSessionRquestDataTypeApplicationContextData,
    AWSessionRquestDataTypeQRCodeBits
} AWSessionRquestDataType;

typedef enum {
    AWSessionRquestTypeDataUpdateNotification,
    AWSessionRquestTypeFetchData,
    AWSessionRquestTypeQRCodeBits
} AWSessionRquestType;

typedef enum {
    AWPhoneNotificationTypeTxReceive
} AWPhoneNotificationType;
