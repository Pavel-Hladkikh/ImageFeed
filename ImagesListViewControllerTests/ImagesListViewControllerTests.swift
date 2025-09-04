@testable import ImageFeed
import XCTest
import UIKit

final class ImagesListViewControllerTests: XCTestCase {


    private func makeVCFromStoryboard(presenter: ImagesListPresenting = ImagesListPresenterSpy())
    -> (vc: ImagesListViewController, table: UITableView, spy: ImagesListPresenterSpy) {

        let bundle = Bundle(for: ImagesListViewController.self)
        let sb = UIStoryboard(name: "Main", bundle: bundle)
        let vc = sb.instantiateViewController(withIdentifier: "ImagesListViewController") as! ImagesListViewController
        let spy = (presenter as? ImagesListPresenterSpy) ?? ImagesListPresenterSpy()
        vc.presenter = spy

        vc.loadViewIfNeeded()
        let table = vc.value(forKey: "tableView") as! UITableView

        return (vc, table, spy)
    }

    private func makePhoto(_ id: String, w: CGFloat = 100, h: CGFloat = 50, liked: Bool = false) -> Photo {
        Photo(
            id: id,
            size: CGSize(width: w, height: h),
            createdAt: Date(),
            welcomeDescription: nil,
            thumbImageURL: "t",
            largeImageURL: "l",
            isLiked: liked
        )
    }

    func test_viewDidLoad_setsDataSourceDelegate_andCallsPresenter() {
        let (vc, table, spy) = makeVCFromStoryboard()
        XCTAssertTrue(table.dataSource === vc)
        XCTAssertTrue(table.delegate === vc)
        XCTAssertEqual(spy.viewDidLoadCalls, 1)
    }

    func test_tableDataSource_countsAndCells() {
        let (vc, table, spy) = makeVCFromStoryboard()
        spy.items = [makePhoto("1"), makePhoto("2")]

        XCTAssertEqual(vc.tableView(table, numberOfRowsInSection: 0), 2)

        let cell = vc.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(cell is ImagesListCell)
    }

    func test_willDisplay_propagatesToPresenter() {
        let (vc, table, spy) = makeVCFromStoryboard()
        spy.items = [makePhoto("1")]

        vc.tableView(table, willDisplay: UITableViewCell(), forRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(spy.willDisplayRows, [0])
    }

    func test_likeTap_callsPresenter() {
        let (vc, table, spy) = makeVCFromStoryboard()
        spy.items = [makePhoto("1")]

        let cell = vc.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0)) as! ImagesListCell
        cell.delegate?.imagesListCellDidTapLike(cell)

        XCTAssertEqual(spy.didTapLikes, [0])
    }

    func test_heightForRow_calculatesScaledHeight() {
        let (vc, table, spy) = makeVCFromStoryboard()
        spy.items = [makePhoto("1", w: 200, h: 100)]
        table.frame = CGRect(x: 0, y: 0, width: 320, height: 480)

        let height = vc.tableView(table, heightForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertGreaterThan(height, 44, "Высота должна быть > 44 с учётом инсет-паддингов")
    }

    func test_reloadInsertedRows_smoke_onZeroOldCount() {
        let (vc, _, _) = makeVCFromStoryboard()
        vc.reloadInsertedRows(oldCount: 0, newCount: 3)
        XCTAssertTrue(true) 
    }

    func test_updateLike_whenCellNotVisible_smoke() {
        let (vc, _, spy) = makeVCFromStoryboard()
        spy.items = [makePhoto("1")]
        vc.updateLike(at: 0, isLiked: true)
        XCTAssertTrue(true)
    }
}


