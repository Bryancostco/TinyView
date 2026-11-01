import UIKit    // uikit for the table view, search and segmented control

// 10/31/26 screen 2, the library list (UITableView + search + filter + sort)
final class library_view_controller: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {

    enum sort_option: String, CaseIterable {        // the 3 ways you can sort, raw value is the menu text
        case recently_opened = "Recently opened"    // newest first
        case title = "Title"                        // a to z
        case progress = "Progress"                  // most read first
    }

    private let search_controller = UISearchController(searchResultsController: nil)                   // search bar under the title, nil = show results in this same table
    private let filter_control = UISegmentedControl(items: ["All", "Reading", "On hold", "Finished"])    // status filter
    private let count_label = app_theme.make_label(size: 14, color: app_theme.secondary_text_color)    // 7 books
    private let sort_button = UIButton(type: .system)                                                  // sort menu button
    private let table_view = UITableView(frame: .zero, style: .insetGrouped)                           // insetGrouped gives the rounded white card look
    private var visible_books: [book_item] = []                                                        // whats actually showing after search + filter + sort
    private var current_sort = sort_option.recently_opened                                             // default sort
    private var search_text = ""                                                                       // whatever they typed in search

    override func viewDidLoad() {                            // uikit calls this once when the screen loads
        super.viewDidLoad()                                  // let uikit do its thing first
        view.backgroundColor = app_theme.background_color    // warm background
        title = "Library"                                    // big title
        navigationItem.largeTitleDisplayMode = .always       // keep it big

        let add_item = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in self?.open_edit_book(book_id: nil) })    // + opens add book
        navigationItem.rightBarButtonItems = [add_item, editButtonItem]    // first item is the far right one, so it goes Edit then +

        search_controller.searchResultsUpdater = self                         // tell us every time the text changes
        search_controller.obscuresBackgroundDuringPresentation = false        // dont gray out the table while typing
        search_controller.searchBar.placeholder = "Search title or author"    // hint text from the figma
        navigationItem.searchController = search_controller                   // attach it under the large title
        navigationItem.hidesSearchBarWhenScrolling = false                    // always show it, easier for screenshots too

        build_layout()        // make the views
        update_sort_menu()    // set up the sort button menu
        apply_filters()       // load the table
        NotificationCenter.default.addObserver(self, selector: #selector(handle_store_change), name: .book_store_did_change, object: nil)    // reload if a book changes
    }

    @objc private func handle_store_change() {    // store posted a change
        apply_filters()                           // rebuild the list
    }

    // 10/31/26 filter + sort row on top, table fills the rest
    private func build_layout() {
        filter_control.selectedSegmentIndex = 0    // start on All
        filter_control.addAction(UIAction { [weak self] _ in self?.apply_filters() }, for: .valueChanged)    // refilter when they tap a segment

        var sort_configuration = UIButton.Configuration.plain()                  // plain text style button
        sort_configuration.image = UIImage(systemName: "arrow.up.arrow.down")    // sort icon
        sort_configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)    // smaller icon
        sort_configuration.imagePadding = 4                                      // gap between icon and text
        sort_configuration.baseForegroundColor = app_theme.accent_color          // orange
        sort_configuration.contentInsets = .zero                                 // no extra padding so it lines up with the count
        sort_button.configuration = sort_configuration                           // apply it
        sort_button.showsMenuAsPrimaryAction = true                              // a normal tap opens the menu (no long press needed)

        let sort_row = UIStackView(arrangedSubviews: [count_label, UIView(), sort_button])    // count, spacer, sort
        sort_row.axis = .horizontal                                                           // side by side
        sort_row.alignment = .center                                                          // centered vertically

        let header_stack = UIStackView(arrangedSubviews: [filter_control, sort_row])    // segment then sort row
        header_stack.axis = .vertical                                                   // top to bottom
        header_stack.spacing = 12                                                       // gap between them
        header_stack.translatesAutoresizingMaskIntoConstraints = false                  // pinned below
        view.addSubview(header_stack)                                                   // put it on screen

        table_view.dataSource = self                                                               // we provide the rows
        table_view.delegate = self                                                                 // we handle taps
        table_view.register(book_cell.self, forCellReuseIdentifier: book_cell.reuse_identifier)    // tell the table about our custom cell
        table_view.rowHeight = UITableView.automaticDimension                                      // rows size themselves from auto layout
        table_view.estimatedRowHeight = 106                                                        // rough guess so scrolling is smooth
        table_view.backgroundColor = app_theme.background_color                                    // match the page
        table_view.allowsSelectionDuringEditing = true                                             // in edit mode tapping a row opens edit book
        table_view.translatesAutoresizingMaskIntoConstraints = false                               // pinned below
        view.addSubview(table_view)                                                                // put it on screen

        let safe_area = view.safeAreaLayoutGuide                                             // area that avoids the notch and home bar
        NSLayoutConstraint.activate([                                                        // turn on constraints
            header_stack.topAnchor.constraint(equalTo: safe_area.topAnchor, constant: 8),    // just under the search bar
            header_stack.leadingAnchor.constraint(equalTo: safe_area.leadingAnchor, constant: app_theme.side_padding),    // left margin
            header_stack.trailingAnchor.constraint(equalTo: safe_area.trailingAnchor, constant: -app_theme.side_padding),    // right margin
            table_view.topAnchor.constraint(equalTo: header_stack.bottomAnchor),             // table starts under the header
            table_view.leadingAnchor.constraint(equalTo: view.leadingAnchor),                // full width left
            table_view.trailingAnchor.constraint(equalTo: view.trailingAnchor),              // full width right
            table_view.bottomAnchor.constraint(equalTo: view.bottomAnchor)                   // all the way down
        ])
    }

    // 10/31/26 rebuilds the sort menu so the current option has a checkmark
    private func update_sort_menu() {
        sort_button.configuration?.title = current_sort.rawValue    // button text = current sort
        let menu_actions = sort_option.allCases.map { option in     // one menu item per sort option
            UIAction(title: option.rawValue, state: option == current_sort ? .on : .off) { [weak self] _ in    // checkmark on the current one
                self?.current_sort = option                         // remember the new sort
                self?.update_sort_menu()                            // move the checkmark
                self?.apply_filters()                               // resort the table
            }
        }
        sort_button.menu = UIMenu(children: menu_actions)    // attach the menu
    }

    // 10/31/26 search + filter + sort, then reload the table
    private func apply_filters() {
        var filtered_books = book_store.shared.books    // start with everything

        switch filter_control.selectedSegmentIndex {                                 // which segment is picked
        case 1: filtered_books = filtered_books.filter { $0.status == .reading }     // Reading
        case 2: filtered_books = filtered_books.filter { $0.status == .on_hold }     // On hold
        case 3: filtered_books = filtered_books.filter { $0.status == .finished }    // Finished
        default: break                                                               // All, keep everything
        }

        let cleaned_search = search_text.trimmingCharacters(in: .whitespaces).lowercased()    // ignore spaces and caps
        if !cleaned_search.isEmpty {                                                          // only filter if they actually typed something
            filtered_books = filtered_books.filter { $0.title.lowercased().contains(cleaned_search) || $0.author.lowercased().contains(cleaned_search) }    // match title or author
        }

        switch current_sort {                                                             // apply the sort
        case .recently_opened: filtered_books.sort { $0.last_opened > $1.last_opened }    // newest first
        case .title: filtered_books.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }    // a to z ignoring caps
        case .progress: filtered_books.sort { $0.progress > $1.progress }                 // most read first
        }

        visible_books = filtered_books                                                             // save the result
        count_label.text = visible_books.count == 1 ? "1 book" : "\(visible_books.count) books"    // 1 book vs 7 books
        table_view.reloadData()                                                                    // redraw the table
    }

    override func setEditing(_ editing: Bool, animated: Bool) {    // uikit calls this when Edit / Done is tapped
        super.setEditing(editing, animated: animated)              // flips the button text between Edit and Done
        table_view.setEditing(editing, animated: animated)         // show or hide the red delete circles
    }

    func updateSearchResults(for searchController: UISearchController) {    // UISearchResultsUpdating, runs on every keystroke
        search_text = searchController.searchBar.text ?? ""                 // grab what they typed
        apply_filters()                                                     // refilter
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {    // UITableViewDataSource, how many rows
        visible_books.count                                                                  // one row per book showing
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {    // UITableViewDataSource, build one row
        guard let cell = tableView.dequeueReusableCell(withIdentifier: book_cell.reuse_identifier, for: indexPath) as? book_cell else { return UITableViewCell() }    // reuse a cell, plain cell if the cast fails
        cell.configure(with: visible_books[indexPath.row])                                              // fill it with this book
        return cell                                                                                     // give it to the table
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {    // UITableViewDelegate, a row got tapped
        tableView.deselectRow(at: indexPath, animated: true)                           // fade the highlight
        let selected_book = visible_books[indexPath.row]                               // which book
        if tableView.isEditing {                                                       // in edit mode, tapping edits the book
            open_edit_book(book_id: selected_book.id)                                  // go to edit book
        } else {                                                                       // normal mode, tapping reads the book
            navigationController?.pushViewController(reader_view_controller(book_id: selected_book.id), animated: true)    // go to the reader
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {    // swipe to delete or the red delete button
        guard editingStyle == .delete else { return }                         // only handle deletes
        book_store.shared.delete(book_id: visible_books[indexPath.row].id)    // remove it, the store notification reloads the table
    }

    // 10/31/26 opens edit book as a sheet, nil id = add a new book
    func open_edit_book(book_id: UUID?) {
        let edit_screen = edit_book_view_controller(book_id: book_id)                       // make the form
        present(UINavigationController(rootViewController: edit_screen), animated: true)    // wrap in a nav controller for cancel / save
    }
}
