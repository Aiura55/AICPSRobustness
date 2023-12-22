function f = objective_function_algo3(x)
    % simulink model を設定する
    mdl = 'nn_fuel_control_3_15_1';

    % モデルのパラメータを設定する
    fuel_inj_tol=1.0;
    MAF_sensor_tol=1.0;
    AF_sensor_tol=1.0;
    pump_tol=1;
    kappa_tol=1;
    tau_ww_tol=1;
    fault_time=50;
    kp=0.04;
    ki=0.14;
    T=50; 

    
    % Br1としてBr1eachSimulinkSystemクラスのインスタンスを生成する
    Br1 = BreachSimulinkSystem(mdl);
    
    % シミュレーションのtime spanを設定する
    Br1.Sys.tspan =0:.01:50;
    
    % インプットのタイプを設定する
    input_gen.type = 'UniStep';
    input_gen.cp = 3;
    
    % このインプットの設定をBr1に渡す
    Br1.SetInputGen(input_gen);
    
        % インプットの範囲を指定する これは変えるべきなのか考える必要がある
    for cpi = 0:input_gen.cp - 1
	    Engine_Speed_sig = strcat('Engine_Speed_u',num2str(cpi));
	    Br1.SetParamRanges({Engine_Speed_sig},[x(1) x(1)]);
	    Pedal_Angle_sig = strcat('Pedal_Angle_u',num2str(cpi));
	    Br1.SetParamRanges({Pedal_Angle_sig},[x(3) x(3)]);
    end
    
    % specification を設定する
    spec = 'alw_[0,30](AF[t] < 1.2*14.7 and AF[t] > 0.8*14.7)';
    
    % STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
    phi = STL_Formula('phi',spec);
    
    % シミュレーションを実行する
    Br1.Sim();
    stl1 = Br1.CheckSpec(phi);
    

    
    
    % Br2としてBr2eachSimulinkSystemクラスのインスタンスを生成する
    Br2 = BreachSimulinkSystem(mdl);
    
    % シミュレーションのtime spanを設定する
    Br2.Sys.tspan =0:.01:50;
    
    % インプットのタイプを設定する
    input_gen.type = 'UniStep';
    input_gen.cp = 3;
    
    % このインプットの設定をBr2に渡す
    Br2.SetInputGen(input_gen);
    
        % インプットの範囲を指定する これは変えるべきなのか考える必要がある
    for cpi = 0:input_gen.cp - 1
	    Engine_Speed_sig = strcat('Engine_Speed_u',num2str(cpi));
	    Br2.SetParamRanges({Engine_Speed_sig},[x(1)+x(2) x(1)+x(2)]);
	    Pedal_Angle_sig = strcat('Pedal_Angle_u',num2str(cpi));
	    Br2.SetParamRanges({Pedal_Angle_sig},[x(3)+x(4) x(3)+x(4)]);
    end
    
    % specification を設定する
    spec = 'alw_[0,30](AF[t] < 1.2*14.7 and AF[t] > 0.8*14.7)';
    
    % STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
    phi = STL_Formula('phi',spec);
    
    % シミュレーションを実行する
    Br2.Sim();
    stl2 = Br2.CheckSpec(phi);


    f = - abs(stl1 - stl2);
    %f = stl1 - stl2;

    disp(['1つ目:', num2str(stl1), ' 2つ目:', num2str(stl2), ' 差:', num2str(-1*f)]);
end