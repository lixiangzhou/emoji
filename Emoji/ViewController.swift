//
//  ViewController.swift
//  Emoji
//
//  Created by 李向洲 on 2020/6/17.
//  Copyright © 2020 李向洲. All rights reserved.
//

import UIKit

let jsonFilePath = "/Users/lixiangzhou/Desktop/lxz/emoji.json"
let emojiDataFilePath = "/Users/lixiangzhou/Desktop/lxz/emojiCodes.data"

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let c1 = Character("\u{1F64E}\u{1F3FF}\u{200D}\u{200D}")
        let c2 = Character("\u{1F64E}\u{1F3FF}\u{200D}\u{200D}\u{FE0F}")
        
        // 查看Unicode值
        for c in c1.unicodeScalars {
            print(c.utf16)
        }
        

        useDemo()
    }
    
    func useDemo() {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: emojiDataFilePath)), let groups = try? JSONDecoder().decode([EmojiGroup].self, from: data) {
//            var emojis = [Character]()
            var emojiString = ""
            for g in groups {
                for s in g.subgroups {
                    for e in s.emojis {
//                        emojis.append(Character(e.codePoints))
                        emojiString.append(Character(e.codePoints))
                    }
                }
            }
            CharacterSet(charactersIn: emojiString)
        }
    }
}

extension ViewController {
    /// 第一步：从官网下载下来的 emoji-test.txt 文件中解析出需要的数据
    func getEmojiTestData() -> [EmojiGroup]? {
        // 数据来源于 https://unicode.org/Public/emoji/13.0/emoji-test.txt
        // 参考网站：https://www.unicode.org/emoji/charts-13.0/emoji-ordering.html
        
        if let path = Bundle.main.path(forResource: "emoji-test", ofType: "txt"),
            let data = FileManager.default.contents(atPath: path),
            let contents = String(data: data, encoding: .utf8) {
            // -----------------------------------------------------
            // -----------------获取数据
            // -----------------------------------------------------
            
            let groupPrifix = "# group:"
            let subGroupPrifix = "# subgroup:"
            let rows = contents.components(separatedBy: "\n")
            
            var groups = [EmojiGroup]()
            
            for row in rows {
                if row.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    (row.starts(with: "#") &&
                        !(row.starts(with: groupPrifix) || row.starts(with: subGroupPrifix))) {
                    continue
                } else {
                    if row.starts(with: groupPrifix) {
                        let name = String(row[groupPrifix.endIndex...])
                        groups.append(EmojiGroup(name: name.trimedString, subgroups: [EmojiSubGroup]()))
                        continue
                    }
                    
                    if row.starts(with: subGroupPrifix) {
                        let name = String(row[subGroupPrifix.endIndex...])
                        let subGroup = EmojiSubGroup(name: name, emojis: [Emoji]())
                        groups.last?.subgroups.append(subGroup)
                        continue
                    }
                    
                    let components = row.components(separatedBy: ";")
                    if components.isEmpty {
                        continue
                    }
                        
                    let codePoints = components.first!
                    
                    let rightComponents = components[1].components(separatedBy: "#")
                    let status = rightComponents.first!
                    
                    let description = rightComponents[1]
                    let emoji = Emoji(codePoints: codePoints.trimedString, status: status.trimedString, description: description.trimedString)
                    groups.last?.subgroups.last?.emojis.append(emoji)
                }
            }
            
            return groups
        }
        return nil
    }
    
    /// 第二步：将  emoji 数据变成Swift可以解析的格式并打印出来, 并赋值给某个变量保存起来 emojiCodes
    func getEmojiCodes(_ groups: [EmojiGroup]) {
        print("[", separator: "", terminator: "")
        for g in groups {
            for g in g.subgroups {
                for e in g.emojis {
                    let components = e.codePoints.components(separatedBy: " ")
                    let code = components.map { "\\u{\($0)}" }.joined()
                    print("\"", code, "\",", separator: "", terminator: "")
                }
            }
        }
        print("]", separator: "", terminator: "")
    }
    
    /// 第三步：将 emojiCodes 转变成Data数据，方便使用
    func generateEmojiData() {
        if let data = try? JSONEncoder().encode(emojiCodes) {
            FileManager.default.createFile(atPath: emojiDataFilePath, contents: data, attributes: nil)
        }
    }
    
    /// 将解析出来的数据生成 json 文件，保存在某个路径下 jsonFilePath，方便以后使用
    func generateJson(_ groups: [EmojiGroup]) {
        // -----------------------------------------------------
        // -----------------生成JSON文件
        // -----------------------------------------------------
        
        if let data = try? JSONEncoder().encode(groups) {
            FileManager.default.createFile(atPath: jsonFilePath, contents: data, attributes: nil)
        }
    }
    
    /// 打印 emoji 信息
    func printInfo(_ groups: [EmojiGroup]) {
        // -----------------------------------------------------
        // -----------------遍历查看、统计
        // -----------------------------------------------------
        
        var fullCount = 0
        var minCount = 0
        var unCount = 0
        var comCount = 0
        
        for g in groups {
            print(g.name)
            for s in g.subgroups {
                print("\t", s.name)
                for e in s.emojis {
                    print("\t\t", e.codePoints, e.status, e.description)
                    if e.status == "fully-qualified" {
                        fullCount += 1
                    } else if e.status == "minimally-qualified" {
                        minCount += 1
                    } else if e.status == "unqualified" {
                        unCount += 1
                    } else if e.status == "component" {
                        comCount += 1
                    }
                }
            }
        }
        print(fullCount, minCount, unCount, comCount)
    }
}

class EmojiGroup: Codable {
    var name: String
    var subgroups: [EmojiSubGroup]
    
    init(name: String, subgroups: [EmojiSubGroup]) {
        self.name = name
        self.subgroups = subgroups
    }
}

class EmojiSubGroup: Codable {
    var name: String
    var emojis: [Emoji]
    
    init(name: String, emojis: [Emoji]) {
        self.name = name
        self.emojis = emojis
    }
}

struct Emoji: Codable {
    var codePoints: String
    var status: String
    var description: String
}

extension String {
    var trimedString: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
