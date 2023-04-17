//
//  UIScrollView.Extension.swift
//  Neves
//
//  Created by 周健平 on 2021/6/3.
//

extension JP where Base: UIScrollView {
    func contentInsetAdjustmentNever() {
        if #available(iOS 11.0, *) {
            base.contentInsetAdjustmentBehavior = .never
            guard let tableView = base as? UITableView
            else { return }
            tableView.estimatedRowHeight = 0
            tableView.estimatedSectionHeaderHeight = 0
            tableView.estimatedSectionFooterHeight = 0
        }
    }
}
