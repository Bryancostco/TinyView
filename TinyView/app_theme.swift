import UIKit    // pulls in uikit (colors, fonts, labels, drawing)

// 10/31/26 shared colors and helpers so every screen matches the figma
enum app_theme {                                                                                  // enum with no cases is just a namespace, cant make one by accident
    static let background_color = UIColor(red: 0.969, green: 0.957, blue: 0.937, alpha: 1)        // warm off white page background
    static let card_color = UIColor(red: 0.937, green: 0.918, blue: 0.890, alpha: 1)              // little darker, used for cards
    static let surface_color = UIColor.white                                                      // white for tiles, rows and cells
    static let accent_color = UIColor(red: 0.761, green: 0.376, blue: 0.227, alpha: 1)            // terracotta, the main brand color
    static let primary_text_color = UIColor(red: 0.110, green: 0.102, blue: 0.090, alpha: 1)      // almost black for main text
    static let secondary_text_color = UIColor(red: 0.478, green: 0.455, blue: 0.424, alpha: 1)    // muted gray for the small stuff
    static let finished_color = UIColor(red: 0.361, green: 0.478, blue: 0.353, alpha: 1)          // sage green for finished books
    static let on_hold_color = UIColor(red: 0.627, green: 0.604, blue: 0.573, alpha: 1)           // warm gray for books on hold
    static let border_color = UIColor(red: 0.886, green: 0.863, blue: 0.831, alpha: 1)            // thin borders and empty progress track
    static let corner_radius: CGFloat = 14                                                        // same rounded corners everywhere
    static let side_padding: CGFloat = 16                                                         // left and right margin on every screen
    static let section_spacing: CGFloat = 22                                                      // gap between sections on home

    // 10/31/26 makes a styled label in one line so we dont repeat 5 lines everywhere
    static func make_label(_ text: String = "", size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor = app_theme.primary_text_color, lines: Int = 1) -> UILabel {
        let label = UILabel()                             // blank label
        label.text = text                                 // starting text
        label.font = UIFontMetrics.default.scaledFont(for: .systemFont(ofSize: size, weight: weight))    // font that also grows with the phones text size setting
        label.adjustsFontForContentSizeCategory = true    // update live if they change text size
        label.textColor = color                           // text color
        label.numberOfLines = lines                       // how many lines it can wrap to
        return label                                      // hand it back ready to use
    }

    // 10/31/26 little colored dot + status word, used on tiles and table rows
    static func make_status_row(for status: reading_status) -> UIStackView {
        let dot_view = UIView()                                                                      // the dot
        dot_view.backgroundColor = status.tint_color                                                 // dot color matches the status
        dot_view.layer.cornerRadius = 3                                                              // 6x6 square with radius 3 = circle
        dot_view.translatesAutoresizingMaskIntoConstraints = false                                   // turn off old frame layout so auto layout can size it
        let status_label = make_label(status.display_name, size: 13, color: secondary_text_color)    // the word next to the dot
        let row_stack = UIStackView(arrangedSubviews: [dot_view, status_label])                      // dot then word
        row_stack.axis = .horizontal                                                                 // side by side
        row_stack.spacing = 6                                                                        // gap between them
        row_stack.alignment = .center                                                                // dot sits in the middle of the text
        NSLayoutConstraint.activate([                                                                // turn on the size constraints
            dot_view.widthAnchor.constraint(equalToConstant: 6),                                     // dot width
            dot_view.heightAnchor.constraint(equalToConstant: 6)                                     // dot height
        ])
        return row_stack    // hand it back
    }

    // 10/31/26 draws a fake cover since we dont import real files until milestone 3
    static func make_cover_image(for item: book_item, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)     // basically a blank canvas we can draw on
        return renderer.image { context in                     // everything in here gets drawn into the image
            item.cover_color.setFill()                         // paint with the books color
            context.fill(CGRect(origin: .zero, size: size))    // fill the whole cover
            let gradient_colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.55).cgColor] as CFArray    // fade to dark so the white title is readable
            let gradient_locations: [CGFloat] = [0.35, 1.0]    // fade starts a third of the way down
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradient_colors, locations: gradient_locations) {    // build the gradient, can fail so its optional
                context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])    // draw it top to bottom
            }
            UIColor.white.withAlphaComponent(0.25).setFill()    // faint white for the spine line
            context.fill(CGRect(x: size.width * 0.03, y: 0, width: max(1, size.width * 0.012), height: size.height))    // thin line on the left like a real book spine
            let padding = size.width * 0.1                      // inner margin around the title
            let font_size = size.width * 0.14                   // title scales with cover size
            let title_font = UIFont(name: "Georgia-Bold", size: font_size) ?? .boldSystemFont(ofSize: font_size)    // serif looks more like a printed cover, fallback just in case
            let title_attributes: [NSAttributedString.Key: Any] = [.font: title_font, .foregroundColor: UIColor.white]    // white bold title
            let title_height = font_size * 2.6                  // room for 2 lines
            let title_rect = CGRect(x: padding, y: size.height - padding - title_height, width: size.width - padding * 2, height: title_height)    // box near the bottom for the title
            (item.title as NSString).draw(with: title_rect, options: [.usesLineFragmentOrigin], attributes: title_attributes, context: nil)    // draw the title, wraps if its long
        }
    }
}
