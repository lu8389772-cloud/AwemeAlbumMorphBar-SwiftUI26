import UIKit
import QuartzCore
import SwiftUI


private extension CGAffineTransform {
    func isApproximatelyEqual(to other: CGAffineTransform, tolerance: CGFloat = 0.01) -> Bool {
        abs(a - other.a) < tolerance &&
        abs(b - other.b) < tolerance &&
        abs(c - other.c) < tolerance &&
        abs(d - other.d) < tolerance &&
        abs(tx - other.tx) < tolerance &&
        abs(ty - other.ty) < tolerance
    }
}


@available(iOS 26.0, *)
private struct AWEPhotosExactGlassIconButton: View {
    let image: UIImage
    let pointSize: CGFloat
    let controlSize: CGFloat
    let foregroundColor: UIColor?
    let preserveOriginalImage: Bool
    let tintedGlass: Bool

    private var resolvedIconSize: CGSize {
        guard preserveOriginalImage else {
            return CGSize(width: pointSize, height: pointSize)
        }

        // Imported PNG artwork is authored in source pixels. Interpret the
        // file as an @3x asset: 30x30 px -> 10x10 pt, 100x100 px ->
        // 33.33x33.33 pt. Small files keep their authored size; only artwork
        // whose longest edge exceeds 100 px is reduced proportionally.
        let pixelWidth: CGFloat
        let pixelHeight: CGFloat
        if let cgImage = image.cgImage {
            pixelWidth = CGFloat(cgImage.width)
            pixelHeight = CGFloat(cgImage.height)
        } else {
            pixelWidth = image.size.width * image.scale
            pixelHeight = image.size.height * image.scale
        }
        guard pixelWidth > 0.0, pixelHeight > 0.0 else {
            return .zero
        }

        let designScale: CGFloat = 3.0
        let maximumPixelEdge: CGFloat = 100.0
        let pixelDownscale = min(
            maximumPixelEdge / pixelWidth,
            maximumPixelEdge / pixelHeight
        )
        let scale = min(1.0, pixelDownscale)
        return CGSize(
            width: pixelWidth * scale / designScale,
            height: pixelHeight * scale / designScale
        )
    }

    @ViewBuilder
    private var icon: some View {
        let size = resolvedIconSize
        let base = Image(uiImage: image)
            .renderingMode(preserveOriginalImage ? .original : .template)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .frame(width: controlSize, height: controlSize)

        if preserveOriginalImage {
            // Original-colour PNG: preserve pixel-authored size, ratio and alpha.
            base
        } else if let foregroundColor {
            // Explicit white/black/accent/custom modes tint only SF Symbols.
            base.foregroundStyle(Color(uiColor: foregroundColor))
        } else {
            // Automatic mode is owned by the selected native glass material.
            base
        }
    }

    @ViewBuilder
    var body: some View {
        // A 46x46 square Capsule is a true circle. Unlike Circle(), Capsule()
        // can become a native pill/oval if its frame is later stretched. Apply
        // glass directly so the material body is exactly 46x46 rather than the
        // 56x46 private interaction shell produced by GlassButtonStyle.
        if tintedGlass {
            icon
                .frame(width: controlSize, height: controlSize)
                .contentShape(Capsule())
                .glassEffect(.regular.interactive(), in: Capsule())
        } else {
            icon
                .frame(width: controlSize, height: controlSize)
                .contentShape(Capsule())
                .glassEffect(.clear.interactive(), in: Capsule())
        }
    }
}

