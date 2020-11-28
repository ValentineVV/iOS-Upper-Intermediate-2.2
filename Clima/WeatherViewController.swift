//
//  ViewController.swift
//  WeatherApp


import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

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
    
    private func getWeatherData(url: String, parameters: [String: String]) {

        AF.request(url, method: .get, parameters: parameters).responseJSON { [weak self] (response) in
            if let json = response.value {
                self?.updateWeatherData(json: JSON(json))
            } else {
                self?.cityLabel.text = "Network Error"
            }
            self?.refreshControll.endRefreshing()
        }
    }
    
    private func updateWeatherData(json : JSON) {
        if let tempResult = json["main"]["temp"].double {
            weatherDataModel.temperature = Int(tempResult - 273.15)
            weatherDataModel.city = json["name"].stringValue
            weatherDataModel.condition = json["weather"][0]["id"].intValue
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
            
            updateUIWithWeatherData()
        } else {
            cityLabel.text = "Unavailable"
        }
    }
    
    private func updateUIWithWeatherData() {
        cityLabel.text = weatherDataModel.city
        temperatureLabel.text = "\(weatherDataModel.temperature)°"
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {

            locationManager.stopUpdatingLocation()

            let latitude = String(location.coordinate.latitude)
            let longitude = String(location.coordinate.longitude)
            let params : [String : String] = ["lat" : latitude, "lon" : longitude, "appid" : APP_ID]
            
            getWeatherData(url: WEATHER_URL, parameters: params)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        cityLabel.text = "Location Unavailable"
        refreshControll.endRefreshing()
    }
}


