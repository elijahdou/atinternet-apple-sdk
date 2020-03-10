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
//  AVMedia.swift
//  Tracker
//
import Foundation

public class AVMedia: RequiredPropertiesDataObject {
    
    fileprivate let MinHeartbeatDuration: Int = 5
    fileprivate let MinBufferHeartbeatDuration: Int = 1
    
    fileprivate let avSynchronizer = DispatchQueue(label: "AVSynchronizer")

    var heartbeatTimer : Timer? = nil
    
    var sessionId: String = Foundation.UUID().uuidString
    var previousEvent: String = ""
    var previousCursorPositionMillis: Int = 0
    var currentCursorPositionMillis: Int = 0
    var eventDurationMillis: Int = 0
    var sessionDurationMillis: Int = 0
    var startSessionTimeMillis: Int = 0
    var bufferTimeMillis: Int = 0
    var heartbeatDurations: [Int:Int] = [Int:Int]()
    var bufferHeartbeatDurations: [Int:Int] = [Int:Int]()
    
    var isPlaying: Bool = false
    var isPlaybackStartAlreadyCalled: Bool = false
    var autoHeartbeat: Bool = false
    var autoBufferHeartbeat: Bool = false
    
    var events : Events?
    
    init(events: Events?) {
        self.events = events
        super.init()
    }
    
    convenience init(events: Events?, heartbeat: Int, bufferHeartbeat: Int) {
        self.init(events: events)
        _ = self.setHeartbeat(heartbeat: heartbeat)
        _ = self.setBufferHeartbeat(bufferHeartbeat: bufferHeartbeat)
    }
    
    convenience init(events: Events?, heartbeat: [Int:Int], bufferHeartbeat: [Int:Int]) {
        self.init(events: events)
        _ = self.setHeartbeat(heartbeat: heartbeat)
        _ = self.setBufferHeartbeat(bufferHeartbeat: bufferHeartbeat)
    }
    
    func setHeartbeat(heartbeat: Int) -> AVMedia {
        return setHeartbeat(heartbeat: [0:heartbeat])
    }
    
    func setHeartbeat(heartbeat: [Int: Int]) -> AVMedia {
        guard heartbeat.count > 0 else { return self }
        self.avSynchronizer.sync {
            self.autoHeartbeat = true
            self.heartbeatDurations.removeAll()
            for (k,v) in heartbeat {
                if v < MinHeartbeatDuration {
                    self.heartbeatDurations[k] = MinHeartbeatDuration
                } else {
                    self.heartbeatDurations[k] = v
                }
            }
            if !self.heartbeatDurations.keys.contains(0) {
               self.heartbeatDurations[0] = MinHeartbeatDuration
            }
        }
        return self
    }
    
    func setBufferHeartbeat(bufferHeartbeat: Int) -> AVMedia {
        return setBufferHeartbeat(bufferHeartbeat: [0:bufferHeartbeat])
    }
    
    func setBufferHeartbeat(bufferHeartbeat: [Int: Int]) -> AVMedia {
        guard bufferHeartbeat.count > 0 else { return self }
        self.avSynchronizer.sync {
            self.autoBufferHeartbeat = true
            self.bufferHeartbeatDurations.removeAll()
            for (k,v) in bufferHeartbeat {
                if v < MinBufferHeartbeatDuration {
                    self.bufferHeartbeatDurations[k] = MinBufferHeartbeatDuration
                } else {
                    self.bufferHeartbeatDurations[k] = v
                }
            }
            if !self.bufferHeartbeatDurations.keys.contains(0) {
               self.bufferHeartbeatDurations[0] = MinBufferHeartbeatDuration
            }
        }
        return self
    }
    
