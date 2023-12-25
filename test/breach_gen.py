import sys  # Pythonのsysモジュールをインポート。コマンドライン引数などのシステム関連の機能にアクセスするために使用。

import platform  # プラットフォームモジュールをインポート。実行中のオペレーティングシステムに関する情報を提供。

import glob  # ファイルパスを検索するglobモジュールをインポート。

matlab = ''  # MATLABの実行パスを格納するための変数を空文字列で初期化。

osys = platform.system()  # オペレーティングシステムの名前を取得し、変数osysに格納。

# オペレーティングシステムがLinuxの場合、/usr/local/MATLAB/*/bin/ に一致するパスを検索。
if osys == 'Linux':
    mpaths = glob.glob('/usr/local/MATLAB/*/bin/')  # MATLABのインストールパスを検索。
    mpaths.sort()  # 取得したパスをソート。
    matlab = mpaths[-1] + 'matlab'  # 最新のMATLABバージョンのパスを変数matlabに設定。

# オペレーティングシステムがMac OS (Darwin)の場合、/Applications/MATLAB*/bin/ に一致するパスを検索。
elif osys == 'Darwin':
    mpaths = glob.glob('/Applications/MATLAB*/bin/')  # MATLABのインストールパスを検索。
    mpaths.sort()  # 取得したパスをソート。
    matlab = mpaths[-1] + 'matlab'  # 最新のMATLABバージョンのパスを変数matlabに設定。


# 設定ファイルから読み取るべきパラメータや情報を格納する変数を初期化。
model = ''
parameters = []
epsilon = ''
input_name = []
input_range = []
input_type = ''
input_cp = []
time_span = ''
spec_str = []
max_time = ''
max_fun_evals = ''


# 設定ファイルの解析状態と現在の引数を追跡するための変数を初期化。
status = 0
arg = ''
linenum = 0


# 設定ファイルの解析に関連する追加変数を初期化。
algopath = ''
trials = ''
addpath = []


# コマンドライン引数で指定された設定ファイルを開き、その内容を行ごとに読み込む。
with open(sys.argv[1],'r') as conf:
    for line in conf.readlines():  # ファイルの各行に対してループ。
        argu = line.strip().split()  # 行を空白で分割し、リストに格納。
        # 引数のステータスに基づいて処理を行う。
        if status == 0:
            status = 1
            arg = argu[0]
            linenum = int(argu[1])
        elif status == 1:
            linenum = linenum - 1
            # 以下、各引数に応じた設定情報を変数に格納する処理。
            if arg == 'model':
                model = argu[0]
            elif arg == 'parameters':
				parameters.append(argu[0])
            elif arg == 'epsilon':
				epsilon = argu[0]
            elif arg == 'input_name':
				input_name.append(argu[0])
            elif arg == 'input_range':
				input_range.append([float(argu[0]),float(argu[1])])
            elif arg == 'input_type':
				input_type = argu[0]
            elif arg == 'input_cp':
				input_cp.append(int(argu[0]))
            elif arg == 'time_span':
				time_span = argu[0]
            elif arg == 'spec':
				complete_spec = argu[0]+';'+argu[1]
				for a in argu[2:]:
					complete_spec = complete_spec + ' '+ a
				spec_str.append(complete_spec)
            elif arg == 'max_time':
				max_time = argu[0]
            elif arg == 'max_fun_evals':
				max_fun_evals = argu[0]
            else:
				continue
			if linenum == 0:
				status = 0

# 設定ファイルから抽出した情報を基に、シミュレーションテストのためのシェルスクリプトを生成するループ。
for sp in spec_str:
    for cp in input_cp:
        property = sp.split(';')  # STL式を分割してproperty変数に格納。
        filename = model+ '_breach_' + property[0]  # ファイル名を生成。
        param = '\n'.join(parameters)  # パラメータを連結してparam変数に格納。

        # 生成するシェルスクリプトのためのファイルを開く。
        with open('test/benchmarks/'+filename,'w') as bm:
            bm.write('#!/bin/sh\n')  # シェルスクリプトのシバン（shebang）行を書き込む。
            bm.write('csv=$1\n')  # コマンドライン引数からCSVファイル名を取得。
            bm.write(matlab + ' -nodesktop -nosplash <<EOF\n')  # MATLABを非対話モードで起動するコマンドを書き込む。
            bm.write('clear;\n')  # MATLABのワークスペースをクリアする。
            
            # addpath変数に格納されたパスをMATLABに追加する。
            for ap in addpath:
                bm.write('addpath(genpath(\'' + ap + '\'));\n)
            
            bm.write('InitBreach;\n\n')  # Breachを初期化する。
            bm.write(param + '\n')  # パラメータをMATLABスクリプトに書き込む。
            bm.write('mdl = \''+ model + '\';\n')  # モデル名を設定する。
            bm.write('epsilon = '+ epsilon + ';\n')
            bm.write('input_name = {\'' + input_name[0])
            if 2<=len(input_name):
                for i in range(len(input_name)-1):
                    bm.write('\', ' + input_name[i+1])
            bm.write('\'};\n')
            bm.write('input_range = [' + input_range[0][0] + ', ' + input_range[0][1])
            if 2<=len(input_name):
                for i in range(len(input_name)-1):
                    bm.write('; ' + input_range[i+1][0] + ', ' + input_range[i+1][1])
            bm.write('];\n')
            bm.write('input_type = \'' + input_type + '\';\n')  # 入力信号のタイプを設定する。
            bm.write('input_cp = '+ str(cp) + ';\n')  # 入力信号の制御点の数を設定する。
            bm.write('time_span = '+ time_span +';\n')  # シミュレーションの時間範囲を設定する。
            bm.write('spec1 = \''+ property[1]+'\';\n')  # spec1を設定する。
            bm.write('spec2 = \'not '+ property[1]+'\';\n')  # spec2を設定する
            bm.write('max_time = '+ max_time + ';\n')
            bm.write('max_fun_evals = '+ max_fun_evals + ';\n')

            # 試行回数、アルゴリズム名、その他の変数を設定する。
            bm.write('trials = ' + trials + ';\n')  
            bm.write('filename = \''+filename+'\';\n')
            bm.write('D = [];\n')
            bm.write('input_D = [];\n')
            bm.write('best D = 0;\n')
            bm.write('input_best_D = [];\n')


            # 実際のシミュレーションテストを行うループ。
            bm.write('for n = 1:trials\n')
            bm.write('\td = afc_algo1(mdl, epsilon, input_name, input_range, input_type, input_cp, spec1, spec2, time_span, max_time, max_fun_evals);\n')
            bm.write('\tD = [D;d];\n')
            bm.write('\tif best_D < d\n')
            bm.write('\t\tbest_D = d;\n')
            bm.write('\tend\n')
            bm.write('end\n')


            # テスト結果をCSVファイルに書き出す。
            bm.write('spec = {spec')
            n_trials = int(trials)
            for j in range(1,n_trials):
                bm.write(';spec')
            bm.write('};\n')

            bm.write('filename = {filename')
            for j in range(1,n_trials):
                bm.write(';filename')
            bm.write('};\n')

            bm.write('result = table(filename, spec, D, best_D);\n')
            
            bm.write('writetable(result,\'$csv\',\'Delimiter\',\';\');\n')
            bm.write('quit force\n')  # MATLABを強制終了する。
            bm.write('EOF\n')  # ヒアドキュメントの終了。


