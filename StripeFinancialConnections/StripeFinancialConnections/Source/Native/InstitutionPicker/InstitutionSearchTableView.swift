//
//  InstitutionSearchTableView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/20/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

private enum Section {
    case main
}

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
protocol InstitutionSearchTableViewDelegate: AnyObject {
    func institutionSearchTableView(_ tableView: InstitutionSearchTableView, didSelectInstitution institution: FinancialConnectionsInstitution)
    func institutionSearchTableViewDidSelectManuallyAddYourAccount(_ tableView: InstitutionSearchTableView)
}

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
final class InstitutionSearchTableView: UIView {
    
    private let allowManualEntry: Bool
    private let tableView = UITableView()
    private let dataSource: UITableViewDiffableDataSource<Section, FinancialConnectionsInstitution>
    private lazy var didSelectManualEntry: (() -> Void)? = {
        return allowManualEntry ? { [weak self] in
            guard let self = self else { return }
            self.delegate?.institutionSearchTableViewDidSelectManuallyAddYourAccount(self)
        } : nil
    }()
    weak var delegate: InstitutionSearchTableViewDelegate? = nil
    
    private lazy var tableFooterView: UIView = {
        let footerView =  InstitutionSearchFooterView(didSelectManuallyAddYourAccount: didSelectManualEntry)
        let footerContainerView = UIView()
        footerContainerView.backgroundColor = .clear
        // we wrap `footerView` in a container to add extra padding
        footerContainerView.addAndPinSubview(
            footerView,
            insets: NSDirectionalEdgeInsets(
                top: 10, // extra padding between table and footer
                leading: 0,
                bottom: 0,
                trailing: 0
            )
        )
        return footerContainerView
    }()
    private lazy var loadingView: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = .textSecondary // set color because we only support light mode
        activityIndicator.backgroundColor = .customBackgroundColor
        activityIndicator.isHidden = true
        activityIndicator.setContentHuggingPriority(.defaultLow, for: .vertical)
        activityIndicator.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return activityIndicator
    }()
    
    init(allowManualEntry: Bool) {
        self.allowManualEntry = allowManualEntry
        tableView.backgroundColor = .customBackgroundColor
        tableView.separatorInset = .zero
        tableView.separatorStyle = .none
        tableView.rowHeight = 54
        tableView.contentInset = UIEdgeInsets(
            // add extra inset at the top/bottom to show the cell-selected-state separators
            top: 1.0 / UIScreen.main.nativeScale,
            left: 0,
            bottom: 1.0 / UIScreen.main.nativeScale,
            right: 0
        )
        tableView.keyboardDismissMode = .onDrag
        let cellIdentifier = "\(InstitutionSearchTableViewCell.self)"
        self.dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, institution in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? InstitutionSearchTableViewCell else {
                fatalError("Unable to dequeue cell \(InstitutionSearchTableViewCell.self) with cell identifier \(cellIdentifier)")
            }
            cell.customize(with: institution)
            return cell
        }
        super.init(frame: .zero)
        tableView.register(InstitutionSearchTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.delegate = self
        addAndPinSubview(tableView)
        addAndPinSubview(loadingView)
        showTableFooterView(true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // `UITableView` does not automatically resize `tableHeaderView`
        // so here we do it manually
        if let tableHeaderView = tableView.tableHeaderView {
            let tableHeaderViewSize = tableHeaderView.systemLayoutSizeFitting(
                CGSize(
                    width: tableView.bounds.size.width,
                    height: UIView.layoutFittingCompressedSize.height
                )
            )
            if tableHeaderView.frame.size.height != tableHeaderViewSize.height {
                tableHeaderView.frame.size.height = tableHeaderViewSize.height
                tableView.tableHeaderView = tableHeaderView
            }
        }
        
        // `UITableView` does not automatically resize `tableFooterView`
        // so here we do it manually
        if let tableFooterView = tableView.tableFooterView {
            let tableFooterViewSize = tableFooterView.systemLayoutSizeFitting(
                CGSize(
                    width: tableView.bounds.size.width,
                    height: UIView.layoutFittingCompressedSize.height
                )
            )
            if tableFooterView.frame.size.height != tableFooterViewSize.height {
                tableFooterView.frame.size.height = tableFooterViewSize.height
                tableView.tableFooterView = tableFooterView
            }
        }
    }
    
    func loadInstitutions(_ institutions: [FinancialConnectionsInstitution]) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, FinancialConnectionsInstitution>()
        snapshot.appendSections([Section.main])
        snapshot.appendItems(institutions, toSection: Section.main)
        dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
        
        // clear state (some of this is defensive programming)
        showNoResultsNotice(query: nil)
        showError(false)
    }
    
    func showLoadingView(_ show: Bool) {
        loadingView.isHidden = !show
        if show {
            loadingView.stp_startAnimatingAndShow()
        } else {
            loadingView.stp_stopAnimatingAndHide()
        }
        bringSubviewToFront(loadingView) // defensive programming to avoid loadingView being hiddden
    }
    
    func showNoResultsNotice(query: String?) {
        if let query = query {
            tableView.tableHeaderView = {
                let noResultsLabel = UILabel()
                noResultsLabel.text = "No results for \"\(query)\"."
                noResultsLabel.font = .stripeFont(forTextStyle: .caption)
                noResultsLabel.textColor = .textSecondary
                noResultsLabel.textAlignment = .center
                // we use `UIStackView` even if its just a single view
                // because it allows for automatic resizing + easy margins
                let stackView = UIStackView(arrangedSubviews: [noResultsLabel])
                stackView.isLayoutMarginsRelativeArrangement = true
                stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                    top: 0,
                    leading: 24,
                    bottom: 16,
                    trailing: 24
                )
                return stackView
            }()
        } else {
            tableView.tableHeaderView = nil
        }
    }
    
    func showError(_ show: Bool) {
        if show {
            tableView.tableHeaderView = InstitutionSearchErrorView(
                didSelectEnterYourBankDetailsManually: didSelectManualEntry
            )
        } else {
            tableView.tableHeaderView = nil
        }
        showTableFooterView(!show)
    }
    
    // the footer is always shown, except for when there is an error searching
    private func showTableFooterView(_ show: Bool) {
        if show {
            tableView.tableFooterView = tableFooterView
        } else {
            tableView.tableFooterView = nil
        }
    }
}

// MARK: - UITableViewDelegate

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
extension InstitutionSearchTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let institution = dataSource.itemIdentifier(for: indexPath) {
            delegate?.institutionSearchTableView(self, didSelectInstitution: institution)
        }
    }
}