    @objc public func track(action: String, options: [String : Any], extraProps: [String : Any]?) {
        self.avSynchronizer.sync {
            switch (action){
            case "av.heartbeat":
                heartbeat(extraProps: extraProps)
            case "av.buffer.heartbeat":
                bufferHeartbeat(extraProps: extraProps)
            case "av.rebuffer.heartbeat":
                rebufferHeartbeat(extraProps: extraProps)
            case "av.play":
                var avPosition = 0
                if let optAvPosition = options["av_position"] as? Int {
                    avPosition = optAvPosition
                }
                play(cursorPosition: avPosition, extraProps: extraProps)
            case "av.buffer.start":
                var avPosition = 0
                if let optAvPosition = options["av_position"] as? Int {
                    avPosition = optAvPosition
                }
                bufferStart(cursorPosition: avPosition, extraProps: extraProps)
            case "av.start":
                var avPosition = 0
                if let optAvPosition = options["av_position"] as? Int {
                    avPosition = optAvPosition
                }
                playbackStart(cursorPosition: avPosition, extraProps: extraProps)
            case "av.resume":
                var avPosition = 0
                if let optAvPosition = options["av_position"] as? Int {
                    avPosition = optAvPosition
                }
                playbackResumed(cursorPosition: avPosition, extraProps: extraProps)
            case "av.pause":
                var avPosition = 0
                if let optAvPosition = options["av_position"] as? Int {
                    avPosition = optAvPosition
                }
                playbackPaused(cursorPosition: avPosition, extraProps: extraProps)
            case "av.stop":
                var avPosition = 0
                if let optAvPosition = options["av_position"] as? Int {
                    avPosition = optAvPosition
                }
                playbackStopped(cursorPosition: avPosition, extraProps: extraProps)
            case "av.backward":
                var avPreviousPosition = 0
                var avPosition = 0
                if let optAvPreviousPosition = options["av_previous_position"] as? Int {
                    avPreviousPosition = optAvPreviousPosition
                }
                if let optAvPosition = options["av_position"] as? Int {
                    avPosition = optAvPosition
                }
                seekBackward(oldCursorPosition: avPreviousPosition, newCursorPosition: avPosition, extraProps: extraProps)
            case "av.forward":
                var avPreviousPosition = 0
                var avPosition = 0
                if let optAvPreviousPosition = options["av_previous_position"] as? Int {
                    avPreviousPosition = optAvPreviousPosition
                }
                if let optAvPosition = options["av_position"] as? Int {
                    avPosition = optAvPosition
                }
                seekForward(oldCursorPosition: avPreviousPosition, newCursorPosition: avPosition, extraProps: extraProps)
            case "av.seek.start":
                var avPreviousPosition = 0
                if let optAvPreviousPosition = options["av_previous_position"] as? Int {
                    avPreviousPosition = optAvPreviousPosition
                }
                seekStart(oldCursorPosition: avPreviousPosition, extraProps: extraProps)
            case "av.error":
                var avError = ""
                if let optAvError = options["av_player_error"] as? String {
                    avError = optAvError
                }
                error(message: avError, extraProps: extraProps)
            default:
                sendEvents(events: self.createEvent(name: action, withOptions: false, extraProps: extraProps))
            }
        }
    }
    
    @objc public func heartbeat(extraProps: [String : Any]?) {
        self.avSynchronizer.sync {
            self.startSessionTimeMillis = self.startSessionTimeMillis == 0 ? Int(Date().timeIntervalSince1970 * 1000) : self.startSessionTimeMillis
            
            if self.isPlaying {
                self.updateDuration()
                
                self.previousCursorPositionMillis = self.currentCursorPositionMillis
                self.currentCursorPositionMillis += self.eventDurationMillis
                
                stopHeartbeatTimer()
                
                let diffMin = (Int(Date().timeIntervalSince1970 * 1000) - self.startSessionTimeMillis) / 60000
                if let duration = self.heartbeatDurations[diffMin] {
                    heartbeatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(duration), target: self, selector: #selector(self.heartbeat), userInfo: nil, repeats: false)
                } else {
                    heartbeatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(MinHeartbeatDuration), target: self, selector: #selector(self.heartbeat), userInfo: nil, repeats: false)
                }
                sendEvents(events: self.createEvent(name: "av.heartbeat", withOptions: true, extraProps: extraProps))
            }
        }
    }
    
    @objc public func bufferHeartbeat(extraProps: [String : Any]?) {
        self.avSynchronizer.sync {
            self.startSessionTimeMillis = self.startSessionTimeMillis == 0 ? Int(Date().timeIntervalSince1970 * 1000) : self.startSessionTimeMillis
            
            if !self.isPlaying {
                self.updateDuration()
                
                stopHeartbeatTimer()
                
                self.bufferTimeMillis = self.bufferTimeMillis == 0 ? Int(Date().timeIntervalSince1970 * 1000) : self.bufferTimeMillis
                let diffMin = (Int(Date().timeIntervalSince1970 * 1000) - self.bufferTimeMillis) / 60000
                if let duration = self.bufferHeartbeatDurations[diffMin] {
                    heartbeatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(duration), target: self, selector: #selector(self.bufferHeartbeat), userInfo: nil, repeats: false)
                } else {
                    heartbeatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(MinBufferHeartbeatDuration), target: self, selector: #selector(self.bufferHeartbeat), userInfo: nil, repeats: false)
                }
                sendEvents(events: self.createEvent(name: "av.buffer.heartbeat", withOptions: true, extraProps: extraProps))
            }
        }
    }
    
