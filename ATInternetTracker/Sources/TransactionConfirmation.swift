/*
 This SDK is licensed under the MIT license (MIT)
 Copyright (c) 2015- Applied Technologies Internet SAS (registration number B 403 261 258 - Trade and Companies Register of Bordeaux – France)
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

//
//  TransactionConfirmation.swift
//  Tracker
//
import Foundation

/// Wrapper class for TransactionConfirmation event tracking (SalesInsight)
public class TransactionConfirmation: Event {
    
    /// Products list
    @objc public lazy var products : [ECommerceProduct] = [ECommerceProduct]()
    
    /// Cart property
    @objc public lazy var cart : ECommerceCart = ECommerceCart()
    
    /// Transaction property
    @objc public lazy var transaction : ECommerceTransaction = ECommerceTransaction()
    
    /// Shipping property
    @objc public lazy var shipping : ECommerceShipping = ECommerceShipping()
    
    /// Payment property
    @objc public lazy var payment : ECommercePayment = ECommercePayment()
    
    override var data: [String : Any] {
        get {
            if !cart.properties.isEmpty {
                _data["cart"] = cart.properties
            }
            if !payment.properties.isEmpty {
                _data["payment"] = payment.properties
            }
            if !shipping.properties.isEmpty {
                _data["shipping"] = shipping.properties
            }
            if !transaction.properties.isEmpty {
                _data["transaction"] = transaction.properties
            }
            return super.data
        }
        set {
            _data = newValue
        }
    }
    
    init() {
        super.init(name: "transaction.confirmation")
    }
    
    @objc public func setProducts(products: [ECommerceProduct]) {
        self.products = products
    }
    
    override func getAdditionalEvents() -> [Event] {
        /// SALES INSIGHTS
        var generatedEvents = super.getAdditionalEvents()
        
        for p in products {
            let pp = ProductPurchased()
            _ = pp.cart.set(key: "id", value: String(describing: cart.get(key: "id") ?? ""))
            _ = pp.transaction.set(key: "id", value: String(describing: transaction.get(key: "id") ?? ""))
            if !p.properties.isEmpty {
                _ = pp.product.setProps(obj: p.properties)
            }
            generatedEvents.append(pp)
        }
        
        return generatedEvents
    }
}

/// Wrapper class to manage TransactionConfirmation event instances
public class TransactionConfirmations : EventsHelper {
    
    private let tracker : Tracker
    
    init(events: Events, tracker: Tracker) {
        self.tracker = tracker
        super.init(events: events)
    }
    
    /// Add transaction confirmation event tracking
    ///
    /// - Returns: TransactionConfirmation instance
    @objc public func add() -> TransactionConfirmation {
        let tc = TransactionConfirmation()
        _ = events.add(event: tc)
        return tc
    }
    
    /// Add transaction confirmation event tracking
    ///
    /// - Parameter screenLabel: a screen label
    /// - Returns: TransactionConfirmation instance
    @available(*, deprecated, message: "Use 'add()' method instead")
    @objc public func add(screenLabel: String?) -> TransactionConfirmation {
        return add()
    }
    
    /// Add transaction confirmation event tracking
    ///
    /// - Parameter screen: a screen instance
    /// - Returns: TransactionConfirmation instance
    @available(*, deprecated, message: "Use 'add()' method instead")
    @objc public func add(screen: Screen?) -> TransactionConfirmation {
        return add()
    }
}
