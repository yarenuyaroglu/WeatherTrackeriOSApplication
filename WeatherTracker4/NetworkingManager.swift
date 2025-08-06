import Foundation
import Alamofire

//API Modelleri

// Güncel hava durumu modeli (Current Weather)
struct WeatherData: Codable {
    let name: String
    let main: MainInfo
    let weather: [WeatherDetail]
    let dt: Int
}

struct MainInfo: Codable {
    let temp: Double
}

// Forecast modeli (5 gün, 3 saat aralıklarla)
struct ForecastData: Codable {
    let list: [ForecastItem]
}

struct ForecastItem: Codable {
    let dt: Int
    let main: MainInfo
    let weather: [WeatherDetail]
    let dt_txt: String
}

struct WeatherDetail: Codable {
    let description: String
    let icon: String
}

// Modeli UI’da kullandığım DailyWeather yapısına dönüştürüyoruz.
struct DailyWeather {
    let dt: Int
    let temp: DailyTemperature
    let weather: [WeatherDetail]
}

struct DailyTemperature {
    let day: Double
}

// İki farklı API çağrısından gelen verileri birleştirmek için:
struct WeatherCombinedData {
    let current: WeatherData
    let daily: [DailyWeather]
}

// NetworkingManager

class NetworkingManager {
    
    
    
    // OpenWeather current weather endpoint (city name ile)
    private func currentWeatherURL(for city: String) -> String {
        return "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(apiKey)&units=metric"
    }
    
    // OpenWeather forecast endpoint (city name ile, 3 saatlik aralıklarla)
    private func forecastURL(for city: String) -> String {
        return "https://api.openweathermap.org/data/2.5/forecast?q=\(city)&appid=\(apiKey)&units=metric"
    }
    
    // Hem güncel hava durumunu hem de forecast verilerini çekip, günlük tahmin haline dönüştürür.
    func fetchWeather(for city: String, completion: @escaping (WeatherCombinedData?) -> Void) {
        let group = DispatchGroup()
        var currentWeather: WeatherData?
        var forecastData: ForecastData?
        
        group.enter()
        AF.request(currentWeatherURL(for: city)).responseDecodable(of: WeatherData.self) { response in
            if let data = response.value {
                currentWeather = data
            } else {
                print("Error fetching current weather: \(String(describing: response.error))")
            }
            group.leave()
        }
        
        group.enter()
        AF.request(forecastURL(for: city)).responseDecodable(of: ForecastData.self) { response in
            if let data = response.value {
                forecastData = data
            } else {
                print("Error fetching forecast: \(String(describing: response.error))")
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let current = currentWeather, let forecast = forecastData {
                let dailyForecast = self.aggregateForecast(forecast.list)
                let combined = WeatherCombinedData(current: current, daily: dailyForecast)
                completion(combined)
            } else {
                completion(nil)
            }
        }
    }
    
    // Forecast verilerini, her gün için öğle saatine yakın tahmine dönüştürür.
    private func aggregateForecast(_ list: [ForecastItem]) -> [DailyWeather] {
        var dailyDict = [String: ForecastItem]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        
        for item in list {
            if let date = dateFormatter.date(from: item.dt_txt) {
                let dayString = dayFormatter.string(from: date)
                // Eğer mevcut gün için bir kayıt varsa, saat 12'ye yakın olanı tercih ediyoruz.
                if let existing = dailyDict[dayString] {
                    let existingDate = dateFormatter.date(from: existing.dt_txt)!
                    let currentHour = Calendar.current.component(.hour, from: date)
                    let existingHour = Calendar.current.component(.hour, from: existingDate)
                    let diffCurrent = abs(currentHour - 12)
                    let diffExisting = abs(existingHour - 12)
                    if diffCurrent < diffExisting {
                        dailyDict[dayString] = item
                    }
                } else {
                    dailyDict[dayString] = item
                }
            }
        }
        // Günlere göre sıralama
        let sortedDays = dailyDict.keys.sorted()
        var daily: [DailyWeather] = []
        for day in sortedDays {
            if let item = dailyDict[day] {
                let dailyWeather = DailyWeather(dt: item.dt,
                                                temp: DailyTemperature(day: item.main.temp),
                                                weather: item.weather)
                daily.append(dailyWeather)
            }
        }
        return daily
    }
}
