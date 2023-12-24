% ワークスペースの変数をクリアする
clear;
% 開いている全てのfigure windowsを閉じる
close all;
% command windowをクリアする
clc;
% CPSTutorialのあるリポジトリにパスを置き換える
addpath(genpath('C:\Users\onepi\Documents\test2'));
% Breachを起動する
InitBreach;


% simulink model を設定する
mdl = 'nn_fuel_control_3_15_1';

% model のパラメータを設定する
fuel_inj_tol=1.0;
MAF_sensor_tol=1.0;
AF_sensor_tol=1.0;
pump_tol=1;
kappa_tol=1;
tau_ww_tol=1;
fault_time=50;
kp=0.04;
ki=0.14;
T = 50;

epsilon = 0.03;

dimension1_LBounds = 900.0; % 最小値
dimension1_UBounds = 1100.0; % 最大値

dimension2_LBounds = 10.0; % 最小値
dimension2_UBounds = 60.0; % 最大値

input_type = 'UniStep';
input_cp = 3;

time_span = 0:.01:50;

spec1 = 'alw_[0,30](AF[t] < 1.2*14.7 and AF[t] > 0.8*14.7)';
spec2 = 'not alw_[0,30](AF[t] < 1.2*14.7 and AF[t] > 0.8*14.7)';

max_time = 100; %1回あたりのcmaesの時間上限が100秒

global_bujet = 3; %繰り返す回数


%afc_algo1_test2(mdl, epsilon, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds, input_type, input_cp, spec1, spec2, time_span, max_time, global_bujet);

MaxFunEvals = 10;
%afc_algo2_test2(mdl, epsilon, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds, input_type, input_cp, spec1, spec2, time_span, max_time, global_bujet, MaxFunEvals);
%afc_algo3_test2(mdl, epsilon, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds, input_type, input_cp, spec1, spec2, time_span, max_time, global_bujet, MaxFunEvals);
afc_algo4_test2(mdl, epsilon, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds, input_type, input_cp, spec1, spec2, time_span, max_time, global_bujet, MaxFunEvals);