/// SwiftUI Liquid Glass host for the top and right-side controls.
/// Clear mode uses interactive `.clear`; tint mode uses interactive `.regular`.
/// The visible material body is a fixed 46x46 square Capsule.
@available(iOS 26.0, *)
@objc(AWEPhotosExactGlassButtonHostView)
final class AWEPhotosExactGlassButtonHostView: UIView {
    private var hostingController: UIHostingController<AnyView>?
    private weak var lastImage: UIImage?
    private var lastPointSize: CGFloat = -1
    private var lastControlSize: CGFloat = -1
    private var lastForegroundColor: UIColor?
    private var lastPreserveOriginalImage = false
    private var lastTintedGlass = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        clipsToBounds = false
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc(updateWithImage:pointSize:controlSize:foregroundColor:preserveOriginalImage:tintedGlass:)
    func update(
        image: UIImage,
        pointSize: CGFloat,
        controlSize: CGFloat,
        foregroundColor: UIColor?,
        preserveOriginalImage: Bool,
        tintedGlass: Bool
    ) {
        let sameColor: Bool
        if let previous = lastForegroundColor, let foregroundColor {
            sameColor = previous.isEqual(foregroundColor)
        } else {
            sameColor = lastForegroundColor == nil && foregroundColor == nil
        }
        if lastImage === image,
           abs(lastPointSize - pointSize) < 0.01,
           abs(lastControlSize - controlSize) < 0.01,
           sameColor,
           lastPreserveOriginalImage == preserveOriginalImage,
           lastTintedGlass == tintedGlass {
            return
        }
        lastImage = image
        lastPointSize = pointSize
        lastControlSize = controlSize
        lastForegroundColor = foregroundColor
        lastPreserveOriginalImage = preserveOriginalImage
        lastTintedGlass = tintedGlass

        let root = AnyView(
            AWEPhotosExactGlassIconButton(
                image: image,
                pointSize: pointSize,
                controlSize: controlSize,
                foregroundColor: foregroundColor,
                preserveOriginalImage: preserveOriginalImage,
                tintedGlass: tintedGlass
            )
        )

        if let hostingController {
            hostingController.rootView = root
            hostingController.view.setNeedsLayout()
            hostingController.view.setNeedsDisplay()
            return
        }

        let controller = UIHostingController(rootView: root)
        controller.view.backgroundColor = .clear
        controller.view.isOpaque = false
        controller.view.clipsToBounds = false
        controller.view.isUserInteractionEnabled = false
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(controller.view)
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        hostingController = controller
    }
}

@objc(AWEAlbumMorphActionSink)
protocol AWEAlbumMorphActionSink: AnyObject {
    @objc(albumMorphDidRequestOriginalIndex:)
    func albumMorphDidRequestOriginalIndex(_ index: Int)

    @objc(albumMorphDidRequestSearch)
    func albumMorphDidRequestSearch()
}

@_silgen_name("AWEAlbumMorphProbeLog")
private func AWEAlbumMorphProbeLog(_ message: UnsafePointer<CChar>)

private func albumMorphProbe(_ message: String) {
    message.withCString { AWEAlbumMorphProbeLog($0) }
}

@_silgen_name("AWEAlbumMorphHideTitlesEnabled")
private func AWEAlbumMorphHideTitlesEnabled() -> Int32

private var albumMorphHideTitles: Bool {
    AWEAlbumMorphHideTitlesEnabled() != 0
}

@_silgen_name("AWEAlbumMorphCreateConfiguredImage")
private func AWEAlbumMorphCreateConfiguredImage(
    _ key: UnsafePointer<CChar>,
    _ fallback: UnsafePointer<CChar>,
    _ pointSize: Double
) -> UnsafeMutableRawPointer?

private func albumMorphConfiguredImage(
    key: String,
    fallback: String,
    pointSize: CGFloat
) -> UIImage? {
    let raw: UnsafeMutableRawPointer? = key.withCString { keyCString in
        fallback.withCString { fallbackCString in
            AWEAlbumMorphCreateConfiguredImage(
                keyCString, fallbackCString, Double(pointSize)
            )
        }
    }
    guard let raw else { return UIImage(systemName: fallback) }
    return Unmanaged<UIImage>.fromOpaque(raw).takeRetainedValue()
}

@available(iOS 26.0, *)
private final class AWEAlbumMorphProxyCell: UICollectionViewCell {
    static let reuseIdentifier = "AWEAlbumMorphProxyCell"
}

