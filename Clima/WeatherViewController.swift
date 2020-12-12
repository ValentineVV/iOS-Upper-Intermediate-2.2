//
//  ViewController.swift
//  WeatherApp


import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

private enum ErrorType {
    case didFail
    case networkError
    case unavailable
    case none
}

final class WeatherViewController: UIViewController, CLLocationManagerDelegate {
    
    private let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    private let APP_ID = "9def5a84f246eddf19f474ac181d71f1"

    private let locationManager = CLLocationManager()
    private let weatherDataModel = WeatherDataModel()

    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!

    private var refreshControll: UIRefreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.requestLocation()

        scroll.addSubview(refreshControll)
        refreshControll.addTarget(self,
                                  action: #selector(didPullToRefresh(sender:)),
                                  for: .valueChanged)
    }

    @objc private func didPullToRefresh(sender: Any) {
        locationManager.requestLocation()
    }
    
    private func getWeatherData(latitude: String, longitude: String) {
        
        let params : [String : String] = ["lat" : latitude, "lon" : longitude, "appid" : APP_ID]

        AF.request(WEATHER_URL, method: .get, parameters: params).responseJSON { [weak self] (response) in
            if let json = response.value {
                self?.updateWeatherData(json: JSON(json))
            } else {
                self?.updateUIWithError(.networkError)
            }
            self?.refreshControll.endRefreshing()
        }
    }
    
    private func updateWeatherData(json: JSON) {
        if let tempResult = json["main"]["temp"].double {
            weatherDataModel.temperature = Int(tempResult - 273.15)
            weatherDataModel.city = json["name"].stringValue
            weatherDataModel.condition = json["weather"][0]["id"].intValue
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
            
            updateUIWithError(.none)
        } else {
            updateUIWithError(.unavailable)
        }
    }
    
    private func updateUIWithError(_ error: ErrorType = .none) {
        switch error {
        
        case .didFail:
            cityLabel.text = "Location Unavailable"
            temperatureLabel.text = ""
            weatherIcon.image = nil
        case .networkError:
            cityLabel.text = "Network Error"
            temperatureLabel.text = ""
            weatherIcon.image = nil
        case .unavailable:
            cityLabel.text = "Unavailable"
            temperatureLabel.text = ""
            weatherIcon.image = nil
        case .none:
            cityLabel.text = weatherDataModel.city
            temperatureLabel.text = "\(weatherDataModel.temperature)°"
            weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {

            locationManager.stopUpdatingLocation()

            let latitude = String(location.coordinate.latitude)
            let longitude = String(location.coordinate.longitude)
            
            getWeatherData(latitude: latitude, longitude: longitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        updateUIWithError(.didFail)
        refreshControll.endRefreshing()
    }
}


