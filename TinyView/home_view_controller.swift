import UIKit    // uikit for view controllers, stack views and buttons

// 10/31/26 screen 1, the home dashboard and root of the navigation stack
final class home_view_controller: UIViewController {
    private let scroll_view = UIScrollView()                                                            // lets home scroll on smaller phones
    private let content_stack = UIStackView()                                                           // one big vertical stack holding every section
    private let cover_image_view = UIImageView()                                                        // cover in the continue reading card
    private let book_title_label = app_theme.make_label(size: 22, weight: .semibold, lines: 2)          // title in the card
    private let author_label = app_theme.make_label(size: 14, color: app_theme.secondary_text_color)    // author line in the card
    private let progress_view = UIProgressView(progressViewStyle: .default)                             // progress bar in the card
    private let progress_label = app_theme.make_label(size: 13, color: app_theme.secondary_text_color)    // page 48 of 160 · 30%
    private let library_count_label = app_theme.make_label(size: 14, color: app_theme.secondary_text_color)    // 7 books
    private let stats_stack = UIStackView()                                                             // the 3 stat tiles row

    // 10/31/26 nav bar stuff goes in init so its set even if a screen gets pushed before home finishes loading
    init() {
        super.init(nibName: nil, bundle: nil)             // built in code, no storyboard
        title = "TinyView"                                // big title at the top
        navigationItem.largeTitleDisplayMode = .always    // keep it big on home
        navigationItem.backButtonTitle = "Home"           // the back button on the next screen says Home instead of TinyView
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in self?.open_add_book() })    // + in the corner opens add book, weak self so we dont leak memory
    }

    required init?(coder: NSCoder) {                               // storyboard init, not used
        fatalError("home_view_controller is made in code only")    // crash loudly if someone tries
    }

    override func viewDidLoad() {                            // uikit calls this once when the screen first loads
        super.viewDidLoad()                                  // let uikit do its thing first
        view.backgroundColor = app_theme.background_color    // warm background
        build_layout()                                       // make all the views
        refresh_content()                                    // fill them with the sample data
        NotificationCenter.default.addObserver(self, selector: #selector(handle_store_change), name: .book_store_did_change, object: nil)    // refresh if a book gets edited somewhere else
    }

    @objc private func handle_store_change() {    // gets called when the store posts a change
        refresh_content()                         // redraw with the new data
    }

    // 10/31/26 builds the whole screen, scroll view > stack view > sections
    private func build_layout() {
        scroll_view.translatesAutoresizingMaskIntoConstraints = false    // we size it with constraints
        scroll_view.alwaysBounceVertical = true                          // bounces even if everything fits, feels more natural
        view.addSubview(scroll_view)                                     // put it on screen

        content_stack.axis = .vertical                                     // sections go top to bottom
        content_stack.spacing = app_theme.section_spacing                  // same gap between every section
        content_stack.isLayoutMarginsRelativeArrangement = true            // respect the padding we set below
        content_stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: app_theme.side_padding, bottom: 32, trailing: app_theme.side_padding)    // padding around everything
        content_stack.translatesAutoresizingMaskIntoConstraints = false    // we size it with constraints
        scroll_view.addSubview(content_stack)                              // the stack lives inside the scroll view

        NSLayoutConstraint.activate([                                                                  // turn on all the constraints
            scroll_view.topAnchor.constraint(equalTo: view.topAnchor),                                 // scroll view fills the screen top
            scroll_view.leadingAnchor.constraint(equalTo: view.leadingAnchor),                         // left
            scroll_view.trailingAnchor.constraint(equalTo: view.trailingAnchor),                       // right
            scroll_view.bottomAnchor.constraint(equalTo: view.bottomAnchor),                           // bottom
            content_stack.topAnchor.constraint(equalTo: scroll_view.contentLayoutGuide.topAnchor),     // stack starts at the top of the scrollable area
            content_stack.leadingAnchor.constraint(equalTo: scroll_view.contentLayoutGuide.leadingAnchor),    // left
            content_stack.trailingAnchor.constraint(equalTo: scroll_view.contentLayoutGuide.trailingAnchor),    // right
            content_stack.bottomAnchor.constraint(equalTo: scroll_view.contentLayoutGuide.bottomAnchor),    // stack height = how far you can scroll
            content_stack.widthAnchor.constraint(equalTo: scroll_view.frameLayoutGuide.widthAnchor)    // same width as the screen so it never scrolls sideways
        ])

        let subtitle_label = app_theme.make_label("A little time. Another world.", size: 16, color: app_theme.secondary_text_color)    // tagline from the figma
        content_stack.addArrangedSubview(subtitle_label)             // section 1, tagline
        content_stack.setCustomSpacing(16, after: subtitle_label)    // tagline sits a little closer to the card
        content_stack.addArrangedSubview(make_continue_card())       // section 2, continue reading card
        let section_header = make_section_header()                   // your library + book count
        content_stack.addArrangedSubview(section_header)             // section 3
        content_stack.setCustomSpacing(12, after: section_header)    // header hugs the tiles below it

        stats_stack.axis = .horizontal                            // tiles side by side
        stats_stack.distribution = .fillEqually                   // all 3 tiles same width no matter the phone
        stats_stack.spacing = 10                                  // gap between tiles
        content_stack.addArrangedSubview(stats_stack)             // section 4, stat tiles (filled in refresh_content)
        content_stack.addArrangedSubview(make_browse_row())       // section 5, browse library
        content_stack.addArrangedSubview(make_import_button())    // section 6, import from files
        content_stack.addArrangedSubview(make_offline_note())     // section 7, little footer note
    }

    // 10/31/26 the continue reading card (cover on the left, details + resume button on the right)
    private func make_continue_card() -> UIView {
        let card_view = UIView()                                  // the rounded background
        card_view.backgroundColor = app_theme.card_color          // slightly darker than the page
        card_view.layer.cornerRadius = app_theme.corner_radius    // rounded corners

        cover_image_view.contentMode = .scaleAspectFill                       // fill without stretching
        cover_image_view.clipsToBounds = true                                 // cut off the overflow
        cover_image_view.layer.cornerRadius = 6                               // rounded cover corners
        cover_image_view.translatesAutoresizingMaskIntoConstraints = false    // fixed size below

        let eyebrow_label = app_theme.make_label("CONTINUE READING", size: 12, weight: .semibold, color: app_theme.accent_color)    // small orange heading
        progress_view.progressTintColor = app_theme.accent_color    // filled part
        progress_view.trackTintColor = app_theme.border_color       // empty part

        var resume_configuration = UIButton.Configuration.filled()                   // solid filled button style
        resume_configuration.title = "Resume reading"                                // button text
        resume_configuration.image = UIImage(systemName: "book")                     // little book icon
        resume_configuration.imagePadding = 6                                        // gap between icon and text
        resume_configuration.baseBackgroundColor = app_theme.accent_color            // terracotta background
        resume_configuration.baseForegroundColor = .white                            // white text and icon
        resume_configuration.cornerStyle = .medium                                   // rounded like the figma
        let resume_button = UIButton(configuration: resume_configuration, primaryAction: UIAction { [weak self] _ in self?.open_continue_book() })    // tap opens the reader
        let button_row = UIStackView(arrangedSubviews: [resume_button, UIView()])    // empty view on the right acts as a spacer so the button doesnt stretch
        button_row.axis = .horizontal                                                // button then spacer

        let text_stack = UIStackView(arrangedSubviews: [eyebrow_label, book_title_label, author_label, progress_view, progress_label, button_row])    // right column of the card
        text_stack.axis = .vertical                               // top to bottom
        text_stack.spacing = 6                                    // default gap
        text_stack.setCustomSpacing(10, after: author_label)      // little room above the bar
        text_stack.setCustomSpacing(12, after: progress_label)    // little room above the button

        let card_stack = UIStackView(arrangedSubviews: [cover_image_view, text_stack])    // cover then text
        card_stack.axis = .horizontal                                                     // side by side
        card_stack.spacing = 16                                                           // gap between them
        card_stack.alignment = .center                                                    // center the cover vertically
        card_stack.translatesAutoresizingMaskIntoConstraints = false                      // pinned below
        card_view.addSubview(card_stack)                                                  // put the content in the card

        NSLayoutConstraint.activate([                                                                  // turn on the constraints
            cover_image_view.widthAnchor.constraint(equalToConstant: 96),                              // cover width from the figma
            cover_image_view.heightAnchor.constraint(equalToConstant: 138),                            // cover height from the figma
            card_stack.topAnchor.constraint(equalTo: card_view.topAnchor, constant: 16),               // inner padding top
            card_stack.leadingAnchor.constraint(equalTo: card_view.leadingAnchor, constant: 16),       // inner padding left
            card_stack.trailingAnchor.constraint(equalTo: card_view.trailingAnchor, constant: -16),    // inner padding right
            card_stack.bottomAnchor.constraint(equalTo: card_view.bottomAnchor, constant: -16)         // inner padding bottom
        ])
        return card_view    // hand back the finished card
    }

    // 10/31/26 "Your library" on the left, book count on the right
    private func make_section_header() -> UIStackView {
        let header_label = app_theme.make_label("Your library", size: 20, weight: .semibold)     // section title
        library_count_label.setContentHuggingPriority(.required, for: .horizontal)               // count stays small so the title takes the space
        let header_stack = UIStackView(arrangedSubviews: [header_label, library_count_label])    // title then count
        header_stack.axis = .horizontal                                                          // side by side
        header_stack.alignment = .firstBaseline                                                  // line up the bottoms of the text
        return header_stack                                                                      // hand it back
    }

    // 10/31/26 one stat tile, big number on top + status underneath
    private func make_stat_tile(for status: reading_status, count: Int) -> UIView {
        let tile_view = UIView()                                            // the tile background
        tile_view.backgroundColor = app_theme.surface_color                 // white
        tile_view.layer.cornerRadius = 12                                   // rounded
        tile_view.layer.borderWidth = 1                                     // thin border
        tile_view.layer.borderColor = app_theme.border_color.cgColor        // light border color
        tile_view.isAccessibilityElement = true                             // voiceover reads the whole tile as one thing
        tile_view.accessibilityLabel = "\(count) \(status.display_name)"    // ex: 3 Reading

        let count_label = UILabel()                             // the big number
        count_label.text = "\(count)"                           // number of books in this status
        count_label.font = UIFontMetrics.default.scaledFont(for: UIFont(name: "Georgia", size: 28) ?? .systemFont(ofSize: 28))    // serif number like the figma
        count_label.adjustsFontForContentSizeCategory = true    // grows with text size setting
        count_label.textColor = app_theme.primary_text_color    // dark text

        let tile_stack = UIStackView(arrangedSubviews: [count_label, app_theme.make_status_row(for: status)])    // number then status
        tile_stack.axis = .vertical                                     // top to bottom
        tile_stack.alignment = .leading                                 // left aligned like the figma
        tile_stack.spacing = 6                                          // gap between number and status
        tile_stack.translatesAutoresizingMaskIntoConstraints = false    // pinned below
        tile_view.addSubview(tile_stack)                                // put it in the tile

        NSLayoutConstraint.activate([                                                               // turn on constraints
            tile_view.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),                    // at least 80 tall, can grow with big text
            tile_stack.topAnchor.constraint(equalTo: tile_view.topAnchor, constant: 12),            // padding top
            tile_stack.leadingAnchor.constraint(equalTo: tile_view.leadingAnchor, constant: 14),    // padding left
            tile_stack.trailingAnchor.constraint(lessThanOrEqualTo: tile_view.trailingAnchor, constant: -10),    // dont run off the right side
            tile_stack.bottomAnchor.constraint(lessThanOrEqualTo: tile_view.bottomAnchor, constant: -12)    // dont run off the bottom
        ])
        return tile_view    // hand back the tile
    }

    // 10/31/26 the browse library row, whole thing is tappable
    private func make_browse_row() -> UIControl {
        let row_control = UIControl()                                     // UIControl so the whole row can be tapped like a button
        row_control.backgroundColor = app_theme.surface_color             // white
        row_control.layer.cornerRadius = app_theme.corner_radius          // rounded
        row_control.layer.borderWidth = 1                                 // thin border
        row_control.layer.borderColor = app_theme.border_color.cgColor    // light border color
        row_control.isAccessibilityElement = true                         // voiceover treats it as one button
        row_control.accessibilityLabel = "Browse library"                 // what voiceover says
        row_control.accessibilityTraits = .button                         // tells voiceover its a button
        row_control.addAction(UIAction { [weak self] _ in self?.open_library() }, for: .touchUpInside)    // tap goes to the library

        let icon_well = UIView()                                                     // the little square behind the icon
        icon_well.backgroundColor = app_theme.card_color                             // light fill
        icon_well.layer.cornerRadius = 10                                            // rounded
        icon_well.translatesAutoresizingMaskIntoConstraints = false                  // fixed size below
        let icon_view = UIImageView(image: UIImage(systemName: "books.vertical"))    // bookshelf icon
        icon_view.tintColor = app_theme.accent_color                                 // orange icon
        icon_view.contentMode = .scaleAspectFit                                      // dont stretch it
        icon_view.translatesAutoresizingMaskIntoConstraints = false                  // centered below
        icon_well.addSubview(icon_view)                                              // icon goes inside the square

        let title_label = app_theme.make_label("Browse library", size: 16, weight: .semibold)    // row title
        let detail_label = app_theme.make_label("Search, sort and organize your books", size: 13, color: app_theme.secondary_text_color, lines: 0)    // row subtitle, can wrap
        let text_stack = UIStackView(arrangedSubviews: [title_label, detail_label])              // title over subtitle
        text_stack.axis = .vertical                                                              // top to bottom
        text_stack.spacing = 2                                                                   // tight gap

        let chevron_view = UIImageView(image: UIImage(systemName: "chevron.right"))    // > on the right
        chevron_view.tintColor = app_theme.secondary_text_color                        // gray
        chevron_view.setContentHuggingPriority(.required, for: .horizontal)            // stays its natural size

        let row_stack = UIStackView(arrangedSubviews: [icon_well, text_stack, chevron_view])    // icon, text, chevron
        row_stack.axis = .horizontal                                                            // side by side
        row_stack.spacing = 14                                                                  // gap between them
        row_stack.alignment = .center                                                           // everything centered vertically
        row_stack.isUserInteractionEnabled = false                                              // let taps fall through to the UIControl underneath
        row_stack.translatesAutoresizingMaskIntoConstraints = false                             // pinned below
        row_control.addSubview(row_stack)                                                       // put it in the row

        NSLayoutConstraint.activate([                                                                   // turn on constraints
            icon_well.widthAnchor.constraint(equalToConstant: 40),                                      // square width
            icon_well.heightAnchor.constraint(equalToConstant: 40),                                     // square height
            icon_view.centerXAnchor.constraint(equalTo: icon_well.centerXAnchor),                       // icon centered left/right
            icon_view.centerYAnchor.constraint(equalTo: icon_well.centerYAnchor),                       // icon centered up/down
            icon_view.widthAnchor.constraint(equalToConstant: 22),                                      // icon size
            icon_view.heightAnchor.constraint(equalToConstant: 22),                                     // icon size
            row_stack.topAnchor.constraint(equalTo: row_control.topAnchor, constant: 14),               // padding top
            row_stack.leadingAnchor.constraint(equalTo: row_control.leadingAnchor, constant: 16),       // padding left
            row_stack.trailingAnchor.constraint(equalTo: row_control.trailingAnchor, constant: -16),    // padding right
            row_stack.bottomAnchor.constraint(equalTo: row_control.bottomAnchor, constant: -14)         // padding bottom
        ])
        return row_control    // hand back the row
    }

    // 10/31/26 outlined import button, opens the add book screen for now (real file picker is milestone 3)
    private func make_import_button() -> UIButton {
        var import_configuration = UIButton.Configuration.plain()                 // plain style so we can draw our own border
        import_configuration.title = "Import from Files"                          // button text
        import_configuration.image = UIImage(systemName: "plus")                  // + icon
        import_configuration.imagePadding = 8                                     // gap between icon and text
        import_configuration.baseForegroundColor = app_theme.accent_color         // orange text and icon
        import_configuration.cornerStyle = .fixed                                 // needed so our corner radius below actually gets used
        import_configuration.background.cornerRadius = app_theme.corner_radius    // rounded corners
        import_configuration.background.strokeColor = app_theme.accent_color      // orange outline
        import_configuration.background.strokeWidth = 1.5                         // outline thickness
        import_configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)    // makes the button taller
        return UIButton(configuration: import_configuration, primaryAction: UIAction { [weak self] _ in self?.open_add_book() })    // tap opens add book
    }

    // 10/31/26 small centered note at the bottom
    private func make_offline_note() -> UILabel {
        let note_label = UILabel()                                                                     // the label
        let check_image = UIImage(systemName: "checkmark.circle")?.withTintColor(app_theme.secondary_text_color, renderingMode: .alwaysOriginal) ?? UIImage()    // gray check icon, empty image if it somehow fails
        let note_text = NSMutableAttributedString(attachment: NSTextAttachment(image: check_image))    // start the text with the icon
        note_text.append(NSAttributedString(string: "  All books available offline · CBZ, PDF"))       // then the words
        note_text.addAttributes([.font: UIFont.systemFont(ofSize: 12), .foregroundColor: app_theme.secondary_text_color], range: NSRange(location: 0, length: note_text.length))    // small gray text for the whole thing
        note_label.attributedText = note_text                                                          // put it on the label
        note_label.textAlignment = .center                                                             // centered like the figma
        return note_label                                                                              // hand it back
    }

    // 10/31/26 fills everything with the latest data from the store
    private func refresh_content() {
        let store = book_store.shared                                                    // shortcut so lines dont get crazy long
        if let current_book = store.continue_reading_book {                              // only fill the card if someone is reading something
            cover_image_view.image = app_theme.make_cover_image(for: current_book, size: CGSize(width: 192, height: 276))    // 2x size so its sharp
            book_title_label.text = current_book.title                                   // title
            author_label.text = "\(current_book.author) · \(current_book.collection)"    // ex: Nora Ellis · Volume 1
            progress_view.progress = current_book.progress                               // fill the bar
            progress_label.text = "Page \(current_book.current_page) of \(current_book.total_pages) · \(current_book.percent_text)"    // ex: Page 48 of 160 · 30%
        }
        library_count_label.text = "\(store.books.count) books"              // total books
        stats_stack.arrangedSubviews.forEach { $0.removeFromSuperview() }    // clear the old tiles first
        for status in [reading_status.reading, .on_hold, .finished] {        // the 3 tiles from the figma
            stats_stack.addArrangedSubview(make_stat_tile(for: status, count: store.count(for: status)))    // make a tile with the current count
        }
    }

    // 10/31/26 navigation, push = slide in from the right, present = slide up as a sheet
    func open_continue_book() {                                                             // resume reading button lands here
        guard let current_book = book_store.shared.continue_reading_book else { return }    // nothing being read, nothing to open
        navigationController?.pushViewController(reader_view_controller(book_id: current_book.id), animated: true)    // go to the reader
    }

    func open_library() {                                                                      // browse library row lands here
        navigationController?.pushViewController(library_view_controller(), animated: true)    // go to the library
    }

    func open_add_book() {                                                                 // + button and import button land here
        let add_screen = edit_book_view_controller(book_id: nil)                           // nil id = add mode instead of edit mode
        present(UINavigationController(rootViewController: add_screen), animated: true)    // wrap it in a nav controller so it gets cancel and save buttons on top
    }
}
