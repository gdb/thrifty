namespace rb IncludeThriftyTest

include "user_service.thrift"

service IncludingService extends user_service.UserStorage {
}
