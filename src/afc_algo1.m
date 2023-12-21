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

% simulink model を設定する
mdl = 'nn_fuel_control_3_15_1';
% mdl = 'nn_fuel_control_3_20';
% mdl = 'nn_fuel_control_4_10';
% mdl = 'nn_fuel_control_4_15_2';
% mdl = 'nn_fuel_control_6_20';

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


% インプットの範囲
% Engine_Speed: [900.0, 1100.0]
% Pedal_Angle: [10.0, 60.0]

%まず、基準となるインプットを1つ決める(今は固定しているが、後々ランダムにする)
dimension1_minVal = 900.0; % 最小値
dimension1_maxVal = 1100.0; % 最大値

dimension2_minVal = 10.0; % 最小値
dimension2_maxVal = 60.0; % 最大値

trials = 3; %繰り返す回数
best_D = 0;

for n = 1:trials
    basis_input = ones(2,3);
    for i = 1:3
        basis_input(1, i) = round(dimension1_minVal + (dimension1_maxVal - dimension1_minVal) * rand, 1);
        basis_input(2, i) = round(dimension2_minVal + (dimension2_maxVal - dimension2_minVal) * rand, 1);
    end
    
    %まず、基準となるインプットのSTL値を求める
    % BrbasisとしてBreachSimulinkSystemクラスのインスタンスを生成する
    Brbasis = BreachSimulinkSystem(mdl);
    % シミュレーションのtime spanを設定する
    Brbasis.Sys.tspan =0:.01:50;
    % インプットのタイプを設定する
    % ここではUniStepにし、ステップ数は3にする
    input_gen.type = 'UniStep';
    input_gen.cp = 3; %inputのステップ数を3に変更した。
    % このインプットの設定をBrに渡す
    Brbasis.SetInputGen(input_gen);
    for cpi = 0:input_gen.cp - 1
	    Engine_Speed_sig = strcat('Engine_Speed_u',num2str(cpi));
        Brbasis.SetParamRanges({Engine_Speed_sig},[basis_input(1, cpi+1) basis_input(1, cpi+1)]);
    
        Pedal_Angle_sig = strcat('Pedal_Angle_u',num2str(cpi));
        Brbasis.SetParamRanges({Pedal_Angle_sig},[basis_input(2, cpi+1) basis_input(1, cpi+1)]);
    end
    % specification を設定する
    spec = 'alw_[0,30](AF[t] < 1.2*14.7 and AF[t] > 0.8*14.7)';
    % STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
    phi = STL_Formula('phi',spec);
    
    Brbasis.Sim();
    stl_basis = Brbasis.CheckSpec(phi);
    disp(mat2str(stl_basis));
    
    
    
    %% perform falsification
    % BrとしてBreachSimulinkSystemクラスのインスタンスを生成する
    Br = BreachSimulinkSystem(mdl);
    
    % シミュレーションのtime spanを設定する
    Br.Sys.tspan =0:.01:50;
    
    % インプットのタイプを設定する
    % ここではUniStepにし、ステップ数は3にする
    input_gen.type = 'UniStep';
    input_gen.cp = 3; %inputのステップ数を3に変更した。
    
    % このインプットの設定をBrに渡す
    Br.SetInputGen(input_gen);
    
    
    %基準のインプットによるεの範囲がインプットの範囲を超えている場合は調整する必要がある。
    for cpi = 0:input_gen.cp - 1
	    Engine_Speed_sig = strcat('Engine_Speed_u',num2str(cpi));
        if basis_input(1, cpi+1)-6 < dimension1_minVal
            Br.SetParamRanges({Engine_Speed_sig},[dimension1_minVal basis_input(1, cpi+1)+6]);
        elseif dimension1_maxVal < basis_input(1, cpi+1)+6
            Br.SetParamRanges({Engine_Speed_sig},[basis_input(1, cpi+1)-6 dimension1_maxVal]);
        else
            Br.SetParamRanges({Engine_Speed_sig},[basis_input(1, cpi+1)-6 basis_input(1, cpi+1)+6]);
        end
    
        Pedal_Angle_sig = strcat('Pedal_Angle_u',num2str(cpi));
        if basis_input(2, cpi+1)-1.5 < dimension2_minVal
            Br.SetParamRanges({Pedal_Angle_sig},[dimension2_minVal basis_input(2, cpi+1)+1.5]);
        elseif dimension2_maxVal < basis_input(2, cpi+1)+1.5
            Br.SetParamRanges({Pedal_Angle_sig},[basis_input(2, cpi+1)-1.5 dimension2_maxVal]);
        else
            Br.SetParamRanges({Pedal_Angle_sig},[basis_input(2, cpi+1)-1.5 basis_input(2, cpi+1)+1.5]);
        end
    end
    
    %まず最小のSTL値を求める
    % specification を設定する
    spec = 'alw_[0,30](AF[t] < 1.2*14.7 and AF[t] > 0.8*14.7)';
    % spec = 'alw_[10,30]((not (AF[t] < 1.1*14.7 and AF[t] > 0.9*14.7)) => ev_[0,2](AF[t] < 1.1*14.7 and AF[t] > 0.9*14.7))';
    % spec = 'alw_[10,30](ev_[0,3](AF[t] < 1.1 * 14.7 and AF[t] > 0.9 * 14.7))';
    
    % STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
    phi = STL_Formula('phi',spec);
    
    % それぞれのインスタンスの時間コストを記録する。
    time_min = [];
    
    % それぞれのインスタンスの最大のロバストネスを記録する。
    obj_min = [];
    
    % 1つのインスタンスにおけるシミュレーションのナンバーを記録する。
    num_sim_min = [];
    
    % FalsificationProblemクラスのfalsification instanceを生成し、名前をfalsif_pbとする。
    falsif_pb_min = FalsificationProblem(Br,phi);
    
    % falsificationの時間の上限を設定する
    falsif_pb_min.max_time = 100;
    
    % 山登りアルゴリズムを設定する。ここではcmaesを使う。
    falsif_pb_min.setup_solver('cmaes');
    
    % falsificationを実行する(STL値を最小化するように変更する必要がある)
    falsif_pb_min.solve();
    
    % falsif_pb.obj_minには今までで最小のSTL値が記録されている
    %この山登りは時間や回数の上限になるまで探索を続ける
    
    % それぞれの値を記録する。
    num_sim_min = [num_sim_min;falsif_pb_min.nb_obj_eval];
    time_miin = [time_min;falsif_pb_min.time_spent];
    obj_min = [obj_min;falsif_pb_min.obj_best];
    
    
    
    %次に、最大のSTL値を求める
    % specification を設定する(notを先頭に着けることで目標関数の正負を反転させる)
    spec = 'not alw_[0,30](AF[t] < 1.2*14.7 and AF[t] > 0.8*14.7)';
    % spec = 'alw_[10,30]((not (AF[t] < 1.1*14.7 and AF[t] > 0.9*14.7)) => ev_[0,2](AF[t] < 1.1*14.7 and AF[t] > 0.9*14.7))';
    % spec = 'alw_[10,30](ev_[0,3](AF[t] < 1.1 * 14.7 and AF[t] > 0.9 * 14.7))';
    
    % STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
    phi = STL_Formula('phi',spec);
    % それぞれのインスタンスの時間コストを記録する。
    time_max = [];
    
    % それぞれのインスタンスの最大のロバストネスを記録する。
    obj_max = [];
    
    % 1つのインスタンスにおけるシミュレーションのナンバーを記録する。
    num_sim_max = [];
    
    % FalsificationProblemクラスのfalsification instanceを生成し、名前をfalsif_pbとする。
    falsif_pb_max = FalsificationProblem(Br,phi);
    
    % falsificationの時間の上限を設定する
    falsif_pb_max.max_time = 100;
    
    % 山登りアルゴリズムを設定する。ここではcmaesを使う。
    falsif_pb_max.setup_solver('cmaes');
    
    % falsificationを実行する(ロバストネスを最大化するようにしている)
    falsif_pb_max.solve();
    
    % falsif_pb.obj_maxには今までで最大のSTL値が記録されている
    %この山登りは時間や回数の上限になるまで探索を続ける
    
    % それぞれの値を記録する。
    num_sim_max = [num_sim_max;falsif_pb_max.nb_obj_eval];
    time_max = [time_max;falsif_pb_max.time_spent];
    obj_max = [obj_max;falsif_pb_max.obj_best];
    
    
    %最大の差であるDを求める。
    if obj_max(1)*(-1) - stl_basis >= stl_basis - obj_min(1) 
        D = obj_max(1)*(-1) - stl_basis;
    else
        D = stl_basis - obj_min(1);
    end
    
    fprintf('%d回目のDの値: %f\n', n, D);

    if best_D < D
        best_D = D;
    end
end

fprintf('ベストなDの値: %f\n', D);