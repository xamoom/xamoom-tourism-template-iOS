//
//  Globals.swift
//  Kollitsch Art
//
//  Created by Raphael Seher on 23/02/2017.
//  Copyright © 2017 xamoom GmbH. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class Globals: NSObject {
  static var apikey = "25c5606b-a7bf-42e2-85c3-39db1753bc05"
  static var isBackgroundImage = "false"
  static var trackingId = ""

  
  struct Tag {
    static let topTip = "x-top-tip"
    static let config = "x-app-config"
    static let infoSite = "x-info"
    static let onboarding = "x-onboarding"
    static let voucher = "x-voucher"
    static let geofence = "x-geofence"
    static let quiz = "x-quiz"
  }
  
  struct Color {
    static var primaryColor = UIColor(red: 2/255.0, green: 112/255.0, blue: 184/255.0, alpha: 1.0)
    static var tabbarSelected = UIColor.white
    static var textColor = UIColor.white
    static var tabbarUnselected = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)
    static var barFontColor = UIColor.black
  }
  
  struct Image {
    static let placeholder = UIImage(named: "placeholder")  }
  
  struct Size {
    static let contentCollectionViewCellSize = CGSize(width: 160,
                                                      height: 120)
    static let contentCollectionViewInsets = UIEdgeInsets(top: 0.0,
                                                          left: 10.0,
                                                          bottom: 15.0,
                                                          right: 10.0)
  }
  
  struct Beacon {
    static let cooldown = 30 * 60
    // TODO: change identifier to app name
    static let klagenfurtBeaconIdentifier = "KlagenfurtBeaconIdentifier"
    static let uuid = UUID(uuidString: "de2b94ae-ed98-11e4-3432-78616d6f6f6d")!
    static var major: NSNumber = 0
  }
  
  struct Location {
    static let klagenfurtCoordinates = CLLocationCoordinate2DMake(46.6280397, 14.2952168)
    static let klagenfurtSpan = 0.1
  }
  
  struct Sound {
    static let correctAnswerKey = "quiz_answer_correct.mp3"
    static let incorrectAnswerKey = "quiz_answer_incorrect.mp3"
  }
    
  struct MapFilter {    
    static let emptyTitle = ""
    static let tagsSorted = ["architektur", "ausflugsziel", "denkmal",
                             "kirche", "galmus", "natur", "sightseeing", "shopping"]
    static let sightseeingTitle = NSLocalizedString("filterViewController.section.sightseeing", comment: "")
    static let sightseeingTags = [
      "ausflugsziel": NSLocalizedString("filterViewController.tag.attraction", comment: ""),
      "architektur": NSLocalizedString("filterViewController.tag.architektur", comment: ""),
      "denkmal": NSLocalizedString("filterViewController.tag.monument", comment: ""),
      "kirche": NSLocalizedString("filterViewController.tag.kirche", comment: ""),
      "galmus": NSLocalizedString("filterViewController.tag.galmus", comment: ""),
      "natur": NSLocalizedString("filterViewController.tag.nature", comment: ""),
      "sightseeing": NSLocalizedString("filterViewController.tag.sightseeing", comment: ""),
      "shopping": NSLocalizedString("filterViewController.tag.shopping", comment: ""),
      ]
      static var tags: [String: Dictionary<String, String>] = [
        sightseeingTitle:sightseeingTags,
      ]
  }
  
  struct Settings {
    static let navigationKey = "navigation"
    static let notificationsOff = "notification"
    static let notificationSoundMuted = "notification.sound"
    static let notificationVibrant = "notification.vibrand"
    static let onboardingPassedKey = "onboarding.passed"
    static let contentNumberViewed = "content.viewedcount"
    static let languageKey = "language"
    static let isFormsActive = "isFormActive";
    static let formsBaseUrl = "formUrl";
    static let isSocialSharingEnabled = "isSocialSharingEnabled"
  }
  
  struct Analytics {
    static let gaiTracker = "trackingID"
    static let contentTypeScreen = "App Screen"
  }
    
  struct Features {
    static var quiz = false
  }
  
  struct Languages {
    static let languages = [
      ("AF", "Afrikaans", "Afrikaans", "Afrikaans"),
      ("SQ", "Albanisch", "Albanian", "Shqip"),
      ("AM", "Amharisch", "Amharic", "አማርኛ"),
      ("AR", "Arabisch", "Arabic", "اَللُّغَةُ اَلْعَرَبِيَّة"),
      ("HY", "Armenisch", "Armenian", "Հայերեն"),
      ("AZ", "Aserbaidschanisch", "Azerbaijani", "Azərbaycana"),
      ("EU", "Baskisch", "Basque", "euskera"),
      ("BN", "Bengalisch", "Bengali", "বাংলা ভাষা"),
      ("BR", "Bertonisch", "Breton", "Brezhoneg"),
      ("MY", "Birmanisch", "Burmese", "မြန်မာ"),
      ("BS", "Bosnisch", "Bosnian", "Bosanski"),
      ("BG", "Bulgarisch", "Bulgarian", "Български"),
      ("ZH", "Chinesisch", "Chinese", "普通話"),
      ("DA", "Dänisch", "Danish", "Dansk"),
      ("DE", "Deutsch", "German", "Deutsch"),
      ("EN", "Englisch", "English", "English"),
      ("EO", "Esperanto", "Esperanto", "Esperanto"),
      ("ET", "Estnisch", "Estonian", "Eesti"),
      ("FO", "Färöisch", "Faroese", "føroyskt"),
      ("FIL", "Filipino", "Filipino", "Wikang Filipino"),
      ("FI", "Finnisch", "Finnish", "Suomi"),
      ("FR", "Französisch", "French", "Français"),
      ("GL", "Galicisch", "Galician", "galego"),
      ("GA", "Gälisch", "Goidelic", "teangacha Gaelacha"),
      ("KA", "Georgisch", "Georgian", "ქართული ენა"),
      ("EL", "Griechisch", "Greek", "ελληνική"),
      ("KL", "Grönländisch", "Greenlandic", "Kalaallisut"),
      ("GH", "Guaraní", "Guarani", "avañe'ẽ"),
      ("HT", "Haitianisch", "Haitian Creole", "kreyòl ayisyen"),
      ("HA", "Hausa", "Hausa", "هَرْشَن هَوْسَ"),
      ("HAW", "Hawaianisch", "Hawaiian", "ʻŌlelo Hawaiʻi"),
      ("IW", "Hebräisch", "Hebrew", "עברית"),
      ("HI", "Hindisch", "Hindi", "हिन्दी"),
      ("IG", "Igbo", "Igbo", "Igbo"),
      ("IN", "Indonesisch", "Malay", "bahasa Indonesia"),
      ("IS", "Isländisch", "Icelandic", "Íslenska"),
      ("IT", "Italienisch", "Italian", "Italiano"),
      ("JA", "Japanisch", "Japanese", "日本語"),
      ("JV", "Javanisch", "Javanese", "basa Jawa"),
      ("KH", "Kambodschanisch", "Cambodian", "ភាសាខ្មែរ"),
      ("KZ", "Kasachisch", "Kazakh", "Қазақ тілі"),
      ("CA", "Katalanisch", "Catalan", "Català"),
      ("KM", "Khmer", "Khmer", "ភាសាខ្មែរ"),
      ("KY", "Kirgisisch", "Kyrgyz", "Кыргыз тили/Kyrgyz tili"),
      ("RN", "Kirundi", "Kirundi", "Kirundi"),
      ("KO", "Koreanisch", "Korean", "한국말"),
      ("HR", "Kroatisch", "Croatian", "Hrvatski"),
      ("KU", "Kurdisch", "Kurdish", "کوردی"),
      ("LO", "Laotisch", "Lao", "ພາສາລາວ"),
      ("LV", "Lettisch", "Latvian", "Latviešu"),
      ("LT", "Litauisch", "Lithuanian", "Lietuvių"),
      ("MG", "Madagassisch", "Malagasy", "Malagasy"),
      ("MA", "Malaiisch", "Malay", "بهاس ملايو"),
      ("MT", "Maltesisch", "Maltese", "Malti"),
      ("MI", "Maorisch", "Maori", "Māori"),
      ("MR", "Marathi", "Marathi", "मराठी"),
      ("MK", "Mazedonisch", "Mazedonian", "Македонски"),
      ("CNR", "Montenegrinisch", "Montenegrin", "Црногорски језик"),
      ("NE", "Nepalesisch", "Nepalese", "नेपाली"),
      ("NL", "Niederländisch", "Dutch", "Nederlands"),
      ("NB", "Norwegisch/Bokmål", "Norwegian/Bokmål", "Bokmål"),
      ("NN", "Norwegisch/Nynorsk", "Norwegian/Nynorsk", "Nynorsk"),
      ("NG", "Oshiwambo", "Ovambo", "OshiVambo"),
      ("PAN", "Panjabi", "Panjabi", "ਪੰਜਾਬੀ"),
      ("FA", "Persisch", "Persian", "زبان فارسی"),
      ("PL", "Polnisch", "Polish", "Polski"),
      ("PT", "Portugiesisch", "Portugese", "Português"),
      ("RM", "Rätoromanisch", "Rhaeto-Romance", "Rumantsch"),
      ("RO", "Rumänisch", "Romanian", "Română"),
      ("RU", "Russisch", "Russian", "Русский"),
      ("SE", "Uralisch", "Northern Sami", "Davvisámegiella"),
      ("SG", "Sango", "Sango", "Sängö"),
      ("SV", "Schwedisch", "Swedish", "Svenska"),
      ("SR", "Serbisch", "Serbian", "Српски"),
      ("SI", "Singalesisch", "Singalese", "සිංහල"),
      ("SS", "Siswati", "Siswati", "siSwati"),
      ("SK", "Slowakisch", "Slowakian", "Slovenčina"),
      ("SL", "Slowenisch", "Slovene", "Slovenščina"),
      ("SO", "Somali", "Somali", "Af Soomaali"),
      ("ES", "Spanisch", "Spanish", "Español"),
      ("SW", "Swahili", "Swahili", "Kiswahili"),
      ("TA", "Tamil", "Tamil", "தமிழ்"),
      ("TE", "Telugu", "Telugu", "తెలుగు"),
      ("TH", "Thailändisch", "Thai", "ภาษาไทย"),
      ("BO", "Tibetisch", "Tibetan", "བོད་སྐད"),
      ("TI", "Tigrinya", "Tigrinya", "ትግርኛ"),
      ("CZ", "Tschechisch", "Czech", "Čeština"),
      ("TR", "Türkisch", "Turkish", "Türkçe"),
      ("HU", "Ungarisch", "Hungarian", "Magyar"),
      ("UR", "Urdu", "Urdu", "اردو"),
      ("UK", "Urkainisch", "Ukrainian", "Українська"),
      ("UZ", "Usbekisch", "Uzbek", "Oʻzbek tili"),
      ("VI", "Vietnamesisch", "Vietnamese", "Tiếng Việt"),
      ("CY", "Walisisch", "Welsh", "Cymraeg"),
      ("BE", "Weißrussisch", "Belarussian", "Беларуская мова"),
      ("XH", "Xhosa", "Xhosa", "isiXhosa"),
      ("YO", "Yoruba", "Yoruba", "èdè Yorùbá"),
      ("ZU", "Zulu", "Zulu", "isiZulu")
    ]
  }
}
