%FalsificationProblem.mのfunction b = stopping(this)を変更した。

% ワークスペースの変数をクリアする
clear;
% 開いている全てのfigure windowsを閉じる
close all;
% command windowをクリアする
clc;
% CPSTutorialのあるリポジトリにパスを置き換える
addpath(genpath('C:\Users\onepi\Documents\test1\CPSTutorial-main'));
% Breachを起動する
InitBreach;


%εの設定(3パーセントで設定している)
epsilon = 0.03;
dimension1_LBounds = 900;
dimension1_UBounds = 1100;
dimension2_LBounds = 10.0;
dimension2_UBounds = 60.0;

% 初期化パラメータ
x0 = [950, -3, 35.0, 1.0]; % 初期点（AFCでは4次元ベクトル）

% cmaesのようなfalsificationを行う回数を設定する 
trials = 3;
best_input = [0, 0, 0, 0];
best_difference = 0;

for n = 1:trials
    % CMA-ESのオプションを設定
    opts = cmaes;
    % 各次元ごとの下限と上限を設定
    opts.LBounds = [dimension1_LBounds; -(dimension1_UBounds - dimension1_LBounds)*epsilon; dimension2_LBounds; -(dimension2_UBounds - dimension2_LBounds)*epsilon];
    opts.UBounds = [dimension1_UBounds; (dimension2_UBounds - dimension2_LBounds)*epsilon; dimension2_UBounds; (dimension2_UBounds - dimension2_LBounds)*epsilon]; 
    opts.MaxIter = 1;  % 繰り返しの最大回数を10回に設定
    opts.MaxFunEvals = 10;  % 関数評価の最大回数を30回に設定
    
    % 適切なsigma値を選ぶ（必要に応じて調整）
    sigma = 0.3;
    
    % CMA-ESアルゴリズムの実行
    [xmin, fmin, counteval, stopflag, out, bestever] = cmaes('objective_function_algo3', x0, [], opts);
    

    if (0 <= xmin(2) && xmin(1) <= 1100 - xmin(2)) || (xmin(2) < 0 && 900 - xmin(2) <= xmin(1))

        if (0 <= xmin(4) && xmin(3) <= 60 - xmin(4)) || (xmin(4) < 0 && 10 - xmin(4) <= xmin(3))
            % 結果の表示
            disp([mat2str(n), '回目のベストなインプット: ', mat2str(xmin)]);
            disp([mat2str(n), '回目のベストな差: ', num2str(-1*fmin)]);

            if best_difference < -1*fmin
                best_input = xmin;
                best_difference = -1*fmin;
            end

        else
            disp([mat2str(n),'回目の結果は無効です']);
            disp(['無効なインプット: ', mat2str(xmin)]);
        end
    else
        disp([mat2str(n),'回目の結果は無効です']);
        disp(['無効なインプット: ', mat2str(xmin)]);
    end
end

% 結果の表示
disp(['ベストなインプット: ', mat2str(best_input)]);
disp(['ベストな差: ', num2str(best_difference)]);