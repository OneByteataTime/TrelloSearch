//
//  ViewController.swift
//  TrelloSearch
//
//  Created by Steve Jackson on 5/27/17.
//  Copyright © 2017 Steve Jackson. All rights reserved.
//

import UIKit
import OAuthSwift
import Charts
import KeychainAccess

class ViewController: UIViewController {
    
    @IBOutlet weak var barChartView: BarChartView!
    
    // oauth swift object (retain)
    var oauthswift: OAuthSwift?
    var months: [String]!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.startUp()
        
        months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let unitsSold = [20.0, 4.0, 6.0, 3.0, 12.0, 16.0, 4.0, 18.0, 2.0, 4.0, 5.0, 4.0]
        
        setChart(dataPoints: months, values: unitsSold)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func startUp() {
        
        // 1 Create OAuth2Swift object
        let oauthswift = OAuth1Swift(
            consumerKey:    "AppID",
            consumerSecret: "ClientID",
            requestTokenUrl:    "https://trello.com/1/OAuthGetRequestToken?scope=read&name=iosTrelloSearch",
            authorizeUrl:       "https://trello.com/1/OAuthAuthorizeToken?scope=read&name=iosTrelloSearch",
            accessTokenUrl:     "https://trello.com/1/OAuthGetAccessToken?scope=read&name=iosTrelloSearch"
        )
        
        self.oauthswift = oauthswift
        
        getOAuthCredential(oauthswift)
        
        
        if (oauthswift.client.credential.oauthTokenSecret.characters.count > 0)  {
            self.testTrello(oauthswift)
        }
        else {
            let handler = SafariURLHandler(viewController: self, oauthSwift: self.oauthswift!)
            handler.presentCompletion = {
                print("Safari presented")
            }
            handler.dismissCompletion = {
                print("Safari dismissed")
            }
            
            oauthswift.authorizeURLHandler = handler
            
            
            oauthswift.authorize(withCallbackURL: URL(string: "trello-search://oauth-callback/callback/trello")!,
                                 success: { credential, response, parameters in
                                    self.saveOAuthCredential(oauthswift)
            },
                                 failure: { error in
                                    print(error.localizedDescription, terminator: "")
            }
            )
        }
    }
    
    func saveOAuthCredential(_ oauthswift : OAuth1Swift) {
        let keychain = Keychain(service: "com.jastech.trello-search")
        keychain[string: "trello_search_token"] = oauthswift.client.credential.oauthToken
        keychain[string: "trello_search_secret"] = oauthswift.client.credential.oauthTokenSecret

        self.testTrello(oauthswift)
    }
    
    func getOAuthCredential(_ oauthswift : OAuth1Swift) {
        let keychain = Keychain(service: "com.jastech.trello-search")
        if let token = keychain[string: "trello_search_token"] {
            let secret = keychain[string: "trello_search_secret"]
         
            oauthswift.client.credential.oauthToken = token
            oauthswift.client.credential.oauthTokenSecret = secret!
        }
        
        return
    }
    
    func setChart(dataPoints: [String], values: [Double]) {
        barChartView.noDataText = "You need to provide data for the chart."
        
        var entries: [BarChartDataEntry] = []
        
        for (i, value) in values.enumerated()
        {
            entries.append(BarChartDataEntry(x: Double(i), y: value))
        }
        
        
        let dataSet = BarChartDataSet(values: entries, label: "Units Sold")
        let data = BarChartData(dataSet: dataSet)
        
        barChartView.data = data
    }
    
    func testTrello(_ oauthswift: OAuth1Swift) {
        let _ = oauthswift.client.get(
            "https://trello.com/1/members/me/boards",
            success: { response in
                if let dataString = response.string {
                    print("Got stuff...")
                }
        }, failure: { error in
            print(error)
        }
        )
    }
    
}