/// Transparent selected child retained by the real UITabBarController. UIKit
/// remains visually inert. Scroll recognition is handled by the source-window
/// gesture bridge, while this controller owns only the native/fallback compact
/// transition so custom vertical offsets never rewrite UIKit's tab-bar frame.
@available(iOS 26.0, *)
private final class AWEAlbumMorphProxyController: UICollectionViewController {
    let originalIndex: Int?
    let representsSearch: Bool
    private weak var boundSourceScrollView: UIScrollView?

    init(originalIndex: Int?, representsSearch: Bool = false) {
        self.originalIndex = originalIndex
        self.representsSearch = representsSearch

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(96.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(96.0)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: 1
        )
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)

        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.isOpaque = false
        collectionView.backgroundColor = .clear
        collectionView.isOpaque = false
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isUserInteractionEnabled = false
        collectionView.accessibilityIdentifier =
            "AwemeLiquidBar.AlbumMorph.ProxyCollection"
        collectionView.register(
            AWEAlbumMorphProxyCell.self,
            forCellWithReuseIdentifier: AWEAlbumMorphProxyCell.reuseIdentifier
        )

        // The proxy stays visually inert. The actual user-controlled source
        // scroll view is bound later through UIKit's public content-scroll API.
        albumMorphProbe(
            "PROXY_VIEW_DID_LOAD index=\(originalIndex.map(String.init) ?? "search") " +
            "bounds=\(collectionView.bounds) content=\(collectionView.contentSize)"
        )
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        80
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AWEAlbumMorphProxyCell.reuseIdentifier,
            for: indexPath
        )
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }

    func bindSourceScrollView(_ scrollView: UIScrollView) {
        // Stability baseline: do not attach host scroll views to the overlay
        // controller. Cross-hierarchy binding caused page-dependent state and
        // visible geometry jumps without reliable native minimization.
        boundSourceScrollView = nil
        albumMorphProbe(
            "SOURCE_BIND_DISABLED proxy=\(originalIndex.map(String.init) ?? "search") " +
            "scroll=\(type(of: scrollView))"
        )
    }


}

@available(iOS 26.0, *)
@_cdecl("AWEAlbumMorphCreateController")
public func AWEAlbumMorphCreateController() -> UnsafeMutableRawPointer {
    let controller = AWEAlbumMorphTabController()
    return Unmanaged.passRetained(controller).toOpaque()
}

