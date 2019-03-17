## 各ファイルの説明

- power_packet.rb
    - power_packet.png を生成するプログラム
- packet_animation.rb
    - power_packet_animation_n.png を生成するプログラム
- packet.rb
    - 上記の2ファイルから共通で使われる部品を切り出したプログラム
- Gemfile, Gemfile.lock
    - 使用する外部のライブラリの情報を記したファイル
    - 参考：https://bundler.io/v1.5/gemfile.html

## 画像の生成方法

```console
$ cd ./power_packet_image
$ bundle install --path vendor/bundle
$ bundle exec ruby power_packet.rb # power_packet.pngが生成される
$ bundle exec ruby packet_animation.rb # power_packet_animation_1.png ... power_packet_animation_3.pngが生成される
```