    @objc public func rebufferHeartbeat(extraProps: [String : Any]?) {
        self.avSynchronizer.sync {
            self.startSessionTimeMillis = self.startSessionTimeMillis == 0 ? Int(Date().timeIntervalSince1970 * 1000) : self.startSessionTimeMillis
            
            if self.isPlaying {
                self.updateDuration()
                
                self.previousCursorPositionMillis = self.currentCursorPositionMillis
                
                stopHeartbeatTimer()
                
                self.bufferTimeMillis = self.bufferTimeMillis == 0 ? Int(Date().timeIntervalSince1970 * 1000) : self.bufferTimeMillis
                let diffMin = (Int(Date().timeIntervalSince1970 * 1000) - self.bufferTimeMillis) / 60000
                if let duration = self.bufferHeartbeatDurations[diffMin] {
                    heartbeatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(duration), target: self, selector: #selector(self.rebufferHeartbeat), userInfo: nil, repeats: false)
                } else {
                    heartbeatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(MinBufferHeartbeatDuration), target: self, selector: #selector(self.rebufferHeartbeat), userInfo: nil, repeats: false)
                }
                sendEvents(events: self.createEvent(name: "av.rebuffer.heartbeat", withOptions: true, extraProps: extraProps))
            }
        }
    }
    
    @objc public func play(cursorPosition: Int, extraProps: [String : Any]?) {
        self.avSynchronizer.sync {
            self.startSessionTimeMillis = self.startSessionTimeMillis == 0 ? Int(Date().timeIntervalSince1970 * 1000) : self.startSessionTimeMillis
            
            self.eventDurationMillis = 0
            
            self.previousCursorPositionMillis = cursorPosition
            self.currentCursorPositionMillis = cursorPosition
            
            self.isPlaying = false
            
            stopHeartbeatTimer()
            
            sendEvents(events: self.createEvent(name: "av.play", withOptions: true, extraProps: extraProps))
        }
    }
    
    @objc public func bufferStart(cursorPosition: Int, extraProps: [String : Any]?) {
        self.avSynchronizer.sync {
            self.startSessionTimeMillis = self.startSessionTimeMillis == 0 ? Int(Date().timeIntervalSince1970 * 1000) : self.startSessionTimeMillis
            
            self.updateDuration()
            self.previousCursorPositionMillis = self.currentCursorPositionMillis
            self.currentCursorPositionMillis = cursorPosition
            
            self.bufferTimeMillis = Int(Date().timeIntervalSince1970 * 1000)
            
            stopHeartbeatTimer()
            
            if self.isPlaying {
                heartbeatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(MinBufferHeartbeatDuration), target: self, selector: #selector(self.rebufferHeartbeat), userInfo: nil, repeats: false)
                sendEvents(events: createEvent(name: "av.rebuffer.start", withOptions: true, extraProps: extraProps))
            } else {
                heartbeatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(MinBufferHeartbeatDuration), target: self, selector: #selector(self.bufferHeartbeat), userInfo: nil, repeats: false)
                sendEvents(events: createEvent(name: "av.buffer.start", withOptions: true, extraProps: extraProps))
            }
        }
    }
    
    @objc public func playbackStart(cursorPosition: Int, extraProps: [String : Any]?) {
        self.avSynchronizer.sync {
            self.startSessionTimeMillis = self.startSessionTimeMillis == 0 ? Int(Date().timeIntervalSince1970 * 1000) : self.startSessionTimeMillis
            
            self.updateDuration()
            self.previousCursorPositionMillis = cursorPosition
            self.currentCursorPositionMillis = cursorPosition
            
            self.isPlaying = true
            
            stopHeartbeatTimer()
            heartbeatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(MinHeartbeatDuration), target: self, selector: #selector(self.heartbeat), userInfo: nil, repeats: false)
            sendEvents(events: createEvent(name: "av.start", withOptions: true, extraProps: extraProps))
        }
    }
    
