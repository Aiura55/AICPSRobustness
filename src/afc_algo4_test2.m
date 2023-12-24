function f = afc_algo4_test2(mdl, epsilon, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds, input_type, input_cp, spec1, spec2, time_span, max_time, global_bujet, MaxFunEvals)

best_input = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
best_difference = 0;

for n = 1:global_bujet
    % CMA-ESのオプションを設定
    opts = cmaes;

    % 各次元ごとの下限と上限を設定
    opts.LBounds = zeros(12, 1); % 12変数の下限値を初期化
    opts.UBounds = zeros(12, 1); % 12変数の上限値を初期化
    for i = 0:input_cp - 1
        opts.LBounds(1 + i*4) = 0;
        opts.LBounds(2 + i*4) = 0;
        opts.LBounds(3 + i*4) = 0;
        opts.LBounds(4 + i*4) = 0;
        opts.UBounds(1 + i*4) = 100;
        opts.UBounds(2 + i*4) = 100;
        opts.UBounds(3 + i*4) = 100;
        opts.UBounds(4 + i*4) = 100;
    end

    opts.MaxIter = 1;  % 繰り返しの最大回数を1回に設定
    opts.MaxFunEvals = MaxFunEvals;  % 関数評価の最大回数を設定

    % 初期化パラメータ(インプットの範囲からランダムに設定)
    x0 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    for i = 0:input_cp - 1
        x0(1 + i*4) = 100 * rand;
        x0(2 + i*4) = 100 * rand;
        x0(3 + i*4) = 100 * rand;
        x0(4 + i*4) = 100 * rand;
    end

    % CMA-ESアルゴリズムの実行
    [xmin, fmin, counteval, stopflag, out, bestever] = cmaes(@(x) objective_function_algo4(mdl, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds, input_type, input_cp, spec1, time_span, epsilon, x), x0, [], opts);
    
    % 結果の表示
    disp([mat2str(n), '回目のベストなインプット: ', mat2str(xmin)]);

    mapping_input = mapping_algo4(xmin, epsilon, input_cp, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds);
    disp(['マッピング後のインプット: ', mat2str(mapping_input)]);
    disp([mat2str(n), '回目のベストな差: ', num2str(-1*fmin)]);

    if best_difference < -1*fmin
        best_input = xmin;
        best_difference = -1*fmin;
    end
end

% 結果の表示
disp(['ベストなインプット: ', mat2str(best_input)]);

best_mapping_input = mapping_algo4(best_input, epsilon, input_cp, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds);
disp(['マッピング後のベストなインプット: ', mat2str(best_mapping_input)]);
disp(['ベストな差: ', num2str(best_difference)]);

f = best_difference;

end



function f = objective_function_algo4(mdl, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds, input_type, input_cp, spec1, time_span, epsilon, x)

    x = mapping_algo4(x, epsilon, input_cp, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds);
    disp(x);
    
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
	    Br2.SetParamRanges({Engine_Speed_sig},[x(2 + cpi*4) x(2 + cpi*4)]);
	    Pedal_Angle_sig = strcat('Pedal_Angle_u',num2str(cpi));
	    Br2.SetParamRanges({Pedal_Angle_sig},[x(4 + cpi*4) x(4 + cpi*4)]);
    end
    
    % STL_Formulaクラスのインスタンスを生成し,このSTL式の名前をphiとする。
    phi = STL_Formula('phi',spec1);
    
    % シミュレーションを実行する
    Br2.Sim();
    stl2 = Br2.CheckSpec(phi);


    f = - abs(stl1 - stl2);

    disp(['1つ目:', num2str(stl1), ' 2つ目:', num2str(stl2), ' 差:', num2str(-1*f)]);
end



function f = mapping_algo4(x, epsilon, input_cp, dimension1_LBounds, dimension1_UBounds, dimension2_LBounds, dimension2_UBounds)
    %epsilonを100倍して、0.03 → 3%として使う。
    epsilon = epsilon * 100;

    for i = 0:input_cp - 1
        %インプットの調整
        if epsilon < x(1 + i*4) + x(2 + i*4) && epsilon < (100 - x(1 + i*4)) + (100 - x(2 + i*4))
            %交点の座標を計算(x=y)
            intersection = (x(1 + i*4) + x(2 + i*4)) / 2;
    
            %1を計算
            if (x(1 + i*4) + x(2 + i*4)) / 2 <= 50
                val = epsilon * abs(-x(1 + i*4) + x(2 + i*4)) / (2*sqrt(2)*intersection);
            else
                val = epsilon * abs(-x(1 + i*4) + x(2 + i*4)) / (2*sqrt(2)*(100 - intersection));
            end
    
            %インプットをマッピング
            if x(1 + i*4) > x(2 + i*4)
                add1 = intersection + val / sqrt(2);
                add2 = intersection - val / sqrt(2);
    
                x(1 + i*4) = dimension1_LBounds + (dimension1_UBounds - dimension1_LBounds)*add1/100;
                x(2 + i*4) = dimension1_LBounds + (dimension1_UBounds - dimension1_LBounds)*add2/100;
    
            else 
                add1 = intersection - val / sqrt(2);
                add2 = intersection + val / sqrt(2);
    
                x(1 + i*4) = dimension1_LBounds + (dimension1_UBounds - dimension1_LBounds)*add1/100;
                x(2 + i*4) = dimension1_LBounds + (dimension1_UBounds - dimension1_LBounds)*add2/100;
    
            end
        else %マッピングを変えなくていいとき
                x(1 + i*4) = dimension1_LBounds + (dimension1_UBounds - dimension1_LBounds)*x(1 + i*4)/100;
                x(2 + i*4) = dimension1_LBounds + (dimension1_UBounds - dimension1_LBounds)*x(2 + i*4)/100;
        end
    
        if epsilon < x(3 + i*4) + x(4 + i*4) && epsilon < (100 - x(3 + i*4)) + (100 - x(4 + i*4))
            %交点の座標を計算(x=y)
            intersection = (x(3 + i*4) + x(4 + i*4)) / 2;
    
            %1を計算
            if (x(3 + i*4) + x(4 + i*4)) / 2 < 50
                val = epsilon * abs(-x(3 + i*4) + x(4 + i*4)) / (2*sqrt(2)*intersection);
            else
                val = epsilon * abs(-x(3 + i*4) + x(4 + i*4)) / (2*sqrt(2)*(100 - intersection));
            end
    
                
            %インプットをマッピング
            if x(3 + i*4) > x(4 + i*4)
                add1 = intersection + val / sqrt(2);
                add2 = intersection - val / sqrt(2);
    
                x(3 + i*4) = dimension2_LBounds + (dimension2_UBounds - dimension2_LBounds)*add1/100;
                x(4 + i*4) = dimension2_LBounds + (dimension2_UBounds - dimension2_LBounds)*add2/100;
    
            else 
                add1 = intersection - val / sqrt(2);
                add2 = intersection + val / sqrt(2);
    
                x(3 + i*4) = dimension2_LBounds + (dimension2_UBounds - dimension2_LBounds)*add1/100;
                x(4 + i*4) = dimension2_LBounds + (dimension2_UBounds - dimension2_LBounds)*add2/100;
    
            end
        else %マッピングを変えなくていいとき
                x(3 + i*4) = dimension1_LBounds + (dimension1_UBounds - dimension1_LBounds)*x(3 + i*4)/100;
                x(4 + i*4) = dimension1_LBounds + (dimension1_UBounds - dimension1_LBounds)*x(4 + i*4)/100;
        end
    end

    f = x;
end