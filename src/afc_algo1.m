function f = afc_algo1(mdl, epsilon, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds, input_type, input_cp, spec1, spec2, time_span, max_time, global_bujet)

best_D = 0;

for n = 1:global_bujet
    basis_input = ones(2,3);
    for i = 1:3
        basis_input(1, i) = round(dimension1_LBounds + (dimension1_UBounds - dimension1_LBounds) * rand, 1);
        basis_input(2, i) = round(dimension2_LBounds + (dimension2_UBounds - dimension2_LBounds) * rand, 1);
    end
    
    %まず、基準となるインプットのSTL値を求める
    % BrbasisとしてBreachSimulinkSystemクラスのインスタンスを生成する
    Brbasis = BreachSimulinkSystem(mdl);
    % シミュレーションのtime spanを設定する
    Brbasis.Sys.tspan = time_span;
    % インプットのタイプを設定する
    % ここではUniStepにし、ステップ数は3にする
    input_gen.type = input_type;
    input_gen.cp = input_cp; %inputのステップ数を3に変更した。
    % このインプットの設定をBrに渡す
    Brbasis.SetInputGen(input_gen);
    for cpi = 0:input_gen.cp - 1
	    Engine_Speed_sig = strcat('Engine_Speed_u',num2str(cpi));
        Brbasis.SetParamRanges({Engine_Speed_sig},[basis_input(1, cpi+1) basis_input(1, cpi+1)]);
    
        Pedal_Angle_sig = strcat('Pedal_Angle_u',num2str(cpi));
        Brbasis.SetParamRanges({Pedal_Angle_sig},[basis_input(2, cpi+1) basis_input(1, cpi+1)]);
    end
    
    % STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
    phi = STL_Formula('phi', spec1);
    
    Brbasis.Sim();
    stl_basis = Brbasis.CheckSpec(phi);
    disp(mat2str(stl_basis));
    
    
    
    %% perform falsification
    % BrとしてBreachSimulinkSystemクラスのインスタンスを生成する
    Br = BreachSimulinkSystem(mdl);
    
    % シミュレーションのtime spanを設定する
    Br.Sys.tspan = time_span;
    
    % インプットのタイプを設定する
    % ここではUniStepにし、ステップ数は3にする
    input_gen.type = input_type;
    input_gen.cp = input_cp; %inputのステップ数を3に変更した。
    
    % このインプットの設定をBrに渡す
    Br.SetInputGen(input_gen);
    
    
    %基準のインプットによるεの範囲がインプットの範囲を超えている場合は調整する必要がある。
    for cpi = 0:input_gen.cp - 1
	    Engine_Speed_sig = strcat('Engine_Speed_u',num2str(cpi));
        if basis_input(1, cpi+1)-(dimension1_UBounds - dimension1_LBounds) * epsilon < dimension1_LBounds
            Br.SetParamRanges({Engine_Speed_sig},[dimension1_LBounds basis_input(1, cpi+1)+(dimension1_UBounds - dimension1_LBounds) * epsilon]);
        elseif dimension1_UBounds < basis_input(1, cpi+1)+(dimension1_UBounds - dimension1_LBounds) * epsilon
            Br.SetParamRanges({Engine_Speed_sig},[basis_input(1, cpi+1)-(dimension1_UBounds - dimension1_LBounds) * epsilon dimension1_UBounds]);
        else
            Br.SetParamRanges({Engine_Speed_sig},[basis_input(1, cpi+1)-(dimension1_UBounds - dimension1_LBounds) * epsilon basis_input(1, cpi+1)+(dimension1_UBounds - dimension1_LBounds) * epsilon]);
        end
    
        Pedal_Angle_sig = strcat('Pedal_Angle_u',num2str(cpi));
        if basis_input(2, cpi+1)-(dimension2_UBounds - dimension2_LBounds) * epsilon < dimension2_LBounds
            Br.SetParamRanges({Pedal_Angle_sig},[dimension2_LBounds basis_input(2, cpi+1)+(dimension2_UBounds - dimension2_LBounds) * epsilon]);
        elseif dimension2_UBounds < basis_input(2, cpi+1)+(dimension2_UBounds - dimension2_LBounds) * epsilon
            Br.SetParamRanges({Pedal_Angle_sig},[basis_input(2, cpi+1)-(dimension2_UBounds - dimension2_LBounds) * epsilon dimension2_UBounds]);
        else
            Br.SetParamRanges({Pedal_Angle_sig},[basis_input(2, cpi+1)-(dimension2_UBounds - dimension2_LBounds) * epsilon basis_input(2, cpi+1)+(dimension2_UBounds - dimension2_LBounds) * epsilon]);
        end
    end
    
    %まず最小のSTL値を求める
    
    % STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
    phi = STL_Formula('phi',spec1);
    
    % FalsificationProblemクラスのfalsification instanceを生成し、名前をfalsif_pbとする。
    falsif_pb_min = FalsificationProblem(Br,phi);
    
    % falsificationの時間の上限を設定する
    falsif_pb_min.max_time = max_time;
    
    % 山登りアルゴリズムを設定する。ここではcmaesを使う。
    falsif_pb_min.setup_solver('cmaes');
    
    % falsificationを実行する(STL値を最小化するように変更する必要がある)
    falsif_pb_min.solve();
    
    % falsif_pb.obj_minには今までで最小のSTL値が記録されている


    
    
    
    %次に、最大のSTL値を求める
    % specification を設定する(notを先頭に着けることで目標関数の正負を反転させる)    
    % STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
    phi = STL_Formula('phi',spec2);
    
    % FalsificationProblemクラスのfalsification instanceを生成し、名前をfalsif_pbとする。
    falsif_pb_max = FalsificationProblem(Br,phi);
    
    % falsificationの時間の上限を設定する
    falsif_pb_max.max_time = max_time;
    
    % 山登りアルゴリズムを設定する。ここではcmaesを使う。
    falsif_pb_max.setup_solver('cmaes');
    
    % falsificationを実行する(ロバストネスを最大化するようにしている)
    falsif_pb_max.solve();
    
    % falsif_pb.obj_maxには今までで最大のSTL値が記録されている



    
    %最大の差であるDを求める。
    if falsif_pb_max.obj_best*(-1) - stl_basis >= stl_basis - falsif_pb_min.obj_best 
        D = falsif_pb_max.obj_best*(-1) - stl_basis;
    else
        D = stl_basis - falsif_pb_min.obj_best;
    end
    
    fprintf('%d回目のDの値: %f\n', n, D);

    if best_D < D
        best_D = D;
    end
end

fprintf('ベストなDの値: %f\n', best_D);
f = best_D;