    @objc public func playbackResumed(cursorPosition: Int, extraProps: [String : Any]?) {
        self.avSynchronizer.sync {
            self.startSessionTimeMillis = self.startSessionTimeMillis == 0 ? Int(Date().timeIntervalSince1970 * 1000) : self.startSessionTimeMillis
            
            self.updateDuration()
            self.previousCursorPositionMillis = self.currentCursorPositionMillis
            self.currentCursorPositionMillis = cursorPosition
            
            self.isPlaying = true
            
            stopHeartbeatTimer()
            heartbeatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(MinHeartbeatDuration), target: self, selector: #selector(self.heartbeat), userInfo: nil, repeats: false)
            sendEvents(events: createEvent(name: "av.resume", withOptions: true, extraProps: extraProps))
        }
    }
    
    @objc public func playbackPaused(cursorPosition: Int, extraProps: [String : Any]?) {
        self.avSynchronizer.sync {
            self.startSessionTimeMillis = self.startSessionTimeMillis == 0 ? Int(Date().timeIntervalSince1970 * 1000) : self.startSessionTimeMillis
            
            self.updateDuration()
            self.previousCursorPositionMillis = self.currentCursorPositionMillis
            self.currentCursorPositionMillis = cursorPosition
            
            self.isPlaying = false
            
            stopHeartbeatTimer()
            sendEvents(events: createEvent(name: "av.pause", withOptions: true, extraProps: extraProps))
        }
    }
    
    @objc public func playbackStopped(cursorPosition: Int, extraProps: [String : Any]?) {
        self.avSynchronizer.sync {
            self.startSessionTimeMillis = self.startSessionTimeMillis == 0 ? Int(Date().timeIntervalSince1970 * 1000) : self.startSessionTimeMillis
            
            self.updateDuration()
            self.previousCursorPositionMillis = self.currentCursorPositionMillis
            self.currentCursorPositionMillis = cursorPosition
            
            self.isPlaying = false
            
            stopHeartbeatTimer()
            self.startSessionTimeMillis = 0
            self.sessionDurationMillis = 0
            self.bufferTimeMillis = 0
            
            sendEvents(events: createEvent(name: "av.stop", withOptions: true, extraProps: extraProps))
            
            self.resetState()
        }
    }
    
    @objc public func seek(oldCursorPosition: Int, newCursorPosition: Int, extraProps: [String : Any]?) {
        if oldCursorPosition > newCursorPosition {
            self.seekBackward(oldCursorPosition: oldCursorPosition, newCursorPosition: newCursorPosition, extraProps: extraProps)
        } else {
            self.seekForward(oldCursorPosition: oldCursorPosition, newCursorPosition: newCursorPosition, extraProps: extraProps)
        }
    }
    
    @objc public func seekBackward(oldCursorPosition: Int, newCursorPosition: Int, extraProps: [String : Any]?) {
        self.avSynchronizer.sync {
            self.processSeek(seekDirection: "backward", oldCursorPosition: oldCursorPosition, newCursorPosition: newCursorPosition, extraProps: extraProps)
        }
    }
    
    @objc public func seekForward(oldCursorPosition: Int, newCursorPosition: Int, extraProps: [String : Any]?) {
        self.avSynchronizer.sync {
            self.processSeek(seekDirection: "forward", oldCursorPosition: oldCursorPosition, newCursorPosition: newCursorPosition, extraProps: extraProps)
        }
    }
    
    @objc public func seekStart(oldCursorPosition: Int, extraProps: [String : Any]?) {
        self.avSynchronizer.sync {
            if self.isPlaying && self.startSessionTimeMillis == 0 {
                self.startSessionTimeMillis = Int(Date().timeIntervalSince1970 * 1000)
            }
            
            self.previousCursorPositionMillis = self.currentCursorPositionMillis
            self.currentCursorPositionMillis = oldCursorPosition
            
            if isPlaying {
                self.updateDuration()
            } else {
                self.eventDurationMillis = 0
            }
            
            sendEvents(events: self.createEvent(name: "av.seek.start", withOptions: true, extraProps: extraProps))
        }
    }
    
    @objc public func adClick(extraProps: [String : Any]?) {
       self.avSynchronizer.sync {
           sendEvents(events: self.createEvent(name: "av.ad.click", withOptions: false, extraProps: extraProps))
       }
    }
    
    @objc public func adSkip(extraProps: [String : Any]?) {
       self.avSynchronizer.sync {
           sendEvents(events: self.createEvent(name: "av.ad.skip", withOptions: false, extraProps: extraProps))
       }
    }
    
    @objc public func error(message: String, extraProps: [String : Any]?) {
       self.avSynchronizer.sync {
            _ = self.player.set(key: "error", value: message)
            sendEvents(events: self.createEvent(name: "av.error", withOptions: false, extraProps: extraProps))
       }
    }
    
