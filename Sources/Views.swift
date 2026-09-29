import SwiftUI
import AppKit

struct UsageView: View {
    @ObservedObject var model: AppModel
    var settings: () -> Void
    private var resetTime: String {
        guard let date = model.window?.resetDate else { return L("暂无数据", "Not available") }
        let formatter = DateFormatter(); formatter.locale = .autoupdatingCurrent; formatter.timeZone = .autoupdatingCurrent
        formatter.dateStyle = .medium; formatter.timeStyle = .short
        return formatter.string(from:date)
    }
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L("额度概览", "Usage overview")).font(.system(size:14,weight:.semibold))
                Spacer()
                Text(model.refreshing ? L("更新中…", "Updating…") : model.stale ? L("数据待更新", "Out of date") : model.updated == nil ? L("等待连接", "Connecting") : L("已同步", "Up to date"))
                    .font(.system(size:11)).foregroundStyle(.secondary)
            }
            if model.entries.count > 1 {
                Picker(L("顶栏显示", "Menu bar display"), selection:$model.selection) {
                    ForEach(Array(model.entries.enumerated()),id:\.offset) { index, entry in Text(entry.0).tag(index) }
                }.labelsHidden().pickerStyle(.menu)
            } else {
                Text(model.entries.first?.0 ?? L("ChatGPT / Codex 额度", "ChatGPT / Codex usage")).font(.system(size:12)).foregroundStyle(.secondary)
            }
            DuoIcon(model:model)
            HStack(spacing:0) {
                metric(model.window.map { String(format:"%.0f%%",$0.remaining) } ?? "—", L("剩余额度", "Remaining quota"))
                Divider().frame(height:36)
                metric(model.credits.map(String.init) ?? "—", L("可用重置次数", "Available resets"))
            }
            VStack(spacing:5) {
                Text(L("下次重置", "NEXT RESET")).font(.system(size:9,weight:.semibold)).tracking(1.4).foregroundStyle(.secondary)
                Text(resetTime).font(.system(size:14,weight:.medium,design:.rounded))
                Text(TimeZone.current.abbreviation() ?? TimeZone.current.identifier).font(.system(size:10)).foregroundStyle(.secondary)
            }
            if let error = model.error {
                Text(error).font(.system(size:11)).foregroundStyle(.secondary).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
                if model.usage == nil {
                    Button(L("打开 ChatGPT / Codex 登录", "Open ChatGPT / Codex")) {
                        for name in ["ChatGPT","Codex"] {
                            let url = URL(fileURLWithPath:"/Applications/\(name).app")
                            if FileManager.default.fileExists(atPath:url.path) { NSWorkspace.shared.open(url);break }
                        }
                    }.buttonStyle(.link)
                }
            }
            if model.usage != nil && model.credits == nil {
                Text(L("当前账号未提供重置次数", "Reset credits are unavailable for this account")).font(.system(size:11)).foregroundStyle(.secondary)
            }
            Divider()
            HStack {
                Button { model.refresh() } label: { Image(systemName:"arrow.clockwise") }.disabled(model.refreshing).help(L("刷新额度", "Refresh usage"))
                if let date = model.updated { Text(date,style:.time).font(.system(size:10)).foregroundStyle(.secondary) }
                Spacer()
                Button { settings() } label: { Image(systemName:"gearshape") }.help(L("开机启动设置", "Settings"))
                Button { NSApp.terminate(nil) } label: { Image(systemName:"power") }.help(L("退出", "Quit"))
            }.buttonStyle(.borderless)
        }.padding(22).frame(width:340).fixedSize(horizontal:false,vertical:true)
    }
    private func metric(_ value: String, _ title: String) -> some View {
        VStack(spacing:5) {
            Text(value).font(.system(size:26,weight:.semibold,design:.rounded)).monospacedDigit()
            Text(title).font(.system(size:11)).foregroundStyle(.secondary)
        }.frame(maxWidth:.infinity)
    }
}

struct SettingsView: View {
    @StateObject private var login = LoginModel()
    @ObservedObject private var updates = UpdateManager.shared
    var body: some View {
        VStack(alignment:.leading,spacing:14) {
            Toggle(L("开机启动", "Launch at login"),isOn:Binding(get:{login.enabled},set:{login.set($0)})).toggleStyle(.switch)
            Text(L("登录 Mac 后，自动在顶栏显示额度。", "Show usage in the menu bar when you log in to your Mac."))
                .font(.system(size:12)).foregroundStyle(.secondary)
            if let message = login.message { Text(message).font(.system(size:11)).foregroundStyle(.secondary) }
            Divider()
            HStack {
                Text(L("版本 \(updates.currentVersion)", "Version \(updates.currentVersion)")).font(.system(size:12)).foregroundStyle(.secondary)
                Spacer()
                Button(updates.checking ? L("检查中…", "Checking…") : L("检查更新…", "Check for updates…")) { updates.check(manual:true) }
                    .disabled(updates.checking || updates.installing)
            }
            if !updates.message.isEmpty {
                Text(updates.message).font(.system(size:11)).foregroundStyle(.secondary).fixedSize(horizontal:false,vertical:true)
            }
            if updates.available != nil {
                HStack {
                    Button(updates.installing ? L("更新中…", "Updating…") : L("下载并更新", "Download and update")) { updates.installAvailable() }.disabled(updates.installing)
                    Button(L("更新说明", "Release notes")) { updates.openRelease() }.buttonStyle(.link)
                }
            }
        }.padding(28).frame(width:330)
    }
}
