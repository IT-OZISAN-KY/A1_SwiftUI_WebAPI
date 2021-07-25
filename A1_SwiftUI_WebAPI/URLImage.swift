//
//  URLImage.swift
//  A1_SwiftUI_WebAPI
//
//  Created by keiji yamaki on 2021/07/18.
//
// URLから画像を取得
// imageDatasに画像のURL情報を配列設定し、setImagesをコールすると、画像が取得されるので、
// urlImage.imageData[index].imageで画像を表示。

import SwiftUI

struct ImageData {
    var URL: String
    var image: UIImage?
}
// URLから画像を取得
class URLImage: ObservableObject {
    // 公開データ
    @Published var imageDatas: [ImageData] = []
    // データを設定
    func setImages(imageDatas: [ImageData]){
        // データを設定
        self.imageDatas = imageDatas
        // 画像データを取得
        for imageData in imageDatas {
            // プレビュー画像の取得
            guard let webformatURL = URL(string: imageData.URL) else { return }
            URLSession.shared.dataTask(with: webformatURL) { [self] data, _, _ in
                guard let data = data,
                    let webformatImage = UIImage(data: data, scale: 5) else {
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() ) { [self] in
                    if let index = imageDatas.firstIndex(where: {$0.URL == imageData.URL}){
                        self.imageDatas[index].image = webformatImage
                    }
                }
            }.resume()
        }
    }
    
}