    @objc public func display(extraProps: [String : Any]?) {
       self.avSynchronizer.sync {
           sendEvents(events: self.createEvent(name: "av.display", withOptions: false, extraProps: extraProps))
       }
    }
    
    @objc public func close(extraProps: [String : Any]?) {
       self.avSynchronizer.sync {
           sendEvents(events: self.createEvent(name: "av.close", withOptions: false, extraProps: extraProps))
       }
    }
    
    @objc public func volume(extraProps: [String : Any]?) {
       self.avSynchronizer.sync {
           sendEvents(events: self.createEvent(name: "av.volume", withOptions: false, extraProps: extraProps))
       }
    }
    
    @objc public func subtitleOn(extraProps: [String : Any]?) {
       self.avSynchronizer.sync {
           sendEvents(events: self.createEvent(name: "av.subtitle.on", withOptions: false, extraProps: extraProps))
       }
    }
    
    @objc public func subtitleOff(extraProps: [String : Any]?) {
       self.avSynchronizer.sync {
           sendEvents(events: self.createEvent(name: "av.subtitle.off", withOptions: false, extraProps: extraProps))
       }
    }
    
    @objc public func fullscreenOn(extraProps: [String : Any]?) {
       self.avSynchronizer.sync {
           sendEvents(events: self.createEvent(name: "av.fullscreen.on", withOptions: false, extraProps: extraProps))
       }
    }
    
    @objc public func fullscreenOff(extraProps: [String : Any]?) {
       self.avSynchronizer.sync {
           sendEvents(events: self.createEvent(name: "av.fullscreen.off", withOptions: false, extraProps: extraProps))
       }
    }
    
    @objc public func quality(extraProps: [String : Any]?) {
       self.avSynchronizer.sync {
           sendEvents(events: self.createEvent(name: "av.quality", withOptions: false, extraProps: extraProps))
       }
    }
    
    @objc public func speed(extraProps: [String : Any]?) {
       self.avSynchronizer.sync {
           sendEvents(events: self.createEvent(name: "av.speed", withOptions: false, extraProps: extraProps))
       }
    }
    
    @objc public func share(extraProps: [String : Any]?) {
       self.avSynchronizer.sync {
           sendEvents(events: self.createEvent(name: "av.share", withOptions: false, extraProps: extraProps))
       }
    }
    
    private func processSeek(seekDirection: String, oldCursorPosition: Int, newCursorPosition: Int, extraProps: [String : Any]?) {
        if self.isPlaying && self.startSessionTimeMillis == 0 {
            self.startSessionTimeMillis = Int(Date().timeIntervalSince1970 * 1000)
        }
        
        self.seekStart(oldCursorPosition: oldCursorPosition, extraProps: extraProps)
        
        self.eventDurationMillis = 0
        self.previousCursorPositionMillis = oldCursorPosition
        self.currentCursorPositionMillis = newCursorPosition
        
        sendEvents(events: self.createEvent(name: "av." + seekDirection, withOptions: true, extraProps: extraProps))
    }
    
    private func updateDuration() {
        self.eventDurationMillis = Int(Date().timeIntervalSince1970 * 1000) - self.startSessionTimeMillis - self.sessionDurationMillis
        self.sessionDurationMillis += self.eventDurationMillis
    }
    
    private func stopHeartbeatTimer() {
        guard heartbeatTimer != nil else { return }
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func resetState() {
        self.sessionId = Foundation.UUID().uuidString
        self.previousEvent = ""
        self.previousCursorPositionMillis = 0
        self.currentCursorPositionMillis = 0
        self.eventDurationMillis = 0
    }
    
    private func createEvent(name: String, withOptions: Bool, extraProps: [String : Any]?) -> Event {
        var props = self.getProps()
        if withOptions{
            props["previous_position"] = self.previousCursorPositionMillis
            props["position"] = self.currentCursorPositionMillis
            props["duration"] = self.eventDurationMillis
            props["previous_event"] = self.previousEvent
            
            self.previousEvent = name
        }
        props["session_id"] = self.sessionId
        
        if extraProps != nil {
            for (k,v) in extraProps! {
                props[k] = v
            }
        }
        
        let ev = Event(name: name)
        ev.data = props
        return ev
    }
    
    private func sendEvents(events: Event...) {
        if events.count == 0 {
            return
        }
        for e in events {
            _ = self.events?.add(event: e)
        }
        self.events?.send()
    }
}
