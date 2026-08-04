import UIKit
import QuartzCore
import SwiftUI


@available(iOS 26.0, *)
private struct AWEPhotosExactGlassIconButton: View {
    let image: UIImage
    let pointSize: CGFloat
    let controlSize: CGFloat
    let foregroundColor: UIColor?
    let preserveOriginalImage: Bool
    let tintedGlass: Bool

    private var resolvedIconLimit: CGFloat {
        // Original-colour PNGs may use any size up to this ceiling.
        // The ceiling is twice the SF Symbol point size, but smaller PNGs are
        // never enlarged to it. SF Symbols retain their native point size.
        preserveOriginalImage ? pointSize * 2.0 : pointSize
    }

    private var resolvedIconSize: CGSize {
        let limit = resolvedIconLimit
        guard preserveOriginalImage else {
            return CGSize(width: limit, height: limit)
        }
        let source = image.size
        guard source.width > 0.0, source.height > 0.0 else {
            return CGSize(width: limit, height: limit)
        }
        // Preserve the PNG's actual logical size whenever it already fits.
        // Only oversized artwork is reduced to the configured ceiling.
        let downscale = min(limit / source.width, limit / source.height)
        let scale = min(1.0, downscale)
        return CGSize(width: source.width * scale, height: source.height * scale)
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
            // PNG keeps its actual size and aspect ratio; no enlargement or template tint.
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
        if tintedGlass {
            Button(action: {}) {
                icon
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
        } else {
            Button(action: {}) {
                icon
            }
            .buttonStyle(.glass(.clear))
            .buttonBorderShape(.circle)
        }
    }
}

/// SwiftUI Liquid Glass host for the top and right-side controls.
/// Clear mode uses `.glass(.clear)`; the optional tint mode restores `.glass`.
/// No UIKit replacement material, custom border, or background fill is added.
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
/// remains visually inert; minimization is disabled in the stable baseline.
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
    private var secondNormalSymbol = "hands.and.sparkles"
    private var secondSelectedSymbol = "hands.and.sparkles.fill"
    private var secondImageRole = "friends"
    private var cachedOriginalIndex = 0
    private var pendingUserIndex: Int?
    private var pendingSelectionUntil: CFTimeInterval = 0
    private var compactMode = false
    private var verticalOffset: CGFloat = 0
    private var hasUserDrivenSelection = false
    private var visibleItemIdentifiers = ItemKey.defaultVisible

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
        normalRole: String,
        selectedRole: String,
        normalFallback: String,
        selectedFallback: String,
        identifier: String,
        originalIndex: Int
    ) -> UITab {
        let normalImage = albumMorphConfiguredImage(
            key: normalRole,
            fallback: normalFallback,
            pointSize: 22.0
        )
        let selectedImage = albumMorphConfiguredImage(
            key: selectedRole,
            fallback: selectedFallback,
            pointSize: 22.0
        )
        let tab = UITab(
            title: title,
            image: normalImage,
            identifier: identifier
        ) { [weak self] _ in
            self?.makeProxy(originalIndex: originalIndex)
                ?? UIViewController()
        }
        if #available(iOS 26.1, *) {
            tab.selectedImage = selectedImage
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
                normalRole: "newbar.home.normal",
                selectedRole: "newbar.home.selected",
                normalFallback: "photo.on.rectangle.angled",
                selectedFallback: "photo.on.rectangle.angled",
                identifier: Identifier.home,
                originalIndex: 0
            )
        case ItemKey.second:
            return makeRegularTab(
                title: secondTitle,
                normalRole: "newbar.\(secondImageRole).normal",
                selectedRole: "newbar.\(secondImageRole).selected",
                normalFallback: secondNormalSymbol,
                selectedFallback: secondSelectedSymbol,
                identifier: Identifier.second,
                originalIndex: 1
            )
        case ItemKey.publish:
            return makeRegularTab(
                title: "发布",
                normalRole: "newbar.publish.normal",
                selectedRole: "newbar.publish.selected",
                normalFallback: "plus",
                selectedFallback: "plus",
                identifier: Identifier.publish,
                originalIndex: 2
            )
        case ItemKey.messages:
            return makeRegularTab(
                title: "消息",
                normalRole: "newbar.messages.normal",
                selectedRole: "newbar.messages.selected",
                normalFallback: "message",
                selectedFallback: "message.fill",
                identifier: Identifier.messages,
                originalIndex: 3
            )
        case ItemKey.profile:
            return makeRegularTab(
                title: "我",
                normalRole: "newbar.profile.normal",
                selectedRole: "newbar.profile.selected",
                normalFallback: "person.crop.circle",
                selectedFallback: "person.crop.circle.fill",
                identifier: Identifier.profile,
                originalIndex: 4
            )
        case ItemKey.search:
            return makeSearchTab()
        default:
            return nil
        }
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
    }

    private func applyStableVerticalOffset() {
        guard isViewLoaded else { return }
        let height = tabBar.frame.height
        guard height > 0 else { return }

        let targetY = view.bounds.maxY - height + verticalOffset
        guard abs(tabBar.frame.minY - targetY) > 0.25 else { return }

        UIView.performWithoutAnimation {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            var frame = tabBar.frame
            frame.origin.y = targetY
            tabBar.frame = frame
            CATransaction.commit()
        }
    }

    @objc(setVerticalOffset:)
    func setVerticalOffset(_ offset: CGFloat) {
        let clamped = min(max(offset, -16.0), 24.0)
        guard abs(verticalOffset - clamped) > 0.01 ||
                abs(tabBar.frame.minY - (view.bounds.maxY - tabBar.frame.height + clamped)) > 0.25 else {
            return
        }
        verticalOffset = clamped
        applyStableVerticalOffset()
        albumMorphProbe(
            "VERTICAL_OFFSET_FIXED value=\(String(format: "%.2f", clamped)) " +
            "tabFrame=\(tabBar.frame)"
        )
    }

    @objc(configureSecondTabAsShop:)
    func configureSecondTab(asShop shop: Bool) {
        let newTitle = shop ? "商城" : "朋友"
        let newNormalSymbol = shop ? "storefront" : "hands.and.sparkles"
        let newSelectedSymbol = shop ? "storefront.fill" : "hands.and.sparkles.fill"
        let newImageRole = shop ? "shop" : "friends"
        guard newTitle != secondTitle || newImageRole != secondImageRole else {
            return
        }

        secondTitle = newTitle
        secondNormalSymbol = newNormalSymbol
        secondSelectedSymbol = newSelectedSymbol
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
        _ = visible
        _ = animated
        // The overlay UIWindow owns visibility. Calling setTabBarHidden here
        // made UIKit run a second vertical transition underneath the window
        // hide/show, which produced the reported jump and disconnected motion.
        tabBar.isHidden = false
        view.isHidden = false
        view.alpha = 1.0
        applyStableVerticalOffset()
    }

    @objc(setCompactMode:animated:)
    func setCompactMode(_ compact: Bool, animated: Bool) {
        // ABI compatibility only. Minimization is intentionally disabled.
        compactMode = false
        albumMorphProbe(
            "SET_COMPACT_DISABLED requested=\(compact) animated=\(animated) " +
            "tabFrame=\(tabBar.frame)"
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
