import AppKit
import ApplicationServices
import Foundation
import XCTest

final class Ln1SmokeTests: Ln1TestCase {
    func testPolicyCommandReturnsKnownActionRiskClassifications() throws {
        let result = try runLn1(["policy"])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let riskLevels = try XCTUnwrap(object["riskLevels"] as? [String])
        let actions = try XCTUnwrap(object["actions"] as? [[String: Any]])
        let actionByName = Dictionary(uniqueKeysWithValues: actions.compactMap { action -> (String, [String: Any])? in
            guard let name = action["name"] as? String else {
                return nil
            }
            return (name, action)
        })

        XCTAssertEqual(object["defaultAllowedRisk"] as? String, "low")
        XCTAssertEqual(riskLevels, ["low", "medium", "high", "unknown"])
        XCTAssertEqual(actionByName["accessibility.inspectMenu"]?["domain"] as? String, "accessibility")
        XCTAssertEqual(actionByName["accessibility.inspectMenu"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["accessibility.inspectMenu"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["accessibility.inspectElement"]?["domain"] as? String, "accessibility")
        XCTAssertEqual(actionByName["accessibility.inspectElement"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["accessibility.inspectElement"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["accessibility.findElement"]?["domain"] as? String, "accessibility")
        XCTAssertEqual(actionByName["accessibility.findElement"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["accessibility.findElement"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["accessibility.waitElement"]?["domain"] as? String, "accessibility")
        XCTAssertEqual(actionByName["accessibility.waitElement"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["accessibility.waitElement"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["accessibility.setValue"]?["domain"] as? String, "accessibility")
        XCTAssertEqual(actionByName["accessibility.setValue"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["accessibility.setValue"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["apps.list"]?["domain"] as? String, "apps")
        XCTAssertEqual(actionByName["apps.list"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["apps.list"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["apps.active"]?["domain"] as? String, "apps")
        XCTAssertEqual(actionByName["apps.active"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["apps.active"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["apps.installed"]?["domain"] as? String, "apps")
        XCTAssertEqual(actionByName["apps.installed"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["apps.installed"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["apps.plan"]?["domain"] as? String, "apps")
        XCTAssertEqual(actionByName["apps.plan"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["apps.plan"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["apps.waitActive"]?["domain"] as? String, "apps")
        XCTAssertEqual(actionByName["apps.waitActive"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["apps.waitActive"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["apps.activate"]?["domain"] as? String, "apps")
        XCTAssertEqual(actionByName["apps.activate"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["apps.activate"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["apps.launch"]?["domain"] as? String, "apps")
        XCTAssertEqual(actionByName["apps.launch"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["apps.launch"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["apps.hide"]?["domain"] as? String, "apps")
        XCTAssertEqual(actionByName["apps.hide"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["apps.hide"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["apps.unhide"]?["domain"] as? String, "apps")
        XCTAssertEqual(actionByName["apps.unhide"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["apps.unhide"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["apps.quit"]?["domain"] as? String, "apps")
        XCTAssertEqual(actionByName["apps.quit"]?["risk"] as? String, "high")
        XCTAssertEqual(actionByName["apps.quit"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["processes.list"]?["domain"] as? String, "processes")
        XCTAssertEqual(actionByName["processes.list"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["processes.list"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["processes.inspect"]?["domain"] as? String, "processes")
        XCTAssertEqual(actionByName["processes.inspect"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["processes.inspect"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["processes.wait"]?["domain"] as? String, "processes")
        XCTAssertEqual(actionByName["processes.wait"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["processes.wait"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["system.context"]?["domain"] as? String, "system")
        XCTAssertEqual(actionByName["system.context"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["system.context"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["benchmarks.matrix"]?["domain"] as? String, "benchmarks")
        XCTAssertEqual(actionByName["benchmarks.matrix"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["benchmarks.matrix"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["workspace.open"]?["domain"] as? String, "workspace")
        XCTAssertEqual(actionByName["workspace.open"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["workspace.open"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["desktop.listDisplays"]?["domain"] as? String, "desktop")
        XCTAssertEqual(actionByName["desktop.listDisplays"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["desktop.listDisplays"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["desktop.listWindows"]?["domain"] as? String, "desktop")
        XCTAssertEqual(actionByName["desktop.listWindows"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["desktop.listWindows"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["desktop.screenshot"]?["domain"] as? String, "desktop")
        XCTAssertEqual(actionByName["desktop.screenshot"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["desktop.screenshot"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["desktop.activeWindow"]?["domain"] as? String, "desktop")
        XCTAssertEqual(actionByName["desktop.activeWindow"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["desktop.activeWindow"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["desktop.waitActiveWindow"]?["domain"] as? String, "desktop")
        XCTAssertEqual(actionByName["desktop.waitActiveWindow"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["desktop.waitActiveWindow"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["desktop.waitWindow"]?["domain"] as? String, "desktop")
        XCTAssertEqual(actionByName["desktop.waitWindow"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["desktop.waitWindow"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["desktop.minimizeActiveWindow"]?["domain"] as? String, "desktop")
        XCTAssertEqual(actionByName["desktop.minimizeActiveWindow"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["desktop.minimizeActiveWindow"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["desktop.restoreWindow"]?["domain"] as? String, "desktop")
        XCTAssertEqual(actionByName["desktop.restoreWindow"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["desktop.restoreWindow"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["desktop.raiseWindow"]?["domain"] as? String, "desktop")
        XCTAssertEqual(actionByName["desktop.raiseWindow"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["desktop.raiseWindow"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["desktop.setWindowFrame"]?["domain"] as? String, "desktop")
        XCTAssertEqual(actionByName["desktop.setWindowFrame"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["desktop.setWindowFrame"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["input.pointer"]?["domain"] as? String, "input")
        XCTAssertEqual(actionByName["input.pointer"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["input.pointer"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["input.movePointer"]?["domain"] as? String, "input")
        XCTAssertEqual(actionByName["input.movePointer"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["input.movePointer"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["input.dragPointer"]?["domain"] as? String, "input")
        XCTAssertEqual(actionByName["input.dragPointer"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["input.dragPointer"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["input.scrollWheel"]?["domain"] as? String, "input")
        XCTAssertEqual(actionByName["input.scrollWheel"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["input.scrollWheel"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["input.pressKey"]?["domain"] as? String, "input")
        XCTAssertEqual(actionByName["input.pressKey"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["input.pressKey"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["input.typeText"]?["domain"] as? String, "input")
        XCTAssertEqual(actionByName["input.typeText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["input.typeText"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["filesystem.search"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["filesystem.search"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.watch"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["filesystem.watch"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.plan"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["filesystem.plan"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.readText"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.readText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.readText"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.tailText"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.tailText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.tailText"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.readLines"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.readLines"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.readLines"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.readJSON"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.readJSON"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.readJSON"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.readPropertyList"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.readPropertyList"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.readPropertyList"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.writeText"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.writeText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.writeText"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["filesystem.appendText"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.appendText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.appendText"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["filesystem.move"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.move"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["filesystem.createDirectory"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.rollbackMove"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.rollbackMove"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["filesystem.rollbackTextWrite"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.rollbackTextWrite"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.rollbackTextWrite"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["clipboard.state"]?["domain"] as? String, "clipboard")
        XCTAssertEqual(actionByName["clipboard.state"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["clipboard.state"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["clipboard.wait"]?["domain"] as? String, "clipboard")
        XCTAssertEqual(actionByName["clipboard.wait"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["clipboard.wait"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["clipboard.readText"]?["domain"] as? String, "clipboard")
        XCTAssertEqual(actionByName["clipboard.readText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["clipboard.readText"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["clipboard.writeText"]?["domain"] as? String, "clipboard")
        XCTAssertEqual(actionByName["clipboard.writeText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["clipboard.writeText"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["clipboard.rollbackText"]?["domain"] as? String, "clipboard")
        XCTAssertEqual(actionByName["clipboard.rollbackText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["clipboard.rollbackText"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.listTabs"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.listTabs"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.listTabs"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.inspectTab"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.inspectTab"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.inspectTab"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.readText"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.readText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.readText"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.captureScreenshot"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.captureScreenshot"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.captureScreenshot"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.readConsole"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.readConsole"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.readConsole"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.readDialogs"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.readDialogs"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.readDialogs"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.readNetwork"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.readNetwork"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.readNetwork"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.readDOM"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.readDOM"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.readDOM"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.fillFormField"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.fillFormField"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.fillFormField"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.selectOption"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.selectOption"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.selectOption"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.setChecked"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.setChecked"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.setChecked"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.focusElement"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.focusElement"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.focusElement"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.pressKey"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.pressKey"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.pressKey"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.clickElement"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.clickElement"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.clickElement"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.navigate"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.navigate"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.navigate"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.waitURL"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitURL"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitURL"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitSelector"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitSelector"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitSelector"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitCount"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitCount"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitCount"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitText"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitText"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitText"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitElementText"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitElementText"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitElementText"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitValue"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitValue"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitValue"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitReady"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitReady"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitReady"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitTitle"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitTitle"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitTitle"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitChecked"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitChecked"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitChecked"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitEnabled"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitEnabled"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitEnabled"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitFocus"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitFocus"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitFocus"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitAttribute"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitAttribute"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitAttribute"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["task.memoryStart"]?["domain"] as? String, "task")
        XCTAssertEqual(actionByName["task.memoryStart"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["task.memoryStart"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["task.memoryRecord"]?["domain"] as? String, "task")
        XCTAssertEqual(actionByName["task.memoryRecord"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["task.memoryRecord"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["task.memoryFinish"]?["domain"] as? String, "task")
        XCTAssertEqual(actionByName["task.memoryFinish"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["task.memoryFinish"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["task.memoryShow"]?["domain"] as? String, "task")
        XCTAssertEqual(actionByName["task.memoryShow"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["task.memoryShow"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["workflow.logRead"]?["domain"] as? String, "workflow")
        XCTAssertEqual(actionByName["workflow.logRead"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["workflow.logRead"]?["mutates"] as? Bool, false)
    }

    func testWorkflowPreflightInspectSystemBuildsSystemContextCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-system"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["operation"] as? String, "inspect-system")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "system", "context"
        ])
    }

    func testWorkflowPreflightInspectDisplaysBuildsDesktopDisplaysCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-displays"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["operation"] as? String, "inspect-displays")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "desktop", "displays"
        ])
    }

    func testWorkflowPreflightInspectActiveWindowBuildsDesktopActiveWindowCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-active-window"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["operation"] as? String, "inspect-active-window")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "desktop", "active-window"
        ])
    }

    func testWorkflowPreflightWaitActiveWindowBuildsDesktopWaitCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-active-window",
            "--title", "Export",
            "--match", "contains",
            "--changed-from", "desktopWindow:previous",
            "--wait-timeout-ms", "2500",
            "--interval-ms", "75"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["operation"] as? String, "wait-active-window")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "desktop", "wait-active-window",
            "--title", "Export",
            "--changed-from", "desktopWindow:previous",
            "--match", "contains",
            "--timeout-ms", "2500",
            "--interval-ms", "75"
        ])
    }

    func testWorkflowPreflightInspectWindowsBuildsDesktopWindowsCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-windows",
            "--limit", "12",
            "--title", "Example",
            "--match", "contains",
            "--include-desktop",
            "--all-layers"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["operation"] as? String, "inspect-windows")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "desktop", "windows",
            "--limit", "12",
            "--title", "Example",
            "--match", "contains",
            "--include-desktop",
            "--all-layers"
        ])
    }

    func testWorkflowPreflightInspectProcessesBuildsProcessListCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-processes",
            "--name", "Finder",
            "--limit", "15"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["operation"] as? String, "inspect-processes")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "processes", "list",
            "--limit", "15",
            "--name", "Finder"
        ])
    }

    func testWorkflowRunExecutesNonMutatingSystemContextAndCapturesJSON() throws {
        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-system-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "inspect-system",
            "--workflow-log", workflowLog.path,
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "inspect-system")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "system", "context"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["platform"] as? String, "macOS")
        XCTAssertNotNil(outputJSON["currentDirectory"] as? String)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesNonMutatingAuditReviewAndCapturesJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-audit-review-run-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data().write(to: auditLog)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "review-audit",
            "--workflow-log", workflowLog.path,
            "--audit-log", auditLog.path,
            "--id", "missing-audit-id",
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "review-audit")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "audit",
            "--limit", "1",
            "--id", "missing-audit-id",
            "--audit-log", auditLog.path
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["path"] as? String, auditLog.path)
        XCTAssertEqual(outputJSON["id"] as? String, "missing-audit-id")
        XCTAssertEqual((outputJSON["entries"] as? [Any])?.count, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesNonMutatingDisplayInspectAndCapturesJSON() throws {
        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-displays-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "inspect-displays",
            "--workflow-log", workflowLog.path,
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "inspect-displays")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "desktop", "displays"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["platform"] as? String, "macOS")
        XCTAssertNotNil(outputJSON["available"] as? Bool)
        XCTAssertNotNil(outputJSON["displays"] as? [[String: Any]])
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesNonMutatingActiveWindowInspectAndCapturesJSON() throws {
        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-active-window-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "inspect-active-window",
            "--workflow-log", workflowLog.path,
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "inspect-active-window")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "desktop", "active-window"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["platform"] as? String, "macOS")
        XCTAssertNotNil(outputJSON["available"] as? Bool)
        XCTAssertNotNil(outputJSON["found"] as? Bool)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesNonMutatingActiveWindowWaitAndCapturesJSON() throws {
        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-wait-active-window-\(UUID().uuidString).jsonl")
        let changedFrom = "desktopWindow:unlikely-\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "wait-active-window",
            "--workflow-log", workflowLog.path,
            "--changed-from", changedFrom,
            "--wait-timeout-ms", "100",
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let verification = try XCTUnwrap(outputJSON["verification"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "wait-active-window")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "desktop", "wait-active-window",
            "--changed-from", changedFrom,
            "--match", "contains",
            "--timeout-ms", "100",
            "--interval-ms", "100"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["platform"] as? String, "macOS")
        XCTAssertNotNil(verification["matched"] as? Bool)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesNonMutatingWindowInspectAndCapturesJSON() throws {
        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-windows-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "inspect-windows",
            "--workflow-log", workflowLog.path,
            "--limit", "10",
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let windows = try XCTUnwrap(outputJSON["windows"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "inspect-windows")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "desktop", "windows",
            "--limit", "10"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["platform"] as? String, "macOS")
        XCTAssertNotNil(outputJSON["available"] as? Bool)
        XCTAssertEqual(outputJSON["limit"] as? Int, 10)
        XCTAssertEqual(outputJSON["count"] as? Int, windows.count)
        XCTAssertLessThanOrEqual(windows.count, 10)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesNonMutatingProcessListAndCapturesJSON() throws {
        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-processes-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "inspect-processes",
            "--workflow-log", workflowLog.path,
            "--limit", "10",
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let processes = try XCTUnwrap(outputJSON["processes"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "inspect-processes")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "processes", "list",
            "--limit", "10"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["platform"] as? String, "macOS")
        XCTAssertEqual(outputJSON["limit"] as? Int, 10)
        XCTAssertEqual(outputJSON["count"] as? Int, processes.count)
        XCTAssertLessThanOrEqual(processes.count, 10)
        XCTAssertTrue(processes.contains { $0["currentProcess"] as? Bool == true })
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowResumeSuggestsObserveAfterSystemInspect() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-system-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "inspect-system-transcript",
            "operation": "inspect-system",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": ["Ln1", "system", "context"],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "platform": "macOS",
                    "currentDirectory": packageRoot.path,
                    "architecture": "arm64"
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-system",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-system")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "observe",
            "--app-limit", "20",
            "--window-limit", "20"
        ])
    }

    func testWorkflowResumeSuggestsObserveAfterDisplayInspect() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-displays-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "inspect-displays-transcript",
            "operation": "inspect-displays",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": ["Ln1", "desktop", "displays"],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "platform": "macOS",
                    "available": true,
                    "count": 0,
                    "displays": []
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-displays",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-displays")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "observe",
            "--app-limit", "20",
            "--window-limit", "20"
        ])
    }

    func testWorkflowResumeSuggestsProcessInspectionAfterActiveWindowInspect() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-active-window-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "inspect-active-window-transcript",
            "operation": "inspect-active-window",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "desktop", "active-window"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "platform": "macOS",
                    "available": true,
                    "found": true,
                    "window": [
                        "id": "window:100",
                        "ownerPID": 456,
                        "ownerName": "Example",
                        "ownerBundleIdentifier": "com.example.App",
                        "active": true,
                        "title": "Example Window"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-active-window",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-active-window")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-process",
            "--pid", "456",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
    }

    func testWorkflowResumeSuggestsProcessInspectionAfterActiveWindowWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-wait-active-window-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "wait-active-window-transcript",
            "operation": "wait-active-window",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "desktop", "wait-active-window",
                    "--title", "Example"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "platform": "macOS",
                    "verification": [
                        "ok": true,
                        "matched": true,
                        "current": [
                            "id": "window:100",
                            "ownerPID": 456,
                            "ownerName": "Example",
                            "ownerBundleIdentifier": "com.example.App",
                            "active": true,
                            "title": "Example Window"
                        ]
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-active-window",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-active-window")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-process",
            "--pid", "456",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
    }

    func testWorkflowResumeSuggestsProcessInspectionAfterWindowInspect() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-windows-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "inspect-windows-transcript",
            "operation": "inspect-windows",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "desktop", "windows",
                    "--limit", "10"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "platform": "macOS",
                    "available": true,
                    "count": 1,
                    "windows": [
                        [
                            "id": "window:100",
                            "ownerPID": 456,
                            "ownerName": "Example",
                            "ownerBundleIdentifier": "com.example.App",
                            "active": false,
                            "title": "Example Window"
                        ]
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-windows",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-windows")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-process",
            "--pid", "456",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
    }

    func testWorkflowResumeSuggestsProcessInspectionAfterProcessListInspect() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-processes-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "inspect-processes-transcript",
            "operation": "inspect-processes",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "processes", "list",
                    "--limit", "10"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "platform": "macOS",
                    "count": 2,
                    "processes": [
                        [
                            "pid": 111,
                            "name": "First",
                            "activeApp": false,
                            "currentProcess": false
                        ],
                        [
                            "pid": 222,
                            "name": "Active",
                            "bundleIdentifier": "com.example.App",
                            "activeApp": true,
                            "currentProcess": false
                        ]
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-processes",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-processes")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-process",
            "--pid", "222",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
    }

    func testDesktopWindowsReturnsStructuredVisibleWindowInventory() throws {
        let result = try runLn1([
            "desktop",
            "windows",
            "--limit", "25"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let windows = try XCTUnwrap(object["windows"] as? [[String: Any]])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertNotNil(object["available"] as? Bool)
        XCTAssertNotNil(object["message"] as? String)
        XCTAssertEqual(object["includeDesktop"] as? Bool, false)
        XCTAssertEqual(object["includeAllLayers"] as? Bool, false)
        XCTAssertEqual(object["limit"] as? Int, 25)
        XCTAssertEqual(object["count"] as? Int, windows.count)
        XCTAssertLessThanOrEqual(windows.count, 25)

        if let first = windows.first {
            XCTAssertNotNil(first["id"] as? String)
            let stableIdentity = try XCTUnwrap(first["stableIdentity"] as? [String: Any])
            XCTAssertNotNil(stableIdentity["id"] as? String)
            XCTAssertEqual(stableIdentity["kind"] as? String, "desktopWindow")
            XCTAssertNotNil(stableIdentity["confidence"] as? String)
            XCTAssertNotNil(stableIdentity["label"] as? String)
            XCTAssertNotNil(stableIdentity["components"] as? [String: String])
            XCTAssertNotNil(stableIdentity["reasons"] as? [String])
            XCTAssertNotNil(first["windowNumber"] as? Int)
            XCTAssertNotNil(first["ownerPID"] as? Int)
            XCTAssertNotNil(first["active"] as? Bool)
            XCTAssertNotNil(first["layer"] as? Int)
            if let bounds = first["bounds"] as? [String: Any] {
                XCTAssertNotNil(bounds["x"] as? Double)
                XCTAssertNotNil(bounds["y"] as? Double)
                XCTAssertNotNil(bounds["width"] as? Double)
                XCTAssertNotNil(bounds["height"] as? Double)
            }
        }
    }

    func testDesktopWindowsCanFilterByTitleWithoutScreenshots() throws {
        let title = "Ln1-missing-window-\(UUID().uuidString)"
        let result = try runLn1([
            "desktop",
            "windows",
            "--title", title,
            "--match", "exact",
            "--limit", "10"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let filter = try XCTUnwrap(object["filter"] as? [String: Any])
        let windows = try XCTUnwrap(object["windows"] as? [[String: Any]])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["limit"] as? Int, 10)
        XCTAssertEqual(object["count"] as? Int, windows.count)
        XCTAssertEqual(filter["title"] as? String, title)
        XCTAssertEqual(filter["titleMatch"] as? String, "exact")
        XCTAssertNil(filter["ownerPID"])
        XCTAssertNil(filter["bundleIdentifier"])
        XCTAssertTrue(windows.isEmpty)
    }

    func testDesktopActiveWindowReturnsFrontmostWindowMetadata() throws {
        let result = try runLn1([
            "desktop",
            "active-window"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertNotNil(object["available"] as? Bool)
        XCTAssertNotNil(object["found"] as? Bool)
        XCTAssertNotNil(object["message"] as? String)

        if object["found"] as? Bool == true {
            let window = try XCTUnwrap(object["window"] as? [String: Any])
            let stableIdentity = try XCTUnwrap(window["stableIdentity"] as? [String: Any])
            XCTAssertNotNil(window["id"] as? String)
            XCTAssertNotNil(window["windowNumber"] as? Int)
            XCTAssertNotNil(window["ownerPID"] as? Int)
            XCTAssertNotNil(window["active"] as? Bool)
            XCTAssertEqual(window["layer"] as? Int, 0)
            XCTAssertEqual(stableIdentity["kind"] as? String, "desktopWindow")
            XCTAssertNotNil(stableIdentity["id"] as? String)
        }
    }

    func testDesktopMinimizeActiveWindowPolicyDenialIsAuditedWithoutMinimizing() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-desktop-minimize-denied-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "desktop",
            "minimize-active-window",
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(result.status, 0)
        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "desktop.minimize-active-window")
        XCTAssertEqual(entry["action"] as? String, "desktop.minimizeActiveWindow")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testDesktopRestoreWindowPolicyDenialIsAuditedWithoutRestoring() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-desktop-restore-denied-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "desktop",
            "restore-window",
            "--element", "w0",
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(result.status, 0)
        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "desktop.restore-window")
        XCTAssertEqual(entry["action"] as? String, "desktop.restoreWindow")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testDesktopRaiseWindowPolicyDenialIsAuditedWithoutRaising() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-desktop-raise-denied-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "desktop",
            "raise-window",
            "--element", "w0",
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(result.status, 0)
        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "desktop.raise-window")
        XCTAssertEqual(entry["action"] as? String, "desktop.raiseWindow")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testDesktopSetWindowFramePolicyDenialIsAuditedWithoutMovingWindow() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-desktop-frame-denied-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "desktop",
            "set-window-frame",
            "--element", "w0",
            "--x", "10",
            "--y", "20",
            "--width", "640",
            "--height", "480",
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(result.status, 0)
        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "desktop.set-window-frame")
        XCTAssertEqual(entry["action"] as? String, "desktop.setWindowFrame")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testDesktopWaitActiveWindowReturnsStructuredVerification() throws {
        let result = try runLn1([
            "desktop",
            "wait-active-window",
            "--changed-from", "desktopWindow:unlikely-\(UUID().uuidString)",
            "--timeout-ms", "0",
            "--interval-ms", "10"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])
        let target = try XCTUnwrap(verification["target"] as? [String: Any])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 0)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 10)
        XCTAssertNotNil(verification["ok"] as? Bool)
        XCTAssertNotNil(verification["code"] as? String)
        XCTAssertNotNil(verification["found"] as? Bool)
        XCTAssertNotNil(verification["changed"] as? Bool)
        XCTAssertNotNil(verification["matched"] as? Bool)
        XCTAssertNotNil(target["changedFrom"] as? String)

        if verification["found"] as? Bool == true {
            let current = try XCTUnwrap(verification["current"] as? [String: Any])
            XCTAssertNotNil(current["id"] as? String)
            XCTAssertNotNil(current["ownerPID"] as? Int)
        }
    }

    func testDesktopDisplaysReturnsStructuredDisplayTopology() throws {
        let result = try runLn1([
            "desktop",
            "displays"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let displays = try XCTUnwrap(object["displays"] as? [[String: Any]])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertNotNil(object["available"] as? Bool)
        XCTAssertNotNil(object["message"] as? String)
        XCTAssertEqual(object["count"] as? Int, displays.count)

        if object["available"] as? Bool == true {
            XCTAssertGreaterThanOrEqual(displays.count, 1)
            let first = try XCTUnwrap(displays.first)
            XCTAssertNotNil(first["id"] as? String)
            XCTAssertNotNil(first["displayID"] as? Int)
            XCTAssertNotNil(first["main"] as? Bool)
            XCTAssertNotNil(first["active"] as? Bool)
            XCTAssertNotNil(first["online"] as? Bool)
            XCTAssertNotNil(first["builtin"] as? Bool)
            XCTAssertNotNil(first["inMirrorSet"] as? Bool)
            XCTAssertNotNil(first["pixelWidth"] as? Int)
            XCTAssertNotNil(first["pixelHeight"] as? Int)
            XCTAssertNotNil(first["rotationDegrees"] as? Double)
            let bounds = try XCTUnwrap(first["bounds"] as? [String: Any])
            XCTAssertNotNil(bounds["x"] as? Double)
            XCTAssertNotNil(bounds["y"] as? Double)
            XCTAssertNotNil(bounds["width"] as? Double)
            XCTAssertNotNil(bounds["height"] as? Double)
        }
    }

    func testDesktopScreenshotReturnsBoundedVisualSnapshotMetadata() throws {
        let result = try runLn1([
            "desktop",
            "screenshot",
            "--allow-risk", "medium",
            "--max-sample-bytes", "4096",
            "--include-ocr", "true",
            "--max-ocr-characters", "256"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let displays = try XCTUnwrap(object["displays"] as? [[String: Any]])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["action"] as? String, "desktop.screenshot")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["maxSampleBytes"] as? Int, 4096)
        XCTAssertEqual(object["includeOCR"] as? Bool, true)
        XCTAssertEqual(object["maxOCRCharacters"] as? Int, 256)
        XCTAssertEqual(object["displayCount"] as? Int, displays.count)
        let message = try XCTUnwrap(object["message"] as? String)
        if displays.isEmpty {
            XCTAssertTrue(message.contains("No online displays"), message)
        }

        if let first = displays.first {
            XCTAssertNotNil(first["id"] as? String)
            XCTAssertNotNil(first["displayID"] as? Int)
            XCTAssertNotNil(first["pixelWidth"] as? Int)
            XCTAssertNotNil(first["pixelHeight"] as? Int)
            XCTAssertNotNil(first["captured"] as? Bool)
            XCTAssertNotNil(first["sampleByteCount"] as? Int)
            let ocr = try XCTUnwrap(first["ocr"] as? [String: Any])
            XCTAssertEqual(ocr["requested"] as? Bool, true)
            XCTAssertNotNil(ocr["available"] as? Bool)
            XCTAssertNotNil(ocr["observationCount"] as? Int)
            XCTAssertNotNil(ocr["textLength"] as? Int)
            XCTAssertNotNil(ocr["truncated"] as? Bool)
            XCTAssertNotNil(ocr["message"] as? String)

            if first["captured"] as? Bool == true {
                XCTAssertNotNil(first["imageWidth"] as? Int)
                XCTAssertNotNil(first["imageHeight"] as? Int)
                XCTAssertNotNil(first["sampleDigest"] as? String)
                XCTAssertLessThanOrEqual(try XCTUnwrap(first["sampleByteCount"] as? Int), 4096)
                if let text = ocr["text"] as? String {
                    XCTAssertLessThanOrEqual(text.count, 256)
                }
            }
        }
    }

    func testInputPointerReturnsGlobalPointerMetadata() throws {
        let result = try runLn1([
            "input",
            "pointer"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["action"] as? String, "input.pointer")
        XCTAssertNotNil(object["available"] as? Bool)
        XCTAssertNotNil(object["message"] as? String)

        if object["available"] as? Bool == true {
            let position = try XCTUnwrap(object["position"] as? [String: Any])
            XCTAssertNotNil(position["x"] as? Double)
            XCTAssertNotNil(position["y"] as? Double)
        }
    }

    func testInputMoveDryRunValidatesAndAuditsWithoutMovingPointer() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-input-move-dry-run-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "input",
            "move",
            "--x", "12",
            "--y", "34",
            "--allow-risk", "medium",
            "--dry-run", "true",
            "--reason", "plan pointer move",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let target = try XCTUnwrap(object["to"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "input.movePointer")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(target["x"] as? Double, 12)
        XCTAssertEqual(target["y"] as? Double, 34)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "dry_run")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])
        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "input.move")
        XCTAssertEqual(entry["action"] as? String, "input.movePointer")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "plan pointer move")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "dry_run")
    }

    func testInputDragDryRunValidatesAndAuditsWithoutDraggingPointer() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-input-drag-dry-run-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "input",
            "drag",
            "--from-x", "10",
            "--from-y", "20",
            "--to-x", "30",
            "--to-y", "40",
            "--steps", "4",
            "--allow-risk", "medium",
            "--dry-run", "true",
            "--reason", "plan pointer drag",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let start = try XCTUnwrap(object["from"] as? [String: Any])
        let target = try XCTUnwrap(object["to"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "input.dragPointer")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["steps"] as? Int, 4)
        XCTAssertEqual(start["x"] as? Double, 10)
        XCTAssertEqual(start["y"] as? Double, 20)
        XCTAssertEqual(target["x"] as? Double, 30)
        XCTAssertEqual(target["y"] as? Double, 40)
        XCTAssertEqual(verification["code"] as? String, "dry_run")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])
        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "input.drag")
        XCTAssertEqual(entry["action"] as? String, "input.dragPointer")
        XCTAssertEqual(entry["reason"] as? String, "plan pointer drag")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "dry_run")
    }

    func testInputScrollDryRunValidatesAndAuditsWithoutScrolling() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-input-scroll-dry-run-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "input",
            "scroll",
            "--dx", "3",
            "--dy", "-12",
            "--allow-risk", "medium",
            "--dry-run", "true",
            "--reason", "plan scroll",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "input.scrollWheel")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["deltaX"] as? Int, 3)
        XCTAssertEqual(object["deltaY"] as? Int, -12)
        XCTAssertEqual(verification["code"] as? String, "dry_run")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])
        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "input.scroll")
        XCTAssertEqual(entry["action"] as? String, "input.scrollWheel")
        XCTAssertEqual(entry["reason"] as? String, "plan scroll")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "dry_run")
    }

    func testInputKeyDryRunValidatesAndAuditsWithoutPostingKeyboardInput() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-input-key-dry-run-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "input",
            "key",
            "--key", "k",
            "--modifiers", "command,shift",
            "--allow-risk", "medium",
            "--dry-run", "true",
            "--reason", "plan key",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "input.pressKey")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["key"] as? String, "k")
        XCTAssertEqual(object["keyCode"] as? Int, 40)
        XCTAssertEqual(object["modifiers"] as? [String], ["meta", "shift"])
        XCTAssertEqual(verification["code"] as? String, "dry_run")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])
        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "input.key")
        XCTAssertEqual(entry["action"] as? String, "input.pressKey")
        XCTAssertEqual(entry["reason"] as? String, "plan key")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "dry_run")
    }

    func testInputTypeDryRunAuditsMetadataWithoutTextContents() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-input-type-dry-run-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "input",
            "type",
            "--text", "hello",
            "--allow-risk", "medium",
            "--dry-run", "true",
            "--reason", "plan text",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "input.typeText")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["textLength"] as? Int, 5)
        XCTAssertNotNil(object["textDigest"] as? String)
        XCTAssertNil(object["text"])
        XCTAssertEqual(verification["code"] as? String, "dry_run")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])
        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "input.type")
        XCTAssertEqual(entry["action"] as? String, "input.typeText")
        XCTAssertEqual(entry["reason"] as? String, "plan text")
        XCTAssertNil(entry["text"])
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "dry_run")
    }

    func testDesktopWaitWindowReturnsStructuredExistenceVerification() throws {
        let unlikelyTitle = "Ln1 nonexistent window \(UUID().uuidString)"
        let result = try runLn1([
            "desktop",
            "wait-window",
            "--title", unlikelyTitle,
            "--match", "exact",
            "--exists", "false",
            "--timeout-ms", "0",
            "--interval-ms", "10",
            "--limit", "20"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])
        let target = try XCTUnwrap(verification["target"] as? [String: Any])
        let current = try XCTUnwrap(verification["current"] as? [[String: Any]])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 0)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 10)
        XCTAssertEqual(object["includeDesktop"] as? Bool, false)
        XCTAssertEqual(object["includeAllLayers"] as? Bool, false)
        XCTAssertEqual(object["limit"] as? Int, 20)
        XCTAssertEqual(target["title"] as? String, unlikelyTitle)
        XCTAssertEqual(target["titleMatch"] as? String, "exact")
        XCTAssertEqual(verification["expectedExists"] as? Bool, false)
        XCTAssertEqual(verification["currentCount"] as? Int, current.count)

        if verification["code"] as? String != "desktop_window_metadata_unavailable" {
            XCTAssertEqual(verification["ok"] as? Bool, true)
            XCTAssertEqual(verification["matched"] as? Bool, true)
            XCTAssertEqual(current.count, 0)
        }
    }

    func testObserveReturnsStructuredFirstStepSnapshot() throws {
        let result = try runLn1([
            "observe",
            "--app-limit", "5",
            "--window-limit", "3"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let accessibility = try XCTUnwrap(object["accessibility"] as? [String: Any])
        let apps = try XCTUnwrap(object["apps"] as? [[String: Any]])
        let desktop = try XCTUnwrap(object["desktop"] as? [String: Any])
        let blockers = try XCTUnwrap(object["blockers"] as? [String])
        let suggestedActions = try XCTUnwrap(object["suggestedActions"] as? [[String: Any]])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["appLimit"] as? Int, 5)
        XCTAssertLessThanOrEqual(apps.count, 5)
        XCTAssertEqual(object["appCount"] as? Int, apps.count)
        XCTAssertNotNil(object["appsTruncated"] as? Bool)
        XCTAssertNotNil(accessibility["trusted"] as? Bool)
        XCTAssertNotNil(accessibility["message"] as? String)
        XCTAssertEqual(desktop["limit"] as? Int, 3)
        XCTAssertNotNil(desktop["available"] as? Bool)
        XCTAssertNotNil(blockers)
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "system.context" })
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "desktop.listWindows" })
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "desktop.activeWindow" })
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "desktop.waitActiveWindow" })
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "desktop.waitWindow" })
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "desktop.listDisplays" })
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "apps.list" })
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "apps.active" })
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "apps.installed" })
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "processes.list" })
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "clipboard.state" })
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "clipboard.wait" })
        if accessibility["trusted"] as? Bool == true {
            XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "accessibility.findElement" })
        }
    }

    func testAppsInstalledListsLaunchableBundleMetadata() throws {
        guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.finder") != nil else {
            throw XCTSkip("Finder application bundle was not available from LaunchServices.")
        }

        let result = try runLn1([
            "apps",
            "installed",
            "--bundle-id", "com.apple.finder",
            "--limit", "5"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let apps = try XCTUnwrap(object["apps"] as? [[String: Any]])
        let first = try XCTUnwrap(apps.first)

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["limit"] as? Int, 5)
        XCTAssertEqual(object["count"] as? Int, apps.count)
        XCTAssertLessThanOrEqual(apps.count, 5)
        XCTAssertNotNil(object["truncated"] as? Bool)
        XCTAssertEqual(first["bundleIdentifier"] as? String, "com.apple.finder")
        XCTAssertNotNil(first["name"] as? String)
        XCTAssertNotNil(first["path"] as? String)
    }

    func testAppsListReturnsBoundedStructuredRunningAppState() throws {
        let result = try runLn1([
            "apps",
            "list",
            "--limit", "10"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let apps = try XCTUnwrap(object["apps"] as? [[String: Any]])
        let first = try XCTUnwrap(apps.first)

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["includeAll"] as? Bool, false)
        XCTAssertEqual(object["limit"] as? Int, 10)
        XCTAssertEqual(object["count"] as? Int, apps.count)
        XCTAssertLessThanOrEqual(apps.count, 10)
        XCTAssertNotNil(object["truncated"] as? Bool)
        XCTAssertNotNil(object["message"] as? String)
        XCTAssertNotNil(first["pid"] as? Int)
        XCTAssertNotNil(first["active"] as? Bool)
        XCTAssertNotNil(first["hidden"] as? Bool)
    }

    func testAppsActiveReturnsFrontmostAppMetadata() throws {
        let result = try runLn1([
            "apps",
            "active"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertNotNil(object["found"] as? Bool)
        XCTAssertNotNil(object["message"] as? String)
        if object["found"] as? Bool == true {
            let app = try XCTUnwrap(object["app"] as? [String: Any])
            XCTAssertNotNil(app["pid"] as? Int)
        }
    }

    func testAppsPlanPreflightsActivationWithoutChangingFocus() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let result = try runLn1([
            "apps",
            "plan",
            "--operation", "activate",
            "--pid", "\(pid)"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let policy = try XCTUnwrap(object["policy"] as? [String: Any])
        let target = try XCTUnwrap(object["target"] as? [String: Any])
        let checks = try XCTUnwrap(object["checks"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "activate")
        XCTAssertEqual(object["action"] as? String, "apps.activate")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["actionMutates"] as? Bool, true)
        XCTAssertEqual(object["requiredAllowRisk"] as? String, "medium")
        XCTAssertEqual(object["canExecute"] as? Bool, false)
        XCTAssertEqual(target["pid"] as? Int, pid)
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertTrue(checks.contains { $0["name"] as? String == "apps.targetRunning" })
        XCTAssertTrue(checks.contains { $0["name"] as? String == "apps.targetActivatable" })
    }

    func testAppsPlanPreflightsLaunchWithoutOpeningApp() throws {
        guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.finder") != nil else {
            throw XCTSkip("Finder application bundle was not available from LaunchServices.")
        }

        let result = try runLn1([
            "apps",
            "plan",
            "--operation", "launch",
            "--bundle-id", "com.apple.finder",
            "--activate", "false",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let policy = try XCTUnwrap(object["policy"] as? [String: Any])
        let target = try XCTUnwrap(object["target"] as? [String: Any])
        let checks = try XCTUnwrap(object["checks"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "launch")
        XCTAssertEqual(object["action"] as? String, "apps.launch")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["actionMutates"] as? Bool, true)
        XCTAssertEqual(object["requiredAllowRisk"] as? String, "medium")
        XCTAssertEqual(object["canExecute"] as? Bool, true)
        XCTAssertEqual(object["activate"] as? Bool, false)
        XCTAssertEqual(target["bundleIdentifier"] as? String, "com.apple.finder")
        XCTAssertNotNil(target["path"] as? String)
        XCTAssertEqual(policy["allowedRisk"] as? String, "medium")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertTrue(checks.contains {
            $0["name"] as? String == "apps.launchTarget"
                && $0["code"] as? String == "launch_target_found"
                && $0["ok"] as? Bool == true
        })
    }

    func testAppsPlanPreflightsHideWithoutHidingApp() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let result = try runLn1([
            "apps",
            "plan",
            "--operation", "hide",
            "--pid", "\(pid)",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let policy = try XCTUnwrap(object["policy"] as? [String: Any])
        let target = try XCTUnwrap(object["target"] as? [String: Any])
        let checks = try XCTUnwrap(object["checks"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "hide")
        XCTAssertEqual(object["action"] as? String, "apps.hide")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["actionMutates"] as? Bool, true)
        XCTAssertEqual(object["requiredAllowRisk"] as? String, "medium")
        XCTAssertEqual(object["canExecute"] as? Bool, true)
        XCTAssertEqual(target["pid"] as? Int, pid)
        XCTAssertNotNil(target["hidden"] as? Bool)
        XCTAssertEqual(policy["allowedRisk"] as? String, "medium")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertTrue(checks.contains { $0["name"] as? String == "apps.targetRunning" })
        XCTAssertTrue(checks.contains { $0["name"] as? String == "apps.targetGUI" })
    }

    func testAppsPlanPreflightsUnhideWithoutUnhidingApp() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let result = try runLn1([
            "apps",
            "plan",
            "--operation", "unhide",
            "--pid", "\(pid)",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let policy = try XCTUnwrap(object["policy"] as? [String: Any])
        let target = try XCTUnwrap(object["target"] as? [String: Any])
        let checks = try XCTUnwrap(object["checks"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "unhide")
        XCTAssertEqual(object["action"] as? String, "apps.unhide")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["actionMutates"] as? Bool, true)
        XCTAssertEqual(object["requiredAllowRisk"] as? String, "medium")
        XCTAssertEqual(object["canExecute"] as? Bool, true)
        XCTAssertEqual(target["pid"] as? Int, pid)
        XCTAssertNotNil(target["hidden"] as? Bool)
        XCTAssertEqual(policy["allowedRisk"] as? String, "medium")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertTrue(checks.contains { $0["name"] as? String == "apps.targetRunning" })
        XCTAssertTrue(checks.contains { $0["name"] as? String == "apps.targetGUI" })
    }

    func testAppsPlanPreflightsQuitWithoutQuittingApp() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let result = try runLn1([
            "apps",
            "plan",
            "--operation", "quit",
            "--pid", "\(pid)",
            "--allow-risk", "high"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let policy = try XCTUnwrap(object["policy"] as? [String: Any])
        let target = try XCTUnwrap(object["target"] as? [String: Any])
        let checks = try XCTUnwrap(object["checks"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "quit")
        XCTAssertEqual(object["action"] as? String, "apps.quit")
        XCTAssertEqual(object["risk"] as? String, "high")
        XCTAssertEqual(object["actionMutates"] as? Bool, true)
        XCTAssertEqual(object["requiredAllowRisk"] as? String, "high")
        XCTAssertEqual(object["canExecute"] as? Bool, true)
        XCTAssertEqual(object["force"] as? Bool, false)
        XCTAssertEqual(target["pid"] as? Int, pid)
        XCTAssertEqual(policy["allowedRisk"] as? String, "high")
        XCTAssertEqual(policy["actionRisk"] as? String, "high")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertTrue(checks.contains { $0["name"] as? String == "apps.targetRunning" })
        XCTAssertTrue(checks.contains { $0["name"] as? String == "apps.targetNotCurrentProcess" })
        XCTAssertTrue(checks.contains { $0["name"] as? String == "apps.targetGUI" })
    }

    func testAppsWaitActiveReturnsMatchedFrontmostAppMetadata() throws {
        let apps = try runLn1(["apps", "--all"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        guard let active = records.first(where: { $0["active"] as? Bool == true }),
              let pid = active["pid"] as? Int else {
            throw XCTSkip("No active app record was available from macOS.")
        }

        let result = try runLn1([
            "apps",
            "wait-active",
            "--pid", "\(pid)",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])
        let target = try XCTUnwrap(verification["target"] as? [String: Any])
        let current = try XCTUnwrap(verification["current"] as? [String: Any])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "active_app_matched")
        XCTAssertEqual(verification["matched"] as? Bool, true)
        XCTAssertEqual(target["pid"] as? Int, pid)
        XCTAssertEqual(current["pid"] as? Int, pid)
    }

    func testAppsActivatePolicyDenialIsAuditedWithoutChangingFocus() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-app-activate-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let rejected = try runLn1([
            "apps",
            "activate",
            "--pid", "\(pid)",
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let app = try XCTUnwrap(entry["app"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "apps.activate")
        XCTAssertEqual(entry["action"] as? String, "apps.activate")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(app["pid"] as? Int, pid)
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testAppsLaunchPolicyDenialIsAuditedWithoutOpeningApp() throws {
        guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.finder") != nil else {
            throw XCTSkip("Finder application bundle was not available from LaunchServices.")
        }

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-app-launch-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let rejected = try runLn1([
            "apps",
            "launch",
            "--bundle-id", "com.apple.finder",
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let target = try XCTUnwrap(entry["appLaunchTarget"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "apps.launch")
        XCTAssertEqual(entry["action"] as? String, "apps.launch")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(target["bundleIdentifier"] as? String, "com.apple.finder")
        XCTAssertNotNil(target["path"] as? String)
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testAppsHidePolicyDenialIsAuditedWithoutHidingApp() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-app-hide-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let rejected = try runLn1([
            "apps",
            "hide",
            "--pid", "\(pid)",
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let app = try XCTUnwrap(entry["app"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "apps.hide")
        XCTAssertEqual(entry["action"] as? String, "apps.hide")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(app["pid"] as? Int, pid)
        XCTAssertNotNil(app["hidden"] as? Bool)
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testAppsUnhidePolicyDenialIsAuditedWithoutUnhidingApp() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-app-unhide-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let rejected = try runLn1([
            "apps",
            "unhide",
            "--pid", "\(pid)",
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let app = try XCTUnwrap(entry["app"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "apps.unhide")
        XCTAssertEqual(entry["action"] as? String, "apps.unhide")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(app["pid"] as? Int, pid)
        XCTAssertNotNil(app["hidden"] as? Bool)
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testAppsQuitPolicyDenialIsAuditedWithoutQuittingApp() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-app-quit-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let rejected = try runLn1([
            "apps",
            "quit",
            "--pid", "\(pid)",
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let app = try XCTUnwrap(entry["app"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "apps.quit")
        XCTAssertEqual(entry["action"] as? String, "apps.quit")
        XCTAssertEqual(entry["risk"] as? String, "high")
        XCTAssertEqual(app["pid"] as? Int, pid)
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "high")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testWorkflowPreflightActivateAppBuildsAuditedActivationCommand() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-app-activate-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "activate-app",
            "--pid", "\(pid)",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "activate-app")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "apps", "activate",
            "--pid", "\(pid)",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "apps.targetRunning" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.policy" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightLaunchAppBuildsAuditedLaunchCommand() throws {
        guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.finder") != nil else {
            throw XCTSkip("Finder application bundle was not available from LaunchServices.")
        }

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-app-launch-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "launch-app",
            "--bundle-id", "com.apple.finder",
            "--activate", "false",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "launch-app")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "apps", "launch",
            "--bundle-id", "com.apple.finder",
            "--activate", "false",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.appLaunchTarget" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.policy" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightHideAppBuildsAuditedHideCommand() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-app-hide-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "hide-app",
            "--pid", "\(pid)",
            "--wait-timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "hide-app")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "apps", "hide",
            "--pid", "\(pid)",
            "--timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "apps.targetRunning" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "apps.targetGUI" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.policy" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightUnhideAppBuildsAuditedUnhideCommand() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-app-unhide-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "unhide-app",
            "--pid", "\(pid)",
            "--wait-timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "unhide-app")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "apps", "unhide",
            "--pid", "\(pid)",
            "--timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "apps.targetRunning" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "apps.targetGUI" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.policy" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightMinimizeActiveWindowBuildsAuditedDesktopCommand() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility permission is required to preflight active window minimization.")
        }
        let activeWindow = try runLn1(["desktop", "active-window"])
        XCTAssertEqual(activeWindow.status, 0, activeWindow.stderr)
        let activeWindowObject = try decodeJSONObject(activeWindow.stdout)
        guard activeWindowObject["found"] as? Bool == true else {
            throw XCTSkip("No active desktop window was available to preflight minimization.")
        }

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-desktop-minimize-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "minimize-active-window",
            "--wait-timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "minimize-active-window")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "desktop", "minimize-active-window",
            "--timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "accessibility" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.activeWindow" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.policy" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightRestoreWindowBuildsAuditedDesktopCommand() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility permission is required to preflight window restoration.")
        }
        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        guard let firstWindow = windows.first,
              let elementID = firstWindow["id"] as? String else {
            throw XCTSkip("No Accessibility window was available for restore preflight.")
        }
        let settableAttributes = firstWindow["settableAttributes"] as? [String] ?? []
        guard settableAttributes.contains(kAXMinimizedAttribute as String) else {
            throw XCTSkip("The current Accessibility window does not expose settable AXMinimized.")
        }

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-desktop-restore-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "restore-window",
            "--pid", "\(pid)",
            "--element", elementID,
            "--wait-timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "restore-window")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "desktop", "restore-window",
            "--pid", "\(pid)",
            "--element", elementID,
            "--timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "accessibility" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowElement" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowRole" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowMinimizedSettable" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.policy" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightRaiseWindowBuildsAuditedDesktopCommand() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility permission is required to preflight window raising.")
        }
        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        guard let firstWindow = windows.first,
              let elementID = firstWindow["id"] as? String else {
            throw XCTSkip("No Accessibility window was available for raise preflight.")
        }
        let actions = firstWindow["actions"] as? [String] ?? []
        guard actions.contains(kAXRaiseAction as String) else {
            throw XCTSkip("The current Accessibility window does not expose AXRaise.")
        }

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-desktop-raise-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "raise-window",
            "--pid", "\(pid)",
            "--element", elementID,
            "--wait-timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "raise-window")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "desktop", "raise-window",
            "--pid", "\(pid)",
            "--element", elementID,
            "--timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "accessibility" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowElement" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowRole" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowRaiseAction" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.policy" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightSetWindowFrameBuildsAuditedDesktopCommand() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility permission is required to preflight window frame changes.")
        }
        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        guard let firstWindow = windows.first,
              let elementID = firstWindow["id"] as? String else {
            throw XCTSkip("No Accessibility window was available for frame preflight.")
        }
        let settableAttributes = firstWindow["settableAttributes"] as? [String] ?? []
        guard settableAttributes.contains(kAXPositionAttribute as String),
              settableAttributes.contains(kAXSizeAttribute as String),
              firstWindow["frame"] as? [String: Any] != nil else {
            throw XCTSkip("The current Accessibility window does not expose settable, readable geometry.")
        }

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-desktop-frame-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "set-window-frame",
            "--pid", "\(pid)",
            "--element", elementID,
            "--x", "10",
            "--y", "20",
            "--width", "640",
            "--height", "480",
            "--wait-timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "set-window-frame")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "desktop", "set-window-frame",
            "--pid", "\(pid)",
            "--element", elementID,
            "--x", "10.0",
            "--y", "20.0",
            "--width", "640.0",
            "--height", "480.0",
            "--timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "accessibility" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowElement" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowFrame" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowRole" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowPositionSettable" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowSizeSettable" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowFrameReadable" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.policy" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightQuitAppBuildsAuditedQuitCommand() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-app-quit-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "quit-app",
            "--pid", "\(pid)",
            "--force",
            "--wait-timeout-ms", "2500",
            "--interval-ms", "75",
            "--allow-risk", "high",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "quit-app")
        XCTAssertEqual(object["risk"] as? String, "high")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "apps", "quit",
            "--pid", "\(pid)",
            "--force",
            "--timeout-ms", "2500",
            "--interval-ms", "75",
            "--allow-risk", "high",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "apps.targetRunning" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "apps.targetNotCurrentProcess" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.policy" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightOpenFileBuildsAuditedOpenCommand() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-open-file-\(UUID().uuidString)")
        let target = directory.appendingPathComponent("artifact.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "artifact".write(to: target, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "open-file",
            "--path", target.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "open-file")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "open",
            "--path", target.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.workspaceOpenTarget" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.policy" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightOpenURLBuildsAuditedOpenCommand() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-open-url-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "open-url",
            "--url", "https://example.com/report",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["operation"] as? String, "open-url")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "open",
            "--url", "https://example.com/report",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
    }

    func testWorkflowRunDryRunOpenURLReturnsStructuredCommandWithoutOpeningURL() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-open-url-dry-run-\(UUID().uuidString).jsonl")
        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-open-url-dry-run-\(UUID().uuidString)-workflow.jsonl")
        defer {
            try? FileManager.default.removeItem(at: auditLog)
            try? FileManager.default.removeItem(at: workflowLog)
        }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "open-url",
            "--url", "https://example.com/report",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "true"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "open-url")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["executed"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "open",
            "--url", "https://example.com/report",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
    }

    func testOpenPlanReturnsDefaultHandlerMetadataWithoutOpeningTarget() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-open-plan-\(UUID().uuidString)")
        let target = directory.appendingPathComponent("artifact.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "artifact".write(to: target, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "open",
            "--path", target.path,
            "--plan",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let policy = try XCTUnwrap(object["policy"] as? [String: Any])
        let targetSummary = try XCTUnwrap(object["target"] as? [String: Any])

        XCTAssertEqual(object["action"] as? String, "workspace.open")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["actionMutates"] as? Bool, true)
        XCTAssertEqual(object["canExecute"] as? Bool, true)
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(targetSummary["kind"] as? String, "file")
        XCTAssertEqual(targetSummary["path"] as? String, target.path)
        if let handler = object["handler"] as? [String: Any] {
            XCTAssertNotNil(handler["path"] as? String)
        }
    }

    func testWorkflowRunDryRunActivateAppReturnsStructuredCommandWithoutChangingFocus() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-app-dry-run-\(UUID().uuidString)")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "activate-app",
            "--pid", "\(pid)",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "true"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "activate-app")
        XCTAssertEqual(object["mode"] as? String, "dry-run")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["executed"] as? Bool, false)
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "apps", "activate",
            "--pid", "\(pid)",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: auditLog.path))
    }

    func testWorkflowRunDryRunHideAppReturnsStructuredCommandWithoutHiding() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-app-hide-dry-run-\(UUID().uuidString)")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "hide-app",
            "--pid", "\(pid)",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "true"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "hide-app")
        XCTAssertEqual(object["mode"] as? String, "dry-run")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["executed"] as? Bool, false)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "apps", "hide",
            "--pid", "\(pid)",
            "--timeout-ms", "2000",
            "--interval-ms", "100",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: auditLog.path))
    }

    func testWorkflowRunDryRunUnhideAppReturnsStructuredCommandWithoutUnhiding() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-app-unhide-dry-run-\(UUID().uuidString)")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "unhide-app",
            "--pid", "\(pid)",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "true"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "unhide-app")
        XCTAssertEqual(object["mode"] as? String, "dry-run")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["executed"] as? Bool, false)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "apps", "unhide",
            "--pid", "\(pid)",
            "--timeout-ms", "2000",
            "--interval-ms", "100",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: auditLog.path))
    }

    func testWorkflowRunDryRunMinimizeActiveWindowReturnsStructuredCommandWithoutMinimizing() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility permission is required to preflight active window minimization.")
        }
        let activeWindow = try runLn1(["desktop", "active-window"])
        XCTAssertEqual(activeWindow.status, 0, activeWindow.stderr)
        let activeWindowObject = try decodeJSONObject(activeWindow.stdout)
        guard activeWindowObject["found"] as? Bool == true else {
            throw XCTSkip("No active desktop window was available to preflight minimization.")
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-desktop-minimize-dry-run-\(UUID().uuidString)")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "minimize-active-window",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "true"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "minimize-active-window")
        XCTAssertEqual(object["mode"] as? String, "dry-run")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["executed"] as? Bool, false)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "desktop", "minimize-active-window",
            "--timeout-ms", "2000",
            "--interval-ms", "100",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: auditLog.path))
    }

    func testWorkflowRunDryRunRestoreWindowReturnsStructuredCommandWithoutRestoring() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility permission is required to preflight window restoration.")
        }
        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        guard let firstWindow = windows.first,
              let elementID = firstWindow["id"] as? String else {
            throw XCTSkip("No Accessibility window was available for restore dry-run.")
        }
        let settableAttributes = firstWindow["settableAttributes"] as? [String] ?? []
        guard settableAttributes.contains(kAXMinimizedAttribute as String) else {
            throw XCTSkip("The current Accessibility window does not expose settable AXMinimized.")
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-desktop-restore-dry-run-\(UUID().uuidString)")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "restore-window",
            "--pid", "\(pid)",
            "--element", elementID,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "true"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "restore-window")
        XCTAssertEqual(object["mode"] as? String, "dry-run")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["executed"] as? Bool, false)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "desktop", "restore-window",
            "--pid", "\(pid)",
            "--element", elementID,
            "--timeout-ms", "2000",
            "--interval-ms", "100",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: auditLog.path))
    }

    func testWorkflowRunDryRunRaiseWindowReturnsStructuredCommandWithoutRaising() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility permission is required to preflight window raising.")
        }
        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        guard let firstWindow = windows.first,
              let elementID = firstWindow["id"] as? String else {
            throw XCTSkip("No Accessibility window was available for raise dry-run.")
        }
        let actions = firstWindow["actions"] as? [String] ?? []
        guard actions.contains(kAXRaiseAction as String) else {
            throw XCTSkip("The current Accessibility window does not expose AXRaise.")
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-desktop-raise-dry-run-\(UUID().uuidString)")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "raise-window",
            "--pid", "\(pid)",
            "--element", elementID,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "true"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "raise-window")
        XCTAssertEqual(object["mode"] as? String, "dry-run")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["executed"] as? Bool, false)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "desktop", "raise-window",
            "--pid", "\(pid)",
            "--element", elementID,
            "--timeout-ms", "2000",
            "--interval-ms", "100",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: auditLog.path))
    }

    func testWorkflowRunDryRunSetWindowFrameReturnsStructuredCommandWithoutMovingWindow() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility permission is required to preflight window frame changes.")
        }
        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        guard let firstWindow = windows.first,
              let elementID = firstWindow["id"] as? String else {
            throw XCTSkip("No Accessibility window was available for frame dry-run.")
        }
        let settableAttributes = firstWindow["settableAttributes"] as? [String] ?? []
        guard settableAttributes.contains(kAXPositionAttribute as String),
              settableAttributes.contains(kAXSizeAttribute as String),
              firstWindow["frame"] as? [String: Any] != nil else {
            throw XCTSkip("The current Accessibility window does not expose settable, readable geometry.")
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-desktop-frame-dry-run-\(UUID().uuidString)")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "set-window-frame",
            "--pid", "\(pid)",
            "--element", elementID,
            "--x", "10",
            "--y", "20",
            "--width", "640",
            "--height", "480",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "true"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "set-window-frame")
        XCTAssertEqual(object["mode"] as? String, "dry-run")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["executed"] as? Bool, false)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "desktop", "set-window-frame",
            "--pid", "\(pid)",
            "--element", elementID,
            "--x", "10.0",
            "--y", "20.0",
            "--width", "640.0",
            "--height", "480.0",
            "--timeout-ms", "2000",
            "--interval-ms", "100",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: auditLog.path))
    }

    func testWorkflowRunDryRunQuitAppReturnsStructuredCommandWithoutQuitting() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-app-quit-dry-run-\(UUID().uuidString)")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "quit-app",
            "--pid", "\(pid)",
            "--allow-risk", "high",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "true"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "quit-app")
        XCTAssertEqual(object["mode"] as? String, "dry-run")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["executed"] as? Bool, false)
        XCTAssertEqual(object["risk"] as? String, "high")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "apps", "quit",
            "--pid", "\(pid)",
            "--timeout-ms", "5000",
            "--interval-ms", "100",
            "--allow-risk", "high",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: auditLog.path))
    }

    func testWorkflowResumeSuggestsActiveInspectionAfterActivateApp() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-app-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "activate-app-transcript",
            "transcriptPath": workflowLog.path,
            "generatedAt": "2026-05-03T00:00:00Z",
            "platform": "macOS",
            "operation": "activate-app",
            "mode": "execute",
            "dryRun": false,
            "ready": true,
            "wouldExecute": true,
            "executed": true,
            "risk": "medium",
            "mutates": true,
            "blockers": [],
            "command": [
                "argv": [
                    "Ln1", "apps", "activate",
                    "--pid", "123",
                    "--allow-risk", "medium",
                    "--reason", "Inspect app"
                ]
            ],
            "execution": [
                "argv": [
                    "Ln1", "apps", "activate",
                    "--pid", "123",
                    "--allow-risk", "medium",
                    "--reason", "Inspect app"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "action": "apps.activate",
                    "target": [
                        "name": "Example",
                        "bundleIdentifier": "com.example.App",
                        "pid": 123
                    ],
                    "verification": [
                        "ok": true,
                        "code": "active_app_matched"
                    ]
                ]
            ],
            "preflight": [
                "operation": "activate-app",
                "nextArguments": []
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "activate-app",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "activate-app")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-active-app",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
    }

    func testWorkflowResumeSuggestsActiveInspectionAfterLaunchApp() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-app-launch-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "launch-app-transcript",
            "transcriptPath": workflowLog.path,
            "generatedAt": "2026-05-03T00:00:00Z",
            "platform": "macOS",
            "operation": "launch-app",
            "mode": "execute",
            "dryRun": false,
            "ready": true,
            "wouldExecute": true,
            "executed": true,
            "risk": "medium",
            "mutates": true,
            "blockers": [],
            "command": [
                "argv": [
                    "Ln1", "apps", "launch",
                    "--bundle-id", "com.example.App",
                    "--activate", "true",
                    "--allow-risk", "medium",
                    "--reason", "Open app"
                ]
            ],
            "execution": [
                "argv": [
                    "Ln1", "apps", "launch",
                    "--bundle-id", "com.example.App",
                    "--activate", "true",
                    "--allow-risk", "medium",
                    "--reason", "Open app"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "action": "apps.launch",
                    "target": [
                        "name": "Example",
                        "bundleIdentifier": "com.example.App",
                        "path": "/Applications/Example.app"
                    ],
                    "app": [
                        "name": "Example",
                        "bundleIdentifier": "com.example.App",
                        "pid": 123
                    ],
                    "activate": true,
                    "verification": [
                        "ok": true,
                        "code": "launched_active_app"
                    ]
                ]
            ],
            "preflight": [
                "operation": "launch-app",
                "nextArguments": []
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "launch-app",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "launch-app")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-active-app",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("app launch completed") == true)
    }

    func testWorkflowResumeSuggestsRunningAppsInspectionAfterHideApp() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-app-hide-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "hide-app-transcript",
            "transcriptPath": workflowLog.path,
            "generatedAt": "2026-05-03T00:00:00Z",
            "platform": "macOS",
            "operation": "hide-app",
            "mode": "execute",
            "dryRun": false,
            "ready": true,
            "wouldExecute": true,
            "executed": true,
            "risk": "medium",
            "mutates": true,
            "blockers": [],
            "command": [
                "argv": [
                    "Ln1", "apps", "hide",
                    "--pid", "123",
                    "--allow-risk", "medium",
                    "--reason", "Hide app"
                ]
            ],
            "execution": [
                "argv": [
                    "Ln1", "apps", "hide",
                    "--pid", "123",
                    "--allow-risk", "medium",
                    "--reason", "Hide app"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "action": "apps.hide",
                    "target": [
                        "name": "Example",
                        "bundleIdentifier": "com.example.App",
                        "pid": 123,
                        "hidden": false
                    ],
                    "hiddenAfter": true,
                    "verification": [
                        "ok": true,
                        "code": "app_hidden"
                    ]
                ]
            ],
            "preflight": [
                "operation": "hide-app",
                "nextArguments": []
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "hide-app",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "hide-app")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-apps",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("app hide completed") == true)
    }

    func testWorkflowResumeSuggestsRunningAppsInspectionAfterUnhideApp() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-app-unhide-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "unhide-app-transcript",
            "transcriptPath": workflowLog.path,
            "generatedAt": "2026-05-03T00:00:00Z",
            "platform": "macOS",
            "operation": "unhide-app",
            "mode": "execute",
            "dryRun": false,
            "ready": true,
            "wouldExecute": true,
            "executed": true,
            "risk": "medium",
            "mutates": true,
            "blockers": [],
            "command": [
                "argv": [
                    "Ln1", "apps", "unhide",
                    "--pid", "123",
                    "--allow-risk", "medium",
                    "--reason", "Show app"
                ]
            ],
            "execution": [
                "argv": [
                    "Ln1", "apps", "unhide",
                    "--pid", "123",
                    "--allow-risk", "medium",
                    "--reason", "Show app"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "action": "apps.unhide",
                    "target": [
                        "name": "Example",
                        "bundleIdentifier": "com.example.App",
                        "pid": 123,
                        "hidden": true
                    ],
                    "hiddenAfter": false,
                    "verification": [
                        "ok": true,
                        "code": "app_unhidden"
                    ]
                ]
            ],
            "preflight": [
                "operation": "unhide-app",
                "nextArguments": []
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "unhide-app",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "unhide-app")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-apps",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("app unhide completed") == true)
    }

    func testWorkflowResumeSuggestsDesktopWindowInspectionAfterMinimizeActiveWindow() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-desktop-minimize-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "minimize-active-window-transcript",
            "transcriptPath": workflowLog.path,
            "generatedAt": "2026-05-03T00:00:00Z",
            "platform": "macOS",
            "operation": "minimize-active-window",
            "mode": "execute",
            "dryRun": false,
            "ready": true,
            "wouldExecute": true,
            "executed": true,
            "risk": "medium",
            "mutates": true,
            "blockers": [],
            "command": [
                "argv": [
                    "Ln1", "desktop", "minimize-active-window",
                    "--allow-risk", "medium",
                    "--reason", "Clear window"
                ]
            ],
            "execution": [
                "argv": [
                    "Ln1", "desktop", "minimize-active-window",
                    "--allow-risk", "medium",
                    "--reason", "Clear window"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "action": "desktop.minimizeActiveWindow",
                    "minimizedAfter": true,
                    "verification": [
                        "ok": true,
                        "code": "window_minimized"
                    ]
                ]
            ],
            "preflight": [
                "operation": "minimize-active-window",
                "nextArguments": []
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "minimize-active-window",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "minimize-active-window")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-windows",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("window minimize completed") == true)
    }

    func testWorkflowResumeSuggestsDesktopWindowInspectionAfterRestoreWindow() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-desktop-restore-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "restore-window-transcript",
            "transcriptPath": workflowLog.path,
            "generatedAt": "2026-05-03T00:00:00Z",
            "platform": "macOS",
            "operation": "restore-window",
            "mode": "execute",
            "dryRun": false,
            "ready": true,
            "wouldExecute": true,
            "executed": true,
            "risk": "medium",
            "mutates": true,
            "blockers": [],
            "command": [
                "argv": [
                    "Ln1", "desktop", "restore-window",
                    "--pid", "123",
                    "--element", "w0",
                    "--allow-risk", "medium",
                    "--reason", "Restore window"
                ]
            ],
            "execution": [
                "argv": [
                    "Ln1", "desktop", "restore-window",
                    "--pid", "123",
                    "--element", "w0",
                    "--allow-risk", "medium",
                    "--reason", "Restore window"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "action": "desktop.restoreWindow",
                    "minimizedAfter": false,
                    "verification": [
                        "ok": true,
                        "code": "window_restored"
                    ]
                ]
            ],
            "preflight": [
                "operation": "restore-window",
                "nextArguments": []
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "restore-window",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "restore-window")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-windows",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("window restore completed") == true)
    }

    func testWorkflowResumeSuggestsRunningAppsInspectionAfterQuitApp() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-app-quit-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "quit-app-transcript",
            "transcriptPath": workflowLog.path,
            "generatedAt": "2026-05-03T00:00:00Z",
            "platform": "macOS",
            "operation": "quit-app",
            "mode": "execute",
            "dryRun": false,
            "ready": true,
            "wouldExecute": true,
            "executed": true,
            "risk": "high",
            "mutates": true,
            "blockers": [],
            "command": [
                "argv": [
                    "Ln1", "apps", "quit",
                    "--pid", "123",
                    "--allow-risk", "high",
                    "--reason", "Close app"
                ]
            ],
            "execution": [
                "argv": [
                    "Ln1", "apps", "quit",
                    "--pid", "123",
                    "--allow-risk", "high",
                    "--reason", "Close app"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "action": "apps.quit",
                    "target": [
                        "name": "Example",
                        "bundleIdentifier": "com.example.App",
                        "pid": 123
                    ],
                    "verification": [
                        "ok": true,
                        "code": "app_exited"
                    ]
                ]
            ],
            "preflight": [
                "operation": "quit-app",
                "nextArguments": []
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "quit-app",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "quit-app")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-apps",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("app quit completed") == true)
    }

    func testWorkflowResumeSuggestsActiveWindowInspectionAfterOpenURL() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-open-url-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "open-url-transcript",
            "transcriptPath": workflowLog.path,
            "generatedAt": "2026-05-03T00:00:00Z",
            "platform": "macOS",
            "operation": "open-url",
            "mode": "execute",
            "dryRun": false,
            "ready": true,
            "wouldExecute": true,
            "executed": true,
            "risk": "medium",
            "mutates": true,
            "blockers": [],
            "command": [
                "argv": [
                    "Ln1", "open",
                    "--url", "https://example.com/report",
                    "--allow-risk", "medium",
                    "--reason", "Open report"
                ]
            ],
            "execution": [
                "argv": [
                    "Ln1", "open",
                    "--url", "https://example.com/report",
                    "--allow-risk", "medium",
                    "--reason", "Open report"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "action": "workspace.open",
                    "target": [
                        "kind": "url",
                        "url": "https://example.com/report",
                        "scheme": "https",
                        "host": "example.com"
                    ],
                    "verification": [
                        "ok": true,
                        "code": "open_request_accepted"
                    ]
                ]
            ],
            "preflight": [
                "operation": "open-url",
                "nextArguments": []
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "open-url",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "open-url")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-active-window",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("workspace open completed") == true)
    }

    func testWorkflowResumeSuggestsLaunchDryRunAfterInstalledAppInspect() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-installed-apps-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "installed-apps-transcript",
            "transcriptPath": workflowLog.path,
            "generatedAt": "2026-05-03T00:00:00Z",
            "platform": "macOS",
            "operation": "inspect-installed-apps",
            "mode": "execute",
            "dryRun": false,
            "ready": true,
            "wouldExecute": true,
            "executed": true,
            "risk": "low",
            "mutates": false,
            "blockers": [],
            "command": [
                "argv": [
                    "Ln1", "apps", "installed",
                    "--name", "Example",
                    "--limit", "5"
                ]
            ],
            "execution": [
                "argv": [
                    "Ln1", "apps", "installed",
                    "--name", "Example",
                    "--limit", "5"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "apps": [
                        [
                            "name": "Example",
                            "bundleIdentifier": "com.example.App",
                            "path": "/Applications/Example.app"
                        ]
                    ]
                ]
            ],
            "preflight": [
                "operation": "inspect-installed-apps",
                "nextArguments": []
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-installed-apps",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-installed-apps")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "launch-app",
            "--bundle-id", "com.example.App",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
    }

    func testWorkflowResumeSuggestsActiveInspectionAfterRunningAppsInspect() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-apps-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "running-apps-transcript",
            "operation": "inspect-apps",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "apps", "list",
                    "--limit", "10"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "platform": "macOS",
                    "limit": 10,
                    "count": 1,
                    "activeApp": [
                        "name": "Example",
                        "bundleIdentifier": "com.example.App",
                        "pid": 123,
                        "active": true
                    ],
                    "apps": [
                        [
                            "name": "Example",
                            "bundleIdentifier": "com.example.App",
                            "pid": 123,
                            "active": true
                        ]
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-apps",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-apps")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-active-app",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
    }

    func testWorkflowResumeSuggestsProcessInspectionAfterFrontmostAppInspect() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-frontmost-app-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "frontmost-app-transcript",
            "operation": "inspect-frontmost-app",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "apps", "active"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "platform": "macOS",
                    "found": true,
                    "app": [
                        "name": "Example",
                        "bundleIdentifier": "com.example.App",
                        "pid": 123
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-frontmost-app",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-frontmost-app")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-process",
            "--pid", "123",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
    }

    func testProcessesListReturnsBoundedStructuredProcessMetadata() throws {
        let result = try runLn1([
            "processes",
            "--limit", "25"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let processes = try XCTUnwrap(object["processes"] as? [[String: Any]])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["limit"] as? Int, 25)
        XCTAssertEqual(object["count"] as? Int, processes.count)
        XCTAssertLessThanOrEqual(processes.count, 25)
        XCTAssertNotNil(object["truncated"] as? Bool)
        XCTAssertTrue(processes.contains { $0["currentProcess"] as? Bool == true })

        let first = try XCTUnwrap(processes.first)
        XCTAssertNotNil(first["pid"] as? Int)
        XCTAssertNotNil(first["currentProcess"] as? Bool)
        XCTAssertNotNil(first["activeApp"] as? Bool)
    }

    func testProcessesInspectCurrentReturnsCurrentProcessMetadata() throws {
        let result = try runLn1([
            "processes",
            "inspect",
            "--current"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let process = try XCTUnwrap(object["process"] as? [String: Any])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["found"] as? Bool, true)
        XCTAssertEqual(process["currentProcess"] as? Bool, true)
        XCTAssertNotNil(process["pid"] as? Int)
        XCTAssertNotNil(process["activeApp"] as? Bool)
        XCTAssertTrue(process["name"] is String || process["executablePath"] is String)
    }

    func testProcessesWaitReturnsMatchedExistingProcessMetadata() throws {
        let result = try runLn1([
            "processes",
            "wait",
            "--pid", "\(ProcessInfo.processInfo.processIdentifier)",
            "--exists", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "process_matched")
        XCTAssertEqual(verification["expectedExists"] as? Bool, true)
        XCTAssertEqual(verification["matched"] as? Bool, true)
        XCTAssertNotNil(verification["current"] as? [String: Any])
    }

    func testProcessesWaitTimesOutForExistingProcessToDisappear() throws {
        let result = try runLn1([
            "processes",
            "wait",
            "--pid", "\(ProcessInfo.processInfo.processIdentifier)",
            "--exists", "false",
            "--timeout-ms", "100",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(verification["ok"] as? Bool, false)
        XCTAssertEqual(verification["code"] as? String, "process_timeout")
        XCTAssertEqual(verification["expectedExists"] as? Bool, false)
        XCTAssertEqual(verification["matched"] as? Bool, false)
    }

    func testWorkflowPreflightInspectProcessBuildsProcessInspectCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-process",
            "--current"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "inspect-process")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "processes", "inspect", "--current"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.processTarget" && $0["status"] as? String == "pass" })
    }

    func testWorkflowRunExecutesNonMutatingProcessInspectAndCapturesJSON() throws {
        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-process-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "inspect-process",
            "--current",
            "--workflow-log", workflowLog.path,
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let process = try XCTUnwrap(outputJSON["process"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "inspect-process")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "processes", "inspect", "--current"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["found"] as? Bool, true)
        XCTAssertEqual(process["currentProcess"] as? Bool, true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowPreflightWaitProcessBuildsProcessWaitCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-process",
            "--pid", "\(ProcessInfo.processInfo.processIdentifier)",
            "--exists", "true",
            "--wait-timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "wait-process")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "processes", "wait",
            "--pid", "\(ProcessInfo.processInfo.processIdentifier)",
            "--exists", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.processTarget" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightWaitWindowBuildsDesktopWaitCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-window",
            "--title", "Export Complete",
            "--match", "contains",
            "--exists", "true",
            "--wait-timeout-ms", "500",
            "--interval-ms", "50",
            "--limit", "20"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "wait-window")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "desktop", "wait-window",
            "--title", "Export Complete",
            "--match", "contains",
            "--exists", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50",
            "--limit", "20"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowTarget" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightWaitElementRequiresElementPath() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-element",
            "--wait-timeout-ms", "500"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "wait-element")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, false)
        XCTAssertTrue(blockers.contains("workflow.element"))
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.element" && $0["status"] as? String == "fail" })
    }

    func testWorkflowPreflightInspectElementRequiresElementPath() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-element",
            "--depth", "0"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "inspect-element")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, false)
        XCTAssertTrue(blockers.contains("workflow.element"))
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.element" && $0["status"] as? String == "fail" })
    }

    func testWorkflowPreflightInspectElementAcceptsMenuElementPath() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-element",
            "--element", "a0.m0.1",
            "--depth", "0",
            "--max-children", "0"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "inspect-element")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertFalse(blockers.contains("workflow.element"))
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.element" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightFindElementBuildsStateFindCommand() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let apps = try runLn1(["apps", "--all"])
        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        guard let active = records.first(where: { $0["active"] as? Bool == true }),
              let pid = active["pid"] as? Int else {
            throw XCTSkip("No active app record was available from macOS.")
        }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "find-element",
            "--pid", "\(pid)",
            "--role", "AXButton",
            "--title", "Save",
            "--action", "AXPress",
            "--enabled", "true",
            "--match", "contains",
            "--include-menu",
            "--depth", "3",
            "--max-children", "40",
            "--result-depth", "1",
            "--result-max-children", "3",
            "--limit", "7"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "find-element")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "state", "find",
            "--pid", "\(pid)",
            "--role", "AXButton",
            "--title", "Save",
            "--action", "AXPress",
            "--enabled", "true",
            "--match", "contains",
            "--depth", "3",
            "--max-children", "40",
            "--result-depth", "1",
            "--result-max-children", "3",
            "--limit", "7",
            "--include-menu"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.appTarget" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.elementQuery" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightWaitElementBuildsStateWaitCommand() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let apps = try runLn1(["apps", "--all"])
        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        guard let active = records.first(where: { $0["active"] as? Bool == true }),
              let pid = active["pid"] as? Int else {
            throw XCTSkip("No active app record was available from macOS.")
        }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-element",
            "--pid", "\(pid)",
            "--element", "w0",
            "--expect-identity", "accessibilityElement:abc123",
            "--min-identity-confidence", "medium",
            "--title", "Export Complete",
            "--match", "contains",
            "--enabled", "true",
            "--exists", "true",
            "--wait-timeout-ms", "500",
            "--interval-ms", "50",
            "--depth", "1",
            "--max-children", "4"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "wait-element")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "state", "wait-element",
            "--pid", "\(pid)",
            "--element", "w0",
            "--expect-identity", "accessibilityElement:abc123",
            "--min-identity-confidence", "medium",
            "--title", "Export Complete",
            "--match", "contains",
            "--exists", "true",
            "--enabled", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50",
            "--depth", "1",
            "--max-children", "4"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.element" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.appTarget" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightInspectElementBuildsStateElementCommand() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let apps = try runLn1(["apps", "--all"])
        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        guard let active = records.first(where: { $0["active"] as? Bool == true }),
              let pid = active["pid"] as? Int else {
            throw XCTSkip("No active app record was available from macOS.")
        }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-element",
            "--pid", "\(pid)",
            "--element", "w0",
            "--expect-identity", "accessibilityElement:abc123",
            "--min-identity-confidence", "medium",
            "--depth", "1",
            "--max-children", "4"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "inspect-element")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "state", "element",
            "--pid", "\(pid)",
            "--element", "w0",
            "--expect-identity", "accessibilityElement:abc123",
            "--min-identity-confidence", "medium",
            "--depth", "1",
            "--max-children", "4"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.element" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.appTarget" && $0["status"] as? String == "pass" })
    }

    func testWorkflowRunExecutesNonMutatingProcessWaitAndCapturesJSON() throws {
        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-process-wait-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "wait-process",
            "--pid", "\(ProcessInfo.processInfo.processIdentifier)",
            "--exists", "true",
            "--wait-timeout-ms", "500",
            "--interval-ms", "50",
            "--workflow-log", workflowLog.path,
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let verification = try XCTUnwrap(outputJSON["verification"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "wait-process")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "processes", "wait",
            "--pid", "\(ProcessInfo.processInfo.processIdentifier)",
            "--exists", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["matched"] as? Bool, true)
        XCTAssertNotNil(verification["current"] as? [String: Any])
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesNonMutatingWindowWaitAndCapturesJSON() throws {
        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-window-wait-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "wait-window",
            "--title", "Ln1 nonexistent window \(UUID().uuidString)",
            "--match", "exact",
            "--exists", "false",
            "--wait-timeout-ms", "500",
            "--interval-ms", "50",
            "--limit", "20",
            "--workflow-log", workflowLog.path,
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let verification = try XCTUnwrap(outputJSON["verification"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "wait-window")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual((command["argv"] as? [String])?.prefix(3), [
            "Ln1", "desktop", "wait-window"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["platform"] as? String, "macOS")
        XCTAssertNotNil(verification["ok"] as? Bool)
        XCTAssertNotNil(verification["matched"] as? Bool)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesNonMutatingElementWaitAndCapturesJSON() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        guard let firstWindow = windows.first,
              let elementID = firstWindow["id"] as? String else {
            throw XCTSkip("No Accessibility window was available for the frontmost app.")
        }

        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-element-wait-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "wait-element",
            "--pid", "\(pid)",
            "--element", elementID,
            "--exists", "true",
            "--wait-timeout-ms", "500",
            "--interval-ms", "50",
            "--depth", "0",
            "--max-children", "0",
            "--workflow-log", workflowLog.path,
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let verification = try XCTUnwrap(outputJSON["verification"] as? [String: Any])
        let current = try XCTUnwrap(verification["current"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "wait-element")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "state", "wait-element",
            "--pid", "\(pid)",
            "--element", elementID,
            "--match", "contains",
            "--exists", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["matched"] as? Bool, true)
        XCTAssertEqual(current["id"] as? String, elementID)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesNonMutatingElementInspectAndCapturesJSON() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        guard let firstWindow = windows.first,
              let elementID = firstWindow["id"] as? String else {
            throw XCTSkip("No Accessibility window was available for the frontmost app.")
        }

        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-element-inspect-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "inspect-element",
            "--pid", "\(pid)",
            "--element", elementID,
            "--min-identity-confidence", "low",
            "--depth", "0",
            "--max-children", "0",
            "--workflow-log", workflowLog.path,
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let element = try XCTUnwrap(outputJSON["element"] as? [String: Any])
        let identityVerification = try XCTUnwrap(outputJSON["identityVerification"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "inspect-element")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "state", "element",
            "--pid", "\(pid)",
            "--element", elementID,
            "--min-identity-confidence", "low",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(element["id"] as? String, elementID)
        XCTAssertEqual(identityVerification["ok"] as? Bool, true)
        XCTAssertEqual(identityVerification["minimumConfidence"] as? String, "low")
        XCTAssertEqual(identityVerification["confidenceAccepted"] as? Bool, true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesNonMutatingElementFindAndCapturesJSON() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)

        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-element-find-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "find-element",
            "--pid", "\(pid)",
            "--role", "AXWindow",
            "--match", "exact",
            "--depth", "0",
            "--max-children", "10",
            "--limit", "5",
            "--workflow-log", workflowLog.path,
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let matches = try XCTUnwrap(outputJSON["matches"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "find-element")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "state", "find",
            "--pid", "\(pid)",
            "--role", "AXWindow",
            "--match", "exact",
            "--depth", "0",
            "--max-children", "10",
            "--result-depth", "0",
            "--result-max-children", "20",
            "--limit", "5"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["platform"] as? String, "macOS")
        XCTAssertEqual(outputJSON["count"] as? Int, matches.count)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesNonMutatingMenuInspectAndCapturesJSON() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let apps = try runLn1(["apps", "--all"])
        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        guard let active = records.first(where: { $0["active"] as? Bool == true }),
              let pid = active["pid"] as? Int else {
            throw XCTSkip("No active app record was available from macOS.")
        }

        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-menu-inspect-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "inspect-menu",
            "--pid", "\(pid)",
            "--depth", "1",
            "--max-children", "5",
            "--workflow-log", workflowLog.path,
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let app = try XCTUnwrap(outputJSON["app"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "inspect-menu")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "state", "menu",
            "--pid", "\(pid)",
            "--depth", "1",
            "--max-children", "5"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["platform"] as? String, "macOS")
        XCTAssertEqual(app["pid"] as? Int, pid)
        XCTAssertEqual(outputJSON["depth"] as? Int, 1)
        XCTAssertEqual(outputJSON["maxChildren"] as? Int, 5)
        XCTAssertNotNil(outputJSON["message"] as? String)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowPreflightWaitActiveAppBuildsAppWaitCommand() throws {
        let apps = try runLn1(["apps", "--all"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        guard let active = records.first(where: { $0["active"] as? Bool == true }),
              let pid = active["pid"] as? Int else {
            throw XCTSkip("No active app record was available from macOS.")
        }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-active-app",
            "--pid", "\(pid)",
            "--wait-timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "wait-active-app")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "apps", "wait-active",
            "--pid", "\(pid)",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.appTarget" && $0["status"] as? String == "pass" })
    }

    func testWorkflowRunExecutesNonMutatingActiveAppWaitAndCapturesJSON() throws {
        let apps = try runLn1(["apps", "--all"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        guard let active = records.first(where: { $0["active"] as? Bool == true }),
              let pid = active["pid"] as? Int else {
            throw XCTSkip("No active app record was available from macOS.")
        }

        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-active-app-wait-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "wait-active-app",
            "--pid", "\(pid)",
            "--wait-timeout-ms", "500",
            "--interval-ms", "50",
            "--workflow-log", workflowLog.path,
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let verification = try XCTUnwrap(outputJSON["verification"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "wait-active-app")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "apps", "wait-active",
            "--pid", "\(pid)",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["matched"] as? Bool, true)
        XCTAssertNotNil(verification["current"] as? [String: Any])
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowPreflightControlActiveAppUsesExplicitPID() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let apps = try runLn1(["apps", "--all"])
        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        guard let target = records.first(where: { $0["active"] as? Bool != true && $0["pid"] is Int })
            ?? records.first(where: { $0["pid"] is Int }),
              let pid = target["pid"] as? Int else {
            throw XCTSkip("No running app record was available from macOS.")
        }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "control-active-app",
            "--pid", "\(pid)",
            "--element", "w0",
            "--expect-identity", "accessibilityElement:abc123",
            "--min-identity-confidence", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "control-active-app")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "perform",
            "--pid", "\(pid)",
            "--element", "w0",
            "--expect-identity", "accessibilityElement:abc123",
            "--min-identity-confidence", "medium",
            "--action", kAXPressAction as String,
            "--allow-risk", "low",
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.appTarget" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightSetElementValueBuildsGuardedCommand() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let apps = try runLn1(["apps", "--all"])
        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        guard let target = records.first(where: { $0["active"] as? Bool != true && $0["pid"] is Int })
            ?? records.first(where: { $0["pid"] is Int }),
              let pid = target["pid"] as? Int else {
            throw XCTSkip("No running app record was available from macOS.")
        }

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-set-value-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let missingValue = try runLn1([
            "workflow",
            "preflight",
            "--operation", "set-element-value",
            "--pid", "\(pid)",
            "--element", "w0",
            "--expect-identity", "accessibilityElement:abc123",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(missingValue.status, 0, missingValue.stderr)
        let missingObject = try decodeJSONObject(missingValue.stdout)
        XCTAssertEqual(missingObject["canProceed"] as? Bool, false)
        XCTAssertTrue((missingObject["blockers"] as? [String])?.contains("workflow.value") == true)

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "set-element-value",
            "--pid", "\(pid)",
            "--element", "w0",
            "--expect-identity", "accessibilityElement:abc123",
            "--min-identity-confidence", "medium",
            "--value", "prepared value",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "set-element-value")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "set-value",
            "--pid", "\(pid)",
            "--element", "w0",
            "--expect-identity", "accessibilityElement:abc123",
            "--min-identity-confidence", "medium",
            "--value", "prepared value",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.appTarget" && $0["status"] as? String == "pass" })
    }

    func testWorkflowResumeSuggestsActivationAfterProcessInspectForGUIApp() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-process-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "inspect-process-transcript",
            "transcriptPath": workflowLog.path,
            "generatedAt": "2026-05-03T00:00:00Z",
            "platform": "macOS",
            "operation": "inspect-process",
            "mode": "execute",
            "dryRun": false,
            "ready": true,
            "wouldExecute": true,
            "executed": true,
            "risk": "low",
            "mutates": false,
            "blockers": [],
            "command": [
                "argv": [
                    "Ln1", "processes", "inspect",
                    "--pid", "123"
                ]
            ],
            "execution": [
                "argv": [
                    "Ln1", "processes", "inspect",
                    "--pid", "123"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "found": true,
                    "process": [
                        "pid": 123,
                        "name": "Example",
                        "bundleIdentifier": "com.example.App",
                        "appName": "Example",
                        "activeApp": false,
                        "currentProcess": false
                    ]
                ]
            ],
            "preflight": [
                "operation": "inspect-process",
                "nextArguments": []
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-process",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-process")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "activate-app",
            "--bundle-id", "com.example.App",
            "--allow-risk", "medium",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
    }

    func testWorkflowResumeSuggestsInspectAfterProcessWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-process-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "wait-process-transcript",
            "operation": "wait-process",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "processes", "wait",
                    "--pid", "123",
                    "--exists", "true"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "verification": [
                        "ok": true,
                        "code": "process_matched",
                        "pid": 123,
                        "expectedExists": true,
                        "matched": true,
                        "current": [
                            "pid": 123,
                            "name": "Example",
                            "activeApp": false,
                            "currentProcess": false
                        ]
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-process",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-process")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-process",
            "--pid", "123",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
    }

    func testWorkflowResumeSuggestsWindowInventoryAfterAbsentWindowWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-window-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "wait-window-transcript",
            "operation": "wait-window",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "desktop", "wait-window",
                    "--title", "Export Complete",
                    "--exists", "false"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "verification": [
                        "ok": true,
                        "code": "desktop_window_matched",
                        "expectedExists": false,
                        "matched": true,
                        "currentCount": 0,
                        "current": []
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-window",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-window")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "desktop", "windows",
            "--limit", "50"
        ])
    }

    func testWorkflowResumeSuggestsGuardedPressAfterElementWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-element-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "wait-element-transcript",
            "operation": "wait-element",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "state", "wait-element",
                    "--pid", "123",
                    "--element", "w0.1",
                    "--exists", "true"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "app": [
                        "pid": 123,
                        "name": "Example",
                        "bundleIdentifier": "com.example.App"
                    ],
                    "verification": [
                        "ok": true,
                        "code": "accessibility_element_matched",
                        "expectedExists": true,
                        "matched": true,
                        "current": [
                            "id": "w0.1",
                            "stableIdentity": [
                                "id": "accessibilityElement:abc123",
                                "kind": "accessibilityElement",
                                "confidence": "high",
                                "label": "AXButton: Save",
                                "components": [:],
                                "reasons": []
                            ],
                            "enabled": true,
                            "actions": [kAXPressAction as String]
                        ]
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-element",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-element")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "perform",
            "--pid", "123",
            "--element", "w0.1",
            "--expect-identity", "accessibilityElement:abc123",
            "--min-identity-confidence", "medium",
            "--action", kAXPressAction as String,
            "--allow-risk", "low",
            "--reason", "Describe intent"
        ])
    }

    func testWorkflowResumeSuggestsElementInspectionAfterElementFind() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-element-find-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "find-element-transcript",
            "operation": "find-element",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "state", "find",
                    "--pid", "123",
                    "--title", "Save"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "app": [
                        "pid": 123,
                        "name": "Example",
                        "bundleIdentifier": "com.example.App"
                    ],
                    "matches": [
                        [
                            "id": "w0.1",
                            "stableIdentity": [
                                "id": "accessibilityElement:abc123",
                                "kind": "accessibilityElement",
                                "confidence": "high",
                                "label": "AXButton: Save",
                                "components": [:],
                                "reasons": []
                            ],
                            "enabled": true,
                            "actions": [kAXPressAction as String]
                        ]
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "find-element",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "find-element")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-element",
            "--pid", "123",
            "--element", "w0.1",
            "--expect-identity", "accessibilityElement:abc123",
            "--min-identity-confidence", "medium",
            "--depth", "1",
            "--max-children", "20",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
    }

    func testWorkflowResumeSuggestsGuardedPressAfterElementInspect() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-element-inspect-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "inspect-element-transcript",
            "operation": "inspect-element",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "state", "element",
                    "--pid", "123",
                    "--element", "w0.1"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "app": [
                        "pid": 123,
                        "name": "Example",
                        "bundleIdentifier": "com.example.App"
                    ],
                    "element": [
                        "id": "w0.1",
                        "stableIdentity": [
                            "id": "accessibilityElement:abc123",
                            "kind": "accessibilityElement",
                            "confidence": "high",
                            "label": "AXButton: Save",
                            "components": [:],
                            "reasons": []
                        ],
                        "enabled": true,
                        "actions": [kAXPressAction as String]
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-element",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-element")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "perform",
            "--pid", "123",
            "--element", "w0.1",
            "--expect-identity", "accessibilityElement:abc123",
            "--min-identity-confidence", "medium",
            "--action", kAXPressAction as String,
            "--allow-risk", "low",
            "--reason", "Describe intent"
        ])
    }

    func testWorkflowResumeSuggestsSetElementValueAfterElementInspect() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-element-value-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "inspect-element-value-transcript",
            "operation": "inspect-element",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "state", "element",
                    "--pid", "123",
                    "--element", "w0.1"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "app": [
                        "pid": 123,
                        "name": "Example",
                        "bundleIdentifier": "com.example.App"
                    ],
                    "element": [
                        "id": "w0.1",
                        "stableIdentity": [
                            "id": "accessibilityElement:abc123",
                            "kind": "accessibilityElement",
                            "confidence": "high",
                            "label": "AXTextField",
                            "components": [:],
                            "reasons": []
                        ],
                        "enabled": true,
                        "actions": [],
                        "settableAttributes": [kAXValueAttribute as String],
                        "valueSettable": true
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-element",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-element")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "set-element-value",
            "--pid", "123",
            "--element", "w0.1",
            "--expect-identity", "accessibilityElement:abc123",
            "--min-identity-confidence", "medium",
            "--value", "Replace value",
            "--dry-run", "true"
        ])
    }

    func testWorkflowResumeSuggestsInspectionAfterSetElementValue() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-set-value-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "set-value-transcript",
            "operation": "set-element-value",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "set-value",
                    "--pid", "123",
                    "--element", "w0.1",
                    "--value", "prepared value",
                    "--allow-risk", "medium"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "pid": 123,
                    "element": "w0.1",
                    "stableIdentity": [
                        "id": "accessibilityElement:abc123",
                        "kind": "accessibilityElement",
                        "confidence": "high"
                    ],
                    "verification": [
                        "ok": true,
                        "code": "value_verified"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "set-element-value",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "set-element-value")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-element",
            "--pid", "123",
            "--element", "w0.1",
            "--expect-identity", "accessibilityElement:abc123",
            "--min-identity-confidence", "medium",
            "--depth", "1",
            "--max-children", "20",
            "--dry-run", "true"
        ])
    }

    func testWorkflowResumeSuggestsStateInspectionAfterMenuInspect() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-menu-inspect-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "inspect-menu-transcript",
            "operation": "inspect-menu",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "state", "menu",
                    "--pid", "123",
                    "--depth", "1",
                    "--max-children", "5"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "platform": "macOS",
                    "app": [
                        "pid": 123,
                        "name": "Example",
                        "bundleIdentifier": "com.example.App"
                    ],
                    "menuBar": [
                        "id": "m0",
                        "children": [
                            [
                                "id": "m0.0",
                                "role": "AXMenuBarItem",
                                "title": "File"
                            ]
                        ]
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-menu",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-menu")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "state",
            "--depth", "3",
            "--max-children", "80",
            "--pid", "123"
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("menu inspection") == true)
    }

    func testWorkflowResumeSuggestsGuardedMenuActionAfterMenuInspect() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-menu-action-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "inspect-menu-action-transcript",
            "operation": "inspect-menu",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "state", "menu",
                    "--pid", "123",
                    "--depth", "1",
                    "--max-children", "5"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "platform": "macOS",
                    "app": [
                        "pid": 123,
                        "name": "Example",
                        "bundleIdentifier": "com.example.App"
                    ],
                    "menuBar": [
                        "id": "m0",
                        "children": [
                            [
                                "id": "m0.0",
                                "stableIdentity": [
                                    "id": "accessibilityElement:menu123",
                                    "kind": "accessibilityElement",
                                    "confidence": "high",
                                    "label": "AXMenuBarItem: File",
                                    "components": [:],
                                    "reasons": []
                                ],
                                "role": "AXMenuBarItem",
                                "title": "File",
                                "enabled": true,
                                "actions": [kAXShowMenuAction as String]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-menu",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-menu")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "perform",
            "--pid", "123",
            "--element", "m0.0",
            "--expect-identity", "accessibilityElement:menu123",
            "--min-identity-confidence", "medium",
            "--action", kAXShowMenuAction as String,
            "--allow-risk", "low",
            "--reason", "Describe intent"
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("guarded menu action") == true)
    }

    func testWorkflowResumeSuggestsActiveInspectionAfterActiveAppWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-active-app-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "wait-active-app-transcript",
            "operation": "wait-active-app",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "apps", "wait-active",
                    "--pid", "123"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "verification": [
                        "ok": true,
                        "code": "active_app_matched",
                        "matched": true,
                        "target": [
                            "pid": 123,
                            "name": "Example",
                            "bundleIdentifier": "com.example.App"
                        ],
                        "current": [
                            "pid": 123,
                            "name": "Example",
                            "bundleIdentifier": "com.example.App"
                        ]
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-active-app",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-active-app")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-active-app",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
    }

    func testSchemaDocumentsStableAccessibilityElementIdentities() throws {
        let result = try runLn1(["schema"])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let state = try XCTUnwrap(object["state"] as? [String: Any])
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        let firstWindow = try XCTUnwrap(windows.first)
        let stableIdentity = try XCTUnwrap(firstWindow["stableIdentity"] as? [String: Any])
        let components = try XCTUnwrap(stableIdentity["components"] as? [String: String])
        let reasons = try XCTUnwrap(stableIdentity["reasons"] as? [String])

        XCTAssertEqual(stableIdentity["kind"] as? String, "accessibilityElement")
        XCTAssertEqual(stableIdentity["confidence"] as? String, "high")
        XCTAssertNotNil(stableIdentity["id"] as? String)
        XCTAssertNotNil(stableIdentity["label"] as? String)
        XCTAssertEqual(components["role"], "AXButton")
        XCTAssertEqual(components["title"], "save")
        XCTAssertNotNil(firstWindow["settableAttributes"] as? [String])
        XCTAssertEqual(firstWindow["valueSettable"] as? Bool, false)
        XCTAssertTrue(reasons.contains("role"))
        XCTAssertTrue(reasons.contains("title"))
    }

    func testSchemaDocumentsIdentityGuardedPerformResults() throws {
        let result = try runLn1(["schema"])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let perform = try XCTUnwrap(object["perform"] as? [String: Any])
        let resultObject = try XCTUnwrap(perform["result"] as? [String: Any])
        let stableIdentity = try XCTUnwrap(resultObject["stableIdentity"] as? [String: Any])
        let identityVerification = try XCTUnwrap(resultObject["identityVerification"] as? [String: Any])

        XCTAssertTrue((perform["command"] as? String)?.contains("--expect-identity") == true)
        XCTAssertTrue((perform["command"] as? String)?.contains("--min-identity-confidence medium") == true)
        XCTAssertEqual(stableIdentity["kind"] as? String, "accessibilityElement")
        XCTAssertEqual(identityVerification["ok"] as? Bool, true)
        XCTAssertEqual(identityVerification["code"] as? String, "identity_verified")
        XCTAssertEqual(identityVerification["expectedID"] as? String, identityVerification["actualID"] as? String)
        XCTAssertEqual(identityVerification["minimumConfidence"] as? String, "medium")
        XCTAssertEqual(identityVerification["actualConfidence"] as? String, "high")
    }

    func testSchemaDocumentsGuardedAccessibilityValueSetting() throws {
        let result = try runLn1(["schema"])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let setValue = try XCTUnwrap(object["setValue"] as? [String: Any])
        let resultObject = try XCTUnwrap(setValue["result"] as? [String: Any])
        let stableIdentity = try XCTUnwrap(resultObject["stableIdentity"] as? [String: Any])
        let verification = try XCTUnwrap(resultObject["verification"] as? [String: Any])
        let identityVerification = try XCTUnwrap(resultObject["identityVerification"] as? [String: Any])

        XCTAssertTrue((setValue["command"] as? String)?.contains("--expect-identity") == true)
        XCTAssertTrue((setValue["command"] as? String)?.contains("--allow-risk medium") == true)
        XCTAssertEqual(resultObject["action"] as? String, "accessibility.setValue")
        XCTAssertEqual(resultObject["risk"] as? String, "medium")
        XCTAssertEqual(resultObject["valueLength"] as? Int, 8)
        XCTAssertNotNil(resultObject["valueDigest"] as? String)
        XCTAssertNil(resultObject["value"] as? String)
        XCTAssertEqual(stableIdentity["kind"] as? String, "accessibilityElement")
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "value_verified")
        XCTAssertEqual(identityVerification["code"] as? String, "identity_verified")
    }

    func testSchemaDocumentsInstalledAppInventory() throws {
        let result = try runLn1(["schema"])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let appsInstalled = try XCTUnwrap(object["appsInstalled"] as? [String: Any])
        let resultObject = try XCTUnwrap(appsInstalled["result"] as? [String: Any])
        let roots = try XCTUnwrap(resultObject["searchRoots"] as? [String])
        let apps = try XCTUnwrap(resultObject["apps"] as? [[String: Any]])
        let first = try XCTUnwrap(apps.first)

        XCTAssertTrue((appsInstalled["command"] as? String)?.contains("apps installed") == true)
        XCTAssertEqual(resultObject["platform"] as? String, "macOS")
        XCTAssertEqual(resultObject["limit"] as? Int, 20)
        XCTAssertEqual(resultObject["truncated"] as? Bool, false)
        XCTAssertTrue(roots.contains("/Applications"))
        XCTAssertEqual(first["bundleIdentifier"] as? String, "com.apple.TextEdit")
        XCTAssertNotNil(first["path"] as? String)
        XCTAssertNotNil(first["executablePath"] as? String)
    }

    func testSchemaDocumentsAppLaunchPlanResults() throws {
        let result = try runLn1(["schema"])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let appsLaunchPlan = try XCTUnwrap(object["appsLaunchPlan"] as? [String: Any])
        let resultObject = try XCTUnwrap(appsLaunchPlan["result"] as? [String: Any])
        let policy = try XCTUnwrap(resultObject["policy"] as? [String: Any])
        let target = try XCTUnwrap(resultObject["target"] as? [String: Any])
        let checks = try XCTUnwrap(resultObject["checks"] as? [[String: Any]])

        XCTAssertTrue((appsLaunchPlan["command"] as? String)?.contains("--operation launch") == true)
        XCTAssertTrue((appsLaunchPlan["command"] as? String)?.contains("--allow-risk medium") == true)
        XCTAssertEqual(resultObject["operation"] as? String, "launch")
        XCTAssertEqual(resultObject["action"] as? String, "apps.launch")
        XCTAssertEqual(resultObject["risk"] as? String, "medium")
        XCTAssertEqual(resultObject["actionMutates"] as? Bool, true)
        XCTAssertEqual(resultObject["activate"] as? Bool, false)
        XCTAssertEqual(resultObject["canExecute"] as? Bool, true)
        XCTAssertEqual(resultObject["requiredAllowRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(target["bundleIdentifier"] as? String, "com.apple.TextEdit")
        XCTAssertNotNil(target["path"] as? String)
        XCTAssertTrue(checks.contains {
            $0["name"] as? String == "apps.launchTarget"
                && $0["code"] as? String == "launch_target_found"
        })
    }

    func testSchemaDocumentsAppLaunchResults() throws {
        let result = try runLn1(["schema"])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let appsLaunch = try XCTUnwrap(object["appsLaunch"] as? [String: Any])
        let resultObject = try XCTUnwrap(appsLaunch["result"] as? [String: Any])
        let target = try XCTUnwrap(resultObject["target"] as? [String: Any])
        let verification = try XCTUnwrap(resultObject["verification"] as? [String: Any])

        XCTAssertTrue((appsLaunch["command"] as? String)?.contains("--allow-risk medium") == true)
        XCTAssertTrue((appsLaunch["command"] as? String)?.contains("--activate true") == true)
        XCTAssertEqual(resultObject["action"] as? String, "apps.launch")
        XCTAssertEqual(resultObject["risk"] as? String, "medium")
        XCTAssertEqual(resultObject["activate"] as? Bool, true)
        XCTAssertEqual(target["bundleIdentifier"] as? String, "com.apple.TextEdit")
        XCTAssertNotNil(target["path"] as? String)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "launched_active_app")
    }

    func testTaskMemoryRecordsTaskScopedEventsWithSensitiveSummaryRedaction() throws {
        let memoryLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-task-memory-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: memoryLog) }

        let start = try runLn1([
            "task",
            "start",
            "--title", "Verify download",
            "--summary", "Wait for report.pdf and compare checksum",
            "--allow-risk", "medium",
            "--memory-log", memoryLog.path
        ])

        XCTAssertEqual(start.status, 0, start.stderr)
        let startObject = try decodeJSONObject(start.stdout)
        let taskID = try XCTUnwrap(startObject["taskID"] as? String)
        let startEvents = try XCTUnwrap(startObject["events"] as? [[String: Any]])
        let started = try XCTUnwrap(startEvents.first)

        XCTAssertEqual(startObject["path"] as? String, memoryLog.path)
        XCTAssertEqual(startObject["status"] as? String, "active")
        XCTAssertEqual(startObject["title"] as? String, "Verify download")
        XCTAssertEqual(startObject["eventCount"] as? Int, 1)
        XCTAssertEqual(started["kind"] as? String, "task.started")
        XCTAssertEqual(started["summary"] as? String, "Wait for report.pdf and compare checksum")
        XCTAssertEqual(started["sensitivity"] as? String, "private")

        let record = try runLn1([
            "task",
            "record",
            "--task-id", taskID,
            "--kind", "verification",
            "--summary", "secret confirmation code 123456",
            "--sensitivity", "sensitive",
            "--related-audit-id", "audit-1",
            "--allow-risk", "medium",
            "--memory-log", memoryLog.path
        ])

        XCTAssertEqual(record.status, 0, record.stderr)
        let recordObject = try decodeJSONObject(record.stdout)
        let recordEvents = try XCTUnwrap(recordObject["events"] as? [[String: Any]])
        let verification = try XCTUnwrap(recordEvents.last)

        XCTAssertEqual(recordObject["eventCount"] as? Int, 2)
        XCTAssertEqual(verification["kind"] as? String, "task.verification")
        XCTAssertEqual(verification["sensitivity"] as? String, "sensitive")
        XCTAssertEqual(verification["summaryLength"] as? Int, 31)
        XCTAssertEqual(verification["summaryDigest"] as? String, "bfdc69fc2ce532ddd962d2d01bc9a5015890b303334f7c131ff6d5efc1172cae")
        XCTAssertEqual(verification["relatedAuditID"] as? String, "audit-1")
        XCTAssertNil(verification["summary"])

        let finish = try runLn1([
            "task",
            "finish",
            "--task-id", taskID,
            "--status", "completed",
            "--summary", "Download was verified.",
            "--allow-risk", "medium",
            "--memory-log", memoryLog.path
        ])

        XCTAssertEqual(finish.status, 0, finish.stderr)

        let show = try runLn1([
            "task",
            "show",
            "--task-id", taskID,
            "--limit", "2",
            "--allow-risk", "medium",
            "--memory-log", memoryLog.path
        ])

        XCTAssertEqual(show.status, 0, show.stderr)
        let showObject = try decodeJSONObject(show.stdout)
        let shownEvents = try XCTUnwrap(showObject["events"] as? [[String: Any]])

        XCTAssertEqual(showObject["status"] as? String, "completed")
        XCTAssertEqual(showObject["eventCount"] as? Int, 3)
        XCTAssertEqual(showObject["limit"] as? Int, 2)
        XCTAssertEqual(shownEvents.count, 2)
        XCTAssertEqual(shownEvents.first?["kind"] as? String, "task.verification")
        XCTAssertEqual(shownEvents.last?["kind"] as? String, "task.finished")
    }

    func testTaskMemoryRequiresMediumRiskBeforePersisting() throws {
        let memoryLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-task-memory-policy-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: memoryLog) }

        let rejected = try runLn1([
            "task",
            "start",
            "--title", "Blocked task",
            "--summary", "should not be persisted",
            "--memory-log", memoryLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: memoryLog.path))
    }

    func testWorkflowPreflightStartTaskBuildsTaskStartCommand() throws {
        let memoryLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-task-preflight-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: memoryLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "start-task",
            "--title", "Verify report",
            "--summary", "Track report download and checksum",
            "--task-id", "task-1",
            "--sensitivity", "private",
            "--allow-risk", "medium",
            "--memory-log", memoryLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "start-task")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "task", "start",
            "--title", "Verify report",
            "--allow-risk", "medium",
            "--task-id", "task-1",
            "--summary", "Track report download and checksum",
            "--sensitivity", "private",
            "--memory-log", memoryLog.path
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.policy" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightRecordAndShowTaskUseTaskMemory() throws {
        let memoryLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-task-record-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: memoryLog) }

        let start = try runLn1([
            "task",
            "start",
            "--title", "Verify report",
            "--task-id", "task-record",
            "--allow-risk", "medium",
            "--memory-log", memoryLog.path
        ])
        XCTAssertEqual(start.status, 0, start.stderr)

        let record = try runLn1([
            "workflow",
            "preflight",
            "--operation", "record-task",
            "--task-id", "task-record",
            "--kind", "verification",
            "--summary", "checksum matched",
            "--sensitivity", "public",
            "--related-audit-id", "audit-1",
            "--allow-risk", "medium",
            "--memory-log", memoryLog.path
        ])

        XCTAssertEqual(record.status, 0, record.stderr)
        let recordObject = try decodeJSONObject(record.stdout)
        let recordPrerequisites = try XCTUnwrap(recordObject["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(recordObject["operation"] as? String, "record-task")
        XCTAssertEqual(recordObject["risk"] as? String, "medium")
        XCTAssertEqual(recordObject["mutates"] as? Bool, true)
        XCTAssertEqual(recordObject["canProceed"] as? Bool, true)
        XCTAssertEqual(recordObject["nextArguments"] as? [String], [
            "Ln1", "task", "record",
            "--task-id", "task-record",
            "--kind", "verification",
            "--summary", "checksum matched",
            "--allow-risk", "medium",
            "--sensitivity", "public",
            "--related-audit-id", "audit-1",
            "--memory-log", memoryLog.path
        ])
        XCTAssertTrue(recordPrerequisites.contains { $0["name"] as? String == "workflow.taskMemory" && $0["status"] as? String == "pass" })

        let show = try runLn1([
            "workflow",
            "preflight",
            "--operation", "show-task",
            "--task-id", "task-record",
            "--limit", "10",
            "--allow-risk", "medium",
            "--memory-log", memoryLog.path
        ])

        XCTAssertEqual(show.status, 0, show.stderr)
        let showObject = try decodeJSONObject(show.stdout)

        XCTAssertEqual(showObject["operation"] as? String, "show-task")
        XCTAssertEqual(showObject["risk"] as? String, "medium")
        XCTAssertEqual(showObject["mutates"] as? Bool, false)
        XCTAssertEqual(showObject["canProceed"] as? Bool, true)
        XCTAssertEqual(showObject["nextArguments"] as? [String], [
            "Ln1", "task", "show",
            "--task-id", "task-record",
            "--allow-risk", "medium",
            "--limit", "10",
            "--memory-log", memoryLog.path
        ])
    }

    func testWorkflowRunExecutesMutatingTaskStartAndCapturesJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-task-run-\(UUID().uuidString)")
        let memoryLog = directory.appendingPathComponent("task-memory.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "start-task",
            "--title", "Verify report",
            "--task-id", "task-run",
            "--summary", "Track report download",
            "--allow-risk", "medium",
            "--memory-log", memoryLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "false",
            "--execute-mutating", "true",
            "--reason", "Track task context"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let events = try XCTUnwrap(outputJSON["events"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "start-task")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "task", "start",
            "--title", "Verify report",
            "--allow-risk", "medium",
            "--task-id", "task-run",
            "--summary", "Track report download",
            "--memory-log", memoryLog.path,
            "--reason", "Track task context"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["taskID"] as? String, "task-run")
        XCTAssertEqual(outputJSON["status"] as? String, "active")
        XCTAssertEqual(outputJSON["path"] as? String, memoryLog.path)
        XCTAssertEqual(events.first?["kind"] as? String, "task.started")
        XCTAssertTrue(FileManager.default.fileExists(atPath: memoryLog.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowResumeSuggestsTaskRecordAfterTaskStart() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-task-resume-\(UUID().uuidString)")
        let memoryLog = directory.appendingPathComponent("task-memory.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "task-start-transcript",
            "operation": "start-task",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "task", "start",
                    "--title", "Verify report",
                    "--task-id", "task-resume",
                    "--allow-risk", "medium",
                    "--memory-log", memoryLog.path
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "path": memoryLog.path,
                    "taskID": "task-resume",
                    "status": "active",
                    "eventCount": 1,
                    "events": [
                        [
                            "kind": "task.started",
                            "taskID": "task-resume"
                        ]
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let result = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "start-task",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "start-task")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "record-task",
            "--task-id", "task-resume",
            "--kind", "observation",
            "--summary", "Describe next observation",
            "--allow-risk", "medium",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path,
            "--memory-log", memoryLog.path
        ])
    }

}
