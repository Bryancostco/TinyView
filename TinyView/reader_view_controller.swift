import UIKit    // uikit for the scroll view, slider and gestures

// 10/31/26 screen 3, the reader (detail screen for one book)
// pages are drawn in code for now, real cbz / pdf rendering is milestone 3
final class reader_view_controller: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    private let book_id: UUID                      // which book were reading
    private var current_page = 1                   // page on screen
    private var total_pages = 1                    // pages in the book
    private var is_right_to_left = false           // manga mode flips the page direction
    private var is_bookmarked = false              // bookmark button state
    private var controls_visible = true            // is the bottom bar showing
    private var bookmark_item: UIBarButtonItem?    // kept so we can swap its icon

    private let page_scroll_view = UIScrollView()                                             // scroll view gives us pinch zoom for free
    private let page_image_view = UIImageView()                                               // the page itself
    private let controls_view = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))    // frosted glass bottom bar
    private let page_label = app_theme.make_label(size: 15, weight: .semibold)                // page 48 of 160
    private let page_slider = UISlider()                                                      // scrubber to jump pages
    private let mode_control = UISegmentedControl(items: ["Single", "Spread", "Vertical"])    // reading mode
    private let previous_button = UIButton(type: .system)                                     // < button
    private let next_button = UIButton(type: .system)                                         // > button

    init(book_id: UUID) {                        // custom init so whoever opens the reader has to say which book
        self.book_id = book_id                   // save it
        super.init(nibName: nil, bundle: nil)    // nil nib = built in code, no storyboard
    }

    required init?(coder: NSCoder) {                                 // storyboard init, not used
        fatalError("reader_view_controller is made in code only")    // crash loudly if someone tries
    }

    override func viewDidLoad() {                            // uikit calls this once when the screen loads
        super.viewDidLoad()                                  // let uikit do its thing first
        view.backgroundColor = app_theme.background_color    // warm background
        navigationItem.largeTitleDisplayMode = .never        // small title, the page needs the room

        guard let current_book = book_store.shared.book(with: book_id) else { return }    // book got deleted somehow, bail
        title = current_book.title                                                        // book title in the nav bar
        total_pages = max(1, current_book.total_pages)                                    // at least 1 page so the slider doesnt break
        current_page = max(1, current_book.current_page)                                  // pick up where they left off
        is_right_to_left = current_book.is_right_to_left                                  // manga or not

        let edit_item = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(open_edit_book))    // pencil opens edit book
        edit_item.accessibilityLabel = "Edit book"                                // voiceover label
        let bookmark_button_item = UIBarButtonItem(image: UIImage(systemName: "bookmark"), style: .plain, target: self, action: #selector(toggle_bookmark))    // bookmark toggle
        bookmark_button_item.accessibilityLabel = "Bookmark page"                 // voiceover label
        bookmark_item = bookmark_button_item                                      // save it so we can change the icon later
        navigationItem.rightBarButtonItems = [edit_item, bookmark_button_item]    // pencil on the far right, bookmark next to it

        build_layout()                                    // make the views
        add_gestures()                                    // tap, double tap, swipe
        go_to_page(current_page, save_progress: false)    // draw the first page, dont save since nothing changed yet
        NotificationCenter.default.addObserver(self, selector: #selector(handle_store_change), name: .book_store_did_change, object: nil)    // pick up title edits
    }

    override func viewWillDisappear(_ animated: Bool) {                            // about to leave the reader
        super.viewWillDisappear(animated)                                          // let uikit do its thing
        navigationController?.setNavigationBarHidden(false, animated: animated)    // bring the nav bar back if we hid it, otherwise the library loses its bar
    }

    @objc private func handle_store_change() {                                            // the book might have been edited
        guard let current_book = book_store.shared.book(with: book_id) else { return }    // book is gone, nothing to update
        title = current_book.title                                                        // new title if they changed it
        is_right_to_left = current_book.is_right_to_left                                  // new direction if they flipped it
    }

    // 10/31/26 page fills the middle, frosted control bar at the bottom
    private func build_layout() {
        page_scroll_view.delegate = self                                      // so we can tell it which view zooms
        page_scroll_view.minimumZoomScale = 1                                 // cant shrink smaller than fit
        page_scroll_view.maximumZoomScale = 4                                 // up to 4x zoom
        page_scroll_view.showsHorizontalScrollIndicator = false               // hide the scroll bars
        page_scroll_view.showsVerticalScrollIndicator = false                 // hide the scroll bars
        page_scroll_view.translatesAutoresizingMaskIntoConstraints = false    // pinned below
        view.addSubview(page_scroll_view)                                     // put it on screen

        page_image_view.contentMode = .scaleAspectFit                                             // whole page visible, no stretching
        page_image_view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)      // 10/31/26 page gives up space before the control bar does, was squishing the bar
        page_image_view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)    // same thing sideways
        page_image_view.setContentHuggingPriority(.defaultLow, for: .vertical)                    // page is allowed to stretch to fill the space
        page_image_view.isAccessibilityElement = true                                             // voiceover can find the page
        page_image_view.translatesAutoresizingMaskIntoConstraints = false                         // pinned below
        page_scroll_view.addSubview(page_image_view)                                              // page lives in the scroll view

        var previous_configuration = UIButton.Configuration.plain()               // plain icon button
        previous_configuration.image = UIImage(systemName: "chevron.left")        // <
        previous_button.configuration = previous_configuration                    // apply it
        previous_button.accessibilityLabel = "Page to the left"                   // voiceover label
        previous_button.addAction(UIAction { [weak self] _ in self?.tap_left_side() }, for: .touchUpInside)    // tap turns the page
        previous_button.setContentHuggingPriority(.required, for: .horizontal)    // stays small

        var next_configuration = UIButton.Configuration.plain()               // plain icon button
        next_configuration.image = UIImage(systemName: "chevron.right")       // >
        next_button.configuration = next_configuration                        // apply it
        next_button.accessibilityLabel = "Page to the right"                  // voiceover label
        next_button.addAction(UIAction { [weak self] _ in self?.tap_right_side() }, for: .touchUpInside)    // tap turns the page
        next_button.setContentHuggingPriority(.required, for: .horizontal)    // stays small

        page_label.textAlignment = .center    // centered between the arrows
        page_label.font = UIFontMetrics.default.scaledFont(for: .monospacedDigitSystemFont(ofSize: 15, weight: .semibold))    // numbers dont wiggle as they change

        page_slider.minimumValue = 1                                  // first page
        page_slider.maximumValue = Float(total_pages)                 // last page
        page_slider.minimumTrackTintColor = app_theme.accent_color    // read part is orange
        page_slider.accessibilityLabel = "Page"                       // voiceover label
        page_slider.addAction(UIAction { [weak self] _ in             // fires while dragging
            guard let self = self else { return }                     // screen is gone, skip
            self.go_to_page(Int(self.page_slider.value.rounded()))    // jump to the nearest whole page
        }, for: .valueChanged)                                        // valueChanged fires on every slider move

        mode_control.selectedSegmentIndex = 0                           // start on Single
        mode_control.addAction(UIAction { [weak self] _ in              // fires when they switch modes
            guard let self = self else { return }                       // screen is gone, skip
            self.go_to_page(self.current_page, save_progress: false)    // redraw the same page in the new mode
        }, for: .valueChanged)                                          // fires when a segment is tapped

        let page_row = UIStackView(arrangedSubviews: [previous_button, page_label, next_button])    // < page x of y >
        page_row.axis = .horizontal                                                                 // side by side
        page_row.alignment = .center                                                                // centered vertically

        let controls_stack = UIStackView(arrangedSubviews: [page_row, page_slider, mode_control])    // the 3 rows in the bar
        controls_stack.axis = .vertical                                                              // top to bottom
        controls_stack.spacing = 12                                                                  // gap between rows
        controls_stack.translatesAutoresizingMaskIntoConstraints = false                             // pinned below
        controls_view.contentView.addSubview(controls_stack)                                         // blur views want subviews in contentView

        controls_view.layer.cornerRadius = 18                              // rounded bar
        controls_view.clipsToBounds = true                                 // blur respects the rounded corners
        controls_view.translatesAutoresizingMaskIntoConstraints = false    // pinned below
        view.addSubview(controls_view)                                     // put it on screen above the page

        let safe_area = view.safeAreaLayoutGuide                                                 // avoids the notch and home bar
        NSLayoutConstraint.activate([                                                            // turn on constraints
            page_scroll_view.topAnchor.constraint(equalTo: safe_area.topAnchor, constant: 8),    // page starts under the nav bar
            page_scroll_view.leadingAnchor.constraint(equalTo: safe_area.leadingAnchor, constant: 12),    // left margin
            page_scroll_view.trailingAnchor.constraint(equalTo: safe_area.trailingAnchor, constant: -12),    // right margin
            page_scroll_view.bottomAnchor.constraint(equalTo: controls_view.topAnchor, constant: -10),    // stops above the bar so the bar never covers the page

            page_image_view.topAnchor.constraint(equalTo: page_scroll_view.contentLayoutGuide.topAnchor),    // page fills the scroll content
            page_image_view.leadingAnchor.constraint(equalTo: page_scroll_view.contentLayoutGuide.leadingAnchor),    // left
            page_image_view.trailingAnchor.constraint(equalTo: page_scroll_view.contentLayoutGuide.trailingAnchor),    // right
            page_image_view.bottomAnchor.constraint(equalTo: page_scroll_view.contentLayoutGuide.bottomAnchor),    // bottom
            page_image_view.widthAnchor.constraint(equalTo: page_scroll_view.frameLayoutGuide.widthAnchor),    // same size as the visible area when not zoomed
            page_image_view.heightAnchor.constraint(equalTo: page_scroll_view.frameLayoutGuide.heightAnchor),    // same size as the visible area when not zoomed

            controls_view.leadingAnchor.constraint(equalTo: safe_area.leadingAnchor, constant: app_theme.side_padding),    // bar left margin
            controls_view.trailingAnchor.constraint(equalTo: safe_area.trailingAnchor, constant: -app_theme.side_padding),    // bar right margin
            controls_view.bottomAnchor.constraint(equalTo: safe_area.bottomAnchor, constant: -12),    // bar floats above the home indicator

            controls_stack.topAnchor.constraint(equalTo: controls_view.contentView.topAnchor, constant: 12),    // inner padding top
            controls_stack.leadingAnchor.constraint(equalTo: controls_view.contentView.leadingAnchor, constant: 12),    // inner padding left
            controls_stack.trailingAnchor.constraint(equalTo: controls_view.contentView.trailingAnchor, constant: -12),    // inner padding right
            controls_stack.bottomAnchor.constraint(equalTo: controls_view.contentView.bottomAnchor, constant: -14)    // inner padding bottom
        ])
    }

    // 10/31/26 tap = show/hide controls, double tap = zoom, swipe = turn page
    private func add_gestures() {
        let double_tap = UITapGestureRecognizer(target: self, action: #selector(handle_double_tap(_:)))    // double tap to zoom
        double_tap.numberOfTapsRequired = 2                  // needs 2 taps
        page_scroll_view.addGestureRecognizer(double_tap)    // listen on the page

        let single_tap = UITapGestureRecognizer(target: self, action: #selector(toggle_controls))    // single tap toggles the bar
        single_tap.require(toFail: double_tap)                                                       // wait to make sure it wasnt a double tap first
        page_scroll_view.addGestureRecognizer(single_tap)                                            // listen on the page

        let swipe_left = UISwipeGestureRecognizer(target: self, action: #selector(handle_swipe_left))    // finger moves right to left
        swipe_left.direction = .left                         // direction of the finger
        swipe_left.delegate = self                           // so it can work alongside the scroll view
        page_scroll_view.addGestureRecognizer(swipe_left)    // listen on the page

        let swipe_right = UISwipeGestureRecognizer(target: self, action: #selector(handle_swipe_right))    // finger moves left to right
        swipe_right.direction = .right                        // direction of the finger
        swipe_right.delegate = self                           // so it can work alongside the scroll view
        page_scroll_view.addGestureRecognizer(swipe_right)    // listen on the page
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {    // UIGestureRecognizerDelegate
        true    // let swipes and the scroll views own pan both run, otherwise the scroll view eats the swipe
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {    // UIScrollViewDelegate, which view gets zoomed
        page_image_view                                              // zoom the page
    }

    // 10/31/26 page direction, left side goes back for normal books but forward for manga
    private func tap_left_side() {
        turn_page(by: is_right_to_left ? 1 : -1)    // manga reads right to left so left = next
    }

    private func tap_right_side() {                 // right arrow
        turn_page(by: is_right_to_left ? -1 : 1)    // normal books right = next
    }

    @objc private func handle_swipe_left() {                     // finger went right to left, same as tapping the right side
        guard page_scroll_view.zoomScale == 1 else { return }    // dont turn pages while zoomed in, they probably meant to pan
        tap_right_side()                                         // turn the page
    }

    @objc private func handle_swipe_right() {                    // finger went left to right, same as tapping the left side
        guard page_scroll_view.zoomScale == 1 else { return }    // dont turn pages while zoomed in
        tap_left_side()                                          // turn the page
    }

    private func turn_page(by offset: Int) {                         // +1 = next page, -1 = previous page
        let step = mode_control.selectedSegmentIndex == 1 ? 2 : 1    // spread mode moves 2 pages at a time
        go_to_page(current_page + offset * step)                     // go there
    }

    // 10/31/26 the main page function, everything that changes pages ends up here
    private func go_to_page(_ page_number: Int, save_progress: Bool = true) {
        current_page = min(max(page_number, 1), total_pages)                                            // keep it between page 1 and the last page
        page_scroll_view.setZoomScale(1, animated: false)                                               // reset zoom on a new page
        page_image_view.image = render_current_page()                                                   // draw it
        page_image_view.accessibilityLabel = "Page \(current_page)"                                     // voiceover reads the page number
        page_label.text = "Page \(current_page) of \(total_pages)"                                      // update the label
        page_slider.value = Float(current_page)                                                         // move the slider to match
        previous_button.isEnabled = is_right_to_left ? current_page < total_pages : current_page > 1    // gray out the arrow at the start
        next_button.isEnabled = is_right_to_left ? current_page > 1 : current_page < total_pages        // gray out the arrow at the end
        if save_progress { save_reading_progress() }                                                    // remember where they are
    }

    // 10/31/26 progress saves on every page turn so there is no save button
    private func save_reading_progress() {
        guard var updated_book = book_store.shared.book(with: book_id) else { return }    // grab a copy, bail if its gone
        updated_book.current_page = current_page                                          // new page
        updated_book.last_opened = Date()                                                 // bumps it to the top of recently opened
        if updated_book.status == .not_started { updated_book.status = .reading }         // first page turn = now reading
        if current_page == total_pages { updated_book.status = .finished }                // hit the last page = finished
        book_store.shared.save(updated_book)                                              // save it back
    }

    // 10/31/26 picks single or spread and draws it
    private func render_current_page() -> UIImage {
        guard let current_book = book_store.shared.book(with: book_id) else { return UIImage() }      // no book, empty image
        let main_page = reader_view_controller.render_page(number: current_page, of: current_book)    // the current page
        guard mode_control.selectedSegmentIndex == 1, current_page < total_pages else { return main_page }    // not spread mode (or last page), just one page

        let facing_page = reader_view_controller.render_page(number: current_page + 1, of: current_book)    // the next page for the spread
        let spread_size = CGSize(width: main_page.size.width * 2 + 8, height: main_page.size.height)    // two pages wide plus a little gutter
        let renderer = UIGraphicsImageRenderer(size: spread_size)                                       // blank canvas for both pages
        return renderer.image { _ in                                                                    // draw both into one image
            let left_page = is_right_to_left ? facing_page : main_page                                  // manga puts the next page on the left
            let right_page = is_right_to_left ? main_page : facing_page                                 // and the current one on the right
            left_page.draw(at: .zero)                                                                   // left half
            right_page.draw(at: CGPoint(x: main_page.size.width + 8, y: 0))                             // right half after the gutter
        }
    }

    // 10/31/26 draws a fake comic page (panels, narration box, speech bubble, page number)
    private static func render_page(number page_number: Int, of item: book_item) -> UIImage {
        let page_size = CGSize(width: 500, height: 708)             // same size as the figma comic page
        let narration_lines = ["The island went quiet as the last ferry left.", "Nobody had climbed the lighthouse in years.", "The light came on anyway.", "She counted the steps out loud.", "Somewhere below, the sea kept time."]    // rotating captions so pages look different
        let dialogue_lines = ["Is anyone up there?", "You came back.", "I saw the light.", "It never really went out.", "Then we should go up."]    // rotating speech bubble text
        let renderer = UIGraphicsImageRenderer(size: page_size)     // blank canvas
        return renderer.image { context in                          // everything in here draws onto the page
            UIColor.white.setFill()                                 // paper color
            context.fill(CGRect(origin: .zero, size: page_size))    // fill the page

            let small_attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: app_theme.secondary_text_color]    // small gray header text
            let chapter_number = (page_number - 1) / 20 + 1                              // pretend every 20 pages is a new chapter
            ("CHAPTER \(chapter_number)" as NSString).draw(at: CGPoint(x: 16, y: 16), withAttributes: small_attributes)    // chapter in the top left
            let title_text = item.title.uppercased() as NSString                         // book title in caps for the top right
            let title_width = title_text.size(withAttributes: small_attributes).width    // measure it so we can right align it
            title_text.draw(at: CGPoint(x: page_size.width - 16 - title_width, y: 16), withAttributes: small_attributes)    // title in the top right

            let top_panel = CGRect(x: 16, y: 40, width: 468, height: 270)              // wide establishing panel
            let left_panel = CGRect(x: 16, y: 318, width: 230, height: 350)            // bottom left panel
            let right_panel = CGRect(x: 254, y: 318, width: 230, height: 350)          // bottom right panel
            let shade = CGFloat(page_number % 4) * 0.08                                // changes the shading a little each page
            item.cover_color.withAlphaComponent(0.95 - shade).setFill()                // darkest panel
            UIBezierPath(roundedRect: top_panel, cornerRadius: 4).fill()               // draw the top panel
            item.cover_color.withAlphaComponent(0.70 - shade).setFill()                // medium panel
            UIBezierPath(roundedRect: left_panel, cornerRadius: 4).fill()              // draw the left panel
            item.cover_color.withAlphaComponent(0.50 - shade / 2).setFill()            // lightest panel
            UIBezierPath(roundedRect: right_panel, cornerRadius: 4).fill()             // draw the right panel
            UIColor.black.setStroke()                                                  // black panel borders like a real comic
            for panel in [top_panel, left_panel, right_panel] {                        // outline every panel
                let border_path = UIBezierPath(roundedRect: panel, cornerRadius: 4)    // panel shape
                border_path.lineWidth = 2                                              // border thickness
                border_path.stroke()                                                   // draw the outline
            }

            let body_attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: app_theme.primary_text_color]    // text inside boxes and bubbles
            let narration_box = CGRect(x: 28, y: 52, width: 206, height: 48)    // caption box in the top panel
            UIColor.white.setFill()                                             // white box
            UIBezierPath(roundedRect: narration_box, cornerRadius: 3).fill()    // draw the box
            (narration_lines[page_number % narration_lines.count] as NSString).draw(in: narration_box.insetBy(dx: 10, dy: 8), withAttributes: body_attributes)    // caption text, picks a line based on the page

            let bubble_rect = CGRect(x: 30, y: 333, width: 160, height: 80)    // speech bubble in the left panel
            UIColor.white.setFill()                                            // 10/31/26 reset to white, drawing the caption text above switched the fill to black
            UIBezierPath(ovalIn: bubble_rect).fill()                           // white oval bubble
            (dialogue_lines[page_number % dialogue_lines.count] as NSString).draw(in: bubble_rect.insetBy(dx: 26, dy: 24), withAttributes: body_attributes)    // bubble text

            let number_text = "\(page_number)" as NSString                                 // printed page number
            let number_width = number_text.size(withAttributes: small_attributes).width    // measure it to center it
            number_text.draw(at: CGPoint(x: (page_size.width - number_width) / 2, y: 684), withAttributes: small_attributes)    // centered at the bottom
        }
    }

    @objc private func toggle_controls() {                                                 // single tap on the page
        controls_visible.toggle()                                                          // flip it
        navigationController?.setNavigationBarHidden(!controls_visible, animated: true)    // hide or show the top bar
        UIView.animate(withDuration: 0.25) {                                               // quick fade
            self.controls_view.alpha = self.controls_visible ? 1 : 0                       // fade the bottom bar
        }
    }

    @objc private func handle_double_tap(_ recognizer: UITapGestureRecognizer) {    // double tap on the page
        if page_scroll_view.zoomScale > 1 {                                         // already zoomed in
            page_scroll_view.setZoomScale(1, animated: true)                        // zoom back out
            return                                                                  // done
        }
        let tap_point = recognizer.location(in: page_image_view)    // where they tapped on the page
        let zoom_size = CGSize(width: page_scroll_view.bounds.width / 2.5, height: page_scroll_view.bounds.height / 2.5)    // area to zoom into (2.5x)
        let zoom_rect = CGRect(x: tap_point.x - zoom_size.width / 2, y: tap_point.y - zoom_size.height / 2, width: zoom_size.width, height: zoom_size.height)    // centered on the tap
        page_scroll_view.zoom(to: zoom_rect, animated: true)        // zoom in there
    }

    @objc private func toggle_bookmark() {                                                          // bookmark button in the nav bar
        is_bookmarked.toggle()                                                                      // flip it (only remembered while the screen is open for now, saving is milestone 3)
        bookmark_item?.image = UIImage(systemName: is_bookmarked ? "bookmark.fill" : "bookmark")    // filled icon when bookmarked
    }

    @objc private func open_edit_book() {                                                   // pencil button in the nav bar
        let edit_screen = edit_book_view_controller(book_id: book_id)                       // edit this book
        present(UINavigationController(rootViewController: edit_screen), animated: true)    // slide up as a sheet
    }
}
