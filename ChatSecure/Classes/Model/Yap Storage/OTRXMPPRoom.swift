//
//  OTRXMPPRoom.swift
//  ChatSecure
//
//  Created by David Chiles on 10/7/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import UIKit
import YapDatabase.YapDatabaseRelationship

public class OTRXMPPRoom: OTRYapDatabaseObject {
    
    public var accountUniqueId:String?
    public var ownJID:String?
    public var jid:String?
    public var joined = false
    public var messageText:String?
    public var lastRoomMessageId:String?
    public var subject:String?
    override public var uniqueId:String {
        get {
            if let account = self.accountUniqueId {
                if let jid = self.jid {
                    return OTRXMPPRoom.createUniqueId(account, jid: jid)
                }
            }
            return super.uniqueId
        }
    }
    
    public class func createUniqueId(accountId:String, jid:String) -> String {
        return accountId + jid
    }
}

extension OTRXMPPRoom:OTRThreadOwner {
    public func threadName() -> String {
        return self.subject ?? self.jid ?? ""
    }
    
    public func threadIdentifier() -> String {
        return self.uniqueId
    }
    
    public func threadCollection() -> String {
        return OTRXMPPRoom.collection()
    }
    
    public func threadAccountIdentifier() -> String {
        return self.accountUniqueId ?? ""
    }
    
    public func setCurrentMessageText(text: String?) {
        self.messageText = text
    }
    
    public func currentMessageText() -> String? {
        return self.messageText
    }
    
    public func avatarImage() -> UIImage {
        return OTRImages.avatarImageWithUniqueIdentifier(self.uniqueId, avatarData: nil, displayName: nil, username: self.threadName())
    }
    
    public func currentStatus() -> OTRThreadStatus {
        switch self.joined {
        case true:
            return .Available
        default:
            return .Offline
        }
    }
    
    public func lastMessageWithTransaction(transaction: YapDatabaseReadTransaction) -> OTRMessageProtocol? {
        
        guard let viewTransaction = transaction.ext(OTRChatDatabaseViewExtensionName) as? YapDatabaseViewTransaction else {
            return nil
        }
        
        let numberOfItems = viewTransaction.numberOfItemsInGroup(self.threadIdentifier())
        
        if numberOfItems == 0 {
            return nil
        }
        
        guard let message = viewTransaction.objectAtIndex(numberOfItems-1, inGroup: self.threadIdentifier()) as? OTRMessageProtocol else {
            return nil
        }
        return message
    }
    
    public func numberOfUnreadMessagesWithTransaction(transaction: YapDatabaseReadTransaction) -> UInt {
        guard let indexTransaction = transaction.ext(OTRMessagesSecondaryIndex) as? YapDatabaseSecondaryIndexTransaction else {
            return 0
        }
        let queryString = "Where \(OTRYapDatabaseMessageThreadIdSecondaryIndexColumnName) == ? AND \(OTRYapDatabaseUnreadMessageSecondaryIndexColumnName) == 0"
        let query = YapDatabaseQuery(string: queryString, parameters: [self.uniqueId])
        var count:UInt = 0
        let success = indexTransaction.getNumberOfRows(&count, matchingQuery: query)
        if (!success) {
            NSLog("Query error for OTRXMPPRoom numberOfUnreadMessagesWithTransaction")
        }
        return count
    }
    
    public func isGroupThread() -> Bool {
        return true
    }
}
