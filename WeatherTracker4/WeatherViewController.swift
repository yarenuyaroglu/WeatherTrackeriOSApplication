import UIKit
import Kingfisher

class WeatherViewController: UIViewController {
    
    weak var delegate: CityProvider?
    let networkingManager = NetworkingManager()
    var dailyWeather: [DailyWeather] = []
    
    // UI components
    private let cityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 60)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let weatherImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 120)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Weather"
        setupUI()
        
        guard let city = delegate?.cityName(), !city.isEmpty else {
            print("No city provided!")
            return
        }
        cityLabel.text = city
        
        fetchWeather(for: city)
    }
    
    private func setupUI() {
        view.addSubview(cityLabel)
        view.addSubview(temperatureLabel)
        view.addSubview(weatherImageView)
        view.addSubview(descriptionLabel)
        view.addSubview(collectionView)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(WeatherCell.self, forCellWithReuseIdentifier: "WeatherCell")
        
        NSLayoutConstraint.activate([
            cityLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cityLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            temperatureLabel.topAnchor.constraint(equalTo: cityLabel.bottomAnchor, constant: 20),
            temperatureLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            weatherImageView.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 20),
            weatherImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            weatherImageView.widthAnchor.constraint(equalToConstant: 100),
            weatherImageView.heightAnchor.constraint(equalToConstant: 100),
            
            descriptionLabel.topAnchor.constraint(equalTo: weatherImageView.bottomAnchor, constant: 10),
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            collectionView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            collectionView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    func fetchWeather(for city: String) {
        networkingManager.fetchWeather(for: city) { [weak self] combinedData in
            guard let self = self, let data = combinedData else {
                print("Failed to fetch weather data.")
                return
            }
            DispatchQueue.main.async {
                self.temperatureLabel.text = "\(data.current.main.temp)°C"
                if let weatherInfo = data.current.weather.first {
                    self.descriptionLabel.text = weatherInfo.description.capitalized
                    let iconURL = "https://openweathermap.org/img/wn/\(weatherInfo.icon)@2x.png"
                    self.weatherImageView.kf.setImage(with: URL(string: iconURL))
                }
                self.dailyWeather = data.daily
                self.collectionView.reloadData()
            }
        }
    }
}

// UICollectionViewDataSource & Delegate
extension WeatherViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dailyWeather.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeatherCell", for: indexPath) as! WeatherCell
        let weather = dailyWeather[indexPath.item]
        cell.configure(with: weather)
        return cell
    }
}
