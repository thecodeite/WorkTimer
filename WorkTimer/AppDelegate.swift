//
//  AppDelegate.swift
//  WorkTimer
//
//  Created by Sam Plews on 12/04/2017.
//  Copyright © 2017 Codeite. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var theLabel: NSTextField!
    @IBOutlet weak var theButton: NSButton!
    
    var buttonPresses = 1.0;
    var tooltip = "Started"
    //let apiEndpoint: String = "https://us-central1-codeite-ttg.cloudfunctions.net/nextTimedEvent"
    let apiEndpoint: String = "https://functions.dev/codeite-ttg/us-central1/nextTimedEvent"

    
    var statusBar = NSStatusBar.system()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var theMenu: NSMenu = NSMenu()
    var openMenuItem : NSMenuItem = NSMenuItem()
    var readMenuItem : NSMenuItem = NSMenuItem()
    var startMenuItem : NSMenuItem = NSMenuItem()
    var startAtMenu: NSMenu = NSMenu()
    var quitMenuItem : NSMenuItem = NSMenuItem()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        self.window!.orderOut(self)
        
        var _ = Timer.scheduledTimer(
            timeInterval: 60.0,
            target: self,
            selector: #selector(tick),
            userInfo: nil,
            repeats: true
        )
        
        tick()

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    override func awakeFromNib() {
        //Add statusBarItem
        statusBarItem = statusBar.statusItem(withLength: -1)
        statusBarItem.menu = theMenu
        
        //Add menuItem to menu
        openMenuItem.title = "Open"
        openMenuItem.target = self
        openMenuItem.action = #selector(setWindowVisible)
        openMenuItem.keyEquivalent = ""
        openMenuItem.isEnabled = true
        
        readMenuItem.title = "Read"
        readMenuItem.target = self
        readMenuItem.action = #selector(makeGetCall)
        readMenuItem.keyEquivalent = ""
        readMenuItem.isEnabled = true
        
        startMenuItem.title = "Start Now"
        startMenuItem.target = self
        startMenuItem.action = #selector(startNewTimerAt)
        startMenuItem.keyEquivalent = ""
        startMenuItem.submenu = startAtMenu

        quitMenuItem.title = "Quit"
        quitMenuItem.target = self
        quitMenuItem.action = #selector(quit)
        quitMenuItem.keyEquivalent = ""
        
        theMenu.addItem(openMenuItem)
        theMenu.addItem(readMenuItem)
        theMenu.addItem(startMenuItem)
        theMenu.addItem(quitMenuItem)
        
        setLabelMessage(percent: 0, message: "Reading API")
    }
    
    
    func setLabelMessage(percent: Double, message: String) {
        theLabel.stringValue = "You've pressed the button \(buttonPresses) times."
        //statusBarItem.button?.title = "Presses: \(buttonPresses)"
        statusBarItem.toolTip = "Left: \(message)"
        
        let imageNumber = 100 - Int(percent * 100)
        
        let pathString = "progress\(imageNumber).png"
        let image = NSImage(imageLiteralResourceName: pathString)
        statusBarItem.button?.image = image
    }
    
    func setWindowVisible(sender: AnyObject){
        self.window!.orderFrontRegardless()
    }
    
    func quit(sender: AnyObject) {
        NSApp.terminate(self)
    }
    
    func tick() {
        var first = Date()
        let calendar = Calendar.current
        let x: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        var components = calendar.dateComponents(x, from: first)
        
        components.second = 0
        first = calendar.date(from: components)!
        while(calendar.component(.minute, from: first) % 5 != 0) {
            first = Calendar.current.date(byAdding: .minute, value: -1, to: first)!
        }
    
        startMenuItem.representedObject = first.iso8601
        startMenuItem.title = "Start at \(first.time)"
        
        startAtMenu.removeAllItems()
        
        for _ in 1...6 {
            first = Calendar.current.date(byAdding: .minute, value: -5, to: first)!
            
            let subMenuItem = NSMenuItem()
            subMenuItem.title = "Start at \(first.time)"
            subMenuItem.target = self
            subMenuItem.action = #selector(startNewTimerAt)
            subMenuItem.representedObject = first.iso8601
            subMenuItem.keyEquivalent = ""

            
            startAtMenu.addItem(subMenuItem)
        }
        startAtMenu.addItem(NSMenuItem.separator())
        
        components.hour = 10
        components.minute = 0
        first = calendar.date(from: components)!
        for _ in 1...9 {
            let subMenuItem = NSMenuItem()
            subMenuItem.title = "Start at \(first.time)"
            subMenuItem.target = self
            subMenuItem.action = #selector(startNewTimerAt)
            subMenuItem.representedObject = first.iso8601
            subMenuItem.keyEquivalent = ""
            
            startAtMenu.addItem(subMenuItem)
            
            first = Calendar.current.date(byAdding: .minute, value: -15, to: first)!
        }
        
        makeGetCall()
    }
    
    func makeGetCall() {
        // Set up the URL request
        guard let url = URL(string: apiEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        let urlRequest = URLRequest(url: url)
        
        // set up the session
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        // make the request
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET on /codeite-ttg/us-central1/nextTimedEvent")
                print(error?.localizedDescription ?? "\(error)")
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            // parse the result as JSON, since that's what the API provides
            do {
                guard let timedEvent = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: AnyObject] else {
                    print("error trying to convert data to JSON")
                    return
                }
                // now we have the timedEvent, let's just print it to prove we can access it
                print("The timedEvent is: " + timedEvent.description)
                
                if let errorMessage = timedEvent["error"] as? String {
                    print("Could not get percent title from JSON")
                    self.setLabelMessage(percent: 1, message: errorMessage)
                    return
                }
                
                guard let percent = timedEvent["percent"] as? Double else {
                    print("Could not get percent title from JSON")
                    self.setLabelMessage(percent: 1, message: "Timed event does not contain percent")
                    return
                }
                
                if let leftDesc = timedEvent["leftDesc"] as? String {
                    self.setLabelMessage(percent: percent, message: leftDesc)
                    return
                } else {
                    self.setLabelMessage(percent: percent, message: "There is \(percent)% left to go.")
                    return
                }

            } catch  {
                print("error trying to convert data to JSON")
                return
            }
        }
        
        task.resume()
    }
    
    func startNewTimerAt(sender: AnyObject) {
        if let menuItem = sender as? NSMenuItem {
            print(menuItem.representedObject ?? "No rep obj")
            if let at = menuItem.representedObject as? String{
                startNewTimer(at: at)
            }
        }
    }
    
    func startNewTimer(at: String) {
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        
        guard let start = Formatter.iso8601.date(from: at) else {
            print("at not a date")
            return
        }
        let end = Calendar.current.date(byAdding: .hour, value: 8, to: start)!
        
        let postString = "description=Work+timer:+\(start.iso8601Date)&start=\(start.iso8601)&end=\(end.iso8601)"
        print(postString)
        
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
            self.tick()
        }
        task.resume()
    }

}

extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
    static let iso8601Date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
    
extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
    var iso8601Date: String {
        return Formatter.iso8601Date.string(from: self)
    }
    var time: String {
        return Formatter.time.string(from: self)
    }
}


