%% SBD1 Phase transition
clear; clc; %#ok<*PFBNS>
run('../initpkg.m');

%% Settings
% Data *params
dist = @(m,n) randn(m,n);       % Distribution of activations
thetas = 10.^linspace(-2.5, -1.5, 10);
p0s = ceil(10.^linspace(2.5, 4.5, 10));

% Experimental settings
trials = 10;                    % Number of trials
maxit = 1e3;                    % Max iter. & tol. for solver
tol = 1e-3;

%% Containers
tmp = [numel(thetas) numel(p0s)];       % *params
obj = NaN(prod(tmp), trials);
its = NaN(prod(tmp), trials);
times = NaN(trials,1);

%% Experimental iterations
clc;
warning('OFF', 'MATLAB:mir_warning_maybe_uninitialized_temporary');

for idx = 1:prod(tmp)
    fprintf('Testing %d of %d...\n', idx-1, prod(tmp)-1);
    [i, j] = ind2sub(tmp, idx);

    theta = thetas(i); p0 = p0s(j);         % *params
    a0 = randn(p0,1);  a0 = a0/norm(a0);
    
    m = 100 * p0;
    lambda = 1/sqrt(p0*theta);

    start = tic;
% WHAT HAPPENS IN EACH TRIAL:
parfor trial = 1:trials
    % A) Generate x & y: supp(x) must be >= 1
    xgood = false;
    while ~xgood
        x0 = (rand(m,1) <= theta) .* dist(m,1);
        xgood = sum(x0~=0) >= 1;
    end
    y = cconv(a0, x0, m);
    
    % B) Create solver and run continuation sequence
    solver = sbd_dq(y, 3*p0-2, struct('lambda', lambda));
    solver = solve(solver, [10 maxit], tol, lambda);
    
    % C) Record statistics
    obj(idx, trial) = maxdotshift(a0, solver.a);
    its(idx, trial) = solver.it;
end
    fprintf('\b\b\b\b: p0 = %d, theta = %.2E, mean obj. = %.2f.', ...
        p0, theta, mean(obj(idx,:)));       % *params
    times(idx) = toc(start);
    fprintf(' Time elapsed: %.1fs.\n', times(idx));
end
%
obj = reshape(obj, [tmp trials]);
its = reshape(its, [tmp trials]);
warning('ON', 'MATLAB:mir_warning_maybe_uninitialized_temporary');
disp('Done.');

% Plots
tmp = {0.9 'flat'};
i = log10(thetas);  j = log10(p0s);         % *params

clf;
if min(size(obj,1), size(obj,2)) == 1
    % 1D transition plots
    if size(obj,1) == 1;  tmp{3} = j;  else;  tmp{3} = i;  end
    yyaxis left;   
    plot(tmp{3}, median(squeeze(obj),2));  hold on;
    plot(tmp{3}, mean(squeeze(obj),2));
    plot(tmp{3}, min(squeeze(obj), [], 2));
    hold off;
    ylabel('\rho = max_i <S_i[a0], a>');

    yyaxis right;    plot(tmp{3}, mean(squeeze(obj) >= tmp{1},2));
    ylabel(['P[\rho > ' sprintf('%.2f]', tmp{1})]); 
    xlabel('p\theta');
    
else
    % 2D transition plots
    colormap gray; 
    subplot(131); surf(i, j, mean(obj,3)'); 
    view(2); shading(tmp{2});  title('Mean of \rho');
    
    subplot(132); surf(i, j, median(obj,3)'); 
    view(2); shading(tmp{2});  title('Median of \rho');
    
    subplot(133); surf(i, j, mean(obj>=tmp{1},3)'); 
    view(2); shading(tmp{2});  title('Success prob.');
end

% End of experiment
beep