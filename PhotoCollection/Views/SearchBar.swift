//
//  SearchBar.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/31/25.
//

import UIKit

protocol SearchBarDelegate: AnyObject {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    func clearButtonClicked()
}

class SearchBar: UIView {
    struct Model {
        let placeholder: String
    }

    private var model: Model? {
        didSet {
            applyModel()
        }
    }
    weak var delegate: SearchBarDelegate?
    // MARK: UI Components

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchTextField.clearButtonMode = .never
        return searchBar
    }()
    private let clearButton: UIButton = {
        let clearButton = UIButton()
        let removeImage = UIImage(systemName: "x.circle.fill")?.withRenderingMode(.alwaysTemplate)
        clearButton.setImage(removeImage, for: .normal)
        clearButton.tintColor = .lightGray
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.isHidden = true
        return clearButton
    }()

    init(model: Model? = nil, delegate: SearchBarDelegate? = nil) {
        super.init(frame: .zero)
        self.model = model
        searchBar.delegate = self
        setupUI()
        setupConstraints()
        addActions()
        applyModel()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func setupUI() {
        addSubview(stackView)
        stackView.addArrangedSubview(searchBar)
        stackView.addArrangedSubview(clearButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }

    private func addActions() {
        clearButton.addTarget(self, action: #selector(handleClearButtonClick), for: .touchUpInside)
    }

    private func applyModel() {
        guard let model else { return }

        searchBar.placeholder = model.placeholder
    }

    func setText(text: String) {
        clearButton.isHidden = text.isEmpty
        searchBar.text = text
    }
}

extension SearchBar {
    @objc private func handleClearButtonClick() {
        delegate?.clearButtonClicked()
    }
}

extension SearchBar: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        clearButton.isHidden = searchText.isEmpty
        delegate?.searchBar(searchBar, textDidChange: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        delegate?.searchBarSearchButtonClicked(searchBar)
    }
}
