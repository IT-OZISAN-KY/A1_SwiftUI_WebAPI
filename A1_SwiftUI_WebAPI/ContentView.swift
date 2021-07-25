//
//  ContentView.swift
//  A1_SwiftUI_WebAPI
//
//  Created by keiji yamaki on 2021/07/25.
//

import SwiftUI
import Alamofire
import SWXMLHash
import SwiftyJSON

struct ContentView: View {
    @State var hiragana = ""            // ひらがな
    @State var words: [String] = []     // 変換した言葉
    @State var kanji: String?           // 漢字
    @State var imageOn = false          // 画像画面
    @ObservedObject var urlImage: URLImage = URLImage()
    
    var body: some View {
        // かな漢字変換画面から画像画面に移動
        if imageOn {
            imageListView
        }else{
            toKanjiView
        }
    }
    // かな漢字変換の画面
    var toKanjiView: some View {
        VStack {
            HStack {
                // ひらがなの入力
                TextField("ひらがなを入力", text: $hiragana)
                    .font(.title)
                    .frame(width: 250, height: 100)
                    .textFieldStyle(RoundedBorderTextFieldStyle())  // 入力域のまわりを枠で囲む
                    .padding()
                // 変換ボタン
                Button(action: {
                    getKanjis(hiragana: hiragana)
                }){
                    Text("変換")
                        .font(.title)
                }.frame(width:70, height: 50)
            }
            // 漢字の一覧
            List {
                ForEach(words, id: \.self) { word in
                    // 漢字の一覧から漢字をタップすると、kanjiに設定、画像画面に
                    Button(action: {
                        kanji = word
                        words = []
                        getImages(keyword: kanji!)
                    }){
                        Text("\(word)")
                            .font(.title)
                    }.frame(height: 50)
                }
            }.frame(height:300)
        }
    }
    // 画像一覧画面
    var imageListView: some View {
        VStack {
            // 閉じるボタン
            Button(action: {
                imageOn = false
            }){
                Text("閉じる")
                    .font(.title)
            }.frame(height: 50)
            // 画像のリスト
            List {
                ForEach(0 ..< urlImage.imageDatas.count) { index in
                    if let image = urlImage.imageDatas[index].image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                }
            }
        }

    }
    // ひらがなをもとに漢字を取得
    private func getKanjis(hiragana: String){
        // 1. ひらがなをエンコード
        let urlKeyword = hiragana.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        // 2. URLを定義←エンコードしたひらがなをキーワードに設定
        let url = "https://jlp.yahooapis.jp/JIMService/V1/conversion?appid=(アプリケーションID)&sentence=\(urlKeyword ?? "")"
        // 3. Alamofireで、APIをリクエスト
        AF.request(url).response { response in
            // 3.1 SWXMLHashで、XMLを解析
            let xml = SWXMLHash.parse(response.data!)
            words = []
            // 3.2 漢字一覧を取得して、wordsに追加
            for element in xml["ResultSet"]["Result"]["SegmentList"]["Segment"][0]["CandidateList"]["Candidate"].all {
                words.append(element.element!.text)
            }
        }
    }
    // 検索ワードをもとに画像を取得
    private func getImages(keyword: String){
        // 1. 検索ワードをエンコード
        let urlKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        // 2. URLを定義←エンコードした検索ワードをキーワードに設定
        let url = "https://pixabay.com/api/?key=(App Key))&q=\(urlKeyword ?? "")&lang=ja&safesearch=true"

        var imageDatas: [ImageData] = []    // 画像のデータ
        // 3. Alamofireで、APIをリクエスト
        AF.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default).responseJSON {(response) in
            switch(response.result) {
            // 3.1. リクエスト成功の場合
            case.success:
                // 3.1.1. "hits", "previewURL"の値をimageDataに追加
                let json:JSON = JSON(response.data as Any)
                urlImage.imageDatas = []
                for (_, subJson) in json["hits"] {
                    if let url = subJson["previewURL"].string {
                        imageDatas.append(ImageData(URL: url))
                    }
                }
                // 3.1.2. 画像データがある場合は、画像画面に切り替え
                if imageDatas.count > 0 {
                    urlImage.setImages(imageDatas: imageDatas)
                    imageOn = true
                }
            // 3.2. 失敗の場合は、メッセージ表示
            case.failure(let error):
                print(error)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