@available(iOS 26.0, *)
@objc(AWEAlbumMorphTabController)
final class AWEAlbumMorphTabController:
    UITabBarController,
    UITabBarControllerDelegate {

    @objc weak var actionSink: AWEAlbumMorphActionSink?

    private enum Identifier {
        static let home = "com.xyy.awemeliquidbar.album.home"
        static let second = "com.xyy.awemeliquidbar.album.second"
        static let publish = "com.xyy.awemeliquidbar.album.publish"
        static let messages = "com.xyy.awemeliquidbar.album.messages"
        static let profile = "com.xyy.awemeliquidbar.album.profile"
    }

    private enum ItemKey {
        static let home = "home"
        static let second = "second"
        static let publish = "publish"
        static let messages = "messages"
        static let profile = "profile"
        static let search = "search"

        static let allowed = [home, second, publish, messages, profile, search]
        static let defaultVisible = [home, second, messages, profile, search]
        static let selectablePages = Set([home, second, messages, profile])
    }

    private var proxies: [AWEAlbumMorphProxyController] = []
    private var suppressCallbacks = false
    private var secondTitle = "朋友"
    private var explicitImagesByIdentifier: [String: (normal: UIImage?, selected: UIImage?)] = [:]
    private var secondNormalSymbol = "hands.and.sparkles"
    private var secondImageRole = "friends"
    private var cachedOriginalIndex = 0
    private var pendingUserIndex: Int?
    private var pendingSelectionUntil: CFTimeInterval = 0
    private var compactMode = false
    private var verticalOffset: CGFloat = 0
    private var fallbackCompactScale: CGFloat = 1
    private var morphVisibleFraction: CGFloat = 1
    private let visibilityMaskView = UIView(frame: .zero)
    private var hasUserDrivenSelection = false
    private var visibleItemIdentifiers = ItemKey.defaultVisible
    private var messageBadgeValue: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.isOpaque = false
        view.tintColor = .systemCyan

        delegate = self
        tabBarMinimizeBehavior = .never

        overrideUserInterfaceStyle = .unspecified
        view.overrideUserInterfaceStyle = .unspecified
        tabBar.overrideUserInterfaceStyle = .unspecified

        tabBar.accessibilityIdentifier =
            "AwemeLiquidBar.AlbumMorph.SystemTabBar"
        tabBar.isTranslucent = true
        tabBar.isOpaque = false
        tabBar.backgroundColor = .clear
        tabBar.clipsToBounds = false
        visibilityMaskView.backgroundColor = .black
        visibilityMaskView.isUserInteractionEnabled = false

        // Keep every regular item on the same native sizing path. Never scale
        // the whole tab bar or squeeze only the two end items when five page/
        // action buttons are enabled beside the independent search capsule.
        tabBar.itemPositioning = .fill
        tabBar.itemWidth = 0
        tabBar.itemSpacing = 0

        rebuildTabs(preservingOriginalIndex: 0)
    }

    private func makeProxy(
        originalIndex: Int?,
        search: Bool = false
    ) -> UIViewController {
        let proxy = AWEAlbumMorphProxyController(
            originalIndex: originalIndex,
            representsSearch: search
        )
        proxies.append(proxy)

        return proxy
    }

    private func makeRegularTab(
        title: String,
        iconRole: String,
        fallback: String,
        identifier: String,
        originalIndex: Int
    ) -> UITab {
        let image = albumMorphConfiguredImage(
            key: iconRole,
            fallback: fallback,
            pointSize: 22.0
        )
        explicitImagesByIdentifier[identifier] = (image, image)
        let tab = UITab(
            title: albumMorphHideTitles ? "" : title,
            image: image,
            identifier: identifier
        ) { [weak self] _ in
            self?.makeProxy(originalIndex: originalIndex)
                ?? UIViewController()
        }
        if #available(iOS 26.1, *) {
            tab.selectedImage = image
        }
        return tab
    }

    private func makeSearchTab() -> UISearchTab {
        let search = UISearchTab { [weak self] _ in
            self?.makeProxy(originalIndex: nil, search: true)
                ?? UIViewController()
        }
        search.automaticallyActivatesSearch = false
        search.image = albumMorphConfiguredImage(
            key: "newbar.search.normal",
            fallback: "magnifyingglass",
            pointSize: 21.0
        )
        return search
    }

    private func tabForItemKey(_ key: String) -> UITab? {
        switch key {
        case ItemKey.home:
            return makeRegularTab(
                title: "首页",
                iconRole: "newbar.home.normal",
                fallback: "photo.on.rectangle.angled",
                identifier: Identifier.home,
                originalIndex: 0
            )
        case ItemKey.second:
            return makeRegularTab(
                title: secondTitle,
                iconRole: "newbar.\(secondImageRole).normal",
                fallback: secondNormalSymbol,
                identifier: Identifier.second,
                originalIndex: 1
            )
        case ItemKey.publish:
            return makeRegularTab(
                title: "发布",
                iconRole: "newbar.publish.normal",
                fallback: "plus",
                identifier: Identifier.publish,
                originalIndex: 2
            )
        case ItemKey.messages:
            return makeRegularTab(
                title: "消息",
                iconRole: "newbar.messages.normal",
                fallback: "message",
                identifier: Identifier.messages,
                originalIndex: 3
            )
        case ItemKey.profile:
            return makeRegularTab(
                title: "我",
                iconRole: "newbar.profile.normal",
                fallback: "person.crop.circle",
                identifier: Identifier.profile,
                originalIndex: 4
            )
        case ItemKey.search:
            return makeSearchTab()
        default:
            return nil
        }
    }

    private func applyExplicitSelectionImages(selectedIdentifier: String?) {
        for tab in tabs {
            let identifier = tab.identifier
            guard let images = explicitImagesByIdentifier[identifier] else {
                continue
            }
            let selected = identifier == selectedIdentifier
            tab.image = selected ? (images.selected ?? images.normal) : images.normal
            if #available(iOS 26.1, *) {
                tab.selectedImage = images.selected ?? images.normal
            }
        }
        tabBar.setNeedsLayout()
    }

    private func applyMessageBadge() {
        guard let messageTab = tab(forIdentifier: Identifier.messages) else { return }
        let normalized = messageBadgeValue?.isEmpty == false ? messageBadgeValue : nil

        // UITab badge API has shifted across SDK revisions. Keep the source
        // compatible by using KVC first, then mirror onto the concrete
        // UITabBarItem when UIKit has materialized it.
        if messageTab.responds(to: NSSelectorFromString("setBadgeValue:")) {
            messageTab.setValue(normalized, forKey: "badgeValue")
        }
        if let index = tabs.firstIndex(where: { $0 === messageTab }),
           let items = tabBar.items, index < items.count {
            items[index].badgeValue = normalized
            items[index].badgeColor = .systemRed
        }
        tabBar.setNeedsLayout()
    }

    @objc(updateMessageBadgeValue:)
    func updateMessageBadgeValue(_ value: String?) {
        messageBadgeValue = value
        applyMessageBadge()
    }

    private func sanitizedVisibleItems(_ identifiers: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for identifier in identifiers where ItemKey.allowed.contains(identifier) {
            guard seen.insert(identifier).inserted else { continue }
            result.append(identifier)
        }

        let selectableCount = result.filter {
            ItemKey.selectablePages.contains($0)
        }.count
        if selectableCount < 2 {
            return ItemKey.defaultVisible
        }

        // UISearchTab owns its independent right-side system capsule. Keep it
        // last regardless of the order of regular items so UIKit never tries
        // to place regular buttons on both sides of that capsule.
        if let searchIndex = result.firstIndex(of: ItemKey.search) {
            result.remove(at: searchIndex)
            result.append(ItemKey.search)
        }
        return result
    }

    private func rebuildTabs(preservingOriginalIndex originalIndex: Int) {
        proxies.removeAll()
        explicitImagesByIdentifier.removeAll(keepingCapacity: true)

        let rebuilt = visibleItemIdentifiers.compactMap(tabForItemKey)
        guard !rebuilt.isEmpty else { return }

        let fallback = rebuilt.first { self.originalIndex(for: $0) != nil }
        let preferred = rebuilt.first {
            self.originalIndex(for: $0) == originalIndex
        } ?? fallback
        let resolvedIndex = self.originalIndex(for: preferred) ?? 0

        suppressCallbacks = true
        UIView.performWithoutAnimation {
            tabs = rebuilt
            selectedTab = preferred
            applyExplicitSelectionImages(selectedIdentifier: preferred?.identifier)
            tabBar.itemPositioning = .fill
            tabBar.itemWidth = 0
            tabBar.itemSpacing = 0
            tabBar.setNeedsLayout()
            tabBar.layoutIfNeeded()
        }
        cachedOriginalIndex = resolvedIndex
        pendingUserIndex = nil
        pendingSelectionUntil = 0
        suppressCallbacks = false
        applyStableVerticalOffset()
        applyFallbackCompactTransform(animated: false)
        applyMessageBadge()
        albumMorphProbe(
            "VISIBLE_ITEMS_APPLIED items=\(visibleItemIdentifiers.joined(separator: ",")) " +
            "selected=\(resolvedIndex) tabFrame=\(tabBar.frame)"
        )
    }

    private func tabForOriginalIndex(_ index: Int) -> UITab? {
        switch index {
        case 0:
            return tab(forIdentifier: Identifier.home)
        case 1:
            return tab(forIdentifier: Identifier.second)
        case 3:
            return tab(forIdentifier: Identifier.messages)
        case 4:
            return tab(forIdentifier: Identifier.profile)
        default:
            return nil
        }
    }

    private func originalIndex(for tab: UITab?) -> Int? {
        guard let identifier = tab?.identifier else { return nil }
        switch identifier {
        case Identifier.home:
            return 0
        case Identifier.second:
            return 1
        case Identifier.publish:
            return 2
        case Identifier.messages:
            return 3
        case Identifier.profile:
            return 4
        default:
            return nil
        }
    }

    private var activeProxy: AWEAlbumMorphProxyController? {
        selectedViewController as? AWEAlbumMorphProxyController
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyStableVerticalOffset()
        setVisibleFraction(morphVisibleFraction, animated: false)
        if compactMode {
            compactMode = false
            tabBar.transform = .identity
        }
    }

    private func applyStableVerticalOffset() {
        guard isViewLoaded else { return }
        let target = CGAffineTransform(translationX: 0, y: verticalOffset)
        guard !view.transform.isApproximatelyEqual(to: target) else { return }
        UIView.performWithoutAnimation {
            self.view.transform = .identity
            self.view.transform = target
        }
    }

    private func currentFallbackCompactScale() -> CGFloat {
        let liveHeight = max(tabBar.bounds.height, tabBar.frame.height)
        guard liveHeight > 1 else { return 1 }
        // Scale the live native tab bar instead of translating it below the
        // screen. This is inherently independent of custom height and offset.
        return 0.82
    }

    private func applyFallbackCompactTransform(animated: Bool) {
        let scale = compactMode ? currentFallbackCompactScale() : 1
        fallbackCompactScale = scale
        let liveHeight = max(tabBar.bounds.height, tabBar.frame.height)
        let keepBottomAligned = compactMode ? (1 - scale) * liveHeight * 0.5 : 0
        let target = CGAffineTransform(translationX: 0, y: keepBottomAligned)
            .scaledBy(x: scale, y: scale)
        let changes = {
            self.tabBar.transform = target
        }
        if animated {
            UIView.animate(
                withDuration: 0.38,
                delay: 0,
                usingSpringWithDamping: 0.88,
                initialSpringVelocity: 0.18,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: changes
            )
        } else {
            UIView.performWithoutAnimation(changes)
        }
    }

    @objc(setVerticalOffset:)
    func setVerticalOffset(_ offset: CGFloat) {
        let clamped = min(max(offset, -24.0), 80.0)
        guard abs(verticalOffset - clamped) > 0.01 ||
                abs(view.transform.ty - clamped) > 0.25 else {
            return
        }
        verticalOffset = clamped
        applyStableVerticalOffset()
        setVisibleFraction(morphVisibleFraction, animated: false)
        if compactMode {
            applyFallbackCompactTransform(animated: false)
        }
        albumMorphProbe(
            "VERTICAL_OFFSET_DYNAMIC value=\(String(format: "%.2f", clamped)) " +
            "viewTY=\(view.transform.ty) tabFrame=\(tabBar.frame)"
        )
    }

    @objc(configureSecondTabAsShop:)
    func configureSecondTab(asShop shop: Bool) {
        let newTitle = shop ? "商城" : "朋友"
        let newNormalSymbol = shop ? "storefront" : "hands.and.sparkles"
        let newImageRole = shop ? "shop" : "friends"
        guard newTitle != secondTitle || newImageRole != secondImageRole else {
            return
        }

        secondTitle = newTitle
        secondNormalSymbol = newNormalSymbol
        secondImageRole = newImageRole
        rebuildTabs(preservingOriginalIndex: cachedOriginalIndex)
    }

    @objc(reloadConfiguredImages)
    func reloadConfiguredImages() {
        rebuildTabs(preservingOriginalIndex: cachedOriginalIndex)
    }

    @objc(configureVisibleItemIdentifiers:)
    func configureVisibleItemIdentifiers(_ identifiers: [String]) {
        let sanitized = sanitizedVisibleItems(identifiers)
        guard sanitized != visibleItemIdentifiers else { return }

        let previousIndex = cachedOriginalIndex
        visibleItemIdentifiers = sanitized
        rebuildTabs(preservingOriginalIndex: previousIndex)

        if cachedOriginalIndex != previousIndex {
            let fallbackIndex = cachedOriginalIndex
            DispatchQueue.main.async { [weak self] in
                self?.actionSink?.albumMorphDidRequestOriginalIndex(fallbackIndex)
            }
        }
    }

    @objc(updateAccentColor:)
    func updateAccentColor(_ color: UIColor) {
        view.tintColor = color
        tabBar.tintColor = color
    }

    @objc(setForcedDark:)
    func setForcedDark(_ forced: Bool) {
        setResolvedInterfaceStyleRaw(
            forced
                ? UIUserInterfaceStyle.dark.rawValue
                : UIUserInterfaceStyle.unspecified.rawValue
        )
    }

    @objc(setResolvedInterfaceStyleRaw:)
    func setResolvedInterfaceStyleRaw(_ rawValue: Int) {
        let requested = UIUserInterfaceStyle(rawValue: rawValue) ?? .unspecified
        let style: UIUserInterfaceStyle
        switch requested {
        case .light, .dark:
            style = requested
        default:
            style = .unspecified
        }

        guard overrideUserInterfaceStyle != style ||
                view.overrideUserInterfaceStyle != style ||
                tabBar.overrideUserInterfaceStyle != style else {
            return
        }

        UIView.performWithoutAnimation {
            overrideUserInterfaceStyle = style
            view.overrideUserInterfaceStyle = style
            tabBar.overrideUserInterfaceStyle = style
        }
    }

    @objc(setMorphBarVisible:animated:)
    func setMorphBarVisible(_ visible: Bool, animated: Bool) {
        // Keep the native Liquid Glass tree alive at all times. Visibility is
        // represented by a left-to-right mask, matching the proven 1.0.10b
        // return architecture instead of alpha/hide reconstruction.
        tabBar.isHidden = false
        view.isHidden = false
        view.alpha = 1.0
        applyStableVerticalOffset()
        applyFallbackCompactTransform(animated: false)
        setVisibleFraction(visible ? 1.0 : 0.0, animated: animated)
    }

    @objc(setVisibleFraction:animated:)
    func setVisibleFraction(_ fraction: CGFloat, animated: Bool) {
        let clamped = min(max(fraction, 0.0), 1.0)
        morphVisibleFraction = clamped

        tabBar.isHidden = false
        view.isHidden = false
        view.alpha = 1.0

        let changes = {
            // The visible Liquid Glass platter is hosted by the controller's
            // floating-bar container, not strictly inside UITabBar. Mask the
            // whole resident controller view so steady hidden pages and
            // interactive returns reveal exactly the uncovered screen width.
            self.tabBar.mask = nil
            if clamped >= 0.999 {
                self.view.mask = nil
            } else {
                self.visibilityMaskView.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: max(0, self.view.bounds.width * clamped),
                    height: self.view.bounds.height
                )
                if self.view.mask !== self.visibilityMaskView {
                    self.view.mask = self.visibilityMaskView
                }
            }
            let interactive = clamped >= 0.82
            self.view.isUserInteractionEnabled = interactive
            self.tabBar.isUserInteractionEnabled = interactive
        }

        if animated {
            changes()
        } else {
            UIView.performWithoutAnimation(changes)
        }
    }

    @objc(setCompactMode:animated:)
    func setCompactMode(_ compact: Bool, animated: Bool) {
        guard compactMode != compact else {
            if compact {
                applyFallbackCompactTransform(animated: false)
            }
            return
        }
        compactMode = compact
        applyFallbackCompactTransform(animated: animated)
        albumMorphProbe(
            "SET_COMPACT_FALLBACK compact=\(compact) animated=\(animated) " +
            "scale=\(String(format: "%.3f", fallbackCompactScale)) " +
            "height=\(String(format: "%.2f", tabBar.frame.height))"
        )
    }

    @objc(currentOriginalIndex)
    func currentOriginalIndex() -> Int {
        cachedOriginalIndex
    }

    @objc(bindSourceScrollView:)
    func bindSourceScrollView(_ scrollView: UIScrollView) {
        _ = scrollView
        albumMorphProbe(
            "TAB_CONTROLLER_SOURCE_BIND_DISABLED selected=\(cachedOriginalIndex)"
        )
    }

    private func reassertSelection(
        originalIndex: Int,
        after delay: TimeInterval = 0
    ) {
        let apply = { [weak self] in
            guard let self,
                  self.pendingUserIndex == originalIndex,
                  let target = self.tabForOriginalIndex(originalIndex) else {
                return
            }

            self.cachedOriginalIndex = originalIndex
            guard self.selectedTab !== target else { return }
            self.suppressCallbacks = true
            self.selectedTab = target
            self.applyExplicitSelectionImages(selectedIdentifier: target.identifier)
            self.suppressCallbacks = false
        }

        if delay <= 0 {
            apply()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                apply()
            }
        }
    }

    @objc(syncSelectedOriginalIndex:)
    func syncSelectedOriginalIndex(_ index: Int) {
        // Once the user has selected a tab on the transplanted native bar, it
        // becomes the authoritative selection source. Douyin's hidden original
        // tab controller can continue publishing a stale Messages index long
        // after the Profile page is already visible.
        if hasUserDrivenSelection && index != cachedOriginalIndex {
            return
        }

        let now = CACurrentMediaTime()

        if let pending = pendingUserIndex {
            if now < pendingSelectionUntil {
                if index != pending {
                    // Douyin can emit an intermediate Messages selection while
                    // the Profile controller is already becoming visible. Keep
                    // the user's native selection authoritative for the full
                    // transition window, even if the correct index appeared
                    // briefly before another stale callback.
                    reassertSelection(originalIndex: pending)
                    return
                }
            } else {
                pendingUserIndex = nil
                pendingSelectionUntil = 0
            }
        }

        guard let target = tabForOriginalIndex(index) else { return }
        cachedOriginalIndex = index

        guard selectedTab !== target else { return }
        suppressCallbacks = true
        selectedTab = target
        applyExplicitSelectionImages(selectedIdentifier: target.identifier)
        suppressCallbacks = false
    }

    @objc(mirrorSourceScrollOffset:)
    func mirrorSourceScrollOffset(_ delta: CGFloat) {
        _ = delta
    }

    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelectTab tab: UITab
    ) -> Bool {
        guard !suppressCallbacks else { return true }

        if tab is UISearchTab {
            actionSink?.albumMorphDidRequestSearch()
            return false
        }
        if originalIndex(for: tab) == 2 {
            actionSink?.albumMorphDidRequestOriginalIndex(2)
            return false
        }
        return true
    }

    func tabBarController(
        _ tabBarController: UITabBarController,
        didSelectTab selectedTab: UITab,
        previousTab: UITab?
    ) {
        guard !suppressCallbacks,
              let originalIndex = originalIndex(for: selectedTab) else {
            return
        }

        cachedOriginalIndex = originalIndex
        applyExplicitSelectionImages(selectedIdentifier: selectedTab.identifier)
        albumMorphProbe(
            "TAB_SELECT originalIndex=\(originalIndex) previous=\(previousTab?.identifier ?? "nil")"
        )
        hasUserDrivenSelection = true
        pendingUserIndex = originalIndex
        pendingSelectionUntil = CACurrentMediaTime() + 3.0

        // Forward the real Douyin action, then keep the system platter on the
        // user's chosen tab while Douyin emits its transient old-index
        // callbacks during the page transition.
        actionSink?.albumMorphDidRequestOriginalIndex(originalIndex)
        reassertSelection(originalIndex: originalIndex)
        reassertSelection(originalIndex: originalIndex, after: 0.12)
        reassertSelection(originalIndex: originalIndex, after: 0.45)
        reassertSelection(originalIndex: originalIndex, after: 1.10)
        reassertSelection(originalIndex: originalIndex, after: 2.40)

    }
}
