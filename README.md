# mdConvertToTex

これはmarkdown(md)記法のファイルを読み込んで、tex形式に変換したファイルを出力します

# 使い方

このファイルをrubyで実行します
	
	$ ruby <this_file> <markdown_file> [-p]

<this_file> はこのrubyのソースファイルのパスです
<markdown_file> はmdファイルのパスです
このコマンドは md -> tex を行います。
-p オプションで追加の変換 tex -> pdf も行います

例:

	$ ruby mdConvertToTex.rb report.md -p


