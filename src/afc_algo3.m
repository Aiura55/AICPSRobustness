function f = afc_algo3(mdl, epsilon, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds, input_type, input_cp, spec1, spec2, time_span, max_time, global_bujet, MaxFunEvals)

best_input = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
best_difference = 0;

for n = 1:global_bujet
    % CMA-ESのオプションを設定
    opts = cmaes;

    % 各次元ごとの下限と上限を設定
    opts.LBounds = zeros(12, 1); % 12変数の下限値を初期化
    opts.UBounds = zeros(12, 1); % 12変数の上限値を初期化
    for i = 0:input_cp - 1
        opts.LBounds(1 + i*4) = dimension1_LBounds;
        opts.LBounds(2 + i*4) = -(dimension1_UBounds - dimension1_LBounds)*epsilon;
        opts.LBounds(3 + i*4) = dimension2_LBounds;
        opts.LBounds(4 + i*4) = -(dimension2_UBounds - dimension2_LBounds)*epsilon;
        opts.UBounds(1 + i*4) = dimension1_UBounds;
        opts.UBounds(2 + i*4) = (dimension1_UBounds - dimension1_LBounds)*epsilon;
        opts.UBounds(3 + i*4) = dimension2_UBounds;
        opts.UBounds(4 + i*4) = (dimension2_UBounds - dimension2_LBounds)*epsilon;
    end

    opts.MaxIter = 1;  % 繰り返しの最大回数を1回に設定
    opts.MaxFunEvals = MaxFunEvals;  % 関数評価の最大回数を設定

    % 初期化パラメータ(インプットの範囲からランダムに設定)
    x0 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    for i = 0:input_cp - 1
        x0(1 + i*4) = round(dimension1_LBounds + (dimension1_UBounds - dimension1_LBounds) * rand, 1);
        x0(2 + i*4) = round((dimension1_UBounds - dimension1_LBounds) * epsilon * (2 * rand - 1), 1);
        x0(3 + i*4) = round(dimension2_LBounds + (dimension2_UBounds - dimension2_LBounds) * rand, 1);
        x0(4 + i*4) = round((dimension2_UBounds - dimension2_LBounds) * epsilon * (2 * rand - 1), 1);
    end
    disp(x0);

    % CMA-ESアルゴリズムの実行
    [xmin, fmin, counteval, stopflag, out, bestever] = cmaes(@(x) objective_function_algo3(mdl, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds, input_type, input_cp, spec1, time_span, x), x0, [], opts);
    
    good_input = 0;
    for i = 0:input_cp - 1
        %インプットが全て範囲内であるかを確認する。
        if (0 <= xmin(2 + i*4) && xmin(1 + i*4) <= dimension1_UBounds - xmin(2 + i*4)) || (xmin(2 + i*4) < 0 && dimension1_LBounds - xmin(2 + i*4) <= xmin(1 + i*4))
            if (0 <= xmin(4 + i*4) && xmin(3 + i*4) <= dimension2_UBounds - xmin(4 + i*4)) || (xmin(4 + i*4) < 0 && dimension2_LBounds - xmin(4 + i*4) <= xmin(3 + i*4))
                % cpごとにインプットが範囲内であるかを確かめる。
                good_input = good_input + 1;
            end
        end
    end

    if good_input == input_cp
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

end

% 結果の表示
disp(['ベストなインプット: ', mat2str(best_input)]);
disp(['ベストな差: ', num2str(best_difference)]);

f = best_difference;

end



function f = objective_function_algo3(mdl, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds, input_type, input_cp, spec1, time_span, x)   
   
    % Br1としてBr1eachSimulinkSystemクラスのインスタンスを生成する
    Br1 = BreachSimulinkSystem(mdl);
    
    % シミュレーションのtime spanを設定する
    Br1.Sys.tspan = time_span;
    
    % インプットのタイプを設定する
    input_gen.type = input_type;
    input_gen.cp = input_cp;
    
    % このインプットの設定をBr1に渡す
    Br1.SetInputGen(input_gen);
    
    % インプットの範囲を指定する
    for cpi = 0:input_gen.cp - 1
	    Engine_Speed_sig = strcat('Engine_Speed_u',num2str(cpi));
	    Br1.SetParamRanges({Engine_Speed_sig},[x(1 + cpi*4) x(1 + cpi*4)]);
	    Pedal_Angle_sig = strcat('Pedal_Angle_u',num2str(cpi));
	    Br1.SetParamRanges({Pedal_Angle_sig},[x(3 + cpi*4) x(3 + cpi*4)]);
    end
        
    % STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
    phi = STL_Formula('phi',spec1);
    
    % シミュレーションを実行する
    Br1.Sim();
    stl1 = Br1.CheckSpec(phi);

    
    
    % Br2としてBr2eachSimulinkSystemクラスのインスタンスを生成する
    Br2 = BreachSimulinkSystem(mdl);
    
    % シミュレーションのtime spanを設定する
    Br2.Sys.tspan = time_span;
    
    % インプットのタイプを設定する
    input_gen.type = input_type;
    input_gen.cp = input_cp;
    
    % このインプットの設定をBr2に渡す
    Br2.SetInputGen(input_gen);
    
    % インプットの範囲を指定する
    for cpi = 0:input_gen.cp - 1
	    Engine_Speed_sig = strcat('Engine_Speed_u',num2str(cpi));
	    Br2.SetParamRanges({Engine_Speed_sig},[x(1 + cpi*4)+x(2 + cpi*4) x(1 + cpi*4)+x(2 + cpi*4)]);
	    Pedal_Angle_sig = strcat('Pedal_Angle_u',num2str(cpi));
	    Br2.SetParamRanges({Pedal_Angle_sig},[x(3 + cpi*4)+x(4 + cpi*4) x(3 + cpi*4)+x(4 + cpi*4)]);
    end
    
    % STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
    phi = STL_Formula('phi',spec1);
    
    % シミュレーションを実行する
    Br2.Sim();
    stl2 = Br2.CheckSpec(phi);


    f = - abs(stl1 - stl2);

    disp(['1つ目:', num2str(stl1), ' 2つ目:', num2str(stl2), ' 差:', num2str(-1*f)]);
end
