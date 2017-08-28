raijin
========

thorに憧れて書かれた、小規模なCLIツールキットです。DSLでコマンドを定義
します。


インストール
--------------

まだgemはないし、インストーラとかもないのでロードパスを通すなりファイ
ルをコピーなりする必要があります。


ライセンス
------------

MITライセンスです。詳しくはLICENSEを参照。


使い方
-------

Raijinクラスを継承して、各コマンドの実装をメソッドで行い、クラスメソッ
ドでメタ情報を定義するという、ほとんどthorのやり方といっしょです。

    class App < Raijin
      desc "アプリケーション自体とか全体の説明"
      option "-V", "--verbose", "Turn on verbose mode" do
        @opt[:verbose] = true
      end
      def initialize
        @opt = {}
      end
      
      desc "install one of the available apps"
      option "--force" do
        @opt[:force] = true
      end
      option "--alias=NAME" do |s|
        @opt[:alias] = s
      end
      def install(name)
        user_alias = @opt[:alias]
        if @opt[:force]
          # do something
        end
        # other code
      end
      
      desc "list all of the avaliable apps, limited by SEARCH"
      def list(search = "")
        # list everything
      end

      private
      
      def command_nothing
        # コマンドが何も指定されてない場合のフック
      end
      
      def command_missing(name)
        # 指定されたコマンドが見つからない場合のフック
      end
      
      def handle_error(program, exception)
        # Raijin::Error やオプション処理で例外が挙がった場合のハンドラ。
        # command_nothingやcommand_missingのデフォルト実装はRaijin::Errorを
        # 挙げてここに来ます。
        stderr.puts "#{program}: Error - #{e.message}"
        true
        # 真を返すとヘルプを表示します。偽だと何もしません。
      end
    end

コマンドはpublicメソッドです。descでコマンドの説明をし、optionでそのコ
マンドのオプションを定義します。optionの使い方については
OptionParser#onについて勉強して下さい。内部的にオプションの処理をして
いるのはOptionParserなのでそのまんまです。
ただし、ブロックはRaijinを継承したクラスのオブジェクトのコンテキストで
評価されます。

    App.run(ARGV, program: 'app', stdout: $stdout, stderr: $stderr)

runでコマンドを実行します。thorみたいにnewしてコマンドのメソッドを呼ん
でも同じようには動きません。注意してください。


