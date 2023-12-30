classdef RandomProblem < FalsificationProblem
     properties  
        epsilon
        deviation

        threshold

        local_budget

        basic_X
        basic_stlv
     end

     methods
         function this = RandomProblem(BrSet, phi, ep, threshold, locBud)
             this = this@FalsificationProblem(BrSet, phi);
             this.epsilon = ep;
             this.deviation = (this.ub - this.lb)*ep;
             this.threhold = threshold;
             this.local_budget = locBud;
             rng('default');
             rng(round(rem(now, 1)*1000000));
         end

        function res = solve(this)
            rfprintf_reset();         
            % reset time
            this.ResetTimeSpent();
         
            while this.time_spent < this.max_time
                this.basic_X = this.lb + rand(1, numel(this.lb))*(this.ub - this.lb);
                this.basic_stlv = this.objective_fn(this.basic_X);
                solver_opt = this.setCMAES();

                this.x0 = this.set_X0();
            
                [x, fval, counteval, stopflag, out, bestever] = cmaes(this.objective, this.x0', [], solver_opt);
                res = struct('x',x, 'fval',fval, 'counteval', counteval,  'stopflag', stopflag, 'out', out, 'bestever', bestever);
                %this.res=res;    
                if res.fval < -this.epsilon
                    break;
                end
            end

            this.DispResultMsg(); 
        end

        function solver_opt = setCMAES(this)
            %disp('Setting options for cmaes solver - use help cmaes for details');
            l_ = this.basic_X - this.deviation;
            for i = 1:numel(l_)
                if l_(i) < this.lb(i)
                    l_(i) = this.lb(i);
                end
            end
            u_ = this.basic_X + this.deviation;
            for j = 1:numel(u_)
                if u_(j) >  this.ub(j)
                    u_(j) = this.ub(j);
                end
            end

            solver_opt = cmaes();
            solver_opt.Seed = 0;
            solver_opt.LBounds = l_;
            solver_opt.UBounds = u_;
            solver_opt.StopIter = this.local_budget;
        end


        function x0 = set_X0(this)

        end

        function fval = objective_wrapper(this, x)
            if this.stopping()==true
                fval = this.obj_best;
            else
                % calling actual objective function
                %fval = this.objective_fn(x);
                stlv = this.objective_fn(x);
                fval = -abs(stlv - this.basic_stlv);
                
                % logging and updating best
                this.LogX(x, fval);
 
                % update status
                if rem(this.nb_obj_eval,this.freq_update)==0
                    this.display_status();
                end
                
            end
        end

        function b = stopping(this)
            b =  (this.time_spent >= this.max_time) ||...
            (this.nb_obj_eval>= this.max_obj_eval) ||...
            (this.obj_best < -this.threshold);
        end
     end
end