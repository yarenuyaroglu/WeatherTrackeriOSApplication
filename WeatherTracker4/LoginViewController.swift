import UIKit

class LoginViewController: UIViewController, CityProvider {
    
    private let cityTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter city"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let searchButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Search", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "WeatherTracker"
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(cityTextField)
        view.addSubview(searchButton)
        
        NSLayoutConstraint.activate([
            cityTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cityTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cityTextField.widthAnchor.constraint(equalToConstant: 250),
            
            searchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchButton.topAnchor.constraint(equalTo: cityTextField.bottomAnchor, constant: 20)
        ])
        
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
    }
    
    @objc private func searchButtonTapped() {
        guard let city = cityTextField.text, !city.isEmpty else {
            print("Please enter a city.")
            return
        }
        let weatherVC = WeatherViewController()
        weatherVC.delegate = self
        navigationController?.pushViewController(weatherVC, animated: true)
    }
    
    // CityProvider protokolü
    func cityName() -> String {
        return cityTextField.text ?? ""
    }
}
