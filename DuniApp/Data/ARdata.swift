//
//  ARdata.swift
//  DuniApp
//
//  Created by 파디오 on 2020/06/15.
//  Copyright © 2020 파디오. All rights reserved.
//

import Foundation

class arLocationData:Codable{
    var clientid : String
    var data : [locationData]
    var dname : String
    var dtime : String
    var dtimestamp : TimeInterval
    var youtube_data_id : String
}
struct locationData:Codable{
    var alt : Double
    var dtimestamp : TimeInterval
    var etc : etcData
    var lat : Double
    var lng : Double
}
struct etcData:Codable{
    var battery : Int
    var marked : Bool
}
